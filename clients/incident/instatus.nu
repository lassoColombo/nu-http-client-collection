# Auto-generated client for Instatus API v2.0.0
# Source: https://raw.githubusercontent.com/instatushq/openapi/main/instatus.yaml
# Auth: --token flag or $env.INSTATUS_API_TOKEN

const BASE_URL = "https://api.instatus.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o INSTATUS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.instatus.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def smsService-completer [] { ["esendex" "messagebird" "sns" "twilio" "vonage"] }
def status-completer [] { ["ALLDEGRADEDPERFORMANCE" "ALLMAJOROUTAGE" "ALLMINOROUTAGE" "ALLPARTIALOUTAGE" "ALLUNDERMAINTENANCE" "HASISSUES" "ONEDEGRADEDPERFORMANCE" "ONEMAJOROUTAGE" "ONEMINOROUTAGE" "ONEPARTIALOUTAGE" "ONEUNDERMAINTENANCE" "SOMEDEGRADEDPERFORMANCE" "SOMEMAJOROUTAGE" "SOMEMINOROUTAGE" "SOMEPARTIALOUTAGE" "SOMEUNDERMAINTENANCE" "UP"] }
def status-completer-1 [] { ["DEGRADEDPERFORMANCE" "MAJOROUTAGE" "OPERATIONAL" "PARTIALOUTAGE" "UNDERMAINTENANCE"] }
def status-completer-2 [] { ["IDENTIFIED" "INVESTIGATING" "MONITORING" "RESOLVED"] }
def status-completer-3 [] { ["COMPLETED" "INPROGRESS" "NOTSTARTEDYET"] }
def type-completer [] { ["INCIDENT" "MAINTENANCE"] }
def status-completer-4 [] { ["COMPLETED" "IDENTIFIED" "INPROGRESS" "INVESTIGATING" "MONITORING" "NOTSTARTEDYET" "RESOLVED"] }
def permission-completer [] { ["EDITOR" "FULL" "MEMBER" "READ" "WRITE"] }
def status-completer-5 [] { ["DEGRADED" "DOWN" "UNKNOWN" "UP"] }
def httpMethod-completer [] { ["DELETE" "GET" "HEAD" "OPTIONS" "PATCH" "POST" "PUT"] }
def type-completer-1 [] { ["DNS" "HTTP" "HTTP_API" "PING" "TCP"] }
def type-completer-2 [] { ["DISCORD" "EMAIL" "MICROSOFT_TEAMS" "PHONE_CALL" "SLACK" "SMS" "WEBHOOK"] }
def status-completer-6 [] { ["ACTIVE" "PAUSED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "pages get" } } | get name | first)
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

# Get your status pages
#
# GET /v2/pages
export def "pages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number for pagination (default: 1)
  --per-page: int # Number of items per page (default: 50)
]: nothing -> table<id: string, subdomain: string, name: string, logoUrl: string, faviconUrl: string, websiteUrl: string, customDomain: string, publicEmail: string, twitter: string, status: string, subscribeBySms: bool, language: string, useLargeHeader: bool, brandColor: string, okColor: string, disruptedColor: string, degradedColor: string, downColor: string, noticeColor: string, unknownColor: string, googleAnalytics: string, smsService: string, htmlInMeta: string, htmlAboveHeader: string, htmlBelowHeader: string, htmlAboveFooter: string, htmlBelowFooter: string, htmlBelowSummary: string, launchDate: string, cssGlobal: string, onboarded: bool, createdAt: string, updatedAt: string, secureLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/pages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a status page
#
# POST /v1/pages
export def "pages post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # format: email
  name: string
  subdomain: string # The subdomain of the status page, make sure it's unique and follows the slug format.
  components: list # The names of the components to add to the status page.
  --logoUrl: string
  --faviconUrl: string
  --websiteUrl: string
  --language: string # The language of the status page in language code (e.g. `en` for English, `fr` for French, `de` for German, etc.). (default: en)
  --useLargeHeader: oneof<nothing, bool>
  --brandColor: string # The brand color of the status page, This only accepts hex colors or rgb(r,g,b).
  --okColor: string # The color for operational, This only accepts hex colors or rgb(r,g,b).
  --disruptedColor: string # The color for partial outage, This only accepts hex colors or rgb(r,g,b).
  --degradedColor: string # The color for degraded performance, This only accepts hex colors or rgb(r,g,b).
  --downColor: string # The color for major outage, This only accepts hex colors or rgb(r,g,b).
  --noticeColor: string # The color for maintenances, This only accepts hex colors or rgb(r,g,b).
  --unknownColor: string
  --googleAnalytics: string
  --subscribeBySms: oneof<nothing, bool>
  --smsService: string@smsService-completer
  --twilioSid: string
  --twilioToken: string
  --twilioSender: string
  --esendexUsername: string
  --esendexPassword: string
  --esendexAccountRef: string
  --nexmoKey: string # nullable
  --nexmoSecret: string # nullable
  --nexmoSender: string # nullable
  --htmlInMeta: string # nullable
  --htmlAboveHeader: string # nullable
  --htmlBelowHeader: string # nullable
  --htmlAboveFooter: string # nullable
  --htmlBelowFooter: string # nullable
  --htmlBelowSummary: string # nullable
  --cssGlobal: string # Global CSS to apply to the status page. (nullable)
  --launchDate: string # nullable
  --dateFormat: string # Formats to display dates on the page, please refer to [date-fns formatting](https://date-fns.org/docs/format)
  --dateFormatShort: string # Formats to display the shortened date on the page, please refer to [date-fns formatting](https://date-fns.org/docs/format)
  --timeFormat: string # Formats to display time on the page, please refer to [date-fns formatting](https://date-fns.org/docs/format)
  --workspace: string # The workspace id to create the status page in, if not provided, a new workspace will be created.
]: any -> record<id: string, createdAt: string, subdomain: string, name: string, status: string, logoUrl: string, faviconUrl: string, websiteUrl: string, color: string, language: string, googleAnalytics: string, publicEmail: string, customDomain: string, useLargeHeader: bool, disableDarkMode: bool, twitter: string, subscribeBySms: bool, brandColor: string, okColor: string, disruptedColor: string, downColor: string, degradedColor: string, noticeColor: string, htmlInMeta: string, htmlAboveHeader: string, htmlBelowHeader: string, htmlAboveFooter: string, htmlBelowFooter: string, htmlBelowSummary: string, cssGlobal: string, onboarded: bool, launchDate: string, dateFormat: string, dateFormatShort: string, timeFormat: string, private: bool, useAllowList: bool, allowList: list<string>, components: table<id: string, name: string, uniqueEmail: string, description: string, status: string, order: int, group: any, nameTranslationId: string, descriptionTranslationId: string, showUptime: bool, createdAt: string, updatedAt: string, archivedAt: string, siteId: string, groupId: string, nameHtml: string, nameHtmlTranslationId: string, descriptionHtml: string, descriptionHtmlTranslationId: string, isThirdParty: bool, thirdPartyStatus: string, thirdPartyComponentId: string, thirdPartyComponentServiceId: string, importedFromStatuspage: bool, startDate: string, translations: record>, translations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/pages")
  let body = {email: $email, name: $name, subdomain: $subdomain, components: $components, logoUrl: $logoUrl, faviconUrl: $faviconUrl, websiteUrl: $websiteUrl, language: $language, useLargeHeader: $useLargeHeader, brandColor: $brandColor, okColor: $okColor, disruptedColor: $disruptedColor, degradedColor: $degradedColor, downColor: $downColor, noticeColor: $noticeColor, unknownColor: $unknownColor, googleAnalytics: $googleAnalytics, subscribeBySms: $subscribeBySms, smsService: $smsService, twilioSid: $twilioSid, twilioToken: $twilioToken, twilioSender: $twilioSender, esendexUsername: $esendexUsername, esendexPassword: $esendexPassword, esendexAccountRef: $esendexAccountRef, nexmoKey: $nexmoKey, nexmoSecret: $nexmoSecret, nexmoSender: $nexmoSender, htmlInMeta: $htmlInMeta, htmlAboveHeader: $htmlAboveHeader, htmlBelowHeader: $htmlBelowHeader, htmlAboveFooter: $htmlAboveFooter, htmlBelowFooter: $htmlBelowFooter, htmlBelowSummary: $htmlBelowSummary, cssGlobal: $cssGlobal, launchDate: $launchDate, dateFormat: $dateFormat, dateFormatShort: $dateFormatShort, timeFormat: $timeFormat, workspace: $workspace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a status page
#
# PUT /v2/{page_id}
export def "status-pages put" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
  --name: string
  --status: string@status-completer
  --subdomain: string
  --logoUrl: string
  --faviconUrl: string
  --websiteUrl: string
  --language: string # The language of the status page in language code (e.g. `en` for English, `fr` for French, `de` for German, etc.).
  --publicEmail: string
  --useLargeHeader: oneof<nothing, bool>
  --brandColor: string # The brand color of the status page, This only accepts hex colors or rgb(r,g,b).
  --okColor: string # The color for operational, This only accepts hex colors or rgb(r,g,b).
  --disruptedColor: string # The color for partial outage, This only accepts hex colors or rgb(r,g,b).
  --degradedColor: string # The color for degraded performance, This only accepts hex colors or rgb(r,g,b).
  --downColor: string # The color for major outage, This only accepts hex colors or rgb(r,g,b).
  --noticeColor: string # The color for maintenances, This only accepts hex colors or rgb(r,g,b).
  --unknownColor: string
  --googleAnalytics: string
  --subscribeBySms: oneof<nothing, bool>
  --smsService: string@smsService-completer
  --twilioSid: string
  --twilioToken: string
  --twilioSender: string
  --esendexUsername: string
  --esendexPassword: string
  --esendexAccountRef: string
  --nexmoKey: string # nullable
  --nexmoSecret: string # nullable
  --nexmoSender: string # nullable
  --htmlInMeta: string # nullable
  --htmlAboveHeader: string # nullable
  --htmlBelowHeader: string # nullable
  --htmlAboveFooter: string # nullable
  --htmlBelowFooter: string # nullable
  --htmlBelowSummary: string # nullable
  --cssGlobal: string # nullable
  --launchDate: string # nullable
  --dateFormat: string
  --dateFormatShort: string
  --timeFormat: string
  --private: oneof<nothing, bool>
  --useAllowList: oneof<nothing, bool>
  --translations: record # Object containing translations where each key is a property name and the value is an object with language codes as keys and translations as values. The language code as the key (e.g., 'en', 'fr') and the translation as the value. (e.g. {name: {en: This will be displayed for English users, fr: Ceci sera affiché pour les utilisateurs francophones}, description: {en: Example description in English, fr: Exemple de description en français}})
]: any -> record<id: string, createdAt: string, subdomain: string, name: string, status: string, logoUrl: string, faviconUrl: string, websiteUrl: string, color: string, language: string, googleAnalytics: string, publicEmail: string, customDomain: string, useLargeHeader: bool, disableDarkMode: bool, twitter: string, subscribeBySms: bool, brandColor: string, okColor: string, disruptedColor: string, downColor: string, degradedColor: string, noticeColor: string, htmlInMeta: string, htmlAboveHeader: string, htmlBelowHeader: string, htmlAboveFooter: string, htmlBelowFooter: string, htmlBelowSummary: string, cssGlobal: string, onboarded: bool, launchDate: string, dateFormat: string, dateFormatShort: string, timeFormat: string, private: bool, useAllowList: bool, allowList: list<string>, components: table<id: string, name: string, uniqueEmail: string, description: string, status: string, order: int, group: any, nameTranslationId: string, descriptionTranslationId: string, showUptime: bool, createdAt: string, updatedAt: string, archivedAt: string, siteId: string, groupId: string, nameHtml: string, nameHtmlTranslationId: string, descriptionHtml: string, descriptionHtmlTranslationId: string, isThirdParty: bool, thirdPartyStatus: string, thirdPartyComponentId: string, thirdPartyComponentServiceId: string, importedFromStatuspage: bool, startDate: string, translations: record>, translations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/($page_id)")
  let body = {id: $id, name: $name, status: $status, subdomain: $subdomain, logoUrl: $logoUrl, faviconUrl: $faviconUrl, websiteUrl: $websiteUrl, language: $language, publicEmail: $publicEmail, useLargeHeader: $useLargeHeader, brandColor: $brandColor, okColor: $okColor, disruptedColor: $disruptedColor, degradedColor: $degradedColor, downColor: $downColor, noticeColor: $noticeColor, unknownColor: $unknownColor, googleAnalytics: $googleAnalytics, subscribeBySms: $subscribeBySms, smsService: $smsService, twilioSid: $twilioSid, twilioToken: $twilioToken, twilioSender: $twilioSender, esendexUsername: $esendexUsername, esendexPassword: $esendexPassword, esendexAccountRef: $esendexAccountRef, nexmoKey: $nexmoKey, nexmoSecret: $nexmoSecret, nexmoSender: $nexmoSender, htmlInMeta: $htmlInMeta, htmlAboveHeader: $htmlAboveHeader, htmlBelowHeader: $htmlBelowHeader, htmlAboveFooter: $htmlAboveFooter, htmlBelowFooter: $htmlBelowFooter, htmlBelowSummary: $htmlBelowSummary, cssGlobal: $cssGlobal, launchDate: $launchDate, dateFormat: $dateFormat, dateFormatShort: $dateFormatShort, timeFormat: $timeFormat, private: $private, useAllowList: $useAllowList, translations: $translations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a status page
#
# DELETE /v2/{page_id}
export def "status-pages delete" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/($page_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all your status page components
#
# GET /v1/{page_id}/components
export def "components list" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number for pagination (default: 1)
  --per-page: int # Number of items per page (default: 50)
]: nothing -> table<id: string, name: string, uniqueEmail: string, description: string, status: string, order: int, group: any, nameTranslationId: string, descriptionTranslationId: string, showUptime: bool, createdAt: string, updatedAt: string, archivedAt: string, siteId: string, groupId: string, nameHtml: string, nameHtmlTranslationId: string, descriptionHtml: string, descriptionHtmlTranslationId: string, isThirdParty: bool, thirdPartyStatus: string, thirdPartyComponentId: string, thirdPartyComponentServiceId: string, importedFromStatuspage: bool, startDate: string, translations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($page_id)/components" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a component
#
# POST /v1/{page_id}/components
export def "components post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
  --status: string@status-completer-1
  --order: int # The order of the component on the status page.
  --showUptime: oneof<nothing, bool> # Whether to show the percentage and uptime bar for the component.
  --grouped: oneof<nothing, bool> # Whether the component is a parent component or not, If set to true, make sure to set the group parent id in the `group` field.
  --group: string # The id of the component to group under. (nullable)
  --archived: oneof<nothing, bool>
  --translations: record # Object containing translations where each key is a property name and the value is an object with language codes as keys and translations as values. The language code as the key (e.g., 'en', 'fr') and the translation as the value. (e.g. {name: {en: This will be displayed for English users, fr: Ceci sera affiché pour les utilisateurs francophones}, description: {en: Example description in English, fr: Exemple de description en français}})
]: any -> record<id: string, name: string, uniqueEmail: string, description: string, status: string, order: int, group: any, nameTranslationId: string, descriptionTranslationId: string, showUptime: bool, createdAt: string, updatedAt: string, archivedAt: string, siteId: string, groupId: string, nameHtml: string, nameHtmlTranslationId: string, descriptionHtml: string, descriptionHtmlTranslationId: string, isThirdParty: bool, thirdPartyStatus: string, thirdPartyComponentId: string, thirdPartyComponentServiceId: string, importedFromStatuspage: bool, startDate: string, translations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/components")
  let body = {name: $name, description: $description, status: $status, order: $order, showUptime: $showUptime, grouped: $grouped, group: $group, archived: $archived, translations: $translations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a component
#
# GET /v1/{page_id}/components/{component_id}
export def "components get" [
  page_id: string
  component_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, uniqueEmail: string, description: string, status: string, order: int, group: any, nameTranslationId: string, descriptionTranslationId: string, showUptime: bool, createdAt: string, updatedAt: string, archivedAt: string, siteId: string, groupId: string, nameHtml: string, nameHtmlTranslationId: string, descriptionHtml: string, descriptionHtmlTranslationId: string, isThirdParty: bool, thirdPartyStatus: string, thirdPartyComponentId: string, thirdPartyComponentServiceId: string, importedFromStatuspage: bool, startDate: string, translations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/components/($component_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a component
#
# PUT /v1/{page_id}/components/{component_id}
export def "components put" [
  page_id: string
  component_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --description: string
  --status: string@status-completer-1
  --order: int # The order of the component on the status page.
  --showUptime: oneof<nothing, bool> # Whether to show the percentage and uptime bar for the component.
  --grouped: oneof<nothing, bool>
  --archived: oneof<nothing, bool>
  --translations: record # Object containing translations where each key is a property name and the value is an object with language codes as keys and translations as values. The language code as the key (e.g., 'en', 'fr') and the translation as the value. (e.g. {name: {en: This will be displayed for English users, fr: Ceci sera affiché pour les utilisateurs francophones}, description: {en: Example description in English, fr: Exemple de description en français}})
]: any -> record<id: string, name: string, uniqueEmail: string, description: string, status: string, order: int, group: any, nameTranslationId: string, descriptionTranslationId: string, showUptime: bool, createdAt: string, updatedAt: string, archivedAt: string, siteId: string, groupId: string, nameHtml: string, nameHtmlTranslationId: string, descriptionHtml: string, descriptionHtmlTranslationId: string, isThirdParty: bool, thirdPartyStatus: string, thirdPartyComponentId: string, thirdPartyComponentServiceId: string, importedFromStatuspage: bool, startDate: string, translations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/components/($component_id)")
  let body = {name: $name, description: $description, status: $status, order: $order, showUptime: $showUptime, grouped: $grouped, archived: $archived, translations: $translations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a component
#
# DELETE /v1/{page_id}/components/{component_id}
export def "components delete" [
  page_id: string
  component_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/components/($component_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all page incidents
#
# GET /v1/{page_id}/incidents
export def "incidents list" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number for pagination (default: 1)
  --per-page: int # Number of items per page (default: 50)
  --status: string # Comma-separated list of statuses to **include** Knowing Statuses are: `INVESTIGATING`, `IDENTIFIED`, `MONITORING`, `RESOLVED`
  --status: string # Comma-separated list of statuses to **exclude** Knowing Statuses are: `INVESTIGATING`, `IDENTIFIED`, `MONITORING`, `RESOLVED`
]: nothing -> table<id: string, name: string, status: string, started: string, duration: int, resolved: string, updates: list<record>, components: list<record>, translations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "!status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($page_id)/incidents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an incident
#
# POST /v1/{page_id}/incidents
# --statuses item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
export def "incidents post-by-page_id" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --message: string
  --components: list # The ids of the components that are affected by the incident.
  --started: string # The date and time the incident started, If left empty the time will be set to the current time. (format: date-time)
  status: string@status-completer-2
  --notify: oneof<nothing, bool> # Whether to notify the subscribers of the page and the affected components.
  --shouldPublish: oneof<nothing, bool> # Whether to publish the incident to the page. (default: true)
  --statuses: list # The statuses of the components that are affected by the incident update. **Make sure the components are also included in the `components` field.** — item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
  --translations: record # Object containing translations where each key is a property name and the value is an object with language codes as keys and translations as values. The language code as the key (e.g., 'en', 'fr') and the translation as the value. (e.g. {name: {en: This will be displayed for English users, fr: Ceci sera affiché pour les utilisateurs francophones}, description: {en: Example description in English, fr: Exemple de description en français}})
]: any -> record<id: string, name: string, status: string, started: string, duration: int, resolved: string, updates: table<id: string, message: string, messageHtml: string, status: string, notify: bool, started: string, ended: string, duration: int, createdAt: string>, components: table<id: string, name: string, status: string, showUptime: bool, site: record>, translations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/incidents")
  let body = {name: $name, message: $message, components: $components, started: $started, status: $status, notify: $notify, shouldPublish: $shouldPublish, statuses: $statuses, translations: $translations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an incident
#
# GET /v1/{page_id}/incidents/{incident_id}
export def "incidents get" [
  page_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, status: string, started: string, duration: int, resolved: string, updates: table<id: string, message: string, messageHtml: string, status: string, notify: bool, started: string, ended: string, duration: int, createdAt: string>, components: table<id: string, name: string, status: string, showUptime: bool, site: record>, translations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/incidents/($incident_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update incident
#
# PUT /v1/{page_id}/incidents/{incident_id}
# --statuses item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
export def "incidents put" [
  page_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --components: list # The ids of the components that are affected by the incident.
  --started: string # The date and time the incident started. (format: date-time)
  --status: string@status-completer-2
  --notify: oneof<nothing, bool> # Whether to notify the subscribers of the page and the affected components.
  --statuses: list # The statuses of the components that are affected by the incident update. **Make sure the components are also included in the `components` field.** — item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
  --translations: record # Object containing translations where each key is a property name and the value is an object with language codes as keys and translations as values. The language code as the key (e.g., 'en', 'fr') and the translation as the value. (e.g. {name: {en: This will be displayed for English users, fr: Ceci sera affiché pour les utilisateurs francophones}, description: {en: Example description in English, fr: Exemple de description en français}})
]: any -> record<id: string, name: string, status: string, started: string, duration: int, resolved: string, updates: table<id: string, message: string, messageHtml: string, status: string, notify: bool, started: string, ended: string, duration: int, createdAt: string>, components: table<id: string, name: string, status: string, showUptime: bool, site: record>, translations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/incidents/($incident_id)")
  let body = {name: $name, components: $components, started: $started, status: $status, notify: $notify, statuses: $statuses, translations: $translations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete incident
#
# DELETE /v1/{page_id}/incidents/{incident_id}
export def "incidents delete" [
  page_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/incidents/($incident_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an incident with a template
#
# POST /v1/{page_id}/incidents/{template}
export def "incidents post-by-page_id-template" [
  page_id: string
  template: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, nameTranslationId: string, notify: bool, status: string, started: string, resolved: string, duration: int, createdAt: string, updatedAt: string, automated: bool, impact: string, appId: string, updates: list<record<id: string, message: string, messageHtml: string, status: string, notify: bool, started: string, incident: record, translations: record>>, siteId: string, importedFromStatuspage: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/incidents/($template)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an incident update
#
# GET /v1/{page_id}/incidents/{incident_id}/incident-updates/{incident_update_id}
export def "incidents-incident-updates get" [
  page_id: string
  incident_id: string
  incident_update_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, message: string, messageHtml: string, status: string, notify: bool, started: string, incident: record<id: string, name: string, started: string, status: string, components: list<record>>, translations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/incidents/($incident_id)/incident-updates/($incident_update_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit an incident update
#
# PUT /v1/{page_id}/incidents/{incident_id}/incident-updates/{incident_update_id}
# --statuses item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
export def "incidents-incident-updates put" [
  page_id: string
  incident_id: string
  incident_update_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message: string
  --components: list # The ids of the components that are affected by the incident.
  --started: string # The date and time the incident update happened. (format: date-time)
  --status: string@status-completer-2
  --notify: oneof<nothing, bool> # Whether to notify the subscribers of the page and the affected components.
  --statuses: list # The statuses of the components that are affected by the incident update. **Make sure the components are also included in the `components` field.** — item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
  --translations: record # Object containing translations where each key is a property name and the value is an object with language codes as keys and translations as values. The language code as the key (e.g., 'en', 'fr') and the translation as the value. (e.g. {name: {en: This will be displayed for English users, fr: Ceci sera affiché pour les utilisateurs francophones}, description: {en: Example description in English, fr: Exemple de description en français}})
]: any -> record<id: string, message: string, messageHtml: string, status: string, notify: bool, started: string, incident: record<id: string, name: string, started: string, status: string, components: list<record>>, translations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/incidents/($incident_id)/incident-updates/($incident_update_id)")
  let body = {message: $message, components: $components, started: $started, status: $status, notify: $notify, statuses: $statuses, translations: $translations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an incident update
#
# DELETE /v1/{page_id}/incidents/{incident_id}/incident-updates/{incident_update_id}
export def "incidents-incident-updates delete" [
  page_id: string
  incident_id: string
  incident_update_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/incidents/($incident_id)/incident-updates/($incident_update_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an incident update
#
# POST /v1/{page_id}/incidents/{incident_id}/incident-updates
# --statuses item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
export def "incidents-incident-updates post-by-page_id-incident_id" [
  page_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message: string
  components: list # The ids of the components that are affected by the incident.
  --started: string # The date and time the incident update happened, If left empty the time will be set to the current time. (format: date-time)
  status: string@status-completer-2
  --notify: oneof<nothing, bool> # Whether to notify the subscribers of the page and the affected components.
  statuses: list # The statuses of the components that are affected by the incident update. **Make sure the components are also included in the `components` field.** — item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
  --translations: record # Object containing translations where each key is a property name and the value is an object with language codes as keys and translations as values. The language code as the key (e.g., 'en', 'fr') and the translation as the value. (e.g. {name: {en: This will be displayed for English users, fr: Ceci sera affiché pour les utilisateurs francophones}, description: {en: Example description in English, fr: Exemple de description en français}})
]: any -> record<id: string, message: string, messageHtml: string, status: string, notify: bool, started: string, incident: record<id: string, name: string, started: string, status: string, components: list<record>>, translations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/incidents/($incident_id)/incident-updates")
  let body = {message: $message, components: $components, started: $started, status: $status, notify: $notify, statuses: $statuses, translations: $translations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resolve an incident with a template
#
# POST /v2/{page_id}/incidents/{incident_id}/incident-updates/{template}
export def "incidents-incident-updates post-by-page_id-incident_id-template" [
  page_id: string
  incident_id: string
  template: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, message: string, messageTranslationId: string, status: string, notify: bool, started: string, ended: string, duration: int, createdAt: string, updatedAt: string, incidentId: string, messageHtml: string, messageHtmlTranslationId: string, importedFromStatuspage: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/($page_id)/incidents/($incident_id)/incident-updates/($template)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all page maintenances
#
# GET /v1/{page_id}/maintenances
export def "maintenances list" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number for pagination (default: 1)
  --per-page: int # Number of items per page (default: 50)
]: nothing -> table<id: string, name: string, status: string, start: string, duration: int, notifyStart: bool, notifyEnd: bool, notifyEarly: bool, notifyMinutes: int, autoStart: bool, autoEnd: bool, updates: list<record>, components: list<record>, translations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($page_id)/maintenances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a maintenance
#
# POST /v1/{page_id}/maintenances
# --statuses item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
export def "maintenances post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --message: string
  components: list # The ids of the components that are affected by the maintenance.
  start: string # The date and time the maintenance will start in ISO-8601 format (UTC Timezone). (format: date-time)
  end: string # The date and time the maintenance will end in ISO-8601 format (UTC Timezone). (format: date-time)
  status: string@status-completer-3
  --notify: oneof<nothing, bool> # Whether to notify the subscribers of the page and the affected components.
  --duration: int # How many minutes the maintenance will last since the `start` date and time if `autoEnd` is set to `true`.
  --notifyStart: oneof<nothing, bool> # Whether to notify the subscribers of the page and the affected components when the maintenance **starts**.
  --notifyEnd: oneof<nothing, bool> # Whether to notify the subscribers of the page and the affected components when the maintenance **ends**.
  --notifyEarly: oneof<nothing, bool> # Whether to notify the subscribers of the page and the affected components before the maintenance starts.
  --notifyMinutes: int # The number of minutes before the maintenance starts that the subscribers will be notified.
  --autoStart: oneof<nothing, bool> # Whether to automatically start the maintenance automatically when the date and time reaches the `start` date and time.
  --autoEnd: oneof<nothing, bool> # Whether to automatically end the maintenance automatically when the date and time« reaches the `end` date and time.
  --isCollapsed: oneof<nothing, bool> # Whether the maintenance is collapsed or not on the page.
  --expandAt: string # The date and time the maintenance will expand at in ISO-8601 format (UTC Timezone). (format: date-time)
  --statuses: list # The statuses of the components that are affected by the maintenance update. **Make sure the components are also included in the `components` field.** — item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
  --translations: record # Object containing translations where each key is a property name and the value is an object with language codes as keys and translations as values. The language code as the key (e.g., 'en', 'fr') and the translation as the value. (e.g. {name: {en: This will be displayed for English users, fr: Ceci sera affiché pour les utilisateurs francophones}, description: {en: Example description in English, fr: Exemple de description en français}})
]: any -> record<id: string, name: string, status: string, start: string, duration: int, notifyStart: bool, notifyEnd: bool, notifyEarly: bool, notifyMinutes: int, autoStart: bool, autoEnd: bool, updates: table<id: string, message: string, messageHtml: string, status: string, notify: bool, started: string, ended: string, duration: int, createdAt: string>, components: table<id: string, name: string, status: string, showUptime: bool, site: record, subscribers: list>, translations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/maintenances")
  let body = {name: $name, message: $message, components: $components, start: $start, end: $end, status: $status, notify: $notify, duration: $duration, notifyStart: $notifyStart, notifyEnd: $notifyEnd, notifyEarly: $notifyEarly, notifyMinutes: $notifyMinutes, autoStart: $autoStart, autoEnd: $autoEnd, isCollapsed: $isCollapsed, expandAt: $expandAt, statuses: $statuses, translations: $translations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a maintenance
#
# GET /v1/{page_id}/maintenances/{maintenance_id}
export def "maintenances get" [
  page_id: string
  maintenance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, status: string, start: string, duration: int, notifyStart: bool, notifyEnd: bool, notifyEarly: bool, notifyMinutes: int, autoStart: bool, autoEnd: bool, updates: table<id: string, message: string, messageHtml: string, status: string, notify: bool, started: string, ended: string, duration: int, createdAt: string>, components: table<id: string, name: string, status: string, showUptime: bool, site: record, subscribers: list>, translations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/maintenances/($maintenance_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update maintenance
#
# PUT /v1/{page_id}/maintenances/{maintenance_id}
# --statuses item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
export def "maintenances put" [
  page_id: string
  maintenance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  message: string # The message of the maintenance.
  components: list # The ids of the components that are affected by the maintenance.
  start: string # The date and time the maintenance will start. (format: date-time)
  end: string # The date and time the maintenance will end. (format: date-time)
  status: string@status-completer-3
  --notify: oneof<nothing, bool> # Whether to notify the subscribers of the page and the affected components.
  --autoStart: oneof<nothing, bool> # Whether to automatically start the maintenance automatically when the date and time reaches the `start` date and time.
  --autoEnd: oneof<nothing, bool> # Whether to automatically end the maintenance automatically when the date and time« reaches the `end` date and time.
  duration: int # How many minutes the maintenance will last since the `start` date and time if `autoEnd` is set to `true`.
  statuses: list # The statuses of the components that are affected by the maintenance update. **Make sure the components are also included in the `components` field.** — item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
  --translations: record # Object containing translations where each key is a property name and the value is an object with language codes as keys and translations as values. The language code as the key (e.g., 'en', 'fr') and the translation as the value. (e.g. {name: {en: This will be displayed for English users, fr: Ceci sera affiché pour les utilisateurs francophones}, description: {en: Example description in English, fr: Exemple de description en français}})
]: any -> record<id: string, name: string, status: string, start: string, duration: int, notifyStart: bool, notifyEnd: bool, notifyEarly: bool, notifyMinutes: int, autoStart: bool, autoEnd: bool, updates: table<id: string, message: string, messageHtml: string, status: string, notify: bool, started: string, ended: string, duration: int, createdAt: string>, components: table<id: string, name: string, status: string, showUptime: bool, site: record, subscribers: list>, translations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/maintenances/($maintenance_id)")
  let body = {name: $name, message: $message, components: $components, start: $start, end: $end, status: $status, notify: $notify, autoStart: $autoStart, autoEnd: $autoEnd, duration: $duration, statuses: $statuses, translations: $translations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete maintenance
#
# DELETE /v1/{page_id}/maintenances/{maintenance_id}
export def "maintenances delete" [
  page_id: string
  maintenance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/maintenances/($maintenance_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a maintenance update
#
# GET /v1/{page_id}/maintenances/{maintenance_id}/maintenance-updates/{maintenance_update_id}
export def "maintenances-maintenance-updates get" [
  page_id: string
  maintenance_id: string
  maintenance_update_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, message: string, messageHtml: string, notify: bool, started: string, status: string, maintenance: record<id: string, name: string, start: string, status: string, components: list<record>>, translations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/maintenances/($maintenance_id)/maintenance-updates/($maintenance_update_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a maintenance update
#
# PUT /v1/{page_id}/maintenances/{maintenance_id}/maintenance-updates/{maintenance_update_id}
# --statuses item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
export def "maintenances-maintenance-updates put" [
  page_id: string
  maintenance_id: string
  maintenance_update_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message: string
  --components: list # The ids of the components that are affected by the maintenance update.
  --started: string # format: date-time
  --end: string # format: date-time
  --status: string@status-completer-3
  --notify: oneof<nothing, bool>
  --statuses: list # The statuses of the components that are affected by the maintenance update. **Make sure the components are also included in the `components` field.** — item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
  --translations: record # Object containing translations where each key is a property name and the value is an object with language codes as keys and translations as values. The language code as the key (e.g., 'en', 'fr') and the translation as the value. (e.g. {name: {en: This will be displayed for English users, fr: Ceci sera affiché pour les utilisateurs francophones}, description: {en: Example description in English, fr: Exemple de description en français}})
]: any -> record<id: string, message: string, messageHtml: string, notify: bool, started: string, status: string, maintenance: record<id: string, name: string, start: string, status: string, components: list<record>>, translations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/maintenances/($maintenance_id)/maintenance-updates/($maintenance_update_id)")
  let body = {message: $message, components: $components, started: $started, end: $end, status: $status, notify: $notify, statuses: $statuses, translations: $translations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a maintenance update
#
# DELETE /v1/{page_id}/maintenances/{maintenance_id}/maintenance-updates/{maintenance_update_id}
export def "maintenances-maintenance-updates delete" [
  page_id: string
  maintenance_id: string
  maintenance_update_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/maintenances/($maintenance_id)/maintenance-updates/($maintenance_update_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a maintenance update
#
# POST /v1/{page_id}/maintenances/{maintenance_id}/maintenance-updates
# --statuses item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
export def "maintenances-maintenance-updates post" [
  page_id: string
  maintenance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message: string
  --components: list # The ids of the components that are affected by the maintenance update.
  --started: string # format: date-time
  --end: string # format: date-time
  --status: string@status-completer-3
  --notify: oneof<nothing, bool> # Whether to notify the subscribers of the page and the affected components about the maintenance update.
  --statuses: list # The statuses of the components that are affected by the maintenance update. **Make sure the components are also included in the `components` field.** — item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
  --translations: record # Object containing translations where each key is a property name and the value is an object with language codes as keys and translations as values. The language code as the key (e.g., 'en', 'fr') and the translation as the value. (e.g. {name: {en: This will be displayed for English users, fr: Ceci sera affiché pour les utilisateurs francophones}, description: {en: Example description in English, fr: Exemple de description en français}})
]: any -> record<id: string, message: string, messageHtml: string, notify: bool, started: string, status: string, maintenance: record<id: string, name: string, start: string, status: string, components: list<record>>, translations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/maintenances/($maintenance_id)/maintenance-updates")
  let body = {message: $message, components: $components, started: $started, end: $end, status: $status, notify: $notify, statuses: $statuses, translations: $translations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all page templates
#
# GET /v1/{page_id}/templates
export def "templates list" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number for pagination (default: 1)
  --per-page: int # Number of items per page (default: 50)
]: nothing -> table<id: string, type: string, name: string, nameTranslationId: string, message: string, messageTranslationId: string, messageHtml: string, messageHtmlTranslationId: string, status: string, notify: bool, createdAt: string, siteId: string, importedFromStatuspage: bool, deletedAt: string, origin: string, components: list<record>, translations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($page_id)/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a template
#
# POST /v1/{page_id}/templates
# --components item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
export def "templates post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer # Whether this template is used to create incidents or maintenances.
  subdomain: string # The subdomain of the page to create the template in
  name: string # The name of the notice it creates.
  message: string # The message for the first update of the notice it creates.
  status: string@status-completer-4 # The status of the notice when it's created using the template. **Incident Options:**  - `INVESTIGATING` - `IDENTIFIED` - `MONITORING` - `RESOLVED`  **Maintenance options:**  - `NOTSTARTEDYET` - `INPROGRESS` - `COMPLETED`
  --notify: oneof<nothing, bool> # Whether to notify the subscribers of the page and the affected components when a notice is created using this template.
  components: list # The list of components that are affected by the incident or maintenance. — item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
  --translations: record # Object containing translations where each key is a property name and the value is an object with language codes as keys and translations as values. The language code as the key (e.g., 'en', 'fr') and the translation as the value. (e.g. {name: {en: This will be displayed for English users, fr: Ceci sera affiché pour les utilisateurs francophones}, description: {en: Example description in English, fr: Exemple de description en français}})
]: any -> record<id: string, type: string, name: string, nameTranslationId: string, message: string, messageTranslationId: string, messageHtml: string, messageHtmlTranslationId: string, status: string, notify: bool, createdAt: string, siteId: string, importedFromStatuspage: bool, deletedAt: string, origin: string, components: table<id: string, status: string, componentId: string, templateId: string, importedFromStatuspage: bool>, translations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/templates")
  let body = {type: $type, subdomain: $subdomain, name: $name, message: $message, status: $status, notify: $notify, components: $components, translations: $translations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a template
#
# GET /v1/{page_id}/templates/{template_id}
export def "templates get" [
  page_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, name: string, nameTranslationId: string, message: string, messageTranslationId: string, messageHtml: string, messageHtmlTranslationId: string, status: string, notify: bool, createdAt: string, siteId: string, importedFromStatuspage: bool, deletedAt: string, origin: string, components: table<id: string, status: string, componentId: string, templateId: string, importedFromStatuspage: bool>, translations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/templates/($template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update template
#
# PUT /v1/{page_id}/templates/{template_id}
# --components item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
export def "templates put" [
  page_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # Whether this template is used to create incidents or maintenances.
  --name: string # The name of the notice it creates.
  --message: string # The message for the first update of the notice it creates.
  --status: string@status-completer-4 # The status of the notice when it's created using the template. **Incident Options:**  - `INVESTIGATING` - `IDENTIFIED` - `MONITORING` - `RESOLVED`  **Maintenance options:**  - `NOTSTARTEDYET` - `INPROGRESS` - `COMPLETED`
  --notify: oneof<nothing, bool> # Whether to notify the subscribers of the page and the affected components.
  --components: list # The list of components that are affected by the incident or maintenance. — item shape: {id?: string, status?: "OPERATIONAL"|"UNDERMAINTENANCE"|"DEGRADEDPERFORMANCE"|"PARTIALOUTAGE"|"MAJOROUTAGE"}
  --translations: record # Object containing translations where each key is a property name and the value is an object with language codes as keys and translations as values. The language code as the key (e.g., 'en', 'fr') and the translation as the value. (e.g. {name: {en: This will be displayed for English users, fr: Ceci sera affiché pour les utilisateurs francophones}, description: {en: Example description in English, fr: Exemple de description en français}})
]: any -> record<id: string, type: string, name: string, nameTranslationId: string, message: string, messageTranslationId: string, messageHtml: string, messageHtmlTranslationId: string, status: string, notify: bool, createdAt: string, siteId: string, importedFromStatuspage: bool, deletedAt: string, origin: string, components: table<id: string, status: string, componentId: string, templateId: string, importedFromStatuspage: bool>, translations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/templates/($template_id)")
  let body = {type: $type, name: $name, message: $message, status: $status, notify: $notify, components: $components, translations: $translations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete template
#
# DELETE /v1/{page_id}/templates/{template_id}
export def "templates delete" [
  page_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, message: string, createdAt: string, site: record<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/templates/($template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get teammates
#
# GET /v1/{page_id}/team
export def "team get" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number for pagination (default: 1)
  --per-page: int # Number of items per page (default: 50)
]: nothing -> table<id: string, user: record<id: string, name: string, email: string, avatar: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($page_id)/team" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a team member
#
# POST /v1/{page_id}/team
export def "team post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email of the teammate you wish to add.
  permission: string@permission-completer # The permissions of the teammate.
  --audienceGroups: list # The ids of the audience groups you wish to add the teammate to. (nullable)
  --team: string # The id of the team you want to include the teammate in. (nullable)
]: any -> record<email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/team")
  let body = {email: $email, permission: $permission, audienceGroups: $audienceGroups, team: $team} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a team member
#
# DELETE /v1/{page_id}/team/{member_id}
export def "team delete" [
  page_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<memberId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/team/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get subscribers
#
# GET /v1/{page_id}/subscribers
export def "subscribers get-by-page_id" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number for pagination (default: 1)
  --per-page: int # Number of items per page (default: 50)
  --search: string # Filter subscribers by email address or phone number
]: nothing -> table<id: string, email: string, phone: string, webhook: string, webhookEmail: string, confirmed: bool, all: bool, components: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($page_id)/subscribers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a subscriber
#
# POST /v1/{page_id}/subscribers
export def "subscribers post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # The email of the subscriber.
  --phone: string # The phone number of the subscriber.
  --webhook: string # The webhook URL of the subscriber.
  --webhookEmail: string # The webhook email of the webhook subscriber. This is used to send email to the subscriber when a webhook request does not receive a positive response.
  --all: oneof<nothing, bool> # Whether the subscriber is subscribed to all components on the page or not.
  --autoConfirm: oneof<nothing, bool> # Whether the subscriber is automatically confirmed or will receive an email to confirm their subscription.
  --components: list # The ids of the components that the subscriber will be subscribed to, Leave as null if `all` is set to true. (nullable)
  --language: string # The language of the subscriber in language code (e.g. `en` for English, `fr` for French, `de` for German, etc.).
]: any -> record<id: string, name: string, email: string, phone: string, confirmed: bool, all: bool, createdAt: string, updatedAt: string, siteId: string, unsubscribeToken: string, webhook: string, webhookEmail: string, discord: string, discordTeam: string, slack: string, slackTeam: string, language: string, company: string, microsoftTeamsWebhook: string, googleChatWebhook: string, googleChatSpace: string, failedAttempts: int, approved: bool, importedFromStatuspage: bool, hideUnsubLink: bool, webhookIncidentBody: string, webhookMaintenanceBody: string, webhookComponentBody: string, webhookHttpMethod: string, webhookHeaders: record, webhookQueryParams: record, site: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/subscribers")
  let body = {email: $email, phone: $phone, webhook: $webhook, webhookEmail: $webhookEmail, all: $all, autoConfirm: $autoConfirm, components: $components, language: $language} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add multiple subscribers
#
# POST /v1/{page_id}/subscribers/bulk
# --subscribers item shape: {email?: string, phone?: string, webhook?: string, webhookEmail?: string, all?: bool, autoConfirm?: bool, components?: list, language?: string}
export def "subscribers-bulk post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subscribers: list # Array of subscriber objects to create. — item shape: {email?: string, phone?: string, webhook?: string, webhookEmail?: string, all?: bool, autoConfirm?: bool, components?: list, language?: string}
  --autoConfirm: oneof<nothing, bool> # Whether subscribers are automatically confirmed or will receive an email to confirm their subscription. Applies to all subscribers in the batch. This is a paid feature.
]: any -> record<success: bool, created: int, failed: int, results: record<created: list<record>, failed: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/subscribers/bulk")
  let body = {subscribers: $subscribers, autoConfirm: $autoConfirm} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a subscriber
#
# DELETE /v1/{page_id}/subscribers/{subscriber_id}
export def "subscribers delete" [
  page_id: string
  subscriber_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, email: string, phone: string, webhook: string, webhookEmail: string, discord: string, microsoftTeamsWebhook: string, company: string, site: record<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/subscribers/($subscriber_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get subscribers
#
# GET /v2/{page_id}/subscribers
export def "subscribers get-by-page_id-1" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number for pagination (default: 1)
  --per-page: int # Number of items per page (default: 50)
  --search: string # Filter subscribers by email address or phone number
]: nothing -> table<id: string, email: string, phone: string, webhook: string, webhookEmail: string, confirmed: bool, all: bool, components: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($page_id)/subscribers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all metrics
#
# GET /v1/{page_id}/metrics
export def "metrics list" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number for pagination (default: 1)
  --per-page: int # Number of items per page (default: 50)
]: nothing -> table<id: string, name: string, active: bool, order: int, suffix: string, data: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($page_id)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a metric
#
# POST /v1/{page_id}/metrics
export def "metrics post-by-page_id" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the metric.
  suffix: string # The suffix of the metric. This is used to display the metric value in the format of `value suffix` e.g. `100ms` where `ms` is the suffix.
]: any -> record<id: string, name: string, active: bool, order: int, suffix: string, data: table<id: string, timestamp: int, value: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/metrics")
  let body = {name: $name, suffix: $suffix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a metric
#
# GET /v1/{page_id}/metrics/{metric_id}
export def "metrics get" [
  page_id: string
  metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, active: bool, order: int, suffix: string, data: table<id: string, timestamp: int, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/metrics/($metric_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a metric
#
# PUT /v1/{page_id}/metrics/{metric_id}
export def "metrics put" [
  page_id: string
  metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the metric.
  --suffix: string # The suffix of the metric. This is used to display the metric value in the format of `value suffix` e.g. `100ms` where `ms` is the suffix.
]: any -> record<id: string, name: string, active: bool, order: int, suffix: string, data: table<id: string, timestamp: int, value: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/metrics/($metric_id)")
  let body = {name: $name, suffix: $suffix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a metric
#
# DELETE /v1/{page_id}/metrics/{metric_id}
export def "metrics delete" [
  page_id: string
  metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/metrics/($metric_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a datapoint to a metric
#
# POST /v1/{page_id}/metrics/{metric_id}
export def "metrics post-by-page_id-metric_id" [
  page_id: string
  metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  timestamp: int # The timestamp of the datapoint in milliseconds. (format: int64)
  value: float # The value of the datapoint, during the time of the `timestamp`.
]: any -> record<id: string, timestamp: int, value: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/metrics/($metric_id)")
  let body = {timestamp: $timestamp, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add multiple datapoints to a metric
#
# POST /v1/{page_id}/metrics/{metric_id}/data
# --data item shape: {timestamp: int, value: float}
export def "metrics-data post" [
  page_id: string
  metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: list # The list of datapoints to add to the metric, Make sure the timestamps are at least 30 seconds apart. — item shape: {timestamp: int, value: float}
]: any -> table<id: string, timestamp: int, value: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/metrics/($metric_id)/data")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete datapoints from a metric
#
# DELETE /v1/{page_id}/metrics/{metric_id}/data
export def "metrics-data delete" [
  page_id: string
  metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, order: int, suffix: string, site: record<id: string, subdomain: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/metrics/($metric_id)/data")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get your user profile
#
# GET /v1/user
export def "user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, email: string, name: string, slug: string, avatar: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get public status summary
#
# GET /summary.json
export def "summaryjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page: record<name: string, url: string, status: string>, activeIncidents: table<name: string, started: string, status: string, impact: string, url: string>, activeMaintenances: table<id: string, name: string, start: string, status: string, duration: float, url: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/summary.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all your status page audience groups
#
# GET /v1/{page_id}/audience-groups
export def "audience-groups list" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number for pagination (default: 1)
  --per-page: int # Number of items per page (default: 50)
]: nothing -> table<id: string, siteId: string, name: string, teammates: list<record>, components: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($page_id)/audience-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an audience group
#
# POST /v1/{page_id}/audience-groups
export def "audience-groups post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --components: list
  --teammates: list
]: any -> record<id: string, siteId: string, name: string, site: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/audience-groups")
  let body = {name: $name, components: $components, teammates: $teammates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an audience group
#
# GET /v1/{page_id}/audience-groups/{audience_group_id}
export def "audience-groups get" [
  page_id: string
  audience_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, siteId: string, name: string, teammates: table<id: string, audienceGroupId: string, teammateId: string, teammate: record>, components: table<id: string, audienceGroupId: string, componentId: string, component: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/audience-groups/($audience_group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an audience group
#
# PUT /v1/{page_id}/audience-groups/{audience_group_id}
export def "audience-groups put" [
  page_id: string
  audience_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --components: list
]: any -> record<id: string, siteId: string, name: string, site: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/audience-groups/($audience_group_id)")
  let body = {components: $components} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an audience group
#
# DELETE /v1/{page_id}/audience-groups/{audience_group_id}
export def "audience-groups delete" [
  page_id: string
  audience_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, siteId: string, name: string, site: record<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/audience-groups/($audience_group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Regenerate your secure link
#
# POST /v1/{page_id}/regenerate-secure-link
export def "regenerate-secure-link post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, secureLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($page_id)/regenerate-secure-link")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check Inserted Logs
#
# GET /monitors/check_inserted_logs
export def "monitors-check-inserted-logs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/monitors/check_inserted_logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Monitors
#
# GET /{page_id}/monitors
export def "monitors get" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of monitors per page (default: 100)
  --search: string # Search term for filtering results.
  --status: string@status-completer-5
]: nothing -> record<monitors: table<pageId: string, url: string, httpMethod: string, body: string, headers: record, queryParams: record, basicAuth: record, type: string, assertions: list, alerts: list, name: string, locations: list, checksInterval: int, onFail: record, onRecover: record, createdAt: string, updatedAt: string>, total: int, page: int, totalPages: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($page_id)/monitors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Monitor
#
# POST /monitors
# --basicAuth shape: {username?: string, password?: string}
# --assertions item shape: {id?: string, type?: "AVAILABLE"|"BODY"|"PING"|"TCP"|"DNS"|"STATUSCODE"|"JSONBODY"|"HEADERS"|"RESPONSETIME", comparison?: "EQUALS"|"NOT_EQUALS"|"IS_EMPTY"|"NOT_EMPTY"|"GREATER_THAN"|"GREATER_THAN_OR_EQUALS"|"LESS_THAN"|"LESS_THAN_OR_EQUALS"|"CONTAINS"|"NOT_CONTAINS"|"HAS_KEY"|"NOT_HAS_KEY"|"HAS_VALUE"|"NOT_HAS_VALUE"|"IS_NULL"|"NOT_NULL"|"STARTS_WITH"|"ENDS_WITH", selector?: string, target?: string}
# --onFail shape: {createIncident?: bool, createOutageDuration?: bool, publishIncident?: bool, notifySubscribers?: bool}
# --onRecover shape: {resolveIncident?: bool, resolveOutageDuration?: bool, publishIncident?: bool, notifySubscribers?: bool}
export def "monitors post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  pageId: string # The id of the status page of the monitor to create the monitor on.
  --body-url: string
  httpMethod: string@httpMethod-completer
  --body-body: string # nullable
  --headers: record
  --queryParams: record
  --basicAuth: record # shape: {username?: string, password?: string}
  --type: string@type-completer-1
  --assertions: list # item shape: {id?: string, type?: "AVAILABLE"|"BODY"|"PING"|"TCP"|"DNS"|"STATUSCODE"|"JSONBODY"|"HEADERS"|"RESPONSETIME", comparison?: "EQUALS"|"NOT_EQUALS"|"IS_EMPTY"|"NOT_EMPTY"|"GREATER_THAN"|"GREATER_THAN_OR_EQUALS"|"LESS_THAN"|"LESS_THAN_OR_EQUALS"|"CONTAINS"|"NOT_CONTAINS"|"HAS_KEY"|"NOT_HAS_KEY"|"HAS_VALUE"|"NOT_HAS_VALUE"|"IS_NULL"|"NOT_NULL"|"STARTS_WITH"|"ENDS_WITH", selector?: string, target?: string}
  --alerts: list # The ids of the alerts to send when the monitor triggers an alert.
  --name: string
  --locations: list
  --checksInterval: int # The interval in seconds between each monitor check.
  --createComponent: oneof<nothing, bool> # Whether to create a component that will follow the status of the monitor on the status page.
  --createMetric: oneof<nothing, bool> # Whether to create a metric that will show the response time of the monitor on the status page.
  --onFail: record # shape: {createIncident?: bool, createOutageDuration?: bool, publishIncident?: bool, notifySubscribers?: bool}
  --onRecover: record # shape: {resolveIncident?: bool, resolveOutageDuration?: bool, publishIncident?: bool, notifySubscribers?: bool}
]: any -> record<monitor: record<pageId: string, url: string, httpMethod: string, body: string, headers: record, queryParams: record, basicAuth: record<username: string, password: string>, type: string, assertions: list<record>, alerts: list<string>, name: string, locations: list<string>, checksInterval: int, onFail: record<createIncident: bool, createOutageDuration: bool, publishIncident: bool, notifySubscribers: bool>, onRecover: record<resolveIncident: bool, resolveOutageDuration: bool, publishIncident: bool, notifySubscribers: bool>, createdAt: string, updatedAt: string>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/monitors")
  let body = {pageId: $pageId, url: $body_url, httpMethod: $httpMethod, body: $body_body, headers: $headers, queryParams: $queryParams, basicAuth: $basicAuth, type: $type, assertions: $assertions, alerts: $alerts, name: $name, locations: $locations, checksInterval: $checksInterval, createComponent: $createComponent, createMetric: $createMetric, onFail: $onFail, onRecover: $onRecover} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a Monitor's Group
#
# PUT /monitors/{id}/group
export def "monitors-group put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parentId: string # The id of the parent monitor group to add the monitor to, leave as null to unparent the monitor completely. (nullable)
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/monitors/($id)/group")
  let body = {parentId: $parentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a Monitor
#
# PUT /monitors/{id}
export def "monitors put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string
  --name: string
]: any -> record<monitor: record<pageId: string, url: string, httpMethod: string, body: string, headers: record, queryParams: record, basicAuth: record<username: string, password: string>, type: string, assertions: list<record>, alerts: list<string>, name: string, locations: list<string>, checksInterval: int, onFail: record<createIncident: bool, createOutageDuration: bool, publishIncident: bool, notifySubscribers: bool>, onRecover: record<resolveIncident: bool, resolveOutageDuration: bool, publishIncident: bool, notifySubscribers: bool>, createdAt: string, updatedAt: string>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/monitors/($id)")
  let body = {url: $body_url, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Monitor
#
# DELETE /monitors/{id}
export def "monitors delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/monitors/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Monitor Alert
#
# POST /monitor-alerts
export def "monitor-alerts post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-2 # The type of message that will be sent when the monitor triggers an alert. * `EMAIL` - Email Alert * `SMS` - SMS Alert * `SLACK` - Slack Alert * `DISCORD` - Discord Alert * `MICROSOFT_TEAMS` - Microsoft Teams Alert * `PHONE_CALL` - Phone Call Alert * `WEBHOOK` - Webhook Alert
  pageId: string # The id of the status page of the monitor to create the monitor alert on.
  recipient: string # The recipient of this alert, This depends on the type of alert. **For example:** * `EMAIL` - Email address * `SMS` and `PHONE_CALL` - Phone number * `SLACK`, `DISCORD`, and `WEBHOOK` - Webhook URL  * `MICROSOFT_TEAMS` - Email address or webhook URL
  --recipientWorkspace: string
  --whenFails: oneof<nothing, bool> # Whether to send an alert when the monitor fails.
  --whenRecovers: oneof<nothing, bool> # Whether to send an alert when the monitor recovers from a failure or degraded state.
  --whenDegrades: oneof<nothing, bool> # Whether to send an alert when the monitor degrades.
  --whenSslExpires: oneof<nothing, bool> # Whether to send an alert when the SSL certificate expires.
  --sslExpiresInDays: int # The number of days left until the SSL certificate expires so the alert will trigger, for example if this value is 30 then the alert will trigger 30 days before the certificate expires.
  --monitors: list # The ids of the monitors this alert will trigger based on.
  --metadata: string
]: any -> record<monitor: record<id: string, siteId: string, type: string, recipient: string, whenFails: bool, whenRecovers: bool, whenDegrades: bool, whenSslExpires: bool, sslExpiresInDays: int, createdAt: string, updatedAt: string, metadata: string>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/monitor-alerts")
  let body = {type: $type, pageId: $pageId, recipient: $recipient, recipientWorkspace: $recipientWorkspace, whenFails: $whenFails, whenRecovers: $whenRecovers, whenDegrades: $whenDegrades, whenSslExpires: $whenSslExpires, sslExpiresInDays: $sslExpiresInDays, monitors: $monitors, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Monitor Alert
#
# PUT /monitor-alerts/{id}
export def "monitor-alerts put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-2 # The type of message that will be sent when the monitor triggers an alert. * `EMAIL` - Email Alert * `SMS` - SMS Alert * `SLACK` - Slack Alert * `DISCORD` - Discord Alert * `MICROSOFT_TEAMS` - Microsoft Teams Alert * `PHONE_CALL` - Phone Call Alert * `WEBHOOK` - Webhook Alert
  --monitors: list # The ids of the monitors this alert will trigger based on.
]: any -> record<monitor: record<id: string, siteId: string, type: string, recipient: string, whenFails: bool, whenRecovers: bool, whenDegrades: bool, whenSslExpires: bool, sslExpiresInDays: int, createdAt: string, updatedAt: string, metadata: string>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/monitor-alerts/($id)")
  let body = {type: $type, monitors: $monitors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Monitor Alert
#
# DELETE /monitor-alerts/{id}
export def "monitor-alerts delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/monitor-alerts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Monitor Alerts
#
# GET /{page_id}/monitor-alerts
export def "monitor-alerts get" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 100
  --page: int # default: 1
]: nothing -> record<monitorAlerts: table<id: string, siteId: string, type: string, recipient: string, whenFails: bool, whenRecovers: bool, whenDegrades: bool, whenSslExpires: bool, sslExpiresInDays: int, createdAt: string, updatedAt: string, metadata: string>, total: int, page: int, totalPages: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($page_id)/monitor-alerts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Monitor Group
#
# POST /monitors-groups
export def "monitors-groups post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  pageId: string # The id of the status page of the monitor group to create the monitor group on.
  name: string
  --childId: string
]: any -> record<monitor: record<id: string, name: string, siteId: string, collapsed: bool, monitors: list<record>, groupId: string, children: list<record>, order: int, createdAt: string, updatedAt: string, parents: list<string>, componentId: string>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/monitors-groups")
  let body = {pageId: $pageId, name: $name, childId: $childId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Monitor Group
#
# PUT /monitors-groups/{id}
export def "monitors-groups put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
]: any -> record<monitor: record<id: string, name: string, siteId: string, collapsed: bool, monitors: list<record>, groupId: string, children: list<record>, order: int, createdAt: string, updatedAt: string, parents: list<string>, componentId: string>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/monitors-groups/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Monitor Group
#
# DELETE /monitors-groups/{id}
export def "monitors-groups delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/monitors-groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Monitors to Group
#
# POST /monitors-groups/{id}/monitors
export def "monitors-groups-monitors post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  monitors: list
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/monitors-groups/($id)/monitors")
  let body = {monitors: $monitors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run Monitor Group Check
#
# GET /monitors-groups/{id}/run
export def "monitors-groups-run get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location: list
  --retry: oneof<nothing, bool> # default: false
  --monitorLogId: string
]: nothing -> record<result: string, monitorLogId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location" $location "multi") (serialize-qp "retry" $retry "scalar") (serialize-qp "monitorLogId" $monitorLogId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/monitors-groups/($id)/run" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Routing Rules
#
# GET /{page_id}/routing-rules
export def "routing-rules get" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<routingRules: table<id: string, siteId: string, assertions: list, actions: list, createdAt: string, updatedAt: string, order: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($page_id)/routing-rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Routing Rule
#
# POST /routing-rules
# --routingRule shape: {assertions?: list, actions?: list, order?: int, siteId?: string}
export def "routing-rules post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --routingRule: record # shape: {assertions?: list, actions?: list, order?: int, siteId?: string}
]: any -> record<routingRule: record<id: string, siteId: string, assertions: list<record>, actions: list<record>, createdAt: string, updatedAt: string, order: int>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/routing-rules")
  let body = {routingRule: $routingRule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Routing Rule
#
# PUT /routing-rules/{id}
# --routingRule shape: {id?: string, assertions?: list, order?: int, siteId?: string}
export def "routing-rules put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --routingRule: record # shape: {id?: string, assertions?: list, order?: int, siteId?: string}
]: any -> record<routingRule: record<id: string, siteId: string, assertions: list<record>, actions: list<record>, createdAt: string, updatedAt: string, order: int>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/routing-rules/($id)")
  let body = {routingRule: $routingRule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Routing Rule
#
# DELETE /routing-rules/{id}
export def "routing-rules delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/routing-rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Escalation Policies
#
# GET /{page_id}/escalation-policies
export def "escalation-policies get" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<escalationPolicies: table<id: string, siteId: string, name: string, description: string, rules: list, repeat: bool, repeatCount: int, repeatDelay: int, revertAcknowledgement: bool, autoResolveIncidentsAfterRepeat: bool, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($page_id)/escalation-policies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Escalation Policy
#
# POST /escalation-policies
# --rules item shape: {delayInMins?: int, condition?: "NOT_ACKNOWLEDGED", actions?: list}
export def "escalation-policies post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  pageId: string # The id of the status page of the escalation policy to create the escalation policy on.
  name: string # The name of the escalation policy.
  --description: string # The description of the escalation policy.
  rules: list # item shape: {delayInMins?: int, condition?: "NOT_ACKNOWLEDGED", actions?: list}
  --repeat: oneof<nothing, bool> # Whether the escalation policy should repeat or not after the last rule is triggered.
  repeatCount: int # The number of times the escalation policy should repeat.
  repeatDelay: int # The delay in minutes between each repeat.
  --revertAcknowledgement: oneof<nothing, bool> # Whether the escalation policy should revert the acknowledgement status of the incident after each repeat.
  --autoResolveIncidentsAfterRepeat: oneof<nothing, bool> # Whether the escalation policy should auto resolve the incident after all the repeats are completed.
]: any -> record<escalationPolicy: record<id: string, siteId: string, name: string, description: string, rules: list<record>, repeat: bool, repeatCount: int, repeatDelay: int, revertAcknowledgement: bool, autoResolveIncidentsAfterRepeat: bool, createdAt: string, updatedAt: string>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/escalation-policies")
  let body = {pageId: $pageId, name: $name, description: $description, rules: $rules, repeat: $repeat, repeatCount: $repeatCount, repeatDelay: $repeatDelay, revertAcknowledgement: $revertAcknowledgement, autoResolveIncidentsAfterRepeat: $autoResolveIncidentsAfterRepeat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Escalation Policy
#
# PUT /escalation-policies/{id}
# --rules item shape: {delayInMins?: int, condition?: "NOT_ACKNOWLEDGED", actions?: list}
export def "escalation-policies put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  pageId: string # The id of the status page of the escalation policy to create the escalation policy on.
  name: string # The name of the escalation policy.
  --description: string # The description of the escalation policy.
  rules: list # item shape: {delayInMins?: int, condition?: "NOT_ACKNOWLEDGED", actions?: list}
  --repeat: oneof<nothing, bool> # Whether the escalation policy should repeat or not after the last rule is triggered.
  repeatCount: int # The number of times the escalation policy should repeat.
  repeatDelay: int # The delay in minutes between each repeat.
  --revertAcknowledgement: oneof<nothing, bool> # Whether the escalation policy should revert the acknowledgement status of the incident after each repeat.
  --autoResolveIncidentsAfterRepeat: oneof<nothing, bool> # Whether the escalation policy should auto resolve the incident after all the repeats are completed.
]: any -> record<escalationPolicy: record<id: string, siteId: string, name: string, description: string, rules: list<record>, repeat: bool, repeatCount: int, repeatDelay: int, revertAcknowledgement: bool, autoResolveIncidentsAfterRepeat: bool, createdAt: string, updatedAt: string>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/escalation-policies/($id)")
  let body = {pageId: $pageId, name: $name, description: $description, rules: $rules, repeat: $repeat, repeatCount: $repeatCount, repeatDelay: $repeatDelay, revertAcknowledgement: $revertAcknowledgement, autoResolveIncidentsAfterRepeat: $autoResolveIncidentsAfterRepeat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Escalation Policy
#
# DELETE /escalation-policies/{id}
export def "escalation-policies delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/escalation-policies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create On-call Schedule
#
# POST /on-call-schedules
# --onCallShifts item shape: {name: string, members: list, rotationType: "DAILY"|"WEEKLY"|"CUSTOM", customRotationTypeValue?: int, customRotationTypeUnit?: "HOURS"|"DAYS"|"WEEKS", startDate: string, endDate?: string, restrictionType?: "NONE"|"TIMEOFDAY"|"TIMEINTERVALS", timeOfDayRestrictionStartTime?: string, timeOfDayRestrictionEndTime?: string, timeIntervals?: list}
export def "on-call-schedules post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the on call schedule.
  --description: string # The description of the on call schedule.
  pageId: string # The id of the page the on call schedule is created on.
  onCallShifts: list # item shape: {name: string, members: list, rotationType: "DAILY"|"WEEKLY"|"CUSTOM", customRotationTypeValue?: int, customRotationTypeUnit?: "HOURS"|"DAYS"|"WEEKS", startDate: string, endDate?: string, restrictionType?: "NONE"|"TIMEOFDAY"|"TIMEINTERVALS", timeOfDayRestrictionStartTime?: string, timeOfDayRestrictionEndTime?: string, timeIntervals?: list}
]: any -> record<id: string, name: string, description: string, status: string, onCallShifts: table<id: string, name: string, order: int, members: list, rotationType: string, customRotationTypeValue: int, customRotationTypeUnit: string, startDate: string, endDate: string, restrictionType: string, timeOfDayRestrictionStartTime: string, timeOfDayRestrictionEndTime: string, timeIntervals: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/on-call-schedules")
  let body = {name: $name, description: $description, pageId: $pageId, onCallShifts: $onCallShifts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update On-call Schedule
#
# PUT /on-call-schedules/{id}
# --onCallShifts item shape: {id?: string, name?: string, order?: int, members?: list, rotationType?: "DAILY"|"WEEKLY"|"CUSTOM", customRotationTypeValue?: int, customRotationTypeUnit?: "HOURS"|"DAYS"|"WEEKS", startDate?: string, endDate?: string, restrictionType?: "NONE"|"TIMEOFDAY"|"TIMEINTERVALS", timeOfDayRestrictionStartTime?: string, timeOfDayRestrictionEndTime?: string, timeIntervals?: list}
export def "on-call-schedules put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --description: string
  --status: string@status-completer-6 # The status of the on call schedule.  - `ACTIVE`: The on call schedule is active. - `PAUSED`: The on call schedule is paused.
  --onCallShifts: list # item shape: {id?: string, name?: string, order?: int, members?: list, rotationType?: "DAILY"|"WEEKLY"|"CUSTOM", customRotationTypeValue?: int, customRotationTypeUnit?: "HOURS"|"DAYS"|"WEEKS", startDate?: string, endDate?: string, restrictionType?: "NONE"|"TIMEOFDAY"|"TIMEINTERVALS", timeOfDayRestrictionStartTime?: string, timeOfDayRestrictionEndTime?: string, timeIntervals?: list}
]: any -> record<id: string, name: string, description: string, status: string, onCallShifts: table<id: string, name: string, order: int, members: list, rotationType: string, customRotationTypeValue: int, customRotationTypeUnit: string, startDate: string, endDate: string, restrictionType: string, timeOfDayRestrictionStartTime: string, timeOfDayRestrictionEndTime: string, timeIntervals: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/on-call-schedules/($id)")
  let body = {name: $name, description: $description, status: $status, onCallShifts: $onCallShifts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete On-call Schedule
#
# DELETE /on-call-schedules/{id}
export def "on-call-schedules delete" [
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
  let full_url = (build-url $base $"/on-call-schedules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get On-call Schedule Members
#
# GET /on-call-schedules/{id}/members
export def "on-call-schedules-members get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<currentMembers: table<id: string, name: string, email: string, phone: string, avatar: string>, nextMembers: table<id: string, name: string, email: string, phone: string, avatar: string>, allMembers: table<id: string, name: string, email: string, phone: string, avatar: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/on-call-schedules/($id)/members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get your workspaces
#
# GET /v1/workspaces
export def "workspaces get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number for pagination (default: 1)
  --per-page: int # Number of items per page (default: 50)
]: nothing -> table<id: string, createdAt: string, updatedAt: string, name: string, slug: string, avatar: string, sites: list<string>, sso: bool, organizationDomains: string, allowDomainEmails: bool, allowedDomainsDefaultPermission: string, ssoActive: bool, directorySyncActive: bool, enableMultipleOrgs: bool, allowedDomains: string, allowedEmailDomains: list<string>, referralId: string, referralCoupon: string, referralCode: string, sendNewWorkspaceMembersStatusPageUpdates: bool, sendNewWorkspaceMembersAutomationIntegrationNotifications: bool, sendNewWorkspaceMembersInvalidCustomDomainNotifications: bool, sendNewWorkspaceMembersPhoneCallNotifications: bool, sendNewWorkspaceMembersWeeklyReportsNotifications: bool, longRunningIncidentNotificationSettings: list<float>, useSSOLogin: bool, useGoogleLogin: bool, useMagiclinkLogin: bool, usePasswordLogin: bool, useGithubLogin: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a workspace
#
# POST /v1/workspaces
export def "workspaces post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --slug: string
  --sendNewWorkspaceMembersStatusPageUpdates: oneof<nothing, bool>
  --sendNewWorkspaceMembersAutomationIntegrationNotifications: oneof<nothing, bool>
  --sendNewWorkspaceMembersInvalidCustomDomainNotifications: oneof<nothing, bool>
  --sendNewWorkspaceMembersPhoneCallNotifications: oneof<nothing, bool>
  --sendNewWorkspaceMembersWeeklyReportsNotifications: oneof<nothing, bool>
  --longRunningIncidentNotificationSettings: list
]: any -> record<id: string, createdAt: string, updatedAt: string, name: string, slug: string, avatar: string, sites: list<string>, sso: bool, organizationDomains: string, allowDomainEmails: bool, allowedDomainsDefaultPermission: string, ssoActive: bool, directorySyncActive: bool, enableMultipleOrgs: bool, allowedDomains: string, allowedEmailDomains: list<string>, referralId: string, referralCoupon: string, referralCode: string, sendNewWorkspaceMembersStatusPageUpdates: bool, sendNewWorkspaceMembersAutomationIntegrationNotifications: bool, sendNewWorkspaceMembersInvalidCustomDomainNotifications: bool, sendNewWorkspaceMembersPhoneCallNotifications: bool, sendNewWorkspaceMembersWeeklyReportsNotifications: bool, longRunningIncidentNotificationSettings: list<float>, useSSOLogin: bool, useGoogleLogin: bool, useMagiclinkLogin: bool, usePasswordLogin: bool, useGithubLogin: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces")
  let body = {name: $name, slug: $slug, sendNewWorkspaceMembersStatusPageUpdates: $sendNewWorkspaceMembersStatusPageUpdates, sendNewWorkspaceMembersAutomationIntegrationNotifications: $sendNewWorkspaceMembersAutomationIntegrationNotifications, sendNewWorkspaceMembersInvalidCustomDomainNotifications: $sendNewWorkspaceMembersInvalidCustomDomainNotifications, sendNewWorkspaceMembersPhoneCallNotifications: $sendNewWorkspaceMembersPhoneCallNotifications, sendNewWorkspaceMembersWeeklyReportsNotifications: $sendNewWorkspaceMembersWeeklyReportsNotifications, longRunningIncidentNotificationSettings: $longRunningIncidentNotificationSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a workspace
#
# DELETE /v1/workspaces/{workspace_id}
export def "workspaces delete" [
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workspaces/($workspace_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
