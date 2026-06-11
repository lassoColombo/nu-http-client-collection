# Auto-generated client for Tolgee API vv1.0
# Source: https://app.tolgee.io/v3/api-docs
# Auth: --token flag or $env.TOLGEE_API_TOKEN

const BASE_URL = "https://app.tolgee.io"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TOLGEE_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://app.tolgee.io"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def forceMode-completer [] { ["KEEP" "NO_FORCE" "OVERRIDE"] }
def suggestionsMode-completer [] { ["DISABLED" "ENABLED"] }
def translationProtection-completer [] { ["NONE" "PROTECT_REVIEWED"] }
def state-completer [] { ["NEEDS_RESOLUTION" "RESOLUTION_NOT_NEEDED" "RESOLVED"] }
def type-completer [] { ["EDIT" "MANAGE" "NONE" "REVIEW" "TRANSLATE" "VIEW"] }
def format-completer [] { ["ANDROID_SDK" "ANDROID_XML" "APPLE_SDK" "APPLE_STRINGS_STRINGSDICT" "APPLE_XCSTRINGS" "APPLE_XLIFF" "COMPOSE_XML" "CSV" "FLUTTER_ARB" "JSON" "JSON_I18NEXT" "JSON_TOLGEE" "PO" "PROPERTIES" "RESX_ICU" "XLIFF" "XLSX" "YAML" "YAML_RUBY"] }
def messageFormat-completer [] { ["APPLE_SPRINTF" "C_SPRINTF" "I18NEXT" "ICU" "JAVA_STRING_FORMAT" "PHP_SPRINTF" "PYTHON_PERCENT" "RUBY_SPRINTF"] }
def resolve-completer [] { ["SOURCE" "TARGET"] }
def roleType-completer [] { ["MAINTAINER" "MEMBER" "OWNER"] }
def type-completer-1 [] { ["ANTHROPIC" "GOOGLE_AI" "OPENAI" "OPENAI_AZURE" "TOLGEE"] }
def priority-completer [] { ["HIGH" "LOW"] }
def period-completer [] { ["MONTHLY" "YEARLY"] }
def group-completer [] { ["ACCOUNT_SECURITY" "TASKS"] }
def channel-completer [] { ["EMAIL" "IN_APP"] }
def type-completer-2 [] { ["FIXED" "PAY_AS_YOU_GO"] }
def metricType-completer [] { ["KEYS_SEATS" "STRINGS"] }
def formality-completer [] { ["DEFAULT" "FORMAL" "INFORMAL"] }
def state-completer-1 [] { ["DISABLED" "REVIEWED" "TRANSLATED" "UNTRANSLATED"] }
def overrideMode-completer [] { ["ALL" "RECOMMENDED"] }
def type-completer-3 [] { ["BRACKETS_MISMATCH" "BRACKETS_UNBALANCED" "CHARACTER_CASE_MISMATCH" "DIFFERENT_URLS" "EMPTY_TRANSLATION" "GRAMMAR" "HTML_SYNTAX" "ICU_SYNTAX" "INCONSISTENT_HTML" "INCONSISTENT_PLACEHOLDERS" "KEY_LENGTH_LIMIT" "MISSING_NUMBERS" "MISSING_PLURAL_CATEGORIES" "PUNCTUATION_MISMATCH" "REPEATED_WORDS" "SPACES_MISMATCH" "SPECIAL_CHARACTER_MISMATCH" "SPELLING" "TRIM_CHECK" "UNMATCHED_NEWLINES"] }
def message-completer [] { ["qa_brackets_extra" "qa_brackets_missing" "qa_brackets_unclosed" "qa_brackets_unmatched_close" "qa_case_capitalize" "qa_case_lowercase" "qa_check_failed" "qa_empty_translation" "qa_grammar_error" "qa_html_tag_extra" "qa_html_tag_missing" "qa_html_unclosed_tag" "qa_html_unopened_tag" "qa_icu_syntax_error" "qa_key_length_limit_exceeded" "qa_leading_newlines" "qa_leading_spaces" "qa_missing_plural_category" "qa_newlines_extra" "qa_newlines_missing" "qa_newlines_too_few_sections" "qa_newlines_too_many_sections" "qa_numbers_missing" "qa_placeholders_extra" "qa_placeholders_missing" "qa_placeholders_replace" "qa_punctuation_add" "qa_punctuation_remove" "qa_punctuation_replace" "qa_repeated_word" "qa_spaces_doubled" "qa_spaces_leading_added" "qa_spaces_leading_removed" "qa_spaces_non_breaking_added" "qa_spaces_non_breaking_removed" "qa_spaces_trailing_added" "qa_spaces_trailing_removed" "qa_special_char_added" "qa_special_char_missing" "qa_spelling_error" "qa_trailing_newlines" "qa_trailing_spaces" "qa_url_extra" "qa_url_missing" "qa_url_replace"] }
def type-completer-4 [] { ["REVIEW" "TRANSLATE"] }
def type-completer-5 [] { ["ADD" "CONFLICT" "DELETE" "UPDATE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "user get" } } | get name | first)
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

# Get user info
#
# GET /v2/user
# operationId: getInfo
export def "user get" [
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
  let full_url = (build-url $base "/v2/user")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user
#
# PUT /v2/user
# operationId: updateUser
export def "user updateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  email: string
  --currentPassword: string
  --callbackUrl: string # Callback url for link sent in e-mail. This may be omitted, when server has set frontEndUrl in properties.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user")
  let body = {name: $name, email: $email, currentPassword: $currentPassword, callbackUrl: $callbackUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates current user's data.
#
# POST /v2/user
# DEPRECATED
# operationId: updateUserOld
@deprecated
export def "user updateUserOld" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  email: string
  --currentPassword: string
  --callbackUrl: string # Callback url for link sent in e-mail. This may be omitted, when server has set frontEndUrl in properties.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user")
  let body = {name: $name, email: $email, currentPassword: $currentPassword, callbackUrl: $callbackUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete user
#
# DELETE /v2/user
# operationId: delete
export def "user delete" [
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
  let full_url = (build-url $base "/v2/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update password
#
# PUT /v2/user/password
# operationId: updateUserPassword
export def "user-password updateUserPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  currentPassword: string
  password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/password")
  let body = {currentPassword: $currentPassword, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable TOTP
#
# PUT /v2/user/mfa/totp
# operationId: enableMfa
export def "user-mfa-totp enableMfa" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  totpKey: string
  otp: string
  password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/mfa/totp")
  let body = {totpKey: $totpKey, otp: $otp, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable TOTP
#
# DELETE /v2/user/mfa/totp
# operationId: disableMfa
export def "user-mfa-totp disableMfa" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/mfa/totp")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Regenerate Codes
#
# PUT /v2/user/mfa/recovery
# operationId: regenerateRecoveryCodes
export def "user-mfa-recovery regenerateRecoveryCodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/mfa/recovery")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload avatar
#
# PUT /v2/user/avatar
# operationId: uploadAvatar
export def "user-avatar uploadAvatar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  avatar: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/avatar")
  let body = {avatar: $avatar} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete avatar
#
# DELETE /v2/user/avatar
# operationId: removeAvatar
export def "user-avatar removeAvatar" [
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
  let full_url = (build-url $base "/v2/user/avatar")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get specific field from user's storage
#
# GET /v2/user-preferences/storage/{fieldName}
# operationId: getStorageField
export def "user-preferences-storage get" [
  fieldName: string
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
  let full_url = (build-url $base $"/v2/user-preferences/storage/($fieldName)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set specific field in user storage
#
# PUT /v2/user-preferences/storage/{fieldName}
# operationId: setStorageField
export def "user-preferences-storage setStorageField" [
  fieldName: string
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
  let full_url = (build-url $base $"/v2/user-preferences/storage/($fieldName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set user preferred organization
#
# PUT /v2/user-preferences/set-preferred-organization/{organizationId}
# operationId: setPreferredOrganization
export def "user-preferences-set-preferred-organization setPreferredOrganization" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/user-preferences/set-preferred-organization/($organizationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set user's UI language
#
# PUT /v2/user-preferences/set-language/{languageTag}
# operationId: setLanguage
export def "user-preferences-set-language setLanguage" [
  languageTag: string
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
  let full_url = (build-url $base $"/v2/user-preferences/set-language/($languageTag)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Complete guide step
#
# PUT /v2/quick-start/steps/{step}/complete
# operationId: completeGuideStep
export def "quick-start-steps-complete completeGuideStep" [
  step: string
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
  let full_url = (build-url $base $"/v2/quick-start/steps/($step)/complete")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set open state
#
# PUT /v2/quick-start/set-open/{open}
# operationId: setOpenState
export def "quick-start-set-open setOpenState" [
  open: bool
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
  let full_url = (build-url $base $"/v2/quick-start/set-open/($open)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set finished state
#
# PUT /v2/quick-start/set-finished/{finished}
# operationId: setFinishedState
export def "quick-start-set-finished setFinishedState" [
  finished: bool
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
  let full_url = (build-url $base $"/v2/quick-start/set-finished/($finished)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get prompt by id
#
# GET /v2/projects/{projectId}/prompts/{promptId}
# operationId: getPrompt
export def "projects-prompts get" [
  promptId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/prompts/($promptId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update prompt
#
# PUT /v2/projects/{projectId}/prompts/{promptId}
# operationId: updatePrompt
export def "projects-prompts updatePrompt" [
  promptId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  providerName: string
  --template: string
  --basicPromptOptions: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/prompts/($promptId)")
  let body = {name: $name, providerName: $providerName, template: $template, basicPromptOptions: $basicPromptOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete prompt
#
# DELETE /v2/projects/{projectId}/prompts/{promptId}
# operationId: deletePrompt
export def "projects-prompts delete" [
  promptId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/prompts/($promptId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get prompt by id
#
# GET /v2/projects/prompts/{promptId}
# operationId: getPrompt_1
export def "projects-prompts get-by-promptId" [
  promptId: int
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
  let full_url = (build-url $base $"/v2/projects/prompts/($promptId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update prompt
#
# PUT /v2/projects/prompts/{promptId}
# operationId: updatePrompt_1
export def "projects-prompts updatePrompt-by-promptId" [
  promptId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  providerName: string
  --template: string
  --basicPromptOptions: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/prompts/($promptId)")
  let body = {name: $name, providerName: $providerName, template: $template, basicPromptOptions: $basicPromptOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete prompt
#
# DELETE /v2/projects/prompts/{promptId}
# operationId: deletePrompt_1
export def "projects-prompts delete-by-promptId" [
  promptId: int
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
  let full_url = (build-url $base $"/v2/projects/prompts/($promptId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add label to translation
#
# PUT /v2/projects/{projectId}/translations/{translationId}/label/{labelId}
# operationId: assignLabel
export def "projects-translations-label assignLabel" [
  translationId: int
  labelId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($translationId)/label/($labelId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove label from translation
#
# DELETE /v2/projects/{projectId}/translations/{translationId}/label/{labelId}
# operationId: unassignLabel
export def "projects-translations-label unassignLabel" [
  translationId: int
  labelId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($translationId)/label/($labelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add label to translation
#
# PUT /v2/projects/translations/{translationId}/label/{labelId}
# operationId: assignLabel_1
export def "projects-translations-label assignLabel-by-translationId-labelId" [
  translationId: int
  labelId: int
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
  let full_url = (build-url $base $"/v2/projects/translations/($translationId)/label/($labelId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove label from translation
#
# DELETE /v2/projects/translations/{translationId}/label/{labelId}
# operationId: unassignLabel_1
export def "projects-translations-label unassignLabel-by-translationId-labelId" [
  translationId: int
  labelId: int
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
  let full_url = (build-url $base $"/v2/projects/translations/($translationId)/label/($labelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add label to translation by key and language id
#
# PUT /v2/projects/{projectId}/translations/label
# operationId: assignLabel_2
export def "projects-translations-label assignLabel-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyId: int # format: int64
  languageId: int # format: int64
  labelId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/label")
  let body = {keyId: $keyId, languageId: $languageId, labelId: $labelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add label to translation by key and language id
#
# PUT /v2/projects/translations/label
# operationId: assignLabel_3
export def "projects-translations-label assignLabel-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyId: int # format: int64
  languageId: int # format: int64
  labelId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/translations/label")
  let body = {keyId: $keyId, languageId: $languageId, labelId: $labelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Execute complex tag operation
#
# PUT /v2/projects/{projectId}/tag-complex
# operationId: executeComplexTagOperation
# --filterKeys item shape: {name?: string, namespace?: string, id?: int}
# --filterKeysNot item shape: {name?: string, namespace?: string, id?: int}
export def "projects-tag-complex executeComplexTagOperation" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
  --filterKeys: list # Include keys filtered by the provided key information — item shape: {name?: string, namespace?: string, id?: int}
  --filterKeysNot: list # Exclude keys filtered by the provided key information — item shape: {name?: string, namespace?: string, id?: int}
  --filterTag: list # Include keys filtered by the provided tag information. This filter supports wildcards. For example, `draft-*` will match all tags starting with `draft-`.
  --filterTagNot: list # Exclude keys filtered by the provided tag information. This filter supports wildcards. For example, `draft-*` will match all tags starting with `draft-`.
  --tagFiltered: list # Specified tags will be added to filtered keys
  --untagFiltered: list # Specified tags will be removed from filtered keys. It supports wildcards. For example, `draft-*` will remove all tags starting with `draft-`.
  --tagOther: list # Specified tags will be added to keys not filtered by any of the specified filters.
  --untagOther: list # Specified tags will be removed from keys not filtered by any of the specified filters. It supports wildcards. For example, `draft-*` will remove all tags starting with `draft-`.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/tag-complex" $qp)
  let body = {filterKeys: $filterKeys, filterKeysNot: $filterKeysNot, filterTag: $filterTag, filterTagNot: $filterTagNot, tagFiltered: $tagFiltered, untagFiltered: $untagFiltered, tagOther: $tagOther, untagOther: $untagOther} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Execute complex tag operation
#
# PUT /v2/projects/tag-complex
# operationId: executeComplexTagOperation_1
# --filterKeys item shape: {name?: string, namespace?: string, id?: int}
# --filterKeysNot item shape: {name?: string, namespace?: string, id?: int}
export def "projects-tag-complex executeComplexTagOperation-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
  --filterKeys: list # Include keys filtered by the provided key information — item shape: {name?: string, namespace?: string, id?: int}
  --filterKeysNot: list # Exclude keys filtered by the provided key information — item shape: {name?: string, namespace?: string, id?: int}
  --filterTag: list # Include keys filtered by the provided tag information. This filter supports wildcards. For example, `draft-*` will match all tags starting with `draft-`.
  --filterTagNot: list # Exclude keys filtered by the provided tag information. This filter supports wildcards. For example, `draft-*` will match all tags starting with `draft-`.
  --tagFiltered: list # Specified tags will be added to filtered keys
  --untagFiltered: list # Specified tags will be removed from filtered keys. It supports wildcards. For example, `draft-*` will remove all tags starting with `draft-`.
  --tagOther: list # Specified tags will be added to keys not filtered by any of the specified filters.
  --untagOther: list # Specified tags will be removed from keys not filtered by any of the specified filters. It supports wildcards. For example, `draft-*` will remove all tags starting with `draft-`.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/tag-complex" $qp)
  let body = {filterKeys: $filterKeys, filterKeysNot: $filterKeysNot, filterTag: $filterTag, filterTagNot: $filterTagNot, tagFiltered: $tagFiltered, untagFiltered: $untagFiltered, tagOther: $tagOther, untagOther: $untagOther} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update label
#
# PUT /v2/projects/{projectId}/labels/{labelId}
# operationId: updateLabel
export def "projects-labels updateLabel" [
  labelId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
  color: string # Hex color in format #RRGGBB. (e.g. #FF5733)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/labels/($labelId)")
  let body = {name: $name, description: $description, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete label
#
# DELETE /v2/projects/{projectId}/labels/{labelId}
# operationId: deleteLabel
export def "projects-labels delete" [
  labelId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/labels/($labelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update label
#
# PUT /v2/projects/labels/{labelId}
# operationId: updateLabel_1
export def "projects-labels updateLabel-by-labelId" [
  labelId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
  color: string # Hex color in format #RRGGBB. (e.g. #FF5733)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/labels/($labelId)")
  let body = {name: $name, description: $description, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete label
#
# DELETE /v2/projects/labels/{labelId}
# operationId: deleteLabel_1
export def "projects-labels delete-by-labelId" [
  labelId: int
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
  let full_url = (build-url $base $"/v2/projects/labels/($labelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tag key
#
# PUT /v2/projects/{projectId}/keys/{keyId}/tags
# operationId: tagKey
export def "projects-keys-tags tagKey" [
  keyId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/($keyId)/tags")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Tag key
#
# PUT /v2/projects/keys/{keyId}/tags
# operationId: tagKey_1
export def "projects-keys-tags tagKey-by-keyId" [
  keyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/keys/($keyId)/tags")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resolve conflict (override)
#
# PUT /v2/projects/{projectId}/import/result/languages/{languageId}/translations/{translationId}/resolve/set-override
# operationId: resolveTranslationSetOverride
export def "projects-import-result-languages-translations-resolve-set-override resolveTranslationSetOverride" [
  languageId: int
  translationId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/import/result/languages/($languageId)/translations/($translationId)/resolve/set-override")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve conflict (override)
#
# PUT /v2/projects/import/result/languages/{languageId}/translations/{translationId}/resolve/set-override
# operationId: resolveTranslationSetOverride_1
export def "projects-import-result-languages-translations-resolve-set-override resolveTranslationSetOverride-by-languageId-translationId" [
  languageId: int
  translationId: int
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
  let full_url = (build-url $base $"/v2/projects/import/result/languages/($languageId)/translations/($translationId)/resolve/set-override")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve conflict (keep existing)
#
# PUT /v2/projects/{projectId}/import/result/languages/{languageId}/translations/{translationId}/resolve/set-keep-existing
# operationId: resolveTranslationSetKeepExisting
export def "projects-import-result-languages-translations-resolve-set-keep-existing resolveTranslationSetKeepExisting" [
  languageId: int
  translationId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/import/result/languages/($languageId)/translations/($translationId)/resolve/set-keep-existing")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve conflict (keep existing)
#
# PUT /v2/projects/import/result/languages/{languageId}/translations/{translationId}/resolve/set-keep-existing
# operationId: resolveTranslationSetKeepExisting_1
export def "projects-import-result-languages-translations-resolve-set-keep-existing resolveTranslationSetKeepExisting-by-languageId-translationId" [
  languageId: int
  translationId: int
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
  let full_url = (build-url $base $"/v2/projects/import/result/languages/($languageId)/translations/($translationId)/resolve/set-keep-existing")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve all translation conflicts (override)
#
# PUT /v2/projects/{projectId}/import/result/languages/{languageId}/resolve-all/set-override
# operationId: resolveTranslationSetOverride_2
export def "projects-import-result-languages-resolve-all-set-override resolveTranslationSetOverride-by-languageId-projectId" [
  languageId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/import/result/languages/($languageId)/resolve-all/set-override")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve all translation conflicts (override)
#
# PUT /v2/projects/import/result/languages/{languageId}/resolve-all/set-override
# operationId: resolveTranslationSetOverride_3
export def "projects-import-result-languages-resolve-all-set-override resolveTranslationSetOverride-by-languageId" [
  languageId: int
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
  let full_url = (build-url $base $"/v2/projects/import/result/languages/($languageId)/resolve-all/set-override")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve all translation conflicts (keep existing)
#
# PUT /v2/projects/{projectId}/import/result/languages/{languageId}/resolve-all/set-keep-existing
# operationId: resolveTranslationSetKeepExisting_2
export def "projects-import-result-languages-resolve-all-set-keep-existing resolveTranslationSetKeepExisting-by-languageId-projectId" [
  languageId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/import/result/languages/($languageId)/resolve-all/set-keep-existing")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve all translation conflicts (keep existing)
#
# PUT /v2/projects/import/result/languages/{languageId}/resolve-all/set-keep-existing
# operationId: resolveTranslationSetKeepExisting_3
export def "projects-import-result-languages-resolve-all-set-keep-existing resolveTranslationSetKeepExisting-by-languageId" [
  languageId: int
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
  let full_url = (build-url $base $"/v2/projects/import/result/languages/($languageId)/resolve-all/set-keep-existing")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pair existing language
#
# PUT /v2/projects/{projectId}/import/result/languages/{importLanguageId}/select-existing/{existingLanguageId}
# operationId: selectExistingLanguage
export def "projects-import-result-languages-select-existing selectExistingLanguage" [
  importLanguageId: int
  existingLanguageId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/import/result/languages/($importLanguageId)/select-existing/($existingLanguageId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pair existing language
#
# PUT /v2/projects/import/result/languages/{importLanguageId}/select-existing/{existingLanguageId}
# operationId: selectExistingLanguage_1
export def "projects-import-result-languages-select-existing selectExistingLanguage-by-importLanguageId-existingLanguageId" [
  importLanguageId: int
  existingLanguageId: int
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
  let full_url = (build-url $base $"/v2/projects/import/result/languages/($importLanguageId)/select-existing/($existingLanguageId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset existing language pairing
#
# PUT /v2/projects/{projectId}/import/result/languages/{importLanguageId}/reset-existing
# operationId: resetExistingLanguage
export def "projects-import-result-languages-reset-existing resetExistingLanguage" [
  importLanguageId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/import/result/languages/($importLanguageId)/reset-existing")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset existing language pairing
#
# PUT /v2/projects/import/result/languages/{importLanguageId}/reset-existing
# operationId: resetExistingLanguage_1
export def "projects-import-result-languages-reset-existing resetExistingLanguage-by-importLanguageId" [
  importLanguageId: int
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
  let full_url = (build-url $base $"/v2/projects/import/result/languages/($importLanguageId)/reset-existing")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Select namespace
#
# PUT /v2/projects/{projectId}/import/result/files/{fileId}/select-namespace
# operationId: selectNamespace
export def "projects-import-result-files-select-namespace selectNamespace" [
  fileId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/import/result/files/($fileId)/select-namespace")
  let body = {namespace: $namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Select namespace
#
# PUT /v2/projects/import/result/files/{fileId}/select-namespace
# operationId: selectNamespace_1
export def "projects-import-result-files-select-namespace selectNamespace-by-fileId" [
  fileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/import/result/files/($fileId)/select-namespace")
  let body = {namespace: $namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Apply import (streaming)
#
# PUT /v2/projects/{projectId}/import/apply-streaming
# operationId: applyImportStreaming
export def "projects-import-apply-streaming applyImportStreaming" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceMode: string@forceMode-completer # Whether override or keep all translations with unresolved conflicts (default: NO_FORCE)
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceMode" $forceMode "scalar") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/import/apply-streaming" $qp)
  let accept_val = "application/x-ndjson"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply import (streaming)
#
# PUT /v2/projects/import/apply-streaming
# operationId: applyImportStreaming_1
export def "projects-import-apply-streaming applyImportStreaming-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceMode: string@forceMode-completer # Whether override or keep all translations with unresolved conflicts (default: NO_FORCE)
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceMode" $forceMode "scalar") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/import/apply-streaming" $qp)
  let accept_val = "application/x-ndjson"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply import
#
# PUT /v2/projects/{projectId}/import/apply
# operationId: applyImport
export def "projects-import-apply applyImport" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceMode: string@forceMode-completer # Whether override or keep all translations with unresolved conflicts (default: NO_FORCE)
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceMode" $forceMode "scalar") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/import/apply" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply import
#
# PUT /v2/projects/import/apply
# operationId: applyImport_1
export def "projects-import-apply applyImport-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceMode: string@forceMode-completer # Whether override or keep all translations with unresolved conflicts (default: NO_FORCE)
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceMode" $forceMode "scalar") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/import/apply" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Import Settings
#
# GET /v2/projects/{projectId}/import-settings
# operationId: get
export def "projects-import-settings get" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/import-settings")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Import Settings
#
# PUT /v2/projects/{projectId}/import-settings
# operationId: store
export def "projects-import-settings store" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --overrideKeyDescriptions: string@bool-completer # If true, key descriptions will be overridden by the import
  --createNewKeys: string@bool-completer # If false, only updates keys, skipping the creation of new keys
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/import-settings")
  let body = {overrideKeyDescriptions: $overrideKeyDescriptions, createNewKeys: $createNewKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Import Settings
#
# GET /v2/projects/import-settings
# operationId: get_1
export def "projects-import-settings get-by-" [
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
  let full_url = (build-url $base "/v2/projects/import-settings")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Import Settings
#
# PUT /v2/projects/import-settings
# operationId: store_1
export def "projects-import-settings store-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --overrideKeyDescriptions: string@bool-completer # If true, key descriptions will be overridden by the import
  --createNewKeys: string@bool-completer # If false, only updates keys, skipping the creation of new keys
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/import-settings")
  let body = {overrideKeyDescriptions: $overrideKeyDescriptions, createNewKeys: $createNewKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stop batch operation
#
# PUT /v2/projects/{projectId}/batch-jobs/{id}/cancel
# operationId: cancel
export def "projects-batch-jobs-cancel cancel" [
  id: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/batch-jobs/($id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop batch operation
#
# PUT /v2/projects/batch-jobs/{id}/cancel
# operationId: cancel_1
export def "projects-batch-jobs-cancel cancel-by-id" [
  id: int
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
  let full_url = (build-url $base $"/v2/projects/batch-jobs/($id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one project
#
# GET /v2/projects/{projectId}
# operationId: get_2
export def "projects get-by-projectId" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update project settings
#
# PUT /v2/projects/{projectId}
# operationId: editProject
export def "projects editProject" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --slug: string
  --baseLanguageId: int # format: int64
  --useNamespaces: string@bool-completer
  --useBranching: string@bool-completer
  --defaultNamespaceId: int # format: int64
  --description: string
  --icuPlaceholders: string@bool-completer # Whether to use ICU placeholder visualization in the editor and it's support.
  suggestionsMode: string@suggestionsMode-completer # Suggestions can be DISABLED (hidden from UI) or ENABLED (visible in the UI)
  translationProtection: string@translationProtection-completer # Protects reviewed translations, so translators can't change them by default and others will receive warning.
  --unassignConflictingTms: string@bool-completer # When true, the request is allowed to unassign shared translation memories whose source language differs from the new base language. Without this flag, such a conflict is rejected with `cannot_change_project_base_language_tm_conflict`. The frontend should only set this after the user explicitly confirms in the conflict dialog.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)")
  let body = {name: $name, slug: $slug, baseLanguageId: $baseLanguageId, useNamespaces: $useNamespaces, useBranching: $useBranching, defaultNamespaceId: $defaultNamespaceId, description: $description, icuPlaceholders: $icuPlaceholders, suggestionsMode: $suggestionsMode, translationProtection: $translationProtection, unassignConflictingTms: $unassignConflictingTms} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete project
#
# DELETE /v2/projects/{projectId}
# operationId: deleteProject
export def "projects delete" [
  projectId: int
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
  let full_url = (build-url $base $"/v2/projects/($projectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one webhook configuration
#
# GET /v2/projects/{projectId}/webhook-configs/{id}
# operationId: get_3
export def "projects-webhook-configs get-by-id-projectId" [
  id: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/webhook-configs/($id)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update webhook configuration
#
# PUT /v2/projects/{projectId}/webhook-configs/{id}
# operationId: update
export def "projects-webhook-configs update" [
  id: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string
  --enabled: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/webhook-configs/($id)")
  let body = {url: $body_url, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete webhook configuration
#
# DELETE /v2/projects/{projectId}/webhook-configs/{id}
# operationId: delete_1
export def "projects-webhook-configs delete-by-id-projectId" [
  id: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/webhook-configs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set user's project permission
#
# PUT /v2/projects/{projectId}/users/{userId}/set-permissions
# operationId: setUsersPermissions
export def "projects-users-set-permissions setUsersPermissions" [
  userId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scopes: list # Granted scopes (e.g. [translations.view, translations.edit])
  --languages: list
  --translateLanguages: list
  --viewLanguages: list
  --stateChangeLanguages: list
  --suggestLanguages: list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scopes" $scopes "multi") (serialize-qp "languages" $languages "multi") (serialize-qp "translateLanguages" $translateLanguages "multi") (serialize-qp "viewLanguages" $viewLanguages "multi") (serialize-qp "stateChangeLanguages" $stateChangeLanguages "multi") (serialize-qp "suggestLanguages" $suggestLanguages "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/users/($userId)/set-permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set direct permission to user
#
# PUT /v2/projects/{projectId}/users/{userId}/set-permissions/{permissionType}
# operationId: setUsersPermissions_1
export def "projects-users-set-permissions setUsersPermissions-by-userId-permissionType-projectId" [
  userId: int
  permissionType: string
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --languages: list
  --translateLanguages: list
  --viewLanguages: list
  --stateChangeLanguages: list
  --suggestLanguages: list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languages" $languages "multi") (serialize-qp "translateLanguages" $translateLanguages "multi") (serialize-qp "viewLanguages" $viewLanguages "multi") (serialize-qp "stateChangeLanguages" $stateChangeLanguages "multi") (serialize-qp "suggestLanguages" $suggestLanguages "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/users/($userId)/set-permissions/($permissionType)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove direct project permission
#
# PUT /v2/projects/{projectId}/users/{userId}/set-by-organization
# operationId: removeDirectProjectPermissions
export def "projects-users-set-by-organization removeDirectProjectPermissions" [
  userId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/users/($userId)/set-by-organization")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke project access
#
# PUT /v2/projects/{projectId}/users/{userId}/revoke-access
# operationId: revokePermission
export def "projects-users-revoke-access revokePermission" [
  projectId: int
  userId: int
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/users/($userId)/revoke-access")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set translation state
#
# PUT /v2/projects/{projectId}/translations/{translationId}/set-state/{state}
# operationId: setTranslationState
export def "projects-translations-set-state setTranslationState" [
  translationId: int
  state: string
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($translationId)/set-state/($state)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set translation state
#
# PUT /v2/projects/translations/{translationId}/set-state/{state}
# operationId: setTranslationState_1
export def "projects-translations-set-state setTranslationState-by-translationId-state" [
  translationId: int
  state: string
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
  let full_url = (build-url $base $"/v2/projects/translations/($translationId)/set-state/($state)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set state of translation comment
#
# PUT /v2/projects/{projectId}/translations/{translationId}/comments/{commentId}/set-state/{state}
# operationId: setState
export def "projects-translations-comments-set-state setState" [
  translationId: int
  commentId: int
  state: string
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($translationId)/comments/($commentId)/set-state/($state)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set state of translation comment
#
# PUT /v2/projects/translations/{translationId}/comments/{commentId}/set-state/{state}
# operationId: setState_1
export def "projects-translations-comments-set-state setState-by-translationId-commentId-state" [
  translationId: int
  commentId: int
  state: string
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
  let full_url = (build-url $base $"/v2/projects/translations/($translationId)/comments/($commentId)/set-state/($state)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one translation comment
#
# GET /v2/projects/{projectId}/translations/{translationId}/comments/{commentId}
# operationId: get_4
export def "projects-translations-comments get-by-translationId-commentId-projectId" [
  translationId: int
  commentId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($translationId)/comments/($commentId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update translation comment
#
# PUT /v2/projects/{projectId}/translations/{translationId}/comments/{commentId}
# operationId: update_1
export def "projects-translations-comments update-by-commentId-translationId-projectId" [
  commentId: int
  translationId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  text: string
  state: string@state-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($translationId)/comments/($commentId)")
  let body = {text: $text, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete translation comment
#
# DELETE /v2/projects/{projectId}/translations/{translationId}/comments/{commentId}
# operationId: delete_2
export def "projects-translations-comments delete-by-translationId-commentId-projectId" [
  translationId: int
  commentId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($translationId)/comments/($commentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one translation comment
#
# GET /v2/projects/translations/{translationId}/comments/{commentId}
# operationId: get_5
export def "projects-translations-comments get-by-translationId-commentId" [
  translationId: int
  commentId: int
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
  let full_url = (build-url $base $"/v2/projects/translations/($translationId)/comments/($commentId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update translation comment
#
# PUT /v2/projects/translations/{translationId}/comments/{commentId}
# operationId: update_2
export def "projects-translations-comments update-by-commentId-translationId" [
  commentId: int
  translationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  text: string
  state: string@state-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/translations/($translationId)/comments/($commentId)")
  let body = {text: $text, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete translation comment
#
# DELETE /v2/projects/translations/{translationId}/comments/{commentId}
# operationId: delete_3
export def "projects-translations-comments delete-by-translationId-commentId" [
  translationId: int
  commentId: int
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
  let full_url = (build-url $base $"/v2/projects/translations/($translationId)/comments/($commentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set outdated value
#
# PUT /v2/projects/{projectId}/translations/{translationId}/set-outdated-flag/{state}
# operationId: setOutdated
export def "projects-translations-set-outdated-flag setOutdated" [
  translationId: int
  state: bool
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($translationId)/set-outdated-flag/($state)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set outdated value
#
# PUT /v2/projects/translations/{translationId}/set-outdated-flag/{state}
# operationId: setOutdated_1
export def "projects-translations-set-outdated-flag setOutdated-by-translationId-state" [
  translationId: int
  state: bool
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
  let full_url = (build-url $base $"/v2/projects/translations/($translationId)/set-outdated-flag/($state)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unignore a QA issue
#
# PUT /v2/projects/{projectId}/translations/{translationId}/qa-issues/{issueId}/unignore
# operationId: unignoreIssue
export def "projects-translations-qa-issues-unignore unignoreIssue" [
  projectId: int
  translationId: int
  issueId: int
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($translationId)/qa-issues/($issueId)/unignore")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ignore a QA issue
#
# PUT /v2/projects/{projectId}/translations/{translationId}/qa-issues/{issueId}/ignore
# operationId: ignoreIssue
export def "projects-translations-qa-issues-ignore ignoreIssue" [
  projectId: int
  translationId: int
  issueId: int
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($translationId)/qa-issues/($issueId)/ignore")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Dismiss auto-translated
#
# PUT /v2/projects/{projectId}/translations/{translationId}/dismiss-auto-translated-state
# operationId: dismissAutoTranslatedState
export def "projects-translations-dismiss-auto-translated-state dismissAutoTranslatedState" [
  translationId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($translationId)/dismiss-auto-translated-state")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Dismiss auto-translated
#
# PUT /v2/projects/translations/{translationId}/dismiss-auto-translated-state
# operationId: dismissAutoTranslatedState_1
export def "projects-translations-dismiss-auto-translated-state dismissAutoTranslatedState-by-translationId" [
  translationId: int
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
  let full_url = (build-url $base $"/v2/projects/translations/($translationId)/dismiss-auto-translated-state")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get translations in project
#
# GET /v2/projects/{projectId}/translations
# operationId: getTranslations
export def "projects-translations list" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to get next data
  --includeQaIssues: string@bool-completer # Include detailed QA issues for inline highlighting
  --filterState: list # Translation state in the format: languageTag,state. You can use this parameter multiple times.  When used with multiple states for same language it is applied with logical OR.    When used with multiple languages, it is applied with logical AND.     
  --languages: list # Languages to be contained in response.                  To add multiple languages, repeat this param (eg. ?languages=en&languages=de) (e.g. en)
  --search: string # String to search in key name or translation text
  --filterKeyName: list # Selects key with provided names. Use this param multiple times to fetch more keys.
  --filterKeyId: list # Selects key with provided ID. Use this param multiple times to fetch more keys.
  --filterUntranslatedAny: string@bool-completer # Selects only keys for which the translation is missing in any returned language. It only filters for translations included in returned languages.
  --filterTranslatedAny: string@bool-completer # Selects only keys, where translation is provided in any language
  --filterUntranslatedInLang: string # Selects only keys where the translation is missing for the specified language. The specified language must be included in the returned languages. Otherwise, this filter doesn't apply. (e.g. en-US)
  --filterTranslatedInLang: string # Selects only keys, where translation is provided in specified language (e.g. en-US)
  --filterAutoTranslatedInLang: list # Selects only keys, where translation was auto translated for specified languages. (e.g. en-US)
  --filterHasScreenshot: string@bool-completer # Selects only keys with screenshots
  --filterHasNoScreenshot: string@bool-completer # Selects only keys without screenshots
  --filterNamespace: list # Selects only keys with provided namespaces.   To filter default namespace, set to empty string.   
  --filterNoNamespace: list # Selects only keys without provided namespaces.   To filter default namespace, set to empty string.   
  --filterTag: list # Selects only keys with provided tag
  --filterNoTag: list # Selects only keys without provided tag
  --filterOutdatedLanguage: list # Selects only keys, where translation in provided langs is in outdated state (e.g. en-US)
  --filterNotOutdatedLanguage: list # Selects only keys, where translation in provided langs is not in outdated state (e.g. en-US)
  --filterRevisionId: list # Selects only key affected by activity with specidfied revision ID (e.g. 1234567)
  --filterFailedKeysOfJob: int # Select only keys which were not successfully translated by batch job with provided id (format: int64)
  --filterTaskNumber: list # Select only keys which are in specified task
  --filterTaskKeysNotDone: string@bool-completer # Filter task keys which are `not done`
  --filterTaskKeysDone: string@bool-completer # Filter task keys which are `done`
  --filterHasUnresolvedCommentsInLang: list # Filter keys with unresolved comments in lang
  --filterHasCommentsInLang: list # Filter keys with any comments in lang
  --filterLabel: list # Filter key translations with labels (e.g. labelId1,labelId2)
  --filterHasQaIssuesInLang: list # Filter keys with open QA issues in lang
  --filterQaCheckType: list # Filter keys with specific QA check type issues in the format: languageTag,checkType. You can use this parameter multiple times.  A key matches if any of the selected check types is present in any of the selected languages.     
  --filterQaChecksStaleInLang: list # Filter keys whose QA checks are stale (pending recomputation) in lang. When set, only keys with at least one stale translation in any of the provided languages are returned.
  --filterHasSuggestionsInLang: list # Filter keys with any suggestions in lang
  --filterHasNoSuggestionsInLang: list # Filter keys with no suggestions in lang
  --branch: string # Selects only keys from specified branch
  --filterDeletedByUserId: list # Filter trashed keys by who deleted them (user IDs)
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "includeQaIssues" $includeQaIssues "scalar") (serialize-qp "filterState" $filterState "multi") (serialize-qp "languages" $languages "multi") (serialize-qp "search" $search "scalar") (serialize-qp "filterKeyName" $filterKeyName "multi") (serialize-qp "filterKeyId" $filterKeyId "multi") (serialize-qp "filterUntranslatedAny" $filterUntranslatedAny "scalar") (serialize-qp "filterTranslatedAny" $filterTranslatedAny "scalar") (serialize-qp "filterUntranslatedInLang" $filterUntranslatedInLang "scalar") (serialize-qp "filterTranslatedInLang" $filterTranslatedInLang "scalar") (serialize-qp "filterAutoTranslatedInLang" $filterAutoTranslatedInLang "multi") (serialize-qp "filterHasScreenshot" $filterHasScreenshot "scalar") (serialize-qp "filterHasNoScreenshot" $filterHasNoScreenshot "scalar") (serialize-qp "filterNamespace" $filterNamespace "multi") (serialize-qp "filterNoNamespace" $filterNoNamespace "multi") (serialize-qp "filterTag" $filterTag "multi") (serialize-qp "filterNoTag" $filterNoTag "multi") (serialize-qp "filterOutdatedLanguage" $filterOutdatedLanguage "multi") (serialize-qp "filterNotOutdatedLanguage" $filterNotOutdatedLanguage "multi") (serialize-qp "filterRevisionId" $filterRevisionId "multi") (serialize-qp "filterFailedKeysOfJob" $filterFailedKeysOfJob "scalar") (serialize-qp "filterTaskNumber" $filterTaskNumber "multi") (serialize-qp "filterTaskKeysNotDone" $filterTaskKeysNotDone "scalar") (serialize-qp "filterTaskKeysDone" $filterTaskKeysDone "scalar") (serialize-qp "filterHasUnresolvedCommentsInLang" $filterHasUnresolvedCommentsInLang "multi") (serialize-qp "filterHasCommentsInLang" $filterHasCommentsInLang "multi") (serialize-qp "filterLabel" $filterLabel "multi") (serialize-qp "filterHasQaIssuesInLang" $filterHasQaIssuesInLang "multi") (serialize-qp "filterQaCheckType" $filterQaCheckType "multi") (serialize-qp "filterQaChecksStaleInLang" $filterQaChecksStaleInLang "multi") (serialize-qp "filterHasSuggestionsInLang" $filterHasSuggestionsInLang "multi") (serialize-qp "filterHasNoSuggestionsInLang" $filterHasNoSuggestionsInLang "multi") (serialize-qp "branch" $branch "scalar") (serialize-qp "filterDeletedByUserId" $filterDeletedByUserId "multi") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update translations for existing key
#
# PUT /v2/projects/{projectId}/translations
# operationId: setTranslations
export def "projects-translations setTranslations" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  key: string # Key name to set translations for (e.g. what_a_key_to_translate)
  --namespace: string # The namespace of the key. (When empty or null default namespace will be used)
  translations: record # Object mapping language tag to translation (e.g. {en: What a translated value!, cs: Jaká to přeložená hodnota!})
  --languagesToReturn: list # List of languages to return translations for.   If not provided, only modified translation will be provided.      (e.g. [en, de, fr])
  --branch: string # Branch name to set translations for
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations")
  let body = {key: $key, namespace: $namespace, translations: $translations, languagesToReturn: $languagesToReturn, branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create key or update translations
#
# POST /v2/projects/{projectId}/translations
# operationId: createOrUpdateTranslations
export def "projects-translations createOrUpdateTranslations" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  key: string # Key name to set translations for (e.g. what_a_key_to_translate)
  --namespace: string # The namespace of the key. (When empty or null default namespace will be used)
  translations: record # Object mapping language tag to translation (e.g. {en: What a translated value!, cs: Jaká to přeložená hodnota!})
  --languagesToReturn: list # List of languages to return translations for.   If not provided, only modified translation will be provided.      (e.g. [en, de, fr])
  --branch: string # Branch name to set translations for
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations")
  let body = {key: $key, namespace: $namespace, translations: $translations, languagesToReturn: $languagesToReturn, branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get translations in project
#
# GET /v2/projects/translations
# operationId: getTranslations_1
export def "projects-translations get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Cursor to get next data
  --includeQaIssues: string@bool-completer # Include detailed QA issues for inline highlighting
  --filterState: list # Translation state in the format: languageTag,state. You can use this parameter multiple times.  When used with multiple states for same language it is applied with logical OR.    When used with multiple languages, it is applied with logical AND.     
  --languages: list # Languages to be contained in response.                  To add multiple languages, repeat this param (eg. ?languages=en&languages=de) (e.g. en)
  --search: string # String to search in key name or translation text
  --filterKeyName: list # Selects key with provided names. Use this param multiple times to fetch more keys.
  --filterKeyId: list # Selects key with provided ID. Use this param multiple times to fetch more keys.
  --filterUntranslatedAny: string@bool-completer # Selects only keys for which the translation is missing in any returned language. It only filters for translations included in returned languages.
  --filterTranslatedAny: string@bool-completer # Selects only keys, where translation is provided in any language
  --filterUntranslatedInLang: string # Selects only keys where the translation is missing for the specified language. The specified language must be included in the returned languages. Otherwise, this filter doesn't apply. (e.g. en-US)
  --filterTranslatedInLang: string # Selects only keys, where translation is provided in specified language (e.g. en-US)
  --filterAutoTranslatedInLang: list # Selects only keys, where translation was auto translated for specified languages. (e.g. en-US)
  --filterHasScreenshot: string@bool-completer # Selects only keys with screenshots
  --filterHasNoScreenshot: string@bool-completer # Selects only keys without screenshots
  --filterNamespace: list # Selects only keys with provided namespaces.   To filter default namespace, set to empty string.   
  --filterNoNamespace: list # Selects only keys without provided namespaces.   To filter default namespace, set to empty string.   
  --filterTag: list # Selects only keys with provided tag
  --filterNoTag: list # Selects only keys without provided tag
  --filterOutdatedLanguage: list # Selects only keys, where translation in provided langs is in outdated state (e.g. en-US)
  --filterNotOutdatedLanguage: list # Selects only keys, where translation in provided langs is not in outdated state (e.g. en-US)
  --filterRevisionId: list # Selects only key affected by activity with specidfied revision ID (e.g. 1234567)
  --filterFailedKeysOfJob: int # Select only keys which were not successfully translated by batch job with provided id (format: int64)
  --filterTaskNumber: list # Select only keys which are in specified task
  --filterTaskKeysNotDone: string@bool-completer # Filter task keys which are `not done`
  --filterTaskKeysDone: string@bool-completer # Filter task keys which are `done`
  --filterHasUnresolvedCommentsInLang: list # Filter keys with unresolved comments in lang
  --filterHasCommentsInLang: list # Filter keys with any comments in lang
  --filterLabel: list # Filter key translations with labels (e.g. labelId1,labelId2)
  --filterHasQaIssuesInLang: list # Filter keys with open QA issues in lang
  --filterQaCheckType: list # Filter keys with specific QA check type issues in the format: languageTag,checkType. You can use this parameter multiple times.  A key matches if any of the selected check types is present in any of the selected languages.     
  --filterQaChecksStaleInLang: list # Filter keys whose QA checks are stale (pending recomputation) in lang. When set, only keys with at least one stale translation in any of the provided languages are returned.
  --filterHasSuggestionsInLang: list # Filter keys with any suggestions in lang
  --filterHasNoSuggestionsInLang: list # Filter keys with no suggestions in lang
  --branch: string # Selects only keys from specified branch
  --filterDeletedByUserId: list # Filter trashed keys by who deleted them (user IDs)
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "includeQaIssues" $includeQaIssues "scalar") (serialize-qp "filterState" $filterState "multi") (serialize-qp "languages" $languages "multi") (serialize-qp "search" $search "scalar") (serialize-qp "filterKeyName" $filterKeyName "multi") (serialize-qp "filterKeyId" $filterKeyId "multi") (serialize-qp "filterUntranslatedAny" $filterUntranslatedAny "scalar") (serialize-qp "filterTranslatedAny" $filterTranslatedAny "scalar") (serialize-qp "filterUntranslatedInLang" $filterUntranslatedInLang "scalar") (serialize-qp "filterTranslatedInLang" $filterTranslatedInLang "scalar") (serialize-qp "filterAutoTranslatedInLang" $filterAutoTranslatedInLang "multi") (serialize-qp "filterHasScreenshot" $filterHasScreenshot "scalar") (serialize-qp "filterHasNoScreenshot" $filterHasNoScreenshot "scalar") (serialize-qp "filterNamespace" $filterNamespace "multi") (serialize-qp "filterNoNamespace" $filterNoNamespace "multi") (serialize-qp "filterTag" $filterTag "multi") (serialize-qp "filterNoTag" $filterNoTag "multi") (serialize-qp "filterOutdatedLanguage" $filterOutdatedLanguage "multi") (serialize-qp "filterNotOutdatedLanguage" $filterNotOutdatedLanguage "multi") (serialize-qp "filterRevisionId" $filterRevisionId "multi") (serialize-qp "filterFailedKeysOfJob" $filterFailedKeysOfJob "scalar") (serialize-qp "filterTaskNumber" $filterTaskNumber "multi") (serialize-qp "filterTaskKeysNotDone" $filterTaskKeysNotDone "scalar") (serialize-qp "filterTaskKeysDone" $filterTaskKeysDone "scalar") (serialize-qp "filterHasUnresolvedCommentsInLang" $filterHasUnresolvedCommentsInLang "multi") (serialize-qp "filterHasCommentsInLang" $filterHasCommentsInLang "multi") (serialize-qp "filterLabel" $filterLabel "multi") (serialize-qp "filterHasQaIssuesInLang" $filterHasQaIssuesInLang "multi") (serialize-qp "filterQaCheckType" $filterQaCheckType "multi") (serialize-qp "filterQaChecksStaleInLang" $filterQaChecksStaleInLang "multi") (serialize-qp "filterHasSuggestionsInLang" $filterHasSuggestionsInLang "multi") (serialize-qp "filterHasNoSuggestionsInLang" $filterHasNoSuggestionsInLang "multi") (serialize-qp "branch" $branch "scalar") (serialize-qp "filterDeletedByUserId" $filterDeletedByUserId "multi") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/translations" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update translations for existing key
#
# PUT /v2/projects/translations
# operationId: setTranslations_1
export def "projects-translations setTranslations-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  key: string # Key name to set translations for (e.g. what_a_key_to_translate)
  --namespace: string # The namespace of the key. (When empty or null default namespace will be used)
  translations: record # Object mapping language tag to translation (e.g. {en: What a translated value!, cs: Jaká to přeložená hodnota!})
  --languagesToReturn: list # List of languages to return translations for.   If not provided, only modified translation will be provided.      (e.g. [en, de, fr])
  --branch: string # Branch name to set translations for
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/translations")
  let body = {key: $key, namespace: $namespace, translations: $translations, languagesToReturn: $languagesToReturn, branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create key or update translations
#
# POST /v2/projects/translations
# operationId: createOrUpdateTranslations_1
export def "projects-translations createOrUpdateTranslations-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  key: string # Key name to set translations for (e.g. what_a_key_to_translate)
  --namespace: string # The namespace of the key. (When empty or null default namespace will be used)
  translations: record # Object mapping language tag to translation (e.g. {en: What a translated value!, cs: Jaká to přeložená hodnota!})
  --languagesToReturn: list # List of languages to return translations for.   If not provided, only modified translation will be provided.      (e.g. [en, de, fr])
  --branch: string # Branch name to set translations for
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/translations")
  let body = {key: $key, namespace: $namespace, translations: $translations, languagesToReturn: $languagesToReturn, branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update project's translation memory assignment (read/write/priority)
#
# PUT /v2/projects/{projectId}/translation-memories/{translationMemoryId}
# operationId: updateAssignment
export def "projects-translation-memories updateAssignment" [
  translationMemoryId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --readAccess: string@bool-completer # Whether this project can read from the TM
  --writeAccess: string@bool-completer # Whether this project writes new translations to the TM
  --priority: int # Priority in suggestion results (lower = higher priority). Omit to leave the current priority unchanged. (format: int32)
  --penalty: int # Per-assignment penalty override (0–100). When null, the TM's default penalty applies. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/translation-memories/($translationMemoryId)")
  let body = {readAccess: $readAccess, writeAccess: $writeAccess, priority: $priority, penalty: $penalty} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign a shared translation memory to the project
#
# POST /v2/projects/{projectId}/translation-memories/{translationMemoryId}
# operationId: assign
export def "projects-translation-memories assign" [
  translationMemoryId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --readAccess: string@bool-completer # Whether this project can read from the TM
  --writeAccess: string@bool-completer # Whether this project writes new translations to the TM
  --priority: int # Priority in suggestion results (lower = higher priority). When null, the assignment is placed after every existing one (max + 1) so it stacks at the bottom of the list. (format: int32)
  --penalty: int # Per-assignment penalty override (0–100). When null, the TM's default penalty applies. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/translation-memories/($translationMemoryId)")
  let body = {readAccess: $readAccess, writeAccess: $writeAccess, priority: $priority, penalty: $penalty} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unassign a shared translation memory from the project
#
# DELETE /v2/projects/{projectId}/translation-memories/{translationMemoryId}
# operationId: unassign
export def "projects-translation-memories unassign" [
  translationMemoryId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/translation-memories/($translationMemoryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update project's translation memory assignment (read/write/priority)
#
# PUT /v2/projects/translation-memories/{translationMemoryId}
# operationId: updateAssignment_1
export def "projects-translation-memories updateAssignment-by-translationMemoryId" [
  translationMemoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --readAccess: string@bool-completer # Whether this project can read from the TM
  --writeAccess: string@bool-completer # Whether this project writes new translations to the TM
  --priority: int # Priority in suggestion results (lower = higher priority). Omit to leave the current priority unchanged. (format: int32)
  --penalty: int # Per-assignment penalty override (0–100). When null, the TM's default penalty applies. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/translation-memories/($translationMemoryId)")
  let body = {readAccess: $readAccess, writeAccess: $writeAccess, priority: $priority, penalty: $penalty} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign a shared translation memory to the project
#
# POST /v2/projects/translation-memories/{translationMemoryId}
# operationId: assign_1
export def "projects-translation-memories assign-by-translationMemoryId" [
  translationMemoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --readAccess: string@bool-completer # Whether this project can read from the TM
  --writeAccess: string@bool-completer # Whether this project writes new translations to the TM
  --priority: int # Priority in suggestion results (lower = higher priority). When null, the assignment is placed after every existing one (max + 1) so it stacks at the bottom of the list. (format: int32)
  --penalty: int # Per-assignment penalty override (0–100). When null, the TM's default penalty applies. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/translation-memories/($translationMemoryId)")
  let body = {readAccess: $readAccess, writeAccess: $writeAccess, priority: $priority, penalty: $penalty} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unassign a shared translation memory from the project
#
# DELETE /v2/projects/translation-memories/{translationMemoryId}
# operationId: unassign_1
export def "projects-translation-memories unassign-by-translationMemoryId" [
  translationMemoryId: int
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
  let full_url = (build-url $base $"/v2/projects/translation-memories/($translationMemoryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the project's own TM settings
#
# PUT /v2/projects/{projectId}/translation-memories/project-tm-settings
# operationId: updateProjectTmSettings
export def "projects-translation-memories-project-tm-settings updateProjectTmSettings" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --writeOnlyReviewed: string@bool-completer # When true, only translations whose state is REVIEWED are written to this project's own TM. Translations that drop back to TRANSLATED or UNTRANSLATED also remove the entry. TMX import and direct TM-browser edits bypass this filter.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/translation-memories/project-tm-settings")
  let body = {writeOnlyReviewed: $writeOnlyReviewed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the project's own TM settings
#
# PUT /v2/projects/translation-memories/project-tm-settings
# operationId: updateProjectTmSettings_1
export def "projects-translation-memories-project-tm-settings updateProjectTmSettings-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --writeOnlyReviewed: string@bool-completer # When true, only translations whose state is REVIEWED are written to this project's own TM. Translations that drop back to TRANSLATED or UNTRANSLATED also remove the entry. TMX import and direct TM-browser edits bypass this filter.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/translation-memories/project-tm-settings")
  let body = {writeOnlyReviewed: $writeOnlyReviewed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Transfer project
#
# PUT /v2/projects/{projectId}/transfer-to-organization/{organizationId}
# operationId: transferProjectToOrganization
export def "projects-transfer-to-organization transferProjectToOrganization" [
  projectId: int
  organizationId: int
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/transfer-to-organization/($organizationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reopen task
#
# PUT /v2/projects/{projectId}/tasks/{taskNumber}/reopen
# operationId: reopenTask
export def "projects-tasks-reopen reopenTask" [
  taskNumber: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/tasks/($taskNumber)/reopen")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reopen task
#
# PUT /v2/projects/tasks/{taskNumber}/reopen
# operationId: reopenTask_1
export def "projects-tasks-reopen reopenTask-by-taskNumber" [
  taskNumber: int
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
  let full_url = (build-url $base $"/v2/projects/tasks/($taskNumber)/reopen")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update task key
#
# PUT /v2/projects/{projectId}/tasks/{taskNumber}/keys/{keyId}
# operationId: updateTaskKey
export def "projects-tasks-keys updateTaskKey" [
  taskNumber: int
  keyId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --done: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/tasks/($taskNumber)/keys/($keyId)")
  let body = {done: $done} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update task key
#
# PUT /v2/projects/tasks/{taskNumber}/keys/{keyId}
# operationId: updateTaskKey_1
export def "projects-tasks-keys updateTaskKey-by-taskNumber-keyId" [
  taskNumber: int
  keyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --done: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/tasks/($taskNumber)/keys/($keyId)")
  let body = {done: $done} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get task keys
#
# GET /v2/projects/{projectId}/tasks/{taskNumber}/keys
# operationId: getTaskKeys
export def "projects-tasks-keys get" [
  taskNumber: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/tasks/($taskNumber)/keys")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or remove task keys
#
# PUT /v2/projects/{projectId}/tasks/{taskNumber}/keys
# operationId: updateTaskKeys
export def "projects-tasks-keys updateTaskKeys" [
  taskNumber: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --addKeys: list # Keys to add to task
  --removeKeys: list # Keys to remove from task
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/tasks/($taskNumber)/keys")
  let body = {addKeys: $addKeys, removeKeys: $removeKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get task keys
#
# GET /v2/projects/tasks/{taskNumber}/keys
# operationId: getTaskKeys_1
export def "projects-tasks-keys get-by-taskNumber" [
  taskNumber: int
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
  let full_url = (build-url $base $"/v2/projects/tasks/($taskNumber)/keys")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or remove task keys
#
# PUT /v2/projects/tasks/{taskNumber}/keys
# operationId: updateTaskKeys_1
export def "projects-tasks-keys updateTaskKeys-by-taskNumber" [
  taskNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --addKeys: list # Keys to add to task
  --removeKeys: list # Keys to remove from task
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/tasks/($taskNumber)/keys")
  let body = {addKeys: $addKeys, removeKeys: $removeKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Finish task
#
# PUT /v2/projects/{projectId}/tasks/{taskNumber}/finish
# operationId: finishTask
export def "projects-tasks-finish finishTask" [
  taskNumber: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/tasks/($taskNumber)/finish")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Finish task
#
# PUT /v2/projects/tasks/{taskNumber}/finish
# operationId: finishTask_1
export def "projects-tasks-finish finishTask-by-taskNumber" [
  taskNumber: int
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
  let full_url = (build-url $base $"/v2/projects/tasks/($taskNumber)/finish")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Close task
#
# PUT /v2/projects/{projectId}/tasks/{taskNumber}/close
# DEPRECATED
# operationId: closeTask
@deprecated
export def "projects-tasks-close closeTask" [
  taskNumber: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/tasks/($taskNumber)/close")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Close task
#
# PUT /v2/projects/tasks/{taskNumber}/close
# DEPRECATED
# operationId: closeTask_1
@deprecated
export def "projects-tasks-close closeTask-by-taskNumber" [
  taskNumber: int
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
  let full_url = (build-url $base $"/v2/projects/tasks/($taskNumber)/close")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Close task
#
# PUT /v2/projects/{projectId}/tasks/{taskNumber}/cancel
# operationId: cancelTask
export def "projects-tasks-cancel cancelTask" [
  taskNumber: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/tasks/($taskNumber)/cancel")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Close task
#
# PUT /v2/projects/tasks/{taskNumber}/cancel
# operationId: cancelTask_1
export def "projects-tasks-cancel cancelTask-by-taskNumber" [
  taskNumber: int
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
  let full_url = (build-url $base $"/v2/projects/tasks/($taskNumber)/cancel")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get task
#
# GET /v2/projects/{projectId}/tasks/{taskNumber}
# operationId: getTask
export def "projects-tasks get" [
  taskNumber: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/tasks/($taskNumber)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update task
#
# PUT /v2/projects/{projectId}/tasks/{taskNumber}
# operationId: updateTask
export def "projects-tasks updateTask" [
  taskNumber: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  description: string
  --dueDate: int # Due to date in epoch format (milliseconds). (format: int64, e.g. 1661172869000)
  assignees: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/tasks/($taskNumber)")
  let body = {name: $name, description: $description, dueDate: $dueDate, assignees: $assignees} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get task
#
# GET /v2/projects/tasks/{taskNumber}
# operationId: getTask_1
export def "projects-tasks get-by-taskNumber" [
  taskNumber: int
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
  let full_url = (build-url $base $"/v2/projects/tasks/($taskNumber)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update task
#
# PUT /v2/projects/tasks/{taskNumber}
# operationId: updateTask_1
export def "projects-tasks updateTask-by-taskNumber" [
  taskNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  description: string
  --dueDate: int # Due to date in epoch format (milliseconds). (format: int64, e.g. 1661172869000)
  assignees: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/tasks/($taskNumber)")
  let body = {name: $name, description: $description, dueDate: $dueDate, assignees: $assignees} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get QA check settings for the project
#
# GET /v2/projects/{projectId}/qa-settings
# operationId: getSettings
export def "projects-qa-settings get" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/qa-settings")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update QA check settings for the project
#
# PUT /v2/projects/{projectId}/qa-settings
# operationId: updateSettings
export def "projects-qa-settings updateSettings" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  settings: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/qa-settings")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get QA settings overrides for a specific language
#
# GET /v2/projects/{projectId}/qa-settings/languages/{languageId}
# operationId: getLanguageSettings
export def "projects-qa-settings-languages get" [
  languageId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/qa-settings/languages/($languageId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set per-language QA settings override
#
# PUT /v2/projects/{projectId}/qa-settings/languages/{languageId}
# operationId: updateLanguageSettings
export def "projects-qa-settings-languages updateLanguageSettings" [
  languageId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  settings: record # Map of check types to their severity. Null values mean 'inherit from global settings'.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/qa-settings/languages/($languageId)")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset language QA settings to global defaults
#
# DELETE /v2/projects/{projectId}/qa-settings/languages/{languageId}
# operationId: deleteLanguageSettings
export def "projects-qa-settings-languages delete" [
  languageId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/qa-settings/languages/($languageId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable or disable QA checks for the project
#
# PUT /v2/projects/{projectId}/qa-settings/enabled
# operationId: setQaEnabled
export def "projects-qa-settings-enabled setQaEnabled" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/qa-settings/enabled")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get per-language auto-translation settings
#
# GET /v2/projects/{projectId}/per-language-auto-translation-settings
# operationId: getPerLanguageAutoTranslationSettings
export def "projects-per-language-auto-translation-settings get" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/per-language-auto-translation-settings")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set per-language auto-translation settings
#
# PUT /v2/projects/{projectId}/per-language-auto-translation-settings
# operationId: setPerLanguageAutoTranslationSettings
export def "projects-per-language-auto-translation-settings setPerLanguageAutoTranslationSettings" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/per-language-auto-translation-settings")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update namespace
#
# PUT /v2/projects/{projectId}/namespaces/{id}
# operationId: update_3
export def "projects-namespaces update-by-id-projectId" [
  id: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/namespaces/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update namespace
#
# PUT /v2/projects/namespaces/{id}
# operationId: update_4
export def "projects-namespaces update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/namespaces/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get machine translation settings
#
# GET /v2/projects/{projectId}/machine-translation-service-settings
# operationId: getMachineTranslationSettings
export def "projects-machine-translation-service-settings get" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/machine-translation-service-settings")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sets machine translation settings
#
# PUT /v2/projects/{projectId}/machine-translation-service-settings
# operationId: setMachineTranslationSettings
# --settings item shape: {targetLanguageId?: int, primaryService?: "GOOGLE"|"AWS"|"DEEPL"|"AZURE"|"BAIDU"|"PROMPT", primaryServiceInfo?: record, enabledServices?: list, enabledServicesInfo?: list}
export def "projects-machine-translation-service-settings setMachineTranslationSettings" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  settings: list # item shape: {targetLanguageId?: int, primaryService?: "GOOGLE"|"AWS"|"DEEPL"|"AZURE"|"BAIDU"|"PROMPT", primaryServiceInfo?: record, enabledServices?: list, enabledServicesInfo?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/machine-translation-service-settings")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sets machine translation default prompt for all languages
#
# PUT /v2/projects/{projectId}/machine-translation-service-settings/set-default-prompt/{promptId}
# operationId: setMachineTranslationSettings_1
export def "projects-machine-translation-service-settings-set-default-prompt setMachineTranslationSettings-by-promptId-projectId" [
  promptId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/machine-translation-service-settings/set-default-prompt/($promptId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Leave project
#
# PUT /v2/projects/{projectId}/leave
# operationId: leaveProject
export def "projects-leave leaveProject" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/leave")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one language
#
# GET /v2/projects/{projectId}/languages/{languageId}
# operationId: get_6
export def "projects-languages get-by-languageId-projectId" [
  languageId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/languages/($languageId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update language
#
# PUT /v2/projects/{projectId}/languages/{languageId}
# operationId: editLanguage
export def "projects-languages editLanguage" [
  languageId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Language name in english (e.g. Czech)
  originalName: string # Language name in this language (e.g. čeština)
  tag: string # Language tag according to BCP 47 definition (e.g. cs-CZ)
  --flagEmoji: string # Language flag emoji as UTF-8 emoji (e.g. 🇨🇿)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/languages/($languageId)")
  let body = {name: $name, originalName: $originalName, tag: $tag, flagEmoji: $flagEmoji} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete specific language
#
# DELETE /v2/projects/{projectId}/languages/{languageId}
# operationId: deleteLanguage
export def "projects-languages delete" [
  languageId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/languages/($languageId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one language
#
# GET /v2/projects/languages/{languageId}
# operationId: get_7
export def "projects-languages get-by-languageId" [
  languageId: int
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
  let full_url = (build-url $base $"/v2/projects/languages/($languageId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update language
#
# PUT /v2/projects/languages/{languageId}
# operationId: editLanguage_1
export def "projects-languages editLanguage-by-languageId" [
  languageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Language name in english (e.g. Czech)
  originalName: string # Language name in this language (e.g. čeština)
  tag: string # Language tag according to BCP 47 definition (e.g. cs-CZ)
  --flagEmoji: string # Language flag emoji as UTF-8 emoji (e.g. 🇨🇿)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/languages/($languageId)")
  let body = {name: $name, originalName: $originalName, tag: $tag, flagEmoji: $flagEmoji} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete specific language
#
# DELETE /v2/projects/languages/{languageId}
# operationId: deleteLanguage_1
export def "projects-languages delete-by-languageId" [
  languageId: int
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
  let full_url = (build-url $base $"/v2/projects/languages/($languageId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set suggestion active
#
# PUT /v2/projects/{projectId}/languages/{languageId}/key/{keyId}/suggestion/{suggestionId}/set-active
# operationId: suggestionSetActive
export def "projects-languages-key-suggestion-set-active suggestionSetActive" [
  languageId: int
  keyId: int
  suggestionId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/languages/($languageId)/key/($keyId)/suggestion/($suggestionId)/set-active")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set suggestion active
#
# PUT /v2/projects/languages/{languageId}/key/{keyId}/suggestion/{suggestionId}/set-active
# operationId: suggestionSetActive_1
export def "projects-languages-key-suggestion-set-active suggestionSetActive-by-languageId-keyId-suggestionId" [
  languageId: int
  keyId: int
  suggestionId: int
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
  let full_url = (build-url $base $"/v2/projects/languages/($languageId)/key/($keyId)/suggestion/($suggestionId)/set-active")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Decline suggestion
#
# PUT /v2/projects/{projectId}/languages/{languageId}/key/{keyId}/suggestion/{suggestionId}/decline
# operationId: declineSuggestion
export def "projects-languages-key-suggestion-decline declineSuggestion" [
  languageId: int
  keyId: int
  suggestionId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/languages/($languageId)/key/($keyId)/suggestion/($suggestionId)/decline")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Decline suggestion
#
# PUT /v2/projects/languages/{languageId}/key/{keyId}/suggestion/{suggestionId}/decline
# operationId: declineSuggestion_1
export def "projects-languages-key-suggestion-decline declineSuggestion-by-languageId-keyId-suggestionId" [
  languageId: int
  keyId: int
  suggestionId: int
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
  let full_url = (build-url $base $"/v2/projects/languages/($languageId)/key/($keyId)/suggestion/($suggestionId)/decline")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept suggestion
#
# PUT /v2/projects/{projectId}/languages/{languageId}/key/{keyId}/suggestion/{suggestionId}/accept
# operationId: acceptSuggestion
export def "projects-languages-key-suggestion-accept acceptSuggestion" [
  languageId: int
  keyId: int
  suggestionId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --declineOther: string@bool-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "declineOther" $declineOther "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/languages/($languageId)/key/($keyId)/suggestion/($suggestionId)/accept" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept suggestion
#
# PUT /v2/projects/languages/{languageId}/key/{keyId}/suggestion/{suggestionId}/accept
# operationId: acceptSuggestion_1
export def "projects-languages-key-suggestion-accept acceptSuggestion-by-languageId-keyId-suggestionId" [
  languageId: int
  keyId: int
  suggestionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --declineOther: string@bool-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "declineOther" $declineOther "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/languages/($languageId)/key/($keyId)/suggestion/($suggestionId)/accept" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sets language level prompt customization
#
# PUT /v2/projects/{projectId}/languages/{languageId}/ai-prompt-customization
# operationId: setLanguagePromptCustomization
export def "projects-languages-ai-prompt-customization setLanguagePromptCustomization" [
  languageId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The language description used in the prompt that helps AI translator to fine tune results for specific language (e.g. For arabic language, we are super formal. Always use these translations:  Paper -> ورقة Office -> مكتب )
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/languages/($languageId)/ai-prompt-customization")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Auto translates keys
#
# PUT /v2/projects/{projectId}/keys/{keyId}/auto-translate
# operationId: autoTranslate
export def "projects-keys-auto-translate autoTranslate" [
  keyId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --languages: list # Tags of languages to auto-translate.  When no languages provided, it translates only untranslated languages.
  --useMachineTranslation: string@bool-completer
  --useTranslationMemory: string@bool-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languages" $languages "multi") (serialize-qp "useMachineTranslation" $useMachineTranslation "scalar") (serialize-qp "useTranslationMemory" $useTranslationMemory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/($keyId)/auto-translate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Auto translates keys
#
# PUT /v2/projects/keys/{keyId}/auto-translate
# operationId: autoTranslate_1
export def "projects-keys-auto-translate autoTranslate-by-keyId" [
  keyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --languages: list # Tags of languages to auto-translate.  When no languages provided, it translates only untranslated languages.
  --useMachineTranslation: string@bool-completer
  --useTranslationMemory: string@bool-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languages" $languages "multi") (serialize-qp "useMachineTranslation" $useMachineTranslation "scalar") (serialize-qp "useTranslationMemory" $useTranslationMemory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/keys/($keyId)/auto-translate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get disabled languages
#
# GET /v2/projects/{projectId}/keys/{id}/disabled-languages
# operationId: getDisabledLanguages
export def "projects-keys-disabled-languages get" [
  id: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/($id)/disabled-languages")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set disabled languages
#
# PUT /v2/projects/{projectId}/keys/{id}/disabled-languages
# operationId: setDisabledLanguages
export def "projects-keys-disabled-languages setDisabledLanguages" [
  id: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  languageIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/($id)/disabled-languages")
  let body = {languageIds: $languageIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get disabled languages
#
# GET /v2/projects/keys/{id}/disabled-languages
# operationId: getDisabledLanguages_1
export def "projects-keys-disabled-languages get-by-id" [
  id: int
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
  let full_url = (build-url $base $"/v2/projects/keys/($id)/disabled-languages")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set disabled languages
#
# PUT /v2/projects/keys/{id}/disabled-languages
# operationId: setDisabledLanguages_1
export def "projects-keys-disabled-languages setDisabledLanguages-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  languageIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/keys/($id)/disabled-languages")
  let body = {languageIds: $languageIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit key and related data
#
# PUT /v2/projects/{projectId}/keys/{id}/complex-update
# operationId: complexEdit
# --screenshotsToAdd item shape: {text?: string, uploadedImageId: int, positions?: list}
# --relatedKeysInOrder item shape: {namespace?: string, keyName: string, branch?: string}
@deprecated --flag screenshotUploadedImageIds
export def "projects-keys-complex-update complexEdit" [
  id: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the key
  --namespace: string
  --translations: record # Translations to update
  --states: record # Translation states to update, if not provided states won't be modified
  --tags: list # Tags of the key. If not provided tags won't be modified
  --screenshotIdsToDelete: list # IDs of screenshots to delete
  --screenshotUploadedImageIds: list # Ids of screenshots uploaded with /v2/image-upload endpoint (DEPRECATED)
  --screenshotsToAdd: list # item shape: {text?: string, uploadedImageId: int, positions?: list}
  --relatedKeysInOrder: list # Keys in the document used as a context for machine translation. Keys in the same order as they appear in the document. The order is important! We are using it for graph distance calculation.  — item shape: {namespace?: string, keyName: string, branch?: string}
  --description: string # Description of the key. It's also used as a context for Tolgee AI translator
  --isPlural: string@bool-completer # If key is pluralized. If it will be reflected in the editor. If null, value won't be modified.
  --pluralArgName: string # The argument name for the plural. If null, value won't be modified. If isPlural is false, this value will be ignored.
  --warnOnDataLoss: string@bool-completer # If true, it will fail with 400 (with code plural_forms_data_loss) if plural is disabled and there are plural forms, which would be lost by the action. You can get rid of this warning by setting this value to false.
  --custom: record # Custom values of the key. If not provided, custom values won't be modified
  --maxCharLimit: int # Maximum character limit. Null = don't modify. 0 = remove limit. (format: int32)
  --branch: string # Branch of the key. If not provided, default branch will be used
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/($id)/complex-update")
  let body = {name: $name, namespace: $namespace, translations: $translations, states: $states, tags: $tags, screenshotIdsToDelete: $screenshotIdsToDelete, screenshotUploadedImageIds: $screenshotUploadedImageIds, screenshotsToAdd: $screenshotsToAdd, relatedKeysInOrder: $relatedKeysInOrder, description: $description, isPlural: $isPlural, pluralArgName: $pluralArgName, warnOnDataLoss: $warnOnDataLoss, custom: $custom, maxCharLimit: $maxCharLimit, branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit key and related data
#
# PUT /v2/projects/keys/{id}/complex-update
# operationId: complexEdit_1
# --screenshotsToAdd item shape: {text?: string, uploadedImageId: int, positions?: list}
# --relatedKeysInOrder item shape: {namespace?: string, keyName: string, branch?: string}
@deprecated --flag screenshotUploadedImageIds
export def "projects-keys-complex-update complexEdit-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the key
  --namespace: string
  --translations: record # Translations to update
  --states: record # Translation states to update, if not provided states won't be modified
  --tags: list # Tags of the key. If not provided tags won't be modified
  --screenshotIdsToDelete: list # IDs of screenshots to delete
  --screenshotUploadedImageIds: list # Ids of screenshots uploaded with /v2/image-upload endpoint (DEPRECATED)
  --screenshotsToAdd: list # item shape: {text?: string, uploadedImageId: int, positions?: list}
  --relatedKeysInOrder: list # Keys in the document used as a context for machine translation. Keys in the same order as they appear in the document. The order is important! We are using it for graph distance calculation.  — item shape: {namespace?: string, keyName: string, branch?: string}
  --description: string # Description of the key. It's also used as a context for Tolgee AI translator
  --isPlural: string@bool-completer # If key is pluralized. If it will be reflected in the editor. If null, value won't be modified.
  --pluralArgName: string # The argument name for the plural. If null, value won't be modified. If isPlural is false, this value will be ignored.
  --warnOnDataLoss: string@bool-completer # If true, it will fail with 400 (with code plural_forms_data_loss) if plural is disabled and there are plural forms, which would be lost by the action. You can get rid of this warning by setting this value to false.
  --custom: record # Custom values of the key. If not provided, custom values won't be modified
  --maxCharLimit: int # Maximum character limit. Null = don't modify. 0 = remove limit. (format: int32)
  --branch: string # Branch of the key. If not provided, default branch will be used
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/keys/($id)/complex-update")
  let body = {name: $name, namespace: $namespace, translations: $translations, states: $states, tags: $tags, screenshotIdsToDelete: $screenshotIdsToDelete, screenshotUploadedImageIds: $screenshotUploadedImageIds, screenshotsToAdd: $screenshotsToAdd, relatedKeysInOrder: $relatedKeysInOrder, description: $description, isPlural: $isPlural, pluralArgName: $pluralArgName, warnOnDataLoss: $warnOnDataLoss, custom: $custom, maxCharLimit: $maxCharLimit, branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get one key
#
# GET /v2/projects/{projectId}/keys/{id}
# operationId: get_8
export def "projects-keys get-by-id-projectId" [
  id: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/($id)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit key name
#
# PUT /v2/projects/{projectId}/keys/{id}
# operationId: edit
export def "projects-keys edit" [
  id: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --namespace: string
  --branch: string # The branch of the key. (When empty or null default branch will be used)
  --description: string # Description of the key (e.g. This key is used on homepage. It's a label of sign up button.)
  --maxCharLimit: int # Maximum character limit for translations of this key. Null means no limit. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/($id)")
  let body = {name: $name, namespace: $namespace, branch: $branch, description: $description, maxCharLimit: $maxCharLimit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get one key
#
# GET /v2/projects/keys/{id}
# operationId: get_9
export def "projects-keys get-by-id" [
  id: int
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
  let full_url = (build-url $base $"/v2/projects/keys/($id)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit key name
#
# PUT /v2/projects/keys/{id}
# operationId: edit_1
export def "projects-keys edit-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --namespace: string
  --branch: string # The branch of the key. (When empty or null default branch will be used)
  --description: string # Description of the key (e.g. This key is used on homepage. It's a label of sign up button.)
  --maxCharLimit: int # Maximum character limit for translations of this key. Null means no limit. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/keys/($id)")
  let body = {name: $name, namespace: $namespace, branch: $branch, description: $description, maxCharLimit: $maxCharLimit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Restore a trashed key
#
# PUT /v2/projects/{projectId}/keys/trash/{keyId}/restore
# operationId: restore
export def "projects-keys-trash-restore restore" [
  keyId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/trash/($keyId)/restore")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restore a trashed key
#
# PUT /v2/projects/keys/trash/{keyId}/restore
# operationId: restore_1
export def "projects-keys-trash-restore restore-by-keyId" [
  keyId: int
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
  let full_url = (build-url $base $"/v2/projects/keys/trash/($keyId)/restore")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate user invitation link for project
#
# PUT /v2/projects/{projectId}/invite
# operationId: inviteUser
@deprecated --flag languages
export def "projects-invite inviteUser" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer
  --scopes: list # Granted scopes for the invited user (e.g. [translations.view, translations.edit])
  --languages: list # Deprecated -> use translate languages (DEPRECATED)
  --translateLanguages: list # Languages user can translate to
  --viewLanguages: list # Languages user can view
  --stateChangeLanguages: list # Languages user can change translation state (review)
  --suggestLanguages: list # Languages user can suggest translation
  --email: string # Email to send invitation to
  --name: string # Name of invited user
  --agencyId: int # Id of invited agency (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/invite")
  let body = {type: $type, scopes: $scopes, languages: $languages, translateLanguages: $translateLanguages, viewLanguages: $viewLanguages, stateChangeLanguages: $stateChangeLanguages, suggestLanguages: $suggestLanguages, email: $email, name: $name, agencyId: $agencyId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Content Storage
#
# GET /v2/projects/{projectId}/content-storages/{contentStorageId}
# operationId: get_10
export def "projects-content-storages get-by-contentStorageId-projectId" [
  contentStorageId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/content-storages/($contentStorageId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Content Storage
#
# PUT /v2/projects/{projectId}/content-storages/{contentStorageId}
# operationId: update_5
# --azureContentStorageConfig shape: {connectionString?: string, containerName: string}
# --s3ContentStorageConfig shape: {bucketName: string, accessKey?: string, secretKey?: string, endpoint: string, signingRegion: string, path: string, contentStorageType?: "S3"|"AZURE", enabled?: bool}
export def "projects-content-storages update-by-contentStorageId-projectId" [
  contentStorageId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --azureContentStorageConfig: record # shape: {connectionString?: string, containerName: string}
  --s3ContentStorageConfig: record # shape: {bucketName: string, accessKey?: string, secretKey?: string, endpoint: string, signingRegion: string, path: string, contentStorageType?: "S3"|"AZURE", enabled?: bool}
  --publicUrlPrefix: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/content-storages/($contentStorageId)")
  let body = {name: $name, azureContentStorageConfig: $azureContentStorageConfig, s3ContentStorageConfig: $s3ContentStorageConfig, publicUrlPrefix: $publicUrlPrefix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Content Storage
#
# DELETE /v2/projects/{projectId}/content-storages/{contentStorageId}
# operationId: delete_4
export def "projects-content-storages delete-by-contentStorageId-projectId" [
  contentStorageId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/content-storages/($contentStorageId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one Content Delivery Config
#
# GET /v2/projects/{projectId}/content-delivery-configs/{id}
# operationId: get_11
export def "projects-content-delivery-configs get-by-id-projectId" [
  id: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/content-delivery-configs/($id)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Content Delivery Config
#
# PUT /v2/projects/{projectId}/content-delivery-configs/{id}
# operationId: update_6
export def "projects-content-delivery-configs update-by-id-projectId" [
  id: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --contentStorageId: int # Id of custom storage to use for content delivery. If null, default server storage is used. Tolgee Cloud provides default Content Storage. (format: int64)
  --autoPublish: string@bool-completer # If true, data are published to the content delivery automatically after each change.
  --slug: string # Tolgee uses a custom slug as a directory name for content storage and public content delivery URL. It is only applicable for custom storage. This field needs to be kept null for Tolgee Cloud content storage or global server storage on self-hosted instances.  Slag has to match following regular expression: `^[a-z0-9]+(?:-[a-z0-9]+)*$`.  If null is provided for update operation, slug will be assigned with generated value.
  --pruneBeforePublish: string@bool-completer # Whether the data in the CDN should be pruned before publishing new data.  In some cases, you might want to keep the data in the storage and only replace the files created by following publish operation.
  --zip: string@bool-completer # Whether to export all files as a single zip archive (translations.zip).
  --languages: list # Languages to be contained in export.                  If null, all languages are exported (e.g. en)
  format: string@format-completer # Format to export to
  --structureDelimiter: string # Delimiter to structure file content.   e.g. For key "home.header.title" would result in {"home": {"header": "title": {"Hello"}}} structure.  When null, resulting file won't be structured. Works only for generic structured formats (e.g. JSON, YAML),  specific formats like `YAML_RUBY` don't honor this parameter.
  --supportArrays: string@bool-completer # If true, for structured formats (like JSON) arrays are supported.   e.g. Key hello[0] will be exported as {"hello": ["..."]}
  --filterKeyId: list # Filter key IDs to be contained in export
  --filterKeyIdNot: list # Filter key IDs not to be contained in export
  --filterTag: string # Filter keys tagged by.  This filter works the same as `filterTagIn` but in this cases it accepts single tag only.
  --filterTagIn: list # Filter keys tagged by one of provided tags
  --filterTagNotIn: list # Filter keys not tagged by one of provided tags
  --filterKeyPrefix: string # Filter keys with prefix
  --filterState: list # Filter translations with state. By default, all states except untranslated is exported.
  --filterNamespace: list # Filter translations with namespace. By default, all namespaces everything are exported. To export default namespace, use empty string.
  --messageFormat: string@messageFormat-completer # Message format to be used for export.        e.g. PHP_PO: Hello %s, ICU: Hello {name}.   This property is honored only for generic formats like JSON or YAML.  For specific formats like `YAML_RUBY` it's ignored.
  --fileStructureTemplate: string # This is a template that defines the structure of the resulting .zip file content.  The template is a string that can contain the following placeholders: {namespace}, {languageTag},  {androidLanguageTag}, {snakeLanguageTag}, {extension}.   For example, when exporting to JSON with the template `{namespace}/{languageTag}.{extension}`,  the English translations of the `home` namespace will be stored in `home/en.json`.  The `{snakeLanguageTag}` placeholder is the same as `{languageTag}` but in snake case. (e.g., en_US).  The Android specific `{androidLanguageTag}` placeholder is the same as `{languageTag}`  but in Android format. (e.g., en-rUS)
  --escapeHtml: string@bool-completer # If true, HTML tags are escaped in the exported file. (Supported in the XLIFF format only).  e.g. Key <b>hello</b> will be exported as &lt;b&gt;hello&lt;/b&gt;
  --filterBranch: string # Filter translations with branch.   By default, default branch is exported.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/content-delivery-configs/($id)")
  let body = {name: $name, contentStorageId: $contentStorageId, autoPublish: $autoPublish, slug: $slug, pruneBeforePublish: $pruneBeforePublish, zip: $zip, languages: $languages, format: $format, structureDelimiter: $structureDelimiter, supportArrays: $supportArrays, filterKeyId: $filterKeyId, filterKeyIdNot: $filterKeyIdNot, filterTag: $filterTag, filterTagIn: $filterTagIn, filterTagNotIn: $filterTagNotIn, filterKeyPrefix: $filterKeyPrefix, filterState: $filterState, filterNamespace: $filterNamespace, messageFormat: $messageFormat, fileStructureTemplate: $fileStructureTemplate, escapeHtml: $escapeHtml, filterBranch: $filterBranch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Publish to Content Delivery
#
# POST /v2/projects/{projectId}/content-delivery-configs/{id}
# operationId: post
export def "projects-content-delivery-configs post" [
  id: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/content-delivery-configs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Content Delivery Config
#
# DELETE /v2/projects/{projectId}/content-delivery-configs/{id}
# operationId: delete_5
export def "projects-content-delivery-configs delete-by-id-projectId" [
  id: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/content-delivery-configs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve all branch merge session conflicts
#
# PUT /v2/projects/{projectId}/branches/merge/{mergeId}/resolve-all
# operationId: resolveAllConflicts
export def "projects-branches-merge-resolve-all resolveAllConflicts" [
  mergeId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  resolve: string@resolve-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/branches/merge/($mergeId)/resolve-all")
  let body = {resolve: $resolve} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resolve all branch merge session conflicts
#
# PUT /v2/projects/branches/merge/{mergeId}/resolve-all
# operationId: resolveAllConflicts_1
export def "projects-branches-merge-resolve-all resolveAllConflicts-by-mergeId" [
  mergeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  resolve: string@resolve-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/branches/merge/($mergeId)/resolve-all")
  let body = {resolve: $resolve} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resolve branch merge session conflicts
#
# PUT /v2/projects/{projectId}/branches/merge/{mergeId}/resolve
# operationId: resolveConflict
export def "projects-branches-merge-resolve resolveConflict" [
  mergeId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  changeId: int # Merge change id (format: int64)
  resolve: string@resolve-completer # Type of resolution
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/branches/merge/($mergeId)/resolve")
  let body = {changeId: $changeId, resolve: $resolve} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resolve branch merge session conflicts
#
# PUT /v2/projects/branches/merge/{mergeId}/resolve
# operationId: resolveConflict_1
export def "projects-branches-merge-resolve resolveConflict-by-mergeId" [
  mergeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  changeId: int # Merge change id (format: int64)
  resolve: string@resolve-completer # Type of resolution
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/branches/merge/($mergeId)/resolve")
  let body = {changeId: $changeId, resolve: $resolve} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload project avatar
#
# PUT /v2/projects/{projectId}/avatar
# operationId: uploadAvatar_1
export def "projects-avatar uploadAvatar-by-projectId" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  avatar: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/avatar")
  let body = {avatar: $avatar} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete project avatar
#
# DELETE /v2/projects/{projectId}/avatar
# operationId: removeAvatar_1
export def "projects-avatar removeAvatar-by-projectId" [
  projectId: int
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/avatar")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get default auto-translation settings for project
#
# GET /v2/projects/{projectId}/auto-translation-settings
# DEPRECATED
# operationId: getAutoTranslationSettings
@deprecated
export def "projects-auto-translation-settings get" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/auto-translation-settings")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set default auto translation settings for project
#
# PUT /v2/projects/{projectId}/auto-translation-settings
# DEPRECATED
# operationId: setAutoTranslationSettings
@deprecated
export def "projects-auto-translation-settings setAutoTranslationSettings" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --languageId: int # format: int64
  --usingTranslationMemory: string@bool-completer # If true, new keys will be automatically translated via batch operation using translation memory when 100% match is found
  --usingMachineTranslation: string@bool-completer # If true, new keys will be automatically translated via batch operationusing primary machine translation service.When "usingTranslationMemory" is enabled, it tries to translate it with translation memory first.
  --enableForImport: string@bool-completer # If true, import will trigger batch operation to translate the new new keys. It includes also the data imported via CLI, Figma, or other integrations using batch key import.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/auto-translation-settings")
  let body = {languageId: $languageId, usingTranslationMemory: $usingTranslationMemory, usingMachineTranslation: $usingMachineTranslation, enableForImport: $enableForImport} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns project level prompt customization
#
# GET /v2/projects/{projectId}/ai-prompt-customization
# operationId: getPromptProjectCustomization
export def "projects-ai-prompt-customization get" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/ai-prompt-customization")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sets project level prompt customization
#
# PUT /v2/projects/{projectId}/ai-prompt-customization
# operationId: setPromptProjectCustomization
export def "projects-ai-prompt-customization setPromptProjectCustomization" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The project description used in the  prompt that helps AI translator to understand the context of your project. (e.g. We are Dunder Mifflin, a paper company. We sell paper. This is an project of translations for out paper selling app.)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/ai-prompt-customization")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get one PAK
#
# GET /v2/pats/{id}
# operationId: get_12
export def "pats get-by-id" [
  id: int
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
  let full_url = (build-url $base $"/v2/pats/($id)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update PAK
#
# PUT /v2/pats/{id}
# operationId: update_7
export def "pats update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # New description of the PAT
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/pats/($id)")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete PAK
#
# DELETE /v2/pats/{id}
# operationId: delete_6
export def "pats delete-by-id" [
  id: int
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
  let full_url = (build-url $base $"/v2/pats/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Regenerate PAK
#
# PUT /v2/pats/{id}/regenerate
# operationId: regenerate
export def "pats-regenerate regenerate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expiresAt: int # Expiration date in epoch format (milliseconds). When null key never expires. (format: int64, e.g. 1661172869000)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/pats/($id)/regenerate")
  let body = {expiresAt: $expiresAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set user role
#
# PUT /v2/organizations/{organizationId}/users/{userId}/set-role
# operationId: setUserRole
export def "organizations-users-set-role setUserRole" [
  organizationId: int
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  roleType: string@roleType-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/users/($userId)/set-role")
  let body = {roleType: $roleType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get translation memory
#
# GET /v2/organizations/{organizationId}/translation-memories/{translationMemoryId}
# operationId: get_13
export def "organizations-translation-memories get-by-organizationId-translationMemoryId" [
  organizationId: int
  translationMemoryId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories/($translationMemoryId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update shared translation memory
#
# PUT /v2/organizations/{organizationId}/translation-memories/{translationMemoryId}
# operationId: update_8
# --assignedProjects item shape: {projectId: int, readAccess: bool, writeAccess: bool, penalty?: int}
export def "organizations-translation-memories update-by-organizationId-translationMemoryId" [
  organizationId: int
  translationMemoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Translation memory name (e.g. Marketing TM)
  sourceLanguageTag: string # Source language tag according to BCP 47 definition (e.g. en)
  --assignedProjects: list # Project assignments with access settings. — item shape: {projectId: int, readAccess: bool, writeAccess: bool, penalty?: int}
  --defaultPenalty: int # Default penalty (0–100) subtracted from match scores for every assignment that does not define its own override. Defaults to 0. (format: int32)
  --writeOnlyReviewed: string@bool-completer # When true, only translations whose state is REVIEWED are written to this TM. Translations that drop back to TRANSLATED or UNTRANSLATED also remove the entry. TMX import and direct TM-browser edits bypass this filter. Defaults to false.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories/($translationMemoryId)")
  let body = {name: $name, sourceLanguageTag: $sourceLanguageTag, assignedProjects: $assignedProjects, defaultPenalty: $defaultPenalty, writeOnlyReviewed: $writeOnlyReviewed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete shared translation memory
#
# DELETE /v2/organizations/{organizationId}/translation-memories/{translationMemoryId}
# operationId: delete_7
export def "organizations-translation-memories delete-by-organizationId-translationMemoryId" [
  organizationId: int
  translationMemoryId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories/($translationMemoryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Toggle the reviewed-only flag on any TM in the organization
#
# PUT /v2/organizations/{organizationId}/translation-memories/{translationMemoryId}/write-only-reviewed
# operationId: setWriteOnlyReviewed
export def "organizations-translation-memories-write-only-reviewed setWriteOnlyReviewed" [
  organizationId: int
  translationMemoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --writeOnlyReviewed: string@bool-completer # When true, only translations whose state is REVIEWED are written to this project's own TM. Translations that drop back to TRANSLATED or UNTRANSLATED also remove the entry. TMX import and direct TM-browser edits bypass this filter.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories/($translationMemoryId)/write-only-reviewed")
  let body = {writeOnlyReviewed: $writeOnlyReviewed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single translation memory entry
#
# GET /v2/organizations/{organizationId}/translation-memories/{translationMemoryId}/entries/{entryId}
# operationId: get_14
export def "organizations-translation-memories-entries get-by-organizationId-translationMemoryId-entryId" [
  organizationId: int
  translationMemoryId: int
  entryId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories/($translationMemoryId)/entries/($entryId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a translation memory entry
#
# PUT /v2/organizations/{organizationId}/translation-memories/{translationMemoryId}/entries/{entryId}
# operationId: update_9
export def "organizations-translation-memories-entries update-by-organizationId-translationMemoryId-entryId" [
  organizationId: int
  translationMemoryId: int
  entryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceText: string # Source text (in the TM's source language) (e.g. Hello world)
  targetText: string # Target translation text (e.g. Hallo Welt)
  targetLanguageTag: string # Target language tag according to BCP 47 definition (e.g. de)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories/($translationMemoryId)/entries/($entryId)")
  let body = {sourceText: $sourceText, targetText: $targetText, targetLanguageTag: $targetLanguageTag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a translation memory entry
#
# DELETE /v2/organizations/{organizationId}/translation-memories/{translationMemoryId}/entries/{entryId}
# operationId: delete_8
export def "organizations-translation-memories-entries delete-by-organizationId-translationMemoryId-entryId" [
  organizationId: int
  translationMemoryId: int
  entryId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories/($translationMemoryId)/entries/($entryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get SSO Tenant configuration for organization
#
# GET /v2/organizations/{organizationId}/sso
# operationId: findProvider
export def "organizations-sso findProvider" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/sso")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set SSO Tenant configuration for organization
#
# PUT /v2/organizations/{organizationId}/sso
# operationId: setProvider
export def "organizations-sso setProvider" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer
  --force: string@bool-completer
  clientId: string
  clientSecret: string
  authorizationUri: string
  tokenUri: string
  domain: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/sso")
  let body = {enabled: $enabled, force: $force, clientId: $clientId, clientSecret: $clientSecret, authorizationUri: $authorizationUri, tokenUri: $tokenUri, domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set organization base permission
#
# PUT /v2/organizations/{organizationId}/set-base-permissions
# operationId: setBasePermissions
export def "organizations-set-base-permissions setBasePermissions" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scopes: list # Granted scopes to all projects for all organization users without direct project permissions set. (e.g. [translations.view, translations.edit])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scopes" $scopes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/set-base-permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set organization base permission
#
# PUT /v2/organizations/{organizationId}/set-base-permissions/{permissionType}
# operationId: setBasePermissions_1
export def "organizations-set-base-permissions setBasePermissions-by-organizationId-permissionType" [
  organizationId: int
  permissionType: string
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/set-base-permissions/($permissionType)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update organization-specific provider
#
# PUT /v2/organizations/{organizationId}/llm-providers/{providerId}
# operationId: updateProvider
export def "organizations-llm-providers updateProvider" [
  organizationId: int
  providerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  type: string@type-completer-1
  apiUrl: string
  --apiKey: string
  --priority: string@priority-completer
  --model: string
  --deployment: string
  --keepAlive: string
  --format: string
  --reasoningEffort: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/llm-providers/($providerId)")
  let body = {name: $name, type: $type, apiUrl: $apiUrl, apiKey: $apiKey, priority: $priority, model: $model, deployment: $deployment, keepAlive: $keepAlive, format: $format, reasoningEffort: $reasoningEffort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete organization-specific provider
#
# DELETE /v2/organizations/{organizationId}/llm-providers/{providerId}
# operationId: deleteProvider
export def "organizations-llm-providers delete" [
  organizationId: int
  providerId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/llm-providers/($providerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get glossary
#
# GET /v2/organizations/{organizationId}/glossaries/{glossaryId}
# operationId: get_15
export def "organizations-glossaries get-by-organizationId-glossaryId" [
  organizationId: int
  glossaryId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries/($glossaryId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update glossary
#
# PUT /v2/organizations/{organizationId}/glossaries/{glossaryId}
# operationId: update_10
export def "organizations-glossaries update-by-organizationId-glossaryId" [
  organizationId: int
  glossaryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Glossary name (e.g. My glossary)
  baseLanguageTag: string # Language tag according to BCP 47 definition (e.g. cs-CZ)
  --assignedProjectIds: list # Projects assigned to glossary; when null, assigned projects will be kept unchanged.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries/($glossaryId)")
  let body = {name: $name, baseLanguageTag: $baseLanguageTag, assignedProjectIds: $assignedProjectIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete glossary
#
# DELETE /v2/organizations/{organizationId}/glossaries/{glossaryId}
# operationId: delete_9
export def "organizations-glossaries delete-by-organizationId-glossaryId" [
  organizationId: int
  glossaryId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries/($glossaryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get glossary term
#
# GET /v2/organizations/{organizationId}/glossaries/{glossaryId}/terms/{termId}
# operationId: get_16
export def "organizations-glossaries-terms get-by-organizationId-glossaryId-termId" [
  organizationId: int
  glossaryId: int
  termId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries/($glossaryId)/terms/($termId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update glossary term
#
# PUT /v2/organizations/{organizationId}/glossaries/{glossaryId}/terms/{termId}
# operationId: update_11
export def "organizations-glossaries-terms update-by-organizationId-glossaryId-termId" [
  organizationId: int
  glossaryId: int
  termId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string
  --flagNonTranslatable: string@bool-completer # When true, this term will have the same translation across all target languages
  --flagCaseSensitive: string@bool-completer # When true, the term matching considers uppercase and lowercase characters as distinct
  --flagAbbreviation: string@bool-completer # Specifies whether the term represents a shortened form of a word or phrase
  --flagForbiddenTerm: string@bool-completer # When true, marks this term as prohibited or not recommended for use in translations
  --text: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries/($glossaryId)/terms/($termId)")
  let body = {description: $description, flagNonTranslatable: $flagNonTranslatable, flagCaseSensitive: $flagCaseSensitive, flagAbbreviation: $flagAbbreviation, flagForbiddenTerm: $flagForbiddenTerm, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete glossary term
#
# DELETE /v2/organizations/{organizationId}/glossaries/{glossaryId}/terms/{termId}
# operationId: delete_10
export def "organizations-glossaries-terms delete-by-organizationId-glossaryId-termId" [
  organizationId: int
  glossaryId: int
  termId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries/($glossaryId)/terms/($termId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update subscription
#
# PUT /v2/organizations/{organizationId}/billing/update-subscription
# operationId: updateSubscription
export def "organizations-billing-update-subscription updateSubscription" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/update-subscription")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refreshes EE subscriptions by Stripe data
#
# PUT /v2/organizations/{organizationId}/billing/self-hosted-ee/refresh-subscriptions
# operationId: refreshSelfHostedEeSubscriptions
export def "organizations-billing-self-hosted-ee-refresh-subscriptions refreshSelfHostedEeSubscriptions" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/self-hosted-ee/refresh-subscriptions")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restore previously cancelled subscription
#
# PUT /v2/organizations/{organizationId}/billing/restore-cancelled-subscription
# operationId: restoreSubscription
export def "organizations-billing-restore-cancelled-subscription restoreSubscription" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/restore-cancelled-subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organizations subscription by Stripe data
#
# PUT /v2/organizations/{organizationId}/billing/refresh-subscription
# operationId: refresh
export def "organizations-billing-refresh-subscription refresh" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/refresh-subscription")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Prepare update subscription session
#
# PUT /v2/organizations/{organizationId}/billing/prepare-update-subscription
# operationId: prepareUpdateSubscription
export def "organizations-billing-prepare-update-subscription prepareUpdateSubscription" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  planId: int # Id of the subscription plan (format: int64)
  period: string@period-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/prepare-update-subscription")
  let body = {planId: $planId, period: $period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel subscription
#
# PUT /v2/organizations/{organizationId}/billing/cancel-subscription
# operationId: cancelSubscription
export def "organizations-billing-cancel-subscription cancelSubscription" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/cancel-subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one organization
#
# GET /v2/organizations/{id}
# operationId: get_17
export def "organizations get-by-id" [
  id: int
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
  let full_url = (build-url $base $"/v2/organizations/($id)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update organization data
#
# PUT /v2/organizations/{id}
# operationId: update_12
export def "organizations update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # e.g. Beautiful organization
  --description: string # e.g. This is a beautiful organization full of beautiful and clever people
  --slug: string # e.g. btforg
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($id)")
  let body = {name: $name, description: $description, slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete organization
#
# DELETE /v2/organizations/{id}
# operationId: delete_11
export def "organizations delete-by-id" [
  id: int
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
  let full_url = (build-url $base $"/v2/organizations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Leave organization
#
# PUT /v2/organizations/{id}/leave
# operationId: leaveOrganization
export def "organizations-leave leaveOrganization" [
  id: int
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
  let full_url = (build-url $base $"/v2/organizations/($id)/leave")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate invitation link for organization
#
# PUT /v2/organizations/{id}/invite
# operationId: inviteUser_1
export def "organizations-invite inviteUser-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  roleType: string@roleType-completer
  --name: string # Name of invited user
  --email: string # Email to send invitation to
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($id)/invite")
  let body = {roleType: $roleType, name: $name, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload organizations avatar
#
# PUT /v2/organizations/{id}/avatar
# operationId: uploadAvatar_2
export def "organizations-avatar uploadAvatar-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  avatar: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($id)/avatar")
  let body = {avatar: $avatar} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete organization avatar
#
# DELETE /v2/organizations/{id}/avatar
# operationId: removeAvatar_2
export def "organizations-avatar removeAvatar-by-id" [
  id: int
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
  let full_url = (build-url $base $"/v2/organizations/($id)/avatar")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Marks notifications of the currently logged in user with given IDs as seen.
#
# PUT /v2/notifications-mark-seen
# operationId: markNotificationsAsSeen
export def "notifications-mark-seen markNotificationsAsSeen" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  notificationIds: list # Notification IDs to be marked as seen (e.g. [1, 2, 3])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/notifications-mark-seen")
  let body = {notificationIds: $notificationIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get notification settings
#
# GET /v2/notification-settings
# operationId: getNotificationsSettings
export def "notification-settings get" [
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
  let full_url = (build-url $base "/v2/notification-settings")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Save notification setting
#
# PUT /v2/notification-settings
# operationId: putNotificationSetting
export def "notification-settings put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  group: string@group-completer # e.g. TASKS
  channel: string@channel-completer # e.g. IN_APP
  --enabled: string@bool-completer # True if the setting should be enabled, false for disabled (e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/notification-settings")
  let body = {group: $group, channel: $channel, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Accepts invitation to project or organization (deprecated: use PUT method instead)
#
# GET /v2/invitations/{code}/accept
# DEPRECATED
# operationId: acceptInvitation
@deprecated
export def "invitations-accept acceptInvitation" [
  code: string
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
  let full_url = (build-url $base $"/v2/invitations/($code)/accept")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accepts invitation to project or organization
#
# PUT /v2/invitations/{code}/accept
# operationId: acceptInvitationPut
export def "invitations-accept acceptInvitationPut" [
  code: string
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
  let full_url = (build-url $base $"/v2/invitations/($code)/accept")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sets the EE licence key
#
# PUT /v2/ee-license/set-license-key
# operationId: setLicenseKey
export def "ee-license-set-license-key setLicenseKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  licenseKey: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/ee-license/set-license-key")
  let body = {licenseKey: $licenseKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove the EE licence key
#
# PUT /v2/ee-license/release-license-key
# operationId: release
export def "ee-license-release-license-key release" [
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
  let full_url = (build-url $base "/v2/ee-license/release-license-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refresh the EE subscription
#
# PUT /v2/ee-license/refresh
# operationId: refreshSubscription
export def "ee-license-refresh refreshSubscription" [
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
  let full_url = (build-url $base "/v2/ee-license/refresh")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update API key
#
# PUT /v2/api-keys/{apiKeyId}
# operationId: update_13
export def "api-keys update-by-apiKeyId" [
  apiKeyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scopes: list
  --description: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/api-keys/($apiKeyId)")
  let body = {scopes: $scopes, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete API key
#
# DELETE /v2/api-keys/{apiKeyId}
# operationId: delete_12
export def "api-keys delete-by-apiKeyId" [
  apiKeyId: int
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
  let full_url = (build-url $base $"/v2/api-keys/($apiKeyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Regenerates API key. It generates new API key value and updates its time of expiration.
#
# PUT /v2/api-keys/{apiKeyId}/regenerate
# operationId: regenerate_1
export def "api-keys-regenerate regenerate-by-apiKeyId" [
  apiKeyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expiresAt: int # Expiration date in epoch format (milliseconds). When null key never expires. (format: int64, e.g. 1661172869000)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/api-keys/($apiKeyId)/regenerate")
  let body = {expiresAt: $expiresAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable user
#
# PUT /v2/administration/users/{userId}/enable
# operationId: enableUser
export def "administration-users-enable enableUser" [
  userId: int
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
  let full_url = (build-url $base $"/v2/administration/users/($userId)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable user
#
# PUT /v2/administration/users/{userId}/disable
# operationId: disableUser
export def "administration-users-disable disableUser" [
  userId: int
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
  let full_url = (build-url $base $"/v2/administration/users/($userId)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Role
#
# PUT /v2/administration/users/{userId}/set-role/{role}
# operationId: setRole
export def "administration-users-set-role setRole" [
  userId: int
  role: string
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
  let full_url = (build-url $base $"/v2/administration/users/($userId)/set-role/($role)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Changes a trial end date
#
# PUT /v2/administration/organizations/{organizationId}/billing/update-trial-end-date
# operationId: updateTrialEndDate
export def "administration-organizations-billing-update-trial-end-date updateTrialEndDate" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  trialEnd: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/administration/organizations/($organizationId)/billing/update-trial-end-date")
  let body = {trialEnd: $trialEnd} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unassign a self-hosted plan
#
# PUT /v2/administration/organizations/{organizationId}/billing/unassign-self-hosted-plan/{planId}
# operationId: unassignSelfHostedPlan
export def "administration-organizations-billing-unassign-self-hosted-plan unassignSelfHostedPlan" [
  organizationId: int
  planId: int
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
  let full_url = (build-url $base $"/v2/administration/organizations/($organizationId)/billing/unassign-self-hosted-plan/($planId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unassign a plan
#
# PUT /v2/administration/organizations/{organizationId}/billing/unassign-cloud-plan/{planId}
# operationId: unassignCloudPlan
export def "administration-organizations-billing-unassign-cloud-plan unassignCloudPlan" [
  organizationId: int
  planId: int
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
  let full_url = (build-url $base $"/v2/administration/organizations/($organizationId)/billing/unassign-cloud-plan/($planId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign a plan
#
# PUT /v2/administration/organizations/{organizationId}/billing/assign-self-hosted-plan
# operationId: assignSelfHostedPlan
export def "administration-organizations-billing-assign-self-hosted-plan assignSelfHostedPlan" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  planId: int # Id of the subscription plan (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/administration/organizations/($organizationId)/billing/assign-self-hosted-plan")
  let body = {planId: $planId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign a plan
#
# PUT /v2/administration/organizations/{organizationId}/billing/assign-cloud-plan
# operationId: assignCloudPlan
# --customPlan shape: {name: string, free: bool, nonCommercial: bool, enabledFeatures: list, type: "PAY_AS_YOU_GO"|"FIXED", prices: record, includedUsage: record, public: bool, stripeProductId: string, notAvailableBefore?: string, availableUntil?: string, usableUntil?: string, forOrganizationIds: list, metricType: "KEYS_SEATS"|"STRINGS", archived?: bool, newStripeProduct: bool, stripeProductName?: string}
export def "administration-organizations-billing-assign-cloud-plan assignCloudPlan" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --trialEnd: int # format: int64
  --planId: int # format: int64
  --customPlan: record # shape: {name: string, free: bool, nonCommercial: bool, enabledFeatures: list, type: "PAY_AS_YOU_GO"|"FIXED", prices: record, includedUsage: record, public: bool, stripeProductId: string, notAvailableBefore?: string, availableUntil?: string, usableUntil?: string, forOrganizationIds: list, metricType: "KEYS_SEATS"|"STRINGS", archived?: bool, newStripeProduct: bool, stripeProductName?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/administration/organizations/($organizationId)/billing/assign-cloud-plan")
  let body = {trialEnd: $trialEnd, planId: $planId, customPlan: $customPlan} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get single translation agency
#
# GET /v2/administration/billing/translation-agency/{agencyId}
# operationId: get_18
export def "administration-billing-translation-agency get-by-agencyId" [
  agencyId: int
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
  let full_url = (build-url $base $"/v2/administration/billing/translation-agency/($agencyId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update translation agency
#
# PUT /v2/administration/billing/translation-agency/{agencyId}
# operationId: update_14
export def "administration-billing-translation-agency update-by-agencyId" [
  agencyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  description: string
  services: list
  --body-url: string
  email: string
  emailBcc: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/administration/billing/translation-agency/($agencyId)")
  let body = {name: $name, description: $description, services: $services, url: $body_url, email: $email, emailBcc: $emailBcc} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete translation agency
#
# DELETE /v2/administration/billing/translation-agency/{agencyId}
# operationId: delete_13
export def "administration-billing-translation-agency delete-by-agencyId" [
  agencyId: int
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
  let full_url = (build-url $base $"/v2/administration/billing/translation-agency/($agencyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload agency avatar
#
# PUT /v2/administration/billing/translation-agency/{agencyId}/avatar
# operationId: uploadAvatar_3
export def "administration-billing-translation-agency-avatar uploadAvatar-by-agencyId" [
  agencyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  avatar: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/administration/billing/translation-agency/($agencyId)/avatar")
  let body = {avatar: $avatar} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete agency avatar
#
# DELETE /v2/administration/billing/translation-agency/{agencyId}/avatar
# operationId: removeAvatar_3
export def "administration-billing-translation-agency-avatar removeAvatar-by-agencyId" [
  agencyId: int
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
  let full_url = (build-url $base $"/v2/administration/billing/translation-agency/($agencyId)/avatar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/administration/billing/self-hosted-ee-plans/{planId}
#
# operationId: getPlan
export def "administration-billing-self-hosted-ee-plans get" [
  planId: int
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
  let full_url = (build-url $base $"/v2/administration/billing/self-hosted-ee-plans/($planId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /v2/administration/billing/self-hosted-ee-plans/{planId}
#
# operationId: updatePlan
# --prices shape: {perSeat?: float, perThousandTranslations?: float, perThousandMtCredits?: float, subscriptionMonthly: float, subscriptionYearly: float, perThousandKeys?: float, _links?: record}
# --includedUsage shape: {seats: int, translations: int, mtCredits: int, keys: int, _links?: record}
export def "administration-billing-self-hosted-ee-plans updatePlan" [
  planId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  enabledFeatures: list
  prices: record # shape: {perSeat?: float, perThousandTranslations?: float, perThousandMtCredits?: float, subscriptionMonthly: float, subscriptionYearly: float, perThousandKeys?: float, _links?: record}
  includedUsage: record # shape: {seats: int, translations: int, mtCredits: int, keys: int, _links?: record}
  --public: string@bool-completer
  --stripeProductId: string
  --notAvailableBefore: string # format: date-time
  --availableUntil: string # format: date-time
  --usableUntil: string # format: date-time
  forOrganizationIds: list
  --free: string@bool-completer
  --nonCommercial: string@bool-completer
  --isPayAsYouGo: string@bool-completer
  --archived: string@bool-completer
  --newStripeProduct: string@bool-completer # If true, a new Stripe product will be created with name specified in [stripeProductName] and [stripeProductId] will be automatically populated with the ID of the newly created Stripe product.
  --stripeProductName: string
  --payAsYouGo: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/administration/billing/self-hosted-ee-plans/($planId)")
  let body = {name: $name, enabledFeatures: $enabledFeatures, prices: $prices, includedUsage: $includedUsage, public: $public, stripeProductId: $stripeProductId, notAvailableBefore: $notAvailableBefore, availableUntil: $availableUntil, usableUntil: $usableUntil, forOrganizationIds: $forOrganizationIds, free: $free, nonCommercial: $nonCommercial, isPayAsYouGo: $isPayAsYouGo, archived: $archived, newStripeProduct: $newStripeProduct, stripeProductName: $stripeProductName, payAsYouGo: $payAsYouGo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /v2/administration/billing/self-hosted-ee-plans/{planId}
#
# operationId: deletePlan
export def "administration-billing-self-hosted-ee-plans delete" [
  planId: int
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
  let full_url = (build-url $base $"/v2/administration/billing/self-hosted-ee-plans/($planId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /v2/administration/billing/self-hosted-ee-plans/{planId}/archive
#
# operationId: archivePlan
export def "administration-billing-self-hosted-ee-plans-archive archivePlan" [
  planId: int
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
  let full_url = (build-url $base $"/v2/administration/billing/self-hosted-ee-plans/($planId)/archive")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/administration/billing/self-hosted-ee-plans/migration/{migrationId}
#
# operationId: getPlanMigration
export def "administration-billing-self-hosted-ee-plans-migration get" [
  migrationId: int
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
  let full_url = (build-url $base $"/v2/administration/billing/self-hosted-ee-plans/migration/($migrationId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /v2/administration/billing/self-hosted-ee-plans/migration/{migrationId}
#
# operationId: updatePlanMigration
export def "administration-billing-self-hosted-ee-plans-migration updatePlanMigration" [
  migrationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer
  targetPlanId: int # format: int64
  monthlyOffsetDays: int # format: int32
  yearlyOffsetDays: int # format: int32
  --customEmailBody: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/administration/billing/self-hosted-ee-plans/migration/($migrationId)")
  let body = {enabled: $enabled, targetPlanId: $targetPlanId, monthlyOffsetDays: $monthlyOffsetDays, yearlyOffsetDays: $yearlyOffsetDays, customEmailBody: $customEmailBody} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /v2/administration/billing/self-hosted-ee-plans/migration/{migrationId}
#
# operationId: deletePlanMigration
export def "administration-billing-self-hosted-ee-plans-migration delete" [
  migrationId: int
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
  let full_url = (build-url $base $"/v2/administration/billing/self-hosted-ee-plans/migration/($migrationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /v2/administration/billing/self-hosted-ee-plans/migration/{migrationId}/upcoming-subscriptions/{subscriptionId}/skip
#
# operationId: setUpcomingSubscriptionSkipped
export def "administration-billing-self-hosted-ee-plans-migration-upcoming-subscriptions-skip setUpcomingSubscriptionSkipped" [
  migrationId: int
  subscriptionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --skipped: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/administration/billing/self-hosted-ee-plans/migration/($migrationId)/upcoming-subscriptions/($subscriptionId)/skip")
  let body = {skipped: $skipped} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /v2/administration/billing/cloud-plans/{planId}
#
# operationId: getPlan_1
export def "administration-billing-cloud-plans get-by-planId" [
  planId: int
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
  let full_url = (build-url $base $"/v2/administration/billing/cloud-plans/($planId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /v2/administration/billing/cloud-plans/{planId}
#
# operationId: updatePlan_1
# --prices shape: {perSeat?: float, perThousandTranslations?: float, perThousandMtCredits?: float, subscriptionMonthly: float, subscriptionYearly: float, perThousandKeys?: float, _links?: record}
# --includedUsage shape: {seats: int, translations: int, mtCredits: int, keys: int, _links?: record}
export def "administration-billing-cloud-plans updatePlan-by-planId" [
  planId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --free: string@bool-completer
  --nonCommercial: string@bool-completer
  enabledFeatures: list
  type: string@type-completer-2
  prices: record # shape: {perSeat?: float, perThousandTranslations?: float, perThousandMtCredits?: float, subscriptionMonthly: float, subscriptionYearly: float, perThousandKeys?: float, _links?: record}
  includedUsage: record # shape: {seats: int, translations: int, mtCredits: int, keys: int, _links?: record}
  --public: string@bool-completer
  stripeProductId: string
  --notAvailableBefore: string # format: date-time
  --availableUntil: string # format: date-time
  --usableUntil: string # format: date-time
  forOrganizationIds: list
  metricType: string@metricType-completer
  --archived: string@bool-completer
  --newStripeProduct: string@bool-completer # If true, a new Stripe product will be created with name specified in [stripeProductName] and [stripeProductId] will be automatically populated with the ID of the newly created Stripe product.
  --stripeProductName: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/administration/billing/cloud-plans/($planId)")
  let body = {name: $name, free: $free, nonCommercial: $nonCommercial, enabledFeatures: $enabledFeatures, type: $type, prices: $prices, includedUsage: $includedUsage, public: $public, stripeProductId: $stripeProductId, notAvailableBefore: $notAvailableBefore, availableUntil: $availableUntil, usableUntil: $usableUntil, forOrganizationIds: $forOrganizationIds, metricType: $metricType, archived: $archived, newStripeProduct: $newStripeProduct, stripeProductName: $stripeProductName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /v2/administration/billing/cloud-plans/{planId}
#
# operationId: deletePlan_1
export def "administration-billing-cloud-plans delete-by-planId" [
  planId: int
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
  let full_url = (build-url $base $"/v2/administration/billing/cloud-plans/($planId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /v2/administration/billing/cloud-plans/{planId}/archive
#
# operationId: archivePlan_1
export def "administration-billing-cloud-plans-archive archivePlan-by-planId" [
  planId: int
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
  let full_url = (build-url $base $"/v2/administration/billing/cloud-plans/($planId)/archive")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/administration/billing/cloud-plans/migration/{migrationId}
#
# operationId: getPlanMigration_1
export def "administration-billing-cloud-plans-migration get-by-migrationId" [
  migrationId: int
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
  let full_url = (build-url $base $"/v2/administration/billing/cloud-plans/migration/($migrationId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /v2/administration/billing/cloud-plans/migration/{migrationId}
#
# operationId: updatePlanMigration_1
export def "administration-billing-cloud-plans-migration updatePlanMigration-by-migrationId" [
  migrationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer
  targetPlanId: int # format: int64
  monthlyOffsetDays: int # format: int32
  yearlyOffsetDays: int # format: int32
  --customEmailBody: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/administration/billing/cloud-plans/migration/($migrationId)")
  let body = {enabled: $enabled, targetPlanId: $targetPlanId, monthlyOffsetDays: $monthlyOffsetDays, yearlyOffsetDays: $yearlyOffsetDays, customEmailBody: $customEmailBody} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /v2/administration/billing/cloud-plans/migration/{migrationId}
#
# operationId: deletePlanMigration_1
export def "administration-billing-cloud-plans-migration delete-by-migrationId" [
  migrationId: int
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
  let full_url = (build-url $base $"/v2/administration/billing/cloud-plans/migration/($migrationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /v2/administration/billing/cloud-plans/migration/{migrationId}/upcoming-subscriptions/{subscriptionId}/skip
#
# operationId: setUpcomingSubscriptionSkipped_1
export def "administration-billing-cloud-plans-migration-upcoming-subscriptions-skip setUpcomingSubscriptionSkipped-by-migrationId-subscriptionId" [
  migrationId: int
  subscriptionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --skipped: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/administration/billing/cloud-plans/migration/($migrationId)/upcoming-subscriptions/($subscriptionId)/skip")
  let body = {skipped: $skipped} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a self-hosted subscription if its plan is free
#
# PUT /v2/administration/billing/cancel-self-hosted-subscription/{subscriptionId}
# operationId: cancelSelfHostedSubscription
export def "administration-billing-cancel-self-hosted-subscription cancelSelfHostedSubscription" [
  subscriptionId: int
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
  let full_url = (build-url $base $"/v2/administration/billing/cancel-self-hosted-subscription/($subscriptionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel local subscriptions
#
# PUT /v2/administration/billing/cancel-local-subscriptions
# operationId: cancelLocalSubscriptions
# --ids item shape: {id: int, type: "CLOUD"|"SELF_HOSTED"}
export def "administration-billing-cancel-local-subscriptions cancelLocalSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ids: list # item shape: {id: int, type: "CLOUD"|"SELF_HOSTED"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/administration/billing/cancel-local-subscriptions")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /v2/administration/billing/add-usage-items-to-invoice-and-finalize-it/{invoiceId}
#
# operationId: addUsageItemsToInvoiceAndFinalizeIt
export def "administration-billing-add-usage-items-to-invoice-and-finalize-it addUsageItemsToInvoiceAndFinalizeIt" [
  invoiceId: string
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
  let full_url = (build-url $base $"/v2/administration/billing/add-usage-items-to-invoice-and-finalize-it/($invoiceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resend email verification
#
# POST /v2/user/send-email-verification
# operationId: sendEmailVerification
export def "user-send-email-verification sendEmailVerification" [
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
  let full_url = (build-url $base "/v2/user/send-email-verification")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get super JWT
#
# POST /v2/user/generate-super-token
# operationId: getSuperToken
export def "user-generate-super-token post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --otp: string # Has to be provided when TOTP enabled
  --password: string # Has to be provided when TOTP not enabled
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/generate-super-token")
  let body = {otp: $otp, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate project slug
#
# POST /v2/slug/generate-project
# operationId: generateProjectSlug
export def "slug-generate-project generateProjectSlug" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --oldSlug: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/slug/generate-project")
  let body = {name: $name, oldSlug: $oldSlug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate organization slug
#
# POST /v2/slug/generate-organization
# operationId: generateOrganizationSlug
export def "slug-generate-organization generateOrganizationSlug" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --oldSlug: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/slug/generate-organization")
  let body = {name: $name, oldSlug: $oldSlug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# User login
#
# POST /v2/slack/user-login
# operationId: userLogin
export def "slack-user-login userLogin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: string # The encrypted data about the desired connection between Slack account and Tolgee account
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data" $data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/slack/user-login" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v2/public/translator/translate
#
# operationId: translate
# --metadata shape: {examples: list, closeItems: list, keyDescription?: string, projectDescription?: string, languageDescription?: string}
export def "public-translator-translate translate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  text: string
  --keyName: string
  sourceTag: string
  targetTag: string
  --metadata: record # shape: {examples: list, closeItems: list, keyDescription?: string, projectDescription?: string, languageDescription?: string}
  --formality: string@formality-completer
  --isBatch: string@bool-completer
  --pluralForms: record
  --pluralFormExamples: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/translator/translate")
  let body = {text: $text, keyName: $keyName, sourceTag: $sourceTag, targetTag: $targetTag, metadata: $metadata, formality: $formality, isBatch: $isBatch, pluralForms: $pluralForms, pluralFormExamples: $pluralFormExamples} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /v2/public/telemetry/report
#
# operationId: report
export def "public-telemetry-report report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  instanceId: string
  projectsCount: int # format: int64
  translationsCount: int # format: int64
  languagesCount: int # format: int64
  distinctLanguagesCount: int # format: int64
  usersCount: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/telemetry/report")
  let body = {instanceId: $instanceId, projectsCount: $projectsCount, translationsCount: $translationsCount, languagesCount: $languagesCount, distinctLanguagesCount: $distinctLanguagesCount, usersCount: $usersCount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /v2/public/slack
#
# operationId: slackCommand
export def "public-slack slackCommand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --payload: string
  --X-Slack-Signature: string
  --X-Slack-Request-Timestamp: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payload" $payload "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/public/slack" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Slack-Signature": $X_Slack_Signature, "X-Slack-Request-Timestamp": $X_Slack_Request_Timestamp} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# On interactivity event
#
# POST /v2/public/slack/on-event
# operationId: onInteractivityEvent
export def "public-slack-on-event onInteractivityEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Slack-Signature: string
  --X-Slack-Request-Timestamp: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/slack/on-event")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Slack-Signature": $X_Slack_Signature, "X-Slack-Request-Timestamp": $X_Slack_Request_Timestamp} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# On bot event
#
# POST /v2/public/slack/on-bot-event
# operationId: fetchBotEvent
export def "public-slack-on-bot-event fetchBotEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Slack-Signature: string
  --X-Slack-Request-Timestamp: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/slack/on-bot-event")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Slack-Signature": $X_Slack_Signature, "X-Slack-Request-Timestamp": $X_Slack_Request_Timestamp} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /v2/public/llm/prompt
#
# operationId: prompt
# --messages item shape: {type: "TEXT"|"IMAGE", text?: string, image?: string}
export def "public-llm-prompt prompt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  messages: list # item shape: {type: "TEXT"|"IMAGE", text?: string, image?: string}
  --shouldOutputJson: string@bool-completer
  priority: string@priority-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/llm/prompt")
  let body = {messages: $messages, shouldOutputJson: $shouldOutputJson, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /v2/public/licensing/subscription
#
# operationId: getMySubscription
export def "public-licensing-subscription post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  licenseKey: string
  instanceId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/licensing/subscription")
  let body = {licenseKey: $licenseKey, instanceId: $instanceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Triggered when user sets licence key on their instance
#
# POST /v2/public/licensing/set-key
# operationId: onLicenceSetKey
export def "public-licensing-set-key onLicenceSetKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  licenseKey: string
  seats: int # format: int64
  --keys: int # Number of keys in the project. If not provided, the number of keys will not be updated. (format: int64)
  instanceId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/licensing/set-key")
  let body = {licenseKey: $licenseKey, seats: $seats, keys: $keys, instanceId: $instanceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /v2/public/licensing/report-usage
#
# operationId: reportUsage
export def "public-licensing-report-usage reportUsage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  licenseKey: string
  --keys: int # Number of keys in the project. If not provided, the number of keys will not be updated. (format: int64)
  --seats: int # Number of languages in the project. If not provided, the number of languages will not be updated. (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/licensing/report-usage")
  let body = {licenseKey: $licenseKey, keys: $keys, seats: $seats} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /v2/public/licensing/report-error
#
# operationId: reportError
export def "public-licensing-report-error reportError" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  stackTrace: string
  licenseKey: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/licensing/report-error")
  let body = {stackTrace: $stackTrace, licenseKey: $licenseKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /v2/public/licensing/release-key
#
# operationId: releaseKey
export def "public-licensing-release-key releaseKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  licenseKey: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/licensing/release-key")
  let body = {licenseKey: $licenseKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /v2/public/licensing/prepare-set-key
#
# operationId: prepareSetLicenseKey
export def "public-licensing-prepare-set-key prepareSetLicenseKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  licenseKey: string
  seats: int # format: int64
  keys: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/licensing/prepare-set-key")
  let body = {licenseKey: $licenseKey, seats: $seats, keys: $keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /v2/public/licensing/current-subscription-usage
#
# operationId: getSubscriptionUsage
export def "public-licensing-current-subscription-usage post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  licenseKey: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/licensing/current-subscription-usage")
  let body = {licenseKey: $licenseKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reports business event
#
# POST /v2/public/business-events/report
# operationId: report_1
export def "public-business-events-report report-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  eventName: string
  --anonymousUserId: string
  --organizationId: int # format: int64
  --projectId: int # format: int64
  --data: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/business-events/report")
  let body = {eventName: $eventName, anonymousUserId: $anonymousUserId, organizationId: $organizationId, projectId: $projectId, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Identifies user
#
# POST /v2/public/business-events/identify
# operationId: identify
export def "public-business-events-identify identify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  anonymousUserId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/business-events/identify")
  let body = {anonymousUserId: $anonymousUserId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /v2/public/billing/webhook
#
# operationId: webhook
export def "public-billing-webhook webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Stripe-Signature: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/billing/webhook")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Stripe-Signature": $Stripe_Signature} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all permitted
#
# GET /v2/projects
# operationId: getAll
export def "projects get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterId: list # Filter projects by id
  --filterNotId: list # Filter projects without id
  --filterBaseLanguageTag: string # Filter projects whose base language tag matches
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [name,ASC])
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterId" $filterId "multi") (serialize-qp "filterNotId" $filterNotId "multi") (serialize-qp "filterBaseLanguageTag" $filterBaseLanguageTag "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create project
#
# POST /v2/projects
# operationId: createProject
# --languages item shape: {name: string, originalName: string, tag: string, flagEmoji?: string}
export def "projects createProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  languages: list # item shape: {name: string, originalName: string, tag: string, flagEmoji?: string}
  --slug: string # Slug of your project used in url e.g. "/v2/projects/what-a-project". If not provided, it will be generated
  organizationId: int # Organization to create the project in (format: int64)
  --baseLanguageTag: string # Tag of one of created languages, to select it as base language. If not provided, first language will be selected as base.
  --icuPlaceholders: string@bool-completer # Whether to use ICU placeholder visualization in the editor and it's support.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects")
  let body = {name: $name, languages: $languages, slug: $slug, organizationId: $organizationId, baseLanguageTag: $baseLanguageTag, icuPlaceholders: $icuPlaceholders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run prompt
#
# POST /v2/projects/{projectId}/prompts/run
# operationId: run
export def "projects-prompts-run run" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --template: string
  keyId: int # format: int64
  targetLanguageId: int # format: int64
  provider: string
  --basicPromptOptions: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/prompts/run")
  let body = {template: $template, keyId: $keyId, targetLanguageId: $targetLanguageId, provider: $provider, basicPromptOptions: $basicPromptOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run prompt
#
# POST /v2/projects/prompts/run
# operationId: run_1
export def "projects-prompts-run run-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --template: string
  keyId: int # format: int64
  targetLanguageId: int # format: int64
  provider: string
  --basicPromptOptions: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/prompts/run")
  let body = {template: $template, keyId: $keyId, targetLanguageId: $targetLanguageId, provider: $provider, basicPromptOptions: $basicPromptOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all prompts
#
# GET /v2/projects/{projectId}/prompts
# operationId: getAllPaged
export def "projects-prompts list" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/prompts" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create prompt
#
# POST /v2/projects/{projectId}/prompts
# operationId: createPrompt
export def "projects-prompts createPrompt" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  providerName: string
  --template: string
  --basicPromptOptions: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/prompts")
  let body = {name: $name, providerName: $providerName, template: $template, basicPromptOptions: $basicPromptOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all prompts
#
# GET /v2/projects/prompts
# operationId: getAllPaged_1
export def "projects-prompts get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/prompts" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create prompt
#
# POST /v2/projects/prompts
# operationId: createPrompt_1
export def "projects-prompts createPrompt-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  providerName: string
  --template: string
  --basicPromptOptions: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/prompts")
  let body = {name: $name, providerName: $providerName, template: $template, basicPromptOptions: $basicPromptOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create multiple tasks with assigned to an agency
#
# POST /v2/projects/{projectId}/billing/order-translation
# operationId: createTranslationOrder
# --tasks item shape: {name?: string, description: string, type: "TRANSLATE"|"REVIEW", dueDate?: int, languageId: int, assignees: list, keys: list, branch?: string}
export def "projects-billing-order-translation createTranslationOrder" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterState: list
  --filterOutdated: string@bool-completer
  agencyId: int # format: int64
  tasks: list # item shape: {name?: string, description: string, type: "TRANSLATE"|"REVIEW", dueDate?: int, languageId: int, assignees: list, keys: list, branch?: string}
  --sendReadOnlyInvitation: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterState" $filterState "multi") (serialize-qp "filterOutdated" $filterOutdated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/billing/order-translation" $qp)
  let body = {agencyId: $agencyId, tasks: $tasks, sendReadOnlyInvitation: $sendReadOnlyInvitation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create multiple tasks with assigned to an agency
#
# POST /v2/projects/billing/order-translation
# operationId: createTranslationOrder_1
# --tasks item shape: {name?: string, description: string, type: "TRANSLATE"|"REVIEW", dueDate?: int, languageId: int, assignees: list, keys: list, branch?: string}
export def "projects-billing-order-translation createTranslationOrder-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterState: list
  --filterOutdated: string@bool-completer
  agencyId: int # format: int64
  tasks: list # item shape: {name?: string, description: string, type: "TRANSLATE"|"REVIEW", dueDate?: int, languageId: int, assignees: list, keys: list, branch?: string}
  --sendReadOnlyInvitation: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterState" $filterState "multi") (serialize-qp "filterOutdated" $filterOutdated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/billing/order-translation" $qp)
  let body = {agencyId: $agencyId, tasks: $tasks, sendReadOnlyInvitation: $sendReadOnlyInvitation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get ai playground result
#
# POST /v2/projects/{projectId}/ai-playground-result
# operationId: getAiPlaygroundResult
export def "projects-ai-playground-result post" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keys: list
  languages: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/ai-playground-result")
  let body = {keys: $keys, languages: $languages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get ai playground result
#
# POST /v2/projects/ai-playground-result
# operationId: getAiPlaygroundResult_1
export def "projects-ai-playground-result post-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keys: list
  languages: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/ai-playground-result")
  let body = {keys: $keys, languages: $languages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove tags
#
# POST /v2/projects/{projectId}/start-batch-job/untag-keys
# operationId: untagKeys
export def "projects-start-batch-job-untag-keys untagKeys" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  tags: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/start-batch-job/untag-keys")
  let body = {keyIds: $keyIds, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove tags
#
# POST /v2/projects/start-batch-job/untag-keys
# operationId: untagKeys_1
export def "projects-start-batch-job-untag-keys untagKeys-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  tags: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/start-batch-job/untag-keys")
  let body = {keyIds: $keyIds, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unassign labels from translations
#
# POST /v2/projects/{projectId}/start-batch-job/unassign-translation-label
# operationId: unassignTranslationLabel
export def "projects-start-batch-job-unassign-translation-label unassignTranslationLabel" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  languageIds: list
  labelIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/start-batch-job/unassign-translation-label")
  let body = {keyIds: $keyIds, languageIds: $languageIds, labelIds: $labelIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unassign labels from translations
#
# POST /v2/projects/start-batch-job/unassign-translation-label
# operationId: unassignTranslationLabel_1
export def "projects-start-batch-job-unassign-translation-label unassignTranslationLabel-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  languageIds: list
  labelIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/start-batch-job/unassign-translation-label")
  let body = {keyIds: $keyIds, languageIds: $languageIds, labelIds: $labelIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add tags
#
# POST /v2/projects/{projectId}/start-batch-job/tag-keys
# operationId: tagKeys
export def "projects-start-batch-job-tag-keys tagKeys" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  tags: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/start-batch-job/tag-keys")
  let body = {keyIds: $keyIds, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add tags
#
# POST /v2/projects/start-batch-job/tag-keys
# operationId: tagKeys_1
export def "projects-start-batch-job-tag-keys tagKeys-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  tags: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/start-batch-job/tag-keys")
  let body = {keyIds: $keyIds, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set translation state
#
# POST /v2/projects/{projectId}/start-batch-job/set-translation-state
# operationId: setTranslationState_2
export def "projects-start-batch-job-set-translation-state setTranslationState-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  languageIds: list
  state: string@state-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/start-batch-job/set-translation-state")
  let body = {keyIds: $keyIds, languageIds: $languageIds, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set translation state
#
# POST /v2/projects/start-batch-job/set-translation-state
# operationId: setTranslationState_3
export def "projects-start-batch-job-set-translation-state setTranslationState-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  languageIds: list
  state: string@state-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/start-batch-job/set-translation-state")
  let body = {keyIds: $keyIds, languageIds: $languageIds, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set keys namespace
#
# POST /v2/projects/{projectId}/start-batch-job/set-keys-namespace
# operationId: setKeysNamespace
export def "projects-start-batch-job-set-keys-namespace setKeysNamespace" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  --namespace: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/start-batch-job/set-keys-namespace")
  let body = {keyIds: $keyIds, namespace: $namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set keys namespace
#
# POST /v2/projects/start-batch-job/set-keys-namespace
# operationId: setKeysNamespace_1
export def "projects-start-batch-job-set-keys-namespace setKeysNamespace-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  --namespace: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/start-batch-job/set-keys-namespace")
  let body = {keyIds: $keyIds, namespace: $namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Restore soft-deleted keys
#
# POST /v2/projects/{projectId}/start-batch-job/restore-keys
# operationId: restoreKeys
export def "projects-start-batch-job-restore-keys restoreKeys" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/start-batch-job/restore-keys")
  let body = {keyIds: $keyIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Restore soft-deleted keys
#
# POST /v2/projects/start-batch-job/restore-keys
# operationId: restoreKeys_1
export def "projects-start-batch-job-restore-keys restoreKeys-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/start-batch-job/restore-keys")
  let body = {keyIds: $keyIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rerun QA checks for translations of selected keys
#
# POST /v2/projects/{projectId}/start-batch-job/qa-check
# operationId: qaCheck
export def "projects-start-batch-job-qa-check qaCheck" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  --languageIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/start-batch-job/qa-check")
  let body = {keyIds: $keyIds, languageIds: $languageIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rerun QA checks for translations of selected keys
#
# POST /v2/projects/start-batch-job/qa-check
# operationId: qaCheck_1
export def "projects-start-batch-job-qa-check qaCheck-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  --languageIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/start-batch-job/qa-check")
  let body = {keyIds: $keyIds, languageIds: $languageIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Translate from memory
#
# POST /v2/projects/{projectId}/start-batch-job/pre-translate-by-tm
# operationId: translate_1
export def "projects-start-batch-job-pre-translate-by-tm translate-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  targetLanguageIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/start-batch-job/pre-translate-by-tm")
  let body = {keyIds: $keyIds, targetLanguageIds: $targetLanguageIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Translate from memory
#
# POST /v2/projects/start-batch-job/pre-translate-by-tm
# operationId: translate_2
export def "projects-start-batch-job-pre-translate-by-tm translate-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  targetLanguageIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/start-batch-job/pre-translate-by-tm")
  let body = {keyIds: $keyIds, targetLanguageIds: $targetLanguageIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Machine Translation
#
# POST /v2/projects/{projectId}/start-batch-job/machine-translate
# operationId: machineTranslation
# --llmPrompt shape: {name: string, providerName: string, template?: string, basicPromptOptions?: list}
export def "projects-start-batch-job-machine-translate machineTranslation" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  targetLanguageIds: list
  --llmPrompt: record # shape: {name: string, providerName: string, template?: string, basicPromptOptions?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/start-batch-job/machine-translate")
  let body = {keyIds: $keyIds, targetLanguageIds: $targetLanguageIds, llmPrompt: $llmPrompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Machine Translation
#
# POST /v2/projects/start-batch-job/machine-translate
# operationId: machineTranslation_1
# --llmPrompt shape: {name: string, providerName: string, template?: string, basicPromptOptions?: list}
export def "projects-start-batch-job-machine-translate machineTranslation-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  targetLanguageIds: list
  --llmPrompt: record # shape: {name: string, providerName: string, template?: string, basicPromptOptions?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/start-batch-job/machine-translate")
  let body = {keyIds: $keyIds, targetLanguageIds: $targetLanguageIds, llmPrompt: $llmPrompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Permanently delete soft-deleted keys
#
# POST /v2/projects/{projectId}/start-batch-job/hard-delete-keys
# operationId: hardDeleteKeys
export def "projects-start-batch-job-hard-delete-keys hardDeleteKeys" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/start-batch-job/hard-delete-keys")
  let body = {keyIds: $keyIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Permanently delete soft-deleted keys
#
# POST /v2/projects/start-batch-job/hard-delete-keys
# operationId: hardDeleteKeys_1
export def "projects-start-batch-job-hard-delete-keys hardDeleteKeys-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/start-batch-job/hard-delete-keys")
  let body = {keyIds: $keyIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete keys
#
# POST /v2/projects/{projectId}/start-batch-job/delete-keys
# operationId: deleteKeys
export def "projects-start-batch-job-delete-keys post" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/start-batch-job/delete-keys")
  let body = {keyIds: $keyIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete keys
#
# POST /v2/projects/start-batch-job/delete-keys
# operationId: deleteKeys_1
export def "projects-start-batch-job-delete-keys post-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/start-batch-job/delete-keys")
  let body = {keyIds: $keyIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Copy translation values
#
# POST /v2/projects/{projectId}/start-batch-job/copy-translations
# operationId: copyTranslations
export def "projects-start-batch-job-copy-translations copyTranslations" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  sourceLanguageId: int # format: int64
  targetLanguageIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/start-batch-job/copy-translations")
  let body = {keyIds: $keyIds, sourceLanguageId: $sourceLanguageId, targetLanguageIds: $targetLanguageIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Copy translation values
#
# POST /v2/projects/start-batch-job/copy-translations
# operationId: copyTranslations_1
export def "projects-start-batch-job-copy-translations copyTranslations-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  sourceLanguageId: int # format: int64
  targetLanguageIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/start-batch-job/copy-translations")
  let body = {keyIds: $keyIds, sourceLanguageId: $sourceLanguageId, targetLanguageIds: $targetLanguageIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clear translation values
#
# POST /v2/projects/{projectId}/start-batch-job/clear-translations
# operationId: clearTranslations
export def "projects-start-batch-job-clear-translations clearTranslations" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  languageIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/start-batch-job/clear-translations")
  let body = {keyIds: $keyIds, languageIds: $languageIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clear translation values
#
# POST /v2/projects/start-batch-job/clear-translations
# operationId: clearTranslations_1
export def "projects-start-batch-job-clear-translations clearTranslations-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  languageIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/start-batch-job/clear-translations")
  let body = {keyIds: $keyIds, languageIds: $languageIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign labels to translations
#
# POST /v2/projects/{projectId}/start-batch-job/assign-translation-label
# operationId: assignTranslationLabel
export def "projects-start-batch-job-assign-translation-label assignTranslationLabel" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  languageIds: list
  labelIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/start-batch-job/assign-translation-label")
  let body = {keyIds: $keyIds, languageIds: $languageIds, labelIds: $labelIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign labels to translations
#
# POST /v2/projects/start-batch-job/assign-translation-label
# operationId: assignTranslationLabel_1
export def "projects-start-batch-job-assign-translation-label assignTranslationLabel-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  languageIds: list
  labelIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/start-batch-job/assign-translation-label")
  let body = {keyIds: $keyIds, languageIds: $languageIds, labelIds: $labelIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Translates via llm and stores result in AiPlaygroundResult
#
# POST /v2/projects/{projectId}/start-batch-job/ai-playground-translate
# operationId: aiPlaygroundTranslate
# --llmPrompt shape: {name: string, providerName: string, template?: string, basicPromptOptions?: list}
export def "projects-start-batch-job-ai-playground-translate aiPlaygroundTranslate" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  targetLanguageIds: list
  --llmPrompt: record # shape: {name: string, providerName: string, template?: string, basicPromptOptions?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/start-batch-job/ai-playground-translate")
  let body = {keyIds: $keyIds, targetLanguageIds: $targetLanguageIds, llmPrompt: $llmPrompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Translates via llm and stores result in AiPlaygroundResult
#
# POST /v2/projects/start-batch-job/ai-playground-translate
# operationId: aiPlaygroundTranslate_1
# --llmPrompt shape: {name: string, providerName: string, template?: string, basicPromptOptions?: list}
export def "projects-start-batch-job-ai-playground-translate aiPlaygroundTranslate-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyIds: list
  targetLanguageIds: list
  --llmPrompt: record # shape: {name: string, providerName: string, template?: string, basicPromptOptions?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/start-batch-job/ai-playground-translate")
  let body = {keyIds: $keyIds, targetLanguageIds: $targetLanguageIds, llmPrompt: $llmPrompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Single step import from body
#
# POST /v2/projects/{projectId}/single-step-import-resolvable
# operationId: singleStepResolvableImport
# --keys item shape: {name: string, namespace?: string, screenshots?: list, translations: record}
export def "projects-single-step-import-resolvable singleStepResolvableImport" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --overrideMode: string@overrideMode-completer # Some translations are forbidden or protected:  When set to `RECOMMENDED` it will fail for DISABLED translations and protected REVIEWED translations. When set to `ALL` it will fail for DISABLED translations, but will try to update protected REVIEWED translations (fails only if user has no permission)
  --errorOnUnresolvedConflict: string@bool-completer # If `false`, import will apply all `non-failed` overrides and reports `unresolvedConflict` .If `true`, import will fail completely on unresolved conflict and won't apply any changes. Unresolved conflicts are reported in the `params` of the error response
  --branch: string # Branch to import keys into. If not specified, default branch is used.
  keys: list # List of keys to import — item shape: {name: string, namespace?: string, screenshots?: list, translations: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/single-step-import-resolvable")
  let body = {overrideMode: $overrideMode, errorOnUnresolvedConflict: $errorOnUnresolvedConflict, branch: $branch, keys: $keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Single step import from body
#
# POST /v2/projects/single-step-import-resolvable
# operationId: singleStepResolvableImport_1
# --keys item shape: {name: string, namespace?: string, screenshots?: list, translations: record}
export def "projects-single-step-import-resolvable singleStepResolvableImport-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --overrideMode: string@overrideMode-completer # Some translations are forbidden or protected:  When set to `RECOMMENDED` it will fail for DISABLED translations and protected REVIEWED translations. When set to `ALL` it will fail for DISABLED translations, but will try to update protected REVIEWED translations (fails only if user has no permission)
  --errorOnUnresolvedConflict: string@bool-completer # If `false`, import will apply all `non-failed` overrides and reports `unresolvedConflict` .If `true`, import will fail completely on unresolved conflict and won't apply any changes. Unresolved conflicts are reported in the `params` of the error response
  --branch: string # Branch to import keys into. If not specified, default branch is used.
  keys: list # List of keys to import — item shape: {name: string, namespace?: string, screenshots?: list, translations: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/single-step-import-resolvable")
  let body = {overrideMode: $overrideMode, errorOnUnresolvedConflict: $errorOnUnresolvedConflict, branch: $branch, keys: $keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Single step import
#
# POST /v2/projects/{projectId}/single-step-import
# operationId: singleStepFromFiles
# --params shape: {structureDelimiter?: string, branch?: string, forceMode: "OVERRIDE"|"KEEP"|"NO_FORCE", overrideMode?: "RECOMMENDED"|"ALL", errorOnUnresolvedConflict?: bool, languageMappings?: list, overrideKeyDescriptions: bool, convertPlaceholdersToIcu: bool, createNewKeys: bool, fileMappings: list, tagNewKeys: list, removeOtherKeys?: bool}
export def "projects-single-step-import singleStepFromFiles" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  files: list
  params: record # shape: {structureDelimiter?: string, branch?: string, forceMode: "OVERRIDE"|"KEEP"|"NO_FORCE", overrideMode?: "RECOMMENDED"|"ALL", errorOnUnresolvedConflict?: bool, languageMappings?: list, overrideKeyDescriptions: bool, convertPlaceholdersToIcu: bool, createNewKeys: bool, fileMappings: list, tagNewKeys: list, removeOtherKeys?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/single-step-import")
  let body = {files: $files, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Single step import
#
# POST /v2/projects/single-step-import
# operationId: singleStepFromFiles_1
# --params shape: {structureDelimiter?: string, branch?: string, forceMode: "OVERRIDE"|"KEEP"|"NO_FORCE", overrideMode?: "RECOMMENDED"|"ALL", errorOnUnresolvedConflict?: bool, languageMappings?: list, overrideKeyDescriptions: bool, convertPlaceholdersToIcu: bool, createNewKeys: bool, fileMappings: list, tagNewKeys: list, removeOtherKeys?: bool}
export def "projects-single-step-import singleStepFromFiles-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  files: list
  params: record # shape: {structureDelimiter?: string, branch?: string, forceMode: "OVERRIDE"|"KEEP"|"NO_FORCE", overrideMode?: "RECOMMENDED"|"ALL", errorOnUnresolvedConflict?: bool, languageMappings?: list, overrideKeyDescriptions: bool, convertPlaceholdersToIcu: bool, createNewKeys: bool, fileMappings: list, tagNewKeys: list, removeOtherKeys?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/single-step-import")
  let body = {files: $files, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get available project labels
#
# GET /v2/projects/{projectId}/labels
# operationId: getAll_1
export def "projects-labels get-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [name,ASC])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/labels" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create label
#
# POST /v2/projects/{projectId}/labels
# operationId: createLabel
export def "projects-labels createLabel" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
  color: string # Hex color in format #RRGGBB. (e.g. #FF5733)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/labels")
  let body = {name: $name, description: $description, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get available project labels
#
# GET /v2/projects/labels
# operationId: getAll_2
export def "projects-labels get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [name,ASC])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/labels" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create label
#
# POST /v2/projects/labels
# operationId: createLabel_1
export def "projects-labels createLabel-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
  color: string # Hex color in format #RRGGBB. (e.g. #FF5733)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/labels")
  let body = {name: $name, description: $description, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add files
#
# POST /v2/projects/{projectId}/import
# operationId: addFiles
export def "projects-import addFiles" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --structureDelimiter: string # When importing files in structured formats (e.g., JSON, YAML), this field defines the delimiter which will be used in names of imported keys. (e.g. .)
  --branch: string # Branch to which files will be imported (e.g. main)
  files: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "structureDelimiter" $structureDelimiter "scalar") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/import" $qp)
  let body = {files: $files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete
#
# DELETE /v2/projects/{projectId}/import
# operationId: cancelImport
export def "projects-import cancelImport" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/import" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add files
#
# POST /v2/projects/import
# operationId: addFiles_1
export def "projects-import addFiles-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --structureDelimiter: string # When importing files in structured formats (e.g., JSON, YAML), this field defines the delimiter which will be used in names of imported keys. (e.g. .)
  --branch: string # Branch to which files will be imported (e.g. main)
  files: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "structureDelimiter" $structureDelimiter "scalar") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/import" $qp)
  let body = {files: $files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete
#
# DELETE /v2/projects/import
# operationId: cancelImport_1
export def "projects-import cancelImport-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/import" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export data
#
# GET /v2/projects/{projectId}/export
# operationId: exportData
export def "projects-export exportData" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --languages: list # Languages to be contained in export.                  If null, all languages are exported (e.g. en)
  --format: string@format-completer # Format to export to
  --structureDelimiter: string # Delimiter to structure file content.   e.g. For key "home.header.title" would result in {"home": {"header": "title": {"Hello"}}} structure.  When null, resulting file won't be structured. Works only for generic structured formats (e.g. JSON, YAML),  specific formats like `YAML_RUBY` don't honor this parameter.
  --filterKeyId: list # Filter key IDs to be contained in export
  --filterKeyIdNot: list # Filter key IDs not to be contained in export
  --filterTag: string # Filter keys tagged by.  This filter works the same as `filterTagIn` but in this cases it accepts single tag only.
  --filterTagIn: list # Filter keys tagged by one of provided tags
  --filterTagNotIn: list # Filter keys not tagged by one of provided tags
  --filterKeyPrefix: string # Filter keys with prefix
  --filterState: list # Filter translations with state. By default, all states except untranslated is exported.
  --filterNamespace: list # Filter translations with namespace. By default, all namespaces everything are exported. To export default namespace, use empty string.
  --zip: string@bool-completer # If false, it doesn't return zip of files, but it returns single file.        This is possible only when single language is exported. Otherwise it returns "400 - Bad Request" response.
  --messageFormat: string@messageFormat-completer # Message format to be used for export.        e.g. PHP_PO: Hello %s, ICU: Hello {name}.   This property is honored only for generic formats like JSON or YAML.  For specific formats like `YAML_RUBY` it's ignored.
  --fileStructureTemplate: string # This is a template that defines the structure of the resulting .zip file content.  The template is a string that can contain the following placeholders: {namespace}, {languageTag},  {androidLanguageTag}, {snakeLanguageTag}, {extension}.   For example, when exporting to JSON with the template `{namespace}/{languageTag}.{extension}`,  the English translations of the `home` namespace will be stored in `home/en.json`.  The `{snakeLanguageTag}` placeholder is the same as `{languageTag}` but in snake case. (e.g., en_US).  The Android specific `{androidLanguageTag}` placeholder is the same as `{languageTag}`  but in Android format. (e.g., en-rUS)
  --supportArrays: string@bool-completer # If true, for structured formats (like JSON) arrays are supported.   e.g. Key hello[0] will be exported as {"hello": ["..."]}
  --escapeHtml: string@bool-completer # If true, HTML tags are escaped in the exported file. (Supported in the XLIFF format only).  e.g. Key <b>hello</b> will be exported as &lt;b&gt;hello&lt;/b&gt;
  --filterBranch: string # Filter translations with branch.   By default, default branch is exported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languages" $languages "multi") (serialize-qp "format" $format "scalar") (serialize-qp "structureDelimiter" $structureDelimiter "scalar") (serialize-qp "filterKeyId" $filterKeyId "multi") (serialize-qp "filterKeyIdNot" $filterKeyIdNot "multi") (serialize-qp "filterTag" $filterTag "scalar") (serialize-qp "filterTagIn" $filterTagIn "multi") (serialize-qp "filterTagNotIn" $filterTagNotIn "multi") (serialize-qp "filterKeyPrefix" $filterKeyPrefix "scalar") (serialize-qp "filterState" $filterState "multi") (serialize-qp "filterNamespace" $filterNamespace "multi") (serialize-qp "zip" $zip "scalar") (serialize-qp "messageFormat" $messageFormat "scalar") (serialize-qp "fileStructureTemplate" $fileStructureTemplate "scalar") (serialize-qp "supportArrays" $supportArrays "scalar") (serialize-qp "escapeHtml" $escapeHtml "scalar") (serialize-qp "filterBranch" $filterBranch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/export" $qp)
  let accept_val = "application/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export data (post)
#
# POST /v2/projects/{projectId}/export
# operationId: exportPost
export def "projects-export exportPost" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --languages: list # Languages to be contained in export.                  If null, all languages are exported (e.g. en)
  format: string@format-completer # Format to export to
  --structureDelimiter: string # Delimiter to structure file content.   e.g. For key "home.header.title" would result in {"home": {"header": "title": {"Hello"}}} structure.  When null, resulting file won't be structured. Works only for generic structured formats (e.g. JSON, YAML),  specific formats like `YAML_RUBY` don't honor this parameter.
  --filterKeyId: list # Filter key IDs to be contained in export
  --filterKeyIdNot: list # Filter key IDs not to be contained in export
  --filterTag: string # Filter keys tagged by.  This filter works the same as `filterTagIn` but in this cases it accepts single tag only.
  --filterTagIn: list # Filter keys tagged by one of provided tags
  --filterTagNotIn: list # Filter keys not tagged by one of provided tags
  --filterKeyPrefix: string # Filter keys with prefix
  --filterState: list # Filter translations with state. By default, all states except untranslated is exported.
  --filterNamespace: list # Filter translations with namespace. By default, all namespaces everything are exported. To export default namespace, use empty string.
  --zip: string@bool-completer
  --messageFormat: string@messageFormat-completer # Message format to be used for export.        e.g. PHP_PO: Hello %s, ICU: Hello {name}.   This property is honored only for generic formats like JSON or YAML.  For specific formats like `YAML_RUBY` it's ignored.
  --fileStructureTemplate: string # This is a template that defines the structure of the resulting .zip file content.  The template is a string that can contain the following placeholders: {namespace}, {languageTag},  {androidLanguageTag}, {snakeLanguageTag}, {extension}.   For example, when exporting to JSON with the template `{namespace}/{languageTag}.{extension}`,  the English translations of the `home` namespace will be stored in `home/en.json`.  The `{snakeLanguageTag}` placeholder is the same as `{languageTag}` but in snake case. (e.g., en_US).  The Android specific `{androidLanguageTag}` placeholder is the same as `{languageTag}`  but in Android format. (e.g., en-rUS)
  --supportArrays: string@bool-completer # If true, for structured formats (like JSON) arrays are supported.   e.g. Key hello[0] will be exported as {"hello": ["..."]}
  --escapeHtml: string@bool-completer # If true, HTML tags are escaped in the exported file. (Supported in the XLIFF format only).  e.g. Key <b>hello</b> will be exported as &lt;b&gt;hello&lt;/b&gt;
  --filterBranch: string # Filter translations with branch.   By default, default branch is exported.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/export")
  let body = {languages: $languages, format: $format, structureDelimiter: $structureDelimiter, filterKeyId: $filterKeyId, filterKeyIdNot: $filterKeyIdNot, filterTag: $filterTag, filterTagIn: $filterTagIn, filterTagNotIn: $filterTagNotIn, filterKeyPrefix: $filterKeyPrefix, filterState: $filterState, filterNamespace: $filterNamespace, zip: $zip, messageFormat: $messageFormat, fileStructureTemplate: $fileStructureTemplate, supportArrays: $supportArrays, escapeHtml: $escapeHtml, filterBranch: $filterBranch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export data
#
# GET /v2/projects/export
# operationId: exportData_1
export def "projects-export exportData-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --languages: list # Languages to be contained in export.                  If null, all languages are exported (e.g. en)
  --format: string@format-completer # Format to export to
  --structureDelimiter: string # Delimiter to structure file content.   e.g. For key "home.header.title" would result in {"home": {"header": "title": {"Hello"}}} structure.  When null, resulting file won't be structured. Works only for generic structured formats (e.g. JSON, YAML),  specific formats like `YAML_RUBY` don't honor this parameter.
  --filterKeyId: list # Filter key IDs to be contained in export
  --filterKeyIdNot: list # Filter key IDs not to be contained in export
  --filterTag: string # Filter keys tagged by.  This filter works the same as `filterTagIn` but in this cases it accepts single tag only.
  --filterTagIn: list # Filter keys tagged by one of provided tags
  --filterTagNotIn: list # Filter keys not tagged by one of provided tags
  --filterKeyPrefix: string # Filter keys with prefix
  --filterState: list # Filter translations with state. By default, all states except untranslated is exported.
  --filterNamespace: list # Filter translations with namespace. By default, all namespaces everything are exported. To export default namespace, use empty string.
  --zip: string@bool-completer # If false, it doesn't return zip of files, but it returns single file.        This is possible only when single language is exported. Otherwise it returns "400 - Bad Request" response.
  --messageFormat: string@messageFormat-completer # Message format to be used for export.        e.g. PHP_PO: Hello %s, ICU: Hello {name}.   This property is honored only for generic formats like JSON or YAML.  For specific formats like `YAML_RUBY` it's ignored.
  --fileStructureTemplate: string # This is a template that defines the structure of the resulting .zip file content.  The template is a string that can contain the following placeholders: {namespace}, {languageTag},  {androidLanguageTag}, {snakeLanguageTag}, {extension}.   For example, when exporting to JSON with the template `{namespace}/{languageTag}.{extension}`,  the English translations of the `home` namespace will be stored in `home/en.json`.  The `{snakeLanguageTag}` placeholder is the same as `{languageTag}` but in snake case. (e.g., en_US).  The Android specific `{androidLanguageTag}` placeholder is the same as `{languageTag}`  but in Android format. (e.g., en-rUS)
  --supportArrays: string@bool-completer # If true, for structured formats (like JSON) arrays are supported.   e.g. Key hello[0] will be exported as {"hello": ["..."]}
  --escapeHtml: string@bool-completer # If true, HTML tags are escaped in the exported file. (Supported in the XLIFF format only).  e.g. Key <b>hello</b> will be exported as &lt;b&gt;hello&lt;/b&gt;
  --filterBranch: string # Filter translations with branch.   By default, default branch is exported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languages" $languages "multi") (serialize-qp "format" $format "scalar") (serialize-qp "structureDelimiter" $structureDelimiter "scalar") (serialize-qp "filterKeyId" $filterKeyId "multi") (serialize-qp "filterKeyIdNot" $filterKeyIdNot "multi") (serialize-qp "filterTag" $filterTag "scalar") (serialize-qp "filterTagIn" $filterTagIn "multi") (serialize-qp "filterTagNotIn" $filterTagNotIn "multi") (serialize-qp "filterKeyPrefix" $filterKeyPrefix "scalar") (serialize-qp "filterState" $filterState "multi") (serialize-qp "filterNamespace" $filterNamespace "multi") (serialize-qp "zip" $zip "scalar") (serialize-qp "messageFormat" $messageFormat "scalar") (serialize-qp "fileStructureTemplate" $fileStructureTemplate "scalar") (serialize-qp "supportArrays" $supportArrays "scalar") (serialize-qp "escapeHtml" $escapeHtml "scalar") (serialize-qp "filterBranch" $filterBranch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/export" $qp)
  let accept_val = "application/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export data (post)
#
# POST /v2/projects/export
# operationId: exportPost_1
export def "projects-export exportPost-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --languages: list # Languages to be contained in export.                  If null, all languages are exported (e.g. en)
  format: string@format-completer # Format to export to
  --structureDelimiter: string # Delimiter to structure file content.   e.g. For key "home.header.title" would result in {"home": {"header": "title": {"Hello"}}} structure.  When null, resulting file won't be structured. Works only for generic structured formats (e.g. JSON, YAML),  specific formats like `YAML_RUBY` don't honor this parameter.
  --filterKeyId: list # Filter key IDs to be contained in export
  --filterKeyIdNot: list # Filter key IDs not to be contained in export
  --filterTag: string # Filter keys tagged by.  This filter works the same as `filterTagIn` but in this cases it accepts single tag only.
  --filterTagIn: list # Filter keys tagged by one of provided tags
  --filterTagNotIn: list # Filter keys not tagged by one of provided tags
  --filterKeyPrefix: string # Filter keys with prefix
  --filterState: list # Filter translations with state. By default, all states except untranslated is exported.
  --filterNamespace: list # Filter translations with namespace. By default, all namespaces everything are exported. To export default namespace, use empty string.
  --zip: string@bool-completer
  --messageFormat: string@messageFormat-completer # Message format to be used for export.        e.g. PHP_PO: Hello %s, ICU: Hello {name}.   This property is honored only for generic formats like JSON or YAML.  For specific formats like `YAML_RUBY` it's ignored.
  --fileStructureTemplate: string # This is a template that defines the structure of the resulting .zip file content.  The template is a string that can contain the following placeholders: {namespace}, {languageTag},  {androidLanguageTag}, {snakeLanguageTag}, {extension}.   For example, when exporting to JSON with the template `{namespace}/{languageTag}.{extension}`,  the English translations of the `home` namespace will be stored in `home/en.json`.  The `{snakeLanguageTag}` placeholder is the same as `{languageTag}` but in snake case. (e.g., en_US).  The Android specific `{androidLanguageTag}` placeholder is the same as `{languageTag}`  but in Android format. (e.g., en-rUS)
  --supportArrays: string@bool-completer # If true, for structured formats (like JSON) arrays are supported.   e.g. Key hello[0] will be exported as {"hello": ["..."]}
  --escapeHtml: string@bool-completer # If true, HTML tags are escaped in the exported file. (Supported in the XLIFF format only).  e.g. Key <b>hello</b> will be exported as &lt;b&gt;hello&lt;/b&gt;
  --filterBranch: string # Filter translations with branch.   By default, default branch is exported.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/export")
  let body = {languages: $languages, format: $format, structureDelimiter: $structureDelimiter, filterKeyId: $filterKeyId, filterKeyIdNot: $filterKeyIdNot, filterTag: $filterTag, filterTagIn: $filterTagIn, filterTagNotIn: $filterTagNotIn, filterKeyPrefix: $filterKeyPrefix, filterState: $filterState, filterNamespace: $filterNamespace, zip: $zip, messageFormat: $messageFormat, fileStructureTemplate: $fileStructureTemplate, supportArrays: $supportArrays, escapeHtml: $escapeHtml, filterBranch: $filterBranch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Store Big Meta
#
# POST /v2/projects/{projectId}/big-meta
# operationId: store_2
# --relatedKeysInOrder item shape: {namespace?: string, keyName: string, branch?: string}
export def "projects-big-meta store-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --relatedKeysInOrder: list # Keys in the document used as a context for machine translation. Keys in the same order as they appear in the document. The order is important! We are using it for graph distance calculation.  — item shape: {namespace?: string, keyName: string, branch?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/big-meta")
  let body = {relatedKeysInOrder: $relatedKeysInOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Store Big Meta
#
# POST /v2/projects/big-meta
# operationId: store_3
# --relatedKeysInOrder item shape: {namespace?: string, keyName: string, branch?: string}
export def "projects-big-meta store-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --relatedKeysInOrder: list # Keys in the document used as a context for machine translation. Keys in the same order as they appear in the document. The order is important! We are using it for graph distance calculation.  — item shape: {namespace?: string, keyName: string, branch?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/big-meta")
  let body = {relatedKeysInOrder: $relatedKeysInOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List webhook configurations
#
# GET /v2/projects/{projectId}/webhook-configs
# operationId: list
export def "projects-webhook-configs list" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/webhook-configs" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new webhook configuration
#
# POST /v2/projects/{projectId}/webhook-configs
# operationId: create
export def "projects-webhook-configs create" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string
  --enabled: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/webhook-configs")
  let body = {url: $body_url, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test webhook configuration
#
# POST /v2/projects/{projectId}/webhook-configs/{id}/test
# operationId: test
export def "projects-webhook-configs-test test" [
  id: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/webhook-configs/($id)/test")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get translation comments
#
# GET /v2/projects/{projectId}/translations/{translationId}/comments
# operationId: getAll_3
export def "projects-translations-comments get-by-translationId-projectId" [
  translationId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($translationId)/comments" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create translation comment
#
# POST /v2/projects/{projectId}/translations/{translationId}/comments
# operationId: create_1
export def "projects-translations-comments create-by-translationId-projectId" [
  translationId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  text: string
  state: string@state-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($translationId)/comments")
  let body = {text: $text, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get translation comments
#
# GET /v2/projects/translations/{translationId}/comments
# operationId: getAll_4
export def "projects-translations-comments get-by-translationId" [
  translationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/translations/($translationId)/comments" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create translation comment
#
# POST /v2/projects/translations/{translationId}/comments
# operationId: create_2
export def "projects-translations-comments create-by-translationId" [
  translationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  text: string
  state: string@state-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/translations/($translationId)/comments")
  let body = {text: $text, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a QA issue suppression by match parameters
#
# POST /v2/projects/{projectId}/translations/{translationId}/qa-issues/suppressions
# operationId: createSuppression
export def "projects-translations-qa-issues-suppressions createSuppression" [
  projectId: int
  translationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-3
  message: string@message-completer
  --replacement: string
  --positionStart: int # format: int32
  --positionEnd: int # format: int32
  --params: record
  --pluralVariant: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($translationId)/qa-issues/suppressions")
  let body = {type: $type, message: $message, replacement: $replacement, positionStart: $positionStart, positionEnd: $positionEnd, params: $params, pluralVariant: $pluralVariant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a QA issue suppression by match parameters
#
# DELETE /v2/projects/{projectId}/translations/{translationId}/qa-issues/suppressions
# operationId: removeSuppression
export def "projects-translations-qa-issues-suppressions removeSuppression" [
  projectId: int
  translationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-3
  message: string@message-completer
  --replacement: string
  --positionStart: int # format: int32
  --positionEnd: int # format: int32
  --params: record
  --pluralVariant: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($translationId)/qa-issues/suppressions")
  let body = {type: $type, message: $message, replacement: $replacement, positionStart: $positionStart, positionEnd: $positionEnd, params: $params, pluralVariant: $pluralVariant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create translation comment
#
# POST /v2/projects/{projectId}/translations/create-comment
# operationId: create_3
export def "projects-translations-create-comment create-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyId: int # format: int64
  languageId: int # format: int64
  text: string
  state: string@state-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/create-comment")
  let body = {keyId: $keyId, languageId: $languageId, text: $text, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create translation comment
#
# POST /v2/projects/translations/create-comment
# operationId: create_4
export def "projects-translations-create-comment create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyId: int # format: int64
  languageId: int # format: int64
  text: string
  state: string@state-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/translations/create-comment")
  let body = {keyId: $keyId, languageId: $languageId, text: $text, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create multiple tasks
#
# POST /v2/projects/{projectId}/tasks/create-multiple-tasks
# operationId: createTasks
# --tasks item shape: {name?: string, description: string, type: "TRANSLATE"|"REVIEW", dueDate?: int, languageId: int, assignees: list, keys: list, branch?: string}
export def "projects-tasks-create-multiple-tasks createTasks" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterState: list
  --filterOutdated: string@bool-completer
  tasks: list # item shape: {name?: string, description: string, type: "TRANSLATE"|"REVIEW", dueDate?: int, languageId: int, assignees: list, keys: list, branch?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterState" $filterState "multi") (serialize-qp "filterOutdated" $filterOutdated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/tasks/create-multiple-tasks" $qp)
  let body = {tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create multiple tasks
#
# POST /v2/projects/tasks/create-multiple-tasks
# operationId: createTasks_1
# --tasks item shape: {name?: string, description: string, type: "TRANSLATE"|"REVIEW", dueDate?: int, languageId: int, assignees: list, keys: list, branch?: string}
export def "projects-tasks-create-multiple-tasks createTasks-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterState: list
  --filterOutdated: string@bool-completer
  tasks: list # item shape: {name?: string, description: string, type: "TRANSLATE"|"REVIEW", dueDate?: int, languageId: int, assignees: list, keys: list, branch?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterState" $filterState "multi") (serialize-qp "filterOutdated" $filterOutdated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/tasks/create-multiple-tasks" $qp)
  let body = {tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Calculate scope
#
# POST /v2/projects/{projectId}/tasks/calculate-scope
# operationId: calculateScope
export def "projects-tasks-calculate-scope calculateScope" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterState: list
  --filterOutdated: string@bool-completer
  languageId: int # format: int64
  type: string@type-completer-4
  keys: list
  --branch: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterState" $filterState "multi") (serialize-qp "filterOutdated" $filterOutdated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/tasks/calculate-scope" $qp)
  let body = {languageId: $languageId, type: $type, keys: $keys, branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Calculate scope
#
# POST /v2/projects/tasks/calculate-scope
# operationId: calculateScope_1
export def "projects-tasks-calculate-scope calculateScope-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterState: list
  --filterOutdated: string@bool-completer
  languageId: int # format: int64
  type: string@type-completer-4
  keys: list
  --branch: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterState" $filterState "multi") (serialize-qp "filterOutdated" $filterOutdated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/tasks/calculate-scope" $qp)
  let body = {languageId: $languageId, type: $type, keys: $keys, branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get tasks
#
# GET /v2/projects/{projectId}/tasks
# operationId: getTasks
export def "projects-tasks list" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterState: list # Filter tasks by state
  --filterNotState: list # Filter tasks without state
  --filterAssignee: list # Filter tasks by assignee
  --filterType: list # Filter tasks by type
  --filterId: list # Filter tasks by id
  --filterNotId: list # Filter tasks without id
  --filterProject: list # Filter tasks by project
  --filterNotProject: list # Filter tasks without project
  --filterLanguage: list # Filter tasks by language
  --filterKey: list # Filter tasks by key
  --filterAgency: list # Filter tasks by agency
  --filterNotClosedBefore: int # Exclude tasks which were closed before specified timestamp (format: int64)
  --branch: string # Filter tasks by branch name. Defaults to project's default branch.
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterState" $filterState "multi") (serialize-qp "filterNotState" $filterNotState "multi") (serialize-qp "filterAssignee" $filterAssignee "multi") (serialize-qp "filterType" $filterType "multi") (serialize-qp "filterId" $filterId "multi") (serialize-qp "filterNotId" $filterNotId "multi") (serialize-qp "filterProject" $filterProject "multi") (serialize-qp "filterNotProject" $filterNotProject "multi") (serialize-qp "filterLanguage" $filterLanguage "multi") (serialize-qp "filterKey" $filterKey "multi") (serialize-qp "filterAgency" $filterAgency "multi") (serialize-qp "filterNotClosedBefore" $filterNotClosedBefore "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/tasks" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create task
#
# POST /v2/projects/{projectId}/tasks
# operationId: createTask
export def "projects-tasks createTask" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterState: list
  --filterOutdated: string@bool-completer
  --name: string
  description: string
  type: string@type-completer-4
  --dueDate: int # Due to date in epoch format (milliseconds). (format: int64, e.g. 1661172869000)
  languageId: int # Id of language, this task is attached to. (format: int64, e.g. 1)
  assignees: list
  keys: list
  --branch: string # Branch name. If empty or null, default branch is used.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterState" $filterState "multi") (serialize-qp "filterOutdated" $filterOutdated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/tasks" $qp)
  let body = {name: $name, description: $description, type: $type, dueDate: $dueDate, languageId: $languageId, assignees: $assignees, keys: $keys, branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get tasks
#
# GET /v2/projects/tasks
# operationId: getTasks_1
export def "projects-tasks get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterState: list # Filter tasks by state
  --filterNotState: list # Filter tasks without state
  --filterAssignee: list # Filter tasks by assignee
  --filterType: list # Filter tasks by type
  --filterId: list # Filter tasks by id
  --filterNotId: list # Filter tasks without id
  --filterProject: list # Filter tasks by project
  --filterNotProject: list # Filter tasks without project
  --filterLanguage: list # Filter tasks by language
  --filterKey: list # Filter tasks by key
  --filterAgency: list # Filter tasks by agency
  --filterNotClosedBefore: int # Exclude tasks which were closed before specified timestamp (format: int64)
  --branch: string # Filter tasks by branch name. Defaults to project's default branch.
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterState" $filterState "multi") (serialize-qp "filterNotState" $filterNotState "multi") (serialize-qp "filterAssignee" $filterAssignee "multi") (serialize-qp "filterType" $filterType "multi") (serialize-qp "filterId" $filterId "multi") (serialize-qp "filterNotId" $filterNotId "multi") (serialize-qp "filterProject" $filterProject "multi") (serialize-qp "filterNotProject" $filterNotProject "multi") (serialize-qp "filterLanguage" $filterLanguage "multi") (serialize-qp "filterKey" $filterKey "multi") (serialize-qp "filterAgency" $filterAgency "multi") (serialize-qp "filterNotClosedBefore" $filterNotClosedBefore "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/tasks" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create task
#
# POST /v2/projects/tasks
# operationId: createTask_1
export def "projects-tasks createTask-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterState: list
  --filterOutdated: string@bool-completer
  --name: string
  description: string
  type: string@type-completer-4
  --dueDate: int # Due to date in epoch format (milliseconds). (format: int64, e.g. 1661172869000)
  languageId: int # Id of language, this task is attached to. (format: int64, e.g. 1)
  assignees: list
  keys: list
  --branch: string # Branch name. If empty or null, default branch is used.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterState" $filterState "multi") (serialize-qp "filterOutdated" $filterOutdated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/tasks" $qp)
  let body = {name: $name, description: $description, type: $type, dueDate: $dueDate, languageId: $languageId, assignees: $assignees, keys: $keys, branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get suggestions from translation memory
#
# POST /v2/projects/{projectId}/suggest/translation-memory
# operationId: suggestTranslationMemory
export def "projects-suggest-translation-memory suggestTranslationMemory" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --keyId: int # Key Id to get results for. Use when key is stored already. (format: int64)
  targetLanguageId: int # format: int64
  --baseText: string # Text value of base translation. Useful, when base translation is not stored yet.
  --isPlural: string@bool-completer # Whether base text is plural. This value is ignored if baseText is null.
  --services: list # List of services to use. If null, then all enabled services are used.
  --plural: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/suggest/translation-memory" $qp)
  let body = {keyId: $keyId, targetLanguageId: $targetLanguageId, baseText: $baseText, isPlural: $isPlural, services: $services, plural: $plural} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get suggestions from translation memory
#
# POST /v2/projects/suggest/translation-memory
# operationId: suggestTranslationMemory_1
export def "projects-suggest-translation-memory suggestTranslationMemory-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --keyId: int # Key Id to get results for. Use when key is stored already. (format: int64)
  targetLanguageId: int # format: int64
  --baseText: string # Text value of base translation. Useful, when base translation is not stored yet.
  --isPlural: string@bool-completer # Whether base text is plural. This value is ignored if baseText is null.
  --services: list # List of services to use. If null, then all enabled services are used.
  --plural: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/suggest/translation-memory" $qp)
  let body = {keyId: $keyId, targetLanguageId: $targetLanguageId, baseText: $baseText, isPlural: $isPlural, services: $services, plural: $plural} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get machine translation suggestions (streaming)
#
# POST /v2/projects/{projectId}/suggest/machine-translations-streaming
# operationId: suggestMachineTranslationsStreaming
export def "projects-suggest-machine-translations-streaming suggestMachineTranslationsStreaming" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --keyId: int # Key Id to get results for. Use when key is stored already. (format: int64)
  targetLanguageId: int # format: int64
  --baseText: string # Text value of base translation. Useful, when base translation is not stored yet.
  --isPlural: string@bool-completer # Whether base text is plural. This value is ignored if baseText is null.
  --services: list # List of services to use. If null, then all enabled services are used.
  --plural: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/suggest/machine-translations-streaming")
  let body = {keyId: $keyId, targetLanguageId: $targetLanguageId, baseText: $baseText, isPlural: $isPlural, services: $services, plural: $plural} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/x-ndjson"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get machine translation suggestions (streaming)
#
# POST /v2/projects/suggest/machine-translations-streaming
# operationId: suggestMachineTranslationsStreaming_1
export def "projects-suggest-machine-translations-streaming suggestMachineTranslationsStreaming-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --keyId: int # Key Id to get results for. Use when key is stored already. (format: int64)
  targetLanguageId: int # format: int64
  --baseText: string # Text value of base translation. Useful, when base translation is not stored yet.
  --isPlural: string@bool-completer # Whether base text is plural. This value is ignored if baseText is null.
  --services: list # List of services to use. If null, then all enabled services are used.
  --plural: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/suggest/machine-translations-streaming")
  let body = {keyId: $keyId, targetLanguageId: $targetLanguageId, baseText: $baseText, isPlural: $isPlural, services: $services, plural: $plural} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/x-ndjson"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get machine translation suggestions
#
# POST /v2/projects/{projectId}/suggest/machine-translations
# operationId: suggestMachineTranslations
export def "projects-suggest-machine-translations suggestMachineTranslations" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --keyId: int # Key Id to get results for. Use when key is stored already. (format: int64)
  targetLanguageId: int # format: int64
  --baseText: string # Text value of base translation. Useful, when base translation is not stored yet.
  --isPlural: string@bool-completer # Whether base text is plural. This value is ignored if baseText is null.
  --services: list # List of services to use. If null, then all enabled services are used.
  --plural: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/suggest/machine-translations")
  let body = {keyId: $keyId, targetLanguageId: $targetLanguageId, baseText: $baseText, isPlural: $isPlural, services: $services, plural: $plural} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get machine translation suggestions
#
# POST /v2/projects/suggest/machine-translations
# operationId: suggestMachineTranslations_1
export def "projects-suggest-machine-translations suggestMachineTranslations-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --keyId: int # Key Id to get results for. Use when key is stored already. (format: int64)
  targetLanguageId: int # format: int64
  --baseText: string # Text value of base translation. Useful, when base translation is not stored yet.
  --isPlural: string@bool-completer # Whether base text is plural. This value is ignored if baseText is null.
  --services: list # List of services to use. If null, then all enabled services are used.
  --plural: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/suggest/machine-translations")
  let body = {keyId: $keyId, targetLanguageId: $targetLanguageId, baseText: $baseText, isPlural: $isPlural, services: $services, plural: $plural} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get suggestions
#
# GET /v2/projects/{projectId}/languages/{languageId}/key/{keyId}/suggestion
# operationId: getSuggestions
export def "projects-languages-key-suggestion get" [
  languageId: int
  keyId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --filterState: list # Filter by suggestion state
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "filterState" $filterState "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/languages/($languageId)/key/($keyId)/suggestion" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create translation suggestion
#
# POST /v2/projects/{projectId}/languages/{languageId}/key/{keyId}/suggestion
# operationId: createSuggestion
export def "projects-languages-key-suggestion createSuggestion" [
  languageId: int
  keyId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  translation: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/languages/($languageId)/key/($keyId)/suggestion")
  let body = {translation: $translation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get suggestions
#
# GET /v2/projects/languages/{languageId}/key/{keyId}/suggestion
# operationId: getSuggestions_1
export def "projects-languages-key-suggestion get-by-languageId-keyId" [
  languageId: int
  keyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --filterState: list # Filter by suggestion state
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "filterState" $filterState "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/languages/($languageId)/key/($keyId)/suggestion" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create translation suggestion
#
# POST /v2/projects/languages/{languageId}/key/{keyId}/suggestion
# operationId: createSuggestion_1
export def "projects-languages-key-suggestion createSuggestion-by-languageId-keyId" [
  languageId: int
  keyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  translation: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/languages/($languageId)/key/($keyId)/suggestion")
  let body = {translation: $translation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all languages
#
# GET /v2/projects/{projectId}/languages
# operationId: getAll_5
export def "projects-languages get-by-projectId" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [tag,ASC])
  --filterId: list # Filter languages by id
  --filterNotId: list # Filter languages without id
  --search: string # Filter languages by name or tag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "filterId" $filterId "multi") (serialize-qp "filterNotId" $filterNotId "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/languages" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create language
#
# POST /v2/projects/{projectId}/languages
# operationId: createLanguage
export def "projects-languages createLanguage" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Language name in english (e.g. Czech)
  originalName: string # Language name in this language (e.g. čeština)
  tag: string # Language tag according to BCP 47 definition (e.g. cs-CZ)
  --flagEmoji: string # Language flag emoji as UTF-8 emoji (e.g. 🇨🇿)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/languages")
  let body = {name: $name, originalName: $originalName, tag: $tag, flagEmoji: $flagEmoji} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all languages
#
# GET /v2/projects/languages
# operationId: getAll_6
export def "projects-languages get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [tag,ASC])
  --filterId: list # Filter languages by id
  --filterNotId: list # Filter languages without id
  --search: string # Filter languages by name or tag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "filterId" $filterId "multi") (serialize-qp "filterNotId" $filterNotId "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/languages" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create language
#
# POST /v2/projects/languages
# operationId: createLanguage_1
export def "projects-languages createLanguage-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Language name in english (e.g. Czech)
  originalName: string # Language name in this language (e.g. čeština)
  tag: string # Language tag according to BCP 47 definition (e.g. cs-CZ)
  --flagEmoji: string # Language flag emoji as UTF-8 emoji (e.g. 🇨🇿)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/languages")
  let body = {name: $name, originalName: $originalName, tag: $tag, flagEmoji: $flagEmoji} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get key info
#
# POST /v2/projects/{projectId}/keys/info
# operationId: getInfo_1
# --keys item shape: {name: string, namespace?: string}
export def "projects-keys-info post-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
  keys: list # item shape: {name: string, namespace?: string}
  languageTags: list # Tags to return language translations in
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/info" $qp)
  let body = {keys: $keys, languageTags: $languageTags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get key info
#
# POST /v2/projects/keys/info
# operationId: getInfo_2
# --keys item shape: {name: string, namespace?: string}
export def "projects-keys-info post-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
  keys: list # item shape: {name: string, namespace?: string}
  languageTags: list # Tags to return language translations in
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/keys/info" $qp)
  let body = {keys: $keys, languageTags: $languageTags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import keys (resolvable)
#
# POST /v2/projects/{projectId}/keys/import-resolvable
# DEPRECATED
# operationId: importKeys
# --keys item shape: {name: string, namespace?: string, screenshots?: list, branch?: string, translations: record}
@deprecated
export def "projects-keys-import-resolvable importKeys" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
  keys: list # item shape: {name: string, namespace?: string, screenshots?: list, branch?: string, translations: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/import-resolvable" $qp)
  let body = {keys: $keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import keys (resolvable)
#
# POST /v2/projects/keys/import-resolvable
# DEPRECATED
# operationId: importKeys_1
# --keys item shape: {name: string, namespace?: string, screenshots?: list, branch?: string, translations: record}
@deprecated
export def "projects-keys-import-resolvable importKeys-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
  keys: list # item shape: {name: string, namespace?: string, screenshots?: list, branch?: string, translations: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/keys/import-resolvable" $qp)
  let body = {keys: $keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import keys
#
# POST /v2/projects/{projectId}/keys/import
# operationId: importKeys_2
# --keys item shape: {name: string, namespace?: string, description?: string, translations: record, tags?: list}
export def "projects-keys-import importKeys-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
  keys: list # item shape: {name: string, namespace?: string, description?: string, translations: record, tags?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/import" $qp)
  let body = {keys: $keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import keys
#
# POST /v2/projects/keys/import
# operationId: importKeys_3
# --keys item shape: {name: string, namespace?: string, description?: string, translations: record, tags?: list}
export def "projects-keys-import importKeys-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
  keys: list # item shape: {name: string, namespace?: string, description?: string, translations: record, tags?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/keys/import" $qp)
  let body = {keys: $keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create new key
#
# POST /v2/projects/{projectId}/keys/create
# operationId: create_5
# --screenshots item shape: {text?: string, uploadedImageId: int, positions?: list}
# --relatedKeysInOrder item shape: {namespace?: string, keyName: string, branch?: string}
@deprecated --flag screenshotUploadedImageIds
export def "projects-keys-create create-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the key
  --namespace: string
  --translations: record
  --states: record # Translation states to update, if not provided states won't be modified
  --tags: list
  --screenshotUploadedImageIds: list # Ids of screenshots uploaded with /v2/image-upload endpoint (DEPRECATED)
  --screenshots: list # item shape: {text?: string, uploadedImageId: int, positions?: list}
  --relatedKeysInOrder: list # Keys in the document used as a context for machine translation. Keys in the same order as they appear in the document. The order is important! We are using it for graph distance calculation.  — item shape: {namespace?: string, keyName: string, branch?: string}
  --description: string # Description of the key (e.g. This key is used on homepage. It's a label of sign up button.)
  --isPlural: string@bool-completer # If key is pluralized. If it will be reflected in the editor
  --pluralArgName: string # The argument name for the plural. If null, value will be guessed from the values provided in translations.
  --maxCharLimit: int # Maximum character limit for translations of this key. Null means no limit. (format: int32)
  --branch: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/create")
  let body = {name: $name, namespace: $namespace, translations: $translations, states: $states, tags: $tags, screenshotUploadedImageIds: $screenshotUploadedImageIds, screenshots: $screenshots, relatedKeysInOrder: $relatedKeysInOrder, description: $description, isPlural: $isPlural, pluralArgName: $pluralArgName, maxCharLimit: $maxCharLimit, branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all keys
#
# GET /v2/projects/{projectId}/keys
# operationId: getAll_7
export def "projects-keys get-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [id,ASC])
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new key
#
# POST /v2/projects/{projectId}/keys
# operationId: create_6
# --screenshots item shape: {text?: string, uploadedImageId: int, positions?: list}
# --relatedKeysInOrder item shape: {namespace?: string, keyName: string, branch?: string}
@deprecated --flag screenshotUploadedImageIds
export def "projects-keys create-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the key
  --namespace: string
  --translations: record
  --states: record # Translation states to update, if not provided states won't be modified
  --tags: list
  --screenshotUploadedImageIds: list # Ids of screenshots uploaded with /v2/image-upload endpoint (DEPRECATED)
  --screenshots: list # item shape: {text?: string, uploadedImageId: int, positions?: list}
  --relatedKeysInOrder: list # Keys in the document used as a context for machine translation. Keys in the same order as they appear in the document. The order is important! We are using it for graph distance calculation.  — item shape: {namespace?: string, keyName: string, branch?: string}
  --description: string # Description of the key (e.g. This key is used on homepage. It's a label of sign up button.)
  --isPlural: string@bool-completer # If key is pluralized. If it will be reflected in the editor
  --pluralArgName: string # The argument name for the plural. If null, value will be guessed from the values provided in translations.
  --maxCharLimit: int # Maximum character limit for translations of this key. Null means no limit. (format: int32)
  --branch: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys")
  let body = {name: $name, namespace: $namespace, translations: $translations, states: $states, tags: $tags, screenshotUploadedImageIds: $screenshotUploadedImageIds, screenshots: $screenshots, relatedKeysInOrder: $relatedKeysInOrder, description: $description, isPlural: $isPlural, pluralArgName: $pluralArgName, maxCharLimit: $maxCharLimit, branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete one or multiple keys (post)
#
# DELETE /v2/projects/{projectId}/keys
# operationId: delete_14
export def "projects-keys delete-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ids: list # IDs of keys to delete
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create new key
#
# POST /v2/projects/keys/create
# operationId: create_7
# --screenshots item shape: {text?: string, uploadedImageId: int, positions?: list}
# --relatedKeysInOrder item shape: {namespace?: string, keyName: string, branch?: string}
@deprecated --flag screenshotUploadedImageIds
export def "projects-keys-create create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the key
  --namespace: string
  --translations: record
  --states: record # Translation states to update, if not provided states won't be modified
  --tags: list
  --screenshotUploadedImageIds: list # Ids of screenshots uploaded with /v2/image-upload endpoint (DEPRECATED)
  --screenshots: list # item shape: {text?: string, uploadedImageId: int, positions?: list}
  --relatedKeysInOrder: list # Keys in the document used as a context for machine translation. Keys in the same order as they appear in the document. The order is important! We are using it for graph distance calculation.  — item shape: {namespace?: string, keyName: string, branch?: string}
  --description: string # Description of the key (e.g. This key is used on homepage. It's a label of sign up button.)
  --isPlural: string@bool-completer # If key is pluralized. If it will be reflected in the editor
  --pluralArgName: string # The argument name for the plural. If null, value will be guessed from the values provided in translations.
  --maxCharLimit: int # Maximum character limit for translations of this key. Null means no limit. (format: int32)
  --branch: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/keys/create")
  let body = {name: $name, namespace: $namespace, translations: $translations, states: $states, tags: $tags, screenshotUploadedImageIds: $screenshotUploadedImageIds, screenshots: $screenshots, relatedKeysInOrder: $relatedKeysInOrder, description: $description, isPlural: $isPlural, pluralArgName: $pluralArgName, maxCharLimit: $maxCharLimit, branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all keys
#
# GET /v2/projects/keys
# operationId: getAll_8
export def "projects-keys get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [id,ASC])
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/keys" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new key
#
# POST /v2/projects/keys
# operationId: create_8
# --screenshots item shape: {text?: string, uploadedImageId: int, positions?: list}
# --relatedKeysInOrder item shape: {namespace?: string, keyName: string, branch?: string}
@deprecated --flag screenshotUploadedImageIds
export def "projects-keys create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the key
  --namespace: string
  --translations: record
  --states: record # Translation states to update, if not provided states won't be modified
  --tags: list
  --screenshotUploadedImageIds: list # Ids of screenshots uploaded with /v2/image-upload endpoint (DEPRECATED)
  --screenshots: list # item shape: {text?: string, uploadedImageId: int, positions?: list}
  --relatedKeysInOrder: list # Keys in the document used as a context for machine translation. Keys in the same order as they appear in the document. The order is important! We are using it for graph distance calculation.  — item shape: {namespace?: string, keyName: string, branch?: string}
  --description: string # Description of the key (e.g. This key is used on homepage. It's a label of sign up button.)
  --isPlural: string@bool-completer # If key is pluralized. If it will be reflected in the editor
  --pluralArgName: string # The argument name for the plural. If null, value will be guessed from the values provided in translations.
  --maxCharLimit: int # Maximum character limit for translations of this key. Null means no limit. (format: int32)
  --branch: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/keys")
  let body = {name: $name, namespace: $namespace, translations: $translations, states: $states, tags: $tags, screenshotUploadedImageIds: $screenshotUploadedImageIds, screenshots: $screenshots, relatedKeysInOrder: $relatedKeysInOrder, description: $description, isPlural: $isPlural, pluralArgName: $pluralArgName, maxCharLimit: $maxCharLimit, branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete one or multiple keys (post)
#
# DELETE /v2/projects/keys
# operationId: delete_15
export def "projects-keys delete-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ids: list # IDs of keys to delete
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/keys")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns glossary term highlights for specified text
#
# POST /v2/projects/{projectId}/glossary-highlights
# operationId: getHighlights
export def "projects-glossary-highlights post" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  languageTag: string # Language tag according to BCP 47 definition (e.g. cs-CZ)
  text: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/glossary-highlights")
  let body = {languageTag: $languageTag, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Content Storages
#
# GET /v2/projects/{projectId}/content-storages
# operationId: list_1
export def "projects-content-storages list-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/content-storages" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Content Storage
#
# POST /v2/projects/{projectId}/content-storages
# operationId: create_9
# --azureContentStorageConfig shape: {connectionString?: string, containerName: string}
# --s3ContentStorageConfig shape: {bucketName: string, accessKey?: string, secretKey?: string, endpoint: string, signingRegion: string, path: string, contentStorageType?: "S3"|"AZURE", enabled?: bool}
export def "projects-content-storages create-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --azureContentStorageConfig: record # shape: {connectionString?: string, containerName: string}
  --s3ContentStorageConfig: record # shape: {bucketName: string, accessKey?: string, secretKey?: string, endpoint: string, signingRegion: string, path: string, contentStorageType?: "S3"|"AZURE", enabled?: bool}
  --publicUrlPrefix: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/content-storages")
  let body = {name: $name, azureContentStorageConfig: $azureContentStorageConfig, s3ContentStorageConfig: $s3ContentStorageConfig, publicUrlPrefix: $publicUrlPrefix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test existing Content Storage
#
# POST /v2/projects/{projectId}/content-storages/{id}/test
# operationId: testExisting
# --azureContentStorageConfig shape: {connectionString?: string, containerName: string}
# --s3ContentStorageConfig shape: {bucketName: string, accessKey?: string, secretKey?: string, endpoint: string, signingRegion: string, path: string, contentStorageType?: "S3"|"AZURE", enabled?: bool}
export def "projects-content-storages-test testExisting" [
  id: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --azureContentStorageConfig: record # shape: {connectionString?: string, containerName: string}
  --s3ContentStorageConfig: record # shape: {bucketName: string, accessKey?: string, secretKey?: string, endpoint: string, signingRegion: string, path: string, contentStorageType?: "S3"|"AZURE", enabled?: bool}
  --publicUrlPrefix: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/content-storages/($id)/test")
  let body = {name: $name, azureContentStorageConfig: $azureContentStorageConfig, s3ContentStorageConfig: $s3ContentStorageConfig, publicUrlPrefix: $publicUrlPrefix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test Content Storage settings
#
# POST /v2/projects/{projectId}/content-storages/test
# operationId: test_1
# --azureContentStorageConfig shape: {connectionString?: string, containerName: string}
# --s3ContentStorageConfig shape: {bucketName: string, accessKey?: string, secretKey?: string, endpoint: string, signingRegion: string, path: string, contentStorageType?: "S3"|"AZURE", enabled?: bool}
export def "projects-content-storages-test test-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --azureContentStorageConfig: record # shape: {connectionString?: string, containerName: string}
  --s3ContentStorageConfig: record # shape: {bucketName: string, accessKey?: string, secretKey?: string, endpoint: string, signingRegion: string, path: string, contentStorageType?: "S3"|"AZURE", enabled?: bool}
  --publicUrlPrefix: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/content-storages/test")
  let body = {name: $name, azureContentStorageConfig: $azureContentStorageConfig, s3ContentStorageConfig: $s3ContentStorageConfig, publicUrlPrefix: $publicUrlPrefix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List existing Content Delivery Configs
#
# GET /v2/projects/{projectId}/content-delivery-configs
# operationId: list_2
export def "projects-content-delivery-configs list-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/content-delivery-configs" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Content Delivery Config
#
# POST /v2/projects/{projectId}/content-delivery-configs
# operationId: create_10
export def "projects-content-delivery-configs create-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --contentStorageId: int # Id of custom storage to use for content delivery. If null, default server storage is used. Tolgee Cloud provides default Content Storage. (format: int64)
  --autoPublish: string@bool-completer # If true, data are published to the content delivery automatically after each change.
  --slug: string # Tolgee uses a custom slug as a directory name for content storage and public content delivery URL. It is only applicable for custom storage. This field needs to be kept null for Tolgee Cloud content storage or global server storage on self-hosted instances.  Slag has to match following regular expression: `^[a-z0-9]+(?:-[a-z0-9]+)*$`.  If null is provided for update operation, slug will be assigned with generated value.
  --pruneBeforePublish: string@bool-completer # Whether the data in the CDN should be pruned before publishing new data.  In some cases, you might want to keep the data in the storage and only replace the files created by following publish operation.
  --zip: string@bool-completer # Whether to export all files as a single zip archive (translations.zip).
  --languages: list # Languages to be contained in export.                  If null, all languages are exported (e.g. en)
  format: string@format-completer # Format to export to
  --structureDelimiter: string # Delimiter to structure file content.   e.g. For key "home.header.title" would result in {"home": {"header": "title": {"Hello"}}} structure.  When null, resulting file won't be structured. Works only for generic structured formats (e.g. JSON, YAML),  specific formats like `YAML_RUBY` don't honor this parameter.
  --supportArrays: string@bool-completer # If true, for structured formats (like JSON) arrays are supported.   e.g. Key hello[0] will be exported as {"hello": ["..."]}
  --filterKeyId: list # Filter key IDs to be contained in export
  --filterKeyIdNot: list # Filter key IDs not to be contained in export
  --filterTag: string # Filter keys tagged by.  This filter works the same as `filterTagIn` but in this cases it accepts single tag only.
  --filterTagIn: list # Filter keys tagged by one of provided tags
  --filterTagNotIn: list # Filter keys not tagged by one of provided tags
  --filterKeyPrefix: string # Filter keys with prefix
  --filterState: list # Filter translations with state. By default, all states except untranslated is exported.
  --filterNamespace: list # Filter translations with namespace. By default, all namespaces everything are exported. To export default namespace, use empty string.
  --messageFormat: string@messageFormat-completer # Message format to be used for export.        e.g. PHP_PO: Hello %s, ICU: Hello {name}.   This property is honored only for generic formats like JSON or YAML.  For specific formats like `YAML_RUBY` it's ignored.
  --fileStructureTemplate: string # This is a template that defines the structure of the resulting .zip file content.  The template is a string that can contain the following placeholders: {namespace}, {languageTag},  {androidLanguageTag}, {snakeLanguageTag}, {extension}.   For example, when exporting to JSON with the template `{namespace}/{languageTag}.{extension}`,  the English translations of the `home` namespace will be stored in `home/en.json`.  The `{snakeLanguageTag}` placeholder is the same as `{languageTag}` but in snake case. (e.g., en_US).  The Android specific `{androidLanguageTag}` placeholder is the same as `{languageTag}`  but in Android format. (e.g., en-rUS)
  --escapeHtml: string@bool-completer # If true, HTML tags are escaped in the exported file. (Supported in the XLIFF format only).  e.g. Key <b>hello</b> will be exported as &lt;b&gt;hello&lt;/b&gt;
  --filterBranch: string # Filter translations with branch.   By default, default branch is exported.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/content-delivery-configs")
  let body = {name: $name, contentStorageId: $contentStorageId, autoPublish: $autoPublish, slug: $slug, pruneBeforePublish: $pruneBeforePublish, zip: $zip, languages: $languages, format: $format, structureDelimiter: $structureDelimiter, supportArrays: $supportArrays, filterKeyId: $filterKeyId, filterKeyIdNot: $filterKeyIdNot, filterTag: $filterTag, filterTagIn: $filterTagIn, filterTagNotIn: $filterTagNotIn, filterKeyPrefix: $filterKeyPrefix, filterState: $filterState, filterNamespace: $filterNamespace, messageFormat: $messageFormat, fileStructureTemplate: $fileStructureTemplate, escapeHtml: $escapeHtml, filterBranch: $filterBranch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set branch protected flag
#
# POST /v2/projects/{projectId}/branches/{branchId}/protected
# operationId: setProtected
export def "projects-branches-protected setProtected" [
  branchId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isProtected: string@bool-completer # Whether the branch is protected (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/branches/($branchId)/protected")
  let body = {isProtected: $isProtected} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set branch protected flag
#
# POST /v2/projects/branches/{branchId}/protected
# operationId: setProtected_1
export def "projects-branches-protected setProtected-by-branchId" [
  branchId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isProtected: string@bool-completer # Whether the branch is protected (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/branches/($branchId)/protected")
  let body = {isProtected: $isProtected} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rename branch
#
# POST /v2/projects/{projectId}/branches/{branchId}
# operationId: rename
export def "projects-branches rename" [
  branchId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # New branch name (e.g. feature/rename-branch)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/branches/($branchId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete branch
#
# DELETE /v2/projects/{projectId}/branches/{branchId}
# operationId: delete_16
export def "projects-branches delete-by-branchId-projectId" [
  branchId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/branches/($branchId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rename branch
#
# POST /v2/projects/branches/{branchId}
# operationId: rename_1
export def "projects-branches rename-by-branchId" [
  branchId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # New branch name (e.g. feature/rename-branch)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/branches/($branchId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete branch
#
# DELETE /v2/projects/branches/{branchId}
# operationId: delete_17
export def "projects-branches delete-by-branchId" [
  branchId: int
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
  let full_url = (build-url $base $"/v2/projects/branches/($branchId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refresh branch merge session preview
#
# POST /v2/projects/{projectId}/branches/merge/{mergeId}/refresh
# operationId: refreshBranchMerge
export def "projects-branches-merge-refresh refreshBranchMerge" [
  mergeId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/branches/merge/($mergeId)/refresh")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refresh branch merge session preview
#
# POST /v2/projects/branches/merge/{mergeId}/refresh
# operationId: refreshBranchMerge_1
export def "projects-branches-merge-refresh refreshBranchMerge-by-mergeId" [
  mergeId: int
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
  let full_url = (build-url $base $"/v2/projects/branches/merge/($mergeId)/refresh")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge source branch to target branch
#
# POST /v2/projects/{projectId}/branches/merge/{mergeId}/apply
# operationId: merge
export def "projects-branches-merge-apply merge" [
  mergeId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deleteBranch: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/branches/merge/($mergeId)/apply")
  let body = {deleteBranch: $deleteBranch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merge source branch to target branch
#
# POST /v2/projects/branches/merge/{mergeId}/apply
# operationId: merge_1
export def "projects-branches-merge-apply merge-by-mergeId" [
  mergeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deleteBranch: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/branches/merge/($mergeId)/apply")
  let body = {deleteBranch: $deleteBranch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a merge, dry-runs source branch to target branch and return preview
#
# POST /v2/projects/{projectId}/branches/merge/preview
# operationId: dryRunMerge
export def "projects-branches-merge-preview dryRunMerge" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceBranchId: int # Source branch id (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/branches/merge/preview")
  let body = {sourceBranchId: $sourceBranchId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a merge, dry-runs source branch to target branch and return preview
#
# POST /v2/projects/branches/merge/preview
# operationId: dryRunMerge_1
export def "projects-branches-merge-preview dryRunMerge-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceBranchId: int # Source branch id (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/branches/merge/preview")
  let body = {sourceBranchId: $sourceBranchId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all branches
#
# GET /v2/projects/{projectId}/branches
# operationId: all
export def "projects-branches all" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/branches" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create branch
#
# POST /v2/projects/{projectId}/branches
# operationId: create_11
export def "projects-branches create-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Branch name (e.g. feature/new-branch)
  originBranchId: int # Origin branch id (format: int64)
  --links: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/branches")
  let body = {name: $name, originBranchId: $originBranchId, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all branches
#
# GET /v2/projects/branches
# operationId: all_1
export def "projects-branches all-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/branches" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create branch
#
# POST /v2/projects/branches
# operationId: create_12
export def "projects-branches create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Branch name (e.g. feature/new-branch)
  originBranchId: int # Origin branch id (format: int64)
  --links: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/branches")
  let body = {name: $name, originBranchId: $originBranchId, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get screenshots
#
# GET /v2/projects/keys/{keyId}/screenshots
# operationId: getKeyScreenshots
export def "projects-keys-screenshots get" [
  keyId: int
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
  let full_url = (build-url $base $"/v2/projects/keys/($keyId)/screenshots")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload screenshot
#
# POST /v2/projects/keys/{keyId}/screenshots
# operationId: uploadScreenshot
# --info shape: {text?: string, positions?: list, location?: string}
export def "projects-keys-screenshots uploadScreenshot" [
  keyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  screenshot: string # format: binary
  --info: record # shape: {text?: string, positions?: list, location?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/keys/($keyId)/screenshots")
  let body = {screenshot: $screenshot, info: $info} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get screenshots
#
# GET /v2/projects/{projectId}/keys/{keyId}/screenshots
# operationId: getKeyScreenshots_1
export def "projects-keys-screenshots get-by-keyId-projectId" [
  keyId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/($keyId)/screenshots")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload screenshot
#
# POST /v2/projects/{projectId}/keys/{keyId}/screenshots
# operationId: uploadScreenshot_1
# --info shape: {text?: string, positions?: list, location?: string}
export def "projects-keys-screenshots uploadScreenshot-by-keyId-projectId" [
  keyId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  screenshot: string # format: binary
  --info: record # shape: {text?: string, positions?: list, location?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/($keyId)/screenshots")
  let body = {screenshot: $screenshot, info: $info} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get PAKs
#
# GET /v2/pats
# operationId: getAll_9
export def "pats get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/pats" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create PAK
#
# POST /v2/pats
# operationId: create_13
export def "pats create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # Description of the PAT
  --expiresAt: int # Expiration date in epoch format (milliseconds). When null, token never expires. (format: int64, e.g. 1661172869000)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/pats")
  let body = {description: $description, expiresAt: $expiresAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all permitted organizations
#
# GET /v2/organizations
# operationId: getAll_10
export def "organizations get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [id,ASC])
  --filterCurrentUserOwner: string@bool-completer
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "filterCurrentUserOwner" $filterCurrentUserOwner "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/organizations" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create organization
#
# POST /v2/organizations
# operationId: create_14
export def "organizations create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # e.g. Beautiful organization
  --description: string # e.g. This is a beautiful organization full of beautiful and clever people
  --slug: string # e.g. btforg
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/organizations")
  let body = {name: $name, description: $description, slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all translation memories in the organization
#
# GET /v2/organizations/{organizationId}/translation-memories
# operationId: getAll_11
export def "organizations-translation-memories get-by-organizationId" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create shared translation memory
#
# POST /v2/organizations/{organizationId}/translation-memories
# operationId: create_15
# --assignedProjects item shape: {projectId: int, readAccess: bool, writeAccess: bool, penalty?: int}
export def "organizations-translation-memories create-by-organizationId" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Translation memory name (e.g. Marketing TM)
  sourceLanguageTag: string # Source language tag according to BCP 47 definition (e.g. en)
  --assignedProjects: list # Project assignments with access settings. — item shape: {projectId: int, readAccess: bool, writeAccess: bool, penalty?: int}
  --defaultPenalty: int # Default penalty (0–100) subtracted from match scores for every assignment that does not define its own override. Defaults to 0. (format: int32)
  --writeOnlyReviewed: string@bool-completer # When true, only translations whose state is REVIEWED are written to this TM. Translations that drop back to TRANSLATED or UNTRANSLATED also remove the entry. TMX import and direct TM-browser edits bypass this filter. Defaults to false.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories")
  let body = {name: $name, sourceLanguageTag: $sourceLanguageTag, assignedProjects: $assignedProjects, defaultPenalty: $defaultPenalty, writeOnlyReviewed: $writeOnlyReviewed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import TMX file into translation memory
#
# POST /v2/organizations/{organizationId}/translation-memories/{translationMemoryId}/import
# operationId: importTmx
export def "organizations-translation-memories-import importTmx" [
  organizationId: int
  translationMemoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --overrideExisting: string@bool-completer # default: false
  file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "overrideExisting" $overrideExisting "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories/($translationMemoryId)/import" $qp)
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List rows of a translation memory (paginated)
#
# GET /v2/organizations/{organizationId}/translation-memories/{translationMemoryId}/entries
# operationId: list_3
export def "organizations-translation-memories-entries list-by-organizationId-translationMemoryId" [
  organizationId: int
  translationMemoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string
  --targetLanguageTag: string
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "targetLanguageTag" $targetLanguageTag "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories/($translationMemoryId)/entries" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a translation memory entry
#
# POST /v2/organizations/{organizationId}/translation-memories/{translationMemoryId}/entries
# operationId: create_16
export def "organizations-translation-memories-entries create-by-organizationId-translationMemoryId" [
  organizationId: int
  translationMemoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceText: string # Source text (in the TM's source language) (e.g. Hello world)
  targetText: string # Target translation text (e.g. Hallo Welt)
  targetLanguageTag: string # Target language tag according to BCP 47 definition (e.g. de)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories/($translationMemoryId)/entries")
  let body = {sourceText: $sourceText, targetText: $targetText, targetLanguageTag: $targetLanguageTag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Batch delete translation memory entry groups
#
# DELETE /v2/organizations/{organizationId}/translation-memories/{translationMemoryId}/entries
# operationId: deleteMultipleGroups
export def "organizations-translation-memories-entries delete" [
  organizationId: int
  translationMemoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  entryIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories/($translationMemoryId)/entries")
  let body = {entryIds: $entryIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create translation memory entries for multiple target languages
#
# POST /v2/organizations/{organizationId}/translation-memories/{translationMemoryId}/entries/multiple
# operationId: createMultiple
# --translations item shape: {targetLanguageTag: string, targetText: string}
export def "organizations-translation-memories-entries-multiple createMultiple" [
  organizationId: int
  translationMemoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceText: string # Source text (in the TM's source language) (e.g. Hello world)
  translations: list # Target translations to create, one per target language — item shape: {targetLanguageTag: string, targetText: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories/($translationMemoryId)/entries/multiple")
  let body = {sourceText: $sourceText, translations: $translations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Connect Slack workspace to organization
#
# POST /v2/organizations/{organizationId}/slack/connect
# operationId: connectWorkspace
export def "organizations-slack-connect connectWorkspace" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  code: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/slack/connect")
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all organization-specific providers
#
# GET /v2/organizations/{organizationId}/llm-providers
# operationId: getAll_12
export def "organizations-llm-providers get-by-organizationId" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/llm-providers")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create organization-specific provider
#
# POST /v2/organizations/{organizationId}/llm-providers
# operationId: createProvider
export def "organizations-llm-providers createProvider" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  type: string@type-completer-1
  apiUrl: string
  --apiKey: string
  --priority: string@priority-completer
  --model: string
  --deployment: string
  --keepAlive: string
  --format: string
  --reasoningEffort: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/llm-providers")
  let body = {name: $name, type: $type, apiUrl: $apiUrl, apiKey: $apiKey, priority: $priority, model: $model, deployment: $deployment, keepAlive: $keepAlive, format: $format, reasoningEffort: $reasoningEffort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all organization glossaries
#
# GET /v2/organizations/{organizationId}/glossaries
# operationId: getAll_13
export def "organizations-glossaries get-by-organizationId" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create glossary
#
# POST /v2/organizations/{organizationId}/glossaries
# operationId: create_17
export def "organizations-glossaries create-by-organizationId" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Glossary name (e.g. My glossary)
  baseLanguageTag: string # Language tag according to BCP 47 definition (e.g. cs-CZ)
  assignedProjectIds: list # IDs of projects to be assigned to glossary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries")
  let body = {name: $name, baseLanguageTag: $baseLanguageTag, assignedProjectIds: $assignedProjectIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all glossary terms
#
# GET /v2/organizations/{organizationId}/glossaries/{glossaryId}/terms
# operationId: getAll_14
export def "organizations-glossaries-terms get-by-organizationId-glossaryId" [
  organizationId: int
  glossaryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
  --languageTags: list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar") (serialize-qp "languageTags" $languageTags "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries/($glossaryId)/terms" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new glossary term
#
# POST /v2/organizations/{organizationId}/glossaries/{glossaryId}/terms
# operationId: create_18
export def "organizations-glossaries-terms create-by-organizationId-glossaryId" [
  organizationId: int
  glossaryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # A detailed explanation or definition of the glossary term (e.g. It's trademark)
  --flagNonTranslatable: string@bool-completer # When true, this term will have the same translation across all target languages
  --flagCaseSensitive: string@bool-completer # When true, the term matching considers uppercase and lowercase characters as distinct
  --flagAbbreviation: string@bool-completer # Specifies whether the term represents a shortened form of a word or phrase
  --flagForbiddenTerm: string@bool-completer # When true, marks this term as prohibited or not recommended for use in translations
  text: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries/($glossaryId)/terms")
  let body = {description: $description, flagNonTranslatable: $flagNonTranslatable, flagCaseSensitive: $flagCaseSensitive, flagAbbreviation: $flagAbbreviation, flagForbiddenTerm: $flagForbiddenTerm, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Batch delete multiple terms
#
# DELETE /v2/organizations/{organizationId}/glossaries/{glossaryId}/terms
# operationId: deleteMultiple
export def "organizations-glossaries-terms delete" [
  organizationId: int
  glossaryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  termIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries/($glossaryId)/terms")
  let body = {termIds: $termIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set a new glossary term translation for language
#
# POST /v2/organizations/{organizationId}/glossaries/{glossaryId}/terms/{termId}/translations
# operationId: update_15
export def "organizations-glossaries-terms-translations update-by-organizationId-glossaryId-termId" [
  organizationId: int
  glossaryId: int
  termId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  text: string # Translation text (e.g. Translated text to language of languageTag)
  languageTag: string # Language tag according to BCP 47 definition (e.g. cs-CZ)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries/($glossaryId)/terms/($termId)/translations")
  let body = {text: $text, languageTag: $languageTag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import glossary terms from CSV
#
# POST /v2/organizations/{organizationId}/glossaries/{glossaryId}/import
# operationId: importCsv
export def "organizations-glossaries-import importCsv" [
  organizationId: int
  glossaryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --removeExistingTerms: string@bool-completer # default: false
  file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "removeExistingTerms" $removeExistingTerms "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries/($glossaryId)/import" $qp)
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get url of Stripe subscribe session
#
# POST /v2/organizations/{organizationId}/billing/subscribe
# operationId: subscribe
export def "organizations-billing-subscribe subscribe" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  planId: int # Id of the subscription plan (format: int64)
  period: string@period-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/subscribe")
  let body = {planId: $planId, period: $period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get self-hosted EE subscriptions
#
# GET /v2/organizations/{organizationId}/billing/self-hosted-ee/subscriptions
# operationId: getSelfHostedEeSubscriptions
export def "organizations-billing-self-hosted-ee-subscriptions get" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/self-hosted-ee/subscriptions")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Setups subscription for self-hosted EE instance
#
# POST /v2/organizations/{organizationId}/billing/self-hosted-ee/subscriptions
# operationId: setupEeSubscription
export def "organizations-billing-self-hosted-ee-subscriptions setupEeSubscription" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  planId: int # Id of the subscription plan (format: int64)
  period: string@period-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/self-hosted-ee/subscriptions")
  let body = {planId: $planId, period: $period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Setups subscription for self-hosted EE instance
#
# POST /v2/organizations/{organizationId}/billing/self-hosted-ee/subscribe-free
# operationId: setupFreeEeSubscription
export def "organizations-billing-self-hosted-ee-subscribe-free setupFreeEeSubscription" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  planId: int # Id of the subscription plan (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/self-hosted-ee/subscribe-free")
  let body = {planId: $planId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get checkout session url to buy more credits
#
# POST /v2/organizations/{organizationId}/billing/buy-more-credits
# operationId: getBuyMoreCreditsCheckoutSessionUrl
export def "organizations-billing-buy-more-credits post" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  priceId: int # format: int64
  amount: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/buy-more-credits")
  let body = {priceId: $priceId, amount: $amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload an image for later use
#
# POST /v2/image-upload
# operationId: upload
# --info shape: {location?: string}
export def "image-upload upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  image: string # format: binary
  --info: record # shape: {location?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/image-upload")
  let body = {image: $image, info: $info} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get info before applying the license key
#
# POST /v2/ee-license/prepare-set-license-key
# operationId: prepareSetLicenseKey_1
export def "ee-license-prepare-set-license-key prepareSetLicenseKey-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  licenseKey: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/ee-license/prepare-set-license-key")
  let body = {licenseKey: $licenseKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get info about authentication provider which can replace the current one
#
# GET /v2/auth-provider/change
# operationId: getChangedAuthProvider
export def "auth-provider-change get" [
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
  let full_url = (build-url $base "/v2/auth-provider/change")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept change of the third party authentication provider
#
# POST /v2/auth-provider/change
# operationId: acceptChangeAuthProvider
export def "auth-provider-change acceptChangeAuthProvider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/auth-provider/change")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reject change of the third party authentication provider
#
# DELETE /v2/auth-provider/change
# operationId: rejectChangeAuthProvider
export def "auth-provider-change rejectChangeAuthProvider" [
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
  let full_url = (build-url $base "/v2/auth-provider/change")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all user's API keys
#
# GET /v2/api-keys
# operationId: allByUser
export def "api-keys allByUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageable: string
  --filterProjectId: int # format: int64
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageable" $pageable "scalar") (serialize-qp "filterProjectId" $filterProjectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/api-keys" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create API key
#
# POST /v2/api-keys
# operationId: create_19
export def "api-keys create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  projectId: int # format: int64
  scopes: list
  --description: string # Description of the project API key
  --expiresAt: int # Expiration date in epoch format (milliseconds). When null key never expires. (format: int64, e.g. 1661172869000)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/api-keys")
  let body = {projectId: $projectId, scopes: $scopes, description: $description, expiresAt: $expiresAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Dismiss announcement
#
# POST /v2/announcement/dismiss
# operationId: dismiss
export def "announcement-dismiss dismiss" [
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
  let full_url = (build-url $base "/v2/announcement/dismiss")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all translation agencies
#
# GET /v2/administration/billing/translation-agency
# operationId: getAll_15
export def "administration-billing-translation-agency get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/administration/billing/translation-agency" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create translation agency
#
# POST /v2/administration/billing/translation-agency
# operationId: create_20
export def "administration-billing-translation-agency create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  description: string
  services: list
  --body-url: string
  email: string
  emailBcc: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/administration/billing/translation-agency")
  let body = {name: $name, description: $description, services: $services, url: $body_url, email: $email, emailBcc: $emailBcc} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /v2/administration/billing/self-hosted-ee-plans
#
# operationId: getPlans
export def "administration-billing-self-hosted-ee-plans list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterAssignableToOrganization: int # Filters only plans which can be assignable to the provided organization it.  Plan can be assignable to organization because of one of these reasons:  - plan is private free, visible to organization - plan is paid (Assignable as trial) (format: int64)
  --filterPlanIds: list
  --filterPublic: string@bool-completer
  --filterHasMigration: string@bool-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterAssignableToOrganization" $filterAssignableToOrganization "scalar") (serialize-qp "filterPlanIds" $filterPlanIds "multi") (serialize-qp "filterPublic" $filterPublic "scalar") (serialize-qp "filterHasMigration" $filterHasMigration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/administration/billing/self-hosted-ee-plans" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v2/administration/billing/self-hosted-ee-plans
#
# operationId: create_21
# --prices shape: {perSeat?: float, perThousandTranslations?: float, perThousandMtCredits?: float, subscriptionMonthly: float, subscriptionYearly: float, perThousandKeys?: float, _links?: record}
# --includedUsage shape: {seats: int, translations: int, mtCredits: int, keys: int, _links?: record}
export def "administration-billing-self-hosted-ee-plans create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  enabledFeatures: list
  prices: record # shape: {perSeat?: float, perThousandTranslations?: float, perThousandMtCredits?: float, subscriptionMonthly: float, subscriptionYearly: float, perThousandKeys?: float, _links?: record}
  includedUsage: record # shape: {seats: int, translations: int, mtCredits: int, keys: int, _links?: record}
  --public: string@bool-completer
  --stripeProductId: string
  --notAvailableBefore: string # format: date-time
  --availableUntil: string # format: date-time
  --usableUntil: string # format: date-time
  forOrganizationIds: list
  --free: string@bool-completer
  --nonCommercial: string@bool-completer
  --isPayAsYouGo: string@bool-completer
  --archived: string@bool-completer
  --newStripeProduct: string@bool-completer # If true, a new Stripe product will be created with name specified in [stripeProductName] and [stripeProductId] will be automatically populated with the ID of the newly created Stripe product.
  --stripeProductName: string
  --payAsYouGo: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/administration/billing/self-hosted-ee-plans")
  let body = {name: $name, enabledFeatures: $enabledFeatures, prices: $prices, includedUsage: $includedUsage, public: $public, stripeProductId: $stripeProductId, notAvailableBefore: $notAvailableBefore, availableUntil: $availableUntil, usableUntil: $usableUntil, forOrganizationIds: $forOrganizationIds, free: $free, nonCommercial: $nonCommercial, isPayAsYouGo: $isPayAsYouGo, archived: $archived, newStripeProduct: $newStripeProduct, stripeProductName: $stripeProductName, payAsYouGo: $payAsYouGo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /v2/administration/billing/self-hosted-ee-plans/migration
#
# operationId: createPlanMigration
export def "administration-billing-self-hosted-ee-plans-migration createPlanMigration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer
  targetPlanId: int # format: int64
  monthlyOffsetDays: int # format: int32
  yearlyOffsetDays: int # format: int32
  --customEmailBody: string
  sourcePlanId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/administration/billing/self-hosted-ee-plans/migration")
  let body = {enabled: $enabled, targetPlanId: $targetPlanId, monthlyOffsetDays: $monthlyOffsetDays, yearlyOffsetDays: $yearlyOffsetDays, customEmailBody: $customEmailBody, sourcePlanId: $sourcePlanId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /v2/administration/billing/self-hosted-ee-plans/migration/email-preview
#
# operationId: sendPlanMigrationPreview
export def "administration-billing-self-hosted-ee-plans-migration-email-preview sendPlanMigrationPreview" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourcePlanId: int # format: int64
  targetPlanId: int # format: int64
  --customEmailBody: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/administration/billing/self-hosted-ee-plans/migration/email-preview")
  let body = {sourcePlanId: $sourcePlanId, targetPlanId: $targetPlanId, customEmailBody: $customEmailBody} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /v2/administration/billing/cloud-plans
#
# operationId: getPlans_1
export def "administration-billing-cloud-plans get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterAssignableToOrganization: int # Filters only plans which can be assignable to the provided organization it.  Plan can be assignable to organization because of one of these reasons:  - plan is private free, visible to organization - plan is paid (Assignable as trial) (format: int64)
  --filterPlanIds: list
  --filterPublic: string@bool-completer
  --filterHasMigration: string@bool-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterAssignableToOrganization" $filterAssignableToOrganization "scalar") (serialize-qp "filterPlanIds" $filterPlanIds "multi") (serialize-qp "filterPublic" $filterPublic "scalar") (serialize-qp "filterHasMigration" $filterHasMigration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/administration/billing/cloud-plans" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v2/administration/billing/cloud-plans
#
# operationId: create_22
# --prices shape: {perSeat?: float, perThousandTranslations?: float, perThousandMtCredits?: float, subscriptionMonthly: float, subscriptionYearly: float, perThousandKeys?: float, _links?: record}
# --includedUsage shape: {seats: int, translations: int, mtCredits: int, keys: int, _links?: record}
export def "administration-billing-cloud-plans create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --free: string@bool-completer
  --nonCommercial: string@bool-completer
  enabledFeatures: list
  type: string@type-completer-2
  prices: record # shape: {perSeat?: float, perThousandTranslations?: float, perThousandMtCredits?: float, subscriptionMonthly: float, subscriptionYearly: float, perThousandKeys?: float, _links?: record}
  includedUsage: record # shape: {seats: int, translations: int, mtCredits: int, keys: int, _links?: record}
  --public: string@bool-completer
  stripeProductId: string
  --notAvailableBefore: string # format: date-time
  --availableUntil: string # format: date-time
  --usableUntil: string # format: date-time
  forOrganizationIds: list
  metricType: string@metricType-completer
  --archived: string@bool-completer
  --newStripeProduct: string@bool-completer # If true, a new Stripe product will be created with name specified in [stripeProductName] and [stripeProductId] will be automatically populated with the ID of the newly created Stripe product.
  --stripeProductName: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/administration/billing/cloud-plans")
  let body = {name: $name, free: $free, nonCommercial: $nonCommercial, enabledFeatures: $enabledFeatures, type: $type, prices: $prices, includedUsage: $includedUsage, public: $public, stripeProductId: $stripeProductId, notAvailableBefore: $notAvailableBefore, availableUntil: $availableUntil, usableUntil: $usableUntil, forOrganizationIds: $forOrganizationIds, metricType: $metricType, archived: $archived, newStripeProduct: $newStripeProduct, stripeProductName: $stripeProductName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /v2/administration/billing/cloud-plans/migration
#
# operationId: createPlanMigration_1
export def "administration-billing-cloud-plans-migration createPlanMigration-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer
  targetPlanId: int # format: int64
  monthlyOffsetDays: int # format: int32
  yearlyOffsetDays: int # format: int32
  --customEmailBody: string
  sourcePlanId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/administration/billing/cloud-plans/migration")
  let body = {enabled: $enabled, targetPlanId: $targetPlanId, monthlyOffsetDays: $monthlyOffsetDays, yearlyOffsetDays: $yearlyOffsetDays, customEmailBody: $customEmailBody, sourcePlanId: $sourcePlanId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /v2/administration/billing/cloud-plans/migration/email-preview
#
# operationId: sendPlanMigrationPreview_1
export def "administration-billing-cloud-plans-migration-email-preview sendPlanMigrationPreview-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourcePlanId: int # format: int64
  targetPlanId: int # format: int64
  --customEmailBody: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/administration/billing/cloud-plans/migration/email-preview")
  let body = {sourcePlanId: $sourcePlanId, targetPlanId: $targetPlanId, customEmailBody: $customEmailBody} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate if email is not in use
#
# POST /api/public/validate_email
# operationId: validateEmail
export def "public-validate-email validateEmail" [
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
  let full_url = (build-url $base "/api/public/validate_email")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create new user account (Sign Up)
#
# POST /api/public/sign_up
# operationId: signUp
export def "public-sign-up signUp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  email: string
  --organizationName: string
  password: string
  --invitationCode: string
  --callbackUrl: string
  --userSource: string # Where did the user find us?
  --recaptchaToken: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/public/sign_up")
  let body = {name: $name, email: $email, organizationName: $organizationName, password: $password, invitationCode: $invitationCode, callbackUrl: $callbackUrl, userSource: $userSource, recaptchaToken: $recaptchaToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set a new password
#
# POST /api/public/reset_password_set
# operationId: resetPasswordSet
export def "public-reset-password-set resetPasswordSet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string
  code: string
  --password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/public/reset_password_set")
  let body = {email: $email, code: $code, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Request password reset
#
# POST /api/public/reset_password_request
# operationId: resetPasswordRequest
export def "public-reset-password-request resetPasswordRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  callbackUrl: string
  email: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/public/reset_password_request")
  let body = {callbackUrl: $callbackUrl, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate JWT token
#
# POST /api/public/generatetoken
# operationId: authenticateUser
export def "public-generatetoken authenticateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username: string
  password: string
  --otp: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/public/generatetoken")
  let body = {username: $username, password: $password, otp: $otp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate authentication url (third-party, SSO)
#
# POST /api/public/authorize_oauth/sso/authentication-url
# operationId: getAuthenticationUrl
export def "public-authorize-oauth-sso-authentication-url post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain: string
  state: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/public/authorize_oauth/sso/authentication-url")
  let body = {domain: $domain, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get information about SSO configuration
#
# GET /v2/user/sso
# operationId: getSso
export def "user-sso get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<domain: string, global: bool, force: bool, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/sso")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all single owned organizations
#
# GET /v2/user/single-owned-organizations
# operationId: getAllSingleOwnedOrganizations
export def "user-single-owned-organizations get" [
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
  let full_url = (build-url $base "/v2/user/single-owned-organizations")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization which manages user
#
# GET /v2/user/managed-by
# operationId: getManagedBy
export def "user-managed-by get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organizationModel: record<id: int, name: string, slug: string, description: string, basePermissions: record<scopes: list, type: string, permittedLanguageIds: list, translateLanguageIds: list, viewLanguageIds: list, stateChangeLanguageIds: list, suggestLanguageIds: list, _links: record>, currentUserRole: string, avatar: record<large: string, thumbnail: string>, _links: record>, enabledFeatures: list<string>, quickStart: record<finished: bool, completedSteps: list<string>, open: bool, _links: record>, activeCloudSubscription: record<trialEnd: int, currentBillingPeriod: string, plan: record<metricType: string, archivedAt: string, includedUsage: record, free: bool, public: bool, enabledFeatures: list, nonCommercial: bool, name: string, id: int, type: string>, cancelAtPeriodEnd: bool, status: string>, basePermissions: record<scopes: list<string>, type: string, permittedLanguageIds: list<int>, translateLanguageIds: list<int>, viewLanguageIds: list<int>, stateChangeLanguageIds: list<int>, suggestLanguageIds: list<int>, _links: record>, currentUserRole: string, avatar: record<large: string, thumbnail: string>, slug: string, description: string, name: string, id: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/managed-by")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user tasks
#
# GET /v2/user-tasks
# operationId: getTasks_2
export def "user-tasks get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterState: list # Filter tasks by state
  --filterNotState: list # Filter tasks without state
  --filterAssignee: list # Filter tasks by assignee
  --filterType: list # Filter tasks by type
  --filterId: list # Filter tasks by id
  --filterNotId: list # Filter tasks without id
  --filterProject: list # Filter tasks by project
  --filterNotProject: list # Filter tasks without project
  --filterLanguage: list # Filter tasks by language
  --filterKey: list # Filter tasks by key
  --filterAgency: list # Filter tasks by agency
  --filterNotClosedBefore: int # Exclude tasks which were closed before specified timestamp (format: int64)
  --branch: string # Filter tasks by branch name. Defaults to project's default branch.
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterState" $filterState "multi") (serialize-qp "filterNotState" $filterNotState "multi") (serialize-qp "filterAssignee" $filterAssignee "multi") (serialize-qp "filterType" $filterType "multi") (serialize-qp "filterId" $filterId "multi") (serialize-qp "filterNotId" $filterNotId "multi") (serialize-qp "filterProject" $filterProject "multi") (serialize-qp "filterNotProject" $filterNotProject "multi") (serialize-qp "filterLanguage" $filterLanguage "multi") (serialize-qp "filterKey" $filterKey "multi") (serialize-qp "filterAgency" $filterAgency "multi") (serialize-qp "filterNotClosedBefore" $filterNotClosedBefore "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user-tasks" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user's preferences
#
# GET /v2/user-preferences
# operationId: get_19
export def "user-preferences get-by-" [
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
  let full_url = (build-url $base "/v2/user-preferences")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate project slug
#
# GET /v2/slug/validate-project/{slug}
# operationId: validateProjectSlug
export def "slug-validate-project validateProjectSlug" [
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
  let full_url = (build-url $base $"/v2/slug/validate-project/($slug)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate organization slug
#
# GET /v2/slug/validate-organization/{slug}
# operationId: validateOrganizationSlug
export def "slug-validate-organization validateOrganizationSlug" [
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
  let full_url = (build-url $base $"/v2/slug/validate-organization/($slug)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns connection info
#
# GET /v2/slack/user-login-info
# operationId: getInfo_3
export def "slack-user-login-info get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: string # The encrypted data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data" $data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/slack/user-login-info" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns user roles and their scopes
#
# GET /v2/public/scope-info/roles
# operationId: getRoles
export def "public-scope-info-roles get" [
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
  let full_url = (build-url $base "/v2/public/scope-info/roles")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns hierarchy of scopes
#
# GET /v2/public/scope-info/hierarchy
# operationId: getHierarchy
export def "public-scope-info-hierarchy get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/public/scope-info/hierarchy" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns information about supported translation providers
#
# GET /v2/public/machine-translation-providers
# operationId: getInfo_4
export def "public-machine-translation-providers get-by-" [
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
  let full_url = (build-url $base "/v2/public/machine-translation-providers")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get initial data
#
# GET /v2/public/initial-data
# operationId: get_20
export def "public-initial-data get-by-" [
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
  let full_url = (build-url $base "/v2/public/initial-data")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/public/export-info/formats
#
# operationId: get_21
export def "public-export-info-formats get-by-" [
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
  let full_url = (build-url $base "/v2/public/export-info/formats")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return server configuration properties documentation
#
# GET /v2/public/configuration-properties
# operationId: get_22
export def "public-configuration-properties get-by-" [
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
  let full_url = (build-url $base "/v2/public/configuration-properties")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user billing stats
#
# GET /v2/public/billing/stats/users
# operationId: getUsers
export def "public-billing-stats-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --changedAfter: int # Unix timestamp in milliseconds. Only return users changed after this time. For cursor pagination, use the lastChange value of the last item from the previous page. (format: int64)
  --afterId: int # ID of the last item from the previous page. Used together with changedAfter for compound cursor pagination to disambiguate items with the same lastChange timestamp. (format: int64)
  --changedBefore: int # Unix timestamp in milliseconds. Only return users changed at or before this time. Use together with changedAfter to create a bounded sync window that guarantees termination. (format: int64)
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "changedAfter" $changedAfter "scalar") (serialize-qp "afterId" $afterId "scalar") (serialize-qp "changedBefore" $changedBefore "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/public/billing/stats/users" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user-organization membership stats
#
# GET /v2/public/billing/stats/user-organizations
# operationId: getUserOrganizations
export def "public-billing-stats-user-organizations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --changedAfter: int # Unix timestamp in milliseconds. Only return memberships changed after this time. For cursor pagination, use the lastChange value of the last item from the previous page. (format: int64)
  --afterId: int # ID of the last item from the previous page. Used together with changedAfter for compound cursor pagination to disambiguate items with the same lastChange timestamp. (format: int64)
  --changedBefore: int # Unix timestamp in milliseconds. Only return memberships changed at or before this time. Use together with changedAfter to create a bounded sync window that guarantees termination. (format: int64)
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "changedAfter" $changedAfter "scalar") (serialize-qp "afterId" $afterId "scalar") (serialize-qp "changedBefore" $changedBefore "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/public/billing/stats/user-organizations" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get subscription plan stats
#
# GET /v2/public/billing/stats/plans
# operationId: getPlans_2
export def "public-billing-stats-plans get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --changedAfter: int # Unix timestamp in milliseconds. Only return plans changed after this time. For cursor pagination, use the lastChange value of the last item from the previous page. (format: int64)
  --afterId: int # ID of the last item from the previous page. Used together with changedAfter for compound cursor pagination to disambiguate items with the same lastChange timestamp. (format: int64)
  --changedBefore: int # Unix timestamp in milliseconds. Only return plans changed at or before this time. Use together with changedAfter to create a bounded sync window that guarantees termination. (format: int64)
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "changedAfter" $changedAfter "scalar") (serialize-qp "afterId" $afterId "scalar") (serialize-qp "changedBefore" $changedBefore "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/public/billing/stats/plans" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization billing stats
#
# GET /v2/public/billing/stats/organizations
# operationId: getOrganizations
export def "public-billing-stats-organizations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --changedAfter: int # Unix timestamp in milliseconds. Only return organizations changed after this time. For cursor pagination, use the lastChange value of the last item from the previous page. (format: int64)
  --afterId: int # ID of the last item from the previous page. Used together with changedAfter for compound cursor pagination to disambiguate items with the same lastChange timestamp. (format: int64)
  --changedBefore: int # Unix timestamp in milliseconds. Only return organizations changed at or before this time. Use together with changedAfter to create a bounded sync window that guarantees termination. (format: int64)
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "changedAfter" $changedAfter "scalar") (serialize-qp "afterId" $afterId "scalar") (serialize-qp "changedBefore" $changedBefore "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/public/billing/stats/organizations" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all public plans
#
# GET /v2/public/billing/plans
# operationId: getPlans_3
export def "public-billing-plans get-by-" [
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
  let full_url = (build-url $base "/v2/public/billing/plans")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get public MT credit prices
#
# GET /v2/public/billing/mt-credit-prices
# DEPRECATED
# operationId: getMtCreditPrices
@deprecated
export def "public-billing-mt-credit-prices get" [
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
  let full_url = (build-url $base "/v2/public/billing/mt-credit-prices")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get variables
#
# GET /v2/projects/{projectId}/prompts/get-variables
# operationId: variables
export def "projects-prompts-get-variables variables" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --keyId: int # format: int64
  --targetLanguageId: int # format: int64
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keyId" $keyId "scalar") (serialize-qp "targetLanguageId" $targetLanguageId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/prompts/get-variables" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get variables
#
# GET /v2/projects/prompts/get-variables
# operationId: variables_1
export def "projects-prompts-get-variables variables-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --keyId: int # format: int64
  --targetLanguageId: int # format: int64
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keyId" $keyId "scalar") (serialize-qp "targetLanguageId" $targetLanguageId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/prompts/get-variables" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get default prompt
#
# GET /v2/projects/{projectId}/prompts/default
# operationId: getDefaultPrompt
export def "projects-prompts-default get" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/prompts/default")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get default prompt
#
# GET /v2/projects/prompts/default
# operationId: getDefaultPrompt_1
export def "projects-prompts-default get-by-" [
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
  let full_url = (build-url $base "/v2/projects/prompts/default")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get preferred agency
#
# GET /v2/projects/{projectId}/billing/order-translation/preferred-agency
# operationId: getPreferredAgency
export def "projects-billing-order-translation-preferred-agency get" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/billing/order-translation/preferred-agency")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get preferred agency
#
# GET /v2/projects/billing/order-translation/preferred-agency
# operationId: getPreferredAgency_1
export def "projects-billing-order-translation-preferred-agency get-by-" [
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
  let full_url = (build-url $base "/v2/projects/billing/order-translation/preferred-agency")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get tags
#
# GET /v2/projects/{projectId}/tags
# operationId: getAll_16
export def "projects-tags get-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [name,ASC])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/tags" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get tags
#
# GET /v2/projects/tags
# operationId: getAll_17
export def "projects-tags get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [name,ASC])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/tags" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user batch operations
#
# GET /v2/projects/{projectId}/my-batch-jobs
# operationId: myList
export def "projects-my-batch-jobs myList" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [id,ASC])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/my-batch-jobs" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user batch operations
#
# GET /v2/projects/my-batch-jobs
# operationId: myList_1
export def "projects-my-batch-jobs myList-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [id,ASC])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/my-batch-jobs" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get credit balance for project
#
# GET /v2/projects/{projectId}/machine-translation-credit-balance
# operationId: getProjectCredits
export def "projects-machine-translation-credit-balance get" [
  projectId: int
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/machine-translation-credit-balance")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get labels by ids
#
# GET /v2/projects/{projectId}/labels/ids
# operationId: getLabelsByIds
export def "projects-labels-ids get" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/labels/ids" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get labels by ids
#
# GET /v2/projects/labels/ids
# operationId: getLabelsByIds_1
export def "projects-labels-ids get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/labels/ids" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Big Meta for key
#
# GET /v2/projects/{projectId}/keys/{id}/big-meta
# operationId: getBigMeta
export def "projects-keys-big-meta get" [
  id: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/($id)/big-meta")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Big Meta for key
#
# GET /v2/projects/keys/{id}/big-meta
# operationId: getBigMeta_1
export def "projects-keys-big-meta get-by-id" [
  id: int
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
  let full_url = (build-url $base $"/v2/projects/keys/($id)/big-meta")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get translations
#
# GET /v2/projects/{projectId}/import/result/languages/{languageId}/translations
# operationId: getImportTranslations
export def "projects-import-result-languages-translations get" [
  projectId: int
  languageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --onlyConflicts: string@bool-completer # Whether only translations, which are in conflict with existing translations should be returned (default: false)
  --onlyUnresolved: string@bool-completer # Whether only translations with unresolved conflictswith existing translations should be returned (default: false)
  --search: string # String to search in translation text or key
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [keyName,ASC])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "onlyConflicts" $onlyConflicts "scalar") (serialize-qp "onlyUnresolved" $onlyUnresolved "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/import/result/languages/($languageId)/translations" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get translations
#
# GET /v2/projects/import/result/languages/{languageId}/translations
# operationId: getImportTranslations_1
export def "projects-import-result-languages-translations get-by-languageId" [
  languageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --onlyConflicts: string@bool-completer # Whether only translations, which are in conflict with existing translations should be returned (default: false)
  --onlyUnresolved: string@bool-completer # Whether only translations with unresolved conflictswith existing translations should be returned (default: false)
  --search: string # String to search in translation text or key
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [keyName,ASC])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "onlyConflicts" $onlyConflicts "scalar") (serialize-qp "onlyUnresolved" $onlyUnresolved "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/import/result/languages/($languageId)/translations" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get import language
#
# GET /v2/projects/{projectId}/import/result/languages/{languageId}
# operationId: getImportLanguage
export def "projects-import-result-languages get" [
  languageId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/import/result/languages/($languageId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete language
#
# DELETE /v2/projects/{projectId}/import/result/languages/{languageId}
# operationId: deleteLanguage_2
export def "projects-import-result-languages delete-by-languageId-projectId" [
  languageId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/import/result/languages/($languageId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get import language
#
# GET /v2/projects/import/result/languages/{languageId}
# operationId: getImportLanguage_1
export def "projects-import-result-languages get-by-languageId" [
  languageId: int
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
  let full_url = (build-url $base $"/v2/projects/import/result/languages/($languageId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete language
#
# DELETE /v2/projects/import/result/languages/{languageId}
# operationId: deleteLanguage_3
export def "projects-import-result-languages delete-by-languageId" [
  languageId: int
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
  let full_url = (build-url $base $"/v2/projects/import/result/languages/($languageId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get file issues
#
# GET /v2/projects/{projectId}/import/result/files/{importFileId}/issues
# operationId: getImportFileIssues
export def "projects-import-result-files-issues get" [
  importFileId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/import/result/files/($importFileId)/issues" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get file issues
#
# GET /v2/projects/import/result/files/{importFileId}/issues
# operationId: getImportFileIssues_1
export def "projects-import-result-files-issues get-by-importFileId" [
  importFileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/import/result/files/($importFileId)/issues" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get result
#
# GET /v2/projects/{projectId}/import/result
# operationId: getImportResult
export def "projects-import-result get" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/import/result" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get result
#
# GET /v2/projects/import/result
# operationId: getImportResult_1
export def "projects-import-result get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/import/result" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get namespaces
#
# GET /v2/projects/{projectId}/import/all-namespaces
# operationId: getAllNamespaces
export def "projects-import-all-namespaces get" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/import/all-namespaces")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get namespaces
#
# GET /v2/projects/import/all-namespaces
# operationId: getAllNamespaces_1
export def "projects-import-all-namespaces get-by-" [
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
  let full_url = (build-url $base "/v2/projects/import/all-namespaces")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all running and pending batch operations
#
# GET /v2/projects/{projectId}/current-batch-jobs
# operationId: currentJobs
export def "projects-current-batch-jobs currentJobs" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/current-batch-jobs")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all running and pending batch operations
#
# GET /v2/projects/current-batch-jobs
# operationId: currentJobs_1
export def "projects-current-batch-jobs currentJobs-by-" [
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
  let full_url = (build-url $base "/v2/projects/current-batch-jobs")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get batch operation
#
# GET /v2/projects/{projectId}/batch-jobs/{id}
# operationId: get_23
export def "projects-batch-jobs get-by-id-projectId" [
  id: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/batch-jobs/($id)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get batch operation
#
# GET /v2/projects/batch-jobs/{id}
# operationId: get_24
export def "projects-batch-jobs get-by-id" [
  id: int
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
  let full_url = (build-url $base $"/v2/projects/batch-jobs/($id)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List batch operations
#
# GET /v2/projects/{projectId}/batch-jobs
# operationId: list_4
export def "projects-batch-jobs list-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [id,ASC])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/batch-jobs" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List batch operations
#
# GET /v2/projects/batch-jobs
# operationId: list_5
export def "projects-batch-jobs list-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [id,ASC])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/batch-jobs" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get users with project access
#
# GET /v2/projects/{projectId}/users
# operationId: getAllUsers
export def "projects-users get" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
  --filterId: list # Filter users by id
  --filterNotId: list # Filter users without id
  --filterAgency: list # Filter users from agency
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar") (serialize-qp "filterId" $filterId "multi") (serialize-qp "filterNotId" $filterNotId "multi") (serialize-qp "filterAgency" $filterAgency "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/users" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get used namespaces
#
# GET /v2/projects/{projectId}/used-namespaces
# operationId: getUsedNamespaces
export def "projects-used-namespaces get" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/used-namespaces")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get used namespaces
#
# GET /v2/projects/used-namespaces
# operationId: getUsedNamespaces_1
export def "projects-used-namespaces get-by-" [
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
  let full_url = (build-url $base "/v2/projects/used-namespaces")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get persisted QA issues for a translation
#
# GET /v2/projects/{projectId}/translations/{translationId}/qa-issues
# operationId: getIssues
export def "projects-translations-qa-issues get" [
  projectId: int
  translationId: int
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($translationId)/qa-issues")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get translation history
#
# GET /v2/projects/{projectId}/translations/{translationId}/history
# operationId: getTranslationHistory
export def "projects-translations-history get" [
  translationId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [timestamp,DESC])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($translationId)/history" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get translation history
#
# GET /v2/projects/translations/{translationId}/history
# operationId: getTranslationHistory_1
export def "projects-translations-history get-by-translationId" [
  translationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [timestamp,DESC])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/translations/($translationId)/history" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all translations
#
# GET /v2/projects/{projectId}/translations/{languages}
# operationId: getAllTranslations
export def "projects-translations get" [
  languages: list
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ns: string # Namespace to return
  --structureDelimiter: string # Delimiter to structure response content.   e.g. For key "home.header.title" would result in {"home": {"header": {"title": "Hello"}}} structure.  When null, resulting file will be a flat key-value object.      (default: .)
  --filterTag: list # Enables filtering of returned keys by their tags. Only keys with at least one provided tag will be returned. Optional, filtering is not applied if not specified. (e.g. [productionReady, nextRelease])
  --branch: string # Branch name to return translations from
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ns" $ns "scalar") (serialize-qp "structureDelimiter" $structureDelimiter "scalar") (serialize-qp "filterTag" $filterTag "multi") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/($languages)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all translations
#
# GET /v2/projects/translations/{languages}
# operationId: getAllTranslations_1
export def "projects-translations get-by-languages" [
  languages: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ns: string # Namespace to return
  --structureDelimiter: string # Delimiter to structure response content.   e.g. For key "home.header.title" would result in {"home": {"header": {"title": "Hello"}}} structure.  When null, resulting file will be a flat key-value object.      (default: .)
  --filterTag: list # Enables filtering of returned keys by their tags. Only keys with at least one provided tag will be returned. Optional, filtering is not applied if not specified. (e.g. [productionReady, nextRelease])
  --branch: string # Branch name to return translations from
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ns" $ns "scalar") (serialize-qp "structureDelimiter" $structureDelimiter "scalar") (serialize-qp "filterTag" $filterTag "multi") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/translations/($languages)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Select keys
#
# GET /v2/projects/{projectId}/translations/select-all
# operationId: selectKeys
export def "projects-translations-select-all selectKeys" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterState: list # Translation state in the format: languageTag,state. You can use this parameter multiple times.  When used with multiple states for same language it is applied with logical OR.    When used with multiple languages, it is applied with logical AND.     
  --languages: list # Languages to be contained in response.                  To add multiple languages, repeat this param (eg. ?languages=en&languages=de) (e.g. en)
  --search: string # String to search in key name or translation text
  --filterKeyName: list # Selects key with provided names. Use this param multiple times to fetch more keys.
  --filterKeyId: list # Selects key with provided ID. Use this param multiple times to fetch more keys.
  --filterUntranslatedAny: string@bool-completer # Selects only keys for which the translation is missing in any returned language. It only filters for translations included in returned languages.
  --filterTranslatedAny: string@bool-completer # Selects only keys, where translation is provided in any language
  --filterUntranslatedInLang: string # Selects only keys where the translation is missing for the specified language. The specified language must be included in the returned languages. Otherwise, this filter doesn't apply. (e.g. en-US)
  --filterTranslatedInLang: string # Selects only keys, where translation is provided in specified language (e.g. en-US)
  --filterAutoTranslatedInLang: list # Selects only keys, where translation was auto translated for specified languages. (e.g. en-US)
  --filterHasScreenshot: string@bool-completer # Selects only keys with screenshots
  --filterHasNoScreenshot: string@bool-completer # Selects only keys without screenshots
  --filterNamespace: list # Selects only keys with provided namespaces.   To filter default namespace, set to empty string.   
  --filterNoNamespace: list # Selects only keys without provided namespaces.   To filter default namespace, set to empty string.   
  --filterTag: list # Selects only keys with provided tag
  --filterNoTag: list # Selects only keys without provided tag
  --filterOutdatedLanguage: list # Selects only keys, where translation in provided langs is in outdated state (e.g. en-US)
  --filterNotOutdatedLanguage: list # Selects only keys, where translation in provided langs is not in outdated state (e.g. en-US)
  --filterRevisionId: list # Selects only key affected by activity with specidfied revision ID (e.g. 1234567)
  --filterFailedKeysOfJob: int # Select only keys which were not successfully translated by batch job with provided id (format: int64)
  --filterTaskNumber: list # Select only keys which are in specified task
  --filterTaskKeysNotDone: string@bool-completer # Filter task keys which are `not done`
  --filterTaskKeysDone: string@bool-completer # Filter task keys which are `done`
  --filterHasUnresolvedCommentsInLang: list # Filter keys with unresolved comments in lang
  --filterHasCommentsInLang: list # Filter keys with any comments in lang
  --filterLabel: list # Filter key translations with labels (e.g. labelId1,labelId2)
  --filterHasQaIssuesInLang: list # Filter keys with open QA issues in lang
  --filterQaCheckType: list # Filter keys with specific QA check type issues in the format: languageTag,checkType. You can use this parameter multiple times.  A key matches if any of the selected check types is present in any of the selected languages.     
  --filterQaChecksStaleInLang: list # Filter keys whose QA checks are stale (pending recomputation) in lang. When set, only keys with at least one stale translation in any of the provided languages are returned.
  --filterHasSuggestionsInLang: list # Filter keys with any suggestions in lang
  --filterHasNoSuggestionsInLang: list # Filter keys with no suggestions in lang
  --branch: string # Selects only keys from specified branch
  --filterDeletedByUserId: list # Filter trashed keys by who deleted them (user IDs)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterState" $filterState "multi") (serialize-qp "languages" $languages "multi") (serialize-qp "search" $search "scalar") (serialize-qp "filterKeyName" $filterKeyName "multi") (serialize-qp "filterKeyId" $filterKeyId "multi") (serialize-qp "filterUntranslatedAny" $filterUntranslatedAny "scalar") (serialize-qp "filterTranslatedAny" $filterTranslatedAny "scalar") (serialize-qp "filterUntranslatedInLang" $filterUntranslatedInLang "scalar") (serialize-qp "filterTranslatedInLang" $filterTranslatedInLang "scalar") (serialize-qp "filterAutoTranslatedInLang" $filterAutoTranslatedInLang "multi") (serialize-qp "filterHasScreenshot" $filterHasScreenshot "scalar") (serialize-qp "filterHasNoScreenshot" $filterHasNoScreenshot "scalar") (serialize-qp "filterNamespace" $filterNamespace "multi") (serialize-qp "filterNoNamespace" $filterNoNamespace "multi") (serialize-qp "filterTag" $filterTag "multi") (serialize-qp "filterNoTag" $filterNoTag "multi") (serialize-qp "filterOutdatedLanguage" $filterOutdatedLanguage "multi") (serialize-qp "filterNotOutdatedLanguage" $filterNotOutdatedLanguage "multi") (serialize-qp "filterRevisionId" $filterRevisionId "multi") (serialize-qp "filterFailedKeysOfJob" $filterFailedKeysOfJob "scalar") (serialize-qp "filterTaskNumber" $filterTaskNumber "multi") (serialize-qp "filterTaskKeysNotDone" $filterTaskKeysNotDone "scalar") (serialize-qp "filterTaskKeysDone" $filterTaskKeysDone "scalar") (serialize-qp "filterHasUnresolvedCommentsInLang" $filterHasUnresolvedCommentsInLang "multi") (serialize-qp "filterHasCommentsInLang" $filterHasCommentsInLang "multi") (serialize-qp "filterLabel" $filterLabel "multi") (serialize-qp "filterHasQaIssuesInLang" $filterHasQaIssuesInLang "multi") (serialize-qp "filterQaCheckType" $filterQaCheckType "multi") (serialize-qp "filterQaChecksStaleInLang" $filterQaChecksStaleInLang "multi") (serialize-qp "filterHasSuggestionsInLang" $filterHasSuggestionsInLang "multi") (serialize-qp "filterHasNoSuggestionsInLang" $filterHasNoSuggestionsInLang "multi") (serialize-qp "branch" $branch "scalar") (serialize-qp "filterDeletedByUserId" $filterDeletedByUserId "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/translations/select-all" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Select keys
#
# GET /v2/projects/translations/select-all
# operationId: selectKeys_1
export def "projects-translations-select-all selectKeys-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterState: list # Translation state in the format: languageTag,state. You can use this parameter multiple times.  When used with multiple states for same language it is applied with logical OR.    When used with multiple languages, it is applied with logical AND.     
  --languages: list # Languages to be contained in response.                  To add multiple languages, repeat this param (eg. ?languages=en&languages=de) (e.g. en)
  --search: string # String to search in key name or translation text
  --filterKeyName: list # Selects key with provided names. Use this param multiple times to fetch more keys.
  --filterKeyId: list # Selects key with provided ID. Use this param multiple times to fetch more keys.
  --filterUntranslatedAny: string@bool-completer # Selects only keys for which the translation is missing in any returned language. It only filters for translations included in returned languages.
  --filterTranslatedAny: string@bool-completer # Selects only keys, where translation is provided in any language
  --filterUntranslatedInLang: string # Selects only keys where the translation is missing for the specified language. The specified language must be included in the returned languages. Otherwise, this filter doesn't apply. (e.g. en-US)
  --filterTranslatedInLang: string # Selects only keys, where translation is provided in specified language (e.g. en-US)
  --filterAutoTranslatedInLang: list # Selects only keys, where translation was auto translated for specified languages. (e.g. en-US)
  --filterHasScreenshot: string@bool-completer # Selects only keys with screenshots
  --filterHasNoScreenshot: string@bool-completer # Selects only keys without screenshots
  --filterNamespace: list # Selects only keys with provided namespaces.   To filter default namespace, set to empty string.   
  --filterNoNamespace: list # Selects only keys without provided namespaces.   To filter default namespace, set to empty string.   
  --filterTag: list # Selects only keys with provided tag
  --filterNoTag: list # Selects only keys without provided tag
  --filterOutdatedLanguage: list # Selects only keys, where translation in provided langs is in outdated state (e.g. en-US)
  --filterNotOutdatedLanguage: list # Selects only keys, where translation in provided langs is not in outdated state (e.g. en-US)
  --filterRevisionId: list # Selects only key affected by activity with specidfied revision ID (e.g. 1234567)
  --filterFailedKeysOfJob: int # Select only keys which were not successfully translated by batch job with provided id (format: int64)
  --filterTaskNumber: list # Select only keys which are in specified task
  --filterTaskKeysNotDone: string@bool-completer # Filter task keys which are `not done`
  --filterTaskKeysDone: string@bool-completer # Filter task keys which are `done`
  --filterHasUnresolvedCommentsInLang: list # Filter keys with unresolved comments in lang
  --filterHasCommentsInLang: list # Filter keys with any comments in lang
  --filterLabel: list # Filter key translations with labels (e.g. labelId1,labelId2)
  --filterHasQaIssuesInLang: list # Filter keys with open QA issues in lang
  --filterQaCheckType: list # Filter keys with specific QA check type issues in the format: languageTag,checkType. You can use this parameter multiple times.  A key matches if any of the selected check types is present in any of the selected languages.     
  --filterQaChecksStaleInLang: list # Filter keys whose QA checks are stale (pending recomputation) in lang. When set, only keys with at least one stale translation in any of the provided languages are returned.
  --filterHasSuggestionsInLang: list # Filter keys with any suggestions in lang
  --filterHasNoSuggestionsInLang: list # Filter keys with no suggestions in lang
  --branch: string # Selects only keys from specified branch
  --filterDeletedByUserId: list # Filter trashed keys by who deleted them (user IDs)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterState" $filterState "multi") (serialize-qp "languages" $languages "multi") (serialize-qp "search" $search "scalar") (serialize-qp "filterKeyName" $filterKeyName "multi") (serialize-qp "filterKeyId" $filterKeyId "multi") (serialize-qp "filterUntranslatedAny" $filterUntranslatedAny "scalar") (serialize-qp "filterTranslatedAny" $filterTranslatedAny "scalar") (serialize-qp "filterUntranslatedInLang" $filterUntranslatedInLang "scalar") (serialize-qp "filterTranslatedInLang" $filterTranslatedInLang "scalar") (serialize-qp "filterAutoTranslatedInLang" $filterAutoTranslatedInLang "multi") (serialize-qp "filterHasScreenshot" $filterHasScreenshot "scalar") (serialize-qp "filterHasNoScreenshot" $filterHasNoScreenshot "scalar") (serialize-qp "filterNamespace" $filterNamespace "multi") (serialize-qp "filterNoNamespace" $filterNoNamespace "multi") (serialize-qp "filterTag" $filterTag "multi") (serialize-qp "filterNoTag" $filterNoTag "multi") (serialize-qp "filterOutdatedLanguage" $filterOutdatedLanguage "multi") (serialize-qp "filterNotOutdatedLanguage" $filterNotOutdatedLanguage "multi") (serialize-qp "filterRevisionId" $filterRevisionId "multi") (serialize-qp "filterFailedKeysOfJob" $filterFailedKeysOfJob "scalar") (serialize-qp "filterTaskNumber" $filterTaskNumber "multi") (serialize-qp "filterTaskKeysNotDone" $filterTaskKeysNotDone "scalar") (serialize-qp "filterTaskKeysDone" $filterTaskKeysDone "scalar") (serialize-qp "filterHasUnresolvedCommentsInLang" $filterHasUnresolvedCommentsInLang "multi") (serialize-qp "filterHasCommentsInLang" $filterHasCommentsInLang "multi") (serialize-qp "filterLabel" $filterLabel "multi") (serialize-qp "filterHasQaIssuesInLang" $filterHasQaIssuesInLang "multi") (serialize-qp "filterQaCheckType" $filterQaCheckType "multi") (serialize-qp "filterQaChecksStaleInLang" $filterQaChecksStaleInLang "multi") (serialize-qp "filterHasSuggestionsInLang" $filterHasSuggestionsInLang "multi") (serialize-qp "filterHasNoSuggestionsInLang" $filterHasNoSuggestionsInLang "multi") (serialize-qp "branch" $branch "scalar") (serialize-qp "filterDeletedByUserId" $filterDeletedByUserId "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/translations/select-all" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Select keys
#
# GET /v2/projects/{projectId}/keys/select
# operationId: selectKeys_2
export def "projects-keys-select selectKeys-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterState: list # Translation state in the format: languageTag,state. You can use this parameter multiple times.  When used with multiple states for same language it is applied with logical OR.    When used with multiple languages, it is applied with logical AND.     
  --languages: list # Languages to be contained in response.                  To add multiple languages, repeat this param (eg. ?languages=en&languages=de) (e.g. en)
  --search: string # String to search in key name or translation text
  --filterKeyName: list # Selects key with provided names. Use this param multiple times to fetch more keys.
  --filterKeyId: list # Selects key with provided ID. Use this param multiple times to fetch more keys.
  --filterUntranslatedAny: string@bool-completer # Selects only keys for which the translation is missing in any returned language. It only filters for translations included in returned languages.
  --filterTranslatedAny: string@bool-completer # Selects only keys, where translation is provided in any language
  --filterUntranslatedInLang: string # Selects only keys where the translation is missing for the specified language. The specified language must be included in the returned languages. Otherwise, this filter doesn't apply. (e.g. en-US)
  --filterTranslatedInLang: string # Selects only keys, where translation is provided in specified language (e.g. en-US)
  --filterAutoTranslatedInLang: list # Selects only keys, where translation was auto translated for specified languages. (e.g. en-US)
  --filterHasScreenshot: string@bool-completer # Selects only keys with screenshots
  --filterHasNoScreenshot: string@bool-completer # Selects only keys without screenshots
  --filterNamespace: list # Selects only keys with provided namespaces.   To filter default namespace, set to empty string.   
  --filterNoNamespace: list # Selects only keys without provided namespaces.   To filter default namespace, set to empty string.   
  --filterTag: list # Selects only keys with provided tag
  --filterNoTag: list # Selects only keys without provided tag
  --filterOutdatedLanguage: list # Selects only keys, where translation in provided langs is in outdated state (e.g. en-US)
  --filterNotOutdatedLanguage: list # Selects only keys, where translation in provided langs is not in outdated state (e.g. en-US)
  --filterRevisionId: list # Selects only key affected by activity with specidfied revision ID (e.g. 1234567)
  --filterFailedKeysOfJob: int # Select only keys which were not successfully translated by batch job with provided id (format: int64)
  --filterTaskNumber: list # Select only keys which are in specified task
  --filterTaskKeysNotDone: string@bool-completer # Filter task keys which are `not done`
  --filterTaskKeysDone: string@bool-completer # Filter task keys which are `done`
  --filterHasUnresolvedCommentsInLang: list # Filter keys with unresolved comments in lang
  --filterHasCommentsInLang: list # Filter keys with any comments in lang
  --filterLabel: list # Filter key translations with labels (e.g. labelId1,labelId2)
  --filterHasQaIssuesInLang: list # Filter keys with open QA issues in lang
  --filterQaCheckType: list # Filter keys with specific QA check type issues in the format: languageTag,checkType. You can use this parameter multiple times.  A key matches if any of the selected check types is present in any of the selected languages.     
  --filterQaChecksStaleInLang: list # Filter keys whose QA checks are stale (pending recomputation) in lang. When set, only keys with at least one stale translation in any of the provided languages are returned.
  --filterHasSuggestionsInLang: list # Filter keys with any suggestions in lang
  --filterHasNoSuggestionsInLang: list # Filter keys with no suggestions in lang
  --branch: string # Selects only keys from specified branch
  --filterDeletedByUserId: list # Filter trashed keys by who deleted them (user IDs)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterState" $filterState "multi") (serialize-qp "languages" $languages "multi") (serialize-qp "search" $search "scalar") (serialize-qp "filterKeyName" $filterKeyName "multi") (serialize-qp "filterKeyId" $filterKeyId "multi") (serialize-qp "filterUntranslatedAny" $filterUntranslatedAny "scalar") (serialize-qp "filterTranslatedAny" $filterTranslatedAny "scalar") (serialize-qp "filterUntranslatedInLang" $filterUntranslatedInLang "scalar") (serialize-qp "filterTranslatedInLang" $filterTranslatedInLang "scalar") (serialize-qp "filterAutoTranslatedInLang" $filterAutoTranslatedInLang "multi") (serialize-qp "filterHasScreenshot" $filterHasScreenshot "scalar") (serialize-qp "filterHasNoScreenshot" $filterHasNoScreenshot "scalar") (serialize-qp "filterNamespace" $filterNamespace "multi") (serialize-qp "filterNoNamespace" $filterNoNamespace "multi") (serialize-qp "filterTag" $filterTag "multi") (serialize-qp "filterNoTag" $filterNoTag "multi") (serialize-qp "filterOutdatedLanguage" $filterOutdatedLanguage "multi") (serialize-qp "filterNotOutdatedLanguage" $filterNotOutdatedLanguage "multi") (serialize-qp "filterRevisionId" $filterRevisionId "multi") (serialize-qp "filterFailedKeysOfJob" $filterFailedKeysOfJob "scalar") (serialize-qp "filterTaskNumber" $filterTaskNumber "multi") (serialize-qp "filterTaskKeysNotDone" $filterTaskKeysNotDone "scalar") (serialize-qp "filterTaskKeysDone" $filterTaskKeysDone "scalar") (serialize-qp "filterHasUnresolvedCommentsInLang" $filterHasUnresolvedCommentsInLang "multi") (serialize-qp "filterHasCommentsInLang" $filterHasCommentsInLang "multi") (serialize-qp "filterLabel" $filterLabel "multi") (serialize-qp "filterHasQaIssuesInLang" $filterHasQaIssuesInLang "multi") (serialize-qp "filterQaCheckType" $filterQaCheckType "multi") (serialize-qp "filterQaChecksStaleInLang" $filterQaChecksStaleInLang "multi") (serialize-qp "filterHasSuggestionsInLang" $filterHasSuggestionsInLang "multi") (serialize-qp "filterHasNoSuggestionsInLang" $filterHasNoSuggestionsInLang "multi") (serialize-qp "branch" $branch "scalar") (serialize-qp "filterDeletedByUserId" $filterDeletedByUserId "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/select" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Select keys
#
# GET /v2/projects/keys/select
# operationId: selectKeys_3
export def "projects-keys-select selectKeys-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterState: list # Translation state in the format: languageTag,state. You can use this parameter multiple times.  When used with multiple states for same language it is applied with logical OR.    When used with multiple languages, it is applied with logical AND.     
  --languages: list # Languages to be contained in response.                  To add multiple languages, repeat this param (eg. ?languages=en&languages=de) (e.g. en)
  --search: string # String to search in key name or translation text
  --filterKeyName: list # Selects key with provided names. Use this param multiple times to fetch more keys.
  --filterKeyId: list # Selects key with provided ID. Use this param multiple times to fetch more keys.
  --filterUntranslatedAny: string@bool-completer # Selects only keys for which the translation is missing in any returned language. It only filters for translations included in returned languages.
  --filterTranslatedAny: string@bool-completer # Selects only keys, where translation is provided in any language
  --filterUntranslatedInLang: string # Selects only keys where the translation is missing for the specified language. The specified language must be included in the returned languages. Otherwise, this filter doesn't apply. (e.g. en-US)
  --filterTranslatedInLang: string # Selects only keys, where translation is provided in specified language (e.g. en-US)
  --filterAutoTranslatedInLang: list # Selects only keys, where translation was auto translated for specified languages. (e.g. en-US)
  --filterHasScreenshot: string@bool-completer # Selects only keys with screenshots
  --filterHasNoScreenshot: string@bool-completer # Selects only keys without screenshots
  --filterNamespace: list # Selects only keys with provided namespaces.   To filter default namespace, set to empty string.   
  --filterNoNamespace: list # Selects only keys without provided namespaces.   To filter default namespace, set to empty string.   
  --filterTag: list # Selects only keys with provided tag
  --filterNoTag: list # Selects only keys without provided tag
  --filterOutdatedLanguage: list # Selects only keys, where translation in provided langs is in outdated state (e.g. en-US)
  --filterNotOutdatedLanguage: list # Selects only keys, where translation in provided langs is not in outdated state (e.g. en-US)
  --filterRevisionId: list # Selects only key affected by activity with specidfied revision ID (e.g. 1234567)
  --filterFailedKeysOfJob: int # Select only keys which were not successfully translated by batch job with provided id (format: int64)
  --filterTaskNumber: list # Select only keys which are in specified task
  --filterTaskKeysNotDone: string@bool-completer # Filter task keys which are `not done`
  --filterTaskKeysDone: string@bool-completer # Filter task keys which are `done`
  --filterHasUnresolvedCommentsInLang: list # Filter keys with unresolved comments in lang
  --filterHasCommentsInLang: list # Filter keys with any comments in lang
  --filterLabel: list # Filter key translations with labels (e.g. labelId1,labelId2)
  --filterHasQaIssuesInLang: list # Filter keys with open QA issues in lang
  --filterQaCheckType: list # Filter keys with specific QA check type issues in the format: languageTag,checkType. You can use this parameter multiple times.  A key matches if any of the selected check types is present in any of the selected languages.     
  --filterQaChecksStaleInLang: list # Filter keys whose QA checks are stale (pending recomputation) in lang. When set, only keys with at least one stale translation in any of the provided languages are returned.
  --filterHasSuggestionsInLang: list # Filter keys with any suggestions in lang
  --filterHasNoSuggestionsInLang: list # Filter keys with no suggestions in lang
  --branch: string # Selects only keys from specified branch
  --filterDeletedByUserId: list # Filter trashed keys by who deleted them (user IDs)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterState" $filterState "multi") (serialize-qp "languages" $languages "multi") (serialize-qp "search" $search "scalar") (serialize-qp "filterKeyName" $filterKeyName "multi") (serialize-qp "filterKeyId" $filterKeyId "multi") (serialize-qp "filterUntranslatedAny" $filterUntranslatedAny "scalar") (serialize-qp "filterTranslatedAny" $filterTranslatedAny "scalar") (serialize-qp "filterUntranslatedInLang" $filterUntranslatedInLang "scalar") (serialize-qp "filterTranslatedInLang" $filterTranslatedInLang "scalar") (serialize-qp "filterAutoTranslatedInLang" $filterAutoTranslatedInLang "multi") (serialize-qp "filterHasScreenshot" $filterHasScreenshot "scalar") (serialize-qp "filterHasNoScreenshot" $filterHasNoScreenshot "scalar") (serialize-qp "filterNamespace" $filterNamespace "multi") (serialize-qp "filterNoNamespace" $filterNoNamespace "multi") (serialize-qp "filterTag" $filterTag "multi") (serialize-qp "filterNoTag" $filterNoTag "multi") (serialize-qp "filterOutdatedLanguage" $filterOutdatedLanguage "multi") (serialize-qp "filterNotOutdatedLanguage" $filterNotOutdatedLanguage "multi") (serialize-qp "filterRevisionId" $filterRevisionId "multi") (serialize-qp "filterFailedKeysOfJob" $filterFailedKeysOfJob "scalar") (serialize-qp "filterTaskNumber" $filterTaskNumber "multi") (serialize-qp "filterTaskKeysNotDone" $filterTaskKeysNotDone "scalar") (serialize-qp "filterTaskKeysDone" $filterTaskKeysDone "scalar") (serialize-qp "filterHasUnresolvedCommentsInLang" $filterHasUnresolvedCommentsInLang "multi") (serialize-qp "filterHasCommentsInLang" $filterHasCommentsInLang "multi") (serialize-qp "filterLabel" $filterLabel "multi") (serialize-qp "filterHasQaIssuesInLang" $filterHasQaIssuesInLang "multi") (serialize-qp "filterQaCheckType" $filterQaCheckType "multi") (serialize-qp "filterQaChecksStaleInLang" $filterQaChecksStaleInLang "multi") (serialize-qp "filterHasSuggestionsInLang" $filterHasSuggestionsInLang "multi") (serialize-qp "filterHasNoSuggestionsInLang" $filterHasNoSuggestionsInLang "multi") (serialize-qp "branch" $branch "scalar") (serialize-qp "filterDeletedByUserId" $filterDeletedByUserId "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/keys/select" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all translation memory assignments for the project
#
# GET /v2/projects/{projectId}/translation-memories
# operationId: list_6
export def "projects-translation-memories list-by-projectId" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/translation-memories")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all translation memory assignments for the project
#
# GET /v2/projects/translation-memories
# operationId: list_7
export def "projects-translation-memories list-by-" [
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
  let full_url = (build-url $base "/v2/projects/translation-memories")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get transfer to organization options
#
# GET /v2/projects/{projectId}/transfer-options
# operationId: getTransferOptions
export def "projects-transfer-options get" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/transfer-options" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get report in XLSX
#
# GET /v2/projects/{projectId}/tasks/{taskNumber}/xlsx-report
# operationId: getXlsxReport
export def "projects-tasks-xlsx-report get" [
  taskNumber: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/tasks/($taskNumber)/xlsx-report")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get report in XLSX
#
# GET /v2/projects/tasks/{taskNumber}/xlsx-report
# operationId: getXlsxReport_1
export def "projects-tasks-xlsx-report get-by-taskNumber" [
  taskNumber: int
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
  let full_url = (build-url $base $"/v2/projects/tasks/($taskNumber)/xlsx-report")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get report
#
# GET /v2/projects/{projectId}/tasks/{taskNumber}/per-user-report
# operationId: getPerUserReport
export def "projects-tasks-per-user-report get" [
  taskNumber: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/tasks/($taskNumber)/per-user-report")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get report
#
# GET /v2/projects/tasks/{taskNumber}/per-user-report
# operationId: getPerUserReport_1
export def "projects-tasks-per-user-report get-by-taskNumber" [
  taskNumber: int
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
  let full_url = (build-url $base $"/v2/projects/tasks/($taskNumber)/per-user-report")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get blocking task numbers
#
# GET /v2/projects/{projectId}/tasks/{taskNumber}/blocking-tasks
# operationId: getBlockingTasks
export def "projects-tasks-blocking-tasks get" [
  taskNumber: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/tasks/($taskNumber)/blocking-tasks")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get blocking task numbers
#
# GET /v2/projects/tasks/{taskNumber}/blocking-tasks
# operationId: getBlockingTasks_1
export def "projects-tasks-blocking-tasks get-by-taskNumber" [
  taskNumber: int
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
  let full_url = (build-url $base $"/v2/projects/tasks/($taskNumber)/blocking-tasks")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get possible assignees
#
# GET /v2/projects/{projectId}/tasks/possible-assignees
# operationId: getPossibleAssignees
export def "projects-tasks-possible-assignees get" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterId: list # Filter users by id
  --filterMinimalScope: string # Filter only users that have at least following scopes
  --filterViewLanguageId: int # Filter only users that can view language (format: int64)
  --filterEditLanguageId: int # Filter only users that can edit language (format: int64)
  --filterStateLanguageId: int # Filter only users that can edit state of language (format: int64)
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterId" $filterId "multi") (serialize-qp "filterMinimalScope" $filterMinimalScope "scalar") (serialize-qp "filterViewLanguageId" $filterViewLanguageId "scalar") (serialize-qp "filterEditLanguageId" $filterEditLanguageId "scalar") (serialize-qp "filterStateLanguageId" $filterStateLanguageId "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/tasks/possible-assignees" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get possible assignees
#
# GET /v2/projects/tasks/possible-assignees
# operationId: getPossibleAssignees_1
export def "projects-tasks-possible-assignees get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterId: list # Filter users by id
  --filterMinimalScope: string # Filter only users that have at least following scopes
  --filterViewLanguageId: int # Filter only users that can view language (format: int64)
  --filterEditLanguageId: int # Filter only users that can edit language (format: int64)
  --filterStateLanguageId: int # Filter only users that can edit state of language (format: int64)
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterId" $filterId "multi") (serialize-qp "filterMinimalScope" $filterMinimalScope "scalar") (serialize-qp "filterViewLanguageId" $filterViewLanguageId "scalar") (serialize-qp "filterEditLanguageId" $filterEditLanguageId "scalar") (serialize-qp "filterStateLanguageId" $filterStateLanguageId "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/tasks/possible-assignees" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get QA issue counts grouped by check type for a language
#
# GET /v2/projects/{projectId}/stats/qa-issue-counts
# operationId: getQaIssueCountsByCheckType
export def "projects-stats-qa-issue-counts get" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --languageId: int # format: int64
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languageId" $languageId "scalar") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/stats/qa-issue-counts" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get QA issue counts grouped by check type for a language
#
# GET /v2/projects/stats/qa-issue-counts
# operationId: getQaIssueCountsByCheckType_1
export def "projects-stats-qa-issue-counts get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --languageId: int # format: int64
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languageId" $languageId "scalar") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/stats/qa-issue-counts" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project daily amount of events
#
# GET /v2/projects/{projectId}/stats/daily-activity
# operationId: getProjectDailyActivity
export def "projects-stats-daily-activity get" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/stats/daily-activity")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project daily amount of events
#
# GET /v2/projects/stats/daily-activity
# operationId: getProjectDailyActivity_1
export def "projects-stats-daily-activity get-by-" [
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
  let full_url = (build-url $base "/v2/projects/stats/daily-activity")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project stats
#
# GET /v2/projects/{projectId}/stats
# operationId: getProjectStats
export def "projects-stats get" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
]: nothing -> record<projectId: int, languageCount: int, keyCount: int, taskCount: int, baseWordsCount: int, translatedPercentage: float, reviewedPercentage: float, membersCount: int, tagCount: int, languageStats: table<languageId: int, languageTag: string, languageName: string, languageOriginalName: string, languageFlagEmoji: string, translatedKeyCount: int, translatedWordCount: int, translatedPercentage: float, reviewedKeyCount: int, reviewedWordCount: int, reviewedPercentage: float, untranslatedKeyCount: int, untranslatedWordCount: int, untranslatedPercentage: float, translationsUpdatedAt: string, qaIssueCount: int, qaChecksStaleCount: int, _links: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project stats
#
# GET /v2/projects/stats
# operationId: getProjectStats_1
export def "projects-stats get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
]: nothing -> record<projectId: int, languageCount: int, keyCount: int, taskCount: int, baseWordsCount: int, translatedPercentage: float, reviewedPercentage: float, membersCount: int, tagCount: int, languageStats: table<languageId: int, languageTag: string, languageName: string, languageOriginalName: string, languageFlagEmoji: string, translatedKeyCount: int, translatedWordCount: int, translatedPercentage: float, reviewedKeyCount: int, reviewedWordCount: int, reviewedPercentage: float, untranslatedKeyCount: int, untranslatedWordCount: int, untranslatedPercentage: float, translationsUpdatedAt: string, qaIssueCount: int, qaChecksStaleCount: int, _links: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get per-language QA settings overrides for all project languages
#
# GET /v2/projects/{projectId}/qa-settings/languages
# operationId: getAllLanguageSettings
export def "projects-qa-settings-languages list" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/qa-settings/languages")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get resolved QA settings for a specific language
#
# GET /v2/projects/{projectId}/qa-settings/languages/{languageId}/resolved
# operationId: getLanguageSettingsResolved
export def "projects-qa-settings-languages-resolved get" [
  languageId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/qa-settings/languages/($languageId)/resolved")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get QA check types grouped by category
#
# GET /v2/projects/{projectId}/qa-settings/check-types
# operationId: getCheckTypes
export def "projects-qa-settings-check-types get" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/qa-settings/check-types")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get namespaces
#
# GET /v2/projects/{projectId}/namespaces
# operationId: getAllNamespaces_2
export def "projects-namespaces get-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [id,ASC])
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/namespaces" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get namespaces
#
# GET /v2/projects/namespaces
# operationId: getAllNamespaces_3
export def "projects-namespaces get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [id,ASC])
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/namespaces" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get namespace by name
#
# GET /v2/projects/{projectId}/namespace-by-name/{name}
# operationId: getByName
export def "projects-namespace-by-name get" [
  name: string
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/namespace-by-name/($name)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get namespace by name
#
# GET /v2/projects/namespace-by-name/{name}
# operationId: getByName_1
export def "projects-namespace-by-name get-by-name" [
  name: string
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
  let full_url = (build-url $base $"/v2/projects/namespace-by-name/($name)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Machine translation info
#
# GET /v2/projects/{projectId}/machine-translation-language-info
# operationId: getMachineTranslationLanguageInfo
export def "projects-machine-translation-language-info get" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/machine-translation-language-info")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns language level prompt customization
#
# GET /v2/projects/{projectId}/language-ai-prompt-customizations
# operationId: getLanguagePromptCustomizations
export def "projects-language-ai-prompt-customizations get" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/language-ai-prompt-customizations")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Select all trashed key IDs matching the filter
#
# GET /v2/projects/{projectId}/keys/trash/select-all
# operationId: selectAll
export def "projects-keys-trash-select-all selectAll" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterState: list # Translation state in the format: languageTag,state. You can use this parameter multiple times.  When used with multiple states for same language it is applied with logical OR.    When used with multiple languages, it is applied with logical AND.     
  --languages: list # Languages to be contained in response.                  To add multiple languages, repeat this param (eg. ?languages=en&languages=de) (e.g. en)
  --search: string # String to search in key name or translation text
  --filterKeyName: list # Selects key with provided names. Use this param multiple times to fetch more keys.
  --filterKeyId: list # Selects key with provided ID. Use this param multiple times to fetch more keys.
  --filterUntranslatedAny: string@bool-completer # Selects only keys for which the translation is missing in any returned language. It only filters for translations included in returned languages.
  --filterTranslatedAny: string@bool-completer # Selects only keys, where translation is provided in any language
  --filterUntranslatedInLang: string # Selects only keys where the translation is missing for the specified language. The specified language must be included in the returned languages. Otherwise, this filter doesn't apply. (e.g. en-US)
  --filterTranslatedInLang: string # Selects only keys, where translation is provided in specified language (e.g. en-US)
  --filterAutoTranslatedInLang: list # Selects only keys, where translation was auto translated for specified languages. (e.g. en-US)
  --filterHasScreenshot: string@bool-completer # Selects only keys with screenshots
  --filterHasNoScreenshot: string@bool-completer # Selects only keys without screenshots
  --filterNamespace: list # Selects only keys with provided namespaces.   To filter default namespace, set to empty string.   
  --filterNoNamespace: list # Selects only keys without provided namespaces.   To filter default namespace, set to empty string.   
  --filterTag: list # Selects only keys with provided tag
  --filterNoTag: list # Selects only keys without provided tag
  --filterOutdatedLanguage: list # Selects only keys, where translation in provided langs is in outdated state (e.g. en-US)
  --filterNotOutdatedLanguage: list # Selects only keys, where translation in provided langs is not in outdated state (e.g. en-US)
  --filterRevisionId: list # Selects only key affected by activity with specidfied revision ID (e.g. 1234567)
  --filterFailedKeysOfJob: int # Select only keys which were not successfully translated by batch job with provided id (format: int64)
  --filterTaskNumber: list # Select only keys which are in specified task
  --filterTaskKeysNotDone: string@bool-completer # Filter task keys which are `not done`
  --filterTaskKeysDone: string@bool-completer # Filter task keys which are `done`
  --filterHasUnresolvedCommentsInLang: list # Filter keys with unresolved comments in lang
  --filterHasCommentsInLang: list # Filter keys with any comments in lang
  --filterLabel: list # Filter key translations with labels (e.g. labelId1,labelId2)
  --filterHasQaIssuesInLang: list # Filter keys with open QA issues in lang
  --filterQaCheckType: list # Filter keys with specific QA check type issues in the format: languageTag,checkType. You can use this parameter multiple times.  A key matches if any of the selected check types is present in any of the selected languages.     
  --filterQaChecksStaleInLang: list # Filter keys whose QA checks are stale (pending recomputation) in lang. When set, only keys with at least one stale translation in any of the provided languages are returned.
  --filterHasSuggestionsInLang: list # Filter keys with any suggestions in lang
  --filterHasNoSuggestionsInLang: list # Filter keys with no suggestions in lang
  --branch: string # Selects only keys from specified branch
  --filterDeletedByUserId: list # Filter trashed keys by who deleted them (user IDs)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterState" $filterState "multi") (serialize-qp "languages" $languages "multi") (serialize-qp "search" $search "scalar") (serialize-qp "filterKeyName" $filterKeyName "multi") (serialize-qp "filterKeyId" $filterKeyId "multi") (serialize-qp "filterUntranslatedAny" $filterUntranslatedAny "scalar") (serialize-qp "filterTranslatedAny" $filterTranslatedAny "scalar") (serialize-qp "filterUntranslatedInLang" $filterUntranslatedInLang "scalar") (serialize-qp "filterTranslatedInLang" $filterTranslatedInLang "scalar") (serialize-qp "filterAutoTranslatedInLang" $filterAutoTranslatedInLang "multi") (serialize-qp "filterHasScreenshot" $filterHasScreenshot "scalar") (serialize-qp "filterHasNoScreenshot" $filterHasNoScreenshot "scalar") (serialize-qp "filterNamespace" $filterNamespace "multi") (serialize-qp "filterNoNamespace" $filterNoNamespace "multi") (serialize-qp "filterTag" $filterTag "multi") (serialize-qp "filterNoTag" $filterNoTag "multi") (serialize-qp "filterOutdatedLanguage" $filterOutdatedLanguage "multi") (serialize-qp "filterNotOutdatedLanguage" $filterNotOutdatedLanguage "multi") (serialize-qp "filterRevisionId" $filterRevisionId "multi") (serialize-qp "filterFailedKeysOfJob" $filterFailedKeysOfJob "scalar") (serialize-qp "filterTaskNumber" $filterTaskNumber "multi") (serialize-qp "filterTaskKeysNotDone" $filterTaskKeysNotDone "scalar") (serialize-qp "filterTaskKeysDone" $filterTaskKeysDone "scalar") (serialize-qp "filterHasUnresolvedCommentsInLang" $filterHasUnresolvedCommentsInLang "multi") (serialize-qp "filterHasCommentsInLang" $filterHasCommentsInLang "multi") (serialize-qp "filterLabel" $filterLabel "multi") (serialize-qp "filterHasQaIssuesInLang" $filterHasQaIssuesInLang "multi") (serialize-qp "filterQaCheckType" $filterQaCheckType "multi") (serialize-qp "filterQaChecksStaleInLang" $filterQaChecksStaleInLang "multi") (serialize-qp "filterHasSuggestionsInLang" $filterHasSuggestionsInLang "multi") (serialize-qp "filterHasNoSuggestionsInLang" $filterHasNoSuggestionsInLang "multi") (serialize-qp "branch" $branch "scalar") (serialize-qp "filterDeletedByUserId" $filterDeletedByUserId "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/trash/select-all" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Select all trashed key IDs matching the filter
#
# GET /v2/projects/keys/trash/select-all
# operationId: selectAll_1
export def "projects-keys-trash-select-all selectAll-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterState: list # Translation state in the format: languageTag,state. You can use this parameter multiple times.  When used with multiple states for same language it is applied with logical OR.    When used with multiple languages, it is applied with logical AND.     
  --languages: list # Languages to be contained in response.                  To add multiple languages, repeat this param (eg. ?languages=en&languages=de) (e.g. en)
  --search: string # String to search in key name or translation text
  --filterKeyName: list # Selects key with provided names. Use this param multiple times to fetch more keys.
  --filterKeyId: list # Selects key with provided ID. Use this param multiple times to fetch more keys.
  --filterUntranslatedAny: string@bool-completer # Selects only keys for which the translation is missing in any returned language. It only filters for translations included in returned languages.
  --filterTranslatedAny: string@bool-completer # Selects only keys, where translation is provided in any language
  --filterUntranslatedInLang: string # Selects only keys where the translation is missing for the specified language. The specified language must be included in the returned languages. Otherwise, this filter doesn't apply. (e.g. en-US)
  --filterTranslatedInLang: string # Selects only keys, where translation is provided in specified language (e.g. en-US)
  --filterAutoTranslatedInLang: list # Selects only keys, where translation was auto translated for specified languages. (e.g. en-US)
  --filterHasScreenshot: string@bool-completer # Selects only keys with screenshots
  --filterHasNoScreenshot: string@bool-completer # Selects only keys without screenshots
  --filterNamespace: list # Selects only keys with provided namespaces.   To filter default namespace, set to empty string.   
  --filterNoNamespace: list # Selects only keys without provided namespaces.   To filter default namespace, set to empty string.   
  --filterTag: list # Selects only keys with provided tag
  --filterNoTag: list # Selects only keys without provided tag
  --filterOutdatedLanguage: list # Selects only keys, where translation in provided langs is in outdated state (e.g. en-US)
  --filterNotOutdatedLanguage: list # Selects only keys, where translation in provided langs is not in outdated state (e.g. en-US)
  --filterRevisionId: list # Selects only key affected by activity with specidfied revision ID (e.g. 1234567)
  --filterFailedKeysOfJob: int # Select only keys which were not successfully translated by batch job with provided id (format: int64)
  --filterTaskNumber: list # Select only keys which are in specified task
  --filterTaskKeysNotDone: string@bool-completer # Filter task keys which are `not done`
  --filterTaskKeysDone: string@bool-completer # Filter task keys which are `done`
  --filterHasUnresolvedCommentsInLang: list # Filter keys with unresolved comments in lang
  --filterHasCommentsInLang: list # Filter keys with any comments in lang
  --filterLabel: list # Filter key translations with labels (e.g. labelId1,labelId2)
  --filterHasQaIssuesInLang: list # Filter keys with open QA issues in lang
  --filterQaCheckType: list # Filter keys with specific QA check type issues in the format: languageTag,checkType. You can use this parameter multiple times.  A key matches if any of the selected check types is present in any of the selected languages.     
  --filterQaChecksStaleInLang: list # Filter keys whose QA checks are stale (pending recomputation) in lang. When set, only keys with at least one stale translation in any of the provided languages are returned.
  --filterHasSuggestionsInLang: list # Filter keys with any suggestions in lang
  --filterHasNoSuggestionsInLang: list # Filter keys with no suggestions in lang
  --branch: string # Selects only keys from specified branch
  --filterDeletedByUserId: list # Filter trashed keys by who deleted them (user IDs)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterState" $filterState "multi") (serialize-qp "languages" $languages "multi") (serialize-qp "search" $search "scalar") (serialize-qp "filterKeyName" $filterKeyName "multi") (serialize-qp "filterKeyId" $filterKeyId "multi") (serialize-qp "filterUntranslatedAny" $filterUntranslatedAny "scalar") (serialize-qp "filterTranslatedAny" $filterTranslatedAny "scalar") (serialize-qp "filterUntranslatedInLang" $filterUntranslatedInLang "scalar") (serialize-qp "filterTranslatedInLang" $filterTranslatedInLang "scalar") (serialize-qp "filterAutoTranslatedInLang" $filterAutoTranslatedInLang "multi") (serialize-qp "filterHasScreenshot" $filterHasScreenshot "scalar") (serialize-qp "filterHasNoScreenshot" $filterHasNoScreenshot "scalar") (serialize-qp "filterNamespace" $filterNamespace "multi") (serialize-qp "filterNoNamespace" $filterNoNamespace "multi") (serialize-qp "filterTag" $filterTag "multi") (serialize-qp "filterNoTag" $filterNoTag "multi") (serialize-qp "filterOutdatedLanguage" $filterOutdatedLanguage "multi") (serialize-qp "filterNotOutdatedLanguage" $filterNotOutdatedLanguage "multi") (serialize-qp "filterRevisionId" $filterRevisionId "multi") (serialize-qp "filterFailedKeysOfJob" $filterFailedKeysOfJob "scalar") (serialize-qp "filterTaskNumber" $filterTaskNumber "multi") (serialize-qp "filterTaskKeysNotDone" $filterTaskKeysNotDone "scalar") (serialize-qp "filterTaskKeysDone" $filterTaskKeysDone "scalar") (serialize-qp "filterHasUnresolvedCommentsInLang" $filterHasUnresolvedCommentsInLang "multi") (serialize-qp "filterHasCommentsInLang" $filterHasCommentsInLang "multi") (serialize-qp "filterLabel" $filterLabel "multi") (serialize-qp "filterHasQaIssuesInLang" $filterHasQaIssuesInLang "multi") (serialize-qp "filterQaCheckType" $filterQaCheckType "multi") (serialize-qp "filterQaChecksStaleInLang" $filterQaChecksStaleInLang "multi") (serialize-qp "filterHasSuggestionsInLang" $filterHasSuggestionsInLang "multi") (serialize-qp "filterHasNoSuggestionsInLang" $filterHasNoSuggestionsInLang "multi") (serialize-qp "branch" $branch "scalar") (serialize-qp "filterDeletedByUserId" $filterDeletedByUserId "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/keys/trash/select-all" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users who deleted keys
#
# GET /v2/projects/{projectId}/keys/trash/deleters
# operationId: listDeleters
export def "projects-keys-trash-deleters listDeleters" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/trash/deleters" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users who deleted keys
#
# GET /v2/projects/keys/trash/deleters
# operationId: listDeleters_1
export def "projects-keys-trash-deleters listDeleters-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/keys/trash/deleters" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List trashed keys
#
# GET /v2/projects/{projectId}/keys/trash
# operationId: list_8
export def "projects-keys-trash list-by-projectId" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [deletedAt,ASC])
  --filterState: list # Translation state in the format: languageTag,state. You can use this parameter multiple times.  When used with multiple states for same language it is applied with logical OR.    When used with multiple languages, it is applied with logical AND.     
  --languages: list # Languages to be contained in response.                  To add multiple languages, repeat this param (eg. ?languages=en&languages=de) (e.g. en)
  --search: string # String to search in key name or translation text
  --filterKeyName: list # Selects key with provided names. Use this param multiple times to fetch more keys.
  --filterKeyId: list # Selects key with provided ID. Use this param multiple times to fetch more keys.
  --filterUntranslatedAny: string@bool-completer # Selects only keys for which the translation is missing in any returned language. It only filters for translations included in returned languages.
  --filterTranslatedAny: string@bool-completer # Selects only keys, where translation is provided in any language
  --filterUntranslatedInLang: string # Selects only keys where the translation is missing for the specified language. The specified language must be included in the returned languages. Otherwise, this filter doesn't apply. (e.g. en-US)
  --filterTranslatedInLang: string # Selects only keys, where translation is provided in specified language (e.g. en-US)
  --filterAutoTranslatedInLang: list # Selects only keys, where translation was auto translated for specified languages. (e.g. en-US)
  --filterHasScreenshot: string@bool-completer # Selects only keys with screenshots
  --filterHasNoScreenshot: string@bool-completer # Selects only keys without screenshots
  --filterNamespace: list # Selects only keys with provided namespaces.   To filter default namespace, set to empty string.   
  --filterNoNamespace: list # Selects only keys without provided namespaces.   To filter default namespace, set to empty string.   
  --filterTag: list # Selects only keys with provided tag
  --filterNoTag: list # Selects only keys without provided tag
  --filterOutdatedLanguage: list # Selects only keys, where translation in provided langs is in outdated state (e.g. en-US)
  --filterNotOutdatedLanguage: list # Selects only keys, where translation in provided langs is not in outdated state (e.g. en-US)
  --filterRevisionId: list # Selects only key affected by activity with specidfied revision ID (e.g. 1234567)
  --filterFailedKeysOfJob: int # Select only keys which were not successfully translated by batch job with provided id (format: int64)
  --filterTaskNumber: list # Select only keys which are in specified task
  --filterTaskKeysNotDone: string@bool-completer # Filter task keys which are `not done`
  --filterTaskKeysDone: string@bool-completer # Filter task keys which are `done`
  --filterHasUnresolvedCommentsInLang: list # Filter keys with unresolved comments in lang
  --filterHasCommentsInLang: list # Filter keys with any comments in lang
  --filterLabel: list # Filter key translations with labels (e.g. labelId1,labelId2)
  --filterHasQaIssuesInLang: list # Filter keys with open QA issues in lang
  --filterQaCheckType: list # Filter keys with specific QA check type issues in the format: languageTag,checkType. You can use this parameter multiple times.  A key matches if any of the selected check types is present in any of the selected languages.     
  --filterQaChecksStaleInLang: list # Filter keys whose QA checks are stale (pending recomputation) in lang. When set, only keys with at least one stale translation in any of the provided languages are returned.
  --filterHasSuggestionsInLang: list # Filter keys with any suggestions in lang
  --filterHasNoSuggestionsInLang: list # Filter keys with no suggestions in lang
  --branch: string # Selects only keys from specified branch
  --filterDeletedByUserId: list # Filter trashed keys by who deleted them (user IDs)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "filterState" $filterState "multi") (serialize-qp "languages" $languages "multi") (serialize-qp "search" $search "scalar") (serialize-qp "filterKeyName" $filterKeyName "multi") (serialize-qp "filterKeyId" $filterKeyId "multi") (serialize-qp "filterUntranslatedAny" $filterUntranslatedAny "scalar") (serialize-qp "filterTranslatedAny" $filterTranslatedAny "scalar") (serialize-qp "filterUntranslatedInLang" $filterUntranslatedInLang "scalar") (serialize-qp "filterTranslatedInLang" $filterTranslatedInLang "scalar") (serialize-qp "filterAutoTranslatedInLang" $filterAutoTranslatedInLang "multi") (serialize-qp "filterHasScreenshot" $filterHasScreenshot "scalar") (serialize-qp "filterHasNoScreenshot" $filterHasNoScreenshot "scalar") (serialize-qp "filterNamespace" $filterNamespace "multi") (serialize-qp "filterNoNamespace" $filterNoNamespace "multi") (serialize-qp "filterTag" $filterTag "multi") (serialize-qp "filterNoTag" $filterNoTag "multi") (serialize-qp "filterOutdatedLanguage" $filterOutdatedLanguage "multi") (serialize-qp "filterNotOutdatedLanguage" $filterNotOutdatedLanguage "multi") (serialize-qp "filterRevisionId" $filterRevisionId "multi") (serialize-qp "filterFailedKeysOfJob" $filterFailedKeysOfJob "scalar") (serialize-qp "filterTaskNumber" $filterTaskNumber "multi") (serialize-qp "filterTaskKeysNotDone" $filterTaskKeysNotDone "scalar") (serialize-qp "filterTaskKeysDone" $filterTaskKeysDone "scalar") (serialize-qp "filterHasUnresolvedCommentsInLang" $filterHasUnresolvedCommentsInLang "multi") (serialize-qp "filterHasCommentsInLang" $filterHasCommentsInLang "multi") (serialize-qp "filterLabel" $filterLabel "multi") (serialize-qp "filterHasQaIssuesInLang" $filterHasQaIssuesInLang "multi") (serialize-qp "filterQaCheckType" $filterQaCheckType "multi") (serialize-qp "filterQaChecksStaleInLang" $filterQaChecksStaleInLang "multi") (serialize-qp "filterHasSuggestionsInLang" $filterHasSuggestionsInLang "multi") (serialize-qp "filterHasNoSuggestionsInLang" $filterHasNoSuggestionsInLang "multi") (serialize-qp "branch" $branch "scalar") (serialize-qp "filterDeletedByUserId" $filterDeletedByUserId "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/trash" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List trashed keys
#
# GET /v2/projects/keys/trash
# operationId: list_9
export def "projects-keys-trash list-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [deletedAt,ASC])
  --filterState: list # Translation state in the format: languageTag,state. You can use this parameter multiple times.  When used with multiple states for same language it is applied with logical OR.    When used with multiple languages, it is applied with logical AND.     
  --languages: list # Languages to be contained in response.                  To add multiple languages, repeat this param (eg. ?languages=en&languages=de) (e.g. en)
  --search: string # String to search in key name or translation text
  --filterKeyName: list # Selects key with provided names. Use this param multiple times to fetch more keys.
  --filterKeyId: list # Selects key with provided ID. Use this param multiple times to fetch more keys.
  --filterUntranslatedAny: string@bool-completer # Selects only keys for which the translation is missing in any returned language. It only filters for translations included in returned languages.
  --filterTranslatedAny: string@bool-completer # Selects only keys, where translation is provided in any language
  --filterUntranslatedInLang: string # Selects only keys where the translation is missing for the specified language. The specified language must be included in the returned languages. Otherwise, this filter doesn't apply. (e.g. en-US)
  --filterTranslatedInLang: string # Selects only keys, where translation is provided in specified language (e.g. en-US)
  --filterAutoTranslatedInLang: list # Selects only keys, where translation was auto translated for specified languages. (e.g. en-US)
  --filterHasScreenshot: string@bool-completer # Selects only keys with screenshots
  --filterHasNoScreenshot: string@bool-completer # Selects only keys without screenshots
  --filterNamespace: list # Selects only keys with provided namespaces.   To filter default namespace, set to empty string.   
  --filterNoNamespace: list # Selects only keys without provided namespaces.   To filter default namespace, set to empty string.   
  --filterTag: list # Selects only keys with provided tag
  --filterNoTag: list # Selects only keys without provided tag
  --filterOutdatedLanguage: list # Selects only keys, where translation in provided langs is in outdated state (e.g. en-US)
  --filterNotOutdatedLanguage: list # Selects only keys, where translation in provided langs is not in outdated state (e.g. en-US)
  --filterRevisionId: list # Selects only key affected by activity with specidfied revision ID (e.g. 1234567)
  --filterFailedKeysOfJob: int # Select only keys which were not successfully translated by batch job with provided id (format: int64)
  --filterTaskNumber: list # Select only keys which are in specified task
  --filterTaskKeysNotDone: string@bool-completer # Filter task keys which are `not done`
  --filterTaskKeysDone: string@bool-completer # Filter task keys which are `done`
  --filterHasUnresolvedCommentsInLang: list # Filter keys with unresolved comments in lang
  --filterHasCommentsInLang: list # Filter keys with any comments in lang
  --filterLabel: list # Filter key translations with labels (e.g. labelId1,labelId2)
  --filterHasQaIssuesInLang: list # Filter keys with open QA issues in lang
  --filterQaCheckType: list # Filter keys with specific QA check type issues in the format: languageTag,checkType. You can use this parameter multiple times.  A key matches if any of the selected check types is present in any of the selected languages.     
  --filterQaChecksStaleInLang: list # Filter keys whose QA checks are stale (pending recomputation) in lang. When set, only keys with at least one stale translation in any of the provided languages are returned.
  --filterHasSuggestionsInLang: list # Filter keys with any suggestions in lang
  --filterHasNoSuggestionsInLang: list # Filter keys with no suggestions in lang
  --branch: string # Selects only keys from specified branch
  --filterDeletedByUserId: list # Filter trashed keys by who deleted them (user IDs)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "filterState" $filterState "multi") (serialize-qp "languages" $languages "multi") (serialize-qp "search" $search "scalar") (serialize-qp "filterKeyName" $filterKeyName "multi") (serialize-qp "filterKeyId" $filterKeyId "multi") (serialize-qp "filterUntranslatedAny" $filterUntranslatedAny "scalar") (serialize-qp "filterTranslatedAny" $filterTranslatedAny "scalar") (serialize-qp "filterUntranslatedInLang" $filterUntranslatedInLang "scalar") (serialize-qp "filterTranslatedInLang" $filterTranslatedInLang "scalar") (serialize-qp "filterAutoTranslatedInLang" $filterAutoTranslatedInLang "multi") (serialize-qp "filterHasScreenshot" $filterHasScreenshot "scalar") (serialize-qp "filterHasNoScreenshot" $filterHasNoScreenshot "scalar") (serialize-qp "filterNamespace" $filterNamespace "multi") (serialize-qp "filterNoNamespace" $filterNoNamespace "multi") (serialize-qp "filterTag" $filterTag "multi") (serialize-qp "filterNoTag" $filterNoTag "multi") (serialize-qp "filterOutdatedLanguage" $filterOutdatedLanguage "multi") (serialize-qp "filterNotOutdatedLanguage" $filterNotOutdatedLanguage "multi") (serialize-qp "filterRevisionId" $filterRevisionId "multi") (serialize-qp "filterFailedKeysOfJob" $filterFailedKeysOfJob "scalar") (serialize-qp "filterTaskNumber" $filterTaskNumber "multi") (serialize-qp "filterTaskKeysNotDone" $filterTaskKeysNotDone "scalar") (serialize-qp "filterTaskKeysDone" $filterTaskKeysDone "scalar") (serialize-qp "filterHasUnresolvedCommentsInLang" $filterHasUnresolvedCommentsInLang "multi") (serialize-qp "filterHasCommentsInLang" $filterHasCommentsInLang "multi") (serialize-qp "filterLabel" $filterLabel "multi") (serialize-qp "filterHasQaIssuesInLang" $filterHasQaIssuesInLang "multi") (serialize-qp "filterQaCheckType" $filterQaCheckType "multi") (serialize-qp "filterQaChecksStaleInLang" $filterQaChecksStaleInLang "multi") (serialize-qp "filterHasSuggestionsInLang" $filterHasSuggestionsInLang "multi") (serialize-qp "filterHasNoSuggestionsInLang" $filterHasNoSuggestionsInLang "multi") (serialize-qp "branch" $branch "scalar") (serialize-qp "filterDeletedByUserId" $filterDeletedByUserId "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/keys/trash" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for keys
#
# GET /v2/projects/{projectId}/keys/search
# operationId: searchForKey
export def "projects-keys-search searchForKey" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search query
  --languageTag: string # Language to search in
  --branch: string
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "languageTag" $languageTag "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/search" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for keys
#
# GET /v2/projects/keys/search
# operationId: searchForKey_1
export def "projects-keys-search searchForKey-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search query
  --languageTag: string # Language to search in
  --branch: string
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "languageTag" $languageTag "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/keys/search" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project invitations
#
# GET /v2/projects/{projectId}/invitations
# operationId: getProjectInvitations
export def "projects-invitations get" [
  projectId: int
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/invitations")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get glossaries assigned to project
#
# GET /v2/projects/{projectId}/glossaries
# operationId: getAssignedGlossaries
export def "projects-glossaries get" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/glossaries")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get branch merge session preview
#
# GET /v2/projects/{projectId}/branches/merge/{mergeId}/preview
# operationId: getBranchMergeSessionPreview
export def "projects-branches-merge-preview get" [
  mergeId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/branches/merge/($mergeId)/preview")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get branch merge session preview
#
# GET /v2/projects/branches/merge/{mergeId}/preview
# operationId: getBranchMergeSessionPreview_1
export def "projects-branches-merge-preview get-by-mergeId" [
  mergeId: int
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
  let full_url = (build-url $base $"/v2/projects/branches/merge/($mergeId)/preview")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get branch merge session conflicts
#
# GET /v2/projects/{projectId}/branches/merge/{mergeId}/conflicts
# operationId: getBranchMergeSessionConflicts
export def "projects-branches-merge-conflicts get" [
  mergeId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/branches/merge/($mergeId)/conflicts" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get branch merge session conflicts
#
# GET /v2/projects/branches/merge/{mergeId}/conflicts
# operationId: getBranchMergeSessionConflicts_1
export def "projects-branches-merge-conflicts get-by-mergeId" [
  mergeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/branches/merge/($mergeId)/conflicts" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get single branch merge session change
#
# GET /v2/projects/{projectId}/branches/merge/{mergeId}/changes/{changeId}
# operationId: getBranchMergeSessionChange
export def "projects-branches-merge-changes get" [
  mergeId: int
  changeId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/branches/merge/($mergeId)/changes/($changeId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get single branch merge session change
#
# GET /v2/projects/branches/merge/{mergeId}/changes/{changeId}
# operationId: getBranchMergeSessionChange_1
export def "projects-branches-merge-changes get-by-mergeId-changeId" [
  mergeId: int
  changeId: int
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
  let full_url = (build-url $base $"/v2/projects/branches/merge/($mergeId)/changes/($changeId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get branch merge session changes
#
# GET /v2/projects/{projectId}/branches/merge/{mergeId}/changes
# operationId: getBranchMergeSessionChanges
export def "projects-branches-merge-changes list" [
  mergeId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --type: string@type-completer-5
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/branches/merge/($mergeId)/changes" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get branch merge session changes
#
# GET /v2/projects/branches/merge/{mergeId}/changes
# operationId: getBranchMergeSessionChanges_1
export def "projects-branches-merge-changes get-by-mergeId" [
  mergeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --type: string@type-completer-5
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/branches/merge/($mergeId)/changes" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get branch merges
#
# GET /v2/projects/{projectId}/branches/merge
# operationId: getBranchMerges
export def "projects-branches-merge get" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/branches/merge" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get branch merges
#
# GET /v2/projects/branches/merge
# operationId: getBranchMerges_1
export def "projects-branches-merge get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/branches/merge" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get branch by name, or the default branch if name is not provided
#
# GET /v2/projects/{projectId}/branches/find
# operationId: find
export def "projects-branches-find find" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/branches/find" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get branch by name, or the default branch if name is not provided
#
# GET /v2/projects/branches/find
# operationId: find_1
export def "projects-branches-find find-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/branches/find" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all project API keys
#
# GET /v2/projects/{projectId}/api-keys
# operationId: allByProject
export def "projects-api-keys allByProject" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageable: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageable" $pageable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/api-keys" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all keys in project
#
# GET /v2/projects/{projectId}/all-keys
# operationId: getAllKeys
export def "projects-all-keys get" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/all-keys" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get disabled languages for all keys in project
#
# GET /v2/projects/{projectId}/all-keys-with-disabled-languages
# operationId: getDisabledLanguages_2
export def "projects-all-keys-with-disabled-languages get-by-projectId" [
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/all-keys-with-disabled-languages")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get modified entities in revision
#
# GET /v2/projects/{projectId}/activity/revisions/{revisionId}/modified-entities
# operationId: getModifiedEntitiesByRevision
export def "projects-activity-revisions-modified-entities get" [
  revisionId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --filterEntityClass: list # Filters results by specific entity class
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "filterEntityClass" $filterEntityClass "multi") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/activity/revisions/($revisionId)/modified-entities" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get modified entities in revision
#
# GET /v2/projects/activity/revisions/{revisionId}/modified-entities
# operationId: getModifiedEntitiesByRevision_1
export def "projects-activity-revisions-modified-entities get-by-revisionId" [
  revisionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --filterEntityClass: list # Filters results by specific entity class
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "filterEntityClass" $filterEntityClass "multi") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/activity/revisions/($revisionId)/modified-entities" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one revision data
#
# GET /v2/projects/{projectId}/activity/revisions/{revisionId}
# operationId: getSingleRevision
export def "projects-activity-revisions get" [
  revisionId: int
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/activity/revisions/($revisionId)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one revision data
#
# GET /v2/projects/activity/revisions/{revisionId}
# operationId: getSingleRevision_1
export def "projects-activity-revisions get-by-revisionId" [
  revisionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/activity/revisions/($revisionId)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project activity
#
# GET /v2/projects/{projectId}/activity
# operationId: getActivity
export def "projects-activity get" [
  projectId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectId)/activity" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project activity
#
# GET /v2/projects/activity
# operationId: getActivity_1
export def "projects-activity get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --branch: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/activity" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all with stats
#
# GET /v2/projects/with-stats
# operationId: getAllWithStatistics
export def "projects-with-stats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects/with-stats" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get preferred organization
#
# GET /v2/preferred-organization
# operationId: getPreferred
export def "preferred-organization get" [
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
  let full_url = (build-url $base "/v2/preferred-organization")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return current PAK
#
# GET /v2/pats/current
# operationId: getCurrent
export def "pats-current get" [
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
  let full_url = (build-url $base "/v2/pats/current")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization by slug
#
# GET /v2/organizations/{slug}
# operationId: get_25
export def "organizations get-by-slug" [
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
  let full_url = (build-url $base $"/v2/organizations/($slug)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all accessible projects (by slug)
#
# GET /v2/organizations/{slug}/projects
# operationId: getAllProjects
export def "organizations-projects get" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
  --filterId: list # Filter projects by id
  --filterNotId: list # Filter projects without id
  --filterBaseLanguageTag: string # Filter projects whose base language tag matches
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar") (serialize-qp "filterId" $filterId "multi") (serialize-qp "filterNotId" $filterNotId "multi") (serialize-qp "filterBaseLanguageTag" $filterBaseLanguageTag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($slug)/projects" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all projects with stats
#
# GET /v2/organizations/{slug}/projects-with-stats
# operationId: getAllWithStatistics_1
export def "organizations-projects-with-stats get-by-slug" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [id,ASC])
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($slug)/projects-with-stats" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all invitations to organization
#
# GET /v2/organizations/{organizationId}/invitations
# operationId: getInvitations
export def "organizations-invitations get" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/invitations")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get credit balance for organization
#
# GET /v2/organizations/{organizationId}/machine-translation-credit-balance
# operationId: getOrganizationCredits
export def "organizations-machine-translation-credit-balance get" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/machine-translation-credit-balance")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current organization usage
#
# GET /v2/organizations/{organizationId}/usage
# operationId: getUsage
export def "organizations-usage get" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/usage")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export translation memory as TMX file
#
# GET /v2/organizations/{organizationId}/translation-memories/{translationMemoryId}/export
# operationId: exportTmx
export def "organizations-translation-memories-export exportTmx" [
  organizationId: int
  translationMemoryId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories/($translationMemoryId)/export")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List representative entry IDs for every stored row
#
# GET /v2/organizations/{organizationId}/translation-memories/{translationMemoryId}/entries/entryIds
# operationId: getAllStoredEntryIds
export def "organizations-translation-memories-entries-entry-ids get" [
  organizationId: int
  translationMemoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories/($translationMemoryId)/entries/entryIds" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get projects assigned to a translation memory
#
# GET /v2/organizations/{organizationId}/translation-memories/{translationMemoryId}/assigned-projects
# operationId: getAssignedProjects
export def "organizations-translation-memories-assigned-projects get" [
  organizationId: int
  translationMemoryId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories/($translationMemoryId)/assigned-projects")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get entry counts for a set of translation memories
#
# GET /v2/organizations/{organizationId}/translation-memories/entry-counts
# operationId: getEntryCounts
export def "organizations-translation-memories-entry-counts get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories/entry-counts" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all translation memories with statistics
#
# GET /v2/organizations/{organizationId}/translation-memories-with-stats
# operationId: getAllWithStats
export def "organizations-translation-memories-with-stats get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
  --type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories-with-stats" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get connected workspaces
#
# GET /v2/organizations/{organizationId}/slack/workspaces
# operationId: getConnectedWorkspaces
export def "organizations-slack-workspaces get" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/slack/workspaces")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get connect URL for Slack authentication
#
# GET /v2/organizations/{organizationId}/slack/get-connect-url
# operationId: connectToSlack
export def "organizations-slack-get-connect-url connectToSlack" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/slack/get-connect-url")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all projects with stats
#
# GET /v2/organizations/{organizationId}/projects-with-stats
# operationId: getAllWithStatistics_2
export def "organizations-projects-with-stats get-by-organizationId" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/projects-with-stats" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all server-configured providers
#
# GET /v2/organizations/{organizationId}/llm-providers/server-providers
# operationId: getServerProviders
export def "organizations-llm-providers-server-providers get" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/llm-providers/server-providers")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all available llm providers
#
# GET /v2/organizations/{organizationId}/llm-providers/all-available
# operationId: getAvailableProviders
export def "organizations-llm-providers-all-available get" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/llm-providers/all-available")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all languages in use by projects owned by specified organization
#
# GET /v2/organizations/{organizationId}/languages
# operationId: getAllLanguagesInUse
export def "organizations-languages get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
  --projectIds: list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar") (serialize-qp "projectIds" $projectIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/languages" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all glossary terms with translations
#
# GET /v2/organizations/{organizationId}/glossaries/{glossaryId}/termsWithTranslations
# operationId: getAllWithTranslations
export def "organizations-glossaries-terms-with-translations get" [
  organizationId: int
  glossaryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
  --languageTags: list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar") (serialize-qp "languageTags" $languageTags "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries/($glossaryId)/termsWithTranslations" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all glossary terms ids
#
# GET /v2/organizations/{organizationId}/glossaries/{glossaryId}/termsIds
# operationId: getAllIds
export def "organizations-glossaries-terms-ids get" [
  organizationId: int
  glossaryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string
  --languageTags: list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "languageTags" $languageTags "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries/($glossaryId)/termsIds" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get glossary term translation for language
#
# GET /v2/organizations/{organizationId}/glossaries/{glossaryId}/terms/{termId}/translations/{languageTag}
# operationId: get_26
export def "organizations-glossaries-terms-translations get-by-organizationId-glossaryId-termId-languageTag" [
  organizationId: int
  glossaryId: int
  termId: int
  languageTag: string
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries/($glossaryId)/terms/($termId)/translations/($languageTag)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all languages in use by the glossary
#
# GET /v2/organizations/{organizationId}/glossaries/{glossaryId}/languages
# operationId: getLanguages
export def "organizations-glossaries-languages get" [
  organizationId: int
  glossaryId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries/($glossaryId)/languages")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export glossary terms as CSV
#
# GET /v2/organizations/{organizationId}/glossaries/{glossaryId}/export
# operationId: export
export def "organizations-glossaries-export export" [
  organizationId: int
  glossaryId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries/($glossaryId)/export")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all projects assigned to glossary
#
# GET /v2/organizations/{organizationId}/glossaries/{glossaryId}/assigned-projects
# operationId: getAssignedProjects_1
export def "organizations-glossaries-assigned-projects get-by-organizationId-glossaryId" [
  organizationId: int
  glossaryId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries/($glossaryId)/assigned-projects")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all organization glossaries with some additional statistics
#
# GET /v2/organizations/{organizationId}/glossaries-with-stats
# operationId: getAllWithStats_1
export def "organizations-glossaries-with-stats get-by-organizationId" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/glossaries-with-stats" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get active subscription
#
# GET /v2/organizations/{organizationId}/billing/subscription
# operationId: getSubscription
export def "organizations-billing-subscription get" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/subscription")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get expected usage for current month
#
# GET /v2/organizations/{organizationId}/billing/self-hosted-ee/subscriptions/{subscriptionId}/expected-usage
# operationId: getExpectedUsage
export def "organizations-billing-self-hosted-ee-subscriptions-expected-usage get" [
  organizationId: int
  subscriptionId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/self-hosted-ee/subscriptions/($subscriptionId)/expected-usage")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current usage
#
# GET /v2/organizations/{organizationId}/billing/self-hosted-ee/subscriptions/{subscriptionId}/current-usage
# operationId: getCurrentUsage
export def "organizations-billing-self-hosted-ee-subscriptions-current-usage get" [
  organizationId: int
  subscriptionId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/self-hosted-ee/subscriptions/($subscriptionId)/current-usage")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get self-hosted EE plans available for organization
#
# GET /v2/organizations/{organizationId}/billing/self-hosted-ee/plans
# operationId: getSelfHostedPlans
export def "organizations-billing-self-hosted-ee-plans get" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/self-hosted-ee/plans")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get cloud plans
#
# GET /v2/organizations/{organizationId}/billing/plans
# operationId: getCloudPlans
export def "organizations-billing-plans get" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/plans")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get invoices
#
# GET /v2/organizations/{organizationId}/billing/invoices
# operationId: getInvoices
export def "organizations-billing-invoices get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 10)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [createdAt,DESC])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/invoices" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get invoiced usage
#
# GET /v2/organizations/{organizationId}/billing/invoices/{invoiceId}/usage
# operationId: getUsage_1
export def "organizations-billing-invoices-usage get-by-organizationId-invoiceId" [
  organizationId: int
  invoiceId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/invoices/($invoiceId)/usage")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get usage detail in CSV format
#
# GET /v2/organizations/{organizationId}/billing/invoices/{invoiceId}/usage/{type}.csv
# operationId: getUsageDetail
export def "organizations-billing-invoices-usage get" [
  organizationId: int
  invoiceId: int
  type: string
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/invoices/($invoiceId)/usage/($type).csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get invoice PDF
#
# GET /v2/organizations/{organizationId}/billing/invoices/{invoiceId}/pdf
# operationId: getInvoicePdf
export def "organizations-billing-invoices-pdf get" [
  organizationId: int
  invoiceId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/invoices/($invoiceId)/pdf")
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get expected usage for current month
#
# GET /v2/organizations/{organizationId}/billing/expected-usage
# operationId: getExpectedUsage_1
export def "organizations-billing-expected-usage get-by-organizationId" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/expected-usage")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get expected usage detail in CSV format
#
# GET /v2/organizations/{organizationId}/billing/expected-usage/{type}.csv
# operationId: getExpectedUsageDetail
export def "organizations-billing-expected-usage get" [
  organizationId: int
  type: string
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/expected-usage/($type).csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get url of Stripe customer portal session
#
# GET /v2/organizations/{organizationId}/billing/customer-portal
# operationId: goToCustomerPortal
export def "organizations-billing-customer-portal goToCustomerPortal" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/customer-portal")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get stored billing info
#
# GET /v2/organizations/{organizationId}/billing/billing-info
# operationId: getBillingInfo
export def "organizations-billing-billing-info get" [
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/billing-info")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all base languages in use by projects owned by specified organization
#
# GET /v2/organizations/{organizationId}/base-languages
# operationId: getAllBaseLanguagesInUse
export def "organizations-base-languages get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
  --projectIds: list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar") (serialize-qp "projectIds" $projectIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/base-languages" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all users in organization
#
# GET /v2/organizations/{id}/users
# operationId: getAllUsers_1
export def "organizations-users get-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [name,ASC, username,ASC])
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($id)/users" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all accessible projects (by ID)
#
# GET /v2/organizations/{id}/projects
# operationId: getAllProjects_1
export def "organizations-projects get-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
  --filterId: list # Filter projects by id
  --filterNotId: list # Filter projects without id
  --filterBaseLanguageTag: string # Filter projects whose base language tag matches
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar") (serialize-qp "filterId" $filterId "multi") (serialize-qp "filterNotId" $filterNotId "multi") (serialize-qp "filterBaseLanguageTag" $filterBaseLanguageTag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($id)/projects" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets notifications of the currently logged in user, newest is first.
#
# GET /v2/notification
# operationId: getNotifications
export def "notification get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --filterSeen: string@bool-completer # Filter by the `seen` parameter.  no value = request everything  true = only seen  false = only unseen
  --cursor: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "filterSeen" $filterSeen "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/notification" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the info about the current EE subscription
#
# GET /v2/ee-license/info
# operationId: getInfo_5
export def "ee-license-info get-by-" [
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
  let full_url = (build-url $base "/v2/ee-license/info")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current usage for the current EE subscription
#
# GET /v2/ee-current-subscription-usage
# operationId: getUsage_2
export def "ee-current-subscription-usage get-by-" [
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
  let full_url = (build-url $base "/v2/ee-current-subscription-usage")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all translation agencies
#
# GET /v2/billing/translation-agency
# operationId: getAll_18
export def "billing-translation-agency get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/billing/translation-agency" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get single translation agency
#
# GET /v2/billing/translation-agency/{agencyId}
# operationId: get_27
export def "billing-translation-agency get-by-agencyId" [
  agencyId: int
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
  let full_url = (build-url $base $"/v2/billing/translation-agency/($agencyId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current third party authentication provider
#
# GET /v2/auth-provider
# operationId: getCurrentAuthProvider
export def "auth-provider get" [
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
  let full_url = (build-url $base "/v2/auth-provider")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate provider change to remove current third party authentication provider
#
# DELETE /v2/auth-provider
# operationId: deleteCurrentAuthProvider
export def "auth-provider delete" [
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
  let full_url = (build-url $base "/v2/auth-provider")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one API key
#
# GET /v2/api-keys/{keyId}
# operationId: get_28
export def "api-keys get-by-keyId" [
  keyId: int
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
  let full_url = (build-url $base $"/v2/api-keys/($keyId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current API key info
#
# GET /v2/api-keys/current
# operationId: getCurrent_1
export def "api-keys-current get-by-" [
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
  let full_url = (build-url $base "/v2/api-keys/current")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current permission info
#
# GET /v2/api-keys/current-permissions
# operationId: getCurrentPermissions
export def "api-keys-current-permissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: int # Required when using with PAT (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/api-keys/current-permissions" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns API key scopes for every permission type
#
# GET /v2/api-keys/availableScopes
# operationId: getScopes
export def "api-keys-available-scopes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/api-keys/availableScopes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get announcement
#
# GET /v2/announcement
# operationId: getLatest
export def "announcement get" [
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
  let full_url = (build-url $base "/v2/announcement")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all server users
#
# GET /v2/administration/users
# operationId: getUsers_1
export def "administration-users get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [name,ASC])
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/administration/users" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Geneate user's JWT token
#
# GET /v2/administration/users/{userId}/generate-token
# operationId: generateUserToken
export def "administration-users-generate-token generateUserToken" [
  userId: int
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
  let full_url = (build-url $base $"/v2/administration/users/($userId)/generate-token")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all project batch locks
#
# GET /v2/administration/project-batch-locks
# operationId: getProjectLocks
export def "administration-project-batch-locks get" [
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
  let full_url = (build-url $base "/v2/administration/project-batch-locks")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all server organizations
#
# GET /v2/administration/organizations
# operationId: getOrganizations_1
export def "administration-organizations get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [name,ASC])
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/administration/organizations" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get invoices for an organization (admin)
#
# GET /v2/administration/organizations/{organizationId}/billing/invoices
# operationId: getInvoices_1
export def "administration-organizations-billing-invoices get-by-organizationId" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 10)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [createdAt,DESC])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/administration/organizations/($organizationId)/billing/invoices" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/administration/billing/stripe-products
#
# operationId: getStripeProducts
export def "administration-billing-stripe-products get" [
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
  let full_url = (build-url $base "/v2/administration/billing/stripe-products")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/administration/billing/self-hosted-ee-plans/{planId}/subscriptions
#
# operationId: planSubscriptions
export def "administration-billing-self-hosted-ee-plans-subscriptions planSubscriptions" [
  planId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/administration/billing/self-hosted-ee-plans/($planId)/subscriptions" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/administration/billing/self-hosted-ee-plans/{planId}/organizations
#
# operationId: getPlanOrganizations
export def "administration-billing-self-hosted-ee-plans-organizations get" [
  planId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [name,ASC])
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/administration/billing/self-hosted-ee-plans/($planId)/organizations" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/administration/billing/self-hosted-ee-plans/migration/{migrationId}/upcoming-subscriptions
#
# operationId: getPlanMigrationUpcomingSubscriptions
export def "administration-billing-self-hosted-ee-plans-migration-upcoming-subscriptions get" [
  migrationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/administration/billing/self-hosted-ee-plans/migration/($migrationId)/upcoming-subscriptions" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/administration/billing/self-hosted-ee-plans/migration/{migrationId}/subscriptions
#
# operationId: getPlanMigrationSubscriptions
export def "administration-billing-self-hosted-ee-plans-migration-subscriptions get" [
  migrationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/administration/billing/self-hosted-ee-plans/migration/($migrationId)/subscriptions" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/administration/billing/plan-migration/email-template
#
# operationId: getPlanMigrationEmailTemplate
export def "administration-billing-plan-migration-email-template get" [
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
  let full_url = (build-url $base "/v2/administration/billing/plan-migration/email-template")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/administration/billing/organizations
#
# operationId: getOrganizations_2
export def "administration-billing-organizations get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
  --search: string
  --withCloudPlanId: int # format: int64
  --hasSelfHostedSubscription: string@bool-completer
  --filterDeleted: string@bool-completer
  --trialing: string@bool-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar") (serialize-qp "withCloudPlanId" $withCloudPlanId "scalar") (serialize-qp "hasSelfHostedSubscription" $hasSelfHostedSubscription "scalar") (serialize-qp "filterDeleted" $filterDeleted "scalar") (serialize-qp "trialing" $trialing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/administration/billing/organizations" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all invoices across organizations (admin)
#
# GET /v2/administration/billing/invoices
# operationId: getAllInvoices
export def "administration-billing-invoices get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # format: int64
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 10)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [createdAt,DESC])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/administration/billing/invoices" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get invoiced usage (admin)
#
# GET /v2/administration/billing/invoices/{invoiceId}/usage
# operationId: getInvoiceUsage
export def "administration-billing-invoices-usage get" [
  invoiceId: int
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
  let full_url = (build-url $base $"/v2/administration/billing/invoices/($invoiceId)/usage")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get invoice PDF (admin)
#
# GET /v2/administration/billing/invoices/{invoiceId}/pdf
# operationId: getInvoicePdf_1
export def "administration-billing-invoices-pdf get-by-invoiceId" [
  invoiceId: int
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
  let full_url = (build-url $base $"/v2/administration/billing/invoices/($invoiceId)/pdf")
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns active cloud subscriptions, which have inconsistent state in Tolgee and Stripe
#
# GET /v2/administration/billing/inconsistent-subscriptions
# operationId: getInconsistentSubscriptions
export def "administration-billing-inconsistent-subscriptions get" [
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
  let full_url = (build-url $base "/v2/administration/billing/inconsistent-subscriptions")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/administration/billing/features
#
# operationId: getAllFeatures
export def "administration-billing-features get" [
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
  let full_url = (build-url $base "/v2/administration/billing/features")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/administration/billing/cloud-plans/{planId}/subscriptions
#
# operationId: planSubscriptions_1
export def "administration-billing-cloud-plans-subscriptions planSubscriptions-by-planId" [
  planId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/administration/billing/cloud-plans/($planId)/subscriptions" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/administration/billing/cloud-plans/{planId}/organizations
#
# operationId: getPlanOrganizations_1
export def "administration-billing-cloud-plans-organizations get-by-planId" [
  planId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [name,ASC])
  --search: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/administration/billing/cloud-plans/($planId)/organizations" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/administration/billing/cloud-plans/migration/{migrationId}/upcoming-subscriptions
#
# operationId: getPlanMigrationUpcomingSubscriptions_1
export def "administration-billing-cloud-plans-migration-upcoming-subscriptions get-by-migrationId" [
  migrationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/administration/billing/cloud-plans/migration/($migrationId)/upcoming-subscriptions" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/administration/billing/cloud-plans/migration/{migrationId}/subscriptions
#
# operationId: getPlanMigrationSubscriptions_1
export def "administration-billing-cloud-plans-migration-subscriptions get-by-migrationId" [
  migrationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 20)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/administration/billing/cloud-plans/migration/($migrationId)/subscriptions" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get active carry-overs (not yet invoiced)
#
# GET /v2/administration/billing/carry-overs
# operationId: getCarryOvers
export def "administration-billing-carry-overs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 10)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [createdAt,DESC])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/administration/billing/carry-overs" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get resolved carry-overs (already invoiced, historical view)
#
# GET /v2/administration/billing/carry-overs/history
# operationId: getCarryOversHistory
export def "administration-billing-carry-overs-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Zero-based page index (0..N) (default: 0)
  --size: int # The size of the page to be returned (default: 10)
  --qp-sort: list # Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported. (default: [createdAt,DESC])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/administration/billing/carry-overs/history" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current batch job queue
#
# GET /v2/administration/batch-job-queue
# operationId: getBatchJobQueue
export def "administration-batch-job-queue get" [
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
  let full_url = (build-url $base "/v2/administration/batch-job-queue")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /uploaded-images/**
#
# operationId: getUploadedImage
export def "uploaded-images get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/uploaded-images/**" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /screenshots/**
#
# operationId: getScreenshot
export def "screenshots get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/screenshots/**" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /avatars/*
#
# operationId: getAvatar
export def "avatars get" [
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
  let full_url = (build-url $base "/avatars/*")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set user account as verified
#
# GET /api/public/verify_email/{userId}/{code}
# operationId: verifyEmail
export def "public-verify-email verifyEmail" [
  userId: int
  code: string
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
  let full_url = (build-url $base $"/api/public/verify_email/($userId)/($code)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate password-resetting key
#
# GET /api/public/reset_password_validate/{email}/{code}
# operationId: resetPasswordValidate
export def "public-reset-password-validate resetPasswordValidate" [
  code: string
  email: string
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
  let full_url = (build-url $base $"/api/public/reset_password_validate/($email)/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Info about invitation
#
# GET /api/public/invitation_info/{code}
# operationId: invitationInfo
export def "public-invitation-info invitationInfo" [
  code: string
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
  let full_url = (build-url $base $"/api/public/invitation_info/($code)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get server configuration
#
# GET /api/public/configuration
# operationId: getPublicConfiguration
export def "public-configuration get" [
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
  let full_url = (build-url $base "/api/public/configuration")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Authenticate user (third-part, oAuth)
#
# GET /api/public/authorize_oauth/{serviceType}
# operationId: authenticateUser_1
export def "public-authorize-oauth authenticateUser-by-serviceType" [
  serviceType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string
  --redirect-uri: string
  --invitationCode: string
  --domain: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code" $code "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "invitationCode" $invitationCode "scalar") (serialize-qp "domain" $domain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/public/authorize_oauth/($serviceType)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export to ZIP of jsons
#
# GET /api/project/{projectId}/export/jsonZip
# DEPRECATED
# operationId: doExportJsonZip
@deprecated
export def "project-export-json-zip doExportJsonZip" [
  projectId: any
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
  let full_url = (build-url $base $"/api/project/($projectId)/export/jsonZip")
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export to ZIP of jsons
#
# GET /api/project/export/jsonZip
# DEPRECATED
# operationId: doExportJsonZip_1
@deprecated
export def "project-export-json-zip doExportJsonZip-by-" [
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
  let full_url = (build-url $base "/api/project/export/jsonZip")
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export to ZIP of jsons
#
# GET /api/repository/{projectId}/export/jsonZip
# DEPRECATED
# operationId: doExportJsonZip_2
@deprecated
export def "repository-export-json-zip doExportJsonZip-by-projectId" [
  projectId: any
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
  let full_url = (build-url $base $"/api/repository/($projectId)/export/jsonZip")
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export to ZIP of jsons
#
# GET /api/repository/export/jsonZip
# DEPRECATED
# operationId: doExportJsonZip_3
@deprecated
export def "repository-export-json-zip doExportJsonZip-by-" [
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
  let full_url = (build-url $base "/api/repository/export/jsonZip")
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove tag
#
# DELETE /v2/projects/{projectId}/keys/{keyId}/tags/{tagId}
# operationId: removeTag
export def "projects-keys-tags removeTag" [
  keyId: int
  tagId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/($keyId)/tags/($tagId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove tag
#
# DELETE /v2/projects/keys/{keyId}/tags/{tagId}
# operationId: removeTag_1
export def "projects-keys-tags removeTag-by-keyId-tagId" [
  keyId: int
  tagId: int
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
  let full_url = (build-url $base $"/v2/projects/keys/($keyId)/tags/($tagId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete suggestion
#
# DELETE /v2/projects/{projectId}/languages/{languageId}/key/{keyId}/suggestion/{suggestionId}
# operationId: deleteSuggestion
export def "projects-languages-key-suggestion delete" [
  languageId: int
  keyId: int
  suggestionId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/languages/($languageId)/key/($keyId)/suggestion/($suggestionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete suggestion
#
# DELETE /v2/projects/languages/{languageId}/key/{keyId}/suggestion/{suggestionId}
# operationId: deleteSuggestion_1
export def "projects-languages-key-suggestion delete-by-languageId-keyId-suggestionId" [
  languageId: int
  keyId: int
  suggestionId: int
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
  let full_url = (build-url $base $"/v2/projects/languages/($languageId)/key/($keyId)/suggestion/($suggestionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete one or multiple keys
#
# DELETE /v2/projects/{projectId}/keys/{ids}
# operationId: delete_18
export def "projects-keys delete-by-ids-projectId" [
  ids: list
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/($ids)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete one or multiple keys
#
# DELETE /v2/projects/keys/{ids}
# operationId: delete_19
export def "projects-keys delete-by-ids" [
  ids: list
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
  let full_url = (build-url $base $"/v2/projects/keys/($ids)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Permanently delete a trashed key
#
# DELETE /v2/projects/{projectId}/keys/trash/{keyId}
# operationId: permanentlyDelete
export def "projects-keys-trash permanentlyDelete" [
  keyId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/trash/($keyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Permanently delete a trashed key
#
# DELETE /v2/projects/keys/trash/{keyId}
# operationId: permanentlyDelete_1
export def "projects-keys-trash permanentlyDelete-by-keyId" [
  keyId: int
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
  let full_url = (build-url $base $"/v2/projects/keys/trash/($keyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete branch merge session
#
# DELETE /v2/projects/{projectId}/branches/merge/{mergeId}
# operationId: deleteBranchMerge
export def "projects-branches-merge delete" [
  mergeId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/branches/merge/($mergeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete branch merge session
#
# DELETE /v2/projects/branches/merge/{mergeId}
# operationId: deleteBranchMerge_1
export def "projects-branches-merge delete-by-mergeId" [
  mergeId: int
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
  let full_url = (build-url $base $"/v2/projects/branches/merge/($mergeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete screenshots
#
# DELETE /v2/projects/keys/{keyId}/screenshots/{ids}
# operationId: deleteScreenshots
export def "projects-keys-screenshots delete" [
  ids: list
  keyId: int
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
  let full_url = (build-url $base $"/v2/projects/keys/($keyId)/screenshots/($ids)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete screenshots
#
# DELETE /v2/projects/{projectId}/keys/{keyId}/screenshots/{ids}
# operationId: deleteScreenshots_1
export def "projects-keys-screenshots delete-by-ids-keyId-projectId" [
  ids: list
  keyId: int
  projectId: any
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/keys/($keyId)/screenshots/($ids)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove user from organization
#
# DELETE /v2/organizations/{organizationId}/users/{userId}
# operationId: removeUser
export def "organizations-users removeUser" [
  organizationId: int
  userId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a whole translation memory entry group
#
# DELETE /v2/organizations/{organizationId}/translation-memories/{translationMemoryId}/entries/{entryId}/group
# operationId: deleteGroup
export def "organizations-translation-memories-entries-group delete" [
  organizationId: int
  translationMemoryId: int
  entryId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/translation-memories/($translationMemoryId)/entries/($entryId)/group")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disconnect workspace
#
# DELETE /v2/organizations/{organizationId}/slack/workspaces/{workspaceId}
# operationId: disconnectWorkspace
export def "organizations-slack-workspaces disconnectWorkspace" [
  workspaceId: int
  organizationId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/slack/workspaces/($workspaceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel subscription for self-hosted EE instance
#
# DELETE /v2/organizations/{organizationId}/billing/self-hosted-ee/subscriptions/{subscriptionId}
# operationId: cancelEeSubscription
export def "organizations-billing-self-hosted-ee-subscriptions cancelEeSubscription" [
  organizationId: int
  subscriptionId: int
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
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/billing/self-hosted-ee/subscriptions/($subscriptionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes invitation by ID
#
# DELETE /v2/invitations/{invitationId}
# operationId: deleteInvitation
export def "invitations delete" [
  invitationId: int
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
  let full_url = (build-url $base $"/v2/invitations/($invitationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete uploaded images
#
# DELETE /v2/image-upload/{ids}
# operationId: delete_20
export def "image-upload delete-by-ids" [
  ids: list
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
  let full_url = (build-url $base $"/v2/image-upload/($ids)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete user
#
# DELETE /v2/administration/users/{userId}
# operationId: deleteUser
export def "administration-users delete" [
  userId: int
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
  let full_url = (build-url $base $"/v2/administration/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
