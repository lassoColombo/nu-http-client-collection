# Auto-generated client for Forms vv3
# Source: https://raw.githubusercontent.com/HubSpot/HubSpot-public-api-spec-collection/main/PublicApiSpecs/Marketing/Forms/Rollouts/144909/v3/forms.json
# Auth: --token flag or $env.FORMS_TOKEN

const BASE_URL = "https://api.hubapi.com"
const DEFAULT_AUTH = "query-hapikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FORMS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-hapikey" => { {headers: {}, query: $"hapikey=($token_val)"} }
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "private-app" => { {headers: {private-app: $token_val}, query: ""} }
    "private-app-legacy" => { {headers: {private-app-legacy: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.hubapi.com"] }
def auth-scheme-completer [] { ["query-hapikey" "bearer" "private-app" "private-app-legacy"] }

# Completers for enum parameters
def formType-completer [] { ["hubspot"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "marketing-forms /marketing/v3/forms" } } | get name | first)
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

# GET /marketing/v3/forms
#
# operationId: get-/marketing/v3/forms_/marketing/v3/forms
export def "marketing-forms /marketing/v3/forms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string
  --archived: oneof<nothing, bool>
  --formTypes: list
  --limit: int # format: int32
]: nothing -> record<paging: record<next: record<after: string, link: string>>, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "formTypes" $formTypes "multi") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketing/v3/forms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /marketing/v3/forms
#
# operationId: post-/marketing/v3/forms_/marketing/v3/forms
# --configuration shape: {allowLinkToResetKnownValues: bool, archivable: bool, cloneable: bool, createNewContactForNewEmail: bool, editable: bool, embedType?: "V3"|"V4", language: "af"|"ar-eg"|"bg"|"bn"|"ca-es"|"cs"|"da"|"de"|"el"|"en"|"en-gb"|"es"|"es-mx"|"fi"|"fr"|"fr-ca"|"he-il"|"hr"|"hu"|"id"|"it"|"ja"|"ko"|"lt"|"ms"|"nl"|"no-no"|"pl"|"pt"|"pt-br"|"ro"|"ru"|"sk"|"sl"|"sv"|"th"|"tl"|"tr"|"uk"|"vi"|"zh-cn"|"zh-hk"|"zh-tw", lifecycleStages: list, notifyContactOwner: bool, notifyRecipients: list, postSubmitAction: record, prePopulateKnownValues: bool, recaptchaEnabled: bool}
# --displayOptions shape: {cssClass?: string, renderRawHtml: bool, style: record, submitButtonText: string, theme: "canvas"|"default_style"|"legacy"|"linear"|"round"|"sharp"}
# --fieldGroups item shape: {fields: list, groupType: "default_group"|"progressive"|"queued", richText?: string, richTextType: "image"|"text"}
export def "marketing-forms /marketing/v3/forms-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived: oneof<nothing, bool>
  --archivedAt: string # format: date-time
  --configuration: record # shape: {allowLinkToResetKnownValues: bool, archivable: bool, cloneable: bool, createNewContactForNewEmail: bool, editable: bool, embedType?: "V3"|"V4", language: "af"|"ar-eg"|"bg"|"bn"|"ca-es"|"cs"|"da"|"de"|"el"|"en"|"en-gb"|"es"|"es-mx"|"fi"|"fr"|"fr-ca"|"he-il"|"hr"|"hu"|"id"|"it"|"ja"|"ko"|"lt"|"ms"|"nl"|"no-no"|"pl"|"pt"|"pt-br"|"ro"|"ru"|"sk"|"sl"|"sv"|"th"|"tl"|"tr"|"uk"|"vi"|"zh-cn"|"zh-hk"|"zh-tw", lifecycleStages: list, notifyContactOwner: bool, notifyRecipients: list, postSubmitAction: record, prePopulateKnownValues: bool, recaptchaEnabled: bool}
  --createdAt: string # format: date-time
  --displayOptions: record # shape: {cssClass?: string, renderRawHtml: bool, style: record, submitButtonText: string, theme: "canvas"|"default_style"|"legacy"|"linear"|"round"|"sharp"}
  --fieldGroups: list # item shape: {fields: list, groupType: "default_group"|"progressive"|"queued", richText?: string, richTextType: "image"|"text"}
  --formType: string@formType-completer # default: hubspot
  --legalConsentOptions: any
  --name: string
  --updatedAt: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/v3/forms")
  let body = {archived: $archived, archivedAt: $archivedAt, configuration: $configuration, createdAt: $createdAt, displayOptions: $displayOptions, fieldGroups: $fieldGroups, formType: $formType, legalConsentOptions: $legalConsentOptions, name: $name, updatedAt: $updatedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a form definition
#
# GET /marketing/v3/forms/{formId}
# operationId: get-/marketing/v3/forms/{formId}_getById
export def "marketing-forms get" [
  formId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived: oneof<nothing, bool> # Whether to return only results that have been archived.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "archived" $archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/v3/forms/($formId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a form definition
#
# PUT /marketing/v3/forms/{formId}
# operationId: put-/marketing/v3/forms/{formId}_replace
# --configuration shape: {allowLinkToResetKnownValues: bool, archivable: bool, cloneable: bool, createNewContactForNewEmail: bool, editable: bool, embedType?: "V3"|"V4", language: "af"|"ar-eg"|"bg"|"bn"|"ca-es"|"cs"|"da"|"de"|"el"|"en"|"en-gb"|"es"|"es-mx"|"fi"|"fr"|"fr-ca"|"he-il"|"hr"|"hu"|"id"|"it"|"ja"|"ko"|"lt"|"ms"|"nl"|"no-no"|"pl"|"pt"|"pt-br"|"ro"|"ru"|"sk"|"sl"|"sv"|"th"|"tl"|"tr"|"uk"|"vi"|"zh-cn"|"zh-hk"|"zh-tw", lifecycleStages: list, notifyContactOwner: bool, notifyRecipients: list, postSubmitAction: record, prePopulateKnownValues: bool, recaptchaEnabled: bool}
# --displayOptions shape: {cssClass?: string, renderRawHtml: bool, style: record, submitButtonText: string, theme: "canvas"|"default_style"|"legacy"|"linear"|"round"|"sharp"}
# --fieldGroups item shape: {fields: list, groupType: "default_group"|"progressive"|"queued", richText?: string, richTextType: "image"|"text"}
export def "marketing-forms replace" [
  formId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived: oneof<nothing, bool>
  --archivedAt: string # format: date-time
  configuration: record # shape: {allowLinkToResetKnownValues: bool, archivable: bool, cloneable: bool, createNewContactForNewEmail: bool, editable: bool, embedType?: "V3"|"V4", language: "af"|"ar-eg"|"bg"|"bn"|"ca-es"|"cs"|"da"|"de"|"el"|"en"|"en-gb"|"es"|"es-mx"|"fi"|"fr"|"fr-ca"|"he-il"|"hr"|"hu"|"id"|"it"|"ja"|"ko"|"lt"|"ms"|"nl"|"no-no"|"pl"|"pt"|"pt-br"|"ro"|"ru"|"sk"|"sl"|"sv"|"th"|"tl"|"tr"|"uk"|"vi"|"zh-cn"|"zh-hk"|"zh-tw", lifecycleStages: list, notifyContactOwner: bool, notifyRecipients: list, postSubmitAction: record, prePopulateKnownValues: bool, recaptchaEnabled: bool}
  createdAt: string # format: date-time
  displayOptions: record # shape: {cssClass?: string, renderRawHtml: bool, style: record, submitButtonText: string, theme: "canvas"|"default_style"|"legacy"|"linear"|"round"|"sharp"}
  fieldGroups: list # item shape: {fields: list, groupType: "default_group"|"progressive"|"queued", richText?: string, richTextType: "image"|"text"}
  formType: string@formType-completer # default: hubspot
  id: string
  legalConsentOptions: any
  name: string
  updatedAt: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/v3/forms/($formId)")
  let body = {archived: $archived, archivedAt: $archivedAt, configuration: $configuration, createdAt: $createdAt, displayOptions: $displayOptions, fieldGroups: $fieldGroups, formType: $formType, id: $id, legalConsentOptions: $legalConsentOptions, name: $name, updatedAt: $updatedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archive a form definition
#
# DELETE /marketing/v3/forms/{formId}
# operationId: delete-/marketing/v3/forms/{formId}_archive
export def "marketing-forms archive" [
  formId: string
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
  let full_url = (build-url $base $"/marketing/v3/forms/($formId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Partially update a form definition
#
# PATCH /marketing/v3/forms/{formId}
# operationId: patch-/marketing/v3/forms/{formId}_update
# --configuration shape: {allowLinkToResetKnownValues: bool, archivable: bool, cloneable: bool, createNewContactForNewEmail: bool, editable: bool, embedType?: "V3"|"V4", language: "af"|"ar-eg"|"bg"|"bn"|"ca-es"|"cs"|"da"|"de"|"el"|"en"|"en-gb"|"es"|"es-mx"|"fi"|"fr"|"fr-ca"|"he-il"|"hr"|"hu"|"id"|"it"|"ja"|"ko"|"lt"|"ms"|"nl"|"no-no"|"pl"|"pt"|"pt-br"|"ro"|"ru"|"sk"|"sl"|"sv"|"th"|"tl"|"tr"|"uk"|"vi"|"zh-cn"|"zh-hk"|"zh-tw", lifecycleStages: list, notifyContactOwner: bool, notifyRecipients: list, postSubmitAction: record, prePopulateKnownValues: bool, recaptchaEnabled: bool}
# --displayOptions shape: {cssClass?: string, renderRawHtml: bool, style: record, submitButtonText: string, theme: "canvas"|"default_style"|"legacy"|"linear"|"round"|"sharp"}
# --fieldGroups item shape: {fields: list, groupType: "default_group"|"progressive"|"queued", richText?: string, richTextType: "image"|"text"}
export def "marketing-forms update" [
  formId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived: oneof<nothing, bool> # Whether this form is archived.
  --configuration: record # shape: {allowLinkToResetKnownValues: bool, archivable: bool, cloneable: bool, createNewContactForNewEmail: bool, editable: bool, embedType?: "V3"|"V4", language: "af"|"ar-eg"|"bg"|"bn"|"ca-es"|"cs"|"da"|"de"|"el"|"en"|"en-gb"|"es"|"es-mx"|"fi"|"fr"|"fr-ca"|"he-il"|"hr"|"hu"|"id"|"it"|"ja"|"ko"|"lt"|"ms"|"nl"|"no-no"|"pl"|"pt"|"pt-br"|"ro"|"ru"|"sk"|"sl"|"sv"|"th"|"tl"|"tr"|"uk"|"vi"|"zh-cn"|"zh-hk"|"zh-tw", lifecycleStages: list, notifyContactOwner: bool, notifyRecipients: list, postSubmitAction: record, prePopulateKnownValues: bool, recaptchaEnabled: bool}
  --displayOptions: record # shape: {cssClass?: string, renderRawHtml: bool, style: record, submitButtonText: string, theme: "canvas"|"default_style"|"legacy"|"linear"|"round"|"sharp"}
  --fieldGroups: list # The fields in the form, grouped in rows. — item shape: {fields: list, groupType: "default_group"|"progressive"|"queued", richText?: string, richTextType: "image"|"text"}
  --legalConsentOptions: any # Configuration for legal consent and data processing compliance options. Supports types: none, legitimate_interest, explicit_consent_to_process, implicit_consent_to_process.
  --name: string # The name of the form. Expected to be unique for a hub.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/v3/forms/($formId)")
  let body = {archived: $archived, configuration: $configuration, displayOptions: $displayOptions, fieldGroups: $fieldGroups, legalConsentOptions: $legalConsentOptions, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
