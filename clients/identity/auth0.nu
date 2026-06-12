# Auto-generated client for Auth0 Management API v2.0
# Source: https://auth0.com/docs/api/management/openapi.json
# Auth: --token flag or $env.AUTH0_MANAGEMENT_API_TOKEN

const BASE_URL = "https://{TENANT}.auth0.com/api/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AUTH0_MANAGEMENT_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://{TENANT}.auth0.com/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def triggerId-completer [] { ["credentials-exchange" "custom-email-provider" "custom-phone-provider" "custom-token-exchange" "event-stream" "login-post-identifier" "password-hash-migration" "password-reset-post-challenge" "post-change-password" "post-login" "post-user-registration" "pre-user-registration" "send-phone-message" "signup-post-identifier"] }
def bot-detection-level-completer [] { ["high" "low" "medium"] }
def challenge-password-policy-completer [] { ["always" "never" "when_risky"] }
def challenge-passwordless-policy-completer [] { ["always" "never" "when_risky"] }
def challenge-password-reset-policy-completer [] { ["always" "never" "when_risky"] }
def method-completer [] { ["enhanced" "standard"] }
def mode-completer [] { ["count_per_identifier" "count_per_identifier_and_ip"] }
def active-provider-id-completer [] { ["arkose" "auth_challenge" "friendly_captcha" "hcaptcha" "recaptcha_enterprise" "recaptcha_v2" "simple_captcha"] }
def name-completer [] { ["custom" "twilio"] }
def delivery-method-completer [] { ["text" "voice"] }
def type-completer [] { ["blocked_account" "change_password" "otp_enroll" "otp_verify" "password_breach"] }
def allow-any-organization-completer [] { ["true"] }
def subject-type-completer [] { ["client" "user"] }
def default-for-completer [] { ["third_party_clients"] }
def organization-usage-completer [] { ["allow" "deny" "require"] }
def organization-usage-completer-1 [] { ["" "allow" "deny" "require"] }
def token-endpoint-auth-method-completer [] { ["client_secret_basic" "client_secret_post" "none"] }
def app-type-completer [] { ["box" "cloudbees" "concur" "dropbox" "echosign" "egnyte" "express_configuration" "mscrm" "native" "newrelic" "non_interactive" "oag" "office365" "regular_web" "resource_server" "rms" "salesforce" "sentry" "sharepoint" "slack" "spa" "springcm" "sso_integration" "zendesk" "zoom"] }
def organization-require-behavior-completer [] { ["no_prompt" "post_login_prompt" "pre_login_prompt"] }
def compliance-level-completer [] { ["" "fapi1_adv_mtls_par" "fapi1_adv_pkj_par" "fapi2_sp_mtls_mtls" "fapi2_sp_pkj_mtls" "none"] }
def third-party-security-mode-completer [] { ["permissive" "strict"] }
def redirection-policy-completer [] { ["allow_always" "open_redirect_protection"] }
def credential-type-completer [] { ["cert_subject_dn" "public_key" "x509_cert"] }
def alg-completer [] { ["PS256" "RS256" "RS384"] }
def token-endpoint-auth-method-completer-1 [] { ["" "client_secret_basic" "client_secret_post" "none"] }
def organization-require-behavior-completer-1 [] { ["" "no_prompt" "post_login_prompt" "pre_login_prompt"] }
def strategy-completer [] { ["ad" "adfs" "amazon" "apple" "auth0" "auth0-oidc" "baidu" "bitbucket" "bitly" "box" "custom" "daccount" "dropbox" "dwolla" "email" "evernote" "evernote-sandbox" "exact" "facebook" "fitbit" "github" "google-apps" "google-oauth2" "instagram" "ip" "line" "linkedin" "oauth1" "oauth2" "office365" "oidc" "okta" "paypal" "paypal-sandbox" "pingfederate" "planningcenter" "salesforce" "salesforce-community" "salesforce-sandbox" "samlp" "sharepoint" "shop" "shopify" "sms" "soundcloud" "thirtysevensignals" "twitter" "untappd" "vkontakte" "waad" "weibo" "windowslive" "wordpress" "yahoo" "yandex"] }
def synchronize-groups-completer [] { ["all" "off" "selected"] }
def signing-alg-completer [] { ["ES256" "ES384" "PS256" "PS384" "RS256" "RS384" "RS512"] }
def type-completer-1 [] { ["auth0_managed_certs" "self_managed_certs"] }
def verification-method-completer [] { ["txt"] }
def tls-policy-completer [] { ["recommended"] }
def type-completer-2 [] { ["public_key" "refresh_token" "rotating_refresh_token"] }
def type-completer-3 [] { ["public_key"] }
def template-completer [] { ["async_approval" "blocked_account" "change_password" "enrollment_email" "mfa_oob_code" "password_reset" "reset_email" "reset_email_by_code" "stolen_credentials" "user_invitation" "verify_email" "verify_email_by_code" "welcome_email"] }
def name-completer-1 [] { ["azure_cs" "custom" "mailgun" "mandrill" "ms365" "resend" "sendgrid" "ses" "smtp" "sparkpost"] }
def status-completer [] { ["disabled" "enabled"] }
def event-type-completer [] { ["group.created" "group.deleted" "group.member.added" "group.member.deleted" "group.role.assigned" "group.role.deleted" "group.updated" "organization.connection.added" "organization.connection.removed" "organization.connection.updated" "organization.created" "organization.deleted" "organization.group.role.assigned" "organization.group.role.deleted" "organization.member.added" "organization.member.deleted" "organization.member.role.assigned" "organization.member.role.deleted" "organization.updated" "user.created" "user.deleted" "user.updated"] }
def factor-completer [] { ["email" "otp" "phone" "push-notification" "webauthn-platform" "webauthn-roaming"] }
def provider-completer [] { ["auth0" "phone-message-hook" "twilio"] }
def provider-completer-1 [] { ["direct" "guardian" "sns"] }
def triggerId-completer-1 [] { ["credentials-exchange" "post-change-password" "post-user-registration" "pre-user-registration" "send-phone-message"] }
def format-completer [] { ["csv" "json"] }
def type-completer-4 [] { ["customer-provided-root-key" "tenant-encryption-key"] }
def type-completer-5 [] { ["http"] }
def status-completer-1 [] { ["active" "paused" "suspended"] }
def organization-access-level-completer [] { ["full" "limited" "none" "readonly"] }
def organization-access-level-completer-1 [] { ["" "full" "limited" "none" "readonly"] }
def status-completer-2 [] { ["pending" "verified"] }
def universal-login-experience-completer [] { ["classic" "new"] }
def rendering-mode-completer [] { ["advanced" "standard"] }
def signing-alg-completer-1 [] { ["HS256" "PS256" "RS256" "RS512"] }
def token-dialect-completer [] { ["access_token" "access_token_authz" "rfc9068_profile" "rfc9068_profile_authz"] }
def consent-policy-completer [] { ["" "transactional-authorization-with-mfa"] }
def resource-parameter-profile-completer [] { ["audience" "compatibility"] }
def dynamic-client-registration-security-mode-completer [] { ["permissive" "strict"] }
def type-completer-6 [] { ["custom_authentication"] }
def search-engine-completer [] { ["v1" "v2" "v3"] }
def type-completer-7 [] { ["email" "passkey" "phone" "totp" "webauthn-roaming"] }
def preferred-authentication-method-completer [] { ["sms" "voice"] }
def provider-completer-2 [] { ["ad" "adfs" "amazon" "apple" "auth0" "auth0-oidc" "baidu" "bitbucket" "bitly" "box" "custom" "daccount" "dropbox" "dwolla" "email" "evernote" "evernote-sandbox" "exact" "facebook" "fitbit" "github" "google-apps" "google-oauth2" "instagram" "ip" "line" "linkedin" "oauth1" "oauth2" "office365" "oidc" "okta" "paypal" "paypal-sandbox" "pingfederate" "planningcenter" "salesforce" "salesforce-community" "salesforce-sandbox" "samlp" "sharepoint" "shop" "shopify" "sms" "soundcloud" "thirtysevensignals" "twitter" "untappd" "vkontakte" "waad" "weibo" "windowslive" "wordpress" "yahoo" "yandex"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "actions-actions actions" } } | get name | first)
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

# Get actions
#
# GET /actions/actions
# operationId: get_actions
export def "actions-actions actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --triggerId: string@triggerId-completer # An actions extensibility point.
  --actionName: string # The name of the action to retrieve.
  --deployed: oneof<nothing, bool> # Optional filter to only retrieve actions that are deployed.
  --page: int # Use this field to request a specific page of the list results.
  --per-page: int # The maximum number of results to be returned by the server in single response. 20 by default
  --installed: oneof<nothing, bool> # Optional. When true, return only installed actions. When false, return only custom actions. Returns all actions by default.
]: nothing -> record<total: float, page: float, per_page: float, actions: table<id: string, name: string, supported_triggers: list, all_changes_deployed: bool, created_at: string, updated_at: string, code: string, dependencies: list, runtime: string, secrets: list, deployed_version: record, installed_integration_id: string, integration: record, status: string, built_at: string, deploy: bool, modules: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "triggerId" $triggerId "scalar") (serialize-qp "actionName" $actionName "scalar") (serialize-qp "deployed" $deployed "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "installed" $installed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/actions/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an action
#
# POST /actions/actions
# operationId: post_action
# --supported_triggers item shape: {id: "post-login"|"credentials-exchange"|"pre-user-registration"|"post-user-registration"|"post-change-password"|"send-phone-message"|"custom-phone-provider"|"custom-email-provider"|"password-reset-post-challenge"|"custom-token-exchange"|"event-stream"|"password-hash-migration"|"login-post-identifier"|"signup-post-identifier", version?: string, status?: string, runtimes?: list, default_runtime?: string, compatible_triggers?: list, binding_policy?: "trigger-bound"|"entity-bound"}
# --dependencies item shape: {name?: string, version?: string, registry_url?: string}
# --secrets item shape: {name?: string, value?: string}
# --modules item shape: {module_id?: string, module_name?: string, module_version_id?: string, module_version_number?: int}
export def "actions-actions action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of an action. (default: my-action)
  supported_triggers: list # The list of triggers that this action supports. At this time, an action can only target a single trigger at a time. — item shape: {id: "post-login"|"credentials-exchange"|"pre-user-registration"|"post-user-registration"|"post-change-password"|"send-phone-message"|"custom-phone-provider"|"custom-email-provider"|"password-reset-post-challenge"|"custom-token-exchange"|"event-stream"|"password-hash-migration"|"login-post-identifier"|"signup-post-identifier", version?: string, status?: string, runtimes?: list, default_runtime?: string, compatible_triggers?: list, binding_policy?: "trigger-bound"|"entity-bound"}
  --code: string # The source code of the action. (default: module.exports = () => {})
  --dependencies: list # The list of third party npm modules, and their versions, that this action depends on. — item shape: {name?: string, version?: string, registry_url?: string}
  --runtime: string # The Node runtime. For example: `node22`, defaults to `node22` (default: node22)
  --secrets: list # The list of secrets that are included in an action or a version of an action. — item shape: {name?: string, value?: string}
  --modules: list # The list of action modules and their versions used by this action. — item shape: {module_id?: string, module_name?: string, module_version_id?: string, module_version_number?: int}
  --deploy: oneof<nothing, bool> # True if the action should be deployed after creation. (default: false)
]: any -> record<id: string, name: string, supported_triggers: table<id: string, version: string, status: string, runtimes: list, default_runtime: string, compatible_triggers: list, binding_policy: string>, all_changes_deployed: bool, created_at: string, updated_at: string, code: string, dependencies: table<name: string, version: string, registry_url: string>, runtime: string, secrets: table<name: string, updated_at: string>, deployed_version: record<id: string, action_id: string, code: string, dependencies: list<record>, deployed: bool, runtime: string, secrets: list<record>, status: string, number: float, errors: list<record>, action: record<id: string, name: string, supported_triggers: list, all_changes_deployed: bool, created_at: string, updated_at: string>, built_at: string, created_at: string, updated_at: string, supported_triggers: list<record>, modules: list<record>>, installed_integration_id: string, integration: record<id: string, catalog_id: string, url_slug: string, partner_id: string, name: string, description: string, short_description: string, logo: string, feature_type: string, terms_of_use_url: string, privacy_policy_url: string, public_support_link: string, current_release: record<id: string, trigger: record, semver: record, required_secrets: list, required_configuration: list>, created_at: string, updated_at: string>, status: string, built_at: string, deploy: bool, modules: table<module_id: string, module_name: string, module_version_id: string, module_version_number: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/actions/actions")
  let body = {name: $name, supported_triggers: $supported_triggers, code: $code, dependencies: $dependencies, runtime: $runtime, secrets: $secrets, modules: $modules, deploy: $deploy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an action's versions
#
# GET /actions/actions/{actionId}/versions
# operationId: get_action_versions
export def "actions-actions-versions versions" [
  actionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Use this field to request a specific page of the list results.
  --per-page: int # This field specify the maximum number of results to be returned by the server. 20 by default
]: nothing -> record<total: float, page: float, per_page: float, versions: table<id: string, action_id: string, code: string, dependencies: list, deployed: bool, runtime: string, secrets: list, status: string, number: float, errors: list, action: record, built_at: string, created_at: string, updated_at: string, supported_triggers: list, modules: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/actions/actions/($actionId)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific version of an action
#
# GET /actions/actions/{actionId}/versions/{id}
# operationId: get_action_version
export def "actions-actions-versions version" [
  actionId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, action_id: string, code: string, dependencies: table<name: string, version: string, registry_url: string>, deployed: bool, runtime: string, secrets: table<name: string, updated_at: string>, status: string, number: float, errors: table<id: string, msg: string, url: string>, action: record<id: string, name: string, supported_triggers: list<record>, all_changes_deployed: bool, created_at: string, updated_at: string>, built_at: string, created_at: string, updated_at: string, supported_triggers: table<id: string, version: string, status: string, runtimes: list, default_runtime: string, compatible_triggers: list, binding_policy: string>, modules: table<module_id: string, module_name: string, module_version_id: string, module_version_number: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/actions/($actionId)/versions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Roll back to a previous action version
#
# POST /actions/actions/{actionId}/versions/{id}/deploy
# operationId: post_deploy_draft_version
export def "actions-actions-versions-deploy version" [
  id: string
  actionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --update-draft: oneof<nothing, bool> # True if the draft of the action should be updated with the reverted version. (default: false)
]: any -> record<id: string, action_id: string, code: string, dependencies: table<name: string, version: string, registry_url: string>, deployed: bool, runtime: string, secrets: table<name: string, updated_at: string>, status: string, number: float, errors: table<id: string, msg: string, url: string>, action: record<id: string, name: string, supported_triggers: list<record>, all_changes_deployed: bool, created_at: string, updated_at: string>, built_at: string, created_at: string, updated_at: string, supported_triggers: table<id: string, version: string, status: string, runtimes: list, default_runtime: string, compatible_triggers: list, binding_policy: string>, modules: table<module_id: string, module_name: string, module_version_id: string, module_version_number: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/actions/($actionId)/versions/($id)/deploy")
  let body = {update_draft: $update_draft} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an action
#
# GET /actions/actions/{id}
# operationId: get_action
export def "actions-actions action-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, supported_triggers: table<id: string, version: string, status: string, runtimes: list, default_runtime: string, compatible_triggers: list, binding_policy: string>, all_changes_deployed: bool, created_at: string, updated_at: string, code: string, dependencies: table<name: string, version: string, registry_url: string>, runtime: string, secrets: table<name: string, updated_at: string>, deployed_version: record<id: string, action_id: string, code: string, dependencies: list<record>, deployed: bool, runtime: string, secrets: list<record>, status: string, number: float, errors: list<record>, action: record<id: string, name: string, supported_triggers: list, all_changes_deployed: bool, created_at: string, updated_at: string>, built_at: string, created_at: string, updated_at: string, supported_triggers: list<record>, modules: list<record>>, installed_integration_id: string, integration: record<id: string, catalog_id: string, url_slug: string, partner_id: string, name: string, description: string, short_description: string, logo: string, feature_type: string, terms_of_use_url: string, privacy_policy_url: string, public_support_link: string, current_release: record<id: string, trigger: record, semver: record, required_secrets: list, required_configuration: list>, created_at: string, updated_at: string>, status: string, built_at: string, deploy: bool, modules: table<module_id: string, module_name: string, module_version_id: string, module_version_number: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/actions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an action
#
# DELETE /actions/actions/{id}
# operationId: delete_action
export def "actions-actions action-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # Force action deletion detaching bindings
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/actions/actions/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an action
#
# PATCH /actions/actions/{id}
# operationId: patch_action
# --supported_triggers item shape: {id: "post-login"|"credentials-exchange"|"pre-user-registration"|"post-user-registration"|"post-change-password"|"send-phone-message"|"custom-phone-provider"|"custom-email-provider"|"password-reset-post-challenge"|"custom-token-exchange"|"event-stream"|"password-hash-migration"|"login-post-identifier"|"signup-post-identifier", version?: string, status?: string, runtimes?: list, default_runtime?: string, compatible_triggers?: list, binding_policy?: "trigger-bound"|"entity-bound"}
# --dependencies item shape: {name?: string, version?: string, registry_url?: string}
# --secrets item shape: {name?: string, value?: string}
# --modules item shape: {module_id?: string, module_name?: string, module_version_id?: string, module_version_number?: int}
export def "actions-actions action-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of an action. (default: my-action)
  --supported-triggers: list # The list of triggers that this action supports. At this time, an action can only target a single trigger at a time. — item shape: {id: "post-login"|"credentials-exchange"|"pre-user-registration"|"post-user-registration"|"post-change-password"|"send-phone-message"|"custom-phone-provider"|"custom-email-provider"|"password-reset-post-challenge"|"custom-token-exchange"|"event-stream"|"password-hash-migration"|"login-post-identifier"|"signup-post-identifier", version?: string, status?: string, runtimes?: list, default_runtime?: string, compatible_triggers?: list, binding_policy?: "trigger-bound"|"entity-bound"}
  --code: string # The source code of the action. (default: module.exports = () => {})
  --dependencies: list # The list of third party npm modules, and their versions, that this action depends on. — item shape: {name?: string, version?: string, registry_url?: string}
  --runtime: string # The Node runtime. For example: `node22`, defaults to `node22` (default: node22)
  --secrets: list # The list of secrets that are included in an action or a version of an action. — item shape: {name?: string, value?: string}
  --modules: list # The list of action modules and their versions used by this action. — item shape: {module_id?: string, module_name?: string, module_version_id?: string, module_version_number?: int}
]: any -> record<id: string, name: string, supported_triggers: table<id: string, version: string, status: string, runtimes: list, default_runtime: string, compatible_triggers: list, binding_policy: string>, all_changes_deployed: bool, created_at: string, updated_at: string, code: string, dependencies: table<name: string, version: string, registry_url: string>, runtime: string, secrets: table<name: string, updated_at: string>, deployed_version: record<id: string, action_id: string, code: string, dependencies: list<record>, deployed: bool, runtime: string, secrets: list<record>, status: string, number: float, errors: list<record>, action: record<id: string, name: string, supported_triggers: list, all_changes_deployed: bool, created_at: string, updated_at: string>, built_at: string, created_at: string, updated_at: string, supported_triggers: list<record>, modules: list<record>>, installed_integration_id: string, integration: record<id: string, catalog_id: string, url_slug: string, partner_id: string, name: string, description: string, short_description: string, logo: string, feature_type: string, terms_of_use_url: string, privacy_policy_url: string, public_support_link: string, current_release: record<id: string, trigger: record, semver: record, required_secrets: list, required_configuration: list>, created_at: string, updated_at: string>, status: string, built_at: string, deploy: bool, modules: table<module_id: string, module_name: string, module_version_id: string, module_version_number: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/actions/($id)")
  let body = {name: $name, supported_triggers: $supported_triggers, code: $code, dependencies: $dependencies, runtime: $runtime, secrets: $secrets, modules: $modules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deploy an action
#
# POST /actions/actions/{id}/deploy
# operationId: post_deploy_action
export def "actions-actions-deploy action" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, action_id: string, code: string, dependencies: table<name: string, version: string, registry_url: string>, deployed: bool, runtime: string, secrets: table<name: string, updated_at: string>, status: string, number: float, errors: table<id: string, msg: string, url: string>, action: record<id: string, name: string, supported_triggers: list<record>, all_changes_deployed: bool, created_at: string, updated_at: string>, built_at: string, created_at: string, updated_at: string, supported_triggers: table<id: string, version: string, status: string, runtimes: list, default_runtime: string, compatible_triggers: list, binding_policy: string>, modules: table<module_id: string, module_name: string, module_version_id: string, module_version_number: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/actions/($id)/deploy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test an Action
#
# POST /actions/actions/{id}/test
# operationId: post_test_action
export def "actions-actions-test action" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  payload: record # The payload for the action.
]: any -> record<payload: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/actions/($id)/test")
  let body = {payload: $payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an execution
#
# GET /actions/executions/{id}
# operationId: get_execution
export def "actions-executions execution" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, trigger_id: string, status: string, results: table<action_name: string, error: record, started_at: string, ended_at: string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/executions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Actions Modules
#
# GET /actions/modules
# operationId: get_action_modules
export def "actions-modules modules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Paging is disabled if parameter not sent.
]: nothing -> record<modules: table<id: string, name: string, code: string, dependencies: list, secrets: list, actions_using_module_total: int, all_changes_published: bool, latest_version_number: int, created_at: string, updated_at: string>, total: int, page: int, per_page: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/actions/modules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Actions Module
#
# POST /actions/modules
# operationId: post_action_module
# --secrets item shape: {name: string, value: string}
# --dependencies item shape: {name: string, version: string}
export def "actions-modules module" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the action module.
  code: string # The source code of the action module.
  --secrets: list # The secrets to associate with the action module. — item shape: {name: string, value: string}
  --dependencies: list # The npm dependencies of the action module. — item shape: {name: string, version: string}
  --api-version: string # The API version of the module.
  --publish: oneof<nothing, bool> # Whether to publish the module immediately after creation.
]: any -> record<id: string, name: string, code: string, dependencies: table<name: string, version: string>, secrets: table<name: string, updated_at: string>, actions_using_module_total: int, all_changes_published: bool, latest_version_number: int, created_at: string, updated_at: string, latest_version: record<id: string, version_number: int, code: string, dependencies: list<record>, secrets: list<record>, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/actions/modules")
  let body = {name: $name, code: $code, secrets: $secrets, dependencies: $dependencies, api_version: $api_version, publish: $publish} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific Actions Module by ID
#
# GET /actions/modules/{id}
# operationId: get_action_module
export def "actions-modules module-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, code: string, dependencies: table<name: string, version: string>, secrets: table<name: string, updated_at: string>, actions_using_module_total: int, all_changes_published: bool, latest_version_number: int, created_at: string, updated_at: string, latest_version: record<id: string, version_number: int, code: string, dependencies: list<record>, secrets: list<record>, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/modules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a specific Actions Module by ID
#
# DELETE /actions/modules/{id}
# operationId: delete_action_module
export def "actions-modules module-by-id-1" [
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
  let full_url = (build-url $base $"/actions/modules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a specific Actions Module
#
# PATCH /actions/modules/{id}
# operationId: patch_action_module
# --secrets item shape: {name: string, value: string}
# --dependencies item shape: {name: string, version: string}
export def "actions-modules module-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # The source code of the action module.
  --secrets: list # The secrets to associate with the action module. — item shape: {name: string, value: string}
  --dependencies: list # The npm dependencies of the action module. — item shape: {name: string, version: string}
]: any -> record<id: string, name: string, code: string, dependencies: table<name: string, version: string>, secrets: table<name: string, updated_at: string>, actions_using_module_total: int, all_changes_published: bool, latest_version_number: int, created_at: string, updated_at: string, latest_version: record<id: string, version_number: int, code: string, dependencies: list<record>, secrets: list<record>, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/modules/($id)")
  let body = {code: $code, secrets: $secrets, dependencies: $dependencies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all actions using an Actions Module
#
# GET /actions/modules/{id}/actions
# operationId: get_action_module_actions
export def "actions-modules-actions actions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page.
]: nothing -> record<actions: table<action_id: string, action_name: string, module_version_id: string, module_version_number: int, supported_triggers: list>, total: int, page: int, per_page: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/actions/modules/($id)/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rollback an Actions Module to a previous version
#
# POST /actions/modules/{id}/rollback
# operationId: post_action_module_rollback
export def "actions-modules-rollback rollback" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  module_version_id: string # The unique ID of the module version to roll back to.
]: any -> record<id: string, name: string, code: string, dependencies: table<name: string, version: string>, secrets: table<name: string, updated_at: string>, actions_using_module_total: int, all_changes_published: bool, latest_version_number: int, created_at: string, updated_at: string, latest_version: record<id: string, version_number: int, code: string, dependencies: list<record>, secrets: list<record>, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/modules/($id)/rollback")
  let body = {module_version_id: $module_version_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all versions of an Actions Module
#
# GET /actions/modules/{id}/versions
# operationId: get_action_module_versions
export def "actions-modules-versions versions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Use this field to request a specific page of the list results.
  --per-page: int # The maximum number of results to be returned by the server in a single response. 20 by default.
]: nothing -> record<versions: table<id: string, module_id: string, version_number: int, code: string, secrets: list, dependencies: list, created_at: string>, total: int, page: int, per_page: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/actions/modules/($id)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new version of an Actions Module
#
# POST /actions/modules/{id}/versions
# operationId: post_action_module_version
export def "actions-modules-versions version-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, module_id: string, version_number: int, code: string, secrets: table<name: string, updated_at: string>, dependencies: table<name: string, version: string>, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/modules/($id)/versions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific version of an Actions Module
#
# GET /actions/modules/{id}/versions/{versionId}
# operationId: get_action_module_version
export def "actions-modules-versions version-by-id-versionId" [
  id: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, module_id: string, version_number: int, code: string, secrets: table<name: string, updated_at: string>, dependencies: table<name: string, version: string>, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/modules/($id)/versions/($versionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get triggers
#
# GET /actions/triggers
# operationId: get_triggers
export def "actions-triggers triggers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<triggers: table<id: string, version: string, status: string, runtimes: list, default_runtime: string, compatible_triggers: list, binding_policy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/actions/triggers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get trigger bindings
#
# GET /actions/triggers/{triggerId}/bindings
# operationId: get_bindings
export def "actions-triggers-bindings bindings-by-triggerId" [
  triggerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Use this field to request a specific page of the list results.
  --per-page: int # The maximum number of results to be returned in a single request. 20 by default
]: nothing -> record<total: float, page: float, per_page: float, bindings: table<id: string, trigger_id: string, display_name: string, action: record, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/actions/triggers/($triggerId)/bindings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update trigger bindings
#
# PATCH /actions/triggers/{triggerId}/bindings
# operationId: patch_bindings
export def "actions-triggers-bindings bindings-by-triggerId-1" [
  triggerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bindings: list # The actions that will be bound to this trigger. The order in which they are included will be the order in which they are executed.
]: any -> record<bindings: table<id: string, trigger_id: string, display_name: string, action: record, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/triggers/($triggerId)/bindings")
  let body = {bindings: $bindings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check if an IP address is blocked
#
# GET /anomaly/blocks/ips/{id}
# operationId: get_ips_by_id
export def "anomaly-blocks-ips id-by-id" [
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
  let full_url = (build-url $base $"/anomaly/blocks/ips/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove the blocked IP address
#
# DELETE /anomaly/blocks/ips/{id}
# operationId: delete_ips_by_id
export def "anomaly-blocks-ips id-by-id-1" [
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
  let full_url = (build-url $base $"/anomaly/blocks/ips/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Bot Detection settings
#
# GET /attack-protection/bot-detection
# operationId: get_bot-detection
export def "attack-protection-bot-detection bot-detection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<bot_detection_level: string, challenge_password_policy: string, challenge_passwordless_policy: string, challenge_password_reset_policy: string, allowlist: list<string>, monitoring_mode_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attack-protection/bot-detection")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Bot Detection settings
#
# PATCH /attack-protection/bot-detection
# operationId: patch_bot-detection
export def "attack-protection-bot-detection bot-detection-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bot-detection-level: string@bot-detection-level-completer # The level of bot detection sensitivity
  --challenge-password-policy: string@challenge-password-policy-completer # The policy that defines how often to show CAPTCHA
  --challenge-passwordless-policy: string@challenge-passwordless-policy-completer # The policy that defines how often to show CAPTCHA
  --challenge-password-reset-policy: string@challenge-password-reset-policy-completer # The policy that defines how often to show CAPTCHA
  --allowlist: list # List of IP addresses or CIDR blocks to allowlist
  --monitoring-mode-enabled: oneof<nothing, bool> # Whether monitoring mode is enabled (logs but does not block)
]: any -> record<bot_detection_level: string, challenge_password_policy: string, challenge_passwordless_policy: string, challenge_password_reset_policy: string, allowlist: list<string>, monitoring_mode_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attack-protection/bot-detection")
  let body = {bot_detection_level: $bot_detection_level, challenge_password_policy: $challenge_password_policy, challenge_passwordless_policy: $challenge_passwordless_policy, challenge_password_reset_policy: $challenge_password_reset_policy, allowlist: $allowlist, monitoring_mode_enabled: $monitoring_mode_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Breached Password Detection settings
#
# GET /attack-protection/breached-password-detection
# operationId: get_breached-password-detection
export def "attack-protection-breached-password-detection breached-password-detection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool, shields: list<string>, admin_notification_frequency: list<string>, method: string, stage: record<pre_user_registration: record<shields: list>, pre_change_password: record<shields: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attack-protection/breached-password-detection")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Breached Password Detection settings
#
# PATCH /attack-protection/breached-password-detection
# operationId: patch_breached-password-detection
# --stage shape: {pre-user-registration?: record, pre-change-password?: record}
export def "attack-protection-breached-password-detection breached-password-detection-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: oneof<nothing, bool> # Whether or not breached password detection is active. (default: true)
  --shields: list # Action to take when a breached password is detected during a login.       Possible values: <code>block</code>, <code>user_notification</code>, <code>admin_notification</code>.
  --admin-notification-frequency: list # When "admin_notification" is enabled, determines how often email notifications are sent.         Possible values: <code>immediately</code>, <code>daily</code>, <code>weekly</code>, <code>monthly</code>.
  --method: string@method-completer # The subscription level for breached password detection methods. Use "enhanced" to enable Credential Guard.         Possible values: <code>standard</code>, <code>enhanced</code>. (default: standard)
  --stage: record # shape: {pre-user-registration?: record, pre-change-password?: record}
]: any -> record<enabled: bool, shields: list<string>, admin_notification_frequency: list<string>, method: string, stage: record<pre_user_registration: record<shields: list>, pre_change_password: record<shields: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attack-protection/breached-password-detection")
  let body = {enabled: $enabled, shields: $shields, admin_notification_frequency: $admin_notification_frequency, method: $method, stage: $stage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Brute-force settings
#
# GET /attack-protection/brute-force-protection
# operationId: get_brute-force-protection
export def "attack-protection-brute-force-protection brute-force-protection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool, shields: list<string>, allowlist: list<string>, mode: string, max_attempts: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attack-protection/brute-force-protection")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Brute-force settings
#
# PATCH /attack-protection/brute-force-protection
# operationId: patch_brute-force-protection
export def "attack-protection-brute-force-protection brute-force-protection-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: oneof<nothing, bool> # Whether or not brute force attack protections are active.
  --shields: list # Action to take when a brute force protection threshold is violated.         Possible values: <code>block</code>, <code>user_notification</code>.
  --allowlist: list # List of trusted IP addresses that will not have attack protection enforced against them.
  --mode: string@mode-completer # Account Lockout: Determines whether or not IP address is used when counting failed attempts.           Possible values: <code>count_per_identifier_and_ip</code>, <code>count_per_identifier</code>. (default: count_per_identifier_and_ip)
  --max-attempts: int # Maximum number of unsuccessful attempts. (default: 10)
]: any -> record<enabled: bool, shields: list<string>, allowlist: list<string>, mode: string, max_attempts: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attack-protection/brute-force-protection")
  let body = {enabled: $enabled, shields: $shields, allowlist: $allowlist, mode: $mode, max_attempts: $max_attempts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the CAPTCHA configuration for a tenant
#
# GET /attack-protection/captcha
# operationId: get_captcha
export def "attack-protection-captcha captcha" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active_provider_id: string, arkose: record<site_key: string, fail_open: bool, client_subdomain: string, verify_subdomain: string>, auth_challenge: record<fail_open: bool>, hcaptcha: record<site_key: string>, friendly_captcha: record<site_key: string>, recaptcha_enterprise: record<site_key: string, project_id: string>, recaptcha_v2: record<site_key: string>, simple_captcha: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attack-protection/captcha")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Partial Update for CAPTCHA Configuration
#
# PATCH /attack-protection/captcha
# operationId: patch_captcha
# --arkose shape: {site_key: string, secret: string, client_subdomain?: string, verify_subdomain?: string, fail_open?: bool}
# --auth_challenge shape: {fail_open: bool}
# --hcaptcha shape: {site_key: string, secret: string}
# --friendly_captcha shape: {site_key: string, secret: string}
# --recaptcha_enterprise shape: {site_key: string, api_key: string, project_id: string}
# --recaptcha_v2 shape: {site_key: string, secret: string}
export def "attack-protection-captcha captcha-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active-provider-id: string@active-provider-id-completer # The id of the active provider for the CAPTCHA.
  --arkose: record # shape: {site_key: string, secret: string, client_subdomain?: string, verify_subdomain?: string, fail_open?: bool}
  --auth-challenge: record # shape: {fail_open: bool}
  --hcaptcha: record # shape: {site_key: string, secret: string}
  --friendly-captcha: record # shape: {site_key: string, secret: string}
  --recaptcha-enterprise: record # shape: {site_key: string, api_key: string, project_id: string}
  --recaptcha-v2: record # shape: {site_key: string, secret: string}
  --simple-captcha: record
]: any -> record<active_provider_id: string, arkose: record<site_key: string, fail_open: bool, client_subdomain: string, verify_subdomain: string>, auth_challenge: record<fail_open: bool>, hcaptcha: record<site_key: string>, friendly_captcha: record<site_key: string>, recaptcha_enterprise: record<site_key: string, project_id: string>, recaptcha_v2: record<site_key: string>, simple_captcha: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attack-protection/captcha")
  let body = {active_provider_id: $active_provider_id, arkose: $arkose, auth_challenge: $auth_challenge, hcaptcha: $hcaptcha, friendly_captcha: $friendly_captcha, recaptcha_enterprise: $recaptcha_enterprise, recaptcha_v2: $recaptcha_v2, simple_captcha: $simple_captcha} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Suspicious IP Throttling settings
#
# GET /attack-protection/suspicious-ip-throttling
# operationId: get_suspicious-ip-throttling
export def "attack-protection-suspicious-ip-throttling suspicious-ip-throttling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool, shields: list<string>, allowlist: list<string>, stage: record<pre_login: record<max_attempts: int, rate: int>, pre_user_registration: record<max_attempts: int, rate: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attack-protection/suspicious-ip-throttling")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Suspicious IP Throttling settings
#
# PATCH /attack-protection/suspicious-ip-throttling
# operationId: patch_suspicious-ip-throttling
# --stage shape: {pre-login?: record, pre-user-registration?: record}
export def "attack-protection-suspicious-ip-throttling suspicious-ip-throttling-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: oneof<nothing, bool> # Whether or not suspicious IP throttling attack protections are active.
  --shields: list # Action to take when a suspicious IP throttling threshold is violated.           Possible values: <code>block</code>, <code>admin_notification</code>.
  --allowlist: list # List of trusted IP addresses that will not have attack protection enforced against them.
  --stage: record # Holds per-stage configuration options (max_attempts and rate). — shape: {pre-login?: record, pre-user-registration?: record}
]: any -> record<enabled: bool, shields: list<string>, allowlist: list<string>, stage: record<pre_login: record<max_attempts: int, rate: int>, pre_user_registration: record<max_attempts: int, rate: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attack-protection/suspicious-ip-throttling")
  let body = {enabled: $enabled, shields: $shields, allowlist: $allowlist, stage: $stage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get branding settings
#
# GET /branding
# operationId: get_branding
export def "branding branding" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<colors: record<primary: string, page_background: any>, favicon_url: string, logo_url: string, identifiers: record<login_display: string, otp_autocomplete: bool, phone_display: record<masking: string, formatting: string>>, font: record<url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/branding")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update branding settings
#
# PATCH /branding
# operationId: patch_branding
# --colors shape: {primary?: string, page_background?: any}
# --identifiers shape: {login_display?: "unified"|"separate", otp_autocomplete?: bool, phone_display?: record}
# --font shape: {url?: string}
export def "branding branding-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --colors: record # Custom color settings. (nullable) — shape: {primary?: string, page_background?: any}
  --favicon-url: string # URL for the favicon. Must use HTTPS. (nullable, format: strict-https-uri-or-null)
  --logo-url: string # URL for the logo. Must use HTTPS. (nullable, format: strict-https-uri-or-null)
  --identifiers: record # Identifier input display settings. (nullable) — shape: {login_display?: "unified"|"separate", otp_autocomplete?: bool, phone_display?: record}
  --font: record # Custom font settings. (nullable) — shape: {url?: string}
]: any -> record<colors: record<primary: string, page_background: any>, favicon_url: string, logo_url: string, identifiers: record<login_display: string, otp_autocomplete: bool, phone_display: record<masking: string, formatting: string>>, font: record<url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/branding")
  let body = {colors: $colors, favicon_url: $favicon_url, logo_url: $logo_url, identifiers: $identifiers, font: $font} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of phone providers
#
# GET /branding/phone/providers
# operationId: get_branding_phone_providers
export def "branding-phone-providers providers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --disabled: oneof<nothing, bool> # Whether the provider is enabled (false) or disabled (true).
]: nothing -> record<providers: table<id: string, tenant: string, name: string, channel: string, disabled: bool, configuration: record, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "disabled" $disabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/branding/phone/providers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Configure the phone provider
#
# POST /branding/phone/providers
# operationId: create_phone_provider
# --configuration shape: {default_from?: string, mssid?: string, sid?: string, delivery_methods?: list}
export def "branding-phone-providers provider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string@name-completer # Name of the phone notification provider
  --disabled: oneof<nothing, bool> # Whether the provider is enabled (false) or disabled (true).
  --configuration: record # shape: {default_from?: string, mssid?: string, sid?: string, delivery_methods?: list}
  credentials: any # Provider credentials required to use authenticate to the provider.
]: any -> record<id: string, tenant: string, name: string, channel: string, disabled: bool, configuration: record, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/branding/phone/providers")
  let body = {name: $name, disabled: $disabled, configuration: $configuration, credentials: $credentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a phone provider
#
# GET /branding/phone/providers/{id}
# operationId: get_phone_provider
export def "branding-phone-providers provider-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, tenant: string, name: string, channel: string, disabled: bool, configuration: record, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/branding/phone/providers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a Phone Provider
#
# DELETE /branding/phone/providers/{id}
# operationId: delete_phone_provider
export def "branding-phone-providers provider-by-id-1" [
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
  let full_url = (build-url $base $"/branding/phone/providers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the phone provider
#
# PATCH /branding/phone/providers/{id}
# operationId: update_phone_provider
# --configuration shape: {default_from?: string, mssid?: string, sid?: string, delivery_methods?: list}
export def "branding-phone-providers provider-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string@name-completer # Name of the phone notification provider
  --disabled: oneof<nothing, bool> # Whether the provider is enabled (false) or disabled (true).
  --credentials: any # Provider credentials required to use authenticate to the provider.
  --configuration: record # shape: {default_from?: string, mssid?: string, sid?: string, delivery_methods?: list}
]: any -> record<id: string, tenant: string, name: string, channel: string, disabled: bool, configuration: record, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/branding/phone/providers/($id)")
  let body = {name: $name, disabled: $disabled, credentials: $credentials, configuration: $configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send a test phone notification for the configured provider
#
# POST /branding/phone/providers/{id}/try
# operationId: try_phone_provider
export def "branding-phone-providers-try provider" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-to: string # The recipient phone number to receive a given notification.
  --delivery-method: string@delivery-method-completer # The delivery method for the notification
]: any -> record<code: float, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/branding/phone/providers/($id)/try")
  let body = {to: $body_to, delivery_method: $delivery_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of phone notification templates
#
# GET /branding/phone/templates
# operationId: get_phone_templates
export def "branding-phone-templates templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --disabled: oneof<nothing, bool> # Whether the template is enabled (false) or disabled (true).
]: nothing -> record<templates: table<id: string, channel: string, customizable: bool, tenant: string, content: record, type: string, disabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "disabled" $disabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/branding/phone/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a phone notification template
#
# POST /branding/phone/templates
# operationId: create_phone_template
# --content shape: {syntax?: string, from?: string, body?: record}
export def "branding-phone-templates template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer
  --disabled: oneof<nothing, bool> # Whether the template is enabled (false) or disabled (true). (default: false)
  --content: record # shape: {syntax?: string, from?: string, body?: record}
]: any -> record<id: string, channel: string, customizable: bool, tenant: string, content: record<syntax: string, from: string, body: record<text: string, voice: string>>, type: string, disabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/branding/phone/templates")
  let body = {type: $type, disabled: $disabled, content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a phone notification template
#
# GET /branding/phone/templates/{id}
# operationId: get_phone_template
export def "branding-phone-templates template-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, channel: string, customizable: bool, tenant: string, content: record<syntax: string, from: string, body: record<text: string, voice: string>>, type: string, disabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/branding/phone/templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a phone notification template
#
# DELETE /branding/phone/templates/{id}
# operationId: delete_phone_template
export def "branding-phone-templates template-by-id-1" [
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
  let full_url = (build-url $base $"/branding/phone/templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a phone notification template
#
# PATCH /branding/phone/templates/{id}
# operationId: update_phone_template
# --content shape: {from?: string, body?: record}
export def "branding-phone-templates template-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: record # shape: {from?: string, body?: record}
  --disabled: oneof<nothing, bool> # Whether the template is enabled (false) or disabled (true). (default: false)
]: any -> record<id: string, channel: string, customizable: bool, tenant: string, content: record<syntax: string, from: string, body: record<text: string, voice: string>>, type: string, disabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/branding/phone/templates/($id)")
  let body = {content: $content, disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resets a phone notification template values
#
# PATCH /branding/phone/templates/{id}/reset
# operationId: reset_phone_template
export def "branding-phone-templates-reset template" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<id: string, channel: string, customizable: bool, tenant: string, content: record<syntax: string, from: string, body: record<text: string, voice: string>>, type: string, disabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/branding/phone/templates/($id)/reset")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send a test phone notification for the configured template
#
# POST /branding/phone/templates/{id}/try
# operationId: try_phone_template
export def "branding-phone-templates-try template" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-to: string # Destination of the testing phone notification
  --delivery-method: string@delivery-method-completer # The delivery method for the notification
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/branding/phone/templates/($id)/try")
  let body = {to: $body_to, delivery_method: $delivery_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get template for New Universal Login Experience
#
# GET /branding/templates/universal-login
# operationId: get_universal-login
export def "branding-templates-universal-login universal-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/branding/templates/universal-login")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete template for New Universal Login Experience
#
# DELETE /branding/templates/universal-login
# operationId: delete_universal-login
export def "branding-templates-universal-login universal-login-1" [
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
  let full_url = (build-url $base "/branding/templates/universal-login")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set template for New Universal Login Experience
#
# PUT /branding/templates/universal-login
# operationId: put_universal-login
export def "branding-templates-universal-login universal-login-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --template: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/branding/templates/universal-login")
  let body = {template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create branding theme
#
# POST /branding/themes
# operationId: post_branding_theme
# --borders shape: {button_border_radius: float, button_border_weight: float, buttons_style: "pill"|"rounded"|"sharp", input_border_radius: float, input_border_weight: float, inputs_style: "pill"|"rounded"|"sharp", show_widget_shadow: bool, widget_border_weight: float, widget_corner_radius: float}
# --colors shape: {base_focus_color?: string, base_hover_color?: string, body_text: string, captcha_widget_theme?: "auto"|"dark"|"light", error: string, header: string, icons: string, input_background: string, input_border: string, input_filled_text: string, input_labels_placeholders: string, links_focused_components: string, primary_button: string, primary_button_label: string, read_only_background?: string, secondary_button_border: string, secondary_button_label: string, success: string, widget_background: string, widget_border: string}
# --fonts shape: {body_text: record, buttons_text: record, font_url: string, input_labels: record, links: record, links_style: "normal"|"underlined", reference_text_size: float, subtitle: record, title: record}
# --page_background shape: {background_color: string, background_image_url: string, page_layout: "center"|"left"|"right"}
# --widget shape: {header_text_alignment: "center"|"left"|"right", logo_height: float, logo_position: "center"|"left"|"none"|"right", logo_url: string, social_buttons_layout: "bottom"|"top"}
export def "branding-themes theme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  borders: record # shape: {button_border_radius: float, button_border_weight: float, buttons_style: "pill"|"rounded"|"sharp", input_border_radius: float, input_border_weight: float, inputs_style: "pill"|"rounded"|"sharp", show_widget_shadow: bool, widget_border_weight: float, widget_corner_radius: float}
  colors: record # shape: {base_focus_color?: string, base_hover_color?: string, body_text: string, captcha_widget_theme?: "auto"|"dark"|"light", error: string, header: string, icons: string, input_background: string, input_border: string, input_filled_text: string, input_labels_placeholders: string, links_focused_components: string, primary_button: string, primary_button_label: string, read_only_background?: string, secondary_button_border: string, secondary_button_label: string, success: string, widget_background: string, widget_border: string}
  --displayName: string # Display Name
  fonts: record # shape: {body_text: record, buttons_text: record, font_url: string, input_labels: record, links: record, links_style: "normal"|"underlined", reference_text_size: float, subtitle: record, title: record}
  page_background: record # shape: {background_color: string, background_image_url: string, page_layout: "center"|"left"|"right"}
  widget: record # shape: {header_text_alignment: "center"|"left"|"right", logo_height: float, logo_position: "center"|"left"|"none"|"right", logo_url: string, social_buttons_layout: "bottom"|"top"}
]: any -> record<borders: record<button_border_radius: float, button_border_weight: float, buttons_style: string, input_border_radius: float, input_border_weight: float, inputs_style: string, show_widget_shadow: bool, widget_border_weight: float, widget_corner_radius: float>, colors: record<base_focus_color: string, base_hover_color: string, body_text: string, captcha_widget_theme: string, error: string, header: string, icons: string, input_background: string, input_border: string, input_filled_text: string, input_labels_placeholders: string, links_focused_components: string, primary_button: string, primary_button_label: string, read_only_background: string, secondary_button_border: string, secondary_button_label: string, success: string, widget_background: string, widget_border: string>, displayName: string, fonts: record<body_text: record<bold: bool, size: float>, buttons_text: record<bold: bool, size: float>, font_url: string, input_labels: record<bold: bool, size: float>, links: record<bold: bool, size: float>, links_style: string, reference_text_size: float, subtitle: record<bold: bool, size: float>, title: record<bold: bool, size: float>>, page_background: record<background_color: string, background_image_url: string, page_layout: string>, themeId: string, widget: record<header_text_alignment: string, logo_height: float, logo_position: string, logo_url: string, social_buttons_layout: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/branding/themes")
  let body = {borders: $borders, colors: $colors, displayName: $displayName, fonts: $fonts, page_background: $page_background, widget: $widget} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get default branding theme
#
# GET /branding/themes/default
# operationId: get_default_branding_theme
export def "branding-themes-default theme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<borders: record<button_border_radius: float, button_border_weight: float, buttons_style: string, input_border_radius: float, input_border_weight: float, inputs_style: string, show_widget_shadow: bool, widget_border_weight: float, widget_corner_radius: float>, colors: record<base_focus_color: string, base_hover_color: string, body_text: string, captcha_widget_theme: string, error: string, header: string, icons: string, input_background: string, input_border: string, input_filled_text: string, input_labels_placeholders: string, links_focused_components: string, primary_button: string, primary_button_label: string, read_only_background: string, secondary_button_border: string, secondary_button_label: string, success: string, widget_background: string, widget_border: string>, displayName: string, fonts: record<body_text: record<bold: bool, size: float>, buttons_text: record<bold: bool, size: float>, font_url: string, input_labels: record<bold: bool, size: float>, links: record<bold: bool, size: float>, links_style: string, reference_text_size: float, subtitle: record<bold: bool, size: float>, title: record<bold: bool, size: float>>, page_background: record<background_color: string, background_image_url: string, page_layout: string>, themeId: string, widget: record<header_text_alignment: string, logo_height: float, logo_position: string, logo_url: string, social_buttons_layout: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/branding/themes/default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get branding theme
#
# GET /branding/themes/{themeId}
# operationId: get_branding_theme
export def "branding-themes theme-by-themeId" [
  themeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<borders: record<button_border_radius: float, button_border_weight: float, buttons_style: string, input_border_radius: float, input_border_weight: float, inputs_style: string, show_widget_shadow: bool, widget_border_weight: float, widget_corner_radius: float>, colors: record<base_focus_color: string, base_hover_color: string, body_text: string, captcha_widget_theme: string, error: string, header: string, icons: string, input_background: string, input_border: string, input_filled_text: string, input_labels_placeholders: string, links_focused_components: string, primary_button: string, primary_button_label: string, read_only_background: string, secondary_button_border: string, secondary_button_label: string, success: string, widget_background: string, widget_border: string>, displayName: string, fonts: record<body_text: record<bold: bool, size: float>, buttons_text: record<bold: bool, size: float>, font_url: string, input_labels: record<bold: bool, size: float>, links: record<bold: bool, size: float>, links_style: string, reference_text_size: float, subtitle: record<bold: bool, size: float>, title: record<bold: bool, size: float>>, page_background: record<background_color: string, background_image_url: string, page_layout: string>, themeId: string, widget: record<header_text_alignment: string, logo_height: float, logo_position: string, logo_url: string, social_buttons_layout: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/branding/themes/($themeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete branding theme
#
# DELETE /branding/themes/{themeId}
# operationId: delete_branding_theme
export def "branding-themes theme-by-themeId-1" [
  themeId: string
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
  let full_url = (build-url $base $"/branding/themes/($themeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update branding theme
#
# PATCH /branding/themes/{themeId}
# operationId: patch_branding_theme
# --borders shape: {button_border_radius: float, button_border_weight: float, buttons_style: "pill"|"rounded"|"sharp", input_border_radius: float, input_border_weight: float, inputs_style: "pill"|"rounded"|"sharp", show_widget_shadow: bool, widget_border_weight: float, widget_corner_radius: float}
# --colors shape: {base_focus_color?: string, base_hover_color?: string, body_text: string, captcha_widget_theme?: "auto"|"dark"|"light", error: string, header: string, icons: string, input_background: string, input_border: string, input_filled_text: string, input_labels_placeholders: string, links_focused_components: string, primary_button: string, primary_button_label: string, read_only_background?: string, secondary_button_border: string, secondary_button_label: string, success: string, widget_background: string, widget_border: string}
# --fonts shape: {body_text: record, buttons_text: record, font_url: string, input_labels: record, links: record, links_style: "normal"|"underlined", reference_text_size: float, subtitle: record, title: record}
# --page_background shape: {background_color: string, background_image_url: string, page_layout: "center"|"left"|"right"}
# --widget shape: {header_text_alignment: "center"|"left"|"right", logo_height: float, logo_position: "center"|"left"|"none"|"right", logo_url: string, social_buttons_layout: "bottom"|"top"}
export def "branding-themes theme-by-themeId-2" [
  themeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  borders: record # shape: {button_border_radius: float, button_border_weight: float, buttons_style: "pill"|"rounded"|"sharp", input_border_radius: float, input_border_weight: float, inputs_style: "pill"|"rounded"|"sharp", show_widget_shadow: bool, widget_border_weight: float, widget_corner_radius: float}
  colors: record # shape: {base_focus_color?: string, base_hover_color?: string, body_text: string, captcha_widget_theme?: "auto"|"dark"|"light", error: string, header: string, icons: string, input_background: string, input_border: string, input_filled_text: string, input_labels_placeholders: string, links_focused_components: string, primary_button: string, primary_button_label: string, read_only_background?: string, secondary_button_border: string, secondary_button_label: string, success: string, widget_background: string, widget_border: string}
  --displayName: string # Display Name
  fonts: record # shape: {body_text: record, buttons_text: record, font_url: string, input_labels: record, links: record, links_style: "normal"|"underlined", reference_text_size: float, subtitle: record, title: record}
  page_background: record # shape: {background_color: string, background_image_url: string, page_layout: "center"|"left"|"right"}
  widget: record # shape: {header_text_alignment: "center"|"left"|"right", logo_height: float, logo_position: "center"|"left"|"none"|"right", logo_url: string, social_buttons_layout: "bottom"|"top"}
]: any -> record<borders: record<button_border_radius: float, button_border_weight: float, buttons_style: string, input_border_radius: float, input_border_weight: float, inputs_style: string, show_widget_shadow: bool, widget_border_weight: float, widget_corner_radius: float>, colors: record<base_focus_color: string, base_hover_color: string, body_text: string, captcha_widget_theme: string, error: string, header: string, icons: string, input_background: string, input_border: string, input_filled_text: string, input_labels_placeholders: string, links_focused_components: string, primary_button: string, primary_button_label: string, read_only_background: string, secondary_button_border: string, secondary_button_label: string, success: string, widget_background: string, widget_border: string>, displayName: string, fonts: record<body_text: record<bold: bool, size: float>, buttons_text: record<bold: bool, size: float>, font_url: string, input_labels: record<bold: bool, size: float>, links: record<bold: bool, size: float>, links_style: string, reference_text_size: float, subtitle: record<bold: bool, size: float>, title: record<bold: bool, size: float>>, page_background: record<background_color: string, background_image_url: string, page_layout: string>, themeId: string, widget: record<header_text_alignment: string, logo_height: float, logo_position: string, logo_url: string, social_buttons_layout: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/branding/themes/($themeId)")
  let body = {borders: $borders, colors: $colors, displayName: $displayName, fonts: $fonts, page_background: $page_background, widget: $widget} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get client grants
#
# GET /client-grants
# operationId: get_client-grants
export def "client-grants client-grants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Number of results per page.
  --page: int # Page index of the results to return. First page is 0.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
  --audience: string # Optional filter on audience.
  --client-id: string # Optional filter on client_id.
  --allow-any-organization: oneof<nothing, bool> # Optional filter on allow_any_organization.
  --subject-type: string@subject-type-completer # The type of application access the client grant allows.
  --default-for: string@default-for-completer # Applies this client grant as the default for all clients in the specified group. The only accepted value is <a href="https://auth0.com/docs/get-started/applications/application-access-to-apis-client-grants#default-permissions-for-third-party-applications">`third_party_clients`</a>, which applies the grant to all third-party clients. Per-client grants for the same audience take precedence. Mutually exclusive with `client_id`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "audience" $audience "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "allow_any_organization" $allow_any_organization "scalar") (serialize-qp "subject_type" $subject_type "scalar") (serialize-qp "default_for" $default_for "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/client-grants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create client grant
#
# POST /client-grants
# operationId: post_client-grants
export def "client-grants client-grants-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # ID of the client.
  audience: string # The audience (API identifier) of this client grant
  --default-for: string@default-for-completer # Applies this client grant as the default for all clients in the specified group. The only accepted value is <a href="https://auth0.com/docs/get-started/applications/application-access-to-apis-client-grants#default-permissions-for-third-party-applications">`third_party_clients`</a>, which applies the grant to all third-party clients. Per-client grants for the same audience take precedence. Mutually exclusive with `client_id`.
  --organization-usage: string@organization-usage-completer # Defines whether organizations can be used with client credentials exchanges for this grant.
  --allow-any-organization: oneof<nothing, bool> # If enabled, any organization can be used with this grant. If disabled (default), the grant must be explicitly assigned to the desired organizations. (default: false)
  --scope: list # Scopes allowed for this client grant.
  --subject-type: string@subject-type-completer # The type of application access the client grant allows.
  --authorization-details-types: list # Types of authorization_details allowed for this client grant.
  --allow-all-scopes: oneof<nothing, bool> # If enabled, all scopes configured on the resource server are allowed for this grant.
]: any -> record<id: string, client_id: string, audience: string, scope: list<string>, organization_usage: string, allow_any_organization: bool, default_for: string, is_system: bool, subject_type: string, authorization_details_types: list<string>, allow_all_scopes: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/client-grants")
  let body = {client_id: $client_id, audience: $audience, default_for: $default_for, organization_usage: $organization_usage, allow_any_organization: $allow_any_organization, scope: $scope, subject_type: $subject_type, authorization_details_types: $authorization_details_types, allow_all_scopes: $allow_all_scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get client grant
#
# GET /client-grants/{id}
# operationId: get_client-grant
export def "client-grants client-grant" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, client_id: string, audience: string, scope: list<string>, organization_usage: string, allow_any_organization: bool, default_for: string, is_system: bool, subject_type: string, authorization_details_types: list<string>, allow_all_scopes: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/client-grants/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete client grant
#
# DELETE /client-grants/{id}
# operationId: delete_client-grants_by_id
export def "client-grants id-by-id" [
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
  let full_url = (build-url $base $"/client-grants/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update client grant
#
# PATCH /client-grants/{id}
# operationId: patch_client-grants_by_id
export def "client-grants id-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scope: list # Scopes allowed for this client grant. (nullable)
  --organization-usage: string@organization-usage-completer-1 # Controls how organizations may be used with this grant (nullable)
  --allow-any-organization: oneof<nothing, bool> # Controls allowing any organization to be used with this grant (nullable)
  --authorization-details-types: list # Types of authorization_details allowed for this client grant.
  --allow-all-scopes: oneof<nothing, bool> # If enabled, all scopes configured on the resource server are allowed for this grant. (nullable)
]: any -> record<id: string, client_id: string, audience: string, scope: list<string>, organization_usage: string, allow_any_organization: bool, default_for: string, is_system: bool, subject_type: string, authorization_details_types: list<string>, allow_all_scopes: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/client-grants/($id)")
  let body = {scope: $scope, organization_usage: $organization_usage, allow_any_organization: $allow_any_organization, authorization_details_types: $authorization_details_types, allow_all_scopes: $allow_all_scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the organizations associated to a client grant
#
# GET /client-grants/{id}/organizations
# operationId: get_client-grant-organizations
export def "client-grants-organizations client-grant-organizations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Defaults to 50.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/client-grants/($id)/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get clients
#
# GET /clients
# operationId: get_clients
export def "clients clients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include or exclude (based on value provided for include_fields) in the result. Leave empty to retrieve all fields.
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false).
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Default value is 50, maximum value is 100
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
  --is-global: oneof<nothing, bool> # Optional filter on the global client parameter.
  --is-first-party: oneof<nothing, bool> # Optional filter on whether or not a client is a first-party client.
  --app-type: string # Optional filter by a comma-separated list of application types.
  --external-client-id: string # Optional filter by the <a href="https://www.ietf.org/archive/id/draft-ietf-oauth-client-id-metadata-document-04.html">Client ID Metadata Document</a> URI for CIMD-registered clients.
  --q: string # Advanced Query in <a href="https://lucene.apache.org/core/2_9_4/queryparsersyntax.html">Lucene</a> syntax.<br /><b>Permitted Queries</b>:<br /><ul><li><i>client_grant.organization_id:{organization_id}</i></li><li><i>client_grant.allow_any_organization:true</i></li></ul><b>Additional Restrictions</b>:<br /><ul><li>Cannot be used in combination with other filters</li><li>Requires use of the <i>from</i> and <i>take</i> paging parameters (checkpoint paginatinon)</li><li>Reduced rate limits apply. See <a href="https://auth0.com/docs/troubleshoot/customer-support/operational-policies/rate-limit-policy/rate-limit-configurations/enterprise-public">Rate Limit Configurations</a></li></ul><i><b>Note</b>: Recent updates may not be immediately reflected in query results</i>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "is_global" $is_global "scalar") (serialize-qp "is_first_party" $is_first_party "scalar") (serialize-qp "app_type" $app_type "scalar") (serialize-qp "external_client_id" $external_client_id "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a client
#
# POST /clients
# operationId: post_clients
# --oidc_logout shape: {backchannel_logout_urls?: list, backchannel_logout_initiators?: record, backchannel_logout_session_metadata?: record}
# --oidc_backchannel_logout shape: {backchannel_logout_urls?: list, backchannel_logout_initiators?: record, backchannel_logout_session_metadata?: record}
# --session_transfer shape: {can_create_session_transfer_token?: bool, enforce_cascade_revocation?: bool, allowed_authentication_methods?: list, enforce_device_binding?: "ip"|"asn"|"none", allow_refresh_token?: bool, enforce_online_refresh_tokens?: bool, delegation?: record}
# --jwt_configuration shape: {lifetime_in_seconds?: int, secret_encoded?: bool, scopes?: record, alg?: "HS256"|"RS256"|"RS512"|"PS256"}
# --encryption_key shape: {pub?: string, cert?: string, subject?: string}
# --addons shape: {aws?: record, azure_blob?: record, azure_sb?: record, rms?: record, mscrm?: record, slack?: record, sentry?: record, box?: record, cloudbees?: record, concur?: record, dropbox?: record, echosign?: record, egnyte?: record, firebase?: record, newrelic?: record, office365?: record, salesforce?: record, salesforce_api?: record, salesforce_sandbox_api?: record, samlp?: record, layer?: record, sap_api?: record, sharepoint?: record, springcm?: record, wams?: record, wsfed?: record, zendesk?: record, zoom?: record, sso_integration?: record, oag?: record}
# --mobile shape: {android?: record, ios?: record}
# --native_social_login shape: {apple?: record, facebook?: record, google?: record}
# --refresh_token shape: {rotation_type: "rotating"|"non-rotating", expiration_type: "expiring"|"non-expiring", leeway?: int, token_lifetime?: int, infinite_token_lifetime?: bool, idle_token_lifetime?: int, infinite_idle_token_lifetime?: bool, policies?: list}
# --default_organization shape: {organization_id: string, flows: list}
# --client_authentication_methods shape: {private_key_jwt?: record, tls_client_auth?: record, self_signed_tls_client_auth?: record}
# --signed_request_object shape: {required?: bool, credentials?: list}
# --token_exchange shape: {allow_any_profile_of_type?: list}
# --token_quota shape: {client_credentials: record}
# --express_configuration shape: {initiate_login_uri_template: string, user_attribute_profile_id: string, connection_profile_id: string, enable_client: bool, enable_organization: bool, linked_clients?: list, okta_oin_client_id: string, admin_login_domain: string, oin_submission_id?: string}
# --my_organization_configuration shape: {connection_profile_id?: string, user_attribute_profile_id?: string, allowed_strategies: list, connection_deletion_behavior: "allow"|"allow_if_empty"}
export def "clients clients-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of this client (min length: 1 character, does not allow `<` or `>`).
  --description: string # Free text description of this client (max length: 140 characters).
  --logo-uri: string # URL of the logo to display for this client. Recommended size is 150x150 pixels. (format: absolute-uri-or-empty)
  --callbacks: list # Comma-separated list of URLs whitelisted for Auth0 to use as a callback to the client after authentication.
  --oidc-logout: record # Configuration for OIDC backchannel logout — shape: {backchannel_logout_urls?: list, backchannel_logout_initiators?: record, backchannel_logout_session_metadata?: record}
  --oidc-backchannel-logout: record # Configuration for OIDC backchannel logout — shape: {backchannel_logout_urls?: list, backchannel_logout_initiators?: record, backchannel_logout_session_metadata?: record}
  --session-transfer: record # Native to Web SSO Configuration (nullable) — shape: {can_create_session_transfer_token?: bool, enforce_cascade_revocation?: bool, allowed_authentication_methods?: list, enforce_device_binding?: "ip"|"asn"|"none", allow_refresh_token?: bool, enforce_online_refresh_tokens?: bool, delegation?: record}
  --allowed-origins: list # Comma-separated list of URLs allowed to make requests from JavaScript to Auth0 API (typically used with CORS). By default, all your callback URLs will be allowed. This field allows you to enter other origins if necessary. You can also use wildcards at the subdomain level (e.g., https://*.contoso.com). Query strings and hash information are not taken into account when validating these URLs.
  --web-origins: list # Comma-separated list of allowed origins for use with <a href='https://auth0.com/docs/cross-origin-authentication'>Cross-Origin Authentication</a>, <a href='https://auth0.com/docs/flows/concepts/device-auth'>Device Flow</a>, and <a href='https://auth0.com/docs/protocols/oauth2#how-response-mode-works'>web message response mode</a>.
  --client-aliases: list # List of audiences/realms for SAML protocol. Used by the wsfed addon.
  --allowed-clients: list # List of allow clients and API ids that are allowed to make delegation requests. Empty means all all your clients are allowed.
  --allowed-logout-urls: list # Comma-separated list of URLs that are valid to redirect to after logout from Auth0. Wildcards are allowed for subdomains.
  --grant-types: list # List of grant types supported for this application. Can include `authorization_code`, `implicit`, `refresh_token`, `client_credentials`, `password`, `http://auth0.com/oauth/grant-type/password-realm`, `http://auth0.com/oauth/grant-type/mfa-oob`, `http://auth0.com/oauth/grant-type/mfa-otp`, `http://auth0.com/oauth/grant-type/mfa-recovery-code`, `urn:openid:params:grant-type:ciba`, `urn:ietf:params:oauth:grant-type:device_code`, and `urn:auth0:params:oauth:grant-type:token-exchange:federated-connection-access-token`.
  --token-endpoint-auth-method: string@token-endpoint-auth-method-completer # Defines the requested authentication method for the token endpoint. Can be `none` (public client without a client secret), `client_secret_post` (client uses HTTP POST parameters), or `client_secret_basic` (client uses HTTP Basic). (default: none)
  --is-token-endpoint-ip-header-trusted: oneof<nothing, bool> # If true, trust that the IP specified in the `auth0-forwarded-for` header is the end-user's IP for brute-force-protection on token endpoint. (default: false)
  --app-type: string@app-type-completer # The type of application this client represents
  --is-first-party: oneof<nothing, bool> # Whether this client a first party client or not (default: true)
  --oidc-conformant: oneof<nothing, bool> # Whether this client conforms to <a href='https://auth0.com/docs/api-auth/tutorials/adoption'>strict OIDC specifications</a> (true) or uses legacy features (false). (default: false)
  --jwt-configuration: record # Configuration related to JWTs for the client. — shape: {lifetime_in_seconds?: int, secret_encoded?: bool, scopes?: record, alg?: "HS256"|"RS256"|"RS512"|"PS256"}
  --encryption-key: record # Encryption used for WsFed responses with this client. (nullable) — shape: {pub?: string, cert?: string, subject?: string}
  --sso: oneof<nothing, bool> # Applies only to SSO clients and determines whether Auth0 will handle Single Sign On (true) or whether the Identity Provider will (false).
  --cross-origin-authentication: oneof<nothing, bool> # Whether this client can be used to make cross-origin authentication requests (true) or it is not allowed to make such requests (false). (default: false)
  --cross-origin-loc: string # URL of the location in your site where the cross origin verification takes place for the cross-origin auth flow when performing Auth in your own domain instead of Auth0 hosted login page. (format: url)
  --sso-disabled: oneof<nothing, bool> # <code>true</code> to disable Single Sign On, <code>false</code> otherwise (default: <code>false</code>)
  --custom-login-page-on: oneof<nothing, bool> # <code>true</code> if the custom login page is to be used, <code>false</code> otherwise. Defaults to <code>true</code>
  --custom-login-page: string # The content (HTML, CSS, JS) of the custom login page.
  --custom-login-page-preview: string # The content (HTML, CSS, JS) of the custom login page. (Used on Previews)
  --form-template: string # HTML form template to be used for WS-Federation.
  --addons: record # Addons enabled for this client and their associated configurations. — shape: {aws?: record, azure_blob?: record, azure_sb?: record, rms?: record, mscrm?: record, slack?: record, sentry?: record, box?: record, cloudbees?: record, concur?: record, dropbox?: record, echosign?: record, egnyte?: record, firebase?: record, newrelic?: record, office365?: record, salesforce?: record, salesforce_api?: record, salesforce_sandbox_api?: record, samlp?: record, layer?: record, sap_api?: record, sharepoint?: record, springcm?: record, wams?: record, wsfed?: record, zendesk?: record, zoom?: record, sso_integration?: record, oag?: record}
  --client-metadata: record # Metadata associated with the client, in the form of an object with string values (max 255 chars).  Maximum of 10 metadata properties allowed.  Field names (max 255 chars) are alphanumeric and may only include the following special characters:  :,-+=_*?"/\()<>@	[Tab] [Space]
  --mobile: record # Additional configuration for native mobile apps. — shape: {android?: record, ios?: record}
  --initiate-login-uri: string # Initiate login uri, must be https (format: absolute-https-uri-with-placeholders-or-empty)
  --native-social-login: record # Configure native social settings — shape: {apple?: record, facebook?: record, google?: record}
  --refresh-token: record # Refresh token configuration (nullable) — shape: {rotation_type: "rotating"|"non-rotating", expiration_type: "expiring"|"non-expiring", leeway?: int, token_lifetime?: int, infinite_token_lifetime?: bool, idle_token_lifetime?: int, infinite_idle_token_lifetime?: bool, policies?: list}
  --default-organization: record # Defines the default Organization ID and flows (nullable) — shape: {organization_id: string, flows: list}
  --organization-usage: string@organization-usage-completer # Defines how to proceed during an authentication transaction with regards an organization. Can be `deny` (default), `allow` or `require`. (default: deny)
  --organization-require-behavior: string@organization-require-behavior-completer # Defines how to proceed during an authentication transaction when `client.organization_usage: 'require'`. Can be `no_prompt` (default), `pre_login_prompt` or `post_login_prompt`. `post_login_prompt` requires `oidc_conformant: true`. (default: no_prompt)
  --organization-discovery-methods: list # Defines the available methods for organization discovery during the `pre_login_prompt`. Users can discover their organization either by `email`, `organization_name` or both.
  --client-authentication-methods: record # Defines client authentication methods. — shape: {private_key_jwt?: record, tls_client_auth?: record, self_signed_tls_client_auth?: record}
  --require-pushed-authorization-requests: oneof<nothing, bool> # Makes the use of Pushed Authorization Requests mandatory for this client (default: false)
  --require-proof-of-possession: oneof<nothing, bool> # Makes the use of Proof-of-Possession mandatory for this client (default: false)
  --signed-request-object: record # JWT-secured Authorization Requests (JAR) settings. — shape: {required?: bool, credentials?: list}
  --compliance-level: string@compliance-level-completer # Defines the compliance level for this client, which may restrict it's capabilities (nullable)
  --skip-non-verifiable-callback-uri-confirmation-prompt: oneof<nothing, bool> # Controls whether a confirmation prompt is shown during login flows when the redirect URI uses non-verifiable callback URIs (for example, a custom URI schema such as `myapp://`, or `localhost`). If set to true, a confirmation prompt will not be shown. We recommend that this is set to false for improved protection from malicious apps. See https://auth0.com/docs/secure/security-guidance/measures-against-app-impersonation for more information.
  --token-exchange: record # Configuration for token exchange. — shape: {allow_any_profile_of_type?: list}
  --par-request-expiry: int # Specifies how long, in seconds, a Pushed Authorization Request URI remains valid (nullable)
  --token-quota: record # shape: {client_credentials: record}
  --resource-server-identifier: string # The identifier of the resource server that this client is linked to.
  --third-party-security-mode: string@third-party-security-mode-completer # Security mode for third-party clients. `strict` enforces <a href="https://auth0.com/docs/get-started/applications/third-party-applications/security-controls">enhanced security controls</a>: OAuth 2.1 alignment, explicit API authorization, and a curated set of supported features. `permissive` preserves <a href="https://auth0.com/docs/get-started/applications/third-party-applications/permissive-mode">pre-existing behavior</a> and is only available to tenants with prior third-party client usage. Set on creation and cannot be modified.
  --redirection-policy: string@redirection-policy-completer # Controls whether Auth0 redirects users to the application's callback URL on authentication errors or in email verification flows. `open_redirect_protection` shows an error page instead of redirecting, and hides the callback domain from email templates. `allow_always` enables standard redirect behavior. Defaults to `open_redirect_protection` for third-party clients. Only applies when `is_first_party` is `false` and `third_party_security_mode` is `strict`. To learn more, read <a href="https://auth0.com/docs/get-started/applications/third-party-applications/security-controls#redirect-protection">Redirect protection</a>.
  --express-configuration: record # Application specific configuration for use with the OIN Express Configuration feature. — shape: {initiate_login_uri_template: string, user_attribute_profile_id: string, connection_profile_id: string, enable_client: bool, enable_organization: bool, linked_clients?: list, okta_oin_client_id: string, admin_login_domain: string, oin_submission_id?: string}
  --my-organization-configuration: record # Configuration related to the My Organization Configuration for the client. — shape: {connection_profile_id?: string, user_attribute_profile_id?: string, allowed_strategies: list, connection_deletion_behavior: "allow"|"allow_if_empty"}
  --async-approval-notification-channels: list # Array of notification channels for contacting the user when their approval is required. Valid values are `guardian-push`, `email`.
]: any -> record<client_id: string, tenant: string, name: string, description: string, global: bool, client_secret: string, app_type: string, logo_uri: string, is_first_party: bool, oidc_conformant: bool, callbacks: list<string>, allowed_origins: list<string>, web_origins: list<string>, client_aliases: list<string>, allowed_clients: list<string>, allowed_logout_urls: list<string>, session_transfer: record<can_create_session_transfer_token: bool, enforce_cascade_revocation: bool, allowed_authentication_methods: list<string>, enforce_device_binding: string, allow_refresh_token: bool, enforce_online_refresh_tokens: bool, delegation: record<allow_delegated_access: bool, enforce_device_binding: string>>, oidc_logout: record<backchannel_logout_urls: list<string>, backchannel_logout_initiators: record<mode: string, selected_initiators: list>, backchannel_logout_session_metadata: record<include: bool>>, grant_types: list<string>, jwt_configuration: record<lifetime_in_seconds: int, secret_encoded: bool, scopes: record, alg: string>, signing_keys: table<pkcs7: string, cert: string, subject: string>, encryption_key: record<pub: string, cert: string, subject: string>, sso: bool, sso_disabled: bool, cross_origin_authentication: bool, cross_origin_loc: string, custom_login_page_on: bool, custom_login_page: string, custom_login_page_preview: string, form_template: string, addons: record<aws: record<principal: string, role: string, lifetime_in_seconds: int>, azure_blob: record<accountName: string, storageAccessKey: string, containerName: string, blobName: string, expiration: int, signedIdentifier: string, blob_read: bool, blob_write: bool, blob_delete: bool, container_read: bool, container_write: bool, container_delete: bool, container_list: bool>, azure_sb: record<namespace: string, sasKeyName: string, sasKey: string, entityPath: string, expiration: int>, rms: record<url: string>, mscrm: record<url: string>, slack: record<team: string>, sentry: record<org_slug: string, base_url: string>, box: record, cloudbees: record, concur: record, dropbox: record, echosign: record<domain: string>, egnyte: record<domain: string>, firebase: record<secret: string, private_key_id: string, private_key: string, client_email: string, lifetime_in_seconds: int>, newrelic: record<account: string>, office365: record<domain: string, connection: string>, salesforce: record<entity_id: string>, salesforce_api: record<clientid: string, principal: string, communityName: string, community_url_section: string>, salesforce_sandbox_api: record<clientid: string, principal: string, communityName: string, community_url_section: string>, samlp: record<mappings: record, audience: string, recipient: string, createUpnClaim: bool, mapUnknownClaimsAsIs: bool, passthroughClaimsWithNoMapping: bool, mapIdentities: bool, signatureAlgorithm: string, digestAlgorithm: string, issuer: string, destination: string, lifetimeInSeconds: int, signResponse: bool, nameIdentifierFormat: string, nameIdentifierProbes: list, authnContextClassRef: string>, layer: record<providerId: string, keyId: string, privateKey: string, principal: string, expiration: int>, sap_api: record<clientid: string, usernameAttribute: string, tokenEndpointUrl: string, scope: string, servicePassword: string, nameIdentifierFormat: string>, sharepoint: record<url: string, external_url: any>, springcm: record<acsurl: string>, wams: record<masterkey: string>, wsfed: record, zendesk: record<accountName: string>, zoom: record<account: string>, sso_integration: record<name: string, version: string>, oag: record>, token_endpoint_auth_method: string, is_token_endpoint_ip_header_trusted: bool, client_metadata: record, mobile: record<android: record<app_package_name: string, sha256_cert_fingerprints: list>, ios: record<team_id: string, app_bundle_identifier: string>>, initiate_login_uri: string, native_social_login: any, refresh_token: record<rotation_type: string, expiration_type: string, leeway: int, token_lifetime: int, infinite_token_lifetime: bool, idle_token_lifetime: int, infinite_idle_token_lifetime: bool, policies: list<record>>, default_organization: record<organization_id: string, flows: list<string>>, organization_usage: string, organization_require_behavior: string, organization_discovery_methods: list<string>, client_authentication_methods: record<private_key_jwt: record<credentials: list>, tls_client_auth: record<credentials: list>, self_signed_tls_client_auth: record<credentials: list>>, require_pushed_authorization_requests: bool, require_proof_of_possession: bool, signed_request_object: record<required: bool, credentials: list<record>>, compliance_level: string, skip_non_verifiable_callback_uri_confirmation_prompt: bool, token_exchange: record<allow_any_profile_of_type: list<string>>, par_request_expiry: int, token_quota: record<client_credentials: record<enforce: bool, per_day: int, per_hour: int>>, express_configuration: record<initiate_login_uri_template: string, user_attribute_profile_id: string, connection_profile_id: string, enable_client: bool, enable_organization: bool, linked_clients: list<record>, okta_oin_client_id: string, admin_login_domain: string, oin_submission_id: string>, my_organization_configuration: record<connection_profile_id: string, user_attribute_profile_id: string, allowed_strategies: list<string>, connection_deletion_behavior: string>, third_party_security_mode: string, redirection_policy: string, resource_server_identifier: string, async_approval_notification_channels: list<string>, external_metadata_type: string, external_metadata_created_by: string, external_client_id: string, jwks_uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clients")
  let body = {name: $name, description: $description, logo_uri: $logo_uri, callbacks: $callbacks, oidc_logout: $oidc_logout, oidc_backchannel_logout: $oidc_backchannel_logout, session_transfer: $session_transfer, allowed_origins: $allowed_origins, web_origins: $web_origins, client_aliases: $client_aliases, allowed_clients: $allowed_clients, allowed_logout_urls: $allowed_logout_urls, grant_types: $grant_types, token_endpoint_auth_method: $token_endpoint_auth_method, is_token_endpoint_ip_header_trusted: $is_token_endpoint_ip_header_trusted, app_type: $app_type, is_first_party: $is_first_party, oidc_conformant: $oidc_conformant, jwt_configuration: $jwt_configuration, encryption_key: $encryption_key, sso: $sso, cross_origin_authentication: $cross_origin_authentication, cross_origin_loc: $cross_origin_loc, sso_disabled: $sso_disabled, custom_login_page_on: $custom_login_page_on, custom_login_page: $custom_login_page, custom_login_page_preview: $custom_login_page_preview, form_template: $form_template, addons: $addons, client_metadata: $client_metadata, mobile: $mobile, initiate_login_uri: $initiate_login_uri, native_social_login: $native_social_login, refresh_token: $refresh_token, default_organization: $default_organization, organization_usage: $organization_usage, organization_require_behavior: $organization_require_behavior, organization_discovery_methods: $organization_discovery_methods, client_authentication_methods: $client_authentication_methods, require_pushed_authorization_requests: $require_pushed_authorization_requests, require_proof_of_possession: $require_proof_of_possession, signed_request_object: $signed_request_object, compliance_level: $compliance_level, skip_non_verifiable_callback_uri_confirmation_prompt: $skip_non_verifiable_callback_uri_confirmation_prompt, token_exchange: $token_exchange, par_request_expiry: $par_request_expiry, token_quota: $token_quota, resource_server_identifier: $resource_server_identifier, third_party_security_mode: $third_party_security_mode, redirection_policy: $redirection_policy, express_configuration: $express_configuration, my_organization_configuration: $my_organization_configuration, async_approval_notification_channels: $async_approval_notification_channels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Preview and validate Client ID Metadata Document
#
# POST /clients/cimd/preview
# operationId: post_clients_cimd_preview
export def "clients-cimd-preview preview" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  external_client_id: string # URL to the Client ID Metadata Document (format: absolute-https-uri-or-empty)
]: any -> record<client_id: string, errors: list<string>, validation: record<valid: bool, violations: list<string>, warnings: list<string>>, mapped_fields: record<external_client_id: string, name: string, app_type: string, callbacks: list<string>, logo_uri: string, description: string, grant_types: list<string>, token_endpoint_auth_method: string, jwks_uri: string, client_authentication_methods: record<private_key_jwt: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clients/cimd/preview")
  let body = {external_client_id: $external_client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Register or update a CIMD client via metadata URI
#
# POST /clients/cimd/register
# operationId: post_clients_cimd_register
export def "clients-cimd-register register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  external_client_id: string # URL to the Client ID Metadata Document. Acts as the unique identifier for upsert operations. (format: absolute-https-uri-or-empty)
]: any -> record<client_id: string, mapped_fields: record<external_client_id: string, name: string, app_type: string, callbacks: list<string>, logo_uri: string, description: string, grant_types: list<string>, token_endpoint_auth_method: string, jwks_uri: string, client_authentication_methods: record<private_key_jwt: record>>, validation: record<valid: bool, violations: list<string>, warnings: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clients/cimd/register")
  let body = {external_client_id: $external_client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get client credentials
#
# GET /clients/{client_id}/credentials
# operationId: get_credentials
export def "clients-credentials credentials-by-client_id" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, name: string, kid: string, alg: string, credential_type: string, subject_dn: string, thumbprint_sha256: string, created_at: string, updated_at: string, expires_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/clients/($client_id)/credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a client credential
#
# POST /clients/{client_id}/credentials
# operationId: post_credentials
export def "clients-credentials credentials-by-client_id-1" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  credential_type: string@credential-type-completer # The type of credential.
  --name: string # Friendly name for a credential. (default: )
  --subject-dn: string # Subject Distinguished Name. Mutually exclusive with `pem` property. Applies to `cert_subject_dn` credential type.
  --pem: string # PEM-formatted public key (SPKI and PKCS1) or X509 certificate. Must be JSON escaped. (default: -----BEGIN PUBLIC KEY----- MIIBIjANBg... -----END PUBLIC KEY----- )
  --alg: string@alg-completer # Algorithm which will be used with the credential. Can be one of RS256, RS384, PS256. If not specified, RS256 will be used. Applies to `public_key` credential type. (default: RS256)
  --parse-expiry-from-cert: oneof<nothing, bool> # Parse expiry from x509 certificate. If true, attempts to parse the expiry date from the provided PEM. Applies to `public_key` credential type. (default: false)
  --expires-at: string # The ISO 8601 formatted date representing the expiration of the credential. If not specified (not recommended), the credential never expires. Applies to `public_key` credential type. (format: date-time, default: 2023-02-07T12:40:17.807Z)
  --kid: string # Optional kid (Key ID), used to uniquely identify the credential. If not specified, a kid value will be auto-generated. The kid header parameter in JWTs sent by your client should match this value. Valid format is [0-9a-zA-Z-_]{10,64}
]: any -> record<id: string, name: string, kid: string, alg: string, credential_type: string, subject_dn: string, thumbprint_sha256: string, created_at: string, updated_at: string, expires_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/clients/($client_id)/credentials")
  let body = {credential_type: $credential_type, name: $name, subject_dn: $subject_dn, pem: $pem, alg: $alg, parse_expiry_from_cert: $parse_expiry_from_cert, expires_at: $expires_at, kid: $kid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get client credential details
#
# GET /clients/{client_id}/credentials/{credential_id}
# operationId: get_credentials_by_credential_id
export def "clients-credentials id-by-client_id-credential_id" [
  client_id: string
  credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, kid: string, alg: string, credential_type: string, subject_dn: string, thumbprint_sha256: string, created_at: string, updated_at: string, expires_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/clients/($client_id)/credentials/($credential_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a client credential
#
# DELETE /clients/{client_id}/credentials/{credential_id}
# operationId: delete_credentials_by_credential_id
export def "clients-credentials id-by-client_id-credential_id-1" [
  client_id: string
  credential_id: string
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
  let full_url = (build-url $base $"/clients/($client_id)/credentials/($credential_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a client credential
#
# PATCH /clients/{client_id}/credentials/{credential_id}
# operationId: patch_credentials_by_credential_id
export def "clients-credentials id-by-client_id-credential_id-2" [
  client_id: string
  credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expires-at: string # The ISO 8601 formatted date representing the expiration of the credential. (nullable, format: date-time)
]: any -> record<id: string, name: string, kid: string, alg: string, credential_type: string, subject_dn: string, thumbprint_sha256: string, created_at: string, updated_at: string, expires_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/clients/($client_id)/credentials/($credential_id)")
  let body = {expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get client by ID
#
# GET /clients/{id}
# operationId: get_clients_by_id
export def "clients id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include or exclude (based on value provided for include_fields) in the result. Leave empty to retrieve all fields.
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false).
]: nothing -> record<client_id: string, tenant: string, name: string, description: string, global: bool, client_secret: string, app_type: string, logo_uri: string, is_first_party: bool, oidc_conformant: bool, callbacks: list<string>, allowed_origins: list<string>, web_origins: list<string>, client_aliases: list<string>, allowed_clients: list<string>, allowed_logout_urls: list<string>, session_transfer: record<can_create_session_transfer_token: bool, enforce_cascade_revocation: bool, allowed_authentication_methods: list<string>, enforce_device_binding: string, allow_refresh_token: bool, enforce_online_refresh_tokens: bool, delegation: record<allow_delegated_access: bool, enforce_device_binding: string>>, oidc_logout: record<backchannel_logout_urls: list<string>, backchannel_logout_initiators: record<mode: string, selected_initiators: list>, backchannel_logout_session_metadata: record<include: bool>>, grant_types: list<string>, jwt_configuration: record<lifetime_in_seconds: int, secret_encoded: bool, scopes: record, alg: string>, signing_keys: table<pkcs7: string, cert: string, subject: string>, encryption_key: record<pub: string, cert: string, subject: string>, sso: bool, sso_disabled: bool, cross_origin_authentication: bool, cross_origin_loc: string, custom_login_page_on: bool, custom_login_page: string, custom_login_page_preview: string, form_template: string, addons: record<aws: record<principal: string, role: string, lifetime_in_seconds: int>, azure_blob: record<accountName: string, storageAccessKey: string, containerName: string, blobName: string, expiration: int, signedIdentifier: string, blob_read: bool, blob_write: bool, blob_delete: bool, container_read: bool, container_write: bool, container_delete: bool, container_list: bool>, azure_sb: record<namespace: string, sasKeyName: string, sasKey: string, entityPath: string, expiration: int>, rms: record<url: string>, mscrm: record<url: string>, slack: record<team: string>, sentry: record<org_slug: string, base_url: string>, box: record, cloudbees: record, concur: record, dropbox: record, echosign: record<domain: string>, egnyte: record<domain: string>, firebase: record<secret: string, private_key_id: string, private_key: string, client_email: string, lifetime_in_seconds: int>, newrelic: record<account: string>, office365: record<domain: string, connection: string>, salesforce: record<entity_id: string>, salesforce_api: record<clientid: string, principal: string, communityName: string, community_url_section: string>, salesforce_sandbox_api: record<clientid: string, principal: string, communityName: string, community_url_section: string>, samlp: record<mappings: record, audience: string, recipient: string, createUpnClaim: bool, mapUnknownClaimsAsIs: bool, passthroughClaimsWithNoMapping: bool, mapIdentities: bool, signatureAlgorithm: string, digestAlgorithm: string, issuer: string, destination: string, lifetimeInSeconds: int, signResponse: bool, nameIdentifierFormat: string, nameIdentifierProbes: list, authnContextClassRef: string>, layer: record<providerId: string, keyId: string, privateKey: string, principal: string, expiration: int>, sap_api: record<clientid: string, usernameAttribute: string, tokenEndpointUrl: string, scope: string, servicePassword: string, nameIdentifierFormat: string>, sharepoint: record<url: string, external_url: any>, springcm: record<acsurl: string>, wams: record<masterkey: string>, wsfed: record, zendesk: record<accountName: string>, zoom: record<account: string>, sso_integration: record<name: string, version: string>, oag: record>, token_endpoint_auth_method: string, is_token_endpoint_ip_header_trusted: bool, client_metadata: record, mobile: record<android: record<app_package_name: string, sha256_cert_fingerprints: list>, ios: record<team_id: string, app_bundle_identifier: string>>, initiate_login_uri: string, native_social_login: any, refresh_token: record<rotation_type: string, expiration_type: string, leeway: int, token_lifetime: int, infinite_token_lifetime: bool, idle_token_lifetime: int, infinite_idle_token_lifetime: bool, policies: list<record>>, default_organization: record<organization_id: string, flows: list<string>>, organization_usage: string, organization_require_behavior: string, organization_discovery_methods: list<string>, client_authentication_methods: record<private_key_jwt: record<credentials: list>, tls_client_auth: record<credentials: list>, self_signed_tls_client_auth: record<credentials: list>>, require_pushed_authorization_requests: bool, require_proof_of_possession: bool, signed_request_object: record<required: bool, credentials: list<record>>, compliance_level: string, skip_non_verifiable_callback_uri_confirmation_prompt: bool, token_exchange: record<allow_any_profile_of_type: list<string>>, par_request_expiry: int, token_quota: record<client_credentials: record<enforce: bool, per_day: int, per_hour: int>>, express_configuration: record<initiate_login_uri_template: string, user_attribute_profile_id: string, connection_profile_id: string, enable_client: bool, enable_organization: bool, linked_clients: list<record>, okta_oin_client_id: string, admin_login_domain: string, oin_submission_id: string>, my_organization_configuration: record<connection_profile_id: string, user_attribute_profile_id: string, allowed_strategies: list<string>, connection_deletion_behavior: string>, third_party_security_mode: string, redirection_policy: string, resource_server_identifier: string, async_approval_notification_channels: list<string>, external_metadata_type: string, external_metadata_created_by: string, external_client_id: string, jwks_uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/clients/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a client
#
# DELETE /clients/{id}
# operationId: delete_clients_by_id
export def "clients id-by-id-1" [
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
  let full_url = (build-url $base $"/clients/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a client
#
# PATCH /clients/{id}
# operationId: patch_clients_by_id
# --oidc_logout shape: {backchannel_logout_urls?: list, backchannel_logout_initiators?: record, backchannel_logout_session_metadata?: record}
# --oidc_backchannel_logout shape: {backchannel_logout_urls?: list, backchannel_logout_initiators?: record, backchannel_logout_session_metadata?: record}
# --session_transfer shape: {can_create_session_transfer_token?: bool, enforce_cascade_revocation?: bool, allowed_authentication_methods?: list, enforce_device_binding?: "ip"|"asn"|"none", allow_refresh_token?: bool, enforce_online_refresh_tokens?: bool, delegation?: record}
# --jwt_configuration shape: {lifetime_in_seconds?: int, secret_encoded?: bool, scopes?: record, alg?: "HS256"|"RS256"|"RS512"|"PS256"}
# --encryption_key shape: {pub?: string, cert?: string, subject?: string}
# --token_quota shape: {client_credentials: record}
# --addons shape: {aws?: record, azure_blob?: record, azure_sb?: record, rms?: record, mscrm?: record, slack?: record, sentry?: record, box?: record, cloudbees?: record, concur?: record, dropbox?: record, echosign?: record, egnyte?: record, firebase?: record, newrelic?: record, office365?: record, salesforce?: record, salesforce_api?: record, salesforce_sandbox_api?: record, samlp?: record, layer?: record, sap_api?: record, sharepoint?: record, springcm?: record, wams?: record, wsfed?: record, zendesk?: record, zoom?: record, sso_integration?: record, oag?: record}
# --mobile shape: {android?: record, ios?: record}
# --native_social_login shape: {apple?: record, facebook?: record, google?: record}
# --refresh_token shape: {rotation_type: "rotating"|"non-rotating", expiration_type: "expiring"|"non-expiring", leeway?: int, token_lifetime?: int, infinite_token_lifetime?: bool, idle_token_lifetime?: int, infinite_idle_token_lifetime?: bool, policies?: list}
# --default_organization shape: {organization_id: string, flows: list}
# --client_authentication_methods shape: {private_key_jwt?: record, tls_client_auth?: record, self_signed_tls_client_auth?: record}
# --signed_request_object shape: {required?: bool, credentials?: list}
# --token_exchange shape: {allow_any_profile_of_type?: list}
# --express_configuration shape: {initiate_login_uri_template: string, user_attribute_profile_id: string, connection_profile_id: string, enable_client: bool, enable_organization: bool, linked_clients?: list, okta_oin_client_id: string, admin_login_domain: string, oin_submission_id?: string}
# --my_organization_configuration shape: {connection_profile_id?: string, user_attribute_profile_id?: string, allowed_strategies: list, connection_deletion_behavior: "allow"|"allow_if_empty"}
export def "clients id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the client. Must contain at least one character. Does not allow '<' or '>'.
  --description: string # Free text description of the purpose of the Client. (Max character length: <code>140</code>)
  --client-secret: string # The secret used to sign tokens for the client
  --logo-uri: string # The URL of the client logo (recommended size: 150x150) (format: absolute-uri-or-empty)
  --callbacks: list # A set of URLs that are valid to call back from Auth0 when authenticating users
  --oidc-logout: record # Configuration for OIDC backchannel logout — shape: {backchannel_logout_urls?: list, backchannel_logout_initiators?: record, backchannel_logout_session_metadata?: record}
  --oidc-backchannel-logout: record # Configuration for OIDC backchannel logout — shape: {backchannel_logout_urls?: list, backchannel_logout_initiators?: record, backchannel_logout_session_metadata?: record}
  --session-transfer: record # Native to Web SSO Configuration (nullable) — shape: {can_create_session_transfer_token?: bool, enforce_cascade_revocation?: bool, allowed_authentication_methods?: list, enforce_device_binding?: "ip"|"asn"|"none", allow_refresh_token?: bool, enforce_online_refresh_tokens?: bool, delegation?: record}
  --allowed-origins: list # A set of URLs that represents valid origins for CORS
  --web-origins: list # A set of URLs that represents valid web origins for use with web message response mode
  --grant-types: list # A set of grant types that the client is authorized to use. Can include `authorization_code`, `implicit`, `refresh_token`, `client_credentials`, `password`, `http://auth0.com/oauth/grant-type/password-realm`, `http://auth0.com/oauth/grant-type/mfa-oob`, `http://auth0.com/oauth/grant-type/mfa-otp`, `http://auth0.com/oauth/grant-type/mfa-recovery-code`, `urn:openid:params:grant-type:ciba`, `urn:ietf:params:oauth:grant-type:device_code`, and `urn:auth0:params:oauth:grant-type:token-exchange:federated-connection-access-token`.
  --client-aliases: list # List of audiences for SAML protocol
  --allowed-clients: list # Ids of clients that will be allowed to perform delegation requests. Clients that will be allowed to make delegation request. By default, all your clients will be allowed. This field allows you to specify specific clients
  --allowed-logout-urls: list # URLs that are valid to redirect to after logout from Auth0
  --jwt-configuration: record # Configuration related to JWTs for the client. — shape: {lifetime_in_seconds?: int, secret_encoded?: bool, scopes?: record, alg?: "HS256"|"RS256"|"RS512"|"PS256"}
  --encryption-key: record # Encryption used for WsFed responses with this client. (nullable) — shape: {pub?: string, cert?: string, subject?: string}
  --sso: oneof<nothing, bool> # <code>true</code> to use Auth0 instead of the IdP to do Single Sign On, <code>false</code> otherwise (default: <code>false</code>)
  --cross-origin-authentication: oneof<nothing, bool> # <code>true</code> if this client can be used to make cross-origin authentication requests, <code>false</code> otherwise if cross origin is disabled
  --cross-origin-loc: string # URL for the location in your site where the cross origin verification takes place for the cross-origin auth flow when performing Auth in your own domain instead of Auth0 hosted login page. (nullable, format: url-or-null)
  --sso-disabled: oneof<nothing, bool> # <code>true</code> to disable Single Sign On, <code>false</code> otherwise (default: <code>false</code>)
  --custom-login-page-on: oneof<nothing, bool> # <code>true</code> if the custom login page is to be used, <code>false</code> otherwise.
  --token-endpoint-auth-method: string@token-endpoint-auth-method-completer-1 # Defines the requested authentication method for the token endpoint. Can be `none` (public client without a client secret), `client_secret_post` (client uses HTTP POST parameters), or `client_secret_basic` (client uses HTTP Basic). (nullable, default: none)
  --is-token-endpoint-ip-header-trusted: oneof<nothing, bool> # If true, trust that the IP specified in the `auth0-forwarded-for` header is the end-user's IP for brute-force-protection on token endpoint. (default: false)
  --app-type: string@app-type-completer # The type of application this client represents
  --is-first-party: oneof<nothing, bool> # Whether this client a first party client or not (default: true)
  --oidc-conformant: oneof<nothing, bool> # Whether this client will conform to strict OIDC specifications (default: false)
  --custom-login-page: string # The content (HTML, CSS, JS) of the custom login page
  --custom-login-page-preview: string
  --token-quota: record # nullable — shape: {client_credentials: record}
  --form-template: string # Form template for WS-Federation protocol
  --addons: record # Addons enabled for this client and their associated configurations. — shape: {aws?: record, azure_blob?: record, azure_sb?: record, rms?: record, mscrm?: record, slack?: record, sentry?: record, box?: record, cloudbees?: record, concur?: record, dropbox?: record, echosign?: record, egnyte?: record, firebase?: record, newrelic?: record, office365?: record, salesforce?: record, salesforce_api?: record, salesforce_sandbox_api?: record, samlp?: record, layer?: record, sap_api?: record, sharepoint?: record, springcm?: record, wams?: record, wsfed?: record, zendesk?: record, zoom?: record, sso_integration?: record, oag?: record}
  --client-metadata: record # Metadata associated with the client, in the form of an object with string values (max 255 chars).  Maximum of 10 metadata properties allowed.  Field names (max 255 chars) are alphanumeric and may only include the following special characters:  :,-+=_*?"/\()<>@	[Tab] [Space]
  --mobile: record # Additional configuration for native mobile apps. — shape: {android?: record, ios?: record}
  --initiate-login-uri: string # Initiate login uri, must be https (format: absolute-https-uri-with-placeholders-or-empty)
  --native-social-login: record # Configure native social settings — shape: {apple?: record, facebook?: record, google?: record}
  --refresh-token: record # Refresh token configuration (nullable) — shape: {rotation_type: "rotating"|"non-rotating", expiration_type: "expiring"|"non-expiring", leeway?: int, token_lifetime?: int, infinite_token_lifetime?: bool, idle_token_lifetime?: int, infinite_idle_token_lifetime?: bool, policies?: list}
  --default-organization: record # Defines the default Organization ID and flows (nullable) — shape: {organization_id: string, flows: list}
  --organization-usage: string@organization-usage-completer-1 # Defines how to proceed during an authentication transaction with regards an organization. Can be `deny` (default), `allow` or `require`. (nullable, default: deny)
  --organization-require-behavior: string@organization-require-behavior-completer-1 # Defines how to proceed during an authentication transaction when `client.organization_usage: 'require'`. Can be `no_prompt` (default), `pre_login_prompt` or `post_login_prompt`. `post_login_prompt` requires `oidc_conformant: true`. (nullable, default: no_prompt)
  --organization-discovery-methods: list # Defines the available methods for organization discovery during the `pre_login_prompt`. Users can discover their organization either by `email`, `organization_name` or both. (nullable)
  --client-authentication-methods: record # Defines client authentication methods. (nullable) — shape: {private_key_jwt?: record, tls_client_auth?: record, self_signed_tls_client_auth?: record}
  --require-pushed-authorization-requests: oneof<nothing, bool> # Makes the use of Pushed Authorization Requests mandatory for this client (default: false)
  --require-proof-of-possession: oneof<nothing, bool> # Makes the use of Proof-of-Possession mandatory for this client (default: false)
  --signed-request-object: record # JWT-secured Authorization Requests (JAR) settings. — shape: {required?: bool, credentials?: list}
  --compliance-level: string@compliance-level-completer # Defines the compliance level for this client, which may restrict it's capabilities (nullable)
  --skip-non-verifiable-callback-uri-confirmation-prompt: oneof<nothing, bool> # Controls whether a confirmation prompt is shown during login flows when the redirect URI uses non-verifiable callback URIs (for example, a custom URI schema such as `myapp://`, or `localhost`). If set to true, a confirmation prompt will not be shown. We recommend that this is set to false for improved protection from malicious apps. See https://auth0.com/docs/secure/security-guidance/measures-against-app-impersonation for more information. (nullable)
  --token-exchange: record # Configuration for token exchange. (nullable) — shape: {allow_any_profile_of_type?: list}
  --par-request-expiry: int # Specifies how long, in seconds, a Pushed Authorization Request URI remains valid (nullable)
  --express-configuration: record # Application specific configuration for use with the OIN Express Configuration feature. (nullable) — shape: {initiate_login_uri_template: string, user_attribute_profile_id: string, connection_profile_id: string, enable_client: bool, enable_organization: bool, linked_clients?: list, okta_oin_client_id: string, admin_login_domain: string, oin_submission_id?: string}
  --my-organization-configuration: record # Configuration related to the My Organization Configuration for the client. (nullable) — shape: {connection_profile_id?: string, user_attribute_profile_id?: string, allowed_strategies: list, connection_deletion_behavior: "allow"|"allow_if_empty"}
  --async-approval-notification-channels: list # Array of notification channels for contacting the user when their approval is required. Valid values are `guardian-push`, `email`. (nullable)
  --third-party-security-mode: string@third-party-security-mode-completer # Security mode for third-party clients. `strict` enforces <a href="https://auth0.com/docs/get-started/applications/third-party-applications/security-controls">enhanced security controls</a>: OAuth 2.1 alignment, explicit API authorization, and a curated set of supported features. `permissive` preserves <a href="https://auth0.com/docs/get-started/applications/third-party-applications/permissive-mode">pre-existing behavior</a> and is only available to tenants with prior third-party client usage. Set on creation and cannot be modified.
  --redirection-policy: string@redirection-policy-completer # Controls whether Auth0 redirects users to the application's callback URL on authentication errors or in email verification flows. `open_redirect_protection` shows an error page instead of redirecting, and hides the callback domain from email templates. `allow_always` enables standard redirect behavior. Defaults to `open_redirect_protection` for third-party clients. Only applies when `is_first_party` is `false` and `third_party_security_mode` is `strict`. To learn more, read <a href="https://auth0.com/docs/get-started/applications/third-party-applications/security-controls#redirect-protection">Redirect protection</a>.
]: any -> record<client_id: string, tenant: string, name: string, description: string, global: bool, client_secret: string, app_type: string, logo_uri: string, is_first_party: bool, oidc_conformant: bool, callbacks: list<string>, allowed_origins: list<string>, web_origins: list<string>, client_aliases: list<string>, allowed_clients: list<string>, allowed_logout_urls: list<string>, session_transfer: record<can_create_session_transfer_token: bool, enforce_cascade_revocation: bool, allowed_authentication_methods: list<string>, enforce_device_binding: string, allow_refresh_token: bool, enforce_online_refresh_tokens: bool, delegation: record<allow_delegated_access: bool, enforce_device_binding: string>>, oidc_logout: record<backchannel_logout_urls: list<string>, backchannel_logout_initiators: record<mode: string, selected_initiators: list>, backchannel_logout_session_metadata: record<include: bool>>, grant_types: list<string>, jwt_configuration: record<lifetime_in_seconds: int, secret_encoded: bool, scopes: record, alg: string>, signing_keys: table<pkcs7: string, cert: string, subject: string>, encryption_key: record<pub: string, cert: string, subject: string>, sso: bool, sso_disabled: bool, cross_origin_authentication: bool, cross_origin_loc: string, custom_login_page_on: bool, custom_login_page: string, custom_login_page_preview: string, form_template: string, addons: record<aws: record<principal: string, role: string, lifetime_in_seconds: int>, azure_blob: record<accountName: string, storageAccessKey: string, containerName: string, blobName: string, expiration: int, signedIdentifier: string, blob_read: bool, blob_write: bool, blob_delete: bool, container_read: bool, container_write: bool, container_delete: bool, container_list: bool>, azure_sb: record<namespace: string, sasKeyName: string, sasKey: string, entityPath: string, expiration: int>, rms: record<url: string>, mscrm: record<url: string>, slack: record<team: string>, sentry: record<org_slug: string, base_url: string>, box: record, cloudbees: record, concur: record, dropbox: record, echosign: record<domain: string>, egnyte: record<domain: string>, firebase: record<secret: string, private_key_id: string, private_key: string, client_email: string, lifetime_in_seconds: int>, newrelic: record<account: string>, office365: record<domain: string, connection: string>, salesforce: record<entity_id: string>, salesforce_api: record<clientid: string, principal: string, communityName: string, community_url_section: string>, salesforce_sandbox_api: record<clientid: string, principal: string, communityName: string, community_url_section: string>, samlp: record<mappings: record, audience: string, recipient: string, createUpnClaim: bool, mapUnknownClaimsAsIs: bool, passthroughClaimsWithNoMapping: bool, mapIdentities: bool, signatureAlgorithm: string, digestAlgorithm: string, issuer: string, destination: string, lifetimeInSeconds: int, signResponse: bool, nameIdentifierFormat: string, nameIdentifierProbes: list, authnContextClassRef: string>, layer: record<providerId: string, keyId: string, privateKey: string, principal: string, expiration: int>, sap_api: record<clientid: string, usernameAttribute: string, tokenEndpointUrl: string, scope: string, servicePassword: string, nameIdentifierFormat: string>, sharepoint: record<url: string, external_url: any>, springcm: record<acsurl: string>, wams: record<masterkey: string>, wsfed: record, zendesk: record<accountName: string>, zoom: record<account: string>, sso_integration: record<name: string, version: string>, oag: record>, token_endpoint_auth_method: string, is_token_endpoint_ip_header_trusted: bool, client_metadata: record, mobile: record<android: record<app_package_name: string, sha256_cert_fingerprints: list>, ios: record<team_id: string, app_bundle_identifier: string>>, initiate_login_uri: string, native_social_login: any, refresh_token: record<rotation_type: string, expiration_type: string, leeway: int, token_lifetime: int, infinite_token_lifetime: bool, idle_token_lifetime: int, infinite_idle_token_lifetime: bool, policies: list<record>>, default_organization: record<organization_id: string, flows: list<string>>, organization_usage: string, organization_require_behavior: string, organization_discovery_methods: list<string>, client_authentication_methods: record<private_key_jwt: record<credentials: list>, tls_client_auth: record<credentials: list>, self_signed_tls_client_auth: record<credentials: list>>, require_pushed_authorization_requests: bool, require_proof_of_possession: bool, signed_request_object: record<required: bool, credentials: list<record>>, compliance_level: string, skip_non_verifiable_callback_uri_confirmation_prompt: bool, token_exchange: record<allow_any_profile_of_type: list<string>>, par_request_expiry: int, token_quota: record<client_credentials: record<enforce: bool, per_day: int, per_hour: int>>, express_configuration: record<initiate_login_uri_template: string, user_attribute_profile_id: string, connection_profile_id: string, enable_client: bool, enable_organization: bool, linked_clients: list<record>, okta_oin_client_id: string, admin_login_domain: string, oin_submission_id: string>, my_organization_configuration: record<connection_profile_id: string, user_attribute_profile_id: string, allowed_strategies: list<string>, connection_deletion_behavior: string>, third_party_security_mode: string, redirection_policy: string, resource_server_identifier: string, async_approval_notification_channels: list<string>, external_metadata_type: string, external_metadata_created_by: string, external_client_id: string, jwks_uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/clients/($id)")
  let body = {name: $name, description: $description, client_secret: $client_secret, logo_uri: $logo_uri, callbacks: $callbacks, oidc_logout: $oidc_logout, oidc_backchannel_logout: $oidc_backchannel_logout, session_transfer: $session_transfer, allowed_origins: $allowed_origins, web_origins: $web_origins, grant_types: $grant_types, client_aliases: $client_aliases, allowed_clients: $allowed_clients, allowed_logout_urls: $allowed_logout_urls, jwt_configuration: $jwt_configuration, encryption_key: $encryption_key, sso: $sso, cross_origin_authentication: $cross_origin_authentication, cross_origin_loc: $cross_origin_loc, sso_disabled: $sso_disabled, custom_login_page_on: $custom_login_page_on, token_endpoint_auth_method: $token_endpoint_auth_method, is_token_endpoint_ip_header_trusted: $is_token_endpoint_ip_header_trusted, app_type: $app_type, is_first_party: $is_first_party, oidc_conformant: $oidc_conformant, custom_login_page: $custom_login_page, custom_login_page_preview: $custom_login_page_preview, token_quota: $token_quota, form_template: $form_template, addons: $addons, client_metadata: $client_metadata, mobile: $mobile, initiate_login_uri: $initiate_login_uri, native_social_login: $native_social_login, refresh_token: $refresh_token, default_organization: $default_organization, organization_usage: $organization_usage, organization_require_behavior: $organization_require_behavior, organization_discovery_methods: $organization_discovery_methods, client_authentication_methods: $client_authentication_methods, require_pushed_authorization_requests: $require_pushed_authorization_requests, require_proof_of_possession: $require_proof_of_possession, signed_request_object: $signed_request_object, compliance_level: $compliance_level, skip_non_verifiable_callback_uri_confirmation_prompt: $skip_non_verifiable_callback_uri_confirmation_prompt, token_exchange: $token_exchange, par_request_expiry: $par_request_expiry, express_configuration: $express_configuration, my_organization_configuration: $my_organization_configuration, async_approval_notification_channels: $async_approval_notification_channels, third_party_security_mode: $third_party_security_mode, redirection_policy: $redirection_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get enabled connections for a client
#
# GET /clients/{id}/connections
# operationId: get_client_connections
export def "clients-connections connections" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --strategy: list # Provide strategies to only retrieve connections with such strategies
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
  --qp-fields: string # A comma separated list of fields to include or exclude (depending on include_fields) from the result, empty to retrieve all fields
  --include-fields: oneof<nothing, bool> # <code>true</code> if the fields specified are to be included in the result, <code>false</code> otherwise (defaults to <code>true</code>)
]: nothing -> record<connections: table<name: string, display_name: string, options: record, id: string, strategy: string, realms: list, is_domain_connection: bool, show_as_button: bool, metadata: record, authentication: record, connected_accounts: record>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "strategy" $strategy "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/clients/($id)/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate a client secret
#
# POST /clients/{id}/rotate-secret
# operationId: post_rotate-secret
export def "clients-rotate-secret rotate-secret" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<client_id: string, tenant: string, name: string, description: string, global: bool, client_secret: string, app_type: string, logo_uri: string, is_first_party: bool, oidc_conformant: bool, callbacks: list<string>, allowed_origins: list<string>, web_origins: list<string>, client_aliases: list<string>, allowed_clients: list<string>, allowed_logout_urls: list<string>, session_transfer: record<can_create_session_transfer_token: bool, enforce_cascade_revocation: bool, allowed_authentication_methods: list<string>, enforce_device_binding: string, allow_refresh_token: bool, enforce_online_refresh_tokens: bool, delegation: record<allow_delegated_access: bool, enforce_device_binding: string>>, oidc_logout: record<backchannel_logout_urls: list<string>, backchannel_logout_initiators: record<mode: string, selected_initiators: list>, backchannel_logout_session_metadata: record<include: bool>>, grant_types: list<string>, jwt_configuration: record<lifetime_in_seconds: int, secret_encoded: bool, scopes: record, alg: string>, signing_keys: table<pkcs7: string, cert: string, subject: string>, encryption_key: record<pub: string, cert: string, subject: string>, sso: bool, sso_disabled: bool, cross_origin_authentication: bool, cross_origin_loc: string, custom_login_page_on: bool, custom_login_page: string, custom_login_page_preview: string, form_template: string, addons: record<aws: record<principal: string, role: string, lifetime_in_seconds: int>, azure_blob: record<accountName: string, storageAccessKey: string, containerName: string, blobName: string, expiration: int, signedIdentifier: string, blob_read: bool, blob_write: bool, blob_delete: bool, container_read: bool, container_write: bool, container_delete: bool, container_list: bool>, azure_sb: record<namespace: string, sasKeyName: string, sasKey: string, entityPath: string, expiration: int>, rms: record<url: string>, mscrm: record<url: string>, slack: record<team: string>, sentry: record<org_slug: string, base_url: string>, box: record, cloudbees: record, concur: record, dropbox: record, echosign: record<domain: string>, egnyte: record<domain: string>, firebase: record<secret: string, private_key_id: string, private_key: string, client_email: string, lifetime_in_seconds: int>, newrelic: record<account: string>, office365: record<domain: string, connection: string>, salesforce: record<entity_id: string>, salesforce_api: record<clientid: string, principal: string, communityName: string, community_url_section: string>, salesforce_sandbox_api: record<clientid: string, principal: string, communityName: string, community_url_section: string>, samlp: record<mappings: record, audience: string, recipient: string, createUpnClaim: bool, mapUnknownClaimsAsIs: bool, passthroughClaimsWithNoMapping: bool, mapIdentities: bool, signatureAlgorithm: string, digestAlgorithm: string, issuer: string, destination: string, lifetimeInSeconds: int, signResponse: bool, nameIdentifierFormat: string, nameIdentifierProbes: list, authnContextClassRef: string>, layer: record<providerId: string, keyId: string, privateKey: string, principal: string, expiration: int>, sap_api: record<clientid: string, usernameAttribute: string, tokenEndpointUrl: string, scope: string, servicePassword: string, nameIdentifierFormat: string>, sharepoint: record<url: string, external_url: any>, springcm: record<acsurl: string>, wams: record<masterkey: string>, wsfed: record, zendesk: record<accountName: string>, zoom: record<account: string>, sso_integration: record<name: string, version: string>, oag: record>, token_endpoint_auth_method: string, is_token_endpoint_ip_header_trusted: bool, client_metadata: record, mobile: record<android: record<app_package_name: string, sha256_cert_fingerprints: list>, ios: record<team_id: string, app_bundle_identifier: string>>, initiate_login_uri: string, native_social_login: any, refresh_token: record<rotation_type: string, expiration_type: string, leeway: int, token_lifetime: int, infinite_token_lifetime: bool, idle_token_lifetime: int, infinite_idle_token_lifetime: bool, policies: list<record>>, default_organization: record<organization_id: string, flows: list<string>>, organization_usage: string, organization_require_behavior: string, organization_discovery_methods: list<string>, client_authentication_methods: record<private_key_jwt: record<credentials: list>, tls_client_auth: record<credentials: list>, self_signed_tls_client_auth: record<credentials: list>>, require_pushed_authorization_requests: bool, require_proof_of_possession: bool, signed_request_object: record<required: bool, credentials: list<record>>, compliance_level: string, skip_non_verifiable_callback_uri_confirmation_prompt: bool, token_exchange: record<allow_any_profile_of_type: list<string>>, par_request_expiry: int, token_quota: record<client_credentials: record<enforce: bool, per_day: int, per_hour: int>>, express_configuration: record<initiate_login_uri_template: string, user_attribute_profile_id: string, connection_profile_id: string, enable_client: bool, enable_organization: bool, linked_clients: list<record>, okta_oin_client_id: string, admin_login_domain: string, oin_submission_id: string>, my_organization_configuration: record<connection_profile_id: string, user_attribute_profile_id: string, allowed_strategies: list<string>, connection_deletion_behavior: string>, third_party_security_mode: string, redirection_policy: string, resource_server_identifier: string, async_approval_notification_channels: list<string>, external_metadata_type: string, external_metadata_created_by: string, external_client_id: string, jwks_uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/clients/($id)/rotate-secret")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Connection Profiles
#
# GET /connection-profiles
# operationId: get_connection-profiles
export def "connection-profiles connection-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 5.
]: nothing -> record<next: string, connection_profiles: table<id: string, name: string, organization: record, connection_name_prefix_template: string, enabled_features: list, connection_config: record, strategy_overrides: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connection-profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a connection profile
#
# POST /connection-profiles
# operationId: post_connection-profiles
# --organization shape: {show_as_button?: "none"|"optional"|"required", assign_membership_on_login?: "none"|"optional"|"required"}
# --strategy_overrides shape: {pingfederate?: record, ad?: record, adfs?: record, waad?: record, google-apps?: record, okta?: record, oidc?: record, samlp?: record}
export def "connection-profiles connection-profiles-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the connection profile.
  --organization: record # The organization of the connection profile. — shape: {show_as_button?: "none"|"optional"|"required", assign_membership_on_login?: "none"|"optional"|"required"}
  --connection-name-prefix-template: string # Connection name prefix template.
  --enabled-features: list # Enabled features for the connection profile.
  --connection-config: record # Connection profile configuration.
  --strategy-overrides: record # Strategy-specific overrides for this attribute — shape: {pingfederate?: record, ad?: record, adfs?: record, waad?: record, google-apps?: record, okta?: record, oidc?: record, samlp?: record}
]: any -> record<id: string, name: string, organization: record<show_as_button: string, assign_membership_on_login: string>, connection_name_prefix_template: string, enabled_features: list<string>, connection_config: record, strategy_overrides: record<pingfederate: record<enabled_features: list, connection_config: record>, ad: record<enabled_features: list, connection_config: record>, adfs: record<enabled_features: list, connection_config: record>, waad: record<enabled_features: list, connection_config: record>, google_apps: record<enabled_features: list, connection_config: record>, okta: record<enabled_features: list, connection_config: record>, oidc: record<enabled_features: list, connection_config: record>, samlp: record<enabled_features: list, connection_config: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/connection-profiles")
  let body = {name: $name, organization: $organization, connection_name_prefix_template: $connection_name_prefix_template, enabled_features: $enabled_features, connection_config: $connection_config, strategy_overrides: $strategy_overrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Connection Profile Templates
#
# GET /connection-profiles/templates
# operationId: get_connection_profile_templates
export def "connection-profiles-templates templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<connection_profile_templates: table<id: string, display_name: string, template: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/connection-profiles/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Connection Profile Template
#
# GET /connection-profiles/templates/{id}
# operationId: get_connection_profile_template
export def "connection-profiles-templates template" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, display_name: string, template: record<name: string, organization: record<show_as_button: string, assign_membership_on_login: string>, connection_name_prefix_template: string, enabled_features: list<string>, connection_config: record, strategy_overrides: record<pingfederate: record, ad: record, adfs: record, waad: record, google_apps: record, okta: record, oidc: record, samlp: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connection-profiles/templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Connection Profile
#
# GET /connection-profiles/{id}
# operationId: get_connection-profiles_by_id
export def "connection-profiles id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, organization: record<show_as_button: string, assign_membership_on_login: string>, connection_name_prefix_template: string, enabled_features: list<string>, connection_config: record, strategy_overrides: record<pingfederate: record<enabled_features: list, connection_config: record>, ad: record<enabled_features: list, connection_config: record>, adfs: record<enabled_features: list, connection_config: record>, waad: record<enabled_features: list, connection_config: record>, google_apps: record<enabled_features: list, connection_config: record>, okta: record<enabled_features: list, connection_config: record>, oidc: record<enabled_features: list, connection_config: record>, samlp: record<enabled_features: list, connection_config: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connection-profiles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Connection Profile
#
# DELETE /connection-profiles/{id}
# operationId: delete_connection-profiles_by_id
export def "connection-profiles id-by-id-1" [
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
  let full_url = (build-url $base $"/connection-profiles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify a Connection Profile
#
# PATCH /connection-profiles/{id}
# operationId: patch_connection-profiles_by_id
# --organization shape: {show_as_button?: "none"|"optional"|"required", assign_membership_on_login?: "none"|"optional"|"required"}
# --strategy_overrides shape: {pingfederate?: record, ad?: record, adfs?: record, waad?: record, google-apps?: record, okta?: record, oidc?: record, samlp?: record}
export def "connection-profiles id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the connection profile.
  --organization: record # The organization of the connection profile. — shape: {show_as_button?: "none"|"optional"|"required", assign_membership_on_login?: "none"|"optional"|"required"}
  --connection-name-prefix-template: string # Connection name prefix template.
  --enabled-features: list # Enabled features for the connection profile.
  --connection-config: record # Connection profile configuration.
  --strategy-overrides: record # Strategy-specific overrides for this attribute — shape: {pingfederate?: record, ad?: record, adfs?: record, waad?: record, google-apps?: record, okta?: record, oidc?: record, samlp?: record}
]: any -> record<id: string, name: string, organization: record<show_as_button: string, assign_membership_on_login: string>, connection_name_prefix_template: string, enabled_features: list<string>, connection_config: record, strategy_overrides: record<pingfederate: record<enabled_features: list, connection_config: record>, ad: record<enabled_features: list, connection_config: record>, adfs: record<enabled_features: list, connection_config: record>, waad: record<enabled_features: list, connection_config: record>, google_apps: record<enabled_features: list, connection_config: record>, okta: record<enabled_features: list, connection_config: record>, oidc: record<enabled_features: list, connection_config: record>, samlp: record<enabled_features: list, connection_config: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connection-profiles/($id)")
  let body = {name: $name, organization: $organization, connection_name_prefix_template: $connection_name_prefix_template, enabled_features: $enabled_features, connection_config: $connection_config, strategy_overrides: $strategy_overrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all connections
#
# GET /connections
# operationId: get_connections
export def "connections connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # The amount of entries per page. Defaults to 100 if not provided
  --page: int # The page number. Zero based
  --include-totals: oneof<nothing, bool> # true if a query summary must be included in the result, false otherwise. Not returned when using checkpoint pagination. Default <code>false</code>.
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
  --strategy: list # Provide strategies to only retrieve connections with such strategies
  --name: string # Provide the name of the connection to retrieve
  --qp-fields: string # A comma separated list of fields to include or exclude (depending on include_fields) from the result, empty to retrieve all fields
  --include-fields: oneof<nothing, bool> # <code>true</code> if the fields specified are to be included in the result, <code>false</code> otherwise (defaults to <code>true</code>)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "strategy" $strategy "multi") (serialize-qp "name" $name "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a connection
#
# POST /connections
# operationId: post_connections
# --options shape: {validation?: record, non_persistent_attrs?: list, precedence?: list, attributes?: record, enable_script_context?: bool, enabledDatabaseCustomization?: bool, import_mode?: bool, configuration?: record, customScripts?: record, authentication_methods?: record, passkey_options?: record, passwordPolicy?: "none"|"low"|"fair"|"good"|"excellent"|"", password_complexity_options?: record, password_history?: record, password_no_personal_info?: record, password_dictionary?: record, api_enable_users?: bool, api_enable_groups?: bool, basic_profile?: bool, ext_admin?: bool, ext_is_suspended?: bool, ext_agreed_terms?: bool, ext_groups?: bool, ext_assigned_plans?: bool, ext_profile?: bool, disable_self_service_change_password?: bool, upstream_params?: record, set_user_root_attributes?: "on_each_login"|"on_first_login"|"never_on_login", gateway_authentication?: record, federated_connections_access_tokens?: record, password_options?: record, assertion_decryption_settings?: record, id_token_signed_response_algs?: list, token_endpoint_auth_method?: "client_secret_post"|"private_key_jwt", token_endpoint_auth_signing_alg?: "ES256"|"ES384"|"PS256"|"PS384"|"RS256"|"RS384"|"RS512", token_endpoint_jwtca_aud_format?: "issuer"|"token_endpoint"}
# --authentication shape: {active: bool}
# --connected_accounts shape: {active: bool, cross_app_access?: bool}
export def "connections connections-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the connection. Must start and end with an alphanumeric character and can only contain alphanumeric characters and '-'. Max length 128
  --display-name: string # Connection name used in the new universal login experience
  strategy: string@strategy-completer # The identity provider identifier for the connection
  --options: record # The connection's options (depend on the connection strategy) — shape: {validation?: record, non_persistent_attrs?: list, precedence?: list, attributes?: record, enable_script_context?: bool, enabledDatabaseCustomization?: bool, import_mode?: bool, configuration?: record, customScripts?: record, authentication_methods?: record, passkey_options?: record, passwordPolicy?: "none"|"low"|"fair"|"good"|"excellent"|"", password_complexity_options?: record, password_history?: record, password_no_personal_info?: record, password_dictionary?: record, api_enable_users?: bool, api_enable_groups?: bool, basic_profile?: bool, ext_admin?: bool, ext_is_suspended?: bool, ext_agreed_terms?: bool, ext_groups?: bool, ext_assigned_plans?: bool, ext_profile?: bool, disable_self_service_change_password?: bool, upstream_params?: record, set_user_root_attributes?: "on_each_login"|"on_first_login"|"never_on_login", gateway_authentication?: record, federated_connections_access_tokens?: record, password_options?: record, assertion_decryption_settings?: record, id_token_signed_response_algs?: list, token_endpoint_auth_method?: "client_secret_post"|"private_key_jwt", token_endpoint_auth_signing_alg?: "ES256"|"ES384"|"PS256"|"PS384"|"RS256"|"RS384"|"RS512", token_endpoint_jwtca_aud_format?: "issuer"|"token_endpoint"}
  --enabled-clients: list # Use of this property is NOT RECOMMENDED. Use the PATCH /v2/connections/{id}/clients endpoint to enable the connection for a set of clients.
  --is-domain-connection: oneof<nothing, bool> # <code>true</code> promotes to a domain-level connection so that third-party applications can use it. <code>false</code> does not promote the connection, so only first-party applications with the connection enabled can use it. (Defaults to <code>false</code>.)
  --show-as-button: oneof<nothing, bool> # Enables showing a button for the connection in the login page (new experience only). If false, it will be usable only by HRD. (Defaults to <code>false</code>.)
  --realms: list # Defines the realms for which the connection will be used (ie: email domains). If the array is empty or the property is not specified, the connection name will be added as realm.
  --metadata: record # Metadata associated with the connection in the form of an object with string values (max 255 chars).  Maximum of 10 metadata properties allowed.
  --authentication: record # Configure the purpose of a connection to be used for authentication during login. — shape: {active: bool}
  --connected-accounts: record # Configure the purpose of a connection to be used for connected accounts and Token Vault. — shape: {active: bool, cross_app_access?: bool}
]: any -> record<name: string, display_name: string, options: record, id: string, strategy: string, realms: list<string>, enabled_clients: list<string>, is_domain_connection: bool, show_as_button: bool, metadata: record, authentication: record<active: bool>, connected_accounts: record<active: bool, cross_app_access: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/connections")
  let body = {name: $name, display_name: $display_name, strategy: $strategy, options: $options, enabled_clients: $enabled_clients, is_domain_connection: $is_domain_connection, show_as_button: $show_as_button, realms: $realms, metadata: $metadata, authentication: $authentication, connected_accounts: $connected_accounts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of directory provisioning configurations
#
# GET /connections-directory-provisionings
# operationId: get_connections-directory-provisionings
export def "connections-directory-provisionings connections-directory-provisionings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
]: nothing -> record<directory_provisionings: table<connection_id: string, connection_name: string, strategy: string, mapping: list, synchronize_automatically: bool, synchronize_groups: string, created_at: string, updated_at: string, last_synchronization_at: string, last_synchronization_status: string, last_synchronization_error: string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connections-directory-provisionings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of SCIM configurations
#
# GET /connections-scim-configurations
# operationId: get_connections-scim-configurations
export def "connections-scim-configurations connections-scim-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
]: nothing -> record<scim_configurations: table<connection_id: string, connection_name: string, strategy: string, tenant_name: string, user_id_attribute: string, mapping: list, created_at: string, updated_on: string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connections-scim-configurations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a connection
#
# GET /connections/{id}
# operationId: get_connections_by_id
export def "connections id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # A comma separated list of fields to include or exclude (depending on include_fields) from the result, empty to retrieve all fields
  --include-fields: oneof<nothing, bool> # <code>true</code> if the fields specified are to be included in the result, <code>false</code> otherwise (defaults to <code>true</code>)
]: nothing -> record<name: string, display_name: string, options: record, id: string, strategy: string, realms: list<string>, enabled_clients: list<string>, is_domain_connection: bool, show_as_button: bool, metadata: record, authentication: record<active: bool>, connected_accounts: record<active: bool, cross_app_access: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/connections/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a connection
#
# DELETE /connections/{id}
# operationId: delete_connections_by_id
export def "connections id-by-id-1" [
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

# Update a connection
#
# PATCH /connections/{id}
# operationId: patch_connections_by_id
# --options shape: {validation?: record, non_persistent_attrs?: list, precedence?: list, attributes?: record, enable_script_context?: bool, enabledDatabaseCustomization?: bool, import_mode?: bool, configuration?: record, customScripts?: record, authentication_methods?: record, passkey_options?: record, passwordPolicy?: "none"|"low"|"fair"|"good"|"excellent"|"", password_complexity_options?: record, password_history?: record, password_no_personal_info?: record, password_dictionary?: record, api_enable_users?: bool, api_enable_groups?: bool, basic_profile?: bool, ext_admin?: bool, ext_is_suspended?: bool, ext_agreed_terms?: bool, ext_groups?: bool, ext_assigned_plans?: bool, ext_profile?: bool, disable_self_service_change_password?: bool, upstream_params?: record, set_user_root_attributes?: "on_each_login"|"on_first_login"|"never_on_login", gateway_authentication?: record, federated_connections_access_tokens?: record, password_options?: record, assertion_decryption_settings?: record, id_token_signed_response_algs?: list, token_endpoint_auth_method?: "client_secret_post"|"private_key_jwt", token_endpoint_auth_signing_alg?: "ES256"|"ES384"|"PS256"|"PS384"|"RS256"|"RS384"|"RS512", token_endpoint_jwtca_aud_format?: "issuer"|"token_endpoint"}
# --authentication shape: {active: bool}
# --connected_accounts shape: {active: bool, cross_app_access?: bool}
export def "connections id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --display-name: string # The connection name used in the new universal login experience. If display_name is not included in the request, the field will be overwritten with the name value.
  --options: record # The connection's options (depend on the connection strategy). To update these options, the `update:connections_options` scope must be present. To verify your changes, also include the `read:connections_options` scope. If this scope is not specified, you will not be able to review the updated object. (nullable) — shape: {validation?: record, non_persistent_attrs?: list, precedence?: list, attributes?: record, enable_script_context?: bool, enabledDatabaseCustomization?: bool, import_mode?: bool, configuration?: record, customScripts?: record, authentication_methods?: record, passkey_options?: record, passwordPolicy?: "none"|"low"|"fair"|"good"|"excellent"|"", password_complexity_options?: record, password_history?: record, password_no_personal_info?: record, password_dictionary?: record, api_enable_users?: bool, api_enable_groups?: bool, basic_profile?: bool, ext_admin?: bool, ext_is_suspended?: bool, ext_agreed_terms?: bool, ext_groups?: bool, ext_assigned_plans?: bool, ext_profile?: bool, disable_self_service_change_password?: bool, upstream_params?: record, set_user_root_attributes?: "on_each_login"|"on_first_login"|"never_on_login", gateway_authentication?: record, federated_connections_access_tokens?: record, password_options?: record, assertion_decryption_settings?: record, id_token_signed_response_algs?: list, token_endpoint_auth_method?: "client_secret_post"|"private_key_jwt", token_endpoint_auth_signing_alg?: "ES256"|"ES384"|"PS256"|"PS384"|"RS256"|"RS384"|"RS512", token_endpoint_jwtca_aud_format?: "issuer"|"token_endpoint"}
  --enabled-clients: list # DEPRECATED property. Use the PATCH /v2/connections/{id}/clients endpoint to enable or disable the connection for any clients. (nullable)
  --is-domain-connection: oneof<nothing, bool> # <code>true</code> promotes to a domain-level connection so that third-party applications can use it. <code>false</code> does not promote the connection, so only first-party applications with the connection enabled can use it. (Defaults to <code>false</code>.)
  --show-as-button: oneof<nothing, bool> # Enables showing a button for the connection in the login page (new experience only). If false, it will be usable only by HRD. (Defaults to <code>false</code>.)
  --realms: list # Defines the realms for which the connection will be used (ie: email domains). If the array is empty or the property is not specified, the connection name will be added as realm.
  --metadata: record # Metadata associated with the connection in the form of an object with string values (max 255 chars).  Maximum of 10 metadata properties allowed.
  --authentication: record # Configure the purpose of a connection to be used for authentication during login. — shape: {active: bool}
  --connected-accounts: record # Configure the purpose of a connection to be used for connected accounts and Token Vault. — shape: {active: bool, cross_app_access?: bool}
]: any -> record<name: string, display_name: string, options: record, id: string, strategy: string, realms: list<string>, enabled_clients: list<string>, is_domain_connection: bool, show_as_button: bool, metadata: record, authentication: record<active: bool>, connected_accounts: record<active: bool, cross_app_access: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)")
  let body = {display_name: $display_name, options: $options, enabled_clients: $enabled_clients, is_domain_connection: $is_domain_connection, show_as_button: $show_as_button, realms: $realms, metadata: $metadata, authentication: $authentication, connected_accounts: $connected_accounts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get enabled clients for a connection
#
# GET /connections/{id}/clients
# operationId: get_connection_clients
export def "connections-clients clients-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --take: int # Number of results per page. Defaults to 50.
  --qp-from: string # Optional Id from which to start selection.
]: nothing -> record<clients: table<client_id: string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "take" $take "scalar") (serialize-qp "from" $qp_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/connections/($id)/clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update enabled clients for a connection
#
# PATCH /connections/{id}/clients
# operationId: patch_clients
export def "connections-clients clients-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)/clients")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a directory provisioning configuration
#
# GET /connections/{id}/directory-provisioning
# operationId: get_directory-provisioning
export def "connections-directory-provisioning directory-provisioning-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<connection_id: string, connection_name: string, strategy: string, mapping: table<auth0: string, idp: string>, synchronize_automatically: bool, synchronize_groups: string, created_at: string, updated_at: string, last_synchronization_at: string, last_synchronization_status: string, last_synchronization_error: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)/directory-provisioning")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a directory provisioning configuration
#
# DELETE /connections/{id}/directory-provisioning
# operationId: delete_directory-provisioning
export def "connections-directory-provisioning directory-provisioning-by-id-1" [
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
  let full_url = (build-url $base $"/connections/($id)/directory-provisioning")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch a directory provisioning configuration
#
# PATCH /connections/{id}/directory-provisioning
# operationId: patch_directory-provisioning
# --mapping item shape: {auth0: string, idp: string}
export def "connections-directory-provisioning directory-provisioning-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --mapping: list # The mapping between Auth0 and IDP user attributes — item shape: {auth0: string, idp: string}
  --synchronize-automatically: oneof<nothing, bool> # Whether periodic automatic synchronization is enabled
  --synchronize-groups: string@synchronize-groups-completer # Group synchronization configuration
]: any -> record<connection_id: string, connection_name: string, strategy: string, mapping: table<auth0: string, idp: string>, synchronize_automatically: bool, synchronize_groups: string, created_at: string, updated_at: string, last_synchronization_at: string, last_synchronization_status: string, last_synchronization_error: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)/directory-provisioning")
  let body = {mapping: $mapping, synchronize_automatically: $synchronize_automatically, synchronize_groups: $synchronize_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a directory provisioning configuration
#
# POST /connections/{id}/directory-provisioning
# operationId: post_directory-provisioning
# --mapping item shape: {auth0: string, idp: string}
export def "connections-directory-provisioning directory-provisioning-by-id-3" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --mapping: list # The mapping between Auth0 and IDP user attributes — item shape: {auth0: string, idp: string}
  --synchronize-automatically: oneof<nothing, bool> # Whether periodic automatic synchronization is enabled
  --synchronize-groups: string@synchronize-groups-completer # Group synchronization configuration
]: any -> record<connection_id: string, connection_name: string, strategy: string, mapping: table<auth0: string, idp: string>, synchronize_automatically: bool, synchronize_groups: string, created_at: string, updated_at: string, last_synchronization_at: string, last_synchronization_status: string, last_synchronization_error: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)/directory-provisioning")
  let body = {mapping: $mapping, synchronize_automatically: $synchronize_automatically, synchronize_groups: $synchronize_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a connection's default directory provisioning attribute mapping
#
# GET /connections/{id}/directory-provisioning/default-mapping
# operationId: get_directory_provisioning_default_mapping
export def "connections-directory-provisioning-default-mapping mapping" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<mapping: table<auth0: string, idp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)/directory-provisioning/default-mapping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request an on-demand synchronization of the directory
#
# POST /connections/{id}/directory-provisioning/synchronizations
# operationId: post_synchronizations
export def "connections-directory-provisioning-synchronizations synchronizations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<connection_id: string, synchronization_id: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)/directory-provisioning/synchronizations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get synchronized groups for a directory provisioning configuration
#
# GET /connections/{id}/directory-provisioning/synchronized-groups
# operationId: get_synchronized-groups
export def "connections-directory-provisioning-synchronized-groups synchronized-groups-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
]: nothing -> record<groups: table<id: string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/connections/($id)/directory-provisioning/synchronized-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or replace synchronized group selections for a directory provisioning configuration
#
# PUT /connections/{id}/directory-provisioning/synchronized-groups
# operationId: put_synchronized-groups
# --groups item shape: {id: string}
export def "connections-directory-provisioning-synchronized-groups synchronized-groups-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  groups: list # Array of Google Workspace Directory group objects to synchronize. — item shape: {id: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)/directory-provisioning/synchronized-groups")
  let body = {groups: $groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get connection keys
#
# GET /connections/{id}/keys
# operationId: get_keys
export def "connections-keys keys-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<kid: string, cert: string, pkcs: string, current: bool, next: bool, previous: bool, current_since: string, fingerprint: string, thumbprint: string, algorithm: string, key_use: string, subject_dn: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)/keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create connection keys
#
# POST /connections/{id}/keys
# operationId: post_keys
export def "connections-keys keys-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --signing-alg: string@signing-alg-completer # Selected Signing Algorithm
]: any -> table<kid: string, cert: string, pkcs: string, current: bool, next: bool, current_since: string, fingerprint: string, thumbprint: string, algorithm: string, key_use: string, subject_dn: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)/keys")
  let body = {signing_alg: $signing_alg} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rotate connection keys
#
# POST /connections/{id}/keys/rotate
# operationId: post_rotate
export def "connections-keys-rotate rotate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --signing-alg: string@signing-alg-completer # Selected Signing Algorithm
]: any -> record<kid: string, cert: string, pkcs: string, next: bool, fingerprint: string, thumbprint: string, algorithm: string, key_use: string, subject_dn: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)/keys/rotate")
  let body = {signing_alg: $signing_alg} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a connection's SCIM configuration
#
# GET /connections/{id}/scim-configuration
# operationId: get_scim-configuration
export def "connections-scim-configuration scim-configuration-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<connection_id: string, connection_name: string, strategy: string, tenant_name: string, user_id_attribute: string, mapping: table<auth0: string, scim: string>, created_at: string, updated_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)/scim-configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a connection's SCIM configuration
#
# DELETE /connections/{id}/scim-configuration
# operationId: delete_scim-configuration
export def "connections-scim-configuration scim-configuration-by-id-1" [
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
  let full_url = (build-url $base $"/connections/($id)/scim-configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch a connection's SCIM configuration
#
# PATCH /connections/{id}/scim-configuration
# operationId: patch_scim-configuration
# --mapping item shape: {auth0?: string, scim?: string}
export def "connections-scim-configuration scim-configuration-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id_attribute: string # User ID attribute for generating unique user ids
  mapping: list # The mapping between auth0 and SCIM — item shape: {auth0?: string, scim?: string}
]: any -> record<connection_id: string, connection_name: string, strategy: string, tenant_name: string, user_id_attribute: string, mapping: table<auth0: string, scim: string>, created_at: string, updated_on: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)/scim-configuration")
  let body = {user_id_attribute: $user_id_attribute, mapping: $mapping} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a SCIM configuration
#
# POST /connections/{id}/scim-configuration
# operationId: post_scim-configuration
# --mapping item shape: {auth0?: string, scim?: string}
export def "connections-scim-configuration scim-configuration-by-id-3" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id-attribute: string # User ID attribute for generating unique user ids
  --mapping: list # The mapping between auth0 and SCIM — item shape: {auth0?: string, scim?: string}
]: any -> record<connection_id: string, connection_name: string, strategy: string, tenant_name: string, user_id_attribute: string, mapping: table<auth0: string, scim: string>, created_at: string, updated_on: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)/scim-configuration")
  let body = {user_id_attribute: $user_id_attribute, mapping: $mapping} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a connection's default SCIM mapping
#
# GET /connections/{id}/scim-configuration/default-mapping
# operationId: get_default-mapping
export def "connections-scim-configuration-default-mapping default-mapping" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<mapping: table<auth0: string, scim: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)/scim-configuration/default-mapping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a connection's SCIM tokens
#
# GET /connections/{id}/scim-configuration/tokens
# operationId: get_scim_tokens
export def "connections-scim-configuration-tokens tokens" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<token_id: string, scopes: list<string>, created_at: string, valid_until: string, last_used_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)/scim-configuration/tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a SCIM Token
#
# POST /connections/{id}/scim-configuration/tokens
# operationId: post_scim_token
export def "connections-scim-configuration-tokens token" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scopes: list # The scopes of the scim token
  --token-lifetime: int # Lifetime of the token in seconds. Must be greater than 900 (nullable)
]: any -> record<token_id: string, token: string, scopes: list<string>, created_at: string, valid_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)/scim-configuration/tokens")
  let body = {scopes: $scopes, token_lifetime: $token_lifetime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a connection's SCIM token
#
# DELETE /connections/{id}/scim-configuration/tokens/{tokenId}
# operationId: delete_tokens_by_tokenId
export def "connections-scim-configuration-tokens tokenId" [
  id: string
  tokenId: string
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
  let full_url = (build-url $base $"/connections/($id)/scim-configuration/tokens/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check connection status
#
# GET /connections/{id}/status
# operationId: get_status
export def "connections-status status" [
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
  let full_url = (build-url $base $"/connections/($id)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a connection user
#
# DELETE /connections/{id}/users
# operationId: delete_users_by_email
export def "connections-users email" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # The email of the user to delete
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/connections/($id)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get custom domains configurations
#
# GET /custom-domains
# operationId: get_custom-domains
export def "custom-domains custom-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --take: int # Number of results per page. Defaults to 50.
  --qp-from: string # Optional Id from which to start selection.
  --q: string # Query in <a href ="https://lucene.apache.org/core/2_9_4/queryparsersyntax.html">Lucene query string syntax</a>.
  --qp-fields: string # Comma-separated list of fields to include or exclude (based on value provided for include_fields) in the result. Leave empty to retrieve all fields.
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false).
  --qp-sort: string # Field to sort by. Only <code>domain:1</code> (ascending order by domain) is supported at this time.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "take" $take "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom-domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Configure a new custom domain
#
# POST /custom-domains
# operationId: post_custom-domains
export def "custom-domains custom-domains-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain: string # Domain name.
  type: string@type-completer-1 # Custom domain provisioning type. Must be `auth0_managed_certs` or `self_managed_certs`.
  --verification-method: string@verification-method-completer # Custom domain verification method. Must be `txt`. (default: txt)
  --tls-policy: string@tls-policy-completer # Custom domain TLS policy. Must be `recommended`, includes TLS 1.2. (default: recommended)
  --custom-client-ip-header: any
  --domain-metadata: record # Domain metadata associated with the custom domain, in the form of an object with string values (max 255 chars). Maximum of 10 domain metadata properties allowed.
  --relying-party-identifier: string # Relying Party ID (rpId) to be used for Passkeys on this custom domain. If not provided, the full domain will be used. (format: hostname)
]: any -> record<custom_domain_id: string, domain: string, primary: bool, is_default: bool, status: string, type: string, verification: record<methods: list<record>, status: string, error_msg: string, last_verified_at: string>, custom_client_ip_header: string, tls_policy: string, domain_metadata: record, certificate: record<status: string, error_msg: string, certificate_authority: string, renews_before: string>, relying_party_identifier: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom-domains")
  let body = {domain: $domain, type: $type, verification_method: $verification_method, tls_policy: $tls_policy, custom_client_ip_header: $custom_client_ip_header, domain_metadata: $domain_metadata, relying_party_identifier: $relying_party_identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the default domain
#
# GET /custom-domains/default
# operationId: get_default
export def "custom-domains-default default" [
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
  let full_url = (build-url $base "/custom-domains/default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the default custom domain for the tenant
#
# PATCH /custom-domains/default
# operationId: patch_default
export def "custom-domains-default default-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain: string # The domain to set as the default custom domain. Must be a verified custom domain or the canonical domain.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom-domains/default")
  let body = {domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get custom domain configuration
#
# GET /custom-domains/{id}
# operationId: get_custom-domains_by_id
export def "custom-domains id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_domain_id: string, domain: string, primary: bool, is_default: bool, status: string, type: string, origin_domain_name: string, verification: record<methods: list<record>, status: string, error_msg: string, last_verified_at: string>, custom_client_ip_header: string, tls_policy: string, domain_metadata: record, certificate: record<status: string, error_msg: string, certificate_authority: string, renews_before: string>, relying_party_identifier: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-domains/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete custom domain configuration
#
# DELETE /custom-domains/{id}
# operationId: delete_custom-domains_by_id
export def "custom-domains id-by-id-1" [
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
  let full_url = (build-url $base $"/custom-domains/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update custom domain configuration
#
# PATCH /custom-domains/{id}
# operationId: patch_custom-domains_by_id
export def "custom-domains id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tls-policy: string@tls-policy-completer # Custom domain TLS policy. Must be `recommended`, includes TLS 1.2. (default: recommended)
  --custom-client-ip-header: any
  --domain-metadata: record # Domain metadata associated with the custom domain, in the form of an object with string values (max 255 chars). Maximum of 10 domain metadata properties allowed.
  --relying-party-identifier: string # Relying Party ID (rpId) to be used for Passkeys on this custom domain. Set to null to remove the rpId and fall back to using the full domain. (nullable, format: hostname)
]: any -> record<custom_domain_id: string, domain: string, primary: bool, is_default: bool, status: string, type: string, verification: record<methods: list<record>, status: string, error_msg: string, last_verified_at: string>, custom_client_ip_header: string, tls_policy: string, domain_metadata: record, certificate: record<status: string, error_msg: string, certificate_authority: string, renews_before: string>, relying_party_identifier: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-domains/($id)")
  let body = {tls_policy: $tls_policy, custom_client_ip_header: $custom_client_ip_header, domain_metadata: $domain_metadata, relying_party_identifier: $relying_party_identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test a custom domain
#
# POST /custom-domains/{id}/test
# operationId: post_test_domain
export def "custom-domains-test domain" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-domains/($id)/test")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify a custom domain
#
# POST /custom-domains/{id}/verify
# operationId: post_verify
export def "custom-domains-verify verify" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_domain_id: string, domain: string, primary: bool, status: string, type: string, cname_api_key: string, origin_domain_name: string, verification: record<methods: list<record>, status: string, error_msg: string, last_verified_at: string>, custom_client_ip_header: string, tls_policy: string, domain_metadata: record, certificate: record<status: string, error_msg: string, certificate_authority: string, renews_before: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-domains/($id)/verify")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve device credentials
#
# GET /device-credentials
# operationId: get_device-credentials
export def "device-credentials device-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page.  There is a maximum of 1000 results allowed from this endpoint.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --qp-fields: string # Comma-separated list of fields to include or exclude (based on value provided for include_fields) in the result. Leave empty to retrieve all fields.
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false).
  --user-id: string # user_id of the devices to retrieve.
  --client-id: string # client_id of the devices to retrieve.
  --type: string@type-completer-2 # Type of credentials to retrieve. Must be `public_key`, `refresh_token` or `rotating_refresh_token`. The property will default to `refresh_token` when paging is requested
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/device-credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a device public key credential
#
# POST /device-credentials
# operationId: post_device-credentials
export def "device-credentials device-credentials-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  device_name: string # Name for this device easily recognized by owner.
  type: string@type-completer-3 # Type of credential. Must be `public_key`.
  value: string # Base64 encoded string containing the credential.
  device_id: string # Unique identifier for the device. Recommend using <a href="http://developer.android.com/reference/android/provider/Settings.Secure.html#ANDROID_ID">Android_ID</a> on Android and <a href="https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDevice_Class/index.html#//apple_ref/occ/instp/UIDevice/identifierForVendor">identifierForVendor</a>.
  --client-id: string # client_id of the client (application) this credential is for. (format: client-id)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device-credentials")
  let body = {device_name: $device_name, type: $type, value: $value, device_id: $device_id, client_id: $client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a device credential
#
# DELETE /device-credentials/{id}
# operationId: delete_device-credentials_by_id
export def "device-credentials id" [
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
  let full_url = (build-url $base $"/device-credentials/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an email template
#
# POST /email-templates
# operationId: post_email-templates
export def "email-templates email-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template: string@template-completer # Template name. Can be `verify_email`, `verify_email_by_code`, `reset_email`, `reset_email_by_code`, `welcome_email`, `blocked_account`, `stolen_credentials`, `enrollment_email`, `mfa_oob_code`, `user_invitation`, `async_approval`, `change_password` (legacy), or `password_reset` (legacy). (default: verify_email)
  --body-body: string # Body of the email template. (nullable)
  --body-from: string # Senders `from` email address. (nullable, default: sender@auth0.com)
  --resultUrl: string # URL to redirect the user to after a successful action. (nullable)
  --subject: string # Subject line of the email. (nullable)
  --syntax: string # Syntax of the template body. (nullable, default: liquid)
  --urlLifetimeInSeconds: float # Lifetime in seconds that the link within the email will be valid for. (nullable)
  --includeEmailInRedirect: oneof<nothing, bool> # Whether the `reset_email` and `verify_email` templates should include the user's email address as the `email` parameter in the returnUrl (true) or whether no email address should be included in the redirect (false). Defaults to true.
  --enabled: oneof<nothing, bool> # Whether the template is enabled (true) or disabled (false). (nullable)
]: any -> record<template: string, body: string, from: string, resultUrl: string, subject: string, syntax: string, urlLifetimeInSeconds: float, includeEmailInRedirect: bool, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/email-templates")
  let body = {template: $template, body: $body_body, from: $body_from, resultUrl: $resultUrl, subject: $subject, syntax: $syntax, urlLifetimeInSeconds: $urlLifetimeInSeconds, includeEmailInRedirect: $includeEmailInRedirect, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an email template
#
# GET /email-templates/{templateName}
# operationId: get_email-templates_by_templateName
export def "email-templates templateName-by-templateName" [
  templateName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<template: string, body: string, from: string, resultUrl: string, subject: string, syntax: string, urlLifetimeInSeconds: float, includeEmailInRedirect: bool, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/email-templates/($templateName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch an email template
#
# PATCH /email-templates/{templateName}
# operationId: patch_email-templates_by_templateName
export def "email-templates templateName-by-templateName-1" [
  templateName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --template: string@template-completer # Template name. Can be `verify_email`, `verify_email_by_code`, `reset_email`, `reset_email_by_code`, `welcome_email`, `blocked_account`, `stolen_credentials`, `enrollment_email`, `mfa_oob_code`, `user_invitation`, `async_approval`, `change_password` (legacy), or `password_reset` (legacy). (default: verify_email)
  --body-body: string # Body of the email template. (nullable)
  --body-from: string # Senders `from` email address. (nullable, default: sender@auth0.com)
  --resultUrl: string # URL to redirect the user to after a successful action. (nullable)
  --subject: string # Subject line of the email. (nullable)
  --syntax: string # Syntax of the template body. (nullable, default: liquid)
  --urlLifetimeInSeconds: float # Lifetime in seconds that the link within the email will be valid for. (nullable)
  --includeEmailInRedirect: oneof<nothing, bool> # Whether the `reset_email` and `verify_email` templates should include the user's email address as the `email` parameter in the returnUrl (true) or whether no email address should be included in the redirect (false). Defaults to true.
  --enabled: oneof<nothing, bool> # Whether the template is enabled (true) or disabled (false). (nullable)
]: any -> record<template: string, body: string, from: string, resultUrl: string, subject: string, syntax: string, urlLifetimeInSeconds: float, includeEmailInRedirect: bool, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/email-templates/($templateName)")
  let body = {template: $template, body: $body_body, from: $body_from, resultUrl: $resultUrl, subject: $subject, syntax: $syntax, urlLifetimeInSeconds: $urlLifetimeInSeconds, includeEmailInRedirect: $includeEmailInRedirect, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an email template
#
# PUT /email-templates/{templateName}
# operationId: put_email-templates_by_templateName
export def "email-templates templateName-by-templateName-2" [
  templateName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template: string@template-completer # Template name. Can be `verify_email`, `verify_email_by_code`, `reset_email`, `reset_email_by_code`, `welcome_email`, `blocked_account`, `stolen_credentials`, `enrollment_email`, `mfa_oob_code`, `user_invitation`, `async_approval`, `change_password` (legacy), or `password_reset` (legacy). (default: verify_email)
  --body-body: string # Body of the email template. (nullable)
  --body-from: string # Senders `from` email address. (nullable, default: sender@auth0.com)
  --resultUrl: string # URL to redirect the user to after a successful action. (nullable)
  --subject: string # Subject line of the email. (nullable)
  --syntax: string # Syntax of the template body. (nullable, default: liquid)
  --urlLifetimeInSeconds: float # Lifetime in seconds that the link within the email will be valid for. (nullable)
  --includeEmailInRedirect: oneof<nothing, bool> # Whether the `reset_email` and `verify_email` templates should include the user's email address as the `email` parameter in the returnUrl (true) or whether no email address should be included in the redirect (false). Defaults to true.
  --enabled: oneof<nothing, bool> # Whether the template is enabled (true) or disabled (false). (nullable)
]: any -> record<template: string, body: string, from: string, resultUrl: string, subject: string, syntax: string, urlLifetimeInSeconds: float, includeEmailInRedirect: bool, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/email-templates/($templateName)")
  let body = {template: $template, body: $body_body, from: $body_from, resultUrl: $resultUrl, subject: $subject, syntax: $syntax, urlLifetimeInSeconds: $urlLifetimeInSeconds, includeEmailInRedirect: $includeEmailInRedirect, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get email provider
#
# GET /emails/provider
# operationId: get_provider
export def "emails-provider provider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include or exclude (dependent upon include_fields) from the result. Leave empty to retrieve `name` and `enabled`. Additional fields available include `credentials`, `default_from_address`, and `settings`.
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false).
]: nothing -> record<name: string, enabled: bool, default_from_address: string, credentials: record<api_user: string, region: string, smtp_host: string, smtp_port: int, smtp_user: string>, settings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/emails/provider" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete email provider
#
# DELETE /emails/provider
# operationId: delete_provider
export def "emails-provider provider-1" [
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
  let full_url = (build-url $base "/emails/provider")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update email provider
#
# PATCH /emails/provider
# operationId: patch_provider
# --credentials shape: {api_key?: string, accessKeyId?: string, secretAccessKey?: string, region?: string, smtp_host?: string, smtp_port?: int, smtp_user?: string, smtp_pass?: string, domain?: string, connectionString?: string, tenantId?: string, clientId?: string, clientSecret?: string}
export def "emails-provider provider-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string@name-completer-1 # Name of the email provider. Can be `mailgun`, `mandrill`, `sendgrid`, `resend`, `ses`, `sparkpost`, `smtp`, `azure_cs`, `ms365`, or `custom`.
  --enabled: oneof<nothing, bool> # Whether the provider is enabled (true) or disabled (false).
  --default-from-address: string # Email address to use as "from" when no other address specified.
  --credentials: record # Credentials required to use the provider. — shape: {api_key?: string, accessKeyId?: string, secretAccessKey?: string, region?: string, smtp_host?: string, smtp_port?: int, smtp_user?: string, smtp_pass?: string, domain?: string, connectionString?: string, tenantId?: string, clientId?: string, clientSecret?: string}
  --settings: record # Specific provider setting (nullable)
]: any -> record<name: string, enabled: bool, default_from_address: string, credentials: record<api_user: string, region: string, smtp_host: string, smtp_port: int, smtp_user: string>, settings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/emails/provider")
  let body = {name: $name, enabled: $enabled, default_from_address: $default_from_address, credentials: $credentials, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Configure email provider
#
# POST /emails/provider
# operationId: post_provider
# --credentials shape: {api_key?: string, accessKeyId?: string, secretAccessKey?: string, region?: string, smtp_host?: string, smtp_port?: int, smtp_user?: string, smtp_pass?: string, domain?: string, connectionString?: string, tenantId?: string, clientId?: string, clientSecret?: string}
export def "emails-provider provider-3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string@name-completer-1 # Name of the email provider. Can be `mailgun`, `mandrill`, `sendgrid`, `resend`, `ses`, `sparkpost`, `smtp`, `azure_cs`, `ms365`, or `custom`.
  --enabled: oneof<nothing, bool> # Whether the provider is enabled (true) or disabled (false). (default: true)
  --default-from-address: string # Email address to use as "from" when no other address specified.
  credentials: record # Credentials required to use the provider. — shape: {api_key?: string, accessKeyId?: string, secretAccessKey?: string, region?: string, smtp_host?: string, smtp_port?: int, smtp_user?: string, smtp_pass?: string, domain?: string, connectionString?: string, tenantId?: string, clientId?: string, clientSecret?: string}
  --settings: record # Specific provider setting (nullable)
]: any -> record<name: string, enabled: bool, default_from_address: string, credentials: record<api_user: string, region: string, smtp_host: string, smtp_port: int, smtp_user: string>, settings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/emails/provider")
  let body = {name: $name, enabled: $enabled, default_from_address: $default_from_address, credentials: $credentials, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get event streams
#
# GET /event-streams
# operationId: get_event-streams
export def "event-streams event-streams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
]: nothing -> record<eventStreams: list<any>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/event-streams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an event stream
#
# POST /event-streams
# operationId: post_event-streams
# --subscriptions item shape: {event_type?: string}
# --destination shape: {type: "webhook", configuration: record}
export def "event-streams event-streams-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the event stream.
  --subscriptions: list # List of event types subscribed to in this stream. — item shape: {event_type?: string}
  --destination: record # shape: {type: "webhook", configuration: record}
  --status: string@status-completer # Indicates whether the event stream is actively forwarding events.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/event-streams")
  let body = {name: $name, subscriptions: $subscriptions, destination: $destination, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an event stream by ID
#
# GET /event-streams/{id}
# operationId: get_event-streams_by_id
export def "event-streams id-by-id" [
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
  let full_url = (build-url $base $"/event-streams/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an event stream
#
# DELETE /event-streams/{id}
# operationId: delete_event-streams_by_id
export def "event-streams id-by-id-1" [
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
  let full_url = (build-url $base $"/event-streams/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an event stream
#
# PATCH /event-streams/{id}
# operationId: patch_event-streams_by_id
# --subscriptions item shape: {event_type?: string}
export def "event-streams id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the event stream.
  --subscriptions: list # List of event types subscribed to in this stream. — item shape: {event_type?: string}
  --destination: any
  --status: string@status-completer # Indicates whether the event stream is actively forwarding events.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event-streams/($id)")
  let body = {name: $name, subscriptions: $subscriptions, destination: $destination, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get this event stream's delivery history
#
# GET /event-streams/{id}/deliveries
# operationId: get_event_deliveries
export def "event-streams-deliveries deliveries" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --statuses: string # Comma-separated list of statuses by which to filter
  --event-types: string # Comma-separated list of event types by which to filter
  --date-from: string # An RFC-3339 date-time for redelivery start, inclusive. Does not allow sub-second precision.
  --date-to: string # An RFC-3339 date-time for redelivery end, exclusive. Does not allow sub-second precision.
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
]: nothing -> table<id: string, event_stream_id: string, status: string, event_type: string, attempts: list<record>, event: record<id: string, source: string, specversion: string, type: string, time: string, data: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statuses" $statuses "scalar") (serialize-qp "event_types" $event_types "scalar") (serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/event-streams/($id)/deliveries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific event's delivery history
#
# GET /event-streams/{id}/deliveries/{event_id}
# operationId: get_deliveries_by_event_id
export def "event-streams-deliveries id" [
  id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, event_stream_id: string, status: string, event_type: string, attempts: table<status: string, timestamp: string, error_message: string>, event: record<id: string, source: string, specversion: string, type: string, time: string, data: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event-streams/($id)/deliveries/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redeliver failed events
#
# POST /event-streams/{id}/redeliver
# operationId: post_redeliver
export def "event-streams-redeliver redeliver" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date-from: string # An RFC-3339 date-time for redelivery start, inclusive. Does not allow sub-second precision. (format: date-time)
  --date-to: string # An RFC-3339 date-time for redelivery end, exclusive. Does not allow sub-second precision. (format: date-time)
  --statuses: list # Filter by status
  --event-types: list # Filter by event type
]: any -> record<date_from: string, date_to: string, statuses: list<string>, event_types: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event-streams/($id)/redeliver")
  let body = {date_from: $date_from, date_to: $date_to, statuses: $statuses, event_types: $event_types} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Redeliver a single failed event by ID
#
# POST /event-streams/{id}/redeliver/{event_id}
# operationId: post_redeliver_by_event_id
export def "event-streams-redeliver id" [
  id: string
  event_id: string
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
  let full_url = (build-url $base $"/event-streams/($id)/redeliver/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send a test event to an event stream
#
# POST /event-streams/{id}/test
# operationId: post_test_event
export def "event-streams-test event" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  event_type: string@event-type-completer # The type of event this test event represents.
  --data: record # The raw payload of the test event.
]: any -> record<id: string, event_stream_id: string, status: string, event_type: string, attempts: table<status: string, timestamp: string, error_message: string>, event: record<id: string, source: string, specversion: string, type: string, time: string, data: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event-streams/($id)/test")
  let body = {event_type: $event_type, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Subscribe to events via Server-Sent Events (SSE)
#
# GET /events
# operationId: subscribe_events
export def "events events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Opaque token representing position in the stream. If not provided, stream will start from the latest events.
  --from-timestamp: string # RFC-3339 timestamp indicating where to start streaming events from. This should only be used on the initial query when a cursor may not be available. Subsequent requests should use the cursor (from) as it will be more accurate.
  --event-type: list # Event type(s) to listen for. Specify multiple times for multiple types (e.g., ?event_type=user.created&event_type=user.updated). If not provided, all event types will be streamed.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "from_timestamp" $from_timestamp "scalar") (serialize-qp "event_type" $event_type "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get flows
#
# GET /flows
# operationId: get_flows
export def "flows flows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Defaults to 50.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --hydrate: list # hydration param
  --synchronous: oneof<nothing, bool> # flag to filter by sync/async flows
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "hydrate" $hydrate "multi") (serialize-qp "synchronous" $synchronous "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/flows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a flow
#
# POST /flows
# operationId: post_flows
export def "flows flows-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --actions: list
]: any -> record<id: string, name: string, actions: list<record>, created_at: string, updated_at: string, executed_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/flows")
  let body = {name: $name, actions: $actions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Flows Vault connection list
#
# GET /flows/vault/connections
# operationId: get_flows_vault_connections
export def "flows-vault-connections connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Defaults to 50.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/flows/vault/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Flows Vault connection
#
# POST /flows/vault/connections
# operationId: post_flows_vault_connections
export def "flows-vault-connections connections-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<id: string, app_id: string, environment: string, name: string, account_name: string, ready: bool, created_at: string, updated_at: string, refreshed_at: string, fingerprint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/flows/vault/connections")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Flows Vault connection
#
# GET /flows/vault/connections/{id}
# operationId: get_flows_vault_connections_by_id
export def "flows-vault-connections id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, app_id: string, environment: string, name: string, account_name: string, ready: bool, created_at: string, updated_at: string, refreshed_at: string, fingerprint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/flows/vault/connections/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Flows Vault connection
#
# DELETE /flows/vault/connections/{id}
# operationId: delete_flows_vault_connections_by_id
export def "flows-vault-connections id-by-id-1" [
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
  let full_url = (build-url $base $"/flows/vault/connections/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Flows Vault connection
#
# PATCH /flows/vault/connections/{id}
# operationId: patch_flows_vault_connections_by_id
# --setup shape: {type?: "API_KEY", api_key?: string, base_url?: string, client_id?: string, client_secret?: string, domain?: string, audience?: string, project_id?: string, private_key?: string, client_email?: string, secret_key?: string, code?: string, token?: string, username?: string, password?: string, name?: string, value?: string, in?: "HEADER"|"QUERY", token_endpoint?: string, resource?: string, scope?: string, algorithm?: "HS256"|"HS384"|"HS512"|"RS256"|"RS384"|"RS512"|"ES256"|"ES384"|"ES512"|"PS256"|"PS384"|"PS512", url?: string, public_key?: string, account_id?: string}
export def "flows-vault-connections id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Flows Vault Connection name.
  --setup: record # Flows Vault Connection configuration. — shape: {type?: "API_KEY", api_key?: string, base_url?: string, client_id?: string, client_secret?: string, domain?: string, audience?: string, project_id?: string, private_key?: string, client_email?: string, secret_key?: string, code?: string, token?: string, username?: string, password?: string, name?: string, value?: string, in?: "HEADER"|"QUERY", token_endpoint?: string, resource?: string, scope?: string, algorithm?: "HS256"|"HS384"|"HS512"|"RS256"|"RS384"|"RS512"|"ES256"|"ES384"|"ES512"|"PS256"|"PS384"|"PS512", url?: string, public_key?: string, account_id?: string}
]: any -> record<id: string, app_id: string, environment: string, name: string, account_name: string, ready: bool, created_at: string, updated_at: string, refreshed_at: string, fingerprint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/flows/vault/connections/($id)")
  let body = {name: $name, setup: $setup} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get flow executions
#
# GET /flows/{flow_id}/executions
# operationId: get_flows_executions
export def "flows-executions executions" [
  flow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Defaults to 50.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/flows/($flow_id)/executions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a flow execution
#
# GET /flows/{flow_id}/executions/{execution_id}
# operationId: get_flows_executions_by_execution_id
export def "flows-executions id-by-flow_id-execution_id" [
  flow_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hydrate: list # Hydration param
]: nothing -> record<id: string, trace_id: string, journey_id: string, status: string, debug: record, created_at: string, updated_at: string, started_at: string, ended_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hydrate" $hydrate "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/flows/($flow_id)/executions/($execution_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a flow execution
#
# DELETE /flows/{flow_id}/executions/{execution_id}
# operationId: delete_flows_executions_by_execution_id
export def "flows-executions id-by-flow_id-execution_id-1" [
  flow_id: string
  execution_id: string
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
  let full_url = (build-url $base $"/flows/($flow_id)/executions/($execution_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a flow
#
# GET /flows/{id}
# operationId: get_flows_by_id
export def "flows id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hydrate: list # hydration param
]: nothing -> record<id: string, name: string, actions: list<record>, created_at: string, updated_at: string, executed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hydrate" $hydrate "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/flows/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a flow
#
# DELETE /flows/{id}
# operationId: delete_flows_by_id
export def "flows id-by-id-1" [
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
  let full_url = (build-url $base $"/flows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a flow
#
# PATCH /flows/{id}
# operationId: patch_flows_by_id
export def "flows id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --actions: list # nullable
]: any -> record<id: string, name: string, actions: list<record>, created_at: string, updated_at: string, executed_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/flows/($id)")
  let body = {name: $name, actions: $actions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get forms
#
# GET /forms
# operationId: get_forms
export def "forms forms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Defaults to 50.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --hydrate: list # Query parameter to hydrate the response with additional data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "hydrate" $hydrate "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/forms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a form
#
# POST /forms
# operationId: create_form
# --messages shape: {errors?: record, custom?: record}
# --languages shape: {primary?: string, default?: string}
# --start shape: {hidden_fields?: list, next_node?: any, coordinates?: record}
# --ending shape: {redirection?: record, after_submit?: record, coordinates?: record, resume_flow?: "true"}
# --style shape: {css?: string}
export def "forms form" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --messages: record # shape: {errors?: record, custom?: record}
  --languages: record # shape: {primary?: string, default?: string}
  --translations: record
  --nodes: list
  --start: record # shape: {hidden_fields?: list, next_node?: any, coordinates?: record}
  --ending: record # shape: {redirection?: record, after_submit?: record, coordinates?: record, resume_flow?: "true"}
  --style: record # shape: {css?: string}
]: any -> record<id: string, name: string, messages: record<errors: record, custom: record>, languages: record<primary: string, default: string>, translations: record, nodes: list<record>, start: record<hidden_fields: list<record>, next_node: any, coordinates: record<x: int, y: int>>, ending: record<redirection: record<delay: int, target: string>, after_submit: record<flow_id: string>, coordinates: record<x: int, y: int>, resume_flow: bool>, style: record<css: string>, created_at: string, updated_at: string, embedded_at: string, submitted_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/forms")
  let body = {name: $name, messages: $messages, languages: $languages, translations: $translations, nodes: $nodes, start: $start, ending: $ending, style: $style} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a form
#
# GET /forms/{id}
# operationId: get_form
export def "forms form-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hydrate: list # Query parameter to hydrate the response with additional data
]: nothing -> record<id: string, name: string, messages: record<errors: record, custom: record>, languages: record<primary: string, default: string>, translations: record, nodes: list<record>, start: record<hidden_fields: list<record>, next_node: any, coordinates: record<x: int, y: int>>, ending: record<redirection: record<delay: int, target: string>, after_submit: record<flow_id: string>, coordinates: record<x: int, y: int>, resume_flow: bool>, style: record<css: string>, created_at: string, updated_at: string, embedded_at: string, submitted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hydrate" $hydrate "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/forms/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a form
#
# DELETE /forms/{id}
# operationId: delete_form
export def "forms form-by-id-1" [
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
  let full_url = (build-url $base $"/forms/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a form
#
# PATCH /forms/{id}
# operationId: patch_form
export def "forms form-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --messages: any
  --languages: any
  --translations: any
  --nodes: any
  --start: any
  --ending: any
  --style: any
]: any -> record<id: string, name: string, messages: record<errors: record, custom: record>, languages: record<primary: string, default: string>, translations: record, nodes: list<record>, start: record<hidden_fields: list<record>, next_node: any, coordinates: record<x: int, y: int>>, ending: record<redirection: record<delay: int, target: string>, after_submit: record<flow_id: string>, coordinates: record<x: int, y: int>, resume_flow: bool>, style: record<css: string>, created_at: string, updated_at: string, embedded_at: string, submitted_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/forms/($id)")
  let body = {name: $name, messages: $messages, languages: $languages, translations: $translations, nodes: $nodes, start: $start, ending: $ending, style: $style} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get grants
#
# GET /grants
# operationId: get_grants
export def "grants grants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Number of results per page.
  --page: int # Page index of the results to return. First page is 0.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --user-id: string # user_id of the grants to retrieve.
  --client-id: string # client_id of the grants to retrieve.
  --audience: string # audience of the grants to retrieve.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "audience" $audience "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a grant by user_id
#
# DELETE /grants
# operationId: delete_grants_by_user_id
export def "grants id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: string # user_id of the grant to delete.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a grant by id
#
# DELETE /grants/{id}
# operationId: delete_grants_by_id
export def "grants id-by-id" [
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
  let full_url = (build-url $base $"/grants/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Groups
#
# GET /groups
# operationId: get_groups
export def "groups groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connection-id: string # Filter groups by connection ID.
  --name: string # Filter groups by name.
  --external-id: string # Filter groups by external ID.
  --search: string # Search for groups by name or external ID.
  --qp-fields: string # A comma separated list of fields to include or exclude (depending on include_fields) from the result, empty to retrieve all fields
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false).
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Defaults to 50.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "connection_id" $connection_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "external_id" $external_id "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Group
#
# GET /groups/{id}
# operationId: get_group
export def "groups group-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, external_id: string, connection_id: string, tenant_name: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Group
#
# DELETE /groups/{id}
# operationId: delete_group
export def "groups group-by-id-1" [
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
  let full_url = (build-url $base $"/groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Group Members
#
# GET /groups/{id}/members
# operationId: get_group_members
export def "groups-members members" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # A comma separated list of fields to include or exclude (depending on include_fields) from the result, empty to retrieve all fields
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false).
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
]: nothing -> record<members: table<id: string, member_type: string, type: string, connection_id: string, created_at: string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a multi-factor authentication enrollment ticket
#
# POST /guardian/enrollments/ticket
# operationId: post_ticket
export def "guardian-enrollments-ticket ticket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: string # user_id for the enrollment ticket (format: user-id)
  --email: string # alternate email to which the enrollment email will be sent. Optional - by default, the email will be sent to the user's default address (format: email)
  --send-mail: oneof<nothing, bool> # Send an email to the user to start the enrollment
  --email-locale: string # Optional. Specify the locale of the enrollment email. Used with send_email.
  --factor: string@factor-completer # Optional. Specifies which factor the user must enroll with.<br />Note: Parameter can only be used with Universal Login; it cannot be used with Classic Login or custom MFA pages.
  --allow-multiple-enrollments: oneof<nothing, bool> # Optional. Allows a user who has previously enrolled in MFA to enroll with additional factors.<br />Note: Parameter can only be used with Universal Login; it cannot be used with Classic Login or custom MFA pages.
]: any -> record<ticket_id: string, ticket_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/enrollments/ticket")
  let body = {user_id: $user_id, email: $email, send_mail: $send_mail, email_locale: $email_locale, factor: $factor, allow_multiple_enrollments: $allow_multiple_enrollments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a multi-factor authentication enrollment
#
# GET /guardian/enrollments/{id}
# operationId: get_enrollments_by_id
export def "guardian-enrollments id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, name: string, identifier: string, phone_number: string, enrolled_at: string, last_auth: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guardian/enrollments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a multi-factor authentication enrollment
#
# DELETE /guardian/enrollments/{id}
# operationId: delete_enrollments_by_id
export def "guardian-enrollments id-by-id-1" [
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
  let full_url = (build-url $base $"/guardian/enrollments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Factors and multi-factor authentication details
#
# GET /guardian/factors
# operationId: get_factors
export def "guardian-factors factors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<enabled: bool, trial_expired: bool, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get DUO Configuration
#
# GET /guardian/factors/duo/settings
# operationId: get_factor_duo_settings
export def "guardian-factors-duo-settings settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ikey: string, skey: string, host: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/duo/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the DUO Configuration
#
# PATCH /guardian/factors/duo/settings
# operationId: patch_factor_duo_settings
export def "guardian-factors-duo-settings settings-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ikey: string
  --skey: string # format: non-empty-string
  --host: string
]: any -> record<ikey: string, skey: string, host: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/duo/settings")
  let body = {ikey: $ikey, skey: $skey, host: $host} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set the DUO Configuration
#
# PUT /guardian/factors/duo/settings
# operationId: put_factor_duo_settings
export def "guardian-factors-duo-settings settings-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ikey: string
  --skey: string # format: non-empty-string
  --host: string
]: any -> record<ikey: string, skey: string, host: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/duo/settings")
  let body = {ikey: $ikey, skey: $skey, host: $host} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Enabled Phone Factors
#
# GET /guardian/factors/phone/message-types
# operationId: get_message-types
export def "guardian-factors-phone-message-types message-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message_types: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/phone/message-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the Enabled Phone Factors
#
# PUT /guardian/factors/phone/message-types
# operationId: put_message-types
export def "guardian-factors-phone-message-types message-types-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  message_types: list # The list of phone factors to enable on the tenant. Can include `sms` and `voice`.
]: any -> record<message_types: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/phone/message-types")
  let body = {message_types: $message_types} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Twilio configuration
#
# GET /guardian/factors/phone/providers/twilio
# operationId: get_phone_twilio_factor_provider
export def "guardian-factors-phone-providers-twilio provider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<from: string, messaging_service_sid: string, auth_token: string, sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/phone/providers/twilio")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Twilio configuration
#
# PUT /guardian/factors/phone/providers/twilio
# operationId: put_twilio
export def "guardian-factors-phone-providers-twilio twilio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-from: string # From number (nullable, default: +1223323)
  --messaging-service-sid: string # Copilot SID (nullable, default: 5dEkAiHLPCuQ1uJj4qNXcAnERFAL6cpq)
  --auth-token: string # Twilio Authentication token (nullable, default: zw5Ku6z2sxhd0ZVXto5SDHX6KPDByJPU)
  --sid: string # Twilio SID (nullable, default: wywA2BH4VqTpfywiDuyDAYZL3xQjoO40)
]: any -> record<from: string, messaging_service_sid: string, auth_token: string, sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/phone/providers/twilio")
  let body = {from: $body_from, messaging_service_sid: $messaging_service_sid, auth_token: $auth_token, sid: $sid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get phone provider configuration
#
# GET /guardian/factors/phone/selected-provider
# operationId: get_guardian_phone_providers
export def "guardian-factors-phone-selected-provider providers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/phone/selected-provider")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update phone provider configuration
#
# PUT /guardian/factors/phone/selected-provider
# operationId: put_phone_providers
export def "guardian-factors-phone-selected-provider providers-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  provider: string@provider-completer
]: any -> record<provider: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/phone/selected-provider")
  let body = {provider: $provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Enrollment and Verification Phone Templates
#
# GET /guardian/factors/phone/templates
# operationId: get_factor_phone_templates
export def "guardian-factors-phone-templates templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enrollment_message: string, verification_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/phone/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Enrollment and Verification Phone Templates
#
# PUT /guardian/factors/phone/templates
# operationId: put_factor_phone_templates
export def "guardian-factors-phone-templates templates-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  enrollment_message: string # Message sent to the user when they are invited to enroll with a phone number. (default: {{code}} is your verification code for {{tenant.friendly_name}}. Please enter this code to verify your enrollment.)
  verification_message: string # Message sent to the user when they are prompted to verify their account. (default: {{code}} is your verification code for {{tenant.friendly_name}})
]: any -> record<enrollment_message: string, verification_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/phone/templates")
  let body = {enrollment_message: $enrollment_message, verification_message: $verification_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get APNS push notification configuration
#
# GET /guardian/factors/push-notification/providers/apns
# operationId: get_apns
export def "guardian-factors-push-notification-providers-apns apns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<bundle_id: string, sandbox: bool, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/push-notification/providers/apns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update APNs provider configuration
#
# PATCH /guardian/factors/push-notification/providers/apns
# operationId: patch_apns
export def "guardian-factors-push-notification-providers-apns apns-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sandbox: oneof<nothing, bool>
  --bundle-id: string # nullable
  --p12: string # nullable
]: any -> record<sandbox: bool, bundle_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/push-notification/providers/apns")
  let body = {sandbox: $sandbox, bundle_id: $bundle_id, p12: $p12} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update APNS configuration
#
# PUT /guardian/factors/push-notification/providers/apns
# operationId: put_apns
export def "guardian-factors-push-notification-providers-apns apns-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sandbox: oneof<nothing, bool>
  --bundle-id: string # nullable
  --p12: string # nullable
]: any -> record<sandbox: bool, bundle_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/push-notification/providers/apns")
  let body = {sandbox: $sandbox, bundle_id: $bundle_id, p12: $p12} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates FCM configuration
#
# PATCH /guardian/factors/push-notification/providers/fcm
# operationId: patch_fcm
export def "guardian-factors-push-notification-providers-fcm fcm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --server-key: string # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/push-notification/providers/fcm")
  let body = {server_key: $server_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Overwrite FCM configuration
#
# PUT /guardian/factors/push-notification/providers/fcm
# operationId: put_fcm
export def "guardian-factors-push-notification-providers-fcm fcm-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --server-key: string # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/push-notification/providers/fcm")
  let body = {server_key: $server_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates FCMV1 configuration
#
# PATCH /guardian/factors/push-notification/providers/fcmv1
# operationId: patch_fcmv1
export def "guardian-factors-push-notification-providers-fcmv1 fcmv1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --server-credentials: string # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/push-notification/providers/fcmv1")
  let body = {server_credentials: $server_credentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Overwrite FCMV1 configuration
#
# PUT /guardian/factors/push-notification/providers/fcmv1
# operationId: put_fcmv1
export def "guardian-factors-push-notification-providers-fcmv1 fcmv1-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --server-credentials: string # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/push-notification/providers/fcmv1")
  let body = {server_credentials: $server_credentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get AWS SNS configuration
#
# GET /guardian/factors/push-notification/providers/sns
# operationId: get_sns
export def "guardian-factors-push-notification-providers-sns sns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<aws_access_key_id: string, aws_secret_access_key: string, aws_region: string, sns_apns_platform_application_arn: string, sns_gcm_platform_application_arn: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/push-notification/providers/sns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update AWS SNS configuration
#
# PATCH /guardian/factors/push-notification/providers/sns
# operationId: patch_sns
export def "guardian-factors-push-notification-providers-sns sns-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --aws-access-key-id: string # nullable, default: wywA2BH4VqTpfywiDuyDAYZL3xQjoO40
  --aws-secret-access-key: string # nullable, default: B1ER5JHDGJL3C4sVAKK7SBsq806R3IpL
  --aws-region: string # nullable, default: us-west-1
  --sns-apns-platform-application-arn: string # nullable
  --sns-gcm-platform-application-arn: string # nullable, default: urn://yRMeBxgcCXh8MeTXPBAxhQnm6gP6f5nP
]: any -> record<aws_access_key_id: string, aws_secret_access_key: string, aws_region: string, sns_apns_platform_application_arn: string, sns_gcm_platform_application_arn: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/push-notification/providers/sns")
  let body = {aws_access_key_id: $aws_access_key_id, aws_secret_access_key: $aws_secret_access_key, aws_region: $aws_region, sns_apns_platform_application_arn: $sns_apns_platform_application_arn, sns_gcm_platform_application_arn: $sns_gcm_platform_application_arn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Configure AWS SNS configuration
#
# PUT /guardian/factors/push-notification/providers/sns
# operationId: put_sns
export def "guardian-factors-push-notification-providers-sns sns-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --aws-access-key-id: string # nullable, default: wywA2BH4VqTpfywiDuyDAYZL3xQjoO40
  --aws-secret-access-key: string # nullable, default: B1ER5JHDGJL3C4sVAKK7SBsq806R3IpL
  --aws-region: string # nullable, default: us-west-1
  --sns-apns-platform-application-arn: string # nullable
  --sns-gcm-platform-application-arn: string # nullable, default: urn://yRMeBxgcCXh8MeTXPBAxhQnm6gP6f5nP
]: any -> record<aws_access_key_id: string, aws_secret_access_key: string, aws_region: string, sns_apns_platform_application_arn: string, sns_gcm_platform_application_arn: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/push-notification/providers/sns")
  let body = {aws_access_key_id: $aws_access_key_id, aws_secret_access_key: $aws_secret_access_key, aws_region: $aws_region, sns_apns_platform_application_arn: $sns_apns_platform_application_arn, sns_gcm_platform_application_arn: $sns_gcm_platform_application_arn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get push notification provider
#
# GET /guardian/factors/push-notification/selected-provider
# operationId: get_pn_providers
export def "guardian-factors-push-notification-selected-provider providers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/push-notification/selected-provider")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Push Notification configuration
#
# PUT /guardian/factors/push-notification/selected-provider
# operationId: put_pn_providers
export def "guardian-factors-push-notification-selected-provider providers-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  provider: string@provider-completer-1
]: any -> record<provider: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/push-notification/selected-provider")
  let body = {provider: $provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Twilio SMS configuration
#
# GET /guardian/factors/sms/providers/twilio
# operationId: get_sms_twilio_factor_provider
export def "guardian-factors-sms-providers-twilio provider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<from: string, messaging_service_sid: string, auth_token: string, sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/sms/providers/twilio")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Twilio SMS configuration
#
# PUT /guardian/factors/sms/providers/twilio
# operationId: put_sms_twilio_factor_provider
export def "guardian-factors-sms-providers-twilio provider-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-from: string # From number (nullable, default: +1223323)
  --messaging-service-sid: string # Copilot SID (nullable, default: 5dEkAiHLPCuQ1uJj4qNXcAnERFAL6cpq)
  --auth-token: string # Twilio Authentication token (nullable, default: zw5Ku6z2sxhd0ZVXto5SDHX6KPDByJPU)
  --sid: string # Twilio SID (nullable, default: wywA2BH4VqTpfywiDuyDAYZL3xQjoO40)
]: any -> record<from: string, messaging_service_sid: string, auth_token: string, sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/sms/providers/twilio")
  let body = {from: $body_from, messaging_service_sid: $messaging_service_sid, auth_token: $auth_token, sid: $sid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get SMS configuration
#
# GET /guardian/factors/sms/selected-provider
# operationId: get_sms_providers
export def "guardian-factors-sms-selected-provider providers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/sms/selected-provider")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update SMS configuration
#
# PUT /guardian/factors/sms/selected-provider
# operationId: put_sms_providers
export def "guardian-factors-sms-selected-provider providers-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  provider: string@provider-completer
]: any -> record<provider: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/sms/selected-provider")
  let body = {provider: $provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get SMS enrollment and verification templates
#
# GET /guardian/factors/sms/templates
# operationId: get_factor_sms_templates
export def "guardian-factors-sms-templates templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enrollment_message: string, verification_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/sms/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update SMS enrollment and verification templates
#
# PUT /guardian/factors/sms/templates
# operationId: put_factor_sms_templates
export def "guardian-factors-sms-templates templates-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  enrollment_message: string # Message sent to the user when they are invited to enroll with a phone number. (default: {{code}} is your verification code for {{tenant.friendly_name}}. Please enter this code to verify your enrollment.)
  verification_message: string # Message sent to the user when they are prompted to verify their account. (default: {{code}} is your verification code for {{tenant.friendly_name}})
]: any -> record<enrollment_message: string, verification_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/factors/sms/templates")
  let body = {enrollment_message: $enrollment_message, verification_message: $verification_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update multi-factor authentication type
#
# PUT /guardian/factors/{name}
# operationId: put_factors_by_name
export def "guardian-factors name" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: oneof<nothing, bool> # Whether this factor is enabled (true) or disabled (false).
]: any -> record<enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guardian/factors/($name)")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get multi-factor authentication policies
#
# GET /guardian/policies
# operationId: get_policies
export def "guardian-policies policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/policies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update multi-factor authentication policies
#
# PUT /guardian/policies
# operationId: put_policies
export def "guardian-policies policies-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guardian/policies")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get hooks
#
# GET /hooks
# operationId: get_hooks
export def "hooks hooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --enabled: oneof<nothing, bool> # Optional filter on whether a hook is enabled (true) or disabled (false).
  --qp-fields: string # Comma-separated list of fields to include in the result. Leave empty to retrieve all fields.
  --triggerId: string@triggerId-completer-1 # Retrieves hooks that match the trigger
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "enabled" $enabled "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "triggerId" $triggerId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a hook
#
# POST /hooks
# operationId: post_hooks
export def "hooks hooks-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of this hook. (default: my-hook)
  script: string # Code to be executed when this hook runs. (default: module.exports = function(client, scope, audience, context, cb) cb(null, access_token); };)
  --enabled: oneof<nothing, bool> # Whether this hook will be executed (true) or ignored (false). (default: false)
  --dependencies: record # Dependencies of this hook used by webtask server.
  triggerId: string@triggerId-completer-1 # Retrieves hooks that match the trigger
]: any -> record<triggerId: string, id: string, name: string, enabled: bool, script: string, dependencies: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hooks")
  let body = {name: $name, script: $script, enabled: $enabled, dependencies: $dependencies, triggerId: $triggerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a hook
#
# GET /hooks/{id}
# operationId: get_hooks_by_id
export def "hooks id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the result. Leave empty to retrieve all fields.
]: nothing -> record<triggerId: string, id: string, name: string, enabled: bool, script: string, dependencies: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/hooks/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a hook
#
# DELETE /hooks/{id}
# operationId: delete_hooks_by_id
export def "hooks id-by-id-1" [
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
  let full_url = (build-url $base $"/hooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a hook
#
# PATCH /hooks/{id}
# operationId: patch_hooks_by_id
export def "hooks id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of this hook. (default: my-hook)
  --script: string # Code to be executed when this hook runs. (default: module.exports = function(client, scope, audience, context, cb) cb(null, access_token); };)
  --enabled: oneof<nothing, bool> # Whether this hook will be executed (true) or ignored (false). (default: false)
  --dependencies: record # Dependencies of this hook used by webtask server.
]: any -> record<triggerId: string, id: string, name: string, enabled: bool, script: string, dependencies: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($id)")
  let body = {name: $name, script: $script, enabled: $enabled, dependencies: $dependencies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get hook secrets
#
# GET /hooks/{id}/secrets
# operationId: get_secrets
export def "hooks-secrets secrets-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($id)/secrets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete hook secrets
#
# DELETE /hooks/{id}/secrets
# operationId: delete_secrets
export def "hooks-secrets secrets-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($id)/secrets")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update hook secrets
#
# PATCH /hooks/{id}/secrets
# operationId: patch_secrets
export def "hooks-secrets secrets-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($id)/secrets")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add hook secrets
#
# POST /hooks/{id}/secrets
# operationId: post_secrets
export def "hooks-secrets secrets-by-id-3" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($id)/secrets")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create export users job
#
# POST /jobs/users-exports
# operationId: post_users-exports
# --fields item shape: {name: string, export_as?: string}
export def "jobs-users-exports users-exports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connection-id: string # connection_id of the connection from which users will be exported. (default: con_0000000000000001)
  --format: string@format-completer # Format of the file. Must be `json` or `csv`.
  --limit: int # Limit the number of records. (default: 5)
  --body-fields: list # List of fields to be included in the CSV. Defaults to a predefined set of fields. — item shape: {name: string, export_as?: string}
]: any -> record<status: string, type: string, created_at: string, id: string, connection_id: string, format: string, limit: int, fields: table<name: string, export_as: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/jobs/users-exports")
  let body = {connection_id: $connection_id, format: $format, limit: $limit, fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create import users job
#
# POST /jobs/users-imports
# operationId: post_users-imports
export def "jobs-users-imports users-imports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  users: string
  connection_id: string # connection_id of the connection to which users will be imported. (default: con_0000000000000001)
  --upsert: oneof<nothing, bool> # Whether to update users if they already exist (true) or to ignore them (false). (default: false)
  --external-id: string # Customer-defined ID.
  --send-completion-email: oneof<nothing, bool> # Whether to send a completion email to all tenant owners when the job is finished (true) or not (false). (default: true)
]: any -> record<status: string, type: string, created_at: string, id: string, connection_id: string, external_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/jobs/users-imports")
  let body = {users: $users, connection_id: $connection_id, upsert: $upsert, external_id: $external_id, send_completion_email: $send_completion_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Send an email address verification email
#
# POST /jobs/verification-email
# operationId: post_verification-email
# --identity shape: {user_id: string, provider: "ad"|"adfs"|"amazon"|"apple"|"dropbox"|"bitbucket"|"auth0-oidc"|"auth0"|"baidu"|"bitly"|"box"|"custom"|"daccount"|"dwolla"|"email"|"evernote-sandbox"|"evernote"|"exact"|"facebook"|"fitbit"|"github"|"google-apps"|"google-oauth2"|"instagram"|"ip"|"line"|"linkedin"|"oauth1"|"oauth2"|"office365"|"oidc"|"okta"|"paypal"|"paypal-sandbox"|"pingfederate"|"planningcenter"|"salesforce-community"|"salesforce-sandbox"|"salesforce"|"samlp"|"sharepoint"|"shopify"|"shop"|"sms"|"soundcloud"|"thirtysevensignals"|"twitter"|"untappd"|"vkontakte"|"waad"|"weibo"|"windowslive"|"wordpress"|"yahoo"|"yandex", connection_id?: string}
export def "jobs-verification-email verification-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: string # user_id of the user to send the verification email to. (format: user-id, default: google-oauth2|1234)
  --client-id: string # client_id of the client (application). If no value provided, the global Client ID will be used. (format: client-id)
  --identity: record # This must be provided to verify primary social, enterprise and passwordless email identities. Also, is needed to verify secondary identities. — shape: {user_id: string, provider: "ad"|"adfs"|"amazon"|"apple"|"dropbox"|"bitbucket"|"auth0-oidc"|"auth0"|"baidu"|"bitly"|"box"|"custom"|"daccount"|"dwolla"|"email"|"evernote-sandbox"|"evernote"|"exact"|"facebook"|"fitbit"|"github"|"google-apps"|"google-oauth2"|"instagram"|"ip"|"line"|"linkedin"|"oauth1"|"oauth2"|"office365"|"oidc"|"okta"|"paypal"|"paypal-sandbox"|"pingfederate"|"planningcenter"|"salesforce-community"|"salesforce-sandbox"|"salesforce"|"samlp"|"sharepoint"|"shopify"|"shop"|"sms"|"soundcloud"|"thirtysevensignals"|"twitter"|"untappd"|"vkontakte"|"waad"|"weibo"|"windowslive"|"wordpress"|"yahoo"|"yandex", connection_id?: string}
  --organization-id: string # (Optional) Organization ID – the ID of the Organization. If provided, organization parameters will be made available to the email template and organization branding will be applied to the prompt. In addition, the redirect link in the prompt will include organization_id and organization_name query string parameters. (format: organization-id, default: org_2eondWoxcMIpaLQc)
]: any -> record<status: string, type: string, created_at: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/jobs/verification-email")
  let body = {user_id: $user_id, client_id: $client_id, identity: $identity, organization_id: $organization_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a job
#
# GET /jobs/{id}
# operationId: get_jobs_by_id
export def "jobs id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, type: string, created_at: string, id: string, connection_id: string, location: string, percentage_done: int, time_left_seconds: int, format: string, status_details: string, summary: record<failed: int, updated: int, inserted: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/jobs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get job error details
#
# GET /jobs/{id}/errors
# operationId: get_errors
export def "jobs-errors errors" [
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
  let full_url = (build-url $base $"/jobs/($id)/errors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get custom signing keys
#
# GET /keys/custom-signing
# operationId: get_custom_signing_keys
export def "keys-custom-signing keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<keys: table<kty: string, kid: string, use: string, key_ops: list, alg: string, n: string, e: string, crv: string, x: string, y: string, x5u: string, x5c: list, x5t: string, x5t_S256: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/keys/custom-signing")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete custom signing keys
#
# DELETE /keys/custom-signing
# operationId: delete_custom_signing_keys
export def "keys-custom-signing keys-1" [
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
  let full_url = (build-url $base "/keys/custom-signing")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or replace custom signing keys
#
# PUT /keys/custom-signing
# operationId: put_custom_signing_keys
# --keys item shape: {kty: "EC"|"RSA", kid?: string, use?: "sig", key_ops?: list, alg?: "RS256"|"RS384"|"RS512"|"ES256"|"ES384"|"ES512"|"PS256"|"PS384"|"PS512", n?: string, e?: string, crv?: "P-256"|"P-384"|"P-521", x?: string, y?: string, x5u?: string, x5c?: list, x5t?: string, x5t#S256?: string}
export def "keys-custom-signing keys-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keys: list # An array of custom public signing keys. — item shape: {kty: "EC"|"RSA", kid?: string, use?: "sig", key_ops?: list, alg?: "RS256"|"RS384"|"RS512"|"ES256"|"ES384"|"ES512"|"PS256"|"PS384"|"PS512", n?: string, e?: string, crv?: "P-256"|"P-384"|"P-521", x?: string, y?: string, x5u?: string, x5c?: list, x5t?: string, x5t#S256?: string}
]: any -> record<keys: table<kty: string, kid: string, use: string, key_ops: list, alg: string, n: string, e: string, crv: string, x: string, y: string, x5u: string, x5c: list, x5t: string, x5t_S256: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/keys/custom-signing")
  let body = {keys: $keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all encryption keys
#
# GET /keys/encryption
# operationId: get_encryption_keys
export def "keys-encryption keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Default value is 50, maximum value is 100.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/keys/encryption" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create the new encryption key
#
# POST /keys/encryption
# operationId: post_encryption
export def "keys-encryption encryption" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-4 # Type of the encryption key to be created.
]: any -> record<kid: string, type: string, state: string, created_at: string, updated_at: string, parent_kid: string, public_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/keys/encryption")
  let body = {type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rekey the key hierarchy
#
# POST /keys/encryption/rekey
# operationId: post_encryption_rekey
export def "keys-encryption-rekey rekey" [
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
  let full_url = (build-url $base "/keys/encryption/rekey")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the encryption key by its key id
#
# GET /keys/encryption/{kid}
# operationId: get_encryption_key
export def "keys-encryption key-by-kid" [
  kid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kid: string, type: string, state: string, created_at: string, updated_at: string, parent_kid: string, public_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/encryption/($kid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the encryption key by its key id
#
# DELETE /keys/encryption/{kid}
# operationId: delete_encryption_key
export def "keys-encryption key-by-kid-1" [
  kid: string
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
  let full_url = (build-url $base $"/keys/encryption/($kid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import the encryption key
#
# POST /keys/encryption/{kid}
# operationId: post_encryption_key
export def "keys-encryption key-by-kid-2" [
  kid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  wrapped_key: string # Base64 encoded ciphertext of key material wrapped by public wrapping key.
]: any -> record<kid: string, type: string, state: string, created_at: string, updated_at: string, parent_kid: string, public_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/encryption/($kid)")
  let body = {wrapped_key: $wrapped_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create the public wrapping key
#
# POST /keys/encryption/{kid}/wrapping-key
# operationId: post_encryption_wrapping_key
export def "keys-encryption-wrapping-key key" [
  kid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<public_key: string, algorithm: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/encryption/($kid)/wrapping-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Application Signing Keys
#
# GET /keys/signing
# operationId: get_signing_keys
export def "keys-signing keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<kid: string, cert: string, pkcs7: string, current: bool, next: bool, previous: bool, current_since: any, current_until: any, fingerprint: string, thumbprint: string, revoked: bool, revoked_at: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/keys/signing")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate the Application Signing Key
#
# POST /keys/signing/rotate
# operationId: post_signing_keys
export def "keys-signing-rotate keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cert: string, kid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/keys/signing/rotate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Application Signing Key by its key id
#
# GET /keys/signing/{kid}
# operationId: get_signing_key
export def "keys-signing key" [
  kid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kid: string, cert: string, pkcs7: string, current: bool, next: bool, previous: bool, current_since: any, current_until: any, fingerprint: string, thumbprint: string, revoked: bool, revoked_at: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/signing/($kid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke an Application Signing Key by its key id
#
# PUT /keys/signing/{kid}/revoke
# operationId: put_signing_keys
export def "keys-signing-revoke keys" [
  kid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cert: string, kid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/signing/($kid)/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get log streams
#
# GET /log-streams
# operationId: get_log-streams
export def "log-streams log-streams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/log-streams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a log stream
#
# POST /log-streams
# operationId: post_log-streams
# --filters item shape: {type?: "category", name?: "auth.login.fail"|"auth.login.notification"|"auth.login.success"|"auth.logout.fail"|"auth.logout.success"|"auth.signup.fail"|"auth.signup.success"|"auth.silent_auth.fail"|"auth.silent_auth.success"|"auth.token_exchange.fail"|"auth.token_exchange.success"|"management.fail"|"management.success"|"scim.event"|"system.notification"|"user.fail"|"user.notification"|"user.success"|"actions"|"other"}
# --pii_config shape: {log_fields: list, method?: "mask"|"hash", algorithm?: "xxhash"}
# --sink shape: {httpAuthorization?: string, httpContentFormat?: "JSONARRAY"|"JSONLINES"|"JSONOBJECT", httpContentType?: string, httpEndpoint: string, httpCustomHeaders?: list}
export def "log-streams log-streams-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # log stream name
  --type: string@type-completer-5
  --isPriority: oneof<nothing, bool> # True for priority log streams, false for non-priority
  --filters: list # Only logs events matching these filters will be delivered by the stream. If omitted or empty, all events will be delivered. — item shape: {type?: "category", name?: "auth.login.fail"|"auth.login.notification"|"auth.login.success"|"auth.logout.fail"|"auth.logout.success"|"auth.signup.fail"|"auth.signup.success"|"auth.silent_auth.fail"|"auth.silent_auth.success"|"auth.token_exchange.fail"|"auth.token_exchange.success"|"management.fail"|"management.success"|"scim.event"|"system.notification"|"user.fail"|"user.notification"|"user.success"|"actions"|"other"}
  --pii-config: record # shape: {log_fields: list, method?: "mask"|"hash", algorithm?: "xxhash"}
  --sink: record # shape: {httpAuthorization?: string, httpContentFormat?: "JSONARRAY"|"JSONLINES"|"JSONOBJECT", httpContentType?: string, httpEndpoint: string, httpCustomHeaders?: list}
  --startFrom: string # The optional datetime (ISO 8601) to start streaming logs from (default: 2021-03-01T19:57:29.532Z)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/log-streams")
  let body = {name: $name, type: $type, isPriority: $isPriority, filters: $filters, pii_config: $pii_config, sink: $sink, startFrom: $startFrom} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get log stream by ID
#
# GET /log-streams/{id}
# operationId: get_log-streams_by_id
export def "log-streams id-by-id" [
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
  let full_url = (build-url $base $"/log-streams/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete log stream
#
# DELETE /log-streams/{id}
# operationId: delete_log-streams_by_id
export def "log-streams id-by-id-1" [
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
  let full_url = (build-url $base $"/log-streams/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a log stream
#
# PATCH /log-streams/{id}
# operationId: patch_log-streams_by_id
# --filters item shape: {type?: "category", name?: "auth.login.fail"|"auth.login.notification"|"auth.login.success"|"auth.logout.fail"|"auth.logout.success"|"auth.signup.fail"|"auth.signup.success"|"auth.silent_auth.fail"|"auth.silent_auth.success"|"auth.token_exchange.fail"|"auth.token_exchange.success"|"management.fail"|"management.success"|"scim.event"|"system.notification"|"user.fail"|"user.notification"|"user.success"|"actions"|"other"}
# --pii_config shape: {log_fields: list, method?: "mask"|"hash", algorithm?: "xxhash"}
export def "log-streams id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # log stream name
  --status: string@status-completer-1 # The status of the log stream. Possible values: `active`, `paused`, `suspended`
  --isPriority: oneof<nothing, bool> # True for priority log streams, false for non-priority
  --filters: list # Only logs events matching these filters will be delivered by the stream. If omitted or empty, all events will be delivered. — item shape: {type?: "category", name?: "auth.login.fail"|"auth.login.notification"|"auth.login.success"|"auth.logout.fail"|"auth.logout.success"|"auth.signup.fail"|"auth.signup.success"|"auth.silent_auth.fail"|"auth.silent_auth.success"|"auth.token_exchange.fail"|"auth.token_exchange.success"|"management.fail"|"management.success"|"scim.event"|"system.notification"|"user.fail"|"user.notification"|"user.success"|"actions"|"other"}
  --pii-config: record # shape: {log_fields: list, method?: "mask"|"hash", algorithm?: "xxhash"}
  --sink: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/log-streams/($id)")
  let body = {name: $name, status: $status, isPriority: $isPriority, filters: $filters, pii_config: $pii_config, sink: $sink} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search log events
#
# GET /logs
# operationId: get_logs
export def "logs logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int #  Number of results per page. Paging is disabled if parameter not sent. Default: <code>50</code>. Max value: <code>100</code>
  --qp-sort: string # Field to use for sorting appended with <code>:1</code>  for ascending and <code>:-1</code> for descending. e.g. <code>date:-1</code>
  --qp-fields: string # Comma-separated list of fields to include or exclude (based on value provided for <code>include_fields</code>) in the result. Leave empty to retrieve all fields.
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (<code>true</code>) or excluded (<code>false</code>)
  --include-totals: oneof<nothing, bool> # Return results as an array when false (default). Return results inside an object that also contains a total result count when true.
  --qp-from: string # Log Event Id from which to start selection from.
  --take: int # Number of entries to retrieve when using the <code>from</code> parameter. Default <code>50</code>, max <code>100</code>
  --search: string # Retrieves logs that match the specified search criteria. This parameter can be combined with all the others in the /api/logs endpoint but is specified separately for clarity. If no fields are provided a case insensitive 'starts with' search is performed on all of the following fields: client_name, connection, user_name. Otherwise, you can specify multiple fields and specify the search using the %field%:%search%, for example: application:node user:"John@contoso.com". Values specified without quotes are matched using a case insensitive 'starts with' search. If quotes are used a case insensitve exact search is used. If multiple fields are used, the AND operator is used to join the clauses.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a log event by id
#
# GET /logs/{id}
# operationId: get_logs_by_id
export def "logs id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<date: any, type: string, description: string, connection: string, connection_id: string, client_id: string, client_name: string, ip: string, hostname: string, user_id: string, user_name: string, audience: string, scope: string, strategy: string, strategy_type: string, log_id: string, isMobile: bool, details: record, user_agent: string, security_context: record<ja3: string, ja4: string>, location_info: record<country_code: string, country_code3: string, country_name: string, city_name: string, latitude: float, longitude: float, time_zone: string, continent_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/logs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all access control list entries for a tenant
#
# GET /network-acls
# operationId: get_network-acls
export def "network-acls network-acls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Use this field to request a specific page of the list results.
  --per-page: int # The amount of results per page.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/network-acls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Access Control List
#
# POST /network-acls
# operationId: post_network-acls
# --rule shape: {action: record, match?: record, not_match?: record, scope: "management"|"authentication"|"tenant"|"dynamic_client_registration"}
export def "network-acls network-acls-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string
  --active: oneof<nothing, bool> # Indicates whether or not this access control list is actively being used
  --priority: float # Indicates the order in which the ACL will be evaluated relative to other ACL rules. (default: 50)
  rule: record # shape: {action: record, match?: record, not_match?: record, scope: "management"|"authentication"|"tenant"|"dynamic_client_registration"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/network-acls")
  let body = {description: $description, active: $active, priority: $priority, rule: $rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific access control list entry for a tenant
#
# GET /network-acls/{id}
# operationId: get_network-acls_by_id
export def "network-acls id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, description: string, active: bool, priority: float, rule: record<action: record<block: bool, allow: bool, log: bool, redirect: bool, redirect_uri: string>, match: record<asns: list, geo_country_codes: list, geo_subdivision_codes: list, ipv4_cidrs: list, ipv6_cidrs: list, ja3_fingerprints: list, ja4_fingerprints: list, user_agents: list, hostnames: list, connecting_ipv4_cidrs: list, connecting_ipv6_cidrs: list>, not_match: record<asns: list, geo_country_codes: list, geo_subdivision_codes: list, ipv4_cidrs: list, ipv6_cidrs: list, ja3_fingerprints: list, ja4_fingerprints: list, user_agents: list, hostnames: list, connecting_ipv4_cidrs: list, connecting_ipv6_cidrs: list>, scope: string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network-acls/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Access Control List
#
# DELETE /network-acls/{id}
# operationId: delete_network-acls_by_id
export def "network-acls id-by-id-1" [
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
  let full_url = (build-url $base $"/network-acls/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Partial Update for an Access Control List
#
# PATCH /network-acls/{id}
# operationId: patch_network-acls_by_id
# --rule shape: {action: record, match?: record, not_match?: record, scope: "management"|"authentication"|"tenant"|"dynamic_client_registration"}
export def "network-acls id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string
  --active: oneof<nothing, bool> # Indicates whether or not this access control list is actively being used
  --priority: float # Indicates the order in which the ACL will be evaluated relative to other ACL rules.
  --rule: record # shape: {action: record, match?: record, not_match?: record, scope: "management"|"authentication"|"tenant"|"dynamic_client_registration"}
]: any -> record<id: string, description: string, active: bool, priority: float, rule: record<action: record<block: bool, allow: bool, log: bool, redirect: bool, redirect_uri: string>, match: record<asns: list, geo_country_codes: list, geo_subdivision_codes: list, ipv4_cidrs: list, ipv6_cidrs: list, ja3_fingerprints: list, ja4_fingerprints: list, user_agents: list, hostnames: list, connecting_ipv4_cidrs: list, connecting_ipv6_cidrs: list>, not_match: record<asns: list, geo_country_codes: list, geo_subdivision_codes: list, ipv4_cidrs: list, ipv6_cidrs: list, ja3_fingerprints: list, ja4_fingerprints: list, user_agents: list, hostnames: list, connecting_ipv4_cidrs: list, connecting_ipv6_cidrs: list>, scope: string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network-acls/($id)")
  let body = {description: $description, active: $active, priority: $priority, rule: $rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Access Control List
#
# PUT /network-acls/{id}
# operationId: put_network-acls_by_id
# --rule shape: {action: record, match?: record, not_match?: record, scope: "management"|"authentication"|"tenant"|"dynamic_client_registration"}
export def "network-acls id-by-id-3" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string
  --active: oneof<nothing, bool> # Indicates whether or not this access control list is actively being used
  --priority: float # Indicates the order in which the ACL will be evaluated relative to other ACL rules. (default: 50)
  rule: record # shape: {action: record, match?: record, not_match?: record, scope: "management"|"authentication"|"tenant"|"dynamic_client_registration"}
]: any -> record<id: string, description: string, active: bool, priority: float, rule: record<action: record<block: bool, allow: bool, log: bool, redirect: bool, redirect_uri: string>, match: record<asns: list, geo_country_codes: list, geo_subdivision_codes: list, ipv4_cidrs: list, ipv6_cidrs: list, ja3_fingerprints: list, ja4_fingerprints: list, user_agents: list, hostnames: list, connecting_ipv4_cidrs: list, connecting_ipv6_cidrs: list>, not_match: record<asns: list, geo_country_codes: list, geo_subdivision_codes: list, ipv4_cidrs: list, ipv6_cidrs: list, ja3_fingerprints: list, ja4_fingerprints: list, user_agents: list, hostnames: list, connecting_ipv4_cidrs: list, connecting_ipv6_cidrs: list>, scope: string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network-acls/($id)")
  let body = {description: $description, active: $active, priority: $priority, rule: $rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get organizations
#
# GET /organizations
# operationId: get_organizations
export def "organizations organizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Defaults to 50.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
  --qp-sort: string # Field to sort by. Use <code>field:order</code> where order is <code>1</code> for ascending and <code>-1</code> for descending. e.g. <code>created_at:1</code>. We currently support sorting by the following fields: <code>name</code>, <code>display_name</code> and <code>created_at</code>.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Organization
#
# POST /organizations
# operationId: post_organizations
# --branding shape: {logo_url?: string, colors?: record}
# --enabled_connections item shape: {connection_id: string, assign_membership_on_login?: bool, show_as_button?: bool, is_signup_enabled?: bool}
# --token_quota shape: {client_credentials: record}
export def "organizations organizations-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of this organization. (format: organization-name, default: organization-1)
  --display-name: string # Friendly name of this organization. (default: Acme Users)
  --branding: record # Theme defines how to style the login pages. — shape: {logo_url?: string, colors?: record}
  --metadata: record # Metadata associated with the organization, in the form of an object with string values (max 255 chars). Maximum of 25 metadata properties allowed.
  --enabled-connections: list # Connections that will be enabled for this organization. See POST enabled_connections endpoint for the object format. (Max of 10 connections allowed) — item shape: {connection_id: string, assign_membership_on_login?: bool, show_as_button?: bool, is_signup_enabled?: bool}
  --token-quota: record # shape: {client_credentials: record}
]: any -> record<id: string, name: string, display_name: string, branding: record<logo_url: string, colors: record<primary: string, page_background: string>>, metadata: record, token_quota: record<client_credentials: record<enforce: bool, per_day: int, per_hour: int>>, enabled_connections: table<connection_id: string, assign_membership_on_login: bool, show_as_button: bool, is_signup_enabled: bool, connection: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizations")
  let body = {name: $name, display_name: $display_name, branding: $branding, metadata: $metadata, enabled_connections: $enabled_connections, token_quota: $token_quota} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get organization by name
#
# GET /organizations/name/{name}
# operationId: get_name_by_name
export def "organizations-name name" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, display_name: string, branding: record<logo_url: string, colors: record<primary: string, page_background: string>>, metadata: record, token_quota: record<client_credentials: record<enforce: bool, per_day: int, per_hour: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/name/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization
#
# GET /organizations/{id}
# operationId: get_organizations_by_id
export def "organizations id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, display_name: string, branding: record<logo_url: string, colors: record<primary: string, page_background: string>>, metadata: record, token_quota: record<client_credentials: record<enforce: bool, per_day: int, per_hour: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete organization
#
# DELETE /organizations/{id}
# operationId: delete_organizations_by_id
export def "organizations id-by-id-1" [
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

# Modify an Organization
#
# PATCH /organizations/{id}
# operationId: patch_organizations_by_id
# --branding shape: {logo_url?: string, colors?: record}
# --token_quota shape: {client_credentials: record}
export def "organizations id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --display-name: string # Friendly name of this organization. (default: Acme Users)
  --name: string # The name of this organization. (format: organization-name, default: organization-1)
  --branding: record # Theme defines how to style the login pages. — shape: {logo_url?: string, colors?: record}
  --metadata: record # Metadata associated with the organization, in the form of an object with string values (max 255 chars). Maximum of 25 metadata properties allowed.
  --token-quota: record # nullable — shape: {client_credentials: record}
]: any -> record<id: string, name: string, display_name: string, branding: record<logo_url: string, colors: record<primary: string, page_background: string>>, metadata: record, token_quota: record<client_credentials: record<enforce: bool, per_day: int, per_hour: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)")
  let body = {display_name: $display_name, name: $name, branding: $branding, metadata: $metadata, token_quota: $token_quota} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get client grants associated to an organization
#
# GET /organizations/{id}/client-grants
# operationId: get_organization-client-grants
export def "organizations-client-grants organization-client-grants-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --audience: string # Optional filter on audience of the client grant.
  --client-id: string # Optional filter on client_id of the client grant.
  --grant-ids: list # Optional filter on the ID of the client grant. Must be URL encoded and may be specified multiple times (max 10).<br /><b>e.g.</b> <i>../client-grants?grant_ids=id1&grant_ids=id2</i>
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Defaults to 50.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "audience" $audience "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "grant_ids" $grant_ids "multi") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/client-grants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Associate a client grant with an organization
#
# POST /organizations/{id}/client-grants
# operationId: create_organization-client-grants
export def "organizations-client-grants organization-client-grants-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  grant_id: string # A Client Grant ID to add to the organization. (format: client-grant-id)
]: any -> record<id: string, client_id: string, audience: string, scope: list<string>, organization_usage: string, allow_any_organization: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/client-grants")
  let body = {grant_id: $grant_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a client grant from an organization
#
# DELETE /organizations/{id}/client-grants/{grant_id}
# operationId: delete_client-grants_by_grant_id
export def "organizations-client-grants id" [
  id: string
  grant_id: string
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
  let full_url = (build-url $base $"/organizations/($id)/client-grants/($grant_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get connections associated with an organization
#
# GET /organizations/{id}/connections
# operationId: get_organization_connections
export def "organizations-connections connections" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Defaults to 50.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --is-enabled: oneof<nothing, bool> # Filter connections by enabled status.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "is_enabled" $is_enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a connection to an organization
#
# POST /organizations/{id}/connections
# operationId: post_organization_connection
export def "organizations-connections connection-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organization-connection-name: string # Name of the connection in the scope of this organization.
  --assign-membership-on-login: oneof<nothing, bool> # When true, all users that log in with this connection will be automatically granted membership in the organization. When false, users must be granted membership in the organization before logging in with this connection.
  --show-as-button: oneof<nothing, bool> # Determines whether a connection should be displayed on this organization’s login prompt. Only applicable for enterprise connections. Default: true.
  --is-signup-enabled: oneof<nothing, bool> # Determines whether organization signup should be enabled for this organization connection. Only applicable for database connections. Default: false.
  --organization-access-level: string@organization-access-level-completer # Access level for the organization (e.g., "none", "full").
  --is-enabled: oneof<nothing, bool> # Whether the connection is enabled for the organization.
  connection_id: string # Connection identifier. (format: connection-id)
]: any -> record<organization_connection_name: string, assign_membership_on_login: bool, show_as_button: bool, is_signup_enabled: bool, organization_access_level: string, is_enabled: bool, connection_id: string, connection: record<name: string, strategy: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/connections")
  let body = {organization_connection_name: $organization_connection_name, assign_membership_on_login: $assign_membership_on_login, show_as_button: $show_as_button, is_signup_enabled: $is_signup_enabled, organization_access_level: $organization_access_level, is_enabled: $is_enabled, connection_id: $connection_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific connection associated with an organization
#
# GET /organizations/{id}/connections/{connection_id}
# operationId: get_organization_connection
export def "organizations-connections connection-by-id-connection_id" [
  id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_connection_name: string, assign_membership_on_login: bool, show_as_button: bool, is_signup_enabled: bool, organization_access_level: string, is_enabled: bool, connection_id: string, connection: record<name: string, strategy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/connections/($connection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a connection from an organization
#
# DELETE /organizations/{id}/connections/{connection_id}
# operationId: delete_organization_connection
export def "organizations-connections connection-by-id-connection_id-1" [
  id: string
  connection_id: string
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
  let full_url = (build-url $base $"/organizations/($id)/connections/($connection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a connection for an organization
#
# PATCH /organizations/{id}/connections/{connection_id}
# operationId: patch_organization_connection
export def "organizations-connections connection-by-id-connection_id-2" [
  id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organization-connection-name: string # Name of the connection in the scope of this organization. (nullable)
  --assign-membership-on-login: oneof<nothing, bool> # When true, all users that log in with this connection will be automatically granted membership in the organization. When false, users must be granted membership in the organization before logging in with this connection.
  --show-as-button: oneof<nothing, bool> # Determines whether a connection should be displayed on this organization’s login prompt. Only applicable for enterprise connections. Default: true.
  --is-signup-enabled: oneof<nothing, bool> # Determines whether organization signup should be enabled for this organization connection. Only applicable for database connections. Default: false.
  --organization-access-level: string@organization-access-level-completer-1 # Access level for the organization (e.g., "none", "full"). (nullable)
  --is-enabled: oneof<nothing, bool> # Whether the connection is enabled for the organization. (nullable)
]: any -> record<organization_connection_name: string, assign_membership_on_login: bool, show_as_button: bool, is_signup_enabled: bool, organization_access_level: string, is_enabled: bool, connection_id: string, connection: record<name: string, strategy: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/connections/($connection_id)")
  let body = {organization_connection_name: $organization_connection_name, assign_membership_on_login: $assign_membership_on_login, show_as_button: $show_as_button, is_signup_enabled: $is_signup_enabled, organization_access_level: $organization_access_level, is_enabled: $is_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all organization discovery domains
#
# GET /organizations/{id}/discovery-domains
# operationId: get_discovery-domains
export def "organizations-discovery-domains discovery-domains-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
]: nothing -> record<next: string, domains: table<id: string, domain: string, status: string, use_for_organization_discovery: bool, verification_txt: string, verification_host: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/discovery-domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an organization discovery domain
#
# POST /organizations/{id}/discovery-domains
# operationId: post_discovery-domains
export def "organizations-discovery-domains discovery-domains-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain: string # The domain name to associate with the organization e.g. acme.com.
  --status: string@status-completer-2 # The verification status of the discovery domain.
  --use-for-organization-discovery: oneof<nothing, bool> # Indicates whether this domain should be used for organization discovery.
]: any -> record<id: string, domain: string, status: string, use_for_organization_discovery: bool, verification_txt: string, verification_host: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/discovery-domains")
  let body = {domain: $domain, status: $status, use_for_organization_discovery: $use_for_organization_discovery} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an organization discovery domain by domain name
#
# GET /organizations/{id}/discovery-domains/name/{discovery_domain}
# operationId: get_name_by_discovery_domain
export def "organizations-discovery-domains-name domain" [
  id: string
  discovery_domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, domain: string, status: string, use_for_organization_discovery: bool, verification_txt: string, verification_host: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/discovery-domains/name/($discovery_domain)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an organization discovery domain by ID
#
# GET /organizations/{id}/discovery-domains/{discovery_domain_id}
# operationId: get_discovery-domains_by_discovery_domain_id
export def "organizations-discovery-domains id-by-id-discovery_domain_id" [
  id: string
  discovery_domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, domain: string, status: string, use_for_organization_discovery: bool, verification_txt: string, verification_host: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/discovery-domains/($discovery_domain_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an organization discovery domain
#
# DELETE /organizations/{id}/discovery-domains/{discovery_domain_id}
# operationId: delete_discovery-domains_by_discovery_domain_id
export def "organizations-discovery-domains id-by-id-discovery_domain_id-1" [
  id: string
  discovery_domain_id: string
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
  let full_url = (build-url $base $"/organizations/($id)/discovery-domains/($discovery_domain_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an organization discovery domain
#
# PATCH /organizations/{id}/discovery-domains/{discovery_domain_id}
# operationId: patch_discovery-domains_by_discovery_domain_id
export def "organizations-discovery-domains id-by-id-discovery_domain_id-2" [
  id: string
  discovery_domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-2 # The verification status of the discovery domain.
  --use-for-organization-discovery: oneof<nothing, bool> # Indicates whether this domain should be used for organization discovery.
]: any -> record<id: string, domain: string, status: string, use_for_organization_discovery: bool, verification_txt: string, verification_host: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/discovery-domains/($discovery_domain_id)")
  let body = {status: $status, use_for_organization_discovery: $use_for_organization_discovery} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get connections enabled for an organization
#
# GET /organizations/{id}/enabled_connections
# operationId: get_enabled_connections
export def "organizations-enabled-connections connections-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Defaults to 50.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/enabled_connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add connections to an organization
#
# POST /organizations/{id}/enabled_connections
# operationId: post_enabled_connections
export def "organizations-enabled-connections connections-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connection_id: string # Single connection ID to add to the organization. (format: connection-id)
  --assign-membership-on-login: oneof<nothing, bool> # When true, all users that log in with this connection will be automatically granted membership in the organization. When false, users must be granted membership in the organization before logging in with this connection.
  --is-signup-enabled: oneof<nothing, bool> # Determines whether organization signup should be enabled for this organization connection. Only applicable for database connections. Default: false.
  --show-as-button: oneof<nothing, bool> # Determines whether a connection should be displayed on this organization’s login prompt. Only applicable for enterprise connections. Default: true.
]: any -> record<connection_id: string, assign_membership_on_login: bool, show_as_button: bool, is_signup_enabled: bool, connection: record<name: string, strategy: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/enabled_connections")
  let body = {connection_id: $connection_id, assign_membership_on_login: $assign_membership_on_login, is_signup_enabled: $is_signup_enabled, show_as_button: $show_as_button} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an enabled connection for an organization
#
# GET /organizations/{id}/enabled_connections/{connectionId}
# operationId: get_enabled_connections_by_connectionId
export def "organizations-enabled-connections connectionId-by-id-connectionId" [
  id: string
  connectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<connection_id: string, assign_membership_on_login: bool, show_as_button: bool, is_signup_enabled: bool, connection: record<name: string, strategy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/enabled_connections/($connectionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete connections from an organization
#
# DELETE /organizations/{id}/enabled_connections/{connectionId}
# operationId: delete_enabled_connections_by_connectionId
export def "organizations-enabled-connections connectionId-by-id-connectionId-1" [
  id: string
  connectionId: string
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
  let full_url = (build-url $base $"/organizations/($id)/enabled_connections/($connectionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the Connection of an Organization
#
# PATCH /organizations/{id}/enabled_connections/{connectionId}
# operationId: patch_enabled_connections_by_connectionId
export def "organizations-enabled-connections connectionId-by-id-connectionId-2" [
  id: string
  connectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assign-membership-on-login: oneof<nothing, bool> # When true, all users that log in with this connection will be automatically granted membership in the organization. When false, users must be granted membership in the organization before logging in with this connection.
  --is-signup-enabled: oneof<nothing, bool> # Determines whether organization signup should be enabled for this organization connection. Only applicable for database connections. Default: false.
  --show-as-button: oneof<nothing, bool> # Determines whether a connection should be displayed on this organization’s login prompt. Only applicable for enterprise connections. Default: true.
]: any -> record<connection_id: string, assign_membership_on_login: bool, show_as_button: bool, is_signup_enabled: bool, connection: record<name: string, strategy: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/enabled_connections/($connectionId)")
  let body = {assign_membership_on_login: $assign_membership_on_login, is_signup_enabled: $is_signup_enabled, show_as_button: $show_as_button} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get invitations to an organization
#
# GET /organizations/{id}/invitations
# operationId: get_invitations
export def "organizations-invitations invitations-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Defaults to 50.
  --include-totals: oneof<nothing, bool> # When true, return results inside an object that also contains the start and limit.  When false (default), a direct array of results is returned.  We do not yet support returning the total invitations count.
  --qp-fields: string # Comma-separated list of fields to include or exclude (based on value provided for include_fields) in the result. Leave empty to retrieve all fields.
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false). Defaults to true.
  --qp-sort: string # Field to sort by. Use field:order where order is 1 for ascending and -1 for descending Defaults to created_at:-1.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create invitations to an organization
#
# POST /organizations/{id}/invitations
# operationId: post_invitations
# --inviter shape: {name: string}
# --invitee shape: {email: string}
export def "organizations-invitations invitations-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  inviter: record # shape: {name: string}
  invitee: record # shape: {email: string}
  client_id: string # Auth0 client ID. Used to resolve the application's login initiation endpoint. (format: client-id, default: AaiyAPdpYdesoKnqjj8HJqRn4T5titww)
  --connection-id: string # The id of the connection to force invitee to authenticate with. (format: connection-id, default: con_0000000000000001)
  --app-metadata: record # Data related to the user that does affect the application's core functionality.
  --user-metadata: record # Data related to the user that does not affect the application's core functionality.
  --ttl-sec: int # Number of seconds for which the invitation is valid before expiration. If unspecified or set to 0, this value defaults to 604800 seconds (7 days). Max value: 2592000 seconds (30 days).
  --roles: list # List of roles IDs to associated with the user.
  --send-invitation-email: oneof<nothing, bool> # Whether the user will receive an invitation email (true) or no email (false), true by default (default: true)
]: any -> record<id: string, organization_id: string, inviter: record<name: string>, invitee: record<email: string>, invitation_url: string, created_at: string, expires_at: string, client_id: string, connection_id: string, app_metadata: record, user_metadata: record, roles: list<string>, ticket_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/invitations")
  let body = {inviter: $inviter, invitee: $invitee, client_id: $client_id, connection_id: $connection_id, app_metadata: $app_metadata, user_metadata: $user_metadata, ttl_sec: $ttl_sec, roles: $roles, send_invitation_email: $send_invitation_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific invitation to an Organization
#
# GET /organizations/{id}/invitations/{invitation_id}
# operationId: get_invitations_by_invitation_id
export def "organizations-invitations id-by-id-invitation_id" [
  id: string
  invitation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include or exclude (based on value provided for include_fields) in the result. Leave empty to retrieve all fields.
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false). Defaults to true.
]: nothing -> record<id: string, organization_id: string, inviter: record<name: string>, invitee: record<email: string>, invitation_url: string, created_at: string, expires_at: string, client_id: string, connection_id: string, app_metadata: record, user_metadata: record, roles: list<string>, ticket_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/invitations/($invitation_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an invitation to an Organization
#
# DELETE /organizations/{id}/invitations/{invitation_id}
# operationId: delete_invitations_by_invitation_id
export def "organizations-invitations id-by-id-invitation_id-1" [
  id: string
  invitation_id: string
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
  let full_url = (build-url $base $"/organizations/($id)/invitations/($invitation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get members who belong to an organization
#
# GET /organizations/{id}/members
# operationId: get_organization_members
export def "organizations-members members-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Defaults to 50.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
  --qp-fields: string # Comma-separated list of fields to include or exclude (based on value provided for include_fields) in the result. Leave empty to retrieve all fields.
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete members from an organization
#
# DELETE /organizations/{id}/members
# operationId: delete_members
export def "organizations-members members-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  members: list # List of user IDs to remove from the organization.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/members")
  let body = {members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add members to an organization
#
# POST /organizations/{id}/members
# operationId: post_members
export def "organizations-members members-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  members: list # List of user IDs to add to the organization as members.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/members")
  let body = {members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get user roles assigned to an Organization member
#
# GET /organizations/{id}/members/{user_id}/roles
# operationId: get_organization_member_roles
export def "organizations-members-roles roles-by-id-user_id" [
  id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Defaults to 50.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/members/($user_id)/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete user roles from an Organization member
#
# DELETE /organizations/{id}/members/{user_id}/roles
# operationId: delete_organization_member_roles
export def "organizations-members-roles roles-by-id-user_id-1" [
  id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  roles: list # List of roles IDs associated with the organization member to remove.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/members/($user_id)/roles")
  let body = {roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign user roles to an Organization member
#
# POST /organizations/{id}/members/{user_id}/roles
# operationId: post_organization_member_roles
export def "organizations-members-roles roles-by-id-user_id-2" [
  id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  roles: list # List of roles IDs to associated with the user.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/members/($user_id)/roles")
  let body = {roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get prompt settings
#
# GET /prompts
# operationId: get_prompts
export def "prompts prompts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<universal_login_experience: string, identifier_first: bool, webauthn_platform_first_factor: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prompts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update prompt settings
#
# PATCH /prompts
# operationId: patch_prompts
export def "prompts prompts-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --universal-login-experience: string@universal-login-experience-completer # Which login experience to use. Can be `new` or `classic`.
  --identifier-first: oneof<nothing, bool> # Whether identifier first is enabled or not (nullable)
  --webauthn-platform-first-factor: oneof<nothing, bool> # Use WebAuthn with Device Biometrics as the first authentication factor (nullable)
]: any -> record<universal_login_experience: string, identifier_first: bool, webauthn_platform_first_factor: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prompts")
  let body = {universal_login_experience: $universal_login_experience, identifier_first: $identifier_first, webauthn_platform_first_factor: $webauthn_platform_first_factor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get render setting configurations for all screens
#
# GET /prompts/rendering
# operationId: get_all_rendering
export def "prompts-rendering rendering" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include or exclude (based on value provided for include_fields) in the result. Leave empty to retrieve all fields.
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (default: true) or excluded (false).
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Maximum value is 100, default value is 50.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total configuration count (true) or as a direct array of results (false, default).
  --prompt: string # Name of the prompt to filter by
  --screen: string # Name of the screen to filter by
  --rendering-mode: string@rendering-mode-completer # Rendering mode to filter by
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "prompt" $prompt "scalar") (serialize-qp "screen" $screen "scalar") (serialize-qp "rendering_mode" $rendering_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prompts/rendering" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update render settings for multiple screens
#
# PATCH /prompts/rendering
# operationId: patch_bulk_rendering
# --configs item shape: {prompt: "login"|"login-id"|"login-password"|"login-passwordless"|"login-email-verification"|"signup"|"signup-id"|"signup-password"|"phone-identifier-enrollment"|"phone-identifier-challenge"|"email-identifier-challenge"|"reset-password"|"custom-form"|"consent"|"customized-consent"|"logout"|"mfa-push"|"mfa-otp"|"mfa-voice"|"mfa-phone"|"mfa-webauthn"|"mfa-sms"|"mfa-email"|"mfa-recovery-code"|"mfa"|"status"|"device-flow"|"email-verification"|"email-otp-challenge"|"organizations"|"invitation"|"common"|"passkeys"|"captcha"|"brute-force-protection"|"async-approval-flow", screen: "login"|"login-id"|"login-password"|"login-passwordless-email-code"|"login-passwordless-email-link"|"login-passwordless-sms-otp"|"login-email-verification"|"signup"|"signup-id"|"signup-password"|"phone-identifier-enrollment"|"phone-identifier-challenge"|"email-identifier-challenge"|"reset-password-request"|"reset-password-email"|"reset-password"|"reset-password-success"|"reset-password-error"|"reset-password-mfa-email-challenge"|"reset-password-mfa-otp-challenge"|"reset-password-mfa-phone-challenge"|"reset-password-mfa-push-challenge-push"|"reset-password-mfa-recovery-code-challenge"|"reset-password-mfa-sms-challenge"|"reset-password-mfa-voice-challenge"|"reset-password-mfa-webauthn-platform-challenge"|"reset-password-mfa-webauthn-roaming-challenge"|"custom-form"|"consent"|"customized-consent"|"logout"|"logout-complete"|"logout-aborted"|"mfa-push-welcome"|"mfa-push-enrollment-qr"|"mfa-push-enrollment-code"|"mfa-push-success"|"mfa-push-challenge-push"|"mfa-push-list"|"mfa-otp-enrollment-qr"|"mfa-otp-enrollment-code"|"mfa-otp-challenge"|"mfa-voice-enrollment"|"mfa-voice-challenge"|"mfa-phone-challenge"|"mfa-phone-enrollment"|"mfa-webauthn-platform-enrollment"|"mfa-webauthn-roaming-enrollment"|"mfa-webauthn-platform-challenge"|"mfa-webauthn-roaming-challenge"|"mfa-webauthn-change-key-nickname"|"mfa-webauthn-enrollment-success"|"mfa-webauthn-error"|"mfa-webauthn-not-available-error"|"mfa-country-codes"|"mfa-sms-enrollment"|"mfa-sms-challenge"|"mfa-sms-list"|"mfa-email-challenge"|"mfa-email-list"|"mfa-recovery-code-enrollment"|"mfa-recovery-code-challenge-new-code"|"mfa-recovery-code-challenge"|"mfa-detect-browser-capabilities"|"mfa-enroll-result"|"mfa-login-options"|"mfa-begin-enroll-options"|"status"|"device-code-activation"|"device-code-activation-allowed"|"device-code-activation-denied"|"device-code-confirmation"|"email-verification-result"|"email-otp-challenge"|"organization-selection"|"organization-picker"|"pre-login-organization-picker"|"accept-invitation"|"redeem-ticket"|"passkey-enrollment"|"passkey-enrollment-local"|"interstitial-captcha"|"brute-force-protection-unblock"|"brute-force-protection-unblock-success"|"brute-force-protection-unblock-failure"|"async-approval-error"|"async-approval-accepted"|"async-approval-denied"|"async-approval-wrong-user", rendering_mode?: "advanced"|"standard", context_configuration?: list, default_head_tags_disabled?: bool, use_page_template?: bool, head_tags?: list, filters?: record}
export def "prompts-rendering rendering-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  configs: list # Array of screen configurations to update — item shape: {prompt: "login"|"login-id"|"login-password"|"login-passwordless"|"login-email-verification"|"signup"|"signup-id"|"signup-password"|"phone-identifier-enrollment"|"phone-identifier-challenge"|"email-identifier-challenge"|"reset-password"|"custom-form"|"consent"|"customized-consent"|"logout"|"mfa-push"|"mfa-otp"|"mfa-voice"|"mfa-phone"|"mfa-webauthn"|"mfa-sms"|"mfa-email"|"mfa-recovery-code"|"mfa"|"status"|"device-flow"|"email-verification"|"email-otp-challenge"|"organizations"|"invitation"|"common"|"passkeys"|"captcha"|"brute-force-protection"|"async-approval-flow", screen: "login"|"login-id"|"login-password"|"login-passwordless-email-code"|"login-passwordless-email-link"|"login-passwordless-sms-otp"|"login-email-verification"|"signup"|"signup-id"|"signup-password"|"phone-identifier-enrollment"|"phone-identifier-challenge"|"email-identifier-challenge"|"reset-password-request"|"reset-password-email"|"reset-password"|"reset-password-success"|"reset-password-error"|"reset-password-mfa-email-challenge"|"reset-password-mfa-otp-challenge"|"reset-password-mfa-phone-challenge"|"reset-password-mfa-push-challenge-push"|"reset-password-mfa-recovery-code-challenge"|"reset-password-mfa-sms-challenge"|"reset-password-mfa-voice-challenge"|"reset-password-mfa-webauthn-platform-challenge"|"reset-password-mfa-webauthn-roaming-challenge"|"custom-form"|"consent"|"customized-consent"|"logout"|"logout-complete"|"logout-aborted"|"mfa-push-welcome"|"mfa-push-enrollment-qr"|"mfa-push-enrollment-code"|"mfa-push-success"|"mfa-push-challenge-push"|"mfa-push-list"|"mfa-otp-enrollment-qr"|"mfa-otp-enrollment-code"|"mfa-otp-challenge"|"mfa-voice-enrollment"|"mfa-voice-challenge"|"mfa-phone-challenge"|"mfa-phone-enrollment"|"mfa-webauthn-platform-enrollment"|"mfa-webauthn-roaming-enrollment"|"mfa-webauthn-platform-challenge"|"mfa-webauthn-roaming-challenge"|"mfa-webauthn-change-key-nickname"|"mfa-webauthn-enrollment-success"|"mfa-webauthn-error"|"mfa-webauthn-not-available-error"|"mfa-country-codes"|"mfa-sms-enrollment"|"mfa-sms-challenge"|"mfa-sms-list"|"mfa-email-challenge"|"mfa-email-list"|"mfa-recovery-code-enrollment"|"mfa-recovery-code-challenge-new-code"|"mfa-recovery-code-challenge"|"mfa-detect-browser-capabilities"|"mfa-enroll-result"|"mfa-login-options"|"mfa-begin-enroll-options"|"status"|"device-code-activation"|"device-code-activation-allowed"|"device-code-activation-denied"|"device-code-confirmation"|"email-verification-result"|"email-otp-challenge"|"organization-selection"|"organization-picker"|"pre-login-organization-picker"|"accept-invitation"|"redeem-ticket"|"passkey-enrollment"|"passkey-enrollment-local"|"interstitial-captcha"|"brute-force-protection-unblock"|"brute-force-protection-unblock-success"|"brute-force-protection-unblock-failure"|"async-approval-error"|"async-approval-accepted"|"async-approval-denied"|"async-approval-wrong-user", rendering_mode?: "advanced"|"standard", context_configuration?: list, default_head_tags_disabled?: bool, use_page_template?: bool, head_tags?: list, filters?: record}
]: any -> record<configs: table<prompt: string, screen: string, rendering_mode: string, context_configuration: list, default_head_tags_disabled: bool, use_page_template: bool, head_tags: list, filters: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prompts/rendering")
  let body = {configs: $configs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get custom text for a prompt
#
# GET /prompts/{prompt}/custom-text/{language}
# operationId: get_custom-text_by_language
export def "prompts-custom-text language-by-prompt-language" [
  prompt: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prompts/($prompt)/custom-text/($language)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set custom text for a specific prompt
#
# PUT /prompts/{prompt}/custom-text/{language}
# operationId: put_custom-text_by_language
export def "prompts-custom-text language-by-prompt-language-1" [
  prompt: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prompts/($prompt)/custom-text/($language)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get partials for a prompt
#
# GET /prompts/{prompt}/partials
# operationId: get_partials
export def "prompts-partials partials-by-prompt" [
  prompt: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prompts/($prompt)/partials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set partials for a prompt
#
# PUT /prompts/{prompt}/partials
# operationId: put_partials
export def "prompts-partials partials-by-prompt-1" [
  prompt: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prompts/($prompt)/partials")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get render settings for a screen
#
# GET /prompts/{prompt}/screen/{screen}/rendering
# operationId: get_rendering
export def "prompts-screen-rendering rendering-by-prompt-screen" [
  prompt: string
  screen: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tenant: string, prompt: string, screen: string, rendering_mode: string, context_configuration: list<any>, default_head_tags_disabled: bool, use_page_template: bool, head_tags: table<tag: string, attributes: record, content: string>, filters: record<match_type: string, clients: list<record>, organizations: list<record>, domains: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prompts/($prompt)/screen/($screen)/rendering")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update render settings for a screen
#
# PATCH /prompts/{prompt}/screen/{screen}/rendering
# operationId: patch_rendering
# --head_tags item shape: {tag?: string, attributes?: record, content?: string}
# --filters shape: {match_type?: "includes_any"|"excludes_any", clients?: list, organizations?: list, domains?: list}
export def "prompts-screen-rendering rendering-by-prompt-screen-1" [
  prompt: string
  screen: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rendering-mode: string@rendering-mode-completer # Rendering mode to filter by
  --context-configuration: list # Context values to make available (nullable)
  --default-head-tags-disabled: oneof<nothing, bool> # Override Universal Login default head tags (nullable, default: false)
  --use-page-template: oneof<nothing, bool> # Use page template with ACUL (nullable, default: false)
  --head-tags: list # An array of head tags (nullable) — item shape: {tag?: string, attributes?: record, content?: string}
  --filters: record # Optional filters to apply rendering rules to specific entities (nullable) — shape: {match_type?: "includes_any"|"excludes_any", clients?: list, organizations?: list, domains?: list}
]: any -> record<rendering_mode: string, context_configuration: list<any>, default_head_tags_disabled: bool, use_page_template: bool, head_tags: table<tag: string, attributes: record, content: string>, filters: record<match_type: string, clients: list<record>, organizations: list<record>, domains: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prompts/($prompt)/screen/($screen)/rendering")
  let body = {rendering_mode: $rendering_mode, context_configuration: $context_configuration, default_head_tags_disabled: $default_head_tags_disabled, use_page_template: $use_page_template, head_tags: $head_tags, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get refresh tokens
#
# GET /refresh-tokens
# operationId: get_refresh_tokens
export def "refresh-tokens tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: string # ID of the user whose refresh tokens to retrieve. Required.
  --client-id: string # Filter results by client ID. Only valid when user_id is provided.
  --qp-from: string # An opaque cursor from which to start the selection (exclusive). Expires after 24 hours. Obtained from the next property of a previous response.
  --take: int # Number of results per page. Defaults to 50.
  --qp-fields: string # Comma-separated list of fields to include or exclude (based on value provided for include_fields) in the result. Leave empty to retrieve all fields.
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false).
]: nothing -> record<refresh_tokens: table<id: string, user_id: string, created_at: any, idle_expires_at: any, expires_at: any, device: record, client_id: string, session_id: string, rotating: bool, resource_servers: list, refresh_token_metadata: record, last_exchanged_at: any>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/refresh-tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke refresh tokens
#
# POST /refresh-tokens/revoke
# operationId: revoke_refresh_tokens
export def "refresh-tokens-revoke tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Array of refresh token IDs to revoke. Limited to 100 at a time.
  --user-id: string # Revoke all refresh tokens for this user. (format: user-id)
  --client-id: string # Revoke all refresh tokens for this client. (format: client-id)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/refresh-tokens/revoke")
  let body = {ids: $ids, user_id: $user_id, client_id: $client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a refresh token
#
# GET /refresh-tokens/{id}
# operationId: get_refresh_token
export def "refresh-tokens token-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, user_id: string, created_at: any, idle_expires_at: any, expires_at: any, device: record<initial_ip: string, initial_asn: string, initial_user_agent: string, last_ip: string, last_asn: string, last_user_agent: string>, client_id: string, session_id: string, rotating: bool, resource_servers: table<audience: string, scopes: string>, refresh_token_metadata: record, last_exchanged_at: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/refresh-tokens/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a refresh token
#
# DELETE /refresh-tokens/{id}
# operationId: delete_refresh_token
export def "refresh-tokens token-by-id-1" [
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
  let full_url = (build-url $base $"/refresh-tokens/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a refresh token
#
# PATCH /refresh-tokens/{id}
# operationId: patch_refresh-tokens_by_id
export def "refresh-tokens id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --refresh-token-metadata: record # Metadata associated with the refresh token, in the form of an object with string values (max 255 chars). Maximum of 25 metadata properties allowed. (nullable)
]: any -> record<id: string, user_id: string, created_at: any, idle_expires_at: any, expires_at: any, device: record<initial_ip: string, initial_asn: string, initial_user_agent: string, last_ip: string, last_asn: string, last_user_agent: string>, client_id: string, session_id: string, rotating: bool, resource_servers: table<audience: string, scopes: string>, refresh_token_metadata: record, last_exchanged_at: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/refresh-tokens/($id)")
  let body = {refresh_token_metadata: $refresh_token_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get resource servers
#
# GET /resource-servers
# operationId: get_resource-servers
export def "resource-servers resource-servers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifiers: list # An optional filter on the resource server identifier. Must be URL encoded and may be specified multiple times (max 10).<br /><b>e.g.</b> <i>../resource-servers?identifiers=id1&identifiers=id2</i>
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifiers" $identifiers "multi") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resource-servers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a resource server
#
# POST /resource-servers
# operationId: post_resource-servers
# --scopes item shape: {value: string, description?: string}
# --token_encryption shape: {format: "compact-nested-jwe", encryption_key: record}
# --proof_of_possession shape: {mechanism: "mtls"|"dpop", required: bool, required_for?: "public_clients"|"all_clients"}
# --subject_type_authorization shape: {user?: record, client?: record}
# --authorization_policy shape: {policy_id: string}
export def "resource-servers resource-servers-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Friendly name for this resource server. Can not contain `<` or `>` characters.
  identifier: string # Unique identifier for the API used as the audience parameter on authorization calls. Can not be changed once set.
  --scopes: list # List of permissions (scopes) that this API uses. — item shape: {value: string, description?: string}
  --signing-alg: string@signing-alg-completer-1 # Algorithm used to sign JWTs. Can be `HS256` (default) or `RS256`. `PS256` available via addon. (default: HS256)
  --signing-secret: string # Secret used to sign tokens when using symmetric algorithms (HS256).
  --allow-offline-access: oneof<nothing, bool> # Whether refresh tokens can be issued for this API (true) or not (false).
  --allow-online-access: oneof<nothing, bool> # Whether Online Refresh Tokens can be issued for this API (true) or not (false).
  --token-lifetime: int # Expiration value (in seconds) for access tokens issued for this API from the token endpoint.
  --token-dialect: string@token-dialect-completer # Dialect of issued access token. `access_token` is a JWT containing standard Auth0 claims; `rfc9068_profile` is a JWT conforming to the IETF JWT Access Token Profile. `access_token_authz` and `rfc9068_profile_authz` additionally include RBAC permissions claims.
  --skip-consent-for-verifiable-first-party-clients: oneof<nothing, bool> # Whether to skip user consent for applications flagged as first party (true) or not (false).
  --enforce-policies: oneof<nothing, bool> # Whether to enforce authorization policies (true) or to ignore them (false).
  --token-encryption: record # nullable — shape: {format: "compact-nested-jwe", encryption_key: record}
  --consent-policy: string@consent-policy-completer # nullable
  --authorization-details: list # nullable
  --proof-of-possession: record # Proof-of-Possession configuration for access tokens (nullable) — shape: {mechanism: "mtls"|"dpop", required: bool, required_for?: "public_clients"|"all_clients"}
  --subject-type-authorization: record # Defines application access permission for a resource server — shape: {user?: record, client?: record}
  --authorization-policy: record # Authorization policy for the resource server. (nullable) — shape: {policy_id: string}
]: any -> record<id: string, name: string, is_system: bool, identifier: string, scopes: table<value: string, description: string>, signing_alg: string, signing_secret: string, allow_offline_access: bool, allow_online_access: bool, skip_consent_for_verifiable_first_party_clients: bool, token_lifetime: int, token_lifetime_for_web: int, enforce_policies: bool, token_dialect: string, token_encryption: record<format: any, encryption_key: record<name: string, alg: string, kid: string, pem: string>>, consent_policy: string, authorization_details: list<any>, proof_of_possession: record<mechanism: string, required: bool, required_for: string>, subject_type_authorization: record<user: record<policy: string>, client: record<policy: string>>, authorization_policy: record<policy_id: string>, client_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/resource-servers")
  let body = {name: $name, identifier: $identifier, scopes: $scopes, signing_alg: $signing_alg, signing_secret: $signing_secret, allow_offline_access: $allow_offline_access, allow_online_access: $allow_online_access, token_lifetime: $token_lifetime, token_dialect: $token_dialect, skip_consent_for_verifiable_first_party_clients: $skip_consent_for_verifiable_first_party_clients, enforce_policies: $enforce_policies, token_encryption: $token_encryption, consent_policy: $consent_policy, authorization_details: $authorization_details, proof_of_possession: $proof_of_possession, subject_type_authorization: $subject_type_authorization, authorization_policy: $authorization_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a resource server
#
# GET /resource-servers/{id}
# operationId: get_resource-servers_by_id
export def "resource-servers id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false).
]: nothing -> record<id: string, name: string, is_system: bool, identifier: string, scopes: table<value: string, description: string>, signing_alg: string, signing_secret: string, allow_offline_access: bool, allow_online_access: bool, skip_consent_for_verifiable_first_party_clients: bool, token_lifetime: int, token_lifetime_for_web: int, enforce_policies: bool, token_dialect: string, token_encryption: record<format: any, encryption_key: record<name: string, alg: string, kid: string, pem: string>>, consent_policy: string, authorization_details: list<any>, proof_of_possession: record<mechanism: string, required: bool, required_for: string>, subject_type_authorization: record<user: record<policy: string>, client: record<policy: string>>, authorization_policy: record<policy_id: string>, client_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/resource-servers/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a resource server
#
# DELETE /resource-servers/{id}
# operationId: delete_resource-servers_by_id
export def "resource-servers id-by-id-1" [
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
  let full_url = (build-url $base $"/resource-servers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a resource server
#
# PATCH /resource-servers/{id}
# operationId: patch_resource-servers_by_id
# --scopes item shape: {value: string, description?: string}
# --token_encryption shape: {format: "compact-nested-jwe", encryption_key: record}
# --proof_of_possession shape: {mechanism: "mtls"|"dpop", required: bool, required_for?: "public_clients"|"all_clients"}
# --subject_type_authorization shape: {user?: record, client?: record}
# --authorization_policy shape: {policy_id: string}
export def "resource-servers id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Friendly name for this resource server. Can not contain `<` or `>` characters.
  --scopes: list # List of permissions (scopes) that this API uses. — item shape: {value: string, description?: string}
  --signing-alg: string@signing-alg-completer-1 # Algorithm used to sign JWTs. Can be `HS256` (default) or `RS256`. `PS256` available via addon. (default: HS256)
  --signing-secret: string # Secret used to sign tokens when using symmetric algorithms (HS256).
  --skip-consent-for-verifiable-first-party-clients: oneof<nothing, bool> # Whether to skip user consent for applications flagged as first party (true) or not (false).
  --allow-offline-access: oneof<nothing, bool> # Whether refresh tokens can be issued for this API (true) or not (false).
  --allow-online-access: oneof<nothing, bool> # Whether Online Refresh Tokens can be issued for this API (true) or not (false).
  --token-lifetime: int # Expiration value (in seconds) for access tokens issued for this API from the token endpoint.
  --token-dialect: string@token-dialect-completer # Dialect of issued access token. `access_token` is a JWT containing standard Auth0 claims; `rfc9068_profile` is a JWT conforming to the IETF JWT Access Token Profile. `access_token_authz` and `rfc9068_profile_authz` additionally include RBAC permissions claims.
  --enforce-policies: oneof<nothing, bool> # Whether authorization policies are enforced (true) or not enforced (false).
  --token-encryption: record # nullable — shape: {format: "compact-nested-jwe", encryption_key: record}
  --consent-policy: string@consent-policy-completer # nullable
  --authorization-details: list # nullable
  --proof-of-possession: record # Proof-of-Possession configuration for access tokens (nullable) — shape: {mechanism: "mtls"|"dpop", required: bool, required_for?: "public_clients"|"all_clients"}
  --subject-type-authorization: record # Defines application access permission for a resource server — shape: {user?: record, client?: record}
  --authorization-policy: record # Authorization policy for the resource server. (nullable) — shape: {policy_id: string}
]: any -> record<id: string, name: string, is_system: bool, identifier: string, scopes: table<value: string, description: string>, signing_alg: string, signing_secret: string, allow_offline_access: bool, allow_online_access: bool, skip_consent_for_verifiable_first_party_clients: bool, token_lifetime: int, token_lifetime_for_web: int, enforce_policies: bool, token_dialect: string, token_encryption: record<format: any, encryption_key: record<name: string, alg: string, kid: string, pem: string>>, consent_policy: string, authorization_details: list<any>, proof_of_possession: record<mechanism: string, required: bool, required_for: string>, subject_type_authorization: record<user: record<policy: string>, client: record<policy: string>>, authorization_policy: record<policy_id: string>, client_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/resource-servers/($id)")
  let body = {name: $name, scopes: $scopes, signing_alg: $signing_alg, signing_secret: $signing_secret, skip_consent_for_verifiable_first_party_clients: $skip_consent_for_verifiable_first_party_clients, allow_offline_access: $allow_offline_access, allow_online_access: $allow_online_access, token_lifetime: $token_lifetime, token_dialect: $token_dialect, enforce_policies: $enforce_policies, token_encryption: $token_encryption, consent_policy: $consent_policy, authorization_details: $authorization_details, proof_of_possession: $proof_of_possession, subject_type_authorization: $subject_type_authorization, authorization_policy: $authorization_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get risk assessment settings
#
# GET /risk-assessments/settings
# operationId: get_risk_assessments_settings
export def "risk-assessments-settings settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/risk-assessments/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update risk assessment settings
#
# PATCH /risk-assessments/settings
# operationId: patch_risk_assessments_settings
export def "risk-assessments-settings settings-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: oneof<nothing, bool> # Whether or not risk assessment is enabled.
]: any -> record<enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/risk-assessments/settings")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get new device assessor
#
# GET /risk-assessments/settings/new-device
# operationId: get_new-device
export def "risk-assessments-settings-new-device new-device" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<remember_for: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/risk-assessments/settings/new-device")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update new device assessor
#
# PATCH /risk-assessments/settings/new-device
# operationId: patch_new-device
export def "risk-assessments-settings-new-device new-device-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  remember_for: int # Length of time to remember devices for, in days.
]: any -> record<remember_for: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/risk-assessments/settings/new-device")
  let body = {remember_for: $remember_for} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get roles
#
# GET /roles
# operationId: get_roles
export def "roles roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Number of results per page. Defaults to 50.
  --page: int # Page index of the results to return. First page is 0.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --name-filter: string # Optional filter on name (case-insensitive).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "name_filter" $name_filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a role
#
# POST /roles
# operationId: post_roles
export def "roles roles-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the role.
  --description: string # Description of the role.
]: any -> record<id: string, name: string, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a role
#
# GET /roles/{id}
# operationId: get_roles_by_id
export def "roles id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a role
#
# DELETE /roles/{id}
# operationId: delete_roles_by_id
export def "roles id-by-id-1" [
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
  let full_url = (build-url $base $"/roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a role
#
# PATCH /roles/{id}
# operationId: patch_roles_by_id
export def "roles id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of this role.
  --description: string # Description of this role.
]: any -> record<id: string, name: string, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get permissions granted by role
#
# GET /roles/{id}/permissions
# operationId: get_role_permission
export def "roles-permissions permission" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Number of results per page. Defaults to 50.
  --page: int # Page index of the results to return. First page is 0.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_totals" $include_totals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/roles/($id)/permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove permissions from a role
#
# DELETE /roles/{id}/permissions
# operationId: delete_role_permission_assignment
# --permissions item shape: {resource_server_identifier: string, permission_name: string}
export def "roles-permissions assignment-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissions: list # array of resource_server_identifier, permission_name pairs. — item shape: {resource_server_identifier: string, permission_name: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($id)/permissions")
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Associate permissions with a role
#
# POST /roles/{id}/permissions
# operationId: post_role_permission_assignment
# --permissions item shape: {resource_server_identifier: string, permission_name: string}
export def "roles-permissions assignment-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissions: list # array of resource_server_identifier, permission_name pairs. — item shape: {resource_server_identifier: string, permission_name: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($id)/permissions")
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a role's users
#
# GET /roles/{id}/users
# operationId: get_role_user
export def "roles-users user" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Number of results per page. Defaults to 50.
  --page: int # Page index of the results to return. First page is 0.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/roles/($id)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign users to a role
#
# POST /roles/{id}/users
# operationId: post_role_users
export def "roles-users users" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  users: list # user_id's of the users to assign the role to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($id)/users")
  let body = {users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get rules
#
# GET /rules
# operationId: get_rules
export def "rules rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --enabled: oneof<nothing, bool> # Optional filter on whether a rule is enabled (true) or disabled (false).
  --qp-fields: string # Comma-separated list of fields to include or exclude (based on value provided for include_fields) in the result. Leave empty to retrieve all fields.
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "enabled" $enabled "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a rule
#
# POST /rules
# operationId: post_rules
export def "rules rules-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of this rule. (default: my-rule)
  script: string # Code to be executed when this rule runs. (default: function (user, context, callback) {   callback(null, user, context); })
  --order: float # Order that this rule should execute in relative to other rules. Lower-valued rules execute first. (default: 2)
  --enabled: oneof<nothing, bool> # Whether the rule is enabled (true), or disabled (false). (default: true)
]: any -> record<name: string, id: string, enabled: bool, script: string, order: float, stage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rules")
  let body = {name: $name, script: $script, order: $order, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve config variable keys for rules (get_rules-configs)
#
# GET /rules-configs
# operationId: get_rules-configs
export def "rules-configs rules-configs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rules-configs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete rules config for a given key
#
# DELETE /rules-configs/{key}
# operationId: delete_rules-configs_by_key
export def "rules-configs key-by-key" [
  key: string
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
  let full_url = (build-url $base $"/rules-configs/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set rules config for a given key
#
# PUT /rules-configs/{key}
# operationId: put_rules-configs_by_key
export def "rules-configs key-by-key-1" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  value: string # Value for a rules config variable. (default: MY_RULES_CONFIG_VALUE)
]: any -> record<key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rules-configs/($key)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a rule
#
# GET /rules/{id}
# operationId: get_rules_by_id
export def "rules id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include or exclude (based on value provided for include_fields) in the result. Leave empty to retrieve all fields.
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false).
]: nothing -> record<name: string, id: string, enabled: bool, script: string, order: float, stage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rules/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a rule
#
# DELETE /rules/{id}
# operationId: delete_rules_by_id
export def "rules id-by-id-1" [
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
  let full_url = (build-url $base $"/rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a rule
#
# PATCH /rules/{id}
# operationId: patch_rules_by_id
export def "rules id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --script: string # Code to be executed when this rule runs. (default: function (user, context, callback) {   callback(null, user, context); })
  --name: string # Name of this rule. (default: my-rule)
  --order: float # Order that this rule should execute in relative to other rules. Lower-valued rules execute first. (default: 2)
  --enabled: oneof<nothing, bool> # Whether the rule is enabled (true), or disabled (false). (default: true)
]: any -> record<name: string, id: string, enabled: bool, script: string, order: float, stage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rules/($id)")
  let body = {script: $script, name: $name, order: $order, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get self-service profiles
#
# GET /self-service-profiles
# operationId: get_self-service-profiles
export def "self-service-profiles self-service-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Defaults to 50.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service-profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a self-service profile
#
# POST /self-service-profiles
# operationId: post_self-service-profiles
# --branding shape: {logo_url?: string, colors?: record}
# --user_attributes item shape: {name: string, description: string, is_optional: bool}
export def "self-service-profiles self-service-profiles-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the self-service Profile.
  --description: string # The description of the self-service Profile.
  --branding: record # shape: {logo_url?: string, colors?: record}
  --allowed-strategies: list # List of IdP strategies that will be shown to users during the Self-Service Enterprise Configuration flow. Possible values: [`oidc`, `samlp`, `waad`, `google-apps`, `adfs`, `okta`, `auth0-samlp`, `okta-samlp`, `keycloak-samlp`, `pingfederate`]
  --user-attributes: list # List of attributes to be mapped that will be shown to the user during the Self-Service Enterprise Configuration flow. — item shape: {name: string, description: string, is_optional: bool}
  --user-attribute-profile-id: string # ID of the user-attribute-profile to associate with this self-service profile. (format: user-attribute-profile-id)
]: any -> record<id: string, name: string, description: string, user_attributes: table<name: string, description: string, is_optional: bool>, created_at: string, updated_at: string, branding: record<logo_url: string, colors: record<primary: string>>, allowed_strategies: list<string>, user_attribute_profile_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/self-service-profiles")
  let body = {name: $name, description: $description, branding: $branding, allowed_strategies: $allowed_strategies, user_attributes: $user_attributes, user_attribute_profile_id: $user_attribute_profile_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a self-service profile by Id
#
# GET /self-service-profiles/{id}
# operationId: get_self-service-profiles_by_id
export def "self-service-profiles id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, user_attributes: table<name: string, description: string, is_optional: bool>, created_at: string, updated_at: string, branding: record<logo_url: string, colors: record<primary: string>>, allowed_strategies: list<string>, user_attribute_profile_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/self-service-profiles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a self-service profile by Id
#
# DELETE /self-service-profiles/{id}
# operationId: delete_self-service-profiles_by_id
export def "self-service-profiles id-by-id-1" [
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
  let full_url = (build-url $base $"/self-service-profiles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a self-service profile
#
# PATCH /self-service-profiles/{id}
# operationId: patch_self-service-profiles_by_id
# --user_attributes item shape: {name: string, description: string, is_optional: bool}
export def "self-service-profiles id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the self-service Profile.
  --description: string # The description of the self-service Profile. (nullable)
  --branding: any
  --allowed-strategies: list # List of IdP strategies that will be shown to users during the Self-Service Enterprise Configuration flow. Possible values: [`oidc`, `samlp`, `waad`, `google-apps`, `adfs`, `okta`, `auth0-samlp`, `okta-samlp`, `keycloak-samlp`, `pingfederate`]
  --user-attributes: list # List of attributes to be mapped that will be shown to the user during the Self-Service Enterprise Configuration flow. (nullable) — item shape: {name: string, description: string, is_optional: bool}
  --user-attribute-profile-id: string # ID of the user-attribute-profile to associate with this self-service profile. (nullable, format: user-attribute-profile-id)
]: any -> record<id: string, name: string, description: string, user_attributes: table<name: string, description: string, is_optional: bool>, created_at: string, updated_at: string, branding: record<logo_url: string, colors: record<primary: string>>, allowed_strategies: list<string>, user_attribute_profile_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/self-service-profiles/($id)")
  let body = {name: $name, description: $description, branding: $branding, allowed_strategies: $allowed_strategies, user_attributes: $user_attributes, user_attribute_profile_id: $user_attribute_profile_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get custom text for a self-service profile
#
# GET /self-service-profiles/{id}/custom-text/{language}/{page}
# operationId: get_self_service_profile_custom_text
export def "self-service-profiles-custom-text text-by-id-language-page" [
  id: string
  language: string
  page: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/self-service-profiles/($id)/custom-text/($language)/($page)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set custom text for a self-service profile
#
# PUT /self-service-profiles/{id}/custom-text/{language}/{page}
# operationId: put_self_service_profile_custom_text
export def "self-service-profiles-custom-text text-by-id-language-page-1" [
  id: string
  language: string
  page: string
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
  let full_url = (build-url $base $"/self-service-profiles/($id)/custom-text/($language)/($page)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an access ticket to initiate the Self-Service Enterprise Configuration flow
#
# POST /self-service-profiles/{id}/sso-ticket
# operationId: post_sso-ticket
# --connection_config shape: {name: string, display_name?: string, is_domain_connection?: bool, show_as_button?: bool, metadata?: record, options?: record}
# --enabled_organizations item shape: {organization_id: string, assign_membership_on_login?: bool, show_as_button?: bool}
# --domain_aliases_config shape: {domain_verification: "none"|"optional"|"required", pending_domains?: list}
# --provisioning_config shape: {scopes?: list, google_workspace?: record, token_lifetime?: int}
# --enabled_features shape: {sso?: bool, domain_verification?: bool, provisioning?: bool}
export def "self-service-profiles-sso-ticket sso-ticket" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connection-id: string # If provided, this will allow editing of the provided connection during the Self-Service Enterprise Configuration flow (format: connection-id)
  --connection-config: record # If provided, this will create a new connection for the Self-Service Enterprise Configuration flow with the given configuration — shape: {name: string, display_name?: string, is_domain_connection?: bool, show_as_button?: bool, metadata?: record, options?: record}
  --enabled-clients: list # List of client_ids that the connection will be enabled for.
  --enabled-organizations: list # List of organizations that the connection will be enabled for. — item shape: {organization_id: string, assign_membership_on_login?: bool, show_as_button?: bool}
  --ttl-sec: int # Number of seconds for which the ticket is valid before expiration. If unspecified or set to 0, this value defaults to 432000 seconds (5 days).
  --domain-aliases-config: record # Configuration for the setup of the connection’s domain_aliases in the Self-Service Enterprise Configuration flow. — shape: {domain_verification: "none"|"optional"|"required", pending_domains?: list}
  --provisioning-config: record # Configuration for the setup of Provisioning in the self-service flow. — shape: {scopes?: list, google_workspace?: record, token_lifetime?: int}
  --use-for-organization-discovery: oneof<nothing, bool> # Indicates whether a verified domain should be used for organization discovery during authentication.
  --enabled-features: record # Specifies which features are enabled for an "edit connection" ticket. Only applicable when connection ID is provided. — shape: {sso?: bool, domain_verification?: bool, provisioning?: bool}
]: any -> record<ticket: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/self-service-profiles/($id)/sso-ticket")
  let body = {connection_id: $connection_id, connection_config: $connection_config, enabled_clients: $enabled_clients, enabled_organizations: $enabled_organizations, ttl_sec: $ttl_sec, domain_aliases_config: $domain_aliases_config, provisioning_config: $provisioning_config, use_for_organization_discovery: $use_for_organization_discovery, enabled_features: $enabled_features} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke a Self-Service Enterprise Configuration access ticket
#
# POST /self-service-profiles/{profileId}/sso-ticket/{id}/revoke
# operationId: post_revoke
export def "self-service-profiles-sso-ticket-revoke revoke" [
  profileId: string
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
  let full_url = (build-url $base $"/self-service-profiles/($profileId)/sso-ticket/($id)/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get session
#
# GET /sessions/{id}
# operationId: get_session
export def "sessions session-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, user_id: string, created_at: any, updated_at: any, authenticated_at: any, idle_expires_at: any, expires_at: any, last_interacted_at: any, device: record<initial_user_agent: string, initial_ip: string, initial_asn: string, last_user_agent: string, last_ip: string, last_asn: string>, clients: table<client_id: string>, authentication: record<methods: list<record>>, cookie: record<mode: string>, session_metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sessions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete session
#
# DELETE /sessions/{id}
# operationId: delete_session
export def "sessions session-by-id-1" [
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
  let full_url = (build-url $base $"/sessions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update session
#
# PATCH /sessions/{id}
# operationId: patch_sessions_by_id
export def "sessions id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --session-metadata: record # Metadata associated with the session, in the form of an object with string values (max 255 chars). Maximum of 25 metadata properties allowed. (nullable)
]: any -> record<id: string, user_id: string, created_at: any, updated_at: any, authenticated_at: any, idle_expires_at: any, expires_at: any, last_interacted_at: any, device: record<initial_user_agent: string, initial_ip: string, initial_asn: string, last_user_agent: string, last_ip: string, last_asn: string>, clients: table<client_id: string>, authentication: record<methods: list<record>>, cookie: record<mode: string>, session_metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sessions/($id)")
  let body = {session_metadata: $session_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revokes a session
#
# POST /sessions/{id}/revoke
# operationId: revoke_session
export def "sessions-revoke session" [
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
  let full_url = (build-url $base $"/sessions/($id)/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get active users count
#
# GET /stats/active-users
# operationId: get_active-users
export def "stats-active-users active-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats/active-users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get daily stats
#
# GET /stats/daily
# operationId: get_daily
export def "stats-daily daily" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Optional first day of the date range (inclusive) in YYYYMMDD format.
  --qp-to: string # Optional last day of the date range (inclusive) in YYYYMMDD format.
]: nothing -> table<date: string, logins: int, signups: int, leaked_passwords: int, updated_at: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/daily" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the supplemental signals configuration for a tenant
#
# GET /supplemental-signals
# operationId: get_supplemental-signals
export def "supplemental-signals supplemental-signals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<akamai_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/supplemental-signals")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the supplemental signals configuration for a tenant
#
# PATCH /supplemental-signals
# operationId: patch_supplemental-signals
export def "supplemental-signals supplemental-signals-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --akamai-enabled: oneof<nothing, bool> # Indicates if incoming Akamai Headers should be processed
]: any -> record<akamai_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/supplemental-signals")
  let body = {akamai_enabled: $akamai_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get tenant settings
#
# GET /tenants/settings
# operationId: tenant_settings_route
export def "tenants-settings route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include or exclude (based on value provided for include_fields) in the result. Leave empty to retrieve all fields.
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false).
]: nothing -> record<change_password: record<enabled: bool, html: string>, guardian_mfa_page: record<enabled: bool, html: string>, default_audience: string, default_directory: string, error_page: record<html: string, show_log_link: bool, url: string>, device_flow: record<charset: string, mask: string>, default_token_quota: record<clients: record<client_credentials: record>, organizations: record<client_credentials: record>>, flags: record<change_pwd_flow_v1: bool, enable_apis_section: bool, disable_impersonation: bool, enable_client_connections: bool, enable_pipeline2: bool, allow_legacy_delegation_grant_types: bool, allow_legacy_ro_grant_types: bool, allow_legacy_tokeninfo_endpoint: bool, enable_legacy_profile: bool, enable_idtoken_api2: bool, enable_public_signup_user_exists_error: bool, enable_sso: bool, allow_changing_enable_sso: bool, disable_clickjack_protection_headers: bool, no_disclose_enterprise_connections: bool, enforce_client_authentication_on_passwordless_start: bool, enable_adfs_waad_email_verification: bool, revoke_refresh_token_grant: bool, dashboard_log_streams_next: bool, dashboard_insights_view: bool, disable_fields_map_fix: bool, mfa_show_factor_list_on_enrollment: bool, remove_alg_from_jwks: bool, improved_signup_bot_detection_in_classic: bool, genai_trial: bool, enable_dynamic_client_registration: bool, disable_management_api_sms_obfuscation: bool, trust_azure_adfs_email_verified_connection_property: bool, custom_domains_provisioning: bool>, friendly_name: string, picture_url: string, support_email: string, support_url: string, allowed_logout_urls: list<string>, session_lifetime: float, idle_session_lifetime: float, ephemeral_session_lifetime: float, idle_ephemeral_session_lifetime: float, sandbox_version: string, legacy_sandbox_version: string, sandbox_versions_available: list<string>, default_redirection_uri: string, enabled_locales: list<string>, session_cookie: record<mode: string>, sessions: record<oidc_logout_prompt_enabled: bool>, oidc_logout: record<rp_logout_end_session_endpoint_discovery: bool>, allow_organization_name_in_authentication_api: bool, customize_mfa_in_postlogin_action: bool, acr_values_supported: list<string>, mtls: record<enable_endpoint_aliases: bool>, pushed_authorization_requests_supported: bool, authorization_response_iss_parameter_supported: bool, skip_non_verifiable_callback_uri_confirmation_prompt: bool, resource_parameter_profile: string, client_id_metadata_document_supported: bool, phone_consolidated_experience: bool, enable_ai_guide: bool, dynamic_client_registration_security_mode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tenants/settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update tenant settings
#
# PATCH /tenants/settings
# operationId: patch_settings
# --change_password shape: {enabled?: bool, html?: string}
# --device_flow shape: {charset?: "base20"|"digits", mask?: string}
# --guardian_mfa_page shape: {enabled?: bool, html?: string}
# --error_page shape: {html?: string, show_log_link?: bool, url?: string}
# --default_token_quota shape: {clients?: record, organizations?: record}
# --flags shape: {change_pwd_flow_v1?: bool, enable_apis_section?: bool, disable_impersonation?: bool, enable_client_connections?: bool, enable_pipeline2?: bool, allow_legacy_delegation_grant_types?: bool, allow_legacy_ro_grant_types?: bool, allow_legacy_tokeninfo_endpoint?: bool, enable_legacy_profile?: bool, enable_idtoken_api2?: bool, enable_public_signup_user_exists_error?: bool, enable_sso?: bool, allow_changing_enable_sso?: bool, disable_clickjack_protection_headers?: bool, no_disclose_enterprise_connections?: bool, enforce_client_authentication_on_passwordless_start?: bool, enable_adfs_waad_email_verification?: bool, revoke_refresh_token_grant?: bool, dashboard_log_streams_next?: bool, dashboard_insights_view?: bool, disable_fields_map_fix?: bool, mfa_show_factor_list_on_enrollment?: bool, remove_alg_from_jwks?: bool, improved_signup_bot_detection_in_classic?: bool, genai_trial?: bool, enable_dynamic_client_registration?: bool, disable_management_api_sms_obfuscation?: bool, trust_azure_adfs_email_verified_connection_property?: bool, custom_domains_provisioning?: bool}
# --session_cookie shape: {mode: "persistent"|"non-persistent"}
# --sessions shape: {oidc_logout_prompt_enabled?: bool}
# --oidc_logout shape: {rp_logout_end_session_endpoint_discovery?: bool}
# --mtls shape: {enable_endpoint_aliases?: bool}
export def "tenants-settings settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --change-password: record # Change Password page customization. (nullable) — shape: {enabled?: bool, html?: string}
  --device-flow: record # Device Flow configuration (nullable) — shape: {charset?: "base20"|"digits", mask?: string}
  --guardian-mfa-page: record # Guardian page customization. (nullable) — shape: {enabled?: bool, html?: string}
  --default-audience: string # Default audience for API Authorization. (default: )
  --default-directory: string # Name of connection used for password grants at the `/token` endpoint. The following connection types are supported: LDAP, AD, Database Connections, Passwordless, Windows Azure Active Directory, ADFS. (default: )
  --error-page: record # Error page customization. (nullable) — shape: {html?: string, show_log_link?: bool, url?: string}
  --default-token-quota: record # Token Quota configuration, to configure quotas for token issuance for clients and organizations. Applied to all clients and organizations unless overridden in individual client or organization settings. (nullable) — shape: {clients?: record, organizations?: record}
  --flags: record # Flags used to change the behavior of this tenant. — shape: {change_pwd_flow_v1?: bool, enable_apis_section?: bool, disable_impersonation?: bool, enable_client_connections?: bool, enable_pipeline2?: bool, allow_legacy_delegation_grant_types?: bool, allow_legacy_ro_grant_types?: bool, allow_legacy_tokeninfo_endpoint?: bool, enable_legacy_profile?: bool, enable_idtoken_api2?: bool, enable_public_signup_user_exists_error?: bool, enable_sso?: bool, allow_changing_enable_sso?: bool, disable_clickjack_protection_headers?: bool, no_disclose_enterprise_connections?: bool, enforce_client_authentication_on_passwordless_start?: bool, enable_adfs_waad_email_verification?: bool, revoke_refresh_token_grant?: bool, dashboard_log_streams_next?: bool, dashboard_insights_view?: bool, disable_fields_map_fix?: bool, mfa_show_factor_list_on_enrollment?: bool, remove_alg_from_jwks?: bool, improved_signup_bot_detection_in_classic?: bool, genai_trial?: bool, enable_dynamic_client_registration?: bool, disable_management_api_sms_obfuscation?: bool, trust_azure_adfs_email_verified_connection_property?: bool, custom_domains_provisioning?: bool}
  --friendly-name: string # Friendly name for this tenant. (default: My Company)
  --picture-url: string # URL of logo to be shown for this tenant (recommended size: 150x150) (format: absolute-uri-or-empty, default: https://mycompany.org/logo.png)
  --support-email: string # End-user support email. (format: email-or-empty, default: support@mycompany.org)
  --support-url: string # End-user support url. (format: absolute-uri-or-empty, default: https://mycompany.org/support)
  --allowed-logout-urls: list # URLs that are valid to redirect to after logout from Auth0.
  --session-lifetime: int # Number of hours a session will stay valid. (default: 168)
  --idle-session-lifetime: int # Number of hours for which a session can be inactive before the user must log in again. (default: 72)
  --ephemeral-session-lifetime: int # Number of hours an ephemeral (non-persistent) session will stay valid. (default: 72)
  --idle-ephemeral-session-lifetime: int # Number of hours for which an ephemeral (non-persistent) session can be inactive before the user must log in again. (default: 24)
  --sandbox-version: string # Selected sandbox version for the extensibility environment (default: 22)
  --legacy-sandbox-version: string # Selected legacy sandbox version for the extensibility environment
  --default-redirection-uri: string # The default absolute redirection uri, must be https (format: absolute-https-uri-or-empty)
  --enabled-locales: list # Supported locales for the user interface
  --session-cookie: record # Session cookie configuration (nullable) — shape: {mode: "persistent"|"non-persistent"}
  --sessions: record # Sessions related settings for tenant (nullable) — shape: {oidc_logout_prompt_enabled?: bool}
  --oidc-logout: record # Settings related to OIDC RP-initiated Logout — shape: {rp_logout_end_session_endpoint_discovery?: bool}
  --customize-mfa-in-postlogin-action: oneof<nothing, bool> # Whether to enable flexible factors for MFA in the PostLogin action (nullable, default: false)
  --allow-organization-name-in-authentication-api: oneof<nothing, bool> # Whether to accept an organization name instead of an ID on auth endpoints (nullable, default: false)
  --acr-values-supported: list # Supported ACR values (nullable)
  --mtls: record # mTLS configuration. (nullable) — shape: {enable_endpoint_aliases?: bool}
  --pushed-authorization-requests-supported: oneof<nothing, bool> # Enables the use of Pushed Authorization Requests (nullable, default: false)
  --authorization-response-iss-parameter-supported: oneof<nothing, bool> # Supports iss parameter in authorization responses (nullable, default: false)
  --skip-non-verifiable-callback-uri-confirmation-prompt: oneof<nothing, bool> # Controls whether a confirmation prompt is shown during login flows when the redirect URI uses non-verifiable callback URIs (for example, a custom URI schema such as `myapp://`, or `localhost`). If set to true, a confirmation prompt will not be shown. We recommend that this is set to false for improved protection from malicious apps. See https://auth0.com/docs/secure/security-guidance/measures-against-app-impersonation for more information. (nullable)
  --resource-parameter-profile: string@resource-parameter-profile-completer # Profile that determines how the identity of the protected resource (i.e., API) can be specified in the OAuth endpoints when access is being requested. When set to audience (default), the audience parameter is used to specify the resource server. When set to compatibility, the audience parameter is still checked first, but if it not provided, then the resource parameter can be used to specify the resource server. (default: audience)
  --client-id-metadata-document-supported: oneof<nothing, bool> # Whether the authorization server supports retrieving client metadata from a client_id URL. (default: false)
  --enable-ai-guide: oneof<nothing, bool> # Whether Auth0 Guide (AI-powered assistance) is enabled for this tenant.
  --phone-consolidated-experience: oneof<nothing, bool> # Whether Phone Consolidated Experience is enabled for this tenant.
  --dynamic-client-registration-security-mode: string@dynamic-client-registration-security-mode-completer # Sets the `third_party_security_mode` assigned to clients created via Dynamic Client Registration. `strict` applies enhanced security controls. `permissive` preserves <a href="https://auth0.com/docs/get-started/applications/third-party-applications/permissive-mode#dynamic-client-registration-in-permissive-mode">pre-existing behavior</a> and is only available to tenants with prior third-party client usage.
]: any -> record<change_password: record<enabled: bool, html: string>, guardian_mfa_page: record<enabled: bool, html: string>, default_audience: string, default_directory: string, error_page: record<html: string, show_log_link: bool, url: string>, device_flow: record<charset: string, mask: string>, default_token_quota: record<clients: record<client_credentials: record>, organizations: record<client_credentials: record>>, flags: record<change_pwd_flow_v1: bool, enable_apis_section: bool, disable_impersonation: bool, enable_client_connections: bool, enable_pipeline2: bool, allow_legacy_delegation_grant_types: bool, allow_legacy_ro_grant_types: bool, allow_legacy_tokeninfo_endpoint: bool, enable_legacy_profile: bool, enable_idtoken_api2: bool, enable_public_signup_user_exists_error: bool, enable_sso: bool, allow_changing_enable_sso: bool, disable_clickjack_protection_headers: bool, no_disclose_enterprise_connections: bool, enforce_client_authentication_on_passwordless_start: bool, enable_adfs_waad_email_verification: bool, revoke_refresh_token_grant: bool, dashboard_log_streams_next: bool, dashboard_insights_view: bool, disable_fields_map_fix: bool, mfa_show_factor_list_on_enrollment: bool, remove_alg_from_jwks: bool, improved_signup_bot_detection_in_classic: bool, genai_trial: bool, enable_dynamic_client_registration: bool, disable_management_api_sms_obfuscation: bool, trust_azure_adfs_email_verified_connection_property: bool, custom_domains_provisioning: bool>, friendly_name: string, picture_url: string, support_email: string, support_url: string, allowed_logout_urls: list<string>, session_lifetime: float, idle_session_lifetime: float, ephemeral_session_lifetime: float, idle_ephemeral_session_lifetime: float, sandbox_version: string, legacy_sandbox_version: string, sandbox_versions_available: list<string>, default_redirection_uri: string, enabled_locales: list<string>, session_cookie: record<mode: string>, sessions: record<oidc_logout_prompt_enabled: bool>, oidc_logout: record<rp_logout_end_session_endpoint_discovery: bool>, allow_organization_name_in_authentication_api: bool, customize_mfa_in_postlogin_action: bool, acr_values_supported: list<string>, mtls: record<enable_endpoint_aliases: bool>, pushed_authorization_requests_supported: bool, authorization_response_iss_parameter_supported: bool, skip_non_verifiable_callback_uri_confirmation_prompt: bool, resource_parameter_profile: string, client_id_metadata_document_supported: bool, phone_consolidated_experience: bool, enable_ai_guide: bool, dynamic_client_registration_security_mode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tenants/settings")
  let body = {change_password: $change_password, device_flow: $device_flow, guardian_mfa_page: $guardian_mfa_page, default_audience: $default_audience, default_directory: $default_directory, error_page: $error_page, default_token_quota: $default_token_quota, flags: $flags, friendly_name: $friendly_name, picture_url: $picture_url, support_email: $support_email, support_url: $support_url, allowed_logout_urls: $allowed_logout_urls, session_lifetime: $session_lifetime, idle_session_lifetime: $idle_session_lifetime, ephemeral_session_lifetime: $ephemeral_session_lifetime, idle_ephemeral_session_lifetime: $idle_ephemeral_session_lifetime, sandbox_version: $sandbox_version, legacy_sandbox_version: $legacy_sandbox_version, default_redirection_uri: $default_redirection_uri, enabled_locales: $enabled_locales, session_cookie: $session_cookie, sessions: $sessions, oidc_logout: $oidc_logout, customize_mfa_in_postlogin_action: $customize_mfa_in_postlogin_action, allow_organization_name_in_authentication_api: $allow_organization_name_in_authentication_api, acr_values_supported: $acr_values_supported, mtls: $mtls, pushed_authorization_requests_supported: $pushed_authorization_requests_supported, authorization_response_iss_parameter_supported: $authorization_response_iss_parameter_supported, skip_non_verifiable_callback_uri_confirmation_prompt: $skip_non_verifiable_callback_uri_confirmation_prompt, resource_parameter_profile: $resource_parameter_profile, client_id_metadata_document_supported: $client_id_metadata_document_supported, enable_ai_guide: $enable_ai_guide, phone_consolidated_experience: $phone_consolidated_experience, dynamic_client_registration_security_mode: $dynamic_client_registration_security_mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an email verification ticket
#
# POST /tickets/email-verification
# operationId: post_email-verification
# --identity shape: {user_id: string, provider: "ad"|"adfs"|"amazon"|"apple"|"dropbox"|"bitbucket"|"auth0-oidc"|"auth0"|"baidu"|"bitly"|"box"|"custom"|"daccount"|"dwolla"|"email"|"evernote-sandbox"|"evernote"|"exact"|"facebook"|"fitbit"|"github"|"google-apps"|"google-oauth2"|"instagram"|"ip"|"line"|"linkedin"|"oauth1"|"oauth2"|"office365"|"oidc"|"okta"|"paypal"|"paypal-sandbox"|"pingfederate"|"planningcenter"|"salesforce-community"|"salesforce-sandbox"|"salesforce"|"samlp"|"sharepoint"|"shopify"|"shop"|"sms"|"soundcloud"|"thirtysevensignals"|"twitter"|"untappd"|"vkontakte"|"waad"|"weibo"|"windowslive"|"wordpress"|"yahoo"|"yandex", connection_id?: string}
export def "tickets-email-verification email-verification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --result-url: string # URL the user will be redirected to in the classic Universal Login experience once the ticket is used. Cannot be specified when using client_id or organization_id. (format: url, default: http://myapp.com/callback)
  user_id: string # user_id of for whom the ticket should be created. (format: user-id)
  --client-id: string # ID of the client (application). If provided for tenants using the New Universal Login experience, the email template and UI displays application details, and the user is prompted to redirect to the application's <a target='' href='https://auth0.com/docs/authenticate/login/auth0-universal-login/configure-default-login-routes#completing-the-password-reset-flow'>default login route</a> after the ticket is used. client_id is required to use the <a target='' href='https://auth0.com/docs/customize/actions/flows-and-triggers/post-change-password-flow'>Password Reset Post Challenge</a> trigger. (format: client-id, default: DaM8bokEXBWrTUFCiJjWn50jei6ardyX)
  --organization-id: string # (Optional) Organization ID – the ID of the Organization. If provided, organization parameters will be made available to the email template and organization branding will be applied to the prompt. In addition, the redirect link in the prompt will include organization_id and organization_name query string parameters. (format: organization-id, default: org_2eondWoxcMIpaLQc)
  --ttl-sec: int # Number of seconds for which the ticket is valid before expiration. If unspecified or set to 0, this value defaults to 432000 seconds (5 days).
  --includeEmailInRedirect: oneof<nothing, bool> # Whether to include the email address as part of the returnUrl in the reset_email (true), or not (false).
  --identity: record # This must be provided to verify primary social, enterprise and passwordless email identities. Also, is needed to verify secondary identities. — shape: {user_id: string, provider: "ad"|"adfs"|"amazon"|"apple"|"dropbox"|"bitbucket"|"auth0-oidc"|"auth0"|"baidu"|"bitly"|"box"|"custom"|"daccount"|"dwolla"|"email"|"evernote-sandbox"|"evernote"|"exact"|"facebook"|"fitbit"|"github"|"google-apps"|"google-oauth2"|"instagram"|"ip"|"line"|"linkedin"|"oauth1"|"oauth2"|"office365"|"oidc"|"okta"|"paypal"|"paypal-sandbox"|"pingfederate"|"planningcenter"|"salesforce-community"|"salesforce-sandbox"|"salesforce"|"samlp"|"sharepoint"|"shopify"|"shop"|"sms"|"soundcloud"|"thirtysevensignals"|"twitter"|"untappd"|"vkontakte"|"waad"|"weibo"|"windowslive"|"wordpress"|"yahoo"|"yandex", connection_id?: string}
]: any -> record<ticket: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tickets/email-verification")
  let body = {result_url: $result_url, user_id: $user_id, client_id: $client_id, organization_id: $organization_id, ttl_sec: $ttl_sec, includeEmailInRedirect: $includeEmailInRedirect, identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a password change ticket
#
# POST /tickets/password-change
# operationId: post_password-change
# --identity shape: {user_id: string, provider: "auth0", connection_id?: string}
export def "tickets-password-change password-change" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --result-url: string # URL the user will be redirected to in the classic Universal Login experience once the ticket is used. Cannot be specified when using client_id or organization_id. (format: url, default: http://myapp.com/callback)
  --user-id: string # user_id of for whom the ticket should be created. (format: user-id)
  --client-id: string # ID of the client (application). If provided for tenants using the New Universal Login experience, the email template and UI displays application details, and the user is prompted to redirect to the application's <a target='' href='https://auth0.com/docs/authenticate/login/auth0-universal-login/configure-default-login-routes#completing-the-password-reset-flow'>default login route</a> after the ticket is used. client_id is required to use the <a target='' href='https://auth0.com/docs/customize/actions/flows-and-triggers/post-change-password-flow'>Password Reset Post Challenge</a> trigger. (format: client-id, default: DaM8bokEXBWrTUFCiJjWn50jei6ardyX)
  --organization-id: string # (Optional) Organization ID – the ID of the Organization. If provided, organization parameters will be made available to the email template and organization branding will be applied to the prompt. In addition, the redirect link in the prompt will include organization_id and organization_name query string parameters. (format: organization-id, default: org_2eondWoxcMIpaLQc)
  --connection-id: string # ID of the connection. If provided, allows the user to be specified using email instead of user_id. If you set this value, you must also send the email parameter. You cannot send user_id when specifying a connection_id. (default: con_0000000000000001)
  --email: string # Email address of the user for whom the tickets should be created. Requires the connection_id parameter. Cannot be specified when using user_id. (format: email)
  --ttl-sec: int # Number of seconds for which the ticket is valid before expiration. If unspecified or set to 0, this value defaults to 432000 seconds (5 days).
  --mark-email-as-verified: oneof<nothing, bool> # Whether to set the email_verified attribute to true (true) or whether it should not be updated (false). (default: false)
  --includeEmailInRedirect: oneof<nothing, bool> # Whether to include the email address as part of the returnUrl in the reset_email (true), or not (false).
  --identity: record # The user's identity. If you set this value, you must also send the user_id parameter. — shape: {user_id: string, provider: "auth0", connection_id?: string}
]: any -> record<ticket: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tickets/password-change")
  let body = {result_url: $result_url, user_id: $user_id, client_id: $client_id, organization_id: $organization_id, connection_id: $connection_id, email: $email, ttl_sec: $ttl_sec, mark_email_as_verified: $mark_email_as_verified, includeEmailInRedirect: $includeEmailInRedirect, identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get token exchange profiles
#
# GET /token-exchange-profiles
# operationId: get_token-exchange-profiles
export def "token-exchange-profiles token-exchange-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
]: nothing -> record<next: string, token_exchange_profiles: table<id: string, name: string, subject_token_type: string, action_id: string, type: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/token-exchange-profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a token exchange profile
#
# POST /token-exchange-profiles
# operationId: post_token-exchange-profiles
export def "token-exchange-profiles token-exchange-profiles-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Friendly name of this profile. (default: Token Exchange Profile 1)
  subject_token_type: string # Subject token type for this profile. When receiving a token exchange request on the Authentication API, the corresponding token exchange profile with a matching subject_token_type will be executed. This must be a URI. (format: url)
  action_id: string # The ID of the Custom Token Exchange action to execute for this profile, in order to validate the subject_token. The action must use the custom-token-exchange trigger.
  type: string@type-completer-6 # The type of the profile, which controls how the profile will be executed when receiving a token exchange request.
]: any -> record<id: string, name: string, subject_token_type: string, action_id: string, type: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token-exchange-profiles")
  let body = {name: $name, subject_token_type: $subject_token_type, action_id: $action_id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a token exchange profile
#
# GET /token-exchange-profiles/{id}
# operationId: get_token-exchange-profiles_by_id
export def "token-exchange-profiles id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, subject_token_type: string, action_id: string, type: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/token-exchange-profiles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a token exchange profile
#
# DELETE /token-exchange-profiles/{id}
# operationId: delete_token-exchange-profiles_by_id
export def "token-exchange-profiles id-by-id-1" [
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
  let full_url = (build-url $base $"/token-exchange-profiles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing token exchange profile
#
# PATCH /token-exchange-profiles/{id}
# operationId: patch_token-exchange-profiles_by_id
export def "token-exchange-profiles id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Friendly name of this profile. (default: Token Exchange Profile 1)
  --subject-token-type: string # Subject token type for this profile. When receiving a token exchange request on the Authentication API, the corresponding token exchange profile with a matching subject_token_type will be executed. This must be a URI. (format: url)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/token-exchange-profiles/($id)")
  let body = {name: $name, subject_token_type: $subject_token_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get User Attribute Profiles
#
# GET /user-attribute-profiles
# operationId: get_user-attribute-profiles
export def "user-attribute-profiles user-attribute-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 5.
]: nothing -> record<next: string, user_attribute_profiles: table<id: string, name: string, user_id: record, user_attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user-attribute-profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Post User Attribute Profile
#
# POST /user-attribute-profiles
# operationId: post_user-attribute-profiles
# --user_id shape: {oidc_mapping?: "sub", saml_mapping?: list, scim_mapping?: string, strategy_overrides?: record}
export def "user-attribute-profiles user-attribute-profiles-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the user attribute profile.
  --user-id: record # User ID mapping configuration — shape: {oidc_mapping?: "sub", saml_mapping?: list, scim_mapping?: string, strategy_overrides?: record}
  user_attributes: record # User attributes configuration map. Keys are attribute names, values are the mapping configuration for each attribute.
]: any -> record<id: string, name: string, user_id: record<oidc_mapping: string, saml_mapping: list<string>, scim_mapping: string, strategy_overrides: record<pingfederate: record, ad: record, adfs: record, waad: record, google_apps: record, okta: record, oidc: record, samlp: record>>, user_attributes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user-attribute-profiles")
  let body = {name: $name, user_id: $user_id, user_attributes: $user_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get User Attribute Profile Templates
#
# GET /user-attribute-profiles/templates
# operationId: get_user_attribute_profile_templates
export def "user-attribute-profiles-templates templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user_attribute_profile_templates: table<id: string, display_name: string, template: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user-attribute-profiles/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User Attribute Profile Template
#
# GET /user-attribute-profiles/templates/{id}
# operationId: get_user_attribute_profile_template
export def "user-attribute-profiles-templates template" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, display_name: string, template: record<name: string, user_id: record<oidc_mapping: string, saml_mapping: list, scim_mapping: string, strategy_overrides: record>, user_attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user-attribute-profiles/templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User Attribute Profile
#
# GET /user-attribute-profiles/{id}
# operationId: get_user-attribute-profiles_by_id
export def "user-attribute-profiles id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, user_id: record<oidc_mapping: string, saml_mapping: list<string>, scim_mapping: string, strategy_overrides: record<pingfederate: record, ad: record, adfs: record, waad: record, google_apps: record, okta: record, oidc: record, samlp: record>>, user_attributes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user-attribute-profiles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete User Attribute Profile
#
# DELETE /user-attribute-profiles/{id}
# operationId: delete_user-attribute-profiles_by_id
export def "user-attribute-profiles id-by-id-1" [
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
  let full_url = (build-url $base $"/user-attribute-profiles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify a user attribute profile
#
# PATCH /user-attribute-profiles/{id}
# operationId: patch_user-attribute-profiles_by_id
export def "user-attribute-profiles id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the user attribute profile.
  --user-id: any
  --user-attributes: record # User attributes configuration map. Keys are attribute names, values are the mapping configuration for each attribute.
]: any -> record<id: string, name: string, user_id: record<oidc_mapping: string, saml_mapping: list<string>, scim_mapping: string, strategy_overrides: record<pingfederate: record, ad: record, adfs: record, waad: record, google_apps: record, okta: record, oidc: record, samlp: record>>, user_attributes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user-attribute-profiles/($id)")
  let body = {name: $name, user_id: $user_id, user_attributes: $user_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get blocks by identifier
#
# GET /user-blocks
# operationId: get_user-blocks
export def "user-blocks user-blocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifier: string # Should be any of a username, phone number, or email.
  --consider-brute-force-enablement: oneof<nothing, bool> #            If true and Brute Force Protection is enabled and configured to block logins, will return a list of blocked IP addresses.           If true and Brute Force Protection is disabled, will return an empty list.         
]: nothing -> record<blocked_for: table<identifier: string, ip: string, connection: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifier" $identifier "scalar") (serialize-qp "consider_brute_force_enablement" $consider_brute_force_enablement "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user-blocks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unblock by identifier
#
# DELETE /user-blocks
# operationId: delete_user-blocks
export def "user-blocks user-blocks-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifier: string # Should be any of a username, phone number, or email.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifier" $identifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user-blocks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user's blocks
#
# GET /user-blocks/{id}
# operationId: get_user-blocks_by_id
export def "user-blocks id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consider-brute-force-enablement: oneof<nothing, bool> #            If true and Brute Force Protection is enabled and configured to block logins, will return a list of blocked IP addresses.           If true and Brute Force Protection is disabled, will return an empty list.         
]: nothing -> record<blocked_for: table<identifier: string, ip: string, connection: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consider_brute_force_enablement" $consider_brute_force_enablement "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user-blocks/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unblock a user
#
# DELETE /user-blocks/{id}
# operationId: delete_user-blocks_by_id
export def "user-blocks id-by-id-1" [
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
  let full_url = (build-url $base $"/user-blocks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or Search Users
#
# GET /users
# operationId: get_users
export def "users users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --qp-sort: string # Field to sort by. Use <code>field:order</code> where order is <code>1</code> for ascending and <code>-1</code> for descending. e.g. <code>created_at:1</code>
  --connection: string # Connection filter. Only applies when using <code>search_engine=v1</code>. To filter by connection with <code>search_engine=v2|v3</code>, use <code>q=identities.connection:"connection_name"</code>
  --qp-fields: string # Comma-separated list of fields to include or exclude (based on value provided for include_fields) in the result. Leave empty to retrieve all fields.
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false).
  --q: string # Query in <a target='_new' href ='https://lucene.apache.org/core/2_9_4/queryparsersyntax.html'>Lucene query string syntax</a>. Some query types cannot be used on metadata fields, for details see <a href='https://auth0.com/docs/users/search/v3/query-syntax#searchable-fields'>Searchable Fields</a>.
  --search-engine: string@search-engine-completer # The version of the search engine
  --primary-order: oneof<nothing, bool> # If true (default), results are returned in a deterministic order. If false, results may be returned in a non-deterministic order, which can enhance performance for complex queries targeting a small number of users. Set to false only when consistent ordering and pagination is not required.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "connection" $connection "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "search_engine" $search_engine "scalar") (serialize-qp "primary_order" $primary_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a User
#
# POST /users
# operationId: post_users
export def "users users-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # The user's email. (format: email, default: john.doe@gmail.com)
  --phone-number: string # The user's phone number (following the E.164 recommendation). (default: +199999999999999)
  --user-metadata: record # Data related to the user that does not affect the application's core functionality.
  --blocked: oneof<nothing, bool> # Whether this user was blocked by an administrator (true) or not (false). (default: false)
  --email-verified: oneof<nothing, bool> # Whether this email address is verified (true) or unverified (false). User will receive a verification email after creation if `email_verified` is false or not specified (default: false)
  --phone-verified: oneof<nothing, bool> # Whether this phone number has been verified (true) or not (false). (default: false)
  --app-metadata: record # Data related to the user that does affect the application's core functionality.
  --given-name: string # The user's given name(s). (default: John)
  --family-name: string # The user's family name(s). (default: Doe)
  --name: string # The user's full name. (default: John Doe)
  --nickname: string # The user's nickname. (default: Johnny)
  --picture: string # A URI pointing to the user's picture. (format: strict-uri, default: https://secure.gravatar.com/avatar/15626c5e0c749cb912f9d1ad48dba440?s=480&r=pg&d=https%3A%2F%2Fssl.gstatic.com%2Fs2%2Fprofiles%2Fimages%2Fsilhouette80.png)
  --user-id: string # The external user's id provided by the identity provider. (default: abc)
  connection: string # Name of the connection this user should be created in. (default: Initial-Connection)
  --password: string # Initial password for this user. Only valid for auth0 connection strategy. (default: secret)
  --verify-email: oneof<nothing, bool> # Whether the user will receive a verification email after creation (true) or no email (false). Overrides behavior of `email_verified` parameter. (default: false)
  --username: string # The user's username. Only valid if the connection requires a username. (default: johndoe)
]: any -> record<user_id: string, email: string, email_verified: bool, username: string, phone_number: string, phone_verified: bool, created_at: any, updated_at: any, identities: table<connection: string, user_id: string, provider: string, isSocial: bool, access_token: string, access_token_secret: string, refresh_token: string, profileData: record>, app_metadata: record, user_metadata: record, picture: string, name: string, nickname: string, multifactor: list<string>, last_ip: string, last_login: any, logins_count: int, blocked: bool, given_name: string, family_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = {email: $email, phone_number: $phone_number, user_metadata: $user_metadata, blocked: $blocked, email_verified: $email_verified, phone_verified: $phone_verified, app_metadata: $app_metadata, given_name: $given_name, family_name: $family_name, name: $name, nickname: $nickname, picture: $picture, user_id: $user_id, connection: $connection, password: $password, verify_email: $verify_email, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search Users by Email
#
# GET /users-by-email
# operationId: get_users-by-email
export def "users-by-email users-by-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include or exclude (based on value provided for include_fields) in the result. Leave empty to retrieve all fields.
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false). Defaults to true.
  --email: string # Email address to search for (case-sensitive).
]: nothing -> table<user_id: string, email: string, email_verified: bool, username: string, phone_number: string, phone_verified: bool, created_at: any, updated_at: any, identities: list<record>, app_metadata: record, user_metadata: record, picture: string, name: string, nickname: string, multifactor: list<string>, last_ip: string, last_login: any, logins_count: int, blocked: bool, given_name: string, family_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users-by-email" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a User
#
# GET /users/{id}
# operationId: get_users_by_id
export def "users id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include or exclude (based on value provided for include_fields) in the result. Leave empty to retrieve all fields.
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false).
]: nothing -> record<user_id: string, email: string, email_verified: bool, username: string, phone_number: string, phone_verified: bool, created_at: any, updated_at: any, identities: table<connection: string, user_id: string, provider: string, isSocial: bool, access_token: string, access_token_secret: string, refresh_token: string, profileData: record>, app_metadata: record, user_metadata: record, picture: string, name: string, nickname: string, multifactor: list<string>, last_ip: string, last_login: any, logins_count: int, blocked: bool, given_name: string, family_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a User
#
# DELETE /users/{id}
# operationId: delete_users_by_id
export def "users id-by-id-1" [
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
  let full_url = (build-url $base $"/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a User
#
# PATCH /users/{id}
# operationId: patch_users_by_id
export def "users id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blocked: oneof<nothing, bool> # Whether this user was blocked by an administrator (true) or not (false). (default: false)
  --email-verified: oneof<nothing, bool> # Whether this email address is verified (true) or unverified (false). If set to false the user will not receive a verification email unless `verify_email` is set to true. (default: false)
  --email: string # Email address of this user. (nullable, format: email, default: john.doe@gmail.com)
  --phone-number: string # The user's phone number (following the E.164 recommendation). (nullable, default: +199999999999999)
  --phone-verified: oneof<nothing, bool> # Whether this phone number has been verified (true) or not (false). (default: false)
  --user-metadata: record # Data related to the user that does not affect the application's core functionality.
  --app-metadata: record # Data related to the user that does affect the application's core functionality.
  --given-name: string # Given name/first name/forename of this user. (nullable, default: John)
  --family-name: string # Family name/last name/surname of this user. (nullable, default: Doe)
  --name: string # Name of this user. (nullable, default: John Doe)
  --nickname: string # Preferred nickname or alias of this user. (nullable, default: Johnny)
  --picture: string # URL to picture, photo, or avatar of this user. (nullable, format: strict-uri, default: https://secure.gravatar.com/avatar/15626c5e0c749cb912f9d1ad48dba440?s=480&r=pg&d=https%3A%2F%2Fssl.gstatic.com%2Fs2%2Fprofiles%2Fimages%2Fsilhouette80.png)
  --verify-email: oneof<nothing, bool> # Whether this user will receive a verification email after creation (true) or no email (false). Overrides behavior of `email_verified` parameter. (default: false)
  --verify-phone-number: oneof<nothing, bool> # Whether this user will receive a text after changing the phone number (true) or no text (false). Only valid when changing phone number for SMS connections. (default: false)
  --password: string # New password for this user. Only valid for database connections. (nullable, default: secret)
  --connection: string # Name of the connection to target for this user update. (default: Initial-Connection)
  --client-id: string # Auth0 client ID. Only valid when updating email address. (default: DaM8bokEXBWrTUFCiJjWn50jei6ardyX)
  --username: string # The user's username. Only valid if the connection requires a username. (nullable, default: johndoe)
]: any -> record<user_id: string, email: string, email_verified: bool, username: string, phone_number: string, phone_verified: bool, created_at: any, updated_at: any, identities: table<connection: string, user_id: string, provider: string, isSocial: bool, access_token: string, access_token_secret: string, refresh_token: string, profileData: record>, app_metadata: record, user_metadata: record, picture: string, name: string, nickname: string, multifactor: list<string>, last_ip: string, last_login: any, logins_count: int, blocked: bool, given_name: string, family_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let body = {blocked: $blocked, email_verified: $email_verified, email: $email, phone_number: $phone_number, phone_verified: $phone_verified, user_metadata: $user_metadata, app_metadata: $app_metadata, given_name: $given_name, family_name: $family_name, name: $name, nickname: $nickname, picture: $picture, verify_email: $verify_email, verify_phone_number: $verify_phone_number, password: $password, connection: $connection, client_id: $client_id, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of authentication methods
#
# GET /users/{id}/authentication-methods
# operationId: get_authentication-methods
export def "users-authentication-methods authentication-methods-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0. Default is 0.
  --per-page: int # Number of results per page. Default is 50.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/authentication-methods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all authentication methods for the given user
#
# DELETE /users/{id}/authentication-methods
# operationId: delete_authentication-methods
export def "users-authentication-methods authentication-methods-by-id-1" [
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
  let full_url = (build-url $base $"/users/($id)/authentication-methods")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates an authentication method for a given user
#
# POST /users/{id}/authentication-methods
# operationId: post_authentication-methods
export def "users-authentication-methods authentication-methods-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-7
  --name: string # A human-readable label to identify the authentication method.
  --totp-secret: string # Base32 encoded secret for TOTP generation.
  --phone-number: string # Applies to phone authentication methods only. The destination phone number used to send verification codes via text and voice.
  --email: string # Applies to email authentication methods only. The email address used to send verification messages.
  --preferred-authentication-method: string@preferred-authentication-method-completer # Applies to phone authentication methods only. The preferred communication method.
  --key-id: string # Applies to webauthn authentication methods only. The id of the credential.
  --public-key: string # Applies to webauthn authentication methods only. The public key, which is encoded as base64.
  --relying-party-identifier: string # Applies to webauthn authentication methods only. The relying party identifier. (format: hostname)
]: any -> record<id: string, type: string, name: string, totp_secret: string, phone_number: string, email: string, authentication_methods: table<type: string, id: string>, preferred_authentication_method: string, key_id: string, public_key: string, aaguid: string, relying_party_identifier: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/authentication-methods")
  let body = {type: $type, name: $name, totp_secret: $totp_secret, phone_number: $phone_number, email: $email, preferred_authentication_method: $preferred_authentication_method, key_id: $key_id, public_key: $public_key, relying_party_identifier: $relying_party_identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update all authentication methods by replacing them with the given ones
#
# PUT /users/{id}/authentication-methods
# operationId: put_authentication-methods
export def "users-authentication-methods authentication-methods-by-id-3" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<id: string, type: string, name: string, totp_secret: string, phone_number: string, email: string, authentication_methods: list<record>, preferred_authentication_method: string, key_id: string, public_key: string, aaguid: string, relying_party_identifier: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/authentication-methods")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an authentication method by ID
#
# GET /users/{id}/authentication-methods/{authentication_method_id}
# operationId: get_authentication-methods_by_authentication_method_id
export def "users-authentication-methods id-by-id-authentication_method_id" [
  id: string
  authentication_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, confirmed: bool, name: string, authentication_methods: table<type: string, id: string>, preferred_authentication_method: string, link_id: string, phone_number: string, email: string, key_id: string, public_key: string, created_at: string, enrolled_at: string, last_auth_at: string, credential_device_type: string, credential_backed_up: bool, identity_user_id: string, user_agent: string, aaguid: string, relying_party_identifier: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/authentication-methods/($authentication_method_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an authentication method by ID
#
# DELETE /users/{id}/authentication-methods/{authentication_method_id}
# operationId: delete_authentication-methods_by_authentication_method_id
export def "users-authentication-methods id-by-id-authentication_method_id-1" [
  id: string
  authentication_method_id: string
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
  let full_url = (build-url $base $"/users/($id)/authentication-methods/($authentication_method_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an authentication method
#
# PATCH /users/{id}/authentication-methods/{authentication_method_id}
# operationId: patch_authentication-methods_by_authentication_method_id
export def "users-authentication-methods id-by-id-authentication_method_id-2" [
  id: string
  authentication_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # A human-readable label to identify the authentication method.
  --preferred-authentication-method: string@preferred-authentication-method-completer # Applies to phone authentication methods only. The preferred communication method.
]: any -> record<id: string, type: string, name: string, totp_secret: string, phone_number: string, email: string, authentication_methods: table<type: string, id: string>, preferred_authentication_method: string, key_id: string, public_key: string, aaguid: string, relying_party_identifier: string, confirmed: bool, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/authentication-methods/($authentication_method_id)")
  let body = {name: $name, preferred_authentication_method: $preferred_authentication_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete All Authenticators
#
# DELETE /users/{id}/authenticators
# operationId: delete_authenticators
export def "users-authenticators authenticators" [
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
  let full_url = (build-url $base $"/users/($id)/authenticators")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a User's Connected Accounts
#
# GET /users/{id}/connected-accounts
# operationId: get_connected-accounts
export def "users-connected-accounts connected-accounts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results to return.  Defaults to 10 with a maximum of 20
]: nothing -> record<connected_accounts: table<id: string, connection: string, connection_id: string, strategy: string, access_type: string, scopes: list, created_at: string, expires_at: string, organization_id: string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/connected-accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the First Confirmed Multi-factor Authentication (MFA) Enrollment
#
# GET /users/{id}/enrollments
# operationId: get_enrollments
export def "users-enrollments enrollments" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, status: string, type: string, name: string, identifier: string, phone_number: string, auth_method: string, enrolled_at: string, last_auth: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/enrollments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get tokensets for a user
#
# GET /users/{id}/federated-connections-tokensets
# operationId: get_federated-connections-tokensets
export def "users-federated-connections-tokensets federated-connections-tokensets" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, connection: string, scope: string, expires_at: string, issued_at: string, last_used_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/federated-connections-tokensets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a tokenset for federated connections by id.
#
# DELETE /users/{id}/federated-connections-tokensets/{tokenset_id}
# operationId: delete_federated-connections-tokensets_by_tokenset_id
export def "users-federated-connections-tokensets id" [
  id: string
  tokenset_id: string
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
  let full_url = (build-url $base $"/users/($id)/federated-connections-tokensets/($tokenset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user's groups
#
# GET /users/{id}/groups
# operationId: get_user_groups
export def "users-groups groups" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # A comma separated list of fields to include or exclude (depending on include_fields) from the result, empty to retrieve all fields
  --include-fields: oneof<nothing, bool> # Whether specified fields are to be included (true) or excluded (false).
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Defaults to 50.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "include_fields" $include_fields "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Link a User Account
#
# POST /users/{id}/identities
# operationId: post_identities
export def "users-identities identities" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --provider: string@provider-completer-2 # The type of identity provider
  --connection-id: string # connection_id of the secondary user account being linked when more than one `auth0` database provider exists.
  --user-id: any # user_id of the secondary user account being linked.
  --link-with: string # JWT for the secondary account being linked. If sending this parameter, `provider`, `user_id`, and `connection_id` must not be sent. (default: {SECONDARY_ACCOUNT_JWT})
]: any -> table<connection: string, user_id: any, provider: string, profileData: record<email: string, email_verified: bool, name: string, username: string, given_name: string, phone_number: string, phone_verified: bool, family_name: string>, isSocial: bool, access_token: string, access_token_secret: string, refresh_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/identities")
  let body = {provider: $provider, connection_id: $connection_id, user_id: $user_id, link_with: $link_with} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unlink a User Identity
#
# DELETE /users/{id}/identities/{provider}/{user_id}
# operationId: delete_user_identity_by_user_id
export def "users-identities id" [
  id: string
  provider: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<connection: string, user_id: string, provider: string, isSocial: bool, access_token: string, access_token_secret: string, refresh_token: string, profileData: record<email: string, email_verified: bool, name: string, username: string, given_name: string, phone_number: string, phone_verified: bool, family_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/identities/($provider)/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user's log events
#
# GET /users/{id}/logs
# operationId: get_logs_by_user
export def "users-logs user" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Paging is disabled if parameter not sent.
  --qp-sort: string # Field to sort by. Use `fieldname:1` for ascending order and `fieldname:-1` for descending.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_totals" $include_totals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invalidate All Remembered Browsers for Multi-factor Authentication (MFA)
#
# POST /users/{id}/multifactor/actions/invalidate-remember-browser
# operationId: post_invalidate-remember-browser
export def "users-multifactor-actions-invalidate-remember-browser invalidate-remember-browser" [
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
  let full_url = (build-url $base $"/users/($id)/multifactor/actions/invalidate-remember-browser")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a User's Multi-factor Provider
#
# DELETE /users/{id}/multifactor/{provider}
# operationId: delete_multifactor_by_provider
export def "users-multifactor provider" [
  id: string
  provider: string
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
  let full_url = (build-url $base $"/users/($id)/multifactor/($provider)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user's organizations
#
# GET /users/{id}/organizations
# operationId: get_user_organizations
export def "users-organizations organizations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of the results to return. First page is 0.
  --per-page: int # Number of results per page. Defaults to 50.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_totals" $include_totals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a User's Permissions
#
# GET /users/{id}/permissions
# operationId: get_permissions
export def "users-permissions permissions-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Number of results per page.
  --page: int # Page index of the results to return. First page is 0.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_totals" $include_totals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove Permissions from a User
#
# DELETE /users/{id}/permissions
# operationId: delete_permissions
# --permissions item shape: {resource_server_identifier: string, permission_name: string}
export def "users-permissions permissions-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissions: list # List of permissions to remove from this user. — item shape: {resource_server_identifier: string, permission_name: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/permissions")
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign Permissions to a User
#
# POST /users/{id}/permissions
# operationId: post_permissions
# --permissions item shape: {resource_server_identifier: string, permission_name: string}
export def "users-permissions permissions-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissions: list # List of permissions to add to this user. — item shape: {resource_server_identifier: string, permission_name: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/permissions")
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate New Multi-factor Authentication (MFA) Recovery Code
#
# POST /users/{id}/recovery-code-regeneration
# operationId: post_recovery-code-regeneration
export def "users-recovery-code-regeneration recovery-code-regeneration" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<recovery_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/recovery-code-regeneration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revokes selected resources from a user
#
# POST /users/{id}/revoke-access
# operationId: user_revoke_access
export def "users-revoke-access access" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --session-id: string # ID of the session to revoke. (format: session-id)
  --preserve-refresh-tokens: oneof<nothing, bool> # Whether to preserve the refresh tokens associated with the session. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/revoke-access")
  let body = {session_id: $session_id, preserve_refresh_tokens: $preserve_refresh_tokens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clear risk assessment assessors for a specific user
#
# POST /users/{id}/risk-assessments/clear
# operationId: post_clear_assessors
export def "users-risk-assessments-clear assessors" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connection: string # The name of the connection containing the user whose assessors should be cleared.
  assessors: list # List of assessors to clear.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/risk-assessments/clear")
  let body = {connection: $connection, assessors: $assessors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user's roles
#
# GET /users/{id}/roles
# operationId: get_user_roles
export def "users-roles roles-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Number of results per page.
  --page: int # Page index of the results to return. First page is 0.
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_totals" $include_totals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Removes roles from a user
#
# DELETE /users/{id}/roles
# operationId: delete_user_roles
export def "users-roles roles-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  roles: list # List of roles IDs to remove from the user.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/roles")
  let body = {roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign roles to a user
#
# POST /users/{id}/roles
# operationId: post_user_roles
export def "users-roles roles-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  roles: list # List of roles IDs to associated with the user.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/roles")
  let body = {roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get refresh tokens for a user
#
# GET /users/{user_id}/refresh-tokens
# operationId: get_refresh_tokens_for_user
export def "users-refresh-tokens user-by-user_id" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --qp-from: string # An optional cursor from which to start the selection (exclusive).
  --take: int # Number of results per page. Defaults to 50.
]: nothing -> record<tokens: table<id: string, user_id: string, created_at: any, idle_expires_at: any, expires_at: any, device: record, client_id: string, session_id: string, rotating: bool, resource_servers: list, refresh_token_metadata: record, last_exchanged_at: any>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/refresh-tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete refresh tokens for a user
#
# DELETE /users/{user_id}/refresh-tokens
# operationId: delete_refresh_tokens_for_user
export def "users-refresh-tokens user-by-user_id-1" [
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
  let full_url = (build-url $base $"/users/($user_id)/refresh-tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get sessions for user
#
# GET /users/{user_id}/sessions
# operationId: get_sessions_for_user
export def "users-sessions user-by-user_id" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-totals: oneof<nothing, bool> # Return results inside an object that contains the total result count (true) or as a direct array of results (false, default).
  --qp-from: string # An optional cursor from which to start the selection (exclusive).
  --take: int # Number of results per page. Defaults to 50.
]: nothing -> record<sessions: table<id: string, user_id: string, created_at: any, updated_at: any, authenticated_at: any, idle_expires_at: any, expires_at: any, last_interacted_at: any, device: record, clients: list, authentication: record, cookie: record, session_metadata: record>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_totals" $include_totals "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete sessions for user
#
# DELETE /users/{user_id}/sessions
# operationId: delete_sessions_for_user
export def "users-sessions user-by-user_id-1" [
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
  let full_url = (build-url $base $"/users/($user_id)/sessions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List verifiable credential templates for a tenant.
#
# GET /verifiable-credentials/verification/templates
# operationId: get_vc_templates
export def "verifiable-credentials-verification-templates templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Optional Id from which to start selection.
  --take: int # Number of results per page. Defaults to 50.
]: nothing -> record<next: string, templates: table<id: string, name: string, type: string, dialect: string, presentation: record, custom_certificate_authority: string, well_known_trusted_issuers: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/verifiable-credentials/verification/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a verifiable credential template.
#
# POST /verifiable-credentials/verification/templates
# operationId: post_vc_templates
# --presentation shape: {org.iso.18013.5.1.mDL: record}
export def "verifiable-credentials-verification-templates templates-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  type: string
  dialect: string
  presentation: record # A simplified presentation request — shape: {org.iso.18013.5.1.mDL: record}
  --custom-certificate-authority: string # nullable
  well_known_trusted_issuers: string
]: any -> record<id: string, name: string, type: string, dialect: string, presentation: record<org_iso_18013_5_1_mDL: record<org_iso_18013_5_1: record>>, custom_certificate_authority: string, well_known_trusted_issuers: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verifiable-credentials/verification/templates")
  let body = {name: $name, type: $type, dialect: $dialect, presentation: $presentation, custom_certificate_authority: $custom_certificate_authority, well_known_trusted_issuers: $well_known_trusted_issuers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a verifiable credential template by ID.
#
# GET /verifiable-credentials/verification/templates/{id}
# operationId: get_vc_templates_by_id
export def "verifiable-credentials-verification-templates id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, type: string, dialect: string, presentation: record<org_iso_18013_5_1_mDL: record<org_iso_18013_5_1: record>>, custom_certificate_authority: string, well_known_trusted_issuers: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/verifiable-credentials/verification/templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a verifiable credential template by ID.
#
# DELETE /verifiable-credentials/verification/templates/{id}
# operationId: delete_vc_templates_by_id
export def "verifiable-credentials-verification-templates id-by-id-1" [
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
  let full_url = (build-url $base $"/verifiable-credentials/verification/templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a verifiable credential template by ID.
#
# PATCH /verifiable-credentials/verification/templates/{id}
# operationId: patch_vc_templates_by_id
# --presentation shape: {org.iso.18013.5.1.mDL: record}
export def "verifiable-credentials-verification-templates id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # nullable
  --type: string # nullable
  --dialect: string # nullable
  --presentation: record # A simplified presentation request — shape: {org.iso.18013.5.1.mDL: record}
  --well-known-trusted-issuers: string # nullable
  --version: float # nullable
]: any -> record<id: string, name: string, type: string, dialect: string, presentation: record<org_iso_18013_5_1_mDL: record<org_iso_18013_5_1: record>>, custom_certificate_authority: string, well_known_trusted_issuers: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/verifiable-credentials/verification/templates/($id)")
  let body = {name: $name, type: $type, dialect: $dialect, presentation: $presentation, well_known_trusted_issuers: $well_known_trusted_issuers, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
