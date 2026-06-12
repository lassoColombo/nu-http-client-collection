# Auto-generated client for Misskey API v2025.4.1-io.12b-fb6fbea074
# Source: https://misskey.io/api.json
# Auth: --token flag or $env.MISSKEY_API_TOKEN

const BASE_URL = "https://misskey.io/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MISSKEY_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://misskey.io/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def expiresAt-completer [] { ["12hours" "1day" "1hour" "1month" "1week" "1year" "3months" "6months" "indefinitely"] }
def method-completer [] { ["email" "webhook"] }
def reporterOrigin-completer [] { ["combined" "local" "remote"] }
def targetUserOrigin-completer [] { ["combined" "local" "remote"] }
def sort-completer [] { ["+createdAt" "-createdAt"] }
def icon-completer [] { ["error" "info" "success" "warning"] }
def display-completer [] { ["banner" "dialog" "normal"] }
def status-completer [] { ["active" "archived"] }
def provider-completer [] { ["hcaptcha" "mcaptcha" "none" "recaptcha" "testcaptcha" "turnstile"] }
def origin-completer [] { ["combined" "local" "remote"] }
def type-completer [] { ["all" "expired" "unused" "used"] }
def sort-completer-1 [] { ["+createdAt" "+usedAt" "-createdAt" "-usedAt"] }
def type-completer-1 [] { ["db" "deliver" "endedPollNotification" "inbox" "objectStorage" "relationship" "system" "systemWebhookDeliver" "userWebhookDeliver"] }
def state-completer [] { ["*" "delayed" "wait"] }
def type-completer-2 [] { ["deliver" "inbox"] }
def resolvedAs-completer [] { ["" "accept" "reject"] }
def target-completer [] { ["conditional" "manual"] }
def from-completer [] { ["all" "local" "remote"] }
def to-completer [] { ["all" "local" "remote"] }
def sort-completer-2 [] { ["+createdAt" "+follower" "+lastActiveDate" "+updatedAt" "-createdAt" "-follower" "-lastActiveDate" "-updatedAt"] }
def state-completer-1 [] { ["admin" "adminOrModerator" "alive" "all" "available" "moderator" "suspended"] }
def type-completer-3 [] { ["jwt" "saml"] }
def binding-completer [] { ["post" "redirect"] }
def type-completer-4 [] { ["abuseReport" "abuseReportResolved" "inactiveModeratorsInvitationOnlyChanged" "inactiveModeratorsWarning" "reportAutoResolved" "userCreated"] }
def sensitiveMediaDetection-completer [] { ["all" "local" "none" "remote"] }
def sensitiveMediaDetectionSensitivity-completer [] { ["high" "low" "medium" "veryHigh" "veryLow"] }
def federation-completer [] { ["all" "none" "specified"] }
def src-completer [] { ["all" "home" "list" "users" "users_blacklist"] }
def type-completer-5 [] { ["nameAndDescription" "nameOnly"] }
def span-completer [] { ["day" "hour"] }
def sort-completer-3 [] { ["" "+createdAt" "+name" "+size" "-createdAt" "-name" "-size"] }
def sort-completer-4 [] { ["" "+firstRetrievedAt" "+followers" "+following" "+latestRequestReceivedAt" "+notes" "+pubSub" "+users" "-firstRetrievedAt" "-followers" "-following" "-latestRequestReceivedAt" "-notes" "-pubSub" "-users"] }
def visibility-completer [] { ["private" "public"] }
def notify-completer [] { ["none" "normal"] }
def sort-completer-5 [] { ["+attachedLocalUsers" "+attachedRemoteUsers" "+attachedUsers" "+mentionedLocalUsers" "+mentionedRemoteUsers" "+mentionedUsers" "-attachedLocalUsers" "-attachedRemoteUsers" "-attachedUsers" "-mentionedLocalUsers" "-mentionedRemoteUsers" "-mentionedUsers"] }
def sort-completer-6 [] { ["+createdAt" "+follower" "+updatedAt" "-createdAt" "-follower" "-updatedAt"] }
def state-completer-2 [] { ["alive" "all"] }
def sort-completer-7 [] { ["+createdAt" "+lastUsedAt" "-createdAt" "-lastUsedAt"] }
def sort-completer-8 [] { ["asc" "desc"] }
def name-completer [] { ["brainDiver" "bubbleGameDoubleExplodingHead" "bubbleGameExplodingHead" "clickedClickHere" "client30min" "client60min" "collectAchievements30" "cookieClicked" "dimensionConfigured" "driveFolderCircularReference" "followers1" "followers10" "followers100" "followers1000" "followers300" "followers50" "followers500" "following1" "following10" "following100" "following300" "following50" "foundTreasure" "htl20npm" "iLoveMisskey" "justPlainLucky" "loggedInOnBirthday" "loggedInOnNewYearsDay" "login100" "login1000" "login15" "login200" "login3" "login30" "login300" "login400" "login500" "login60" "login600" "login7" "login700" "login800" "login900" "markedAsCat" "myNoteFavorited1" "noteClipped1" "noteDeletedWithin1min" "noteFavorited1" "notes1" "notes10" "notes100" "notes1000" "notes10000" "notes100000" "notes20000" "notes30000" "notes40000" "notes500" "notes5000" "notes50000" "notes60000" "notes70000" "notes80000" "notes90000" "open3windows" "outputHelloWorldOnScratchpad" "passedSinceAccountCreated1" "passedSinceAccountCreated2" "passedSinceAccountCreated3" "postedAt0min0sec" "postedAtLateNight" "postingLanguageConfigured" "profileFilled" "reactWithoutRead" "selfQuote" "sensitiveContentConsentResponded" "setNameToSyuilo" "smashTestNotificationButton" "tutorialCompleted" "viewAchievements3min" "viewInstanceChart" "viewingLanguagesConfigured"] }
def type-completer-6 [] { ["antenna" "home" "list" "user"] }
def lang-completer [] { ["" "ach" "ady" "af" "af-NA" "af-ZA" "ak" "ar" "ar-AR" "ar-MA" "ar-SA" "ay-BO" "az" "az-AZ" "be-BY" "bg" "bg-BG" "bn" "bn-BD" "bn-IN" "br" "bs-BA" "ca" "ca-ES" "cak" "ck-US" "cs" "cs-CZ" "cy" "cy-GB" "da" "da-DK" "de" "de-AT" "de-CH" "de-DE" "dsb" "el" "el-GR" "en" "en-AU" "en-CA" "en-GB" "en-IE" "en-IN" "en-PI" "en-SG" "en-UD" "en-US" "en-ZA" "en@pirate" "eo" "eo-EO" "es" "es-419" "es-AR" "es-CL" "es-CO" "es-EC" "es-ES" "es-LA" "es-MX" "es-NI" "es-US" "es-VE" "et" "et-EE" "eu" "eu-ES" "fa" "fa-IR" "fb-LT" "ff" "fi" "fi-FI" "fil" "fo" "fo-FO" "fr" "fr-BE" "fr-CA" "fr-CH" "fr-FR" "fy-NL" "ga" "ga-IE" "gd" "gl" "gl-ES" "gn-PY" "gu-IN" "gv" "gx-GR" "he" "he-IL" "hi" "hi-IN" "hr" "hr-HR" "hsb" "ht" "hu" "hu-HU" "hy" "hy-AM" "id" "id-ID" "is" "is-IS" "it" "it-IT" "ja" "ja-JP" "jv-ID" "ka-GE" "kab" "kk-KZ" "kl" "km" "km-KH" "kn" "kn-IN" "ko" "ko-KR" "ku-TR" "kw" "la" "la-VA" "lb" "li-NL" "lt" "lt-LT" "lv" "lv-LV" "mai" "mg-MG" "mk" "mk-MK" "ml" "ml-IN" "mn-MN" "mr" "mr-IN" "ms" "ms-MY" "mt" "mt-MT" "my" "nb" "nb-NO" "ne" "ne-NP" "nl" "nl-BE" "nl-NL" "nn-NO" "no" "oc" "or-IN" "pa" "pa-IN" "pl" "pl-PL" "ps-AF" "pt" "pt-BR" "pt-PT" "qu-PE" "rm-CH" "ro" "ro-RO" "ru" "ru-RU" "sa-IN" "se-NO" "sh" "si-LK" "sk" "sk-SK" "sl" "sl-SI" "so-SO" "sq" "sq-AL" "sr" "sr-RS" "su" "sv" "sv-SE" "sw" "sw-KE" "ta" "ta-IN" "te" "te-IN" "tg" "tg-TJ" "th" "th-TH" "tlh" "tr" "tr-TR" "tt-RU" "uk" "uk-UA" "ur" "ur-PK" "uz" "uz-UZ" "vi" "vi-VN" "xh-ZA" "yi" "yi-DE" "zh" "zh-CN" "zh-HK" "zh-Hans" "zh-Hant" "zh-SG" "zh-TW" "zu-ZA"] }
def postingLang-completer [] { ["" "ja" "ja-JP" "ko" "ko-KR" "other"] }
def followingVisibility-completer [] { ["followers" "private" "public"] }
def followersVisibility-completer [] { ["followers" "private" "public"] }
def chatScope-completer [] { ["everyone" "followers" "following" "mutual" "none"] }
def type-completer-7 [] { ["follow" "followed" "mention" "note" "reaction" "renote" "reply" "reportAutoResolved" "reportCreated" "reportResolved" "unfollow"] }
def visibility-completer-1 [] { ["followers" "home" "public" "specified"] }
def reactionAcceptance-completer [] { ["" "likeOnly" "likeOnlyForRemote" "nonSensitiveOnly" "nonSensitiveOnlyForLocalLikeOnlyForRemote"] }
def lang-completer-1 [] { ["" "ja" "ja-JP" "ko" "ko-KR" "other"] }
def font-completer [] { ["sans-serif" "serif"] }
def sort-completer-9 [] { ["+createdAt" "+follower" "+pv" "+updatedAt" "-createdAt" "-follower" "-pv" "-updatedAt"] }
def category-completer [] { ["criticalBreach" "explicit" "nsfw" "other" "otherBreach" "personalInfoLeak" "phishing" "selfHarm" "spam" "violationRights" "violationRightsOther"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "admin-abuse-report-resolver-create create" } } | get name | first)
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

# admin/abuse-report-resolver/create
#
# POST /admin/abuse-report-resolver/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/abuse-report-resolver/create.ts — Source code
# operationId: post___admin___abuse-report-resolver___create
export def "admin-abuse-report-resolver-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --targetUserPattern: string # nullable
  --reporterPattern: string # nullable
  --reportContentPattern: string # nullable
  expiresAt: string@expiresAt-completer
  --forward: oneof<nothing, bool>
]: any -> record<name: string, targetUserPattern: string, reporterPattern: string, reportContentPattern: string, expiresAt: string, forward: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/abuse-report-resolver/create")
  let body = {name: $name, targetUserPattern: $targetUserPattern, reporterPattern: $reporterPattern, reportContentPattern: $reportContentPattern, expiresAt: $expiresAt, forward: $forward} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/abuse-report-resolver/delete
#
# POST /admin/abuse-report-resolver/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/abuse-report-resolver/delete.ts — Source code
# operationId: post___admin___abuse-report-resolver___delete
export def "admin-abuse-report-resolver-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  resolverId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/abuse-report-resolver/delete")
  let body = {resolverId: $resolverId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/abuse-report-resolver/list
#
# POST /admin/abuse-report-resolver/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/abuse-report-resolver/list.ts — Source code
# operationId: post___admin___abuse-report-resolver___list
export def "admin-abuse-report-resolver-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<name: string, targetUserPattern: string, reporterPattern: string, reportContentPattern: string, expiresAt: string, forward: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/abuse-report-resolver/list")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/abuse-report-resolver/update
#
# POST /admin/abuse-report-resolver/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/abuse-report-resolver/update.ts — Source code
# operationId: post___admin___abuse-report-resolver___update
export def "admin-abuse-report-resolver-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  resolverId: string # format: misskey:id
  --name: string
  --targetUserPattern: string # nullable
  --reporterPattern: string # nullable
  --reportContentPattern: string # nullable
  --expiresAt: string@expiresAt-completer
  --forward: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/abuse-report-resolver/update")
  let body = {resolverId: $resolverId, name: $name, targetUserPattern: $targetUserPattern, reporterPattern: $reporterPattern, reportContentPattern: $reportContentPattern, expiresAt: $expiresAt, forward: $forward} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/abuse-report/notification-recipient/create
#
# POST /admin/abuse-report/notification-recipient/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/abuse-report/notification-recipient/create.ts — Source code
# operationId: post___admin___abuse-report___notification-recipient___create
export def "admin-abuse-report-notification-recipient-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isActive: oneof<nothing, bool>
  name: string
  method: string@method-completer
  --userId: string # format: misskey:id
  --systemWebhookId: string # format: misskey:id
]: any -> record<id: string, isActive: bool, updatedAt: string, name: string, method: string, userId: string, user: record, systemWebhookId: string, systemWebhook: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/abuse-report/notification-recipient/create")
  let body = {isActive: $isActive, name: $name, method: $method, userId: $userId, systemWebhookId: $systemWebhookId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/abuse-report/notification-recipient/delete
#
# POST /admin/abuse-report/notification-recipient/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/abuse-report/notification-recipient/delete.ts — Source code
# operationId: post___admin___abuse-report___notification-recipient___delete
export def "admin-abuse-report-notification-recipient-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/abuse-report/notification-recipient/delete")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/abuse-report/notification-recipient/list
#
# POST /admin/abuse-report/notification-recipient/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/abuse-report/notification-recipient/list.ts — Source code
# operationId: post___admin___abuse-report___notification-recipient___list
export def "admin-abuse-report-notification-recipient-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --method: list
]: any -> table<id: string, isActive: bool, updatedAt: string, name: string, method: string, userId: string, user: record, systemWebhookId: string, systemWebhook: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/abuse-report/notification-recipient/list")
  let body = {method: $method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/abuse-report/notification-recipient/show
#
# POST /admin/abuse-report/notification-recipient/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/abuse-report/notification-recipient/show.ts — Source code
# operationId: post___admin___abuse-report___notification-recipient___show
export def "admin-abuse-report-notification-recipient-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: misskey:id
]: any -> record<id: string, isActive: bool, updatedAt: string, name: string, method: string, userId: string, user: record, systemWebhookId: string, systemWebhook: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/abuse-report/notification-recipient/show")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/abuse-report/notification-recipient/update
#
# POST /admin/abuse-report/notification-recipient/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/abuse-report/notification-recipient/update.ts — Source code
# operationId: post___admin___abuse-report___notification-recipient___update
export def "admin-abuse-report-notification-recipient-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: misskey:id
  --isActive: oneof<nothing, bool>
  name: string
  method: string@method-completer
  --userId: string # format: misskey:id
  --systemWebhookId: string # format: misskey:id
]: any -> record<id: string, isActive: bool, updatedAt: string, name: string, method: string, userId: string, user: record, systemWebhookId: string, systemWebhook: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/abuse-report/notification-recipient/update")
  let body = {id: $id, isActive: $isActive, name: $name, method: $method, userId: $userId, systemWebhookId: $systemWebhookId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/abuse-user-reports
#
# POST /admin/abuse-user-reports
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/abuse-user-reports.ts — Source code
# operationId: post___admin___abuse-user-reports
export def "admin-abuse-user-reports abuse-user-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --state: string # nullable
  --reporterOrigin: string@reporterOrigin-completer # default: combined
  --targetUserOrigin: string@targetUserOrigin-completer # default: combined
  --forwarded: oneof<nothing, bool> # default: false
  --category: string # nullable
]: any -> table<id: string, createdAt: string, comment: string, resolved: bool, forwarded: bool, resolvedAs: string, reporterId: string, targetUserId: string, assigneeId: string, reporter: any, targetUser: any, assignee: record, category: string, moderationNote: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/abuse-user-reports")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId, state: $state, reporterOrigin: $reporterOrigin, targetUserOrigin: $targetUserOrigin, forwarded: $forwarded, category: $category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/accounts/create
#
# POST /admin/accounts/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/accounts/create.ts — Source code
# operationId: post___admin___accounts___create
export def "admin-accounts-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  username: string
  password: string
  --setupPassword: string # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/accounts/create")
  let body = {username: $username, password: $password, setupPassword: $setupPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/accounts/delete
#
# POST /admin/accounts/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/accounts/delete.ts — Source code
# operationId: post___admin___accounts___delete
export def "admin-accounts-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
  --soft: oneof<nothing, bool> # Since deletion by an administrator is a moderation action, the default is to soft delete. (default: true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/accounts/delete")
  let body = {userId: $userId, soft: $soft} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/accounts/find-by-email
#
# POST /admin/accounts/find-by-email
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/accounts/find-by-email.ts — Source code
# operationId: post___admin___accounts___find-by-email
export def "admin-accounts-find-by-email find-by-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/accounts/find-by-email")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/accounts/pending/list
#
# POST /admin/accounts/pending/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/accounts/pending/list.ts — Source code
# operationId: post___admin___accounts___pending___list
export def "admin-accounts-pending-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int # default: 0
  --body-sort: string@sort-completer
  --username: string # nullable
  --email: string # nullable
  --code: string # nullable
]: any -> table<id: string, createdAt: string, code: string, username: string, email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/accounts/pending/list")
  let body = {limit: $limit, offset: $offset, sort: $body_sort, username: $username, email: $email, code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/accounts/pending/revoke
#
# POST /admin/accounts/pending/revoke
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/accounts/pending/revoke.ts — Source code
# operationId: post___admin___accounts___pending___revoke
export def "admin-accounts-pending-revoke revoke" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # format: misskey:id
  --code: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/accounts/pending/revoke")
  let body = {id: $id, code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/ad/create
#
# POST /admin/ad/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/ad/create.ts — Source code
# operationId: post___admin___ad___create
export def "admin-ad-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string
  memo: string
  place: string
  priority: string
  ratio: int
  expiresAt: int
  startsAt: int
  imageUrl: string
  dayOfWeek: int
  --isSensitive: oneof<nothing, bool> # default: false
]: any -> record<id: string, expiresAt: string, startsAt: string, place: string, priority: string, ratio: float, url: string, imageUrl: string, imageBlurhash: string, memo: string, dayOfWeek: int, isSensitive: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/ad/create")
  let body = {url: $body_url, memo: $memo, place: $place, priority: $priority, ratio: $ratio, expiresAt: $expiresAt, startsAt: $startsAt, imageUrl: $imageUrl, dayOfWeek: $dayOfWeek, isSensitive: $isSensitive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/ad/delete
#
# POST /admin/ad/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/ad/delete.ts — Source code
# operationId: post___admin___ad___delete
export def "admin-ad-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/ad/delete")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/ad/list
#
# POST /admin/ad/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/ad/list.ts — Source code
# operationId: post___admin___ad___list
export def "admin-ad-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --publishing: oneof<nothing, bool> # nullable
]: any -> table<id: string, expiresAt: string, startsAt: string, place: string, priority: string, ratio: float, url: string, imageUrl: string, imageBlurhash: string, memo: string, dayOfWeek: int, isSensitive: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/ad/list")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId, publishing: $publishing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/ad/update
#
# POST /admin/ad/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/ad/update.ts — Source code
# operationId: post___admin___ad___update
export def "admin-ad-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: misskey:id
  --memo: string
  --body-url: string
  --imageUrl: string
  --place: string
  --priority: string
  --ratio: int
  --expiresAt: int
  --startsAt: int
  --dayOfWeek: int
  --isSensitive: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/ad/update")
  let body = {id: $id, memo: $memo, url: $body_url, imageUrl: $imageUrl, place: $place, priority: $priority, ratio: $ratio, expiresAt: $expiresAt, startsAt: $startsAt, dayOfWeek: $dayOfWeek, isSensitive: $isSensitive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/announcements/create
#
# POST /admin/announcements/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/announcements/create.ts — Source code
# operationId: post___admin___announcements___create
export def "admin-announcements-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string
  text: string
  --imageUrl: string # nullable
  --icon: string@icon-completer # default: info
  --display: string@display-completer # default: normal
  --forExistingUsers: oneof<nothing, bool> # default: false
  --needConfirmationToRead: oneof<nothing, bool> # default: false
  --needEnrollmentTutorialToRead: oneof<nothing, bool> # default: false
  --closeDuration: float # default: 0
  --displayOrder: float # default: 0
  --silence: oneof<nothing, bool> # default: false
  --userId: string # nullable, format: misskey:id
]: any -> record<id: string, createdAt: string, updatedAt: string, title: string, text: string, imageUrl: string, icon: string, display: string, forYou: bool, needConfirmationToRead: bool, needEnrollmentTutorialToRead: bool, closeDuration: float, displayOrder: float, silence: bool, isRead: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/announcements/create")
  let body = {title: $title, text: $text, imageUrl: $imageUrl, icon: $icon, display: $display, forExistingUsers: $forExistingUsers, needConfirmationToRead: $needConfirmationToRead, needEnrollmentTutorialToRead: $needEnrollmentTutorialToRead, closeDuration: $closeDuration, displayOrder: $displayOrder, silence: $silence, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/announcements/delete
#
# POST /admin/announcements/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/announcements/delete.ts — Source code
# operationId: post___admin___announcements___delete
export def "admin-announcements-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/announcements/delete")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/announcements/list
#
# POST /admin/announcements/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/announcements/list.ts — Source code
# operationId: post___admin___announcements___list
export def "admin-announcements-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int # default: 0
  --userId: string # nullable, format: misskey:id
  --status: string@status-completer # nullable
]: any -> table<id: string, createdAt: string, updatedAt: string, text: string, isActive: bool, title: string, imageUrl: string, icon: string, display: string, forExistingUsers: bool, needConfirmationToRead: bool, needEnrollmentTutorialToRead: bool, closeDuration: float, displayOrder: float, silence: bool, userId: string, user: record, reads: float, lastReadAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/announcements/list")
  let body = {limit: $limit, offset: $offset, userId: $userId, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/announcements/update
#
# POST /admin/announcements/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/announcements/update.ts — Source code
# operationId: post___admin___announcements___update
export def "admin-announcements-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: misskey:id
  --title: string
  --text: string
  --imageUrl: string # nullable
  --icon: string@icon-completer
  --display: string@display-completer
  --forExistingUsers: oneof<nothing, bool>
  --needConfirmationToRead: oneof<nothing, bool>
  --needEnrollmentTutorialToRead: oneof<nothing, bool>
  --closeDuration: float # default: 0
  --displayOrder: float # default: 0
  --silence: oneof<nothing, bool>
  --isActive: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/announcements/update")
  let body = {id: $id, title: $title, text: $text, imageUrl: $imageUrl, icon: $icon, display: $display, forExistingUsers: $forExistingUsers, needConfirmationToRead: $needConfirmationToRead, needEnrollmentTutorialToRead: $needEnrollmentTutorialToRead, closeDuration: $closeDuration, displayOrder: $displayOrder, silence: $silence, isActive: $isActive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/avatar-decorations/create
#
# POST /admin/avatar-decorations/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/avatar-decorations/create.ts — Source code
# operationId: post___admin___avatar-decorations___create
export def "admin-avatar-decorations-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  description: string
  --body-url: string
  --roleIdsThatCanBeUsedThisDecoration: list
]: any -> record<id: string, createdAt: string, updatedAt: string, name: string, description: string, url: string, roleIdsThatCanBeUsedThisDecoration: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/avatar-decorations/create")
  let body = {name: $name, description: $description, url: $body_url, roleIdsThatCanBeUsedThisDecoration: $roleIdsThatCanBeUsedThisDecoration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/avatar-decorations/delete
#
# POST /admin/avatar-decorations/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/avatar-decorations/delete.ts — Source code
# operationId: post___admin___avatar-decorations___delete
export def "admin-avatar-decorations-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/avatar-decorations/delete")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/avatar-decorations/list
#
# POST /admin/avatar-decorations/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/avatar-decorations/list.ts — Source code
# operationId: post___admin___avatar-decorations___list
export def "admin-avatar-decorations-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --userId: string # nullable, format: misskey:id
]: any -> table<id: string, createdAt: string, updatedAt: string, name: string, description: string, url: string, roleIdsThatCanBeUsedThisDecoration: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/avatar-decorations/list")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/avatar-decorations/update
#
# POST /admin/avatar-decorations/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/avatar-decorations/update.ts — Source code
# operationId: post___admin___avatar-decorations___update
export def "admin-avatar-decorations-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: misskey:id
  --name: string
  --description: string
  --body-url: string
  --roleIdsThatCanBeUsedThisDecoration: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/avatar-decorations/update")
  let body = {id: $id, name: $name, description: $description, url: $body_url, roleIdsThatCanBeUsedThisDecoration: $roleIdsThatCanBeUsedThisDecoration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/captcha/current
#
# POST /admin/captcha/current
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/captcha/current.ts — Source code
# operationId: post___admin___captcha___current
export def "admin-captcha-current current" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<provider: string, hcaptcha: record<siteKey: string, secretKey: string>, mcaptcha: record<siteKey: string, secretKey: string, instanceUrl: string>, recaptcha: record<siteKey: string, secretKey: string>, turnstile: record<siteKey: string, secretKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/captcha/current")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# admin/captcha/save
#
# POST /admin/captcha/save
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/captcha/save.ts — Source code
# operationId: post___admin___captcha___save
export def "admin-captcha-save save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  provider: string@provider-completer
  --captchaResult: string # nullable
  --sitekey: string # nullable
  --secret: string # nullable
  --instanceUrl: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/captcha/save")
  let body = {provider: $provider, captchaResult: $captchaResult, sitekey: $sitekey, secret: $secret, instanceUrl: $instanceUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/drive/clean-remote-files
#
# POST /admin/drive/clean-remote-files
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/drive/clean-remote-files.ts — Source code
# operationId: post___admin___drive___clean-remote-files
export def "admin-drive-clean-remote-files clean-remote-files" [
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
  let full_url = (build-url $base "/admin/drive/clean-remote-files")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# admin/drive/cleanup
#
# POST /admin/drive/cleanup
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/drive/cleanup.ts — Source code
# operationId: post___admin___drive___cleanup
export def "admin-drive-cleanup cleanup" [
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
  let full_url = (build-url $base "/admin/drive/cleanup")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# admin/drive/delete-all-files-of-a-user
#
# POST /admin/drive/delete-all-files-of-a-user
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/drive/delete-all-files-of-a-user.ts — Source code
# operationId: post___admin___drive___delete-all-files-of-a-user
export def "admin-drive-delete-all-files-of-a-user delete-all-files-of-a-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/drive/delete-all-files-of-a-user")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/drive/files
#
# POST /admin/drive/files
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/drive/files.ts — Source code
# operationId: post___admin___drive___files
export def "admin-drive-files files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --userId: string # nullable, format: misskey:id
  --type: string # nullable
  --origin: string@origin-completer # default: local
  --hostname: string # The local host is represented with `null`. (nullable)
]: any -> table<id: string, createdAt: string, name: string, type: string, md5: string, size: float, isSensitive: bool, isSensitiveByModerator: bool, blurhash: string, properties: record<width: float, height: float, orientation: float, avgColor: string>, url: string, thumbnailUrl: string, comment: string, folderId: string, folder: record, userId: string, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/drive/files")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId, userId: $userId, type: $type, origin: $origin, hostname: $hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/drive/show-file
#
# POST /admin/drive/show-file
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/drive/show-file.ts — Source code
# operationId: post___admin___drive___show-file
export def "admin-drive-show-file show-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fileId: string # format: misskey:id
  --body-url: string
]: any -> record<id: string, createdAt: string, userId: string, userHost: string, md5: string, name: string, type: string, size: float, comment: string, blurhash: string, properties: record<width: float, height: float, orientation: float, avgColor: string>, storedInternal: bool, url: string, thumbnailUrl: string, webpublicUrl: string, accessKey: string, thumbnailAccessKey: string, webpublicAccessKey: string, uri: string, src: string, folderId: string, isSensitive: bool, isLink: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/drive/show-file")
  let body = {fileId: $fileId, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/emoji/add
#
# POST /admin/emoji/add
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/emoji/add.ts — Source code
# operationId: post___admin___emoji___add
export def "admin-emoji-add add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  fileId: string # format: misskey:id
  --category: string # Use `null` to reset the category. (nullable)
  --aliases: list
  --license: string # nullable
  --isSensitive: oneof<nothing, bool>
  --localOnly: oneof<nothing, bool>
  --requestedBy: string # nullable
  --memo: string # nullable
  --roleIdsThatCanBeUsedThisEmojiAsReaction: list
  --roleIdsThatCanNotBeUsedThisEmojiAsReaction: list
]: any -> record<id: string, createdAt: string, updatedAt: string, aliases: list<string>, name: string, category: string, host: string, url: string, license: string, isSensitive: bool, localOnly: bool, requestedBy: string, memo: string, roleIdsThatCanBeUsedThisEmojiAsReaction: list<string>, roleIdsThatCanNotBeUsedThisEmojiAsReaction: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/emoji/add")
  let body = {name: $name, fileId: $fileId, category: $category, aliases: $aliases, license: $license, isSensitive: $isSensitive, localOnly: $localOnly, requestedBy: $requestedBy, memo: $memo, roleIdsThatCanBeUsedThisEmojiAsReaction: $roleIdsThatCanBeUsedThisEmojiAsReaction, roleIdsThatCanNotBeUsedThisEmojiAsReaction: $roleIdsThatCanNotBeUsedThisEmojiAsReaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/emoji/add-aliases-bulk
#
# POST /admin/emoji/add-aliases-bulk
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/emoji/add-aliases-bulk.ts — Source code
# operationId: post___admin___emoji___add-aliases-bulk
export def "admin-emoji-add-aliases-bulk add-aliases-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list
  aliases: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/emoji/add-aliases-bulk")
  let body = {ids: $ids, aliases: $aliases} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/emoji/copy
#
# POST /admin/emoji/copy
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/emoji/copy.ts — Source code
# operationId: post___admin___emoji___copy
export def "admin-emoji-copy copy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  emojiId: string # format: misskey:id
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/emoji/copy")
  let body = {emojiId: $emojiId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/emoji/delete
#
# POST /admin/emoji/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/emoji/delete.ts — Source code
# operationId: post___admin___emoji___delete
export def "admin-emoji-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/emoji/delete")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/emoji/delete-bulk
#
# POST /admin/emoji/delete-bulk
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/emoji/delete-bulk.ts — Source code
# operationId: post___admin___emoji___delete-bulk
export def "admin-emoji-delete-bulk delete-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/emoji/delete-bulk")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/emoji/import-zip
#
# POST /admin/emoji/import-zip
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/emoji/import-zip.ts — Source code
# operationId: post___admin___emoji___import-zip
export def "admin-emoji-import-zip import-zip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  fileId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/emoji/import-zip")
  let body = {fileId: $fileId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/emoji/list
#
# POST /admin/emoji/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/emoji/list.ts — Source code
# operationId: post___admin___emoji___list
export def "admin-emoji-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-query: string # nullable
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, aliases: list<string>, name: string, category: string, host: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/emoji/list")
  let body = {query: $body_query, limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/emoji/list-remote
#
# POST /admin/emoji/list-remote
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/emoji/list-remote.ts — Source code
# operationId: post___admin___emoji___list-remote
export def "admin-emoji-list-remote list-remote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-query: string # nullable
  --host: string # Use `null` to represent the local host. (nullable)
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, aliases: list<string>, name: string, category: string, host: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/emoji/list-remote")
  let body = {query: $body_query, host: $host, limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/emoji/remove-aliases-bulk
#
# POST /admin/emoji/remove-aliases-bulk
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/emoji/remove-aliases-bulk.ts — Source code
# operationId: post___admin___emoji___remove-aliases-bulk
export def "admin-emoji-remove-aliases-bulk remove-aliases-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list
  aliases: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/emoji/remove-aliases-bulk")
  let body = {ids: $ids, aliases: $aliases} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/emoji/set-aliases-bulk
#
# POST /admin/emoji/set-aliases-bulk
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/emoji/set-aliases-bulk.ts — Source code
# operationId: post___admin___emoji___set-aliases-bulk
export def "admin-emoji-set-aliases-bulk set-aliases-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list
  aliases: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/emoji/set-aliases-bulk")
  let body = {ids: $ids, aliases: $aliases} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/emoji/set-category-bulk
#
# POST /admin/emoji/set-category-bulk
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/emoji/set-category-bulk.ts — Source code
# operationId: post___admin___emoji___set-category-bulk
export def "admin-emoji-set-category-bulk set-category-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list
  --category: string # Use `null` to reset the category. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/emoji/set-category-bulk")
  let body = {ids: $ids, category: $category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/emoji/set-license-bulk
#
# POST /admin/emoji/set-license-bulk
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/emoji/set-license-bulk.ts — Source code
# operationId: post___admin___emoji___set-license-bulk
export def "admin-emoji-set-license-bulk set-license-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list
  --license: string # Use `null` to reset the license. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/emoji/set-license-bulk")
  let body = {ids: $ids, license: $license} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/emoji/update
#
# POST /admin/emoji/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/emoji/update.ts — Source code
# operationId: post___admin___emoji___update
export def "admin-emoji-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # format: misskey:id
  --name: string
  --fileId: string # format: misskey:id
  --category: string # Use `null` to reset the category. (nullable)
  --aliases: list
  --license: string # nullable
  --isSensitive: oneof<nothing, bool>
  --localOnly: oneof<nothing, bool>
  --requestedBy: string # nullable
  --memo: string # nullable
  --roleIdsThatCanBeUsedThisEmojiAsReaction: list
  --roleIdsThatCanNotBeUsedThisEmojiAsReaction: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/emoji/update")
  let body = {id: $id, name: $name, fileId: $fileId, category: $category, aliases: $aliases, license: $license, isSensitive: $isSensitive, localOnly: $localOnly, requestedBy: $requestedBy, memo: $memo, roleIdsThatCanBeUsedThisEmojiAsReaction: $roleIdsThatCanBeUsedThisEmojiAsReaction, roleIdsThatCanNotBeUsedThisEmojiAsReaction: $roleIdsThatCanNotBeUsedThisEmojiAsReaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/federation/delete-all-files
#
# POST /admin/federation/delete-all-files
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/federation/delete-all-files.ts — Source code
# operationId: post___admin___federation___delete-all-files
export def "admin-federation-delete-all-files delete-all-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  host: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/federation/delete-all-files")
  let body = {host: $host} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/federation/refresh-remote-instance-metadata
#
# POST /admin/federation/refresh-remote-instance-metadata
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/federation/refresh-remote-instance-metadata.ts — Source code
# operationId: post___admin___federation___refresh-remote-instance-metadata
export def "admin-federation-refresh-remote-instance-metadata refresh-remote-instance-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  host: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/federation/refresh-remote-instance-metadata")
  let body = {host: $host} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/federation/remove-all-following
#
# POST /admin/federation/remove-all-following
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/federation/remove-all-following.ts — Source code
# operationId: post___admin___federation___remove-all-following
export def "admin-federation-remove-all-following remove-all-following" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  host: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/federation/remove-all-following")
  let body = {host: $host} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/federation/update-instance
#
# POST /admin/federation/update-instance
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/federation/update-instance.ts — Source code
# operationId: post___admin___federation___update-instance
export def "admin-federation-update-instance update-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  host: string
  --isSuspended: oneof<nothing, bool>
  --moderationNote: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/federation/update-instance")
  let body = {host: $host, isSuspended: $isSuspended, moderationNote: $moderationNote} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/forward-abuse-user-report
#
# POST /admin/forward-abuse-user-report
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/forward-abuse-user-report.ts — Source code
# operationId: post___admin___forward-abuse-user-report
export def "admin-forward-abuse-user-report forward-abuse-user-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  reportId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/forward-abuse-user-report")
  let body = {reportId: $reportId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/get-index-stats
#
# POST /admin/get-index-stats
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/get-index-stats.ts — Source code
# operationId: post___admin___get-index-stats
export def "admin-get-index-stats get-index-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<tablename: string, indexname: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/get-index-stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# admin/get-table-stats
#
# POST /admin/get-table-stats
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/get-table-stats.ts — Source code
# operationId: post___admin___get-table-stats
export def "admin-get-table-stats get-table-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/get-table-stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# admin/get-user-ips
#
# POST /admin/get-user-ips
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/get-user-ips.ts — Source code
# operationId: post___admin___get-user-ips
export def "admin-get-user-ips get-user-ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> table<ip: string, createdAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/get-user-ips")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/indie-auth/create
#
# POST /admin/indie-auth/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/indie-auth/create.ts — Source code
# operationId: post___admin___indie-auth___create
export def "admin-indie-auth-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string
  --name: string # nullable
  --redirectUris: list
]: any -> record<id: string, createdAt: string, name: string, redirectUris: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/indie-auth/create")
  let body = {id: $id, name: $name, redirectUris: $redirectUris} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/indie-auth/delete
#
# POST /admin/indie-auth/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/indie-auth/delete.ts — Source code
# operationId: post___admin___indie-auth___delete
export def "admin-indie-auth-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/indie-auth/delete")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/indie-auth/list
#
# POST /admin/indie-auth/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/indie-auth/list.ts — Source code
# operationId: post___admin___indie-auth___list
export def "admin-indie-auth-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int # default: 0
]: any -> table<id: string, createdAt: string, name: string, redirectUris: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/indie-auth/list")
  let body = {limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/indie-auth/update
#
# POST /admin/indie-auth/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/indie-auth/update.ts — Source code
# operationId: post___admin___indie-auth___update
export def "admin-indie-auth-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string
  --name: string # nullable
  --redirectUris: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/indie-auth/update")
  let body = {id: $id, name: $name, redirectUris: $redirectUris} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/invite/create
#
# POST /admin/invite/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/invite/create.ts — Source code
# operationId: post___admin___invite___create
export def "admin-invite-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # default: 1
  --expiresAt: string # nullable
]: any -> table<id: string, code: string, expiresAt: string, createdAt: string, createdBy: record, usedBy: record, usedAt: string, used: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/invite/create")
  let body = {count: $count, expiresAt: $expiresAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/invite/list
#
# POST /admin/invite/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/invite/list.ts — Source code
# operationId: post___admin___invite___list
export def "admin-invite-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 30
  --offset: int # default: 0
  --type: string@type-completer # default: all
  --body-sort: string@sort-completer-1
]: any -> table<id: string, code: string, expiresAt: string, createdAt: string, createdBy: record, usedBy: record, usedAt: string, used: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/invite/list")
  let body = {limit: $limit, offset: $offset, type: $type, sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/meta
#
# POST /admin/meta
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/meta.ts — Source code
# operationId: post___admin___meta
export def "admin-meta meta" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cacheRemoteFiles: bool, cacheRemoteSensitiveFiles: bool, emailRequiredForSignup: bool, enableHcaptcha: bool, hcaptchaSiteKey: string, enableMcaptcha: bool, mcaptchaSiteKey: string, mcaptchaInstanceUrl: string, enableRecaptcha: bool, recaptchaSiteKey: string, enableTurnstile: bool, turnstileSiteKey: string, googleAnalyticsId: string, swPublickey: string, mascotImageUrl: string, bannerUrl: string, serverErrorImageUrl: string, infoImageUrl: string, notFoundImageUrl: string, iconUrl: string, app192IconUrl: string, app512IconUrl: string, enableEmail: bool, enableServiceWorker: bool, translatorAvailable: bool, silencedHosts: list<string>, sensitiveMediaHosts: list<string>, pinnedUsers: list<string>, hiddenTags: list<string>, blockedHosts: list<string>, blockedRemoteCustomEmojis: list<string>, sensitiveWords: list<string>, prohibitedWords: list<string>, bannedEmailDomains: list<string>, preservedUsernames: list<string>, hcaptchaSecretKey: string, mcaptchaSecretKey: string, recaptchaSecretKey: string, turnstileSecretKey: string, sensitiveMediaDetection: string, sensitiveMediaDetectionSensitivity: string, setSensitiveFlagAutomatically: bool, enableSensitiveMediaDetectionForVideos: bool, proxyAccountId: string, email: string, smtpSecure: bool, smtpHost: string, smtpPort: float, smtpUser: string, smtpPass: string, swPrivateKey: string, useObjectStorage: bool, objectStorageBaseUrl: string, objectStorageBucket: string, objectStoragePrefix: string, objectStorageEndpoint: string, objectStorageRegion: string, objectStoragePort: float, objectStorageAccessKey: string, objectStorageSecretKey: string, objectStorageUseSSL: bool, objectStorageUseProxy: bool, objectStorageSetPublicRead: bool, enableIpLogging: bool, enableActiveEmailValidation: bool, enableVerifymailApi: bool, verifymailAuthKey: string, enableTruemailApi: bool, truemailInstance: string, truemailAuthKey: string, enableChartsForRemoteUser: bool, enableChartsForFederatedInstances: bool, enableServerMachineStats: bool, enableIdenticonGeneration: bool, manifestJsonOverride: string, policies: record, enableFanoutTimeline: bool, enableFanoutTimelineDbFallback: bool, perLocalUserUserTimelineCacheMax: float, perRemoteUserUserTimelineCacheMax: float, perUserHomeTimelineCacheMax: float, perUserListTimelineCacheMax: float, notesPerOneAd: float, wellKnownWebsites: list<string>, urlPreviewDenyList: list<string>, featuredGameChannels: list<string>, backgroundImageUrl: string, deeplAuthKey: string, deeplIsPro: bool, defaultDarkTheme: string, defaultLightTheme: string, description: string, dimensions: float, disableRegistration: bool, impressumUrl: string, maintainerEmail: string, maintainerName: string, name: string, shortName: string, objectStorageS3ForcePathStyle: bool, privacyPolicyUrl: string, repositoryUrl: string, summalyProxy: string, themeColor: string, tosUrl: string, uri: string, version: string, urlPreviewEnabled: bool, urlPreviewTimeout: float, urlPreviewMaximumContentLength: float, urlPreviewRequireContentLength: bool, urlPreviewUserAgent: string, urlPreviewSummaryProxyUrl: string, federation: string, federationHosts: list<string>, prohibitedWordsForNameOfUser: list<string>, inquiryUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/meta")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# admin/promo/create
#
# POST /admin/promo/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/promo/create.ts — Source code
# operationId: post___admin___promo___create
export def "admin-promo-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
  expiresAt: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/promo/create")
  let body = {noteId: $noteId, expiresAt: $expiresAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/queue/clear
#
# POST /admin/queue/clear
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/queue/clear.ts — Source code
# operationId: post___admin___queue___clear
export def "admin-queue-clear clear" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-1
  state: string@state-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/queue/clear")
  let body = {type: $type, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/queue/deliver-delayed
#
# POST /admin/queue/deliver-delayed
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/queue/deliver-delayed.ts — Source code
# operationId: post___admin___queue___deliver-delayed
export def "admin-queue-deliver-delayed deliver-delayed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/queue/deliver-delayed")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# admin/queue/inbox-delayed
#
# POST /admin/queue/inbox-delayed
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/queue/inbox-delayed.ts — Source code
# operationId: post___admin___queue___inbox-delayed
export def "admin-queue-inbox-delayed inbox-delayed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/queue/inbox-delayed")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# admin/queue/promote
#
# POST /admin/queue/promote
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/queue/promote.ts — Source code
# operationId: post___admin___queue___promote
export def "admin-queue-promote promote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-2
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/queue/promote")
  let body = {type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/queue/stats
#
# POST /admin/queue/stats
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/queue/stats.ts — Source code
# operationId: post___admin___queue___stats
export def "admin-queue-stats stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deliver: record<waiting: float, active: float, completed: float, failed: float, delayed: float>, inbox: record<waiting: float, active: float, completed: float, failed: float, delayed: float>, db: record<waiting: float, active: float, completed: float, failed: float, delayed: float>, objectStorage: record<waiting: float, active: float, completed: float, failed: float, delayed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/queue/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# admin/regenerate-user-token
#
# POST /admin/regenerate-user-token
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/regenerate-user-token.ts — Source code
# operationId: post___admin___regenerate-user-token
export def "admin-regenerate-user-token regenerate-user-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/regenerate-user-token")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/relays/add
#
# POST /admin/relays/add
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/relays/add.ts — Source code
# operationId: post___admin___relays___add
export def "admin-relays-add add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  inbox: string
]: any -> record<id: string, inbox: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/relays/add")
  let body = {inbox: $inbox} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/relays/list
#
# POST /admin/relays/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/relays/list.ts — Source code
# operationId: post___admin___relays___list
export def "admin-relays-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, inbox: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/relays/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# admin/relays/remove
#
# POST /admin/relays/remove
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/relays/remove.ts — Source code
# operationId: post___admin___relays___remove
export def "admin-relays-remove remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  inbox: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/relays/remove")
  let body = {inbox: $inbox} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/reset-password
#
# POST /admin/reset-password
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/reset-password.ts — Source code
# operationId: post___admin___reset-password
export def "admin-reset-password reset-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> record<password: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/reset-password")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/resolve-abuse-user-report
#
# POST /admin/resolve-abuse-user-report
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/resolve-abuse-user-report.ts — Source code
# operationId: post___admin___resolve-abuse-user-report
export def "admin-resolve-abuse-user-report resolve-abuse-user-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  reportId: string # format: misskey:id
  --resolvedAs: string@resolvedAs-completer # nullable
  --forward: oneof<nothing, bool> # default: false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/resolve-abuse-user-report")
  let body = {reportId: $reportId, resolvedAs: $resolvedAs, forward: $forward} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/roles/assign
#
# POST /admin/roles/assign
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/roles/assign.ts — Source code
# operationId: post___admin___roles___assign
export def "admin-roles-assign assign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  roleId: string # format: misskey:id
  userId: string # format: misskey:id
  --memo: string
  --expiresAt: int # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/roles/assign")
  let body = {roleId: $roleId, userId: $userId, memo: $memo, expiresAt: $expiresAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/roles/create
#
# POST /admin/roles/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/roles/create.ts — Source code
# operationId: post___admin___roles___create
export def "admin-roles-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  description: string
  --color: string # nullable
  --iconUrl: string # nullable
  target: string@target-completer
  condFormula: record
  --isPublic: oneof<nothing, bool>
  --isModerator: oneof<nothing, bool>
  --isAdministrator: oneof<nothing, bool>
  --isExplorable: oneof<nothing, bool> # default: false
  --asBadge: oneof<nothing, bool>
  --badgeBehavior: string # nullable
  --preserveAssignmentOnMoveAccount: oneof<nothing, bool>
  --canEditMembersByModerator: oneof<nothing, bool>
  displayOrder: float
  policies: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/roles/create")
  let body = {name: $name, description: $description, color: $color, iconUrl: $iconUrl, target: $target, condFormula: $condFormula, isPublic: $isPublic, isModerator: $isModerator, isAdministrator: $isAdministrator, isExplorable: $isExplorable, asBadge: $asBadge, badgeBehavior: $badgeBehavior, preserveAssignmentOnMoveAccount: $preserveAssignmentOnMoveAccount, canEditMembersByModerator: $canEditMembersByModerator, displayOrder: $displayOrder, policies: $policies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/roles/delete
#
# POST /admin/roles/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/roles/delete.ts — Source code
# operationId: post___admin___roles___delete
export def "admin-roles-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  roleId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/roles/delete")
  let body = {roleId: $roleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/roles/list
#
# POST /admin/roles/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/roles/list.ts — Source code
# operationId: post___admin___roles___list
export def "admin-roles-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/roles/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# admin/roles/show
#
# POST /admin/roles/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/roles/show.ts — Source code
# operationId: post___admin___roles___show
export def "admin-roles-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  roleId: string # format: misskey:id
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/roles/show")
  let body = {roleId: $roleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/roles/unassign
#
# POST /admin/roles/unassign
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/roles/unassign.ts — Source code
# operationId: post___admin___roles___unassign
export def "admin-roles-unassign unassign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  roleId: string # format: misskey:id
  userId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/roles/unassign")
  let body = {roleId: $roleId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/roles/update
#
# POST /admin/roles/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/roles/update.ts — Source code
# operationId: post___admin___roles___update
export def "admin-roles-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  roleId: string # format: misskey:id
  --name: string
  --description: string
  --color: string # nullable
  --iconUrl: string # nullable
  --target: string@target-completer
  --condFormula: record
  --isPublic: oneof<nothing, bool>
  --isModerator: oneof<nothing, bool>
  --isAdministrator: oneof<nothing, bool>
  --isExplorable: oneof<nothing, bool>
  --asBadge: oneof<nothing, bool>
  --badgeBehavior: string # nullable
  --preserveAssignmentOnMoveAccount: oneof<nothing, bool>
  --canEditMembersByModerator: oneof<nothing, bool>
  --displayOrder: float
  --policies: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/roles/update")
  let body = {roleId: $roleId, name: $name, description: $description, color: $color, iconUrl: $iconUrl, target: $target, condFormula: $condFormula, isPublic: $isPublic, isModerator: $isModerator, isAdministrator: $isAdministrator, isExplorable: $isExplorable, asBadge: $asBadge, badgeBehavior: $badgeBehavior, preserveAssignmentOnMoveAccount: $preserveAssignmentOnMoveAccount, canEditMembersByModerator: $canEditMembersByModerator, displayOrder: $displayOrder, policies: $policies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/roles/update-default-policies
#
# POST /admin/roles/update-default-policies
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/roles/update-default-policies.ts — Source code
# operationId: post___admin___roles___update-default-policies
export def "admin-roles-update-default-policies update-default-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  policies: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/roles/update-default-policies")
  let body = {policies: $policies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/roles/update-inline-policies
#
# POST /admin/roles/update-inline-policies
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/roles/update-inline-policies.ts — Source code
# operationId: post___admin___roles___update-inline-policies
# --policies item shape: {id?: string, policy: "gtlAvailable"|"ltlAvailable"|"canPublicNote"|"canScheduleNote"|"scheduleNoteLimit"|"scheduleNoteMaxDays"|"canInitiateConversation"|"canCreateContent"|"canUpdateContent"|"canDeleteContent"|"canPurgeAccount"|"canUpdateAvatar"|"canUpdateBanner"|"mentionLimit"|"canInvite"|"inviteLimit"|"inviteLimitCycle"|"inviteExpirationTime"|"canManageCustomEmojis"|"canManageAvatarDecorations"|"canSearchNotes"|"canUseTranslator"|"canUseDriveFileInSoundSettings"|"canUseReaction"|"canHideAds"|"driveCapacityMb"|"maxFileSizeMb"|"alwaysMarkNsfw"|"canUpdateBioMedia"|"skipNsfwDetection"|"pinLimit"|"antennaLimit"|"antennaNotesLimit"|"wordMuteLimit"|"webhookLimit"|"clipLimit"|"noteEachClipsLimit"|"userListLimit"|"userEachUserListsLimit"|"rateLimitFactor"|"avatarDecorationLimit"|"canImportAntennas"|"canImportBlocking"|"canImportFollowing"|"canImportMuting"|"canImportUserLists"|"mutualLinkSectionLimit"|"mutualLinkLimit"|"chatAvailability", operation?: "set"|"increment", value?: any, memo?: string}
export def "admin-roles-update-inline-policies update-inline-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
  policies: list # item shape: {id?: string, policy: "gtlAvailable"|"ltlAvailable"|"canPublicNote"|"canScheduleNote"|"scheduleNoteLimit"|"scheduleNoteMaxDays"|"canInitiateConversation"|"canCreateContent"|"canUpdateContent"|"canDeleteContent"|"canPurgeAccount"|"canUpdateAvatar"|"canUpdateBanner"|"mentionLimit"|"canInvite"|"inviteLimit"|"inviteLimitCycle"|"inviteExpirationTime"|"canManageCustomEmojis"|"canManageAvatarDecorations"|"canSearchNotes"|"canUseTranslator"|"canUseDriveFileInSoundSettings"|"canUseReaction"|"canHideAds"|"driveCapacityMb"|"maxFileSizeMb"|"alwaysMarkNsfw"|"canUpdateBioMedia"|"skipNsfwDetection"|"pinLimit"|"antennaLimit"|"antennaNotesLimit"|"wordMuteLimit"|"webhookLimit"|"clipLimit"|"noteEachClipsLimit"|"userListLimit"|"userEachUserListsLimit"|"rateLimitFactor"|"avatarDecorationLimit"|"canImportAntennas"|"canImportBlocking"|"canImportFollowing"|"canImportMuting"|"canImportUserLists"|"mutualLinkSectionLimit"|"mutualLinkLimit"|"chatAvailability", operation?: "set"|"increment", value?: any, memo?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/roles/update-inline-policies")
  let body = {userId: $userId, policies: $policies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/roles/users
#
# POST /admin/roles/users
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/roles/users.ts — Source code
# operationId: post___admin___roles___users
export def "admin-roles-users users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  roleId: string # format: misskey:id
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --limit: int # default: 10
]: any -> table<id: string, createdAt: string, user: any, memo: string, expiresAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/roles/users")
  let body = {roleId: $roleId, sinceId: $sinceId, untilId: $untilId, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/send-email
#
# POST /admin/send-email
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/send-email.ts — Source code
# operationId: post___admin___send-email
export def "admin-send-email send-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-to: string
  subject: string
  text: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/send-email")
  let body = {to: $body_to, subject: $subject, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/show-moderation-logs
#
# POST /admin/show-moderation-logs
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/show-moderation-logs.ts — Source code
# operationId: post___admin___show-moderation-logs
export def "admin-show-moderation-logs show-moderation-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --type: string # nullable
  --userId: string # nullable, format: misskey:id
]: any -> table<id: string, createdAt: string, type: string, info: record, userId: string, user: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/show-moderation-logs")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId, type: $type, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/show-user
#
# POST /admin/show-user
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/show-user.ts — Source code
# operationId: post___admin___show-user
export def "admin-show-user show-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> record<email: string, emailVerified: bool, followedMessage: string, autoAcceptFollowed: bool, noCrawle: bool, preventAiLearning: bool, alwaysMarkNsfw: bool, autoSensitive: bool, carefulBot: bool, injectFeaturedNote: bool, receiveAnnouncementEmail: bool, mutedWords: list<any>, mutedInstances: list<string>, notificationRecieveConfig: record<note: record, follow: record, mention: record, reply: record, renote: record, quote: record, reaction: record, pollEnded: record, receiveFollowRequest: record, followRequestAccepted: record, roleAssigned: record, chatRoomInvitationReceived: record, achievementEarned: record, app: record, test: record>, isModerator: bool, isSilenced: bool, isLimited: bool, isDeleted: bool, isSuspended: bool, isHibernated: bool, lastActiveDate: string, moderationNote: string, signins: table<id: string, createdAt: string, ip: string, headers: record, success: bool>, policies: record<gtlAvailable: bool, ltlAvailable: bool, canPublicNote: bool, canScheduleNote: bool, scheduleNoteLimit: int, scheduleNoteMaxDays: int, canInitiateConversation: bool, canCreateContent: bool, canUpdateContent: bool, canDeleteContent: bool, canPurgeAccount: bool, canUpdateAvatar: bool, canUpdateBanner: bool, mentionLimit: int, canInvite: bool, inviteLimit: int, inviteLimitCycle: int, inviteExpirationTime: int, canManageCustomEmojis: bool, canManageAvatarDecorations: bool, canSearchNotes: bool, canUseTranslator: bool, canUseDriveFileInSoundSettings: bool, canUseReaction: bool, canHideAds: bool, driveCapacityMb: int, maxFileSizeMb: int, alwaysMarkNsfw: bool, skipNsfwDetection: bool, canUpdateBioMedia: bool, pinLimit: int, antennaLimit: int, antennaNotesLimit: int, wordMuteLimit: int, webhookLimit: int, clipLimit: int, noteEachClipsLimit: int, userListLimit: int, userEachUserListsLimit: int, rateLimitFactor: int, avatarDecorationLimit: int, canImportAntennas: bool, canImportBlocking: bool, canImportFollowing: bool, canImportMuting: bool, canImportUserLists: bool, mutualLinkSectionLimit: int, mutualLinkLimit: int, chatAvailability: string>, roles: list<record>, roleAssigns: table<createdAt: string, expiresAt: string, roleId: string, memo: string>, inlinePolicies: table<id: string, createdAt: string, updatedAt: string, policy: string, operation: string, value: any, memo: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/show-user")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/show-user-account-move-logs
#
# POST /admin/show-user-account-move-logs
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/show-user-account-move-logs.ts — Source code
# operationId: post___admin___show-user-account-move-logs
export def "admin-show-user-account-move-logs show-user-account-move-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --movedFromId: string # nullable, format: misskey:id
  --movedToId: string # nullable, format: misskey:id
  --body-from: string@from-completer # nullable
  --body-to: string@to-completer # nullable
]: any -> table<id: string, createdAt: string, movedToId: string, movedTo: any, movedFromId: string, movedFrom: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/show-user-account-move-logs")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId, movedFromId: $movedFromId, movedToId: $movedToId, from: $body_from, to: $body_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/show-users
#
# POST /admin/show-users
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/show-users.ts — Source code
# operationId: post___admin___show-users
export def "admin-show-users show-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int # default: 0
  --body-sort: string@sort-completer-2
  --state: string@state-completer-1 # default: all
  --origin: string@origin-completer # default: combined
  --username: string # nullable
  --hostname: string # The local host is represented with `null`. (nullable)
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/show-users")
  let body = {limit: $limit, offset: $offset, sort: $body_sort, state: $state, origin: $origin, username: $username, hostname: $hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/sso/create
#
# POST /admin/sso/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/sso/create.ts — Source code
# operationId: post___admin___sso___create
export def "admin-sso-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # nullable
  type: string@type-completer-3
  issuer: string
  --audience: list # default: []
  --binding: string@binding-completer
  acsUrl: string
  signatureAlgorithm: string
  --cipherAlgorithm: string # nullable
  --wantAuthnRequestsSigned: oneof<nothing, bool> # default: false
  --wantAssertionsSigned: oneof<nothing, bool> # default: true
  --wantEmailAddressNormalized: oneof<nothing, bool> # default: true
  --useCertificate: oneof<nothing, bool> # default: true
  --secret: string # nullable
]: any -> record<id: string, createdAt: string, name: string, type: string, issuer: string, audience: list<string>, binding: string, acsUrl: string, publicKey: string, signatureAlgorithm: string, cipherAlgorithm: string, wantAuthnRequestsSigned: bool, wantAssertionsSigned: bool, wantEmailAddressNormalized: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/sso/create")
  let body = {name: $name, type: $type, issuer: $issuer, audience: $audience, binding: $binding, acsUrl: $acsUrl, signatureAlgorithm: $signatureAlgorithm, cipherAlgorithm: $cipherAlgorithm, wantAuthnRequestsSigned: $wantAuthnRequestsSigned, wantAssertionsSigned: $wantAssertionsSigned, wantEmailAddressNormalized: $wantEmailAddressNormalized, useCertificate: $useCertificate, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/sso/delete
#
# POST /admin/sso/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/sso/delete.ts — Source code
# operationId: post___admin___sso___delete
export def "admin-sso-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/sso/delete")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/sso/list
#
# POST /admin/sso/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/sso/list.ts — Source code
# operationId: post___admin___sso___list
export def "admin-sso-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int # default: 0
]: any -> table<id: string, createdAt: string, name: string, type: string, issuer: string, audience: list<string>, binding: string, acsUrl: string, useCertificate: bool, publicKey: string, signatureAlgorithm: string, cipherAlgorithm: string, wantAuthnRequestsSigned: bool, wantAssertionsSigned: bool, wantEmailAddressNormalized: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/sso/list")
  let body = {limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/sso/update
#
# POST /admin/sso/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/sso/update.ts — Source code
# operationId: post___admin___sso___update
export def "admin-sso-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string
  --name: string # nullable
  --issuer: string
  --audience: list
  --binding: string@binding-completer
  --acsUrl: string
  --signatureAlgorithm: string
  --cipherAlgorithm: string # nullable
  --wantAuthnRequestsSigned: oneof<nothing, bool>
  --wantAssertionsSigned: oneof<nothing, bool>
  --wantEmailAddressNormalized: oneof<nothing, bool>
  --regenerateCertificate: oneof<nothing, bool> # nullable
  --secret: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/sso/update")
  let body = {id: $id, name: $name, issuer: $issuer, audience: $audience, binding: $binding, acsUrl: $acsUrl, signatureAlgorithm: $signatureAlgorithm, cipherAlgorithm: $cipherAlgorithm, wantAuthnRequestsSigned: $wantAuthnRequestsSigned, wantAssertionsSigned: $wantAssertionsSigned, wantEmailAddressNormalized: $wantEmailAddressNormalized, regenerateCertificate: $regenerateCertificate, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/suspend-user
#
# POST /admin/suspend-user
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/suspend-user.ts — Source code
# operationId: post___admin___suspend-user
export def "admin-suspend-user suspend-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/suspend-user")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/system-webhook/create
#
# POST /admin/system-webhook/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/system-webhook/create.ts — Source code
# operationId: post___admin___system-webhook___create
export def "admin-system-webhook-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isActive: oneof<nothing, bool>
  name: string
  on: list
  --body-url: string
  secret: string
]: any -> record<id: string, isActive: bool, updatedAt: string, latestSentAt: string, latestStatus: float, name: string, on: list<string>, url: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/system-webhook/create")
  let body = {isActive: $isActive, name: $name, on: $on, url: $body_url, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/system-webhook/delete
#
# POST /admin/system-webhook/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/system-webhook/delete.ts — Source code
# operationId: post___admin___system-webhook___delete
export def "admin-system-webhook-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/system-webhook/delete")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/system-webhook/list
#
# POST /admin/system-webhook/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/system-webhook/list.ts — Source code
# operationId: post___admin___system-webhook___list
export def "admin-system-webhook-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isActive: oneof<nothing, bool>
  --on: list
]: any -> table<id: string, isActive: bool, updatedAt: string, latestSentAt: string, latestStatus: float, name: string, on: list<string>, url: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/system-webhook/list")
  let body = {isActive: $isActive, on: $on} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/system-webhook/show
#
# POST /admin/system-webhook/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/system-webhook/show.ts — Source code
# operationId: post___admin___system-webhook___show
export def "admin-system-webhook-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: misskey:id
]: any -> record<id: string, isActive: bool, updatedAt: string, latestSentAt: string, latestStatus: float, name: string, on: list<string>, url: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/system-webhook/show")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/system-webhook/test
#
# POST /admin/system-webhook/test
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/system-webhook/test.ts — Source code
# operationId: post___admin___system-webhook___test
# --override shape: {url?: string, secret?: string}
export def "admin-system-webhook-test test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  webhookId: string # format: misskey:id
  type: string@type-completer-4
  --override: record # shape: {url?: string, secret?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/system-webhook/test")
  let body = {webhookId: $webhookId, type: $type, override: $override} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/system-webhook/update
#
# POST /admin/system-webhook/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/system-webhook/update.ts — Source code
# operationId: post___admin___system-webhook___update
export def "admin-system-webhook-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: misskey:id
  --isActive: oneof<nothing, bool>
  name: string
  on: list
  --body-url: string
  secret: string
]: any -> record<id: string, isActive: bool, updatedAt: string, latestSentAt: string, latestStatus: float, name: string, on: list<string>, url: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/system-webhook/update")
  let body = {id: $id, isActive: $isActive, name: $name, on: $on, url: $body_url, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/unset-user-avatar
#
# POST /admin/unset-user-avatar
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/unset-user-avatar.ts — Source code
# operationId: post___admin___unset-user-avatar
export def "admin-unset-user-avatar unset-user-avatar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/unset-user-avatar")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/unset-user-banner
#
# POST /admin/unset-user-banner
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/unset-user-banner.ts — Source code
# operationId: post___admin___unset-user-banner
export def "admin-unset-user-banner unset-user-banner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/unset-user-banner")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/unset-user-mutual-link
#
# POST /admin/unset-user-mutual-link
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/unset-user-mutual-link.ts — Source code
# operationId: post___admin___unset-user-mutual-link
export def "admin-unset-user-mutual-link unset-user-mutual-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
  itemId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/unset-user-mutual-link")
  let body = {userId: $userId, itemId: $itemId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/unsuspend-user
#
# POST /admin/unsuspend-user
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/unsuspend-user.ts — Source code
# operationId: post___admin___unsuspend-user
export def "admin-unsuspend-user unsuspend-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/unsuspend-user")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/update-abuse-user-report
#
# POST /admin/update-abuse-user-report
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/update-abuse-user-report.ts — Source code
# operationId: post___admin___update-abuse-user-report
export def "admin-update-abuse-user-report update-abuse-user-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  reportId: string # format: misskey:id
  --moderationNote: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/update-abuse-user-report")
  let body = {reportId: $reportId, moderationNote: $moderationNote} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/update-meta
#
# POST /admin/update-meta
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/update-meta.ts — Source code
# operationId: post___admin___update-meta
export def "admin-update-meta update-meta" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --disableRegistration: oneof<nothing, bool> # nullable
  --pinnedUsers: list # nullable
  --hiddenTags: list # nullable
  --blockedHosts: list # nullable
  --sensitiveWords: list # nullable
  --blockedRemoteCustomEmojis: list # nullable
  --prohibitedWords: list # nullable
  --themeColor: string # nullable
  --mascotImageUrl: string # nullable
  --bannerUrl: string # nullable
  --serverErrorImageUrl: string # nullable
  --infoImageUrl: string # nullable
  --notFoundImageUrl: string # nullable
  --iconUrl: string # nullable
  --app192IconUrl: string # nullable
  --app512IconUrl: string # nullable
  --backgroundImageUrl: string # nullable
  --logoImageUrl: string # nullable
  --name: string # nullable
  --shortName: string # nullable
  --description: string # nullable
  --defaultLightTheme: string # nullable
  --defaultDarkTheme: string # nullable
  --cacheRemoteFiles: oneof<nothing, bool>
  --cacheRemoteSensitiveFiles: oneof<nothing, bool>
  --emailRequiredForSignup: oneof<nothing, bool>
  --enableHcaptcha: oneof<nothing, bool>
  --hcaptchaSiteKey: string # nullable
  --hcaptchaSecretKey: string # nullable
  --enableMcaptcha: oneof<nothing, bool>
  --mcaptchaSiteKey: string # nullable
  --mcaptchaInstanceUrl: string # nullable
  --mcaptchaSecretKey: string # nullable
  --enableRecaptcha: oneof<nothing, bool>
  --recaptchaSiteKey: string # nullable
  --recaptchaSecretKey: string # nullable
  --enableTurnstile: oneof<nothing, bool>
  --turnstileSiteKey: string # nullable
  --turnstileSecretKey: string # nullable
  --googleAnalyticsId: string # nullable
  --sensitiveMediaDetection: string@sensitiveMediaDetection-completer
  --sensitiveMediaDetectionSensitivity: string@sensitiveMediaDetectionSensitivity-completer
  --setSensitiveFlagAutomatically: oneof<nothing, bool>
  --enableSensitiveMediaDetectionForVideos: oneof<nothing, bool>
  --maintainerName: string # nullable
  --maintainerEmail: string # nullable
  --langs: list
  --dimensions: int
  --deeplAuthKey: string # nullable
  --deeplIsPro: oneof<nothing, bool>
  --enableEmail: oneof<nothing, bool>
  --email: string # nullable
  --smtpSecure: oneof<nothing, bool>
  --smtpHost: string # nullable
  --smtpPort: int # nullable
  --smtpUser: string # nullable
  --smtpPass: string # nullable
  --enableServiceWorker: oneof<nothing, bool>
  --swPublicKey: string # nullable
  --swPrivateKey: string # nullable
  --tosUrl: string # nullable
  --repositoryUrl: string # nullable
  --feedbackUrl: string # nullable
  --impressumUrl: string # nullable
  --privacyPolicyUrl: string # nullable
  --useObjectStorage: oneof<nothing, bool>
  --objectStorageBaseUrl: string # nullable
  --objectStorageBucket: string # nullable
  --objectStoragePrefix: string # nullable
  --objectStorageEndpoint: string # nullable
  --objectStorageRegion: string # nullable
  --objectStoragePort: int # nullable
  --objectStorageAccessKey: string # nullable
  --objectStorageSecretKey: string # nullable
  --objectStorageUseSSL: oneof<nothing, bool>
  --objectStorageUseProxy: oneof<nothing, bool>
  --objectStorageSetPublicRead: oneof<nothing, bool>
  --objectStorageS3ForcePathStyle: oneof<nothing, bool>
  --enableIpLogging: oneof<nothing, bool>
  --enableActiveEmailValidation: oneof<nothing, bool>
  --enableVerifymailApi: oneof<nothing, bool>
  --verifymailAuthKey: string # nullable
  --enableTruemailApi: oneof<nothing, bool>
  --truemailInstance: string # nullable
  --truemailAuthKey: string # nullable
  --enableChartsForRemoteUser: oneof<nothing, bool>
  --enableChartsForFederatedInstances: oneof<nothing, bool>
  --enableServerMachineStats: oneof<nothing, bool>
  --enableIdenticonGeneration: oneof<nothing, bool>
  --serverRules: list
  --bannedEmailDomains: list
  --preservedUsernames: list
  --manifestJsonOverride: string
  --enableFanoutTimeline: oneof<nothing, bool>
  --enableFanoutTimelineDbFallback: oneof<nothing, bool>
  --perLocalUserUserTimelineCacheMax: int
  --perRemoteUserUserTimelineCacheMax: int
  --perUserHomeTimelineCacheMax: int
  --perUserListTimelineCacheMax: int
  --notesPerOneAd: int
  --silencedHosts: list # nullable
  --sensitiveMediaHosts: list # nullable
  --wellKnownWebsites: list # nullable
  --urlPreviewDenyList: list # nullable
  --featuredGameChannels: list # nullable
  --summalyProxy: string # [Deprecated] Use "urlPreviewSummaryProxyUrl" instead. (nullable)
  --urlPreviewEnabled: oneof<nothing, bool>
  --urlPreviewTimeout: int
  --urlPreviewMaximumContentLength: int
  --urlPreviewRequireContentLength: oneof<nothing, bool>
  --urlPreviewUserAgent: string # nullable
  --urlPreviewSummaryProxyUrl: string # nullable
  --prohibitedWordsForNameOfUser: list # nullable
  --federation: string@federation-completer
  --federationHosts: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/update-meta")
  let body = {disableRegistration: $disableRegistration, pinnedUsers: $pinnedUsers, hiddenTags: $hiddenTags, blockedHosts: $blockedHosts, sensitiveWords: $sensitiveWords, blockedRemoteCustomEmojis: $blockedRemoteCustomEmojis, prohibitedWords: $prohibitedWords, themeColor: $themeColor, mascotImageUrl: $mascotImageUrl, bannerUrl: $bannerUrl, serverErrorImageUrl: $serverErrorImageUrl, infoImageUrl: $infoImageUrl, notFoundImageUrl: $notFoundImageUrl, iconUrl: $iconUrl, app192IconUrl: $app192IconUrl, app512IconUrl: $app512IconUrl, backgroundImageUrl: $backgroundImageUrl, logoImageUrl: $logoImageUrl, name: $name, shortName: $shortName, description: $description, defaultLightTheme: $defaultLightTheme, defaultDarkTheme: $defaultDarkTheme, cacheRemoteFiles: $cacheRemoteFiles, cacheRemoteSensitiveFiles: $cacheRemoteSensitiveFiles, emailRequiredForSignup: $emailRequiredForSignup, enableHcaptcha: $enableHcaptcha, hcaptchaSiteKey: $hcaptchaSiteKey, hcaptchaSecretKey: $hcaptchaSecretKey, enableMcaptcha: $enableMcaptcha, mcaptchaSiteKey: $mcaptchaSiteKey, mcaptchaInstanceUrl: $mcaptchaInstanceUrl, mcaptchaSecretKey: $mcaptchaSecretKey, enableRecaptcha: $enableRecaptcha, recaptchaSiteKey: $recaptchaSiteKey, recaptchaSecretKey: $recaptchaSecretKey, enableTurnstile: $enableTurnstile, turnstileSiteKey: $turnstileSiteKey, turnstileSecretKey: $turnstileSecretKey, googleAnalyticsId: $googleAnalyticsId, sensitiveMediaDetection: $sensitiveMediaDetection, sensitiveMediaDetectionSensitivity: $sensitiveMediaDetectionSensitivity, setSensitiveFlagAutomatically: $setSensitiveFlagAutomatically, enableSensitiveMediaDetectionForVideos: $enableSensitiveMediaDetectionForVideos, maintainerName: $maintainerName, maintainerEmail: $maintainerEmail, langs: $langs, dimensions: $dimensions, deeplAuthKey: $deeplAuthKey, deeplIsPro: $deeplIsPro, enableEmail: $enableEmail, email: $email, smtpSecure: $smtpSecure, smtpHost: $smtpHost, smtpPort: $smtpPort, smtpUser: $smtpUser, smtpPass: $smtpPass, enableServiceWorker: $enableServiceWorker, swPublicKey: $swPublicKey, swPrivateKey: $swPrivateKey, tosUrl: $tosUrl, repositoryUrl: $repositoryUrl, feedbackUrl: $feedbackUrl, impressumUrl: $impressumUrl, privacyPolicyUrl: $privacyPolicyUrl, useObjectStorage: $useObjectStorage, objectStorageBaseUrl: $objectStorageBaseUrl, objectStorageBucket: $objectStorageBucket, objectStoragePrefix: $objectStoragePrefix, objectStorageEndpoint: $objectStorageEndpoint, objectStorageRegion: $objectStorageRegion, objectStoragePort: $objectStoragePort, objectStorageAccessKey: $objectStorageAccessKey, objectStorageSecretKey: $objectStorageSecretKey, objectStorageUseSSL: $objectStorageUseSSL, objectStorageUseProxy: $objectStorageUseProxy, objectStorageSetPublicRead: $objectStorageSetPublicRead, objectStorageS3ForcePathStyle: $objectStorageS3ForcePathStyle, enableIpLogging: $enableIpLogging, enableActiveEmailValidation: $enableActiveEmailValidation, enableVerifymailApi: $enableVerifymailApi, verifymailAuthKey: $verifymailAuthKey, enableTruemailApi: $enableTruemailApi, truemailInstance: $truemailInstance, truemailAuthKey: $truemailAuthKey, enableChartsForRemoteUser: $enableChartsForRemoteUser, enableChartsForFederatedInstances: $enableChartsForFederatedInstances, enableServerMachineStats: $enableServerMachineStats, enableIdenticonGeneration: $enableIdenticonGeneration, serverRules: $serverRules, bannedEmailDomains: $bannedEmailDomains, preservedUsernames: $preservedUsernames, manifestJsonOverride: $manifestJsonOverride, enableFanoutTimeline: $enableFanoutTimeline, enableFanoutTimelineDbFallback: $enableFanoutTimelineDbFallback, perLocalUserUserTimelineCacheMax: $perLocalUserUserTimelineCacheMax, perRemoteUserUserTimelineCacheMax: $perRemoteUserUserTimelineCacheMax, perUserHomeTimelineCacheMax: $perUserHomeTimelineCacheMax, perUserListTimelineCacheMax: $perUserListTimelineCacheMax, notesPerOneAd: $notesPerOneAd, silencedHosts: $silencedHosts, sensitiveMediaHosts: $sensitiveMediaHosts, wellKnownWebsites: $wellKnownWebsites, urlPreviewDenyList: $urlPreviewDenyList, featuredGameChannels: $featuredGameChannels, summalyProxy: $summalyProxy, urlPreviewEnabled: $urlPreviewEnabled, urlPreviewTimeout: $urlPreviewTimeout, urlPreviewMaximumContentLength: $urlPreviewMaximumContentLength, urlPreviewRequireContentLength: $urlPreviewRequireContentLength, urlPreviewUserAgent: $urlPreviewUserAgent, urlPreviewSummaryProxyUrl: $urlPreviewSummaryProxyUrl, prohibitedWordsForNameOfUser: $prohibitedWordsForNameOfUser, federation: $federation, federationHosts: $federationHosts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/update-proxy-account
#
# POST /admin/update-proxy-account
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/update-proxy-account.ts — Source code
# operationId: post___admin___update-proxy-account
export def "admin-update-proxy-account update-proxy-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/update-proxy-account")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/update-user-name
#
# POST /admin/update-user-name
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/update-user-name.ts — Source code
# operationId: post___admin___update-user-name
export def "admin-update-user-name update-user-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/update-user-name")
  let body = {userId: $userId, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# admin/update-user-note
#
# POST /admin/update-user-note
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/admin/update-user-note.ts — Source code
# operationId: post___admin___update-user-note
export def "admin-update-user-note update-user-note" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
  text: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/update-user-note")
  let body = {userId: $userId, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# announcement
#
# POST /announcement
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/announcement.ts — Source code
# operationId: post___announcement
export def "announcement announcement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  announcementId: string # format: misskey:id
]: any -> record<id: string, createdAt: string, updatedAt: string, text: string, title: string, imageUrl: string, icon: string, display: string, needConfirmationToRead: bool, needEnrollmentTutorialToRead: bool, forYou: bool, closeDuration: float, displayOrder: float, silence: bool, isRead: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/announcement")
  let body = {announcementId: $announcementId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# announcements
#
# POST /announcements
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/announcements.ts — Source code
# operationId: post___announcements
export def "announcements announcements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --offset: int # default: 0
  --isActive: oneof<nothing, bool> # default: true
]: any -> table<id: string, createdAt: string, updatedAt: string, text: string, title: string, imageUrl: string, icon: string, display: string, needConfirmationToRead: bool, needEnrollmentTutorialToRead: bool, forYou: bool, closeDuration: float, displayOrder: float, silence: bool, isRead: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/announcements")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId, offset: $offset, isActive: $isActive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# announcements/show
#
# POST /announcements/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/announcements/show.ts — Source code
# operationId: post___announcements___show
export def "announcements-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  announcementId: string # format: misskey:id
]: any -> record<id: string, createdAt: string, updatedAt: string, text: string, title: string, imageUrl: string, icon: string, display: string, needConfirmationToRead: bool, needEnrollmentTutorialToRead: bool, forYou: bool, closeDuration: float, displayOrder: float, silence: bool, isRead: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/announcements/show")
  let body = {announcementId: $announcementId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# antennas/create
#
# POST /antennas/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/antennas/create.ts — Source code
# operationId: post___antennas___create
export def "antennas-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  src: string@src-completer
  --userListId: string # nullable, format: misskey:id
  keywords: list
  excludeKeywords: list
  users: list
  --caseSensitive: oneof<nothing, bool>
  --localOnly: oneof<nothing, bool>
  --excludeBots: oneof<nothing, bool>
  --withReplies: oneof<nothing, bool>
  --withFile: oneof<nothing, bool>
  --excludeNotesInSensitiveChannel: oneof<nothing, bool>
]: any -> record<id: string, createdAt: string, name: string, keywords: list<list<string>>, excludeKeywords: list<list<string>>, src: string, userListId: string, users: list<string>, caseSensitive: bool, localOnly: bool, excludeBots: bool, withReplies: bool, withFile: bool, isActive: bool, hasUnreadNote: bool, notify: bool, excludeNotesInSensitiveChannel: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/antennas/create")
  let body = {name: $name, src: $src, userListId: $userListId, keywords: $keywords, excludeKeywords: $excludeKeywords, users: $users, caseSensitive: $caseSensitive, localOnly: $localOnly, excludeBots: $excludeBots, withReplies: $withReplies, withFile: $withFile, excludeNotesInSensitiveChannel: $excludeNotesInSensitiveChannel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# antennas/delete
#
# POST /antennas/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/antennas/delete.ts — Source code
# operationId: post___antennas___delete
export def "antennas-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  antennaId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/antennas/delete")
  let body = {antennaId: $antennaId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# antennas/list
#
# POST /antennas/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/antennas/list.ts — Source code
# operationId: post___antennas___list
export def "antennas-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, createdAt: string, name: string, keywords: list<list>, excludeKeywords: list<list>, src: string, userListId: string, users: list<string>, caseSensitive: bool, localOnly: bool, excludeBots: bool, withReplies: bool, withFile: bool, isActive: bool, hasUnreadNote: bool, notify: bool, excludeNotesInSensitiveChannel: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/antennas/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# antennas/notes
#
# POST /antennas/notes
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/antennas/notes.ts — Source code
# operationId: post___antennas___notes
export def "antennas-notes notes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  antennaId: string # format: misskey:id
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --sinceDate: int
  --untilDate: int
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/antennas/notes")
  let body = {antennaId: $antennaId, limit: $limit, sinceId: $sinceId, untilId: $untilId, sinceDate: $sinceDate, untilDate: $untilDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# antennas/show
#
# POST /antennas/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/antennas/show.ts — Source code
# operationId: post___antennas___show
export def "antennas-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  antennaId: string # format: misskey:id
]: any -> record<id: string, createdAt: string, name: string, keywords: list<list<string>>, excludeKeywords: list<list<string>>, src: string, userListId: string, users: list<string>, caseSensitive: bool, localOnly: bool, excludeBots: bool, withReplies: bool, withFile: bool, isActive: bool, hasUnreadNote: bool, notify: bool, excludeNotesInSensitiveChannel: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/antennas/show")
  let body = {antennaId: $antennaId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# antennas/update
#
# POST /antennas/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/antennas/update.ts — Source code
# operationId: post___antennas___update
export def "antennas-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  antennaId: string # format: misskey:id
  --name: string
  --src: string@src-completer
  --userListId: string # nullable, format: misskey:id
  --keywords: list
  --excludeKeywords: list
  --users: list
  --caseSensitive: oneof<nothing, bool>
  --localOnly: oneof<nothing, bool>
  --excludeBots: oneof<nothing, bool>
  --withReplies: oneof<nothing, bool>
  --withFile: oneof<nothing, bool>
  --excludeNotesInSensitiveChannel: oneof<nothing, bool>
]: any -> record<id: string, createdAt: string, name: string, keywords: list<list<string>>, excludeKeywords: list<list<string>>, src: string, userListId: string, users: list<string>, caseSensitive: bool, localOnly: bool, excludeBots: bool, withReplies: bool, withFile: bool, isActive: bool, hasUnreadNote: bool, notify: bool, excludeNotesInSensitiveChannel: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/antennas/update")
  let body = {antennaId: $antennaId, name: $name, src: $src, userListId: $userListId, keywords: $keywords, excludeKeywords: $excludeKeywords, users: $users, caseSensitive: $caseSensitive, localOnly: $localOnly, excludeBots: $excludeBots, withReplies: $withReplies, withFile: $withFile, excludeNotesInSensitiveChannel: $excludeNotesInSensitiveChannel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ap/get
#
# POST /ap/get
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/ap/get.ts — Source code
# operationId: post___ap___get
export def "ap-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  uri: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ap/get")
  let body = {uri: $uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ap/show
#
# POST /ap/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/ap/show.ts — Source code
# operationId: post___ap___show
export def "ap-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  uri: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ap/show")
  let body = {uri: $uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# app/create
#
# POST /app/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/app/create.ts — Source code
# operationId: post___app___create
export def "app-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  description: string
  permission: list
  --callbackUrl: string # nullable
]: any -> record<id: string, name: string, callbackUrl: string, permission: list<string>, secret: string, isAuthorized: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/app/create")
  let body = {name: $name, description: $description, permission: $permission, callbackUrl: $callbackUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# app/show
#
# POST /app/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/app/show.ts — Source code
# operationId: post___app___show
export def "app-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  appId: string # format: misskey:id
]: any -> record<id: string, name: string, callbackUrl: string, permission: list<string>, secret: string, isAuthorized: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/app/show")
  let body = {appId: $appId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# auth/accept
#
# POST /auth/accept
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/auth/accept.ts — Source code
# operationId: post___auth___accept
export def "auth-accept accept" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/accept")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# auth/session/generate
#
# POST /auth/session/generate
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/auth/session/generate.ts — Source code
# operationId: post___auth___session___generate
export def "auth-session-generate generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  appSecret: string
]: any -> record<token: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/session/generate")
  let body = {appSecret: $appSecret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# auth/session/show
#
# POST /auth/session/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/auth/session/show.ts — Source code
# operationId: post___auth___session___show
export def "auth-session-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string
]: any -> record<id: string, app: record<id: string, name: string, callbackUrl: string, permission: list<string>, secret: string, isAuthorized: bool>, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/session/show")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# auth/session/userkey
#
# POST /auth/session/userkey
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/auth/session/userkey.ts — Source code
# operationId: post___auth___session___userkey
export def "auth-session-userkey userkey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  appSecret: string
  --body-token: string
]: any -> record<accessToken: string, user: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/session/userkey")
  let body = {appSecret: $appSecret, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# blocking/create
#
# POST /blocking/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/blocking/create.ts — Source code
# operationId: post___blocking___create
export def "blocking-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/blocking/create")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# blocking/delete
#
# POST /blocking/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/blocking/delete.ts — Source code
# operationId: post___blocking___delete
export def "blocking-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/blocking/delete")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# blocking/list
#
# POST /blocking/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/blocking/list.ts — Source code
# operationId: post___blocking___list
export def "blocking-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 30
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, blockeeId: string, blockee: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/blocking/list")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# bubble-game/ranking
#
# GET /bubble-game/ranking
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/bubble-game/ranking.ts — Source code
# operationId: get___bubble-game___ranking
export def "bubble-game-ranking ranking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  gameMode: string
]: any -> table<id: string, score: int, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bubble-game/ranking")
  let body = {gameMode: $gameMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# bubble-game/ranking
#
# POST /bubble-game/ranking
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/bubble-game/ranking.ts — Source code
# operationId: post___bubble-game___ranking
export def "bubble-game-ranking ranking-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  gameMode: string
]: any -> table<id: string, score: int, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bubble-game/ranking")
  let body = {gameMode: $gameMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# bubble-game/register
#
# POST /bubble-game/register
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/bubble-game/register.ts — Source code
# operationId: post___bubble-game___register
export def "bubble-game-register register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  score: int
  seed: string
  logs: list
  gameMode: string
  gameVersion: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bubble-game/register")
  let body = {score: $score, seed: $seed, logs: $logs, gameMode: $gameMode, gameVersion: $gameVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# channels/create
#
# POST /channels/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/channels/create.ts — Source code
# operationId: post___channels___create
export def "channels-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string # nullable
  --bannerId: string # nullable, format: misskey:id
  --color: string
  --isSensitive: oneof<nothing, bool> # nullable
  --allowRenoteToExternal: oneof<nothing, bool> # nullable
]: any -> record<id: string, createdAt: string, lastNotedAt: string, name: string, description: string, userId: string, bannerUrl: string, pinnedNoteIds: list<string>, color: string, isArchived: bool, usersCount: float, notesCount: float, isSensitive: bool, allowRenoteToExternal: bool, isFollowing: bool, isFavorited: bool, pinnedNotes: table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list, visibleUserIds: list, fileIds: list, files: list, tags: list, poll: record, emojis: record, channelId: string, channel: record, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list, clippedCount: float, myReaction: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/create")
  let body = {name: $name, description: $description, bannerId: $bannerId, color: $color, isSensitive: $isSensitive, allowRenoteToExternal: $allowRenoteToExternal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# channels/favorite
#
# POST /channels/favorite
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/channels/favorite.ts — Source code
# operationId: post___channels___favorite
export def "channels-favorite favorite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channelId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/favorite")
  let body = {channelId: $channelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# channels/featured
#
# POST /channels/featured
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/channels/featured.ts — Source code
# operationId: post___channels___featured
export def "channels-featured featured" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, createdAt: string, lastNotedAt: string, name: string, description: string, userId: string, bannerUrl: string, pinnedNoteIds: list<string>, color: string, isArchived: bool, usersCount: float, notesCount: float, isSensitive: bool, allowRenoteToExternal: bool, isFollowing: bool, isFavorited: bool, pinnedNotes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/featured")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# channels/featured-games
#
# POST /channels/featured-games
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/channels/featured-games.ts — Source code
# operationId: post___channels___featured-games
export def "channels-featured-games featured-games" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, createdAt: string, lastNotedAt: string, name: string, description: string, userId: string, bannerUrl: string, pinnedNoteIds: list<string>, color: string, isArchived: bool, usersCount: float, notesCount: float, isSensitive: bool, allowRenoteToExternal: bool, isFollowing: bool, isFavorited: bool, pinnedNotes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/featured-games")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# channels/follow
#
# POST /channels/follow
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/channels/follow.ts — Source code
# operationId: post___channels___follow
export def "channels-follow follow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channelId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/follow")
  let body = {channelId: $channelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# channels/followed
#
# POST /channels/followed
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/channels/followed.ts — Source code
# operationId: post___channels___followed
export def "channels-followed followed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --limit: int # default: 5
]: any -> table<id: string, createdAt: string, lastNotedAt: string, name: string, description: string, userId: string, bannerUrl: string, pinnedNoteIds: list<string>, color: string, isArchived: bool, usersCount: float, notesCount: float, isSensitive: bool, allowRenoteToExternal: bool, isFollowing: bool, isFavorited: bool, pinnedNotes: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/followed")
  let body = {sinceId: $sinceId, untilId: $untilId, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# channels/my-favorites
#
# POST /channels/my-favorites
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/channels/my-favorites.ts — Source code
# operationId: post___channels___my-favorites
export def "channels-my-favorites my-favorites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, createdAt: string, lastNotedAt: string, name: string, description: string, userId: string, bannerUrl: string, pinnedNoteIds: list<string>, color: string, isArchived: bool, usersCount: float, notesCount: float, isSensitive: bool, allowRenoteToExternal: bool, isFollowing: bool, isFavorited: bool, pinnedNotes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/my-favorites")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# channels/owned
#
# POST /channels/owned
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/channels/owned.ts — Source code
# operationId: post___channels___owned
export def "channels-owned owned" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --limit: int # default: 5
]: any -> table<id: string, createdAt: string, lastNotedAt: string, name: string, description: string, userId: string, bannerUrl: string, pinnedNoteIds: list<string>, color: string, isArchived: bool, usersCount: float, notesCount: float, isSensitive: bool, allowRenoteToExternal: bool, isFollowing: bool, isFavorited: bool, pinnedNotes: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/owned")
  let body = {sinceId: $sinceId, untilId: $untilId, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# channels/search
#
# POST /channels/search
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/channels/search.ts — Source code
# operationId: post___channels___search
export def "channels-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-query: string
  --type: string@type-completer-5 # default: nameAndDescription
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --limit: int # default: 5
]: any -> table<id: string, createdAt: string, lastNotedAt: string, name: string, description: string, userId: string, bannerUrl: string, pinnedNoteIds: list<string>, color: string, isArchived: bool, usersCount: float, notesCount: float, isSensitive: bool, allowRenoteToExternal: bool, isFollowing: bool, isFavorited: bool, pinnedNotes: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/search")
  let body = {query: $body_query, type: $type, sinceId: $sinceId, untilId: $untilId, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# channels/show
#
# POST /channels/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/channels/show.ts — Source code
# operationId: post___channels___show
export def "channels-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channelId: string # format: misskey:id
]: any -> record<id: string, createdAt: string, lastNotedAt: string, name: string, description: string, userId: string, bannerUrl: string, pinnedNoteIds: list<string>, color: string, isArchived: bool, usersCount: float, notesCount: float, isSensitive: bool, allowRenoteToExternal: bool, isFollowing: bool, isFavorited: bool, pinnedNotes: table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list, visibleUserIds: list, fileIds: list, files: list, tags: list, poll: record, emojis: record, channelId: string, channel: record, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list, clippedCount: float, myReaction: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/show")
  let body = {channelId: $channelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# channels/timeline
#
# POST /channels/timeline
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/channels/timeline.ts — Source code
# operationId: post___channels___timeline
export def "channels-timeline timeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channelId: string # format: misskey:id
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --sinceDate: int
  --untilDate: int
  --allowPartial: oneof<nothing, bool> # default: false
  --dimension: int # nullable
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/timeline")
  let body = {channelId: $channelId, limit: $limit, sinceId: $sinceId, untilId: $untilId, sinceDate: $sinceDate, untilDate: $untilDate, allowPartial: $allowPartial, dimension: $dimension} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# channels/unfavorite
#
# POST /channels/unfavorite
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/channels/unfavorite.ts — Source code
# operationId: post___channels___unfavorite
export def "channels-unfavorite unfavorite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channelId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/unfavorite")
  let body = {channelId: $channelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# channels/unfollow
#
# POST /channels/unfollow
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/channels/unfollow.ts — Source code
# operationId: post___channels___unfollow
export def "channels-unfollow unfollow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channelId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/unfollow")
  let body = {channelId: $channelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# channels/update
#
# POST /channels/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/channels/update.ts — Source code
# operationId: post___channels___update
export def "channels-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channelId: string # format: misskey:id
  --name: string
  --description: string # nullable
  --bannerId: string # nullable, format: misskey:id
  --isArchived: oneof<nothing, bool> # nullable
  --pinnedNoteIds: list
  --color: string
  --isSensitive: oneof<nothing, bool> # nullable
  --allowRenoteToExternal: oneof<nothing, bool> # nullable
]: any -> record<id: string, createdAt: string, lastNotedAt: string, name: string, description: string, userId: string, bannerUrl: string, pinnedNoteIds: list<string>, color: string, isArchived: bool, usersCount: float, notesCount: float, isSensitive: bool, allowRenoteToExternal: bool, isFollowing: bool, isFavorited: bool, pinnedNotes: table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list, visibleUserIds: list, fileIds: list, files: list, tags: list, poll: record, emojis: record, channelId: string, channel: record, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list, clippedCount: float, myReaction: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/update")
  let body = {channelId: $channelId, name: $name, description: $description, bannerId: $bannerId, isArchived: $isArchived, pinnedNoteIds: $pinnedNoteIds, color: $color, isSensitive: $isSensitive, allowRenoteToExternal: $allowRenoteToExternal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/active-users
#
# GET /charts/active-users
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/active-users.ts — Source code
# operationId: get___charts___active-users
export def "charts-active-users active-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
]: any -> record<readWrite: list<float>, read: list<float>, write: list<float>, registeredWithinWeek: list<float>, registeredWithinMonth: list<float>, registeredWithinYear: list<float>, registeredOutsideWeek: list<float>, registeredOutsideMonth: list<float>, registeredOutsideYear: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/active-users")
  let body = {span: $span, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/active-users
#
# POST /charts/active-users
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/active-users.ts — Source code
# operationId: post___charts___active-users
export def "charts-active-users active-users-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
]: any -> record<readWrite: list<float>, read: list<float>, write: list<float>, registeredWithinWeek: list<float>, registeredWithinMonth: list<float>, registeredWithinYear: list<float>, registeredOutsideWeek: list<float>, registeredOutsideMonth: list<float>, registeredOutsideYear: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/active-users")
  let body = {span: $span, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/ap-request
#
# GET /charts/ap-request
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/ap-request.ts — Source code
# operationId: get___charts___ap-request
export def "charts-ap-request ap-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
]: any -> record<deliverFailed: list<float>, deliverSucceeded: list<float>, inboxReceived: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/ap-request")
  let body = {span: $span, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/ap-request
#
# POST /charts/ap-request
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/ap-request.ts — Source code
# operationId: post___charts___ap-request
export def "charts-ap-request ap-request-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
]: any -> record<deliverFailed: list<float>, deliverSucceeded: list<float>, inboxReceived: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/ap-request")
  let body = {span: $span, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/drive
#
# GET /charts/drive
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/drive.ts — Source code
# operationId: get___charts___drive
export def "charts-drive drive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
]: any -> record<local: record<incCount: list<float>, incSize: list<float>, decCount: list<float>, decSize: list<float>>, remote: record<incCount: list<float>, incSize: list<float>, decCount: list<float>, decSize: list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/drive")
  let body = {span: $span, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/drive
#
# POST /charts/drive
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/drive.ts — Source code
# operationId: post___charts___drive
export def "charts-drive drive-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
]: any -> record<local: record<incCount: list<float>, incSize: list<float>, decCount: list<float>, decSize: list<float>>, remote: record<incCount: list<float>, incSize: list<float>, decCount: list<float>, decSize: list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/drive")
  let body = {span: $span, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/federation
#
# GET /charts/federation
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/federation.ts — Source code
# operationId: get___charts___federation
export def "charts-federation federation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
]: any -> record<deliveredInstances: list<float>, inboxInstances: list<float>, stalled: list<float>, sub: list<float>, pub: list<float>, pubsub: list<float>, subActive: list<float>, pubActive: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/federation")
  let body = {span: $span, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/federation
#
# POST /charts/federation
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/federation.ts — Source code
# operationId: post___charts___federation
export def "charts-federation federation-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
]: any -> record<deliveredInstances: list<float>, inboxInstances: list<float>, stalled: list<float>, sub: list<float>, pub: list<float>, pubsub: list<float>, subActive: list<float>, pubActive: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/federation")
  let body = {span: $span, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/instance
#
# GET /charts/instance
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/instance.ts — Source code
# operationId: get___charts___instance
export def "charts-instance instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
  host: string
]: any -> record<requests: record<failed: list<float>, succeeded: list<float>, received: list<float>>, notes: record<total: list<float>, inc: list<float>, dec: list<float>, diffs: record<normal: list, reply: list, renote: list, withFile: list>>, users: record<total: list<float>, inc: list<float>, dec: list<float>>, following: record<total: list<float>, inc: list<float>, dec: list<float>>, followers: record<total: list<float>, inc: list<float>, dec: list<float>>, drive: record<totalFiles: list<float>, incFiles: list<float>, decFiles: list<float>, incUsage: list<float>, decUsage: list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/instance")
  let body = {span: $span, limit: $limit, offset: $offset, host: $host} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/instance
#
# POST /charts/instance
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/instance.ts — Source code
# operationId: post___charts___instance
export def "charts-instance instance-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
  host: string
]: any -> record<requests: record<failed: list<float>, succeeded: list<float>, received: list<float>>, notes: record<total: list<float>, inc: list<float>, dec: list<float>, diffs: record<normal: list, reply: list, renote: list, withFile: list>>, users: record<total: list<float>, inc: list<float>, dec: list<float>>, following: record<total: list<float>, inc: list<float>, dec: list<float>>, followers: record<total: list<float>, inc: list<float>, dec: list<float>>, drive: record<totalFiles: list<float>, incFiles: list<float>, decFiles: list<float>, incUsage: list<float>, decUsage: list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/instance")
  let body = {span: $span, limit: $limit, offset: $offset, host: $host} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/notes
#
# GET /charts/notes
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/notes.ts — Source code
# operationId: get___charts___notes
export def "charts-notes notes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
]: any -> record<local: record<total: list<float>, inc: list<float>, dec: list<float>, diffs: record<normal: list, reply: list, renote: list, withFile: list>>, remote: record<total: list<float>, inc: list<float>, dec: list<float>, diffs: record<normal: list, reply: list, renote: list, withFile: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/notes")
  let body = {span: $span, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/notes
#
# POST /charts/notes
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/notes.ts — Source code
# operationId: post___charts___notes
export def "charts-notes notes-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
]: any -> record<local: record<total: list<float>, inc: list<float>, dec: list<float>, diffs: record<normal: list, reply: list, renote: list, withFile: list>>, remote: record<total: list<float>, inc: list<float>, dec: list<float>, diffs: record<normal: list, reply: list, renote: list, withFile: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/notes")
  let body = {span: $span, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/user/drive
#
# GET /charts/user/drive
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/user/drive.ts — Source code
# operationId: get___charts___user___drive
export def "charts-user-drive drive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
  userId: string # format: misskey:id
]: any -> record<totalCount: list<float>, totalSize: list<float>, incCount: list<float>, incSize: list<float>, decCount: list<float>, decSize: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/user/drive")
  let body = {span: $span, limit: $limit, offset: $offset, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/user/drive
#
# POST /charts/user/drive
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/user/drive.ts — Source code
# operationId: post___charts___user___drive
export def "charts-user-drive drive-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
  userId: string # format: misskey:id
]: any -> record<totalCount: list<float>, totalSize: list<float>, incCount: list<float>, incSize: list<float>, decCount: list<float>, decSize: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/user/drive")
  let body = {span: $span, limit: $limit, offset: $offset, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/user/following
#
# GET /charts/user/following
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/user/following.ts — Source code
# operationId: get___charts___user___following
export def "charts-user-following following" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
  userId: string # format: misskey:id
]: any -> record<local: record<followings: record<total: list, inc: list, dec: list>, followers: record<total: list, inc: list, dec: list>>, remote: record<followings: record<total: list, inc: list, dec: list>, followers: record<total: list, inc: list, dec: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/user/following")
  let body = {span: $span, limit: $limit, offset: $offset, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/user/following
#
# POST /charts/user/following
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/user/following.ts — Source code
# operationId: post___charts___user___following
export def "charts-user-following following-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
  userId: string # format: misskey:id
]: any -> record<local: record<followings: record<total: list, inc: list, dec: list>, followers: record<total: list, inc: list, dec: list>>, remote: record<followings: record<total: list, inc: list, dec: list>, followers: record<total: list, inc: list, dec: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/user/following")
  let body = {span: $span, limit: $limit, offset: $offset, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/user/notes
#
# GET /charts/user/notes
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/user/notes.ts — Source code
# operationId: get___charts___user___notes
export def "charts-user-notes notes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
  userId: string # format: misskey:id
]: any -> record<total: list<float>, inc: list<float>, dec: list<float>, diffs: record<normal: list<float>, reply: list<float>, renote: list<float>, withFile: list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/user/notes")
  let body = {span: $span, limit: $limit, offset: $offset, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/user/notes
#
# POST /charts/user/notes
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/user/notes.ts — Source code
# operationId: post___charts___user___notes
export def "charts-user-notes notes-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
  userId: string # format: misskey:id
]: any -> record<total: list<float>, inc: list<float>, dec: list<float>, diffs: record<normal: list<float>, reply: list<float>, renote: list<float>, withFile: list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/user/notes")
  let body = {span: $span, limit: $limit, offset: $offset, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/user/pv
#
# GET /charts/user/pv
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/user/pv.ts — Source code
# operationId: get___charts___user___pv
export def "charts-user-pv pv" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
  userId: string # format: misskey:id
]: any -> record<upv: record<user: list<float>, visitor: list<float>>, pv: record<user: list<float>, visitor: list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/user/pv")
  let body = {span: $span, limit: $limit, offset: $offset, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/user/pv
#
# POST /charts/user/pv
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/user/pv.ts — Source code
# operationId: post___charts___user___pv
export def "charts-user-pv pv-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
  userId: string # format: misskey:id
]: any -> record<upv: record<user: list<float>, visitor: list<float>>, pv: record<user: list<float>, visitor: list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/user/pv")
  let body = {span: $span, limit: $limit, offset: $offset, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/user/reactions
#
# GET /charts/user/reactions
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/user/reactions.ts — Source code
# operationId: get___charts___user___reactions
export def "charts-user-reactions reactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
  userId: string # format: misskey:id
]: any -> record<local: record<count: list<float>>, remote: record<count: list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/user/reactions")
  let body = {span: $span, limit: $limit, offset: $offset, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/user/reactions
#
# POST /charts/user/reactions
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/user/reactions.ts — Source code
# operationId: post___charts___user___reactions
export def "charts-user-reactions reactions-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
  userId: string # format: misskey:id
]: any -> record<local: record<count: list<float>>, remote: record<count: list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/user/reactions")
  let body = {span: $span, limit: $limit, offset: $offset, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/users
#
# GET /charts/users
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/users.ts — Source code
# operationId: get___charts___users
export def "charts-users users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
]: any -> record<local: record<total: list<float>, inc: list<float>, dec: list<float>>, remote: record<total: list<float>, inc: list<float>, dec: list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/users")
  let body = {span: $span, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# charts/users
#
# POST /charts/users
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/charts/users.ts — Source code
# operationId: post___charts___users
export def "charts-users users-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  span: string@span-completer
  --limit: int # default: 30
  --offset: int # nullable
]: any -> record<local: record<total: list<float>, inc: list<float>, dec: list<float>>, remote: record<total: list<float>, inc: list<float>, dec: list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charts/users")
  let body = {span: $span, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# clips/add-note
#
# POST /clips/add-note
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/clips/add-note.ts — Source code
# operationId: post___clips___add-note
export def "clips-add-note add-note" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  clipId: string # format: misskey:id
  noteId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clips/add-note")
  let body = {clipId: $clipId, noteId: $noteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# clips/create
#
# POST /clips/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/clips/create.ts — Source code
# operationId: post___clips___create
export def "clips-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --isPublic: oneof<nothing, bool> # default: false
  --description: string # nullable
]: any -> record<id: string, createdAt: string, lastClippedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list<record>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: list<record>>, name: string, description: string, isPublic: bool, favoritedCount: float, isFavorited: bool, notesCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clips/create")
  let body = {name: $name, isPublic: $isPublic, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# clips/delete
#
# POST /clips/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/clips/delete.ts — Source code
# operationId: post___clips___delete
export def "clips-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  clipId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clips/delete")
  let body = {clipId: $clipId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# clips/favorite
#
# POST /clips/favorite
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/clips/favorite.ts — Source code
# operationId: post___clips___favorite
export def "clips-favorite favorite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  clipId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clips/favorite")
  let body = {clipId: $clipId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# clips/list
#
# POST /clips/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/clips/list.ts — Source code
# operationId: post___clips___list
export def "clips-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, createdAt: string, lastClippedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, name: string, description: string, isPublic: bool, favoritedCount: float, isFavorited: bool, notesCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clips/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# clips/my-favorites
#
# POST /clips/my-favorites
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/clips/my-favorites.ts — Source code
# operationId: post___clips___my-favorites
export def "clips-my-favorites my-favorites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, createdAt: string, lastClippedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, name: string, description: string, isPublic: bool, favoritedCount: float, isFavorited: bool, notesCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clips/my-favorites")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# clips/notes
#
# POST /clips/notes
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/clips/notes.ts — Source code
# operationId: post___clips___notes
export def "clips-notes notes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  clipId: string # format: misskey:id
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clips/notes")
  let body = {clipId: $clipId, limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# clips/remove-note
#
# POST /clips/remove-note
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/clips/remove-note.ts — Source code
# operationId: post___clips___remove-note
export def "clips-remove-note remove-note" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  clipId: string # format: misskey:id
  noteId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clips/remove-note")
  let body = {clipId: $clipId, noteId: $noteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# clips/show
#
# POST /clips/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/clips/show.ts — Source code
# operationId: post___clips___show
export def "clips-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  clipId: string # format: misskey:id
]: any -> record<id: string, createdAt: string, lastClippedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list<record>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: list<record>>, name: string, description: string, isPublic: bool, favoritedCount: float, isFavorited: bool, notesCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clips/show")
  let body = {clipId: $clipId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# clips/unfavorite
#
# POST /clips/unfavorite
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/clips/unfavorite.ts — Source code
# operationId: post___clips___unfavorite
export def "clips-unfavorite unfavorite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  clipId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clips/unfavorite")
  let body = {clipId: $clipId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# clips/update
#
# POST /clips/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/clips/update.ts — Source code
# operationId: post___clips___update
export def "clips-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  clipId: string # format: misskey:id
  --name: string
  --isPublic: oneof<nothing, bool>
  --description: string # nullable
]: any -> record<id: string, createdAt: string, lastClippedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list<record>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: list<record>>, name: string, description: string, isPublic: bool, favoritedCount: float, isFavorited: bool, notesCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clips/update")
  let body = {clipId: $clipId, name: $name, isPublic: $isPublic, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# drive
#
# POST /drive
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive.ts — Source code
# operationId: post___drive
export def "drive drive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<capacity: float, usage: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# drive/files
#
# POST /drive/files
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive/files.ts — Source code
# operationId: post___drive___files
export def "drive-files files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --folderId: string # nullable, format: misskey:id
  --type: string # nullable
  --body-sort: string@sort-completer-3 # nullable
]: any -> table<id: string, createdAt: string, name: string, type: string, md5: string, size: float, isSensitive: bool, isSensitiveByModerator: bool, blurhash: string, properties: record<width: float, height: float, orientation: float, avgColor: string>, url: string, thumbnailUrl: string, comment: string, folderId: string, folder: record, userId: string, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive/files")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId, folderId: $folderId, type: $type, sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# drive/files/attached-notes
#
# POST /drive/files/attached-notes
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive/files/attached-notes.ts — Source code
# operationId: post___drive___files___attached-notes
export def "drive-files-attached-notes attached-notes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --limit: int # default: 10
  fileId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive/files/attached-notes")
  let body = {sinceId: $sinceId, untilId: $untilId, limit: $limit, fileId: $fileId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# drive/files/check-existence
#
# POST /drive/files/check-existence
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive/files/check-existence.ts — Source code
# operationId: post___drive___files___check-existence
export def "drive-files-check-existence check-existence" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  md5: string
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive/files/check-existence")
  let body = {md5: $md5} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# drive/files/create
#
# POST /drive/files/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive/files/create.ts — Source code
# operationId: post___drive___files___create
export def "drive-files-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --folderId: string # nullable, format: misskey:id
  --name: string # nullable
  --comment: string # nullable
  --isSensitive: oneof<nothing, bool> # default: false
  --force: oneof<nothing, bool> # default: false
  file: string # The file contents. (format: binary)
]: any -> record<id: string, createdAt: string, name: string, type: string, md5: string, size: float, isSensitive: bool, isSensitiveByModerator: bool, blurhash: string, properties: record<width: float, height: float, orientation: float, avgColor: string>, url: string, thumbnailUrl: string, comment: string, folderId: string, folder: record, userId: string, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive/files/create")
  let body = {folderId: $folderId, name: $name, comment: $comment, isSensitive: $isSensitive, force: $force, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# drive/files/delete
#
# POST /drive/files/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive/files/delete.ts — Source code
# operationId: post___drive___files___delete
export def "drive-files-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  fileId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive/files/delete")
  let body = {fileId: $fileId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# drive/files/find
#
# POST /drive/files/find
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive/files/find.ts — Source code
# operationId: post___drive___files___find
export def "drive-files-find find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --folderId: string # nullable, format: misskey:id
]: any -> table<id: string, createdAt: string, name: string, type: string, md5: string, size: float, isSensitive: bool, isSensitiveByModerator: bool, blurhash: string, properties: record<width: float, height: float, orientation: float, avgColor: string>, url: string, thumbnailUrl: string, comment: string, folderId: string, folder: record, userId: string, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive/files/find")
  let body = {name: $name, folderId: $folderId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# drive/files/find-by-hash
#
# POST /drive/files/find-by-hash
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive/files/find-by-hash.ts — Source code
# operationId: post___drive___files___find-by-hash
export def "drive-files-find-by-hash find-by-hash" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  md5: string
]: any -> table<id: string, createdAt: string, name: string, type: string, md5: string, size: float, isSensitive: bool, isSensitiveByModerator: bool, blurhash: string, properties: record<width: float, height: float, orientation: float, avgColor: string>, url: string, thumbnailUrl: string, comment: string, folderId: string, folder: record, userId: string, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive/files/find-by-hash")
  let body = {md5: $md5} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# drive/files/show
#
# POST /drive/files/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive/files/show.ts — Source code
# operationId: post___drive___files___show
export def "drive-files-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fileId: string # format: misskey:id
  --body-url: string
]: any -> record<id: string, createdAt: string, name: string, type: string, md5: string, size: float, isSensitive: bool, isSensitiveByModerator: bool, blurhash: string, properties: record<width: float, height: float, orientation: float, avgColor: string>, url: string, thumbnailUrl: string, comment: string, folderId: string, folder: record, userId: string, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive/files/show")
  let body = {fileId: $fileId, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# drive/files/update
#
# POST /drive/files/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive/files/update.ts — Source code
# operationId: post___drive___files___update
export def "drive-files-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  fileId: string # format: misskey:id
  --folderId: string # nullable, format: misskey:id
  --name: string
  --isSensitive: oneof<nothing, bool>
  --comment: string # nullable
]: any -> record<id: string, createdAt: string, name: string, type: string, md5: string, size: float, isSensitive: bool, isSensitiveByModerator: bool, blurhash: string, properties: record<width: float, height: float, orientation: float, avgColor: string>, url: string, thumbnailUrl: string, comment: string, folderId: string, folder: record, userId: string, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive/files/update")
  let body = {fileId: $fileId, folderId: $folderId, name: $name, isSensitive: $isSensitive, comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# drive/files/upload-from-url
#
# POST /drive/files/upload-from-url
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive/files/upload-from-url.ts — Source code
# operationId: post___drive___files___upload-from-url
export def "drive-files-upload-from-url upload-from-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string
  --folderId: string # nullable, format: misskey:id
  --isSensitive: oneof<nothing, bool> # default: false
  --comment: string # nullable
  --marker: string # nullable
  --force: oneof<nothing, bool> # default: false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive/files/upload-from-url")
  let body = {url: $body_url, folderId: $folderId, isSensitive: $isSensitive, comment: $comment, marker: $marker, force: $force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# drive/folders
#
# POST /drive/folders
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive/folders.ts — Source code
# operationId: post___drive___folders
export def "drive-folders folders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --folderId: string # nullable, format: misskey:id
]: any -> table<id: string, createdAt: string, name: string, parentId: string, foldersCount: float, filesCount: float, parent: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive/folders")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId, folderId: $folderId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# drive/folders/create
#
# POST /drive/folders/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive/folders/create.ts — Source code
# operationId: post___drive___folders___create
export def "drive-folders-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # default: Untitled
  --parentId: string # nullable, format: misskey:id
]: any -> record<id: string, createdAt: string, name: string, parentId: string, foldersCount: float, filesCount: float, parent: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive/folders/create")
  let body = {name: $name, parentId: $parentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# drive/folders/delete
#
# POST /drive/folders/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive/folders/delete.ts — Source code
# operationId: post___drive___folders___delete
export def "drive-folders-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  folderId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive/folders/delete")
  let body = {folderId: $folderId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# drive/folders/find
#
# POST /drive/folders/find
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive/folders/find.ts — Source code
# operationId: post___drive___folders___find
export def "drive-folders-find find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --parentId: string # nullable, format: misskey:id
]: any -> table<id: string, createdAt: string, name: string, parentId: string, foldersCount: float, filesCount: float, parent: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive/folders/find")
  let body = {name: $name, parentId: $parentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# drive/folders/show
#
# POST /drive/folders/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive/folders/show.ts — Source code
# operationId: post___drive___folders___show
export def "drive-folders-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  folderId: string # format: misskey:id
]: any -> record<id: string, createdAt: string, name: string, parentId: string, foldersCount: float, filesCount: float, parent: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive/folders/show")
  let body = {folderId: $folderId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# drive/folders/update
#
# POST /drive/folders/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive/folders/update.ts — Source code
# operationId: post___drive___folders___update
export def "drive-folders-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  folderId: string # format: misskey:id
  --name: string
  --parentId: string # nullable, format: misskey:id
]: any -> record<id: string, createdAt: string, name: string, parentId: string, foldersCount: float, filesCount: float, parent: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive/folders/update")
  let body = {folderId: $folderId, name: $name, parentId: $parentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# drive/stream
#
# POST /drive/stream
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/drive/stream.ts — Source code
# operationId: post___drive___stream
export def "drive-stream stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --type: string
]: any -> table<id: string, createdAt: string, name: string, type: string, md5: string, size: float, isSensitive: bool, isSensitiveByModerator: bool, blurhash: string, properties: record<width: float, height: float, orientation: float, avgColor: string>, url: string, thumbnailUrl: string, comment: string, folderId: string, folder: record, userId: string, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drive/stream")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# email-address/available
#
# POST /email-address/available
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/email-address/available.ts — Source code
# operationId: post___email-address___available
export def "email-address-available available" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  emailAddress: string
]: any -> record<available: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/email-address/available")
  let body = {emailAddress: $emailAddress} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# emoji
#
# GET /emoji
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/emoji.ts — Source code
# operationId: get___emoji
export def "emoji emoji" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<id: string, createdAt: string, updatedAt: string, aliases: list<string>, name: string, category: string, host: string, url: string, license: string, isSensitive: bool, localOnly: bool, requestedBy: string, memo: string, roleIdsThatCanBeUsedThisEmojiAsReaction: list<string>, roleIdsThatCanNotBeUsedThisEmojiAsReaction: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/emoji")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# emoji
#
# POST /emoji
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/emoji.ts — Source code
# operationId: post___emoji
export def "emoji emoji-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<id: string, createdAt: string, updatedAt: string, aliases: list<string>, name: string, category: string, host: string, url: string, license: string, isSensitive: bool, localOnly: bool, requestedBy: string, memo: string, roleIdsThatCanBeUsedThisEmojiAsReaction: list<string>, roleIdsThatCanNotBeUsedThisEmojiAsReaction: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/emoji")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# emojis
#
# GET /emojis
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/emojis.ts — Source code
# operationId: get___emojis
export def "emojis emojis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<emojis: table<aliases: list, name: string, category: string, url: string, localOnly: bool, isSensitive: bool, roleIdsThatCanBeUsedThisEmojiAsReaction: list, roleIdsThatCanNotBeUsedThisEmojiAsReaction: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/emojis")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# emojis
#
# POST /emojis
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/emojis.ts — Source code
# operationId: post___emojis
export def "emojis emojis-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<emojis: table<aliases: list, name: string, category: string, url: string, localOnly: bool, isSensitive: bool, roleIdsThatCanBeUsedThisEmojiAsReaction: list, roleIdsThatCanNotBeUsedThisEmojiAsReaction: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/emojis")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# endpoint
#
# POST /endpoint
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/endpoint.ts — Source code
# operationId: post___endpoint
export def "endpoint endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  endpoint: string
]: any -> record<params: table<name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/endpoint")
  let body = {endpoint: $endpoint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# endpoints
#
# POST /endpoints
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/endpoints.ts — Source code
# operationId: post___endpoints
export def "endpoints endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/endpoints")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# export-custom-emojis
#
# POST /export-custom-emojis
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/export-custom-emojis.ts — Source code
# operationId: post___export-custom-emojis
export def "export-custom-emojis export-custom-emojis" [
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
  let full_url = (build-url $base "/export-custom-emojis")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# federation/followers
#
# POST /federation/followers
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/federation/followers.ts — Source code
# operationId: post___federation___followers
export def "federation-followers followers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  host: string
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --limit: int # default: 10
]: any -> table<id: string, createdAt: string, followeeId: string, followerId: string, followee: record, follower: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/federation/followers")
  let body = {host: $host, sinceId: $sinceId, untilId: $untilId, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# federation/following
#
# POST /federation/following
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/federation/following.ts — Source code
# operationId: post___federation___following
export def "federation-following following" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  host: string
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --limit: int # default: 10
]: any -> table<id: string, createdAt: string, followeeId: string, followerId: string, followee: record, follower: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/federation/following")
  let body = {host: $host, sinceId: $sinceId, untilId: $untilId, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# federation/instances
#
# GET /federation/instances
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/federation/instances.ts — Source code
# operationId: get___federation___instances
export def "federation-instances instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --host: string # Omit or use `null` to not filter by host. (nullable)
  --blocked: oneof<nothing, bool> # nullable
  --notResponding: oneof<nothing, bool> # nullable
  --suspended: oneof<nothing, bool> # nullable
  --silenced: oneof<nothing, bool> # nullable
  --federating: oneof<nothing, bool> # nullable
  --subscribing: oneof<nothing, bool> # nullable
  --publishing: oneof<nothing, bool> # nullable
  --limit: int # default: 30
  --offset: int # default: 0
  --body-sort: string@sort-completer-4 # nullable
]: any -> table<id: string, firstRetrievedAt: string, host: string, usersCount: float, notesCount: float, followingCount: float, followersCount: float, isNotResponding: bool, isSuspended: bool, suspensionState: string, isBlocked: bool, softwareName: string, softwareVersion: string, openRegistrations: bool, name: string, description: string, maintainerName: string, maintainerEmail: string, isSilenced: bool, isSensitiveMedia: bool, iconUrl: string, faviconUrl: string, themeColor: string, infoUpdatedAt: string, latestRequestReceivedAt: string, moderationNote: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/federation/instances")
  let body = {host: $host, blocked: $blocked, notResponding: $notResponding, suspended: $suspended, silenced: $silenced, federating: $federating, subscribing: $subscribing, publishing: $publishing, limit: $limit, offset: $offset, sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# federation/instances
#
# POST /federation/instances
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/federation/instances.ts — Source code
# operationId: post___federation___instances
export def "federation-instances instances-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --host: string # Omit or use `null` to not filter by host. (nullable)
  --blocked: oneof<nothing, bool> # nullable
  --notResponding: oneof<nothing, bool> # nullable
  --suspended: oneof<nothing, bool> # nullable
  --silenced: oneof<nothing, bool> # nullable
  --federating: oneof<nothing, bool> # nullable
  --subscribing: oneof<nothing, bool> # nullable
  --publishing: oneof<nothing, bool> # nullable
  --limit: int # default: 30
  --offset: int # default: 0
  --body-sort: string@sort-completer-4 # nullable
]: any -> table<id: string, firstRetrievedAt: string, host: string, usersCount: float, notesCount: float, followingCount: float, followersCount: float, isNotResponding: bool, isSuspended: bool, suspensionState: string, isBlocked: bool, softwareName: string, softwareVersion: string, openRegistrations: bool, name: string, description: string, maintainerName: string, maintainerEmail: string, isSilenced: bool, isSensitiveMedia: bool, iconUrl: string, faviconUrl: string, themeColor: string, infoUpdatedAt: string, latestRequestReceivedAt: string, moderationNote: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/federation/instances")
  let body = {host: $host, blocked: $blocked, notResponding: $notResponding, suspended: $suspended, silenced: $silenced, federating: $federating, subscribing: $subscribing, publishing: $publishing, limit: $limit, offset: $offset, sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# federation/show-instance
#
# POST /federation/show-instance
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/federation/show-instance.ts — Source code
# operationId: post___federation___show-instance
export def "federation-show-instance show-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  host: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/federation/show-instance")
  let body = {host: $host} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# federation/stats
#
# GET /federation/stats
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/federation/stats.ts — Source code
# operationId: get___federation___stats
export def "federation-stats stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
]: any -> record<topSubInstances: table<id: string, firstRetrievedAt: string, host: string, usersCount: float, notesCount: float, followingCount: float, followersCount: float, isNotResponding: bool, isSuspended: bool, suspensionState: string, isBlocked: bool, softwareName: string, softwareVersion: string, openRegistrations: bool, name: string, description: string, maintainerName: string, maintainerEmail: string, isSilenced: bool, isSensitiveMedia: bool, iconUrl: string, faviconUrl: string, themeColor: string, infoUpdatedAt: string, latestRequestReceivedAt: string, moderationNote: string>, otherFollowersCount: float, topPubInstances: table<id: string, firstRetrievedAt: string, host: string, usersCount: float, notesCount: float, followingCount: float, followersCount: float, isNotResponding: bool, isSuspended: bool, suspensionState: string, isBlocked: bool, softwareName: string, softwareVersion: string, openRegistrations: bool, name: string, description: string, maintainerName: string, maintainerEmail: string, isSilenced: bool, isSensitiveMedia: bool, iconUrl: string, faviconUrl: string, themeColor: string, infoUpdatedAt: string, latestRequestReceivedAt: string, moderationNote: string>, otherFollowingCount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/federation/stats")
  let body = {limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# federation/stats
#
# POST /federation/stats
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/federation/stats.ts — Source code
# operationId: post___federation___stats
export def "federation-stats stats-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
]: any -> record<topSubInstances: table<id: string, firstRetrievedAt: string, host: string, usersCount: float, notesCount: float, followingCount: float, followersCount: float, isNotResponding: bool, isSuspended: bool, suspensionState: string, isBlocked: bool, softwareName: string, softwareVersion: string, openRegistrations: bool, name: string, description: string, maintainerName: string, maintainerEmail: string, isSilenced: bool, isSensitiveMedia: bool, iconUrl: string, faviconUrl: string, themeColor: string, infoUpdatedAt: string, latestRequestReceivedAt: string, moderationNote: string>, otherFollowersCount: float, topPubInstances: table<id: string, firstRetrievedAt: string, host: string, usersCount: float, notesCount: float, followingCount: float, followersCount: float, isNotResponding: bool, isSuspended: bool, suspensionState: string, isBlocked: bool, softwareName: string, softwareVersion: string, openRegistrations: bool, name: string, description: string, maintainerName: string, maintainerEmail: string, isSilenced: bool, isSensitiveMedia: bool, iconUrl: string, faviconUrl: string, themeColor: string, infoUpdatedAt: string, latestRequestReceivedAt: string, moderationNote: string>, otherFollowingCount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/federation/stats")
  let body = {limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# federation/update-remote-user
#
# POST /federation/update-remote-user
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/federation/update-remote-user.ts — Source code
# operationId: post___federation___update-remote-user
export def "federation-update-remote-user update-remote-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/federation/update-remote-user")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# federation/users
#
# POST /federation/users
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/federation/users.ts — Source code
# operationId: post___federation___users
export def "federation-users users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  host: string
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --limit: int # default: 10
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/federation/users")
  let body = {host: $host, sinceId: $sinceId, untilId: $untilId, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# fetch-external-resources
#
# POST /fetch-external-resources
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/fetch-external-resources.ts — Source code
# operationId: post___fetch-external-resources
export def "fetch-external-resources fetch-external-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string
  hash: string
]: any -> record<type: string, data: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fetch-external-resources")
  let body = {url: $body_url, hash: $hash} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# fetch-rss
#
# GET /fetch-rss
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/fetch-rss.ts — Source code
# operationId: get___fetch-rss
export def "fetch-rss fetch-rss" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string
]: any -> record<image: record<link: string, url: string, title: string>, paginationLinks: record<self: string, first: string, next: string, last: string, prev: string>, link: string, title: string, items: table<link: string, guid: string, title: string, pubDate: string, creator: string, summary: string, content: string, isoDate: string, categories: list, contentSnippet: string, enclosure: record>, feedUrl: string, description: string, itunes: record<image: string, owner: record<name: string, email: string>, author: string, summary: string, explicit: string, categories: list<string>, keywords: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fetch-rss")
  let body = {url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# fetch-rss
#
# POST /fetch-rss
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/fetch-rss.ts — Source code
# operationId: post___fetch-rss
export def "fetch-rss fetch-rss-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string
]: any -> record<image: record<link: string, url: string, title: string>, paginationLinks: record<self: string, first: string, next: string, last: string, prev: string>, link: string, title: string, items: table<link: string, guid: string, title: string, pubDate: string, creator: string, summary: string, content: string, isoDate: string, categories: list, contentSnippet: string, enclosure: record>, feedUrl: string, description: string, itunes: record<image: string, owner: record<name: string, email: string>, author: string, summary: string, explicit: string, categories: list<string>, keywords: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fetch-rss")
  let body = {url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# flash/create
#
# POST /flash/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/flash/create.ts — Source code
# operationId: post___flash___create
export def "flash-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string
  summary: string
  script: string
  permissions: list
  --visibility: string@visibility-completer # default: public
]: any -> record<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list<record>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: list<record>>, title: string, summary: string, script: string, visibility: string, likedCount: float, isLiked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/flash/create")
  let body = {title: $title, summary: $summary, script: $script, permissions: $permissions, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# flash/delete
#
# POST /flash/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/flash/delete.ts — Source code
# operationId: post___flash___delete
export def "flash-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  flashId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/flash/delete")
  let body = {flashId: $flashId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# flash/featured
#
# POST /flash/featured
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/flash/featured.ts — Source code
# operationId: post___flash___featured
export def "flash-featured featured" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # default: 0
  --limit: int # default: 10
]: any -> table<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, title: string, summary: string, script: string, visibility: string, likedCount: float, isLiked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/flash/featured")
  let body = {offset: $offset, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# flash/like
#
# POST /flash/like
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/flash/like.ts — Source code
# operationId: post___flash___like
export def "flash-like like" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  flashId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/flash/like")
  let body = {flashId: $flashId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# flash/my
#
# POST /flash/my
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/flash/my.ts — Source code
# operationId: post___flash___my
export def "flash-my my" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, title: string, summary: string, script: string, visibility: string, likedCount: float, isLiked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/flash/my")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# flash/my-likes
#
# POST /flash/my-likes
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/flash/my-likes.ts — Source code
# operationId: post___flash___my-likes
export def "flash-my-likes my-likes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, flash: record<id: string, createdAt: string, updatedAt: string, userId: string, user: record, title: string, summary: string, script: string, visibility: string, likedCount: float, isLiked: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/flash/my-likes")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# flash/show
#
# POST /flash/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/flash/show.ts — Source code
# operationId: post___flash___show
export def "flash-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  flashId: string # format: misskey:id
]: any -> record<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list<record>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: list<record>>, title: string, summary: string, script: string, visibility: string, likedCount: float, isLiked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/flash/show")
  let body = {flashId: $flashId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# flash/unlike
#
# POST /flash/unlike
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/flash/unlike.ts — Source code
# operationId: post___flash___unlike
export def "flash-unlike unlike" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  flashId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/flash/unlike")
  let body = {flashId: $flashId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# flash/update
#
# POST /flash/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/flash/update.ts — Source code
# operationId: post___flash___update
export def "flash-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  flashId: string # format: misskey:id
  --title: string
  --summary: string
  --script: string
  --permissions: list
  --visibility: string@visibility-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/flash/update")
  let body = {flashId: $flashId, title: $title, summary: $summary, script: $script, permissions: $permissions, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# following/create
#
# POST /following/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/following/create.ts — Source code
# operationId: post___following___create
export def "following-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
  --withReplies: oneof<nothing, bool>
]: any -> record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: table<id: string, angle: float, flipH: bool, url: string, offsetX: float, offsetY: float>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: table<name: string, iconUrl: string, displayOrder: float, behavior: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/following/create")
  let body = {userId: $userId, withReplies: $withReplies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# following/delete
#
# POST /following/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/following/delete.ts — Source code
# operationId: post___following___delete
export def "following-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: table<id: string, angle: float, flipH: bool, url: string, offsetX: float, offsetY: float>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: table<name: string, iconUrl: string, displayOrder: float, behavior: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/following/delete")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# following/invalidate
#
# POST /following/invalidate
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/following/invalidate.ts — Source code
# operationId: post___following___invalidate
export def "following-invalidate invalidate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: table<id: string, angle: float, flipH: bool, url: string, offsetX: float, offsetY: float>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: table<name: string, iconUrl: string, displayOrder: float, behavior: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/following/invalidate")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# following/requests/accept
#
# POST /following/requests/accept
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/following/requests/accept.ts — Source code
# operationId: post___following___requests___accept
export def "following-requests-accept accept" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/following/requests/accept")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# following/requests/cancel
#
# POST /following/requests/cancel
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/following/requests/cancel.ts — Source code
# operationId: post___following___requests___cancel
export def "following-requests-cancel cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: table<id: string, angle: float, flipH: bool, url: string, offsetX: float, offsetY: float>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: table<name: string, iconUrl: string, displayOrder: float, behavior: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/following/requests/cancel")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# following/requests/list
#
# POST /following/requests/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/following/requests/list.ts — Source code
# operationId: post___following___requests___list
export def "following-requests-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --limit: int # default: 10
]: any -> table<id: string, follower: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, followee: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/following/requests/list")
  let body = {sinceId: $sinceId, untilId: $untilId, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# following/requests/reject
#
# POST /following/requests/reject
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/following/requests/reject.ts — Source code
# operationId: post___following___requests___reject
export def "following-requests-reject reject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/following/requests/reject")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# following/requests/sent
#
# POST /following/requests/sent
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/following/requests/sent.ts — Source code
# operationId: post___following___requests___sent
export def "following-requests-sent sent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --limit: int # default: 10
]: any -> table<id: string, follower: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, followee: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/following/requests/sent")
  let body = {sinceId: $sinceId, untilId: $untilId, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# following/update
#
# POST /following/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/following/update.ts — Source code
# operationId: post___following___update
export def "following-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
  --notify: string@notify-completer
  --withReplies: oneof<nothing, bool>
]: any -> record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: table<id: string, angle: float, flipH: bool, url: string, offsetX: float, offsetY: float>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: table<name: string, iconUrl: string, displayOrder: float, behavior: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/following/update")
  let body = {userId: $userId, notify: $notify, withReplies: $withReplies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# following/update-all
#
# POST /following/update-all
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/following/update-all.ts — Source code
# operationId: post___following___update-all
export def "following-update-all update-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify: string@notify-completer
  --withReplies: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/following/update-all")
  let body = {notify: $notify, withReplies: $withReplies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# gallery/featured
#
# POST /gallery/featured
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/gallery/featured.ts — Source code
# operationId: post___gallery___featured
export def "gallery-featured featured" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, title: string, description: string, fileIds: list<string>, files: list<record>, tags: list<string>, isSensitive: bool, likedCount: float, isLiked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gallery/featured")
  let body = {limit: $limit, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# gallery/popular
#
# POST /gallery/popular
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/gallery/popular.ts — Source code
# operationId: post___gallery___popular
export def "gallery-popular popular" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, title: string, description: string, fileIds: list<string>, files: list<record>, tags: list<string>, isSensitive: bool, likedCount: float, isLiked: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gallery/popular")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# gallery/posts
#
# POST /gallery/posts
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/gallery/posts.ts — Source code
# operationId: post___gallery___posts
export def "gallery-posts posts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, title: string, description: string, fileIds: list<string>, files: list<record>, tags: list<string>, isSensitive: bool, likedCount: float, isLiked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gallery/posts")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# gallery/posts/create
#
# POST /gallery/posts/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/gallery/posts/create.ts — Source code
# operationId: post___gallery___posts___create
export def "gallery-posts-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string
  --description: string # nullable
  fileIds: list
  --isSensitive: oneof<nothing, bool> # default: false
]: any -> record<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list<record>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: list<record>>, title: string, description: string, fileIds: list<string>, files: table<id: string, createdAt: string, name: string, type: string, md5: string, size: float, isSensitive: bool, isSensitiveByModerator: bool, blurhash: string, properties: record, url: string, thumbnailUrl: string, comment: string, folderId: string, folder: record, userId: string, user: record>, tags: list<string>, isSensitive: bool, likedCount: float, isLiked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gallery/posts/create")
  let body = {title: $title, description: $description, fileIds: $fileIds, isSensitive: $isSensitive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# gallery/posts/delete
#
# POST /gallery/posts/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/gallery/posts/delete.ts — Source code
# operationId: post___gallery___posts___delete
export def "gallery-posts-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  postId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gallery/posts/delete")
  let body = {postId: $postId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# gallery/posts/like
#
# POST /gallery/posts/like
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/gallery/posts/like.ts — Source code
# operationId: post___gallery___posts___like
export def "gallery-posts-like like" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  postId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gallery/posts/like")
  let body = {postId: $postId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# gallery/posts/show
#
# POST /gallery/posts/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/gallery/posts/show.ts — Source code
# operationId: post___gallery___posts___show
export def "gallery-posts-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  postId: string # format: misskey:id
]: any -> record<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list<record>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: list<record>>, title: string, description: string, fileIds: list<string>, files: table<id: string, createdAt: string, name: string, type: string, md5: string, size: float, isSensitive: bool, isSensitiveByModerator: bool, blurhash: string, properties: record, url: string, thumbnailUrl: string, comment: string, folderId: string, folder: record, userId: string, user: record>, tags: list<string>, isSensitive: bool, likedCount: float, isLiked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gallery/posts/show")
  let body = {postId: $postId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# gallery/posts/unlike
#
# POST /gallery/posts/unlike
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/gallery/posts/unlike.ts — Source code
# operationId: post___gallery___posts___unlike
export def "gallery-posts-unlike unlike" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  postId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gallery/posts/unlike")
  let body = {postId: $postId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# gallery/posts/update
#
# POST /gallery/posts/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/gallery/posts/update.ts — Source code
# operationId: post___gallery___posts___update
export def "gallery-posts-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  postId: string # format: misskey:id
  --title: string
  --description: string # nullable
  --fileIds: list
  --isSensitive: oneof<nothing, bool> # default: false
]: any -> record<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list<record>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: list<record>>, title: string, description: string, fileIds: list<string>, files: table<id: string, createdAt: string, name: string, type: string, md5: string, size: float, isSensitive: bool, isSensitiveByModerator: bool, blurhash: string, properties: record, url: string, thumbnailUrl: string, comment: string, folderId: string, folder: record, userId: string, user: record>, tags: list<string>, isSensitive: bool, likedCount: float, isLiked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gallery/posts/update")
  let body = {postId: $postId, title: $title, description: $description, fileIds: $fileIds, isSensitive: $isSensitive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# get-avatar-decorations
#
# POST /get-avatar-decorations
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/get-avatar-decorations.ts — Source code
# operationId: post___get-avatar-decorations
export def "get-avatar-decorations get-avatar-decorations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, description: string, url: string, roleIdsThatCanBeUsedThisDecoration: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/get-avatar-decorations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get-online-users-count
#
# GET /get-online-users-count
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/get-online-users-count.ts — Source code
# operationId: get___get-online-users-count
export def "get-online-users-count get-online-users-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/get-online-users-count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get-online-users-count
#
# POST /get-online-users-count
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/get-online-users-count.ts — Source code
# operationId: post___get-online-users-count
export def "get-online-users-count get-online-users-count-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/get-online-users-count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# hashtags/list
#
# POST /hashtags/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/hashtags/list.ts — Source code
# operationId: post___hashtags___list
export def "hashtags-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --attachedToUserOnly: oneof<nothing, bool> # default: false
  --attachedToLocalUserOnly: oneof<nothing, bool> # default: false
  --attachedToRemoteUserOnly: oneof<nothing, bool> # default: false
  --body-sort: string@sort-completer-5
]: any -> table<tag: string, mentionedUsersCount: float, mentionedLocalUsersCount: float, mentionedRemoteUsersCount: float, attachedUsersCount: float, attachedLocalUsersCount: float, attachedRemoteUsersCount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hashtags/list")
  let body = {limit: $limit, attachedToUserOnly: $attachedToUserOnly, attachedToLocalUserOnly: $attachedToLocalUserOnly, attachedToRemoteUserOnly: $attachedToRemoteUserOnly, sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# hashtags/search
#
# POST /hashtags/search
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/hashtags/search.ts — Source code
# operationId: post___hashtags___search
export def "hashtags-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --body-query: string
  --offset: int # default: 0
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hashtags/search")
  let body = {limit: $limit, query: $body_query, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# hashtags/show
#
# POST /hashtags/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/hashtags/show.ts — Source code
# operationId: post___hashtags___show
export def "hashtags-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  tag: string
]: any -> record<tag: string, mentionedUsersCount: float, mentionedLocalUsersCount: float, mentionedRemoteUsersCount: float, attachedUsersCount: float, attachedLocalUsersCount: float, attachedRemoteUsersCount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hashtags/show")
  let body = {tag: $tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# hashtags/trend
#
# GET /hashtags/trend
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/hashtags/trend.ts — Source code
# operationId: get___hashtags___trend
export def "hashtags-trend trend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<tag: string, chart: list<float>, usersCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hashtags/trend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# hashtags/trend
#
# POST /hashtags/trend
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/hashtags/trend.ts — Source code
# operationId: post___hashtags___trend
export def "hashtags-trend trend-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<tag: string, chart: list<float>, usersCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hashtags/trend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# hashtags/users
#
# POST /hashtags/users
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/hashtags/users.ts — Source code
# operationId: post___hashtags___users
export def "hashtags-users users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  tag: string
  --limit: int # default: 10
  --body-sort: string@sort-completer-6
  --state: string@state-completer-2 # default: all
  --origin: string@origin-completer # default: local
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hashtags/users")
  let body = {tag: $tag, limit: $limit, sort: $body_sort, state: $state, origin: $origin, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i
#
# POST /i
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i.ts — Source code
# operationId: post___i
export def "i i" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# i/2fa/done
#
# POST /i/2fa/done
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/2fa/done.ts — Source code
# operationId: post___i___2fa___done
export def "i-2fa-done done" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string
]: any -> record<backupCodes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/2fa/done")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/2fa/key-done
#
# POST /i/2fa/key-done
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/2fa/key-done.ts — Source code
# operationId: post___i___2fa___key-done
export def "i-2fa-key-done key-done" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string
  --body-token: string # nullable
  name: string
  credential: record
]: any -> record<id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/2fa/key-done")
  let body = {password: $password, token: $body_token, name: $name, credential: $credential} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/2fa/password-less
#
# POST /i/2fa/password-less
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/2fa/password-less.ts — Source code
# operationId: post___i___2fa___password-less
export def "i-2fa-password-less password-less" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/2fa/password-less")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/2fa/register
#
# POST /i/2fa/register
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/2fa/register.ts — Source code
# operationId: post___i___2fa___register
export def "i-2fa-register register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string
  --body-token: string # nullable
]: any -> record<qr: string, url: string, secret: string, label: string, issuer: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/2fa/register")
  let body = {password: $password, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/2fa/register-key
#
# POST /i/2fa/register-key
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/2fa/register-key.ts — Source code
# operationId: post___i___2fa___register-key
export def "i-2fa-register-key register-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string
  --body-token: string # nullable
]: any -> record<rp: record<id: string>, user: record<id: string, name: string, displayName: string>, challenge: string, pubKeyCredParams: table<type: string, alg: float>, timeout: float, excludeCredentials: table<id: string, type: string, transports: list>, authenticatorSelection: record<authenticatorAttachment: string, requireResidentKey: bool, userVerification: string>, attestation: string, extensions: record<appid: string, credProps: bool, hmacCreateSecret: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/2fa/register-key")
  let body = {password: $password, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/2fa/remove-key
#
# POST /i/2fa/remove-key
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/2fa/remove-key.ts — Source code
# operationId: post___i___2fa___remove-key
export def "i-2fa-remove-key remove-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string
  --body-token: string # nullable
  credentialId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/2fa/remove-key")
  let body = {password: $password, token: $body_token, credentialId: $credentialId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/2fa/unregister
#
# POST /i/2fa/unregister
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/2fa/unregister.ts — Source code
# operationId: post___i___2fa___unregister
export def "i-2fa-unregister unregister" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string
  --body-token: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/2fa/unregister")
  let body = {password: $password, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/2fa/update-key
#
# POST /i/2fa/update-key
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/2fa/update-key.ts — Source code
# operationId: post___i___2fa___update-key
export def "i-2fa-update-key update-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  credentialId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/2fa/update-key")
  let body = {name: $name, credentialId: $credentialId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/apps
#
# POST /i/apps
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/apps.ts — Source code
# operationId: post___i___apps
export def "i-apps apps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-sort: string@sort-completer-7
]: any -> table<id: string, name: string, createdAt: string, lastUsedAt: string, permission: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/apps")
  let body = {sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/authorized-apps
#
# POST /i/authorized-apps
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/authorized-apps.ts — Source code
# operationId: post___i___authorized-apps
export def "i-authorized-apps authorized-apps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int # default: 0
  --body-sort: string@sort-completer-8 # default: desc
]: any -> table<id: string, name: string, callbackUrl: string, permission: list<string>, isAuthorized: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/authorized-apps")
  let body = {limit: $limit, offset: $offset, sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/change-password
#
# POST /i/change-password
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/change-password.ts — Source code
# operationId: post___i___change-password
export def "i-change-password change-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  currentPassword: string
  newPassword: string
  --body-token: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/change-password")
  let body = {currentPassword: $currentPassword, newPassword: $newPassword, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/claim-achievement
#
# POST /i/claim-achievement
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/claim-achievement.ts — Source code
# operationId: post___i___claim-achievement
export def "i-claim-achievement claim-achievement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string@name-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/claim-achievement")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/delete-account
#
# POST /i/delete-account
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/delete-account.ts — Source code
# operationId: post___i___delete-account
export def "i-delete-account delete-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string
  --body-token: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/delete-account")
  let body = {password: $password, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/export-antennas
#
# POST /i/export-antennas
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/export-antennas.ts — Source code
# operationId: post___i___export-antennas
export def "i-export-antennas export-antennas" [
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
  let full_url = (build-url $base "/i/export-antennas")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# i/export-blocking
#
# POST /i/export-blocking
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/export-blocking.ts — Source code
# operationId: post___i___export-blocking
export def "i-export-blocking export-blocking" [
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
  let full_url = (build-url $base "/i/export-blocking")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# i/export-clips
#
# POST /i/export-clips
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/export-clips.ts — Source code
# operationId: post___i___export-clips
export def "i-export-clips export-clips" [
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
  let full_url = (build-url $base "/i/export-clips")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# i/export-favorites
#
# POST /i/export-favorites
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/export-favorites.ts — Source code
# operationId: post___i___export-favorites
export def "i-export-favorites export-favorites" [
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
  let full_url = (build-url $base "/i/export-favorites")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# i/export-following
#
# POST /i/export-following
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/export-following.ts — Source code
# operationId: post___i___export-following
export def "i-export-following export-following" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --excludeMuting: oneof<nothing, bool> # default: false
  --excludeInactive: oneof<nothing, bool> # default: false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/export-following")
  let body = {excludeMuting: $excludeMuting, excludeInactive: $excludeInactive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/export-mute
#
# POST /i/export-mute
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/export-mute.ts — Source code
# operationId: post___i___export-mute
export def "i-export-mute export-mute" [
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
  let full_url = (build-url $base "/i/export-mute")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# i/export-notes
#
# POST /i/export-notes
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/export-notes.ts — Source code
# operationId: post___i___export-notes
export def "i-export-notes export-notes" [
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
  let full_url = (build-url $base "/i/export-notes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# i/export-user-lists
#
# POST /i/export-user-lists
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/export-user-lists.ts — Source code
# operationId: post___i___export-user-lists
export def "i-export-user-lists export-user-lists" [
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
  let full_url = (build-url $base "/i/export-user-lists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# i/favorites
#
# POST /i/favorites
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/favorites.ts — Source code
# operationId: post___i___favorites
export def "i-favorites favorites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, note: record<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list, visibleUserIds: list, fileIds: list, files: list, tags: list, poll: record, emojis: record, channelId: string, channel: record, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list, clippedCount: float, myReaction: string>, noteId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/favorites")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/gallery/likes
#
# POST /i/gallery/likes
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/gallery/likes.ts — Source code
# operationId: post___i___gallery___likes
export def "i-gallery-likes likes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, post: record<id: string, createdAt: string, updatedAt: string, userId: string, user: record, title: string, description: string, fileIds: list, files: list, tags: list, isSensitive: bool, likedCount: float, isLiked: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/gallery/likes")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/gallery/posts
#
# POST /i/gallery/posts
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/gallery/posts.ts — Source code
# operationId: post___i___gallery___posts
export def "i-gallery-posts posts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, title: string, description: string, fileIds: list<string>, files: list<record>, tags: list<string>, isSensitive: bool, likedCount: float, isLiked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/gallery/posts")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/import-antennas
#
# POST /i/import-antennas
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/import-antennas.ts — Source code
# operationId: post___i___import-antennas
export def "i-import-antennas import-antennas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  fileId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/import-antennas")
  let body = {fileId: $fileId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/import-blocking
#
# POST /i/import-blocking
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/import-blocking.ts — Source code
# operationId: post___i___import-blocking
export def "i-import-blocking import-blocking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  fileId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/import-blocking")
  let body = {fileId: $fileId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/import-following
#
# POST /i/import-following
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/import-following.ts — Source code
# operationId: post___i___import-following
export def "i-import-following import-following" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  fileId: string # format: misskey:id
  --withReplies: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/import-following")
  let body = {fileId: $fileId, withReplies: $withReplies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/import-muting
#
# POST /i/import-muting
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/import-muting.ts — Source code
# operationId: post___i___import-muting
export def "i-import-muting import-muting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  fileId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/import-muting")
  let body = {fileId: $fileId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/import-user-lists
#
# POST /i/import-user-lists
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/import-user-lists.ts — Source code
# operationId: post___i___import-user-lists
export def "i-import-user-lists import-user-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  fileId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/import-user-lists")
  let body = {fileId: $fileId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/move
#
# POST /i/move
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/move.ts — Source code
# operationId: post___i___move
export def "i-move move" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  moveToAccount: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/move")
  let body = {moveToAccount: $moveToAccount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/notifications
#
# POST /i/notifications
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/notifications.ts — Source code
# operationId: post___i___notifications
export def "i-notifications notifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --markAsRead: oneof<nothing, bool> # default: true
  --includeTypes: list
  --excludeTypes: list
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/notifications")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId, markAsRead: $markAsRead, includeTypes: $includeTypes, excludeTypes: $excludeTypes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/notifications-grouped
#
# POST /i/notifications-grouped
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/notifications-grouped.ts — Source code
# operationId: post___i___notifications-grouped
export def "i-notifications-grouped notifications-grouped" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --markAsRead: oneof<nothing, bool> # default: true
  --includeTypes: list
  --excludeTypes: list
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/notifications-grouped")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId, markAsRead: $markAsRead, includeTypes: $includeTypes, excludeTypes: $excludeTypes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/page-likes
#
# POST /i/page-likes
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/page-likes.ts — Source code
# operationId: post___i___page-likes
export def "i-page-likes page-likes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, page: record<id: string, createdAt: string, updatedAt: string, userId: string, user: record, content: list, variables: list, title: string, name: string, summary: string, hideTitleWhenPinned: bool, alignCenter: bool, font: string, script: string, eyeCatchingImageId: string, eyeCatchingImage: record, attachedFiles: list, likedCount: float, isLiked: bool, visibility: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/page-likes")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/pages
#
# POST /i/pages
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/pages.ts — Source code
# operationId: post___i___pages
export def "i-pages pages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, content: list<record>, variables: list<record>, title: string, name: string, summary: string, hideTitleWhenPinned: bool, alignCenter: bool, font: string, script: string, eyeCatchingImageId: string, eyeCatchingImage: record, attachedFiles: list<record>, likedCount: float, isLiked: bool, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/pages")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/pin
#
# POST /i/pin
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/pin.ts — Source code
# operationId: post___i___pin
export def "i-pin pin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/pin")
  let body = {noteId: $noteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/purge-timeline-cache
#
# POST /i/purge-timeline-cache
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/purge-timeline-cache.ts — Source code
# operationId: post___i___purge-timeline-cache
export def "i-purge-timeline-cache purge-timeline-cache" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-6
  --listId: string # nullable, format: misskey:id
  --antennaId: string # nullable, format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/purge-timeline-cache")
  let body = {type: $type, listId: $listId, antennaId: $antennaId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/read-announcement
#
# POST /i/read-announcement
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/read-announcement.ts — Source code
# operationId: post___i___read-announcement
export def "i-read-announcement read-announcement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  announcementId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/read-announcement")
  let body = {announcementId: $announcementId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/regenerate-token
#
# POST /i/regenerate-token
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/regenerate-token.ts — Source code
# operationId: post___i___regenerate-token
export def "i-regenerate-token regenerate-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/regenerate-token")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/registry/get
#
# POST /i/registry/get
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/registry/get.ts — Source code
# operationId: post___i___registry___get
export def "i-registry-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string
  scope: list # default: []
  --domain: string # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/registry/get")
  let body = {key: $key, scope: $scope, domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/registry/get-all
#
# POST /i/registry/get-all
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/registry/get-all.ts — Source code
# operationId: post___i___registry___get-all
export def "i-registry-get-all get-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  scope: list # default: []
  --domain: string # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/registry/get-all")
  let body = {scope: $scope, domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/registry/get-detail
#
# POST /i/registry/get-detail
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/registry/get-detail.ts — Source code
# operationId: post___i___registry___get-detail
export def "i-registry-get-detail get-detail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string
  scope: list # default: []
  --domain: string # nullable
]: any -> record<updatedAt: string, value: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/registry/get-detail")
  let body = {key: $key, scope: $scope, domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/registry/keys
#
# POST /i/registry/keys
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/registry/keys.ts — Source code
# operationId: post___i___registry___keys
export def "i-registry-keys keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  scope: list # default: []
  --domain: string # nullable
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/registry/keys")
  let body = {scope: $scope, domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/registry/keys-with-type
#
# POST /i/registry/keys-with-type
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/registry/keys-with-type.ts — Source code
# operationId: post___i___registry___keys-with-type
export def "i-registry-keys-with-type keys-with-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  scope: list # default: []
  --domain: string # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/registry/keys-with-type")
  let body = {scope: $scope, domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/registry/remove
#
# POST /i/registry/remove
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/registry/remove.ts — Source code
# operationId: post___i___registry___remove
export def "i-registry-remove remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string
  scope: list # default: []
  --domain: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/registry/remove")
  let body = {key: $key, scope: $scope, domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/registry/scopes-with-domain
#
# POST /i/registry/scopes-with-domain
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/registry/scopes-with-domain.ts — Source code
# operationId: post___i___registry___scopes-with-domain
export def "i-registry-scopes-with-domain scopes-with-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<scopes: list<list>, domain: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/registry/scopes-with-domain")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# i/registry/set
#
# POST /i/registry/set
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/registry/set.ts — Source code
# operationId: post___i___registry___set
export def "i-registry-set set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string
  value: any
  scope: list # default: []
  --domain: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/registry/set")
  let body = {key: $key, value: $value, scope: $scope, domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/revoke-token
#
# POST /i/revoke-token
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/revoke-token.ts — Source code
# operationId: post___i___revoke-token
export def "i-revoke-token revoke-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tokenId: string # format: misskey:id
  --body-token: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/revoke-token")
  let body = {tokenId: $tokenId, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/signin-history
#
# POST /i/signin-history
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/signin-history.ts — Source code
# operationId: post___i___signin-history
export def "i-signin-history signin-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, ip: string, headers: record, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/signin-history")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/unpin
#
# POST /i/unpin
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/unpin.ts — Source code
# operationId: post___i___unpin
export def "i-unpin unpin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/unpin")
  let body = {noteId: $noteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/update
#
# POST /i/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/update.ts — Source code
# operationId: post___i___update
# --avatarDecorations item shape: {id: string, angle?: float, flipH?: bool, offsetX?: float, offsetY?: float}
# --fields item shape: {name: string, value: string}
# --notificationRecieveConfig shape: {note?: record, follow?: record, mention?: record, reply?: record, renote?: record, quote?: record, reaction?: record, pollEnded?: record, receiveFollowRequest?: record, followRequestAccepted?: record, roleAssigned?: record, chatRoomInvitationReceived?: record, achievementEarned?: record, app?: record, test?: record}
# --mutualLinkSections item shape: {name?: string, mutualLinks: list}
export def "i-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # nullable
  --description: string # nullable
  --followedMessage: string # nullable
  --location: string # nullable
  --birthday: string # nullable
  --lang: string@lang-completer # nullable
  --postingLang: string@postingLang-completer # nullable
  --viewingLangs: list
  --showMediaInAllLanguages: oneof<nothing, bool>
  --showHashtagsInAllLanguages: oneof<nothing, bool>
  --avatarId: string # nullable, format: misskey:id
  --avatarDecorations: list # item shape: {id: string, angle?: float, flipH?: bool, offsetX?: float, offsetY?: float}
  --bannerId: string # nullable, format: misskey:id
  --body-fields: list # item shape: {name: string, value: string}
  --isLocked: oneof<nothing, bool>
  --isExplorable: oneof<nothing, bool>
  --hideOnlineStatus: oneof<nothing, bool>
  --publicReactions: oneof<nothing, bool>
  --carefulBot: oneof<nothing, bool>
  --autoAcceptFollowed: oneof<nothing, bool>
  --noCrawle: oneof<nothing, bool>
  --preventAiLearning: oneof<nothing, bool>
  --requireSigninToViewContents: oneof<nothing, bool>
  --makeNotesFollowersOnlyBefore: int # nullable
  --makeNotesHiddenBefore: int # nullable
  --isBot: oneof<nothing, bool>
  --isCat: oneof<nothing, bool>
  --injectFeaturedNote: oneof<nothing, bool>
  --receiveAnnouncementEmail: oneof<nothing, bool>
  --alwaysMarkNsfw: oneof<nothing, bool>
  --autoSensitive: oneof<nothing, bool>
  --followingVisibility: string@followingVisibility-completer
  --followersVisibility: string@followersVisibility-completer
  --chatScope: string@chatScope-completer
  --pinnedPageId: string # nullable, format: misskey:id
  --mutedWords: list
  --mutedInstances: list
  --notificationRecieveConfig: record # shape: {note?: record, follow?: record, mention?: record, reply?: record, renote?: record, quote?: record, reaction?: record, pollEnded?: record, receiveFollowRequest?: record, followRequestAccepted?: record, roleAssigned?: record, chatRoomInvitationReceived?: record, achievementEarned?: record, app?: record, test?: record}
  --emailNotificationTypes: list
  --alsoKnownAs: list
  --mutualLinkSections: list # item shape: {name?: string, mutualLinks: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/update")
  let body = {name: $name, description: $description, followedMessage: $followedMessage, location: $location, birthday: $birthday, lang: $lang, postingLang: $postingLang, viewingLangs: $viewingLangs, showMediaInAllLanguages: $showMediaInAllLanguages, showHashtagsInAllLanguages: $showHashtagsInAllLanguages, avatarId: $avatarId, avatarDecorations: $avatarDecorations, bannerId: $bannerId, fields: $body_fields, isLocked: $isLocked, isExplorable: $isExplorable, hideOnlineStatus: $hideOnlineStatus, publicReactions: $publicReactions, carefulBot: $carefulBot, autoAcceptFollowed: $autoAcceptFollowed, noCrawle: $noCrawle, preventAiLearning: $preventAiLearning, requireSigninToViewContents: $requireSigninToViewContents, makeNotesFollowersOnlyBefore: $makeNotesFollowersOnlyBefore, makeNotesHiddenBefore: $makeNotesHiddenBefore, isBot: $isBot, isCat: $isCat, injectFeaturedNote: $injectFeaturedNote, receiveAnnouncementEmail: $receiveAnnouncementEmail, alwaysMarkNsfw: $alwaysMarkNsfw, autoSensitive: $autoSensitive, followingVisibility: $followingVisibility, followersVisibility: $followersVisibility, chatScope: $chatScope, pinnedPageId: $pinnedPageId, mutedWords: $mutedWords, mutedInstances: $mutedInstances, notificationRecieveConfig: $notificationRecieveConfig, emailNotificationTypes: $emailNotificationTypes, alsoKnownAs: $alsoKnownAs, mutualLinkSections: $mutualLinkSections} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/update-email
#
# POST /i/update-email
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/update-email.ts — Source code
# operationId: post___i___update-email
export def "i-update-email update-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string
  --email: string # nullable
  --body-token: string # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/update-email")
  let body = {password: $password, email: $email, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/webhooks/create
#
# POST /i/webhooks/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/webhooks/create.ts — Source code
# operationId: post___i___webhooks___create
export def "i-webhooks-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --body-url: string
  --secret: string # default: 
  on: list
]: any -> record<id: string, userId: string, name: string, on: list<string>, url: string, secret: string, active: bool, latestSentAt: string, latestStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/webhooks/create")
  let body = {name: $name, url: $body_url, secret: $secret, on: $on} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/webhooks/delete
#
# POST /i/webhooks/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/webhooks/delete.ts — Source code
# operationId: post___i___webhooks___delete
export def "i-webhooks-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  webhookId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/webhooks/delete")
  let body = {webhookId: $webhookId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/webhooks/list
#
# POST /i/webhooks/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/webhooks/list.ts — Source code
# operationId: post___i___webhooks___list
export def "i-webhooks-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, userId: string, name: string, on: list<string>, url: string, secret: string, active: bool, latestSentAt: string, latestStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/webhooks/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# i/webhooks/show
#
# POST /i/webhooks/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/webhooks/show.ts — Source code
# operationId: post___i___webhooks___show
export def "i-webhooks-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  webhookId: string # format: misskey:id
]: any -> record<id: string, userId: string, name: string, on: list<string>, url: string, secret: string, active: bool, latestSentAt: string, latestStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/webhooks/show")
  let body = {webhookId: $webhookId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/webhooks/test
#
# POST /i/webhooks/test
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/webhooks/test.ts — Source code
# operationId: post___i___webhooks___test
# --override shape: {url?: string, secret?: string}
export def "i-webhooks-test test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  webhookId: string # format: misskey:id
  type: string@type-completer-7
  --override: record # shape: {url?: string, secret?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/webhooks/test")
  let body = {webhookId: $webhookId, type: $type, override: $override} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# i/webhooks/update
#
# POST /i/webhooks/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/i/webhooks/update.ts — Source code
# operationId: post___i___webhooks___update
export def "i-webhooks-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  webhookId: string # format: misskey:id
  --name: string
  --body-url: string
  --secret: string # nullable
  --on: list
  --active: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/i/webhooks/update")
  let body = {webhookId: $webhookId, name: $name, url: $body_url, secret: $secret, on: $on, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# invite/create
#
# POST /invite/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/invite/create.ts — Source code
# operationId: post___invite___create
export def "invite-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, code: string, expiresAt: string, createdAt: string, createdBy: record, usedBy: record, usedAt: string, used: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invite/create")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# invite/delete
#
# POST /invite/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/invite/delete.ts — Source code
# operationId: post___invite___delete
export def "invite-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  inviteId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invite/delete")
  let body = {inviteId: $inviteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# invite/limit
#
# POST /invite/limit
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/invite/limit.ts — Source code
# operationId: post___invite___limit
export def "invite-limit limit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<remaining: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invite/limit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# invite/list
#
# POST /invite/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/invite/list.ts — Source code
# operationId: post___invite___list
export def "invite-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 30
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, code: string, expiresAt: string, createdAt: string, createdBy: record, usedBy: record, usedAt: string, used: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invite/list")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# meta
#
# GET /meta
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/meta.ts — Source code
# operationId: get___meta
export def "meta meta" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --detail: oneof<nothing, bool> # default: true
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/meta")
  let body = {detail: $detail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# meta
#
# POST /meta
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/meta.ts — Source code
# operationId: post___meta
export def "meta meta-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --detail: oneof<nothing, bool> # default: true
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/meta")
  let body = {detail: $detail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# miauth/gen-token
#
# POST /miauth/gen-token
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/miauth/gen-token.ts — Source code
# operationId: post___miauth___gen-token
export def "miauth-gen-token gen-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --session: string # nullable
  --name: string # nullable
  --description: string # nullable
  --iconUrl: string # nullable
  permission: list
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/miauth/gen-token")
  let body = {session: $session, name: $name, description: $description, iconUrl: $iconUrl, permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# mute/create
#
# POST /mute/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/mute/create.ts — Source code
# operationId: post___mute___create
export def "mute-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
  --expiresAt: int # A Unix Epoch timestamp that must lie in the future. `null` means an indefinite mute. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mute/create")
  let body = {userId: $userId, expiresAt: $expiresAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# mute/delete
#
# POST /mute/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/mute/delete.ts — Source code
# operationId: post___mute___delete
export def "mute-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mute/delete")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# mute/list
#
# POST /mute/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/mute/list.ts — Source code
# operationId: post___mute___list
export def "mute-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 30
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, expiresAt: string, muteeId: string, mutee: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mute/list")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# my/apps
#
# POST /my/apps
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/my/apps.ts — Source code
# operationId: post___my___apps
export def "my-apps apps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int # default: 0
]: any -> table<id: string, name: string, callbackUrl: string, permission: list<string>, secret: string, isAuthorized: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my/apps")
  let body = {limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes
#
# POST /notes
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes.ts — Source code
# operationId: post___notes
export def "notes notes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --local: oneof<nothing, bool> # default: false
  --reply: oneof<nothing, bool>
  --renote: oneof<nothing, bool>
  --withFiles: oneof<nothing, bool>
  --poll: oneof<nothing, bool>
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes")
  let body = {local: $local, reply: $reply, renote: $renote, withFiles: $withFiles, poll: $poll, limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/children
#
# POST /notes/children
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/children.ts — Source code
# operationId: post___notes___children
export def "notes-children children" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/children")
  let body = {noteId: $noteId, limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/clips
#
# POST /notes/clips
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/clips.ts — Source code
# operationId: post___notes___clips
export def "notes-clips clips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, lastClippedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, name: string, description: string, isPublic: bool, favoritedCount: float, isFavorited: bool, notesCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/clips")
  let body = {noteId: $noteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/conversation
#
# POST /notes/conversation
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/conversation.ts — Source code
# operationId: post___notes___conversation
export def "notes-conversation conversation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
  --limit: int # default: 10
  --offset: int # default: 0
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/conversation")
  let body = {noteId: $noteId, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/create
#
# POST /notes/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/create.ts — Source code
# operationId: post___notes___create
# --poll shape: {choices: list, multiple?: bool, expiresAt?: int, expiredAfter?: int}
export def "notes-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --visibility: string@visibility-completer-1 # default: public
  --visibleUserIds: list
  --cw: string # nullable
  --localOnly: oneof<nothing, bool> # default: false
  --dimension: int # nullable
  --reactionAcceptance: string@reactionAcceptance-completer # nullable
  --noExtractMentions: oneof<nothing, bool> # default: false
  --noExtractHashtags: oneof<nothing, bool> # default: false
  --noExtractEmojis: oneof<nothing, bool> # default: false
  --replyId: string # nullable, format: misskey:id
  --renoteId: string # nullable, format: misskey:id
  --channelId: string # nullable, format: misskey:id
  --lang: string@lang-completer-1 # nullable
  --text: string # nullable
  --fileIds: list
  --mediaIds: list
  --poll: record # nullable — shape: {choices: list, multiple?: bool, expiresAt?: int, expiredAfter?: int}
  --scheduledAt: int # nullable
  --noCreatedNote: oneof<nothing, bool> # default: false
]: any -> record<createdNote: record<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/create")
  let body = {visibility: $visibility, visibleUserIds: $visibleUserIds, cw: $cw, localOnly: $localOnly, dimension: $dimension, reactionAcceptance: $reactionAcceptance, noExtractMentions: $noExtractMentions, noExtractHashtags: $noExtractHashtags, noExtractEmojis: $noExtractEmojis, replyId: $replyId, renoteId: $renoteId, channelId: $channelId, lang: $lang, text: $text, fileIds: $fileIds, mediaIds: $mediaIds, poll: $poll, scheduledAt: $scheduledAt, noCreatedNote: $noCreatedNote} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/delete
#
# POST /notes/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/delete.ts — Source code
# operationId: post___notes___delete
export def "notes-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/delete")
  let body = {noteId: $noteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/favorites/create
#
# POST /notes/favorites/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/favorites/create.ts — Source code
# operationId: post___notes___favorites___create
export def "notes-favorites-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/favorites/create")
  let body = {noteId: $noteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/favorites/delete
#
# POST /notes/favorites/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/favorites/delete.ts — Source code
# operationId: post___notes___favorites___delete
export def "notes-favorites-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/favorites/delete")
  let body = {noteId: $noteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/featured
#
# GET /notes/featured
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/featured.ts — Source code
# operationId: get___notes___featured
export def "notes-featured featured" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --untilId: string # format: misskey:id
  --channelId: string # nullable, format: misskey:id
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/featured")
  let body = {limit: $limit, untilId: $untilId, channelId: $channelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/featured
#
# POST /notes/featured
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/featured.ts — Source code
# operationId: post___notes___featured
export def "notes-featured featured-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --untilId: string # format: misskey:id
  --channelId: string # nullable, format: misskey:id
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/featured")
  let body = {limit: $limit, untilId: $untilId, channelId: $channelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/global-timeline
#
# POST /notes/global-timeline
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/global-timeline.ts — Source code
# operationId: post___notes___global-timeline
export def "notes-global-timeline global-timeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --withFiles: oneof<nothing, bool> # default: false
  --withRenotes: oneof<nothing, bool> # default: true
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --sinceDate: int
  --untilDate: int
  --dimension: int # nullable
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/global-timeline")
  let body = {withFiles: $withFiles, withRenotes: $withRenotes, limit: $limit, sinceId: $sinceId, untilId: $untilId, sinceDate: $sinceDate, untilDate: $untilDate, dimension: $dimension} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/hybrid-timeline
#
# POST /notes/hybrid-timeline
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/hybrid-timeline.ts — Source code
# operationId: post___notes___hybrid-timeline
export def "notes-hybrid-timeline hybrid-timeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --sinceDate: int
  --untilDate: int
  --allowPartial: oneof<nothing, bool> # default: false
  --includeMyRenotes: oneof<nothing, bool> # default: true
  --includeRenotedMyNotes: oneof<nothing, bool> # default: true
  --includeLocalRenotes: oneof<nothing, bool> # default: true
  --withFiles: oneof<nothing, bool> # default: false
  --withRenotes: oneof<nothing, bool> # default: true
  --withReplies: oneof<nothing, bool> # default: false
  --dimension: int # nullable
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/hybrid-timeline")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId, sinceDate: $sinceDate, untilDate: $untilDate, allowPartial: $allowPartial, includeMyRenotes: $includeMyRenotes, includeRenotedMyNotes: $includeRenotedMyNotes, includeLocalRenotes: $includeLocalRenotes, withFiles: $withFiles, withRenotes: $withRenotes, withReplies: $withReplies, dimension: $dimension} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/local-timeline
#
# POST /notes/local-timeline
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/local-timeline.ts — Source code
# operationId: post___notes___local-timeline
export def "notes-local-timeline local-timeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --withFiles: oneof<nothing, bool> # default: false
  --withRenotes: oneof<nothing, bool> # default: true
  --withReplies: oneof<nothing, bool> # default: false
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --allowPartial: oneof<nothing, bool> # default: false
  --sinceDate: int
  --untilDate: int
  --dimension: int # nullable
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/local-timeline")
  let body = {withFiles: $withFiles, withRenotes: $withRenotes, withReplies: $withReplies, limit: $limit, sinceId: $sinceId, untilId: $untilId, allowPartial: $allowPartial, sinceDate: $sinceDate, untilDate: $untilDate, dimension: $dimension} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/mentions
#
# POST /notes/mentions
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/mentions.ts — Source code
# operationId: post___notes___mentions
export def "notes-mentions mentions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --following: oneof<nothing, bool> # default: false
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --visibility: string
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/mentions")
  let body = {following: $following, limit: $limit, sinceId: $sinceId, untilId: $untilId, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/polls/recommendation
#
# POST /notes/polls/recommendation
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/polls/recommendation.ts — Source code
# operationId: post___notes___polls___recommendation
export def "notes-polls-recommendation recommendation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int # default: 0
  --excludeChannels: oneof<nothing, bool> # default: false
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/polls/recommendation")
  let body = {limit: $limit, offset: $offset, excludeChannels: $excludeChannels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/polls/vote
#
# POST /notes/polls/vote
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/polls/vote.ts — Source code
# operationId: post___notes___polls___vote
export def "notes-polls-vote vote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
  choice: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/polls/vote")
  let body = {noteId: $noteId, choice: $choice} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/reactions
#
# GET /notes/reactions
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/reactions.ts — Source code
# operationId: get___notes___reactions
export def "notes-reactions reactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
  --type: string # nullable
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/reactions")
  let body = {noteId: $noteId, type: $type, limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/reactions
#
# POST /notes/reactions
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/reactions.ts — Source code
# operationId: post___notes___reactions
export def "notes-reactions reactions-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
  --type: string # nullable
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/reactions")
  let body = {noteId: $noteId, type: $type, limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/reactions/create
#
# POST /notes/reactions/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/reactions/create.ts — Source code
# operationId: post___notes___reactions___create
export def "notes-reactions-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
  reaction: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/reactions/create")
  let body = {noteId: $noteId, reaction: $reaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/reactions/delete
#
# POST /notes/reactions/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/reactions/delete.ts — Source code
# operationId: post___notes___reactions___delete
export def "notes-reactions-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/reactions/delete")
  let body = {noteId: $noteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/renotes
#
# POST /notes/renotes
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/renotes.ts — Source code
# operationId: post___notes___renotes
export def "notes-renotes renotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/renotes")
  let body = {noteId: $noteId, limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/replies
#
# POST /notes/replies
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/replies.ts — Source code
# operationId: post___notes___replies
export def "notes-replies replies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --limit: int # default: 10
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/replies")
  let body = {noteId: $noteId, sinceId: $sinceId, untilId: $untilId, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/scheduled/cancel
#
# POST /notes/scheduled/cancel
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/scheduled/cancel.ts — Source code
# operationId: post___notes___scheduled___cancel
export def "notes-scheduled-cancel cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  draftId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/scheduled/cancel")
  let body = {draftId: $draftId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/scheduled/list
#
# POST /notes/scheduled/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/scheduled/list.ts — Source code
# operationId: post___notes___scheduled___list
export def "notes-scheduled-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int # default: 0
]: any -> table<id: string, updatedAt: string, scheduledAt: string, reason: string, channel: record<id: string, name: string>, renote: record<id: string, text: string, user: record>, reply: record<id: string, text: string, user: record>, data: record<text: string, useCw: bool, cw: string, visibility: string, localOnly: bool, lang: string, dimension: int, files: list, poll: record, visibleUserIds: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/scheduled/list")
  let body = {limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/search
#
# POST /notes/search
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/search.ts — Source code
# operationId: post___notes___search
export def "notes-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-query: string
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --limit: int # default: 10
  --offset: int # default: 0
  --host: string # The local host is represented with `.`.
  --userId: string # nullable, format: misskey:id
  --channelId: string # nullable, format: misskey:id
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/search")
  let body = {query: $body_query, sinceId: $sinceId, untilId: $untilId, limit: $limit, offset: $offset, host: $host, userId: $userId, channelId: $channelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/search-by-tag
#
# POST /notes/search-by-tag
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/search-by-tag.ts — Source code
# operationId: post___notes___search-by-tag
export def "notes-search-by-tag search-by-tag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --local: oneof<nothing, bool> # nullable
  --reply: oneof<nothing, bool> # nullable
  --renote: oneof<nothing, bool> # nullable
  --withFiles: oneof<nothing, bool> # Only show notes that have attached files. (default: false)
  --poll: oneof<nothing, bool> # nullable
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --limit: int # default: 10
  --tag: string
  --body-query: list # The outer arrays are chained with OR, the inner arrays are chained with AND.
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/search-by-tag")
  let body = {local: $local, reply: $reply, renote: $renote, withFiles: $withFiles, poll: $poll, sinceId: $sinceId, untilId: $untilId, limit: $limit, tag: $tag, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/show
#
# POST /notes/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/show.ts — Source code
# operationId: post___notes___show
export def "notes-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
]: any -> record<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list<record>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: list<record>>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: table<id: string, createdAt: string, name: string, type: string, md5: string, size: float, isSensitive: bool, isSensitiveByModerator: bool, blurhash: string, properties: record, url: string, thumbnailUrl: string, comment: string, folderId: string, folder: record, userId: string, user: record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list<record>>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/show")
  let body = {noteId: $noteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/state
#
# POST /notes/state
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/state.ts — Source code
# operationId: post___notes___state
export def "notes-state state" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
]: any -> record<isFavorited: bool, isMutedThread: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/state")
  let body = {noteId: $noteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/thread-muting/create
#
# POST /notes/thread-muting/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/thread-muting/create.ts — Source code
# operationId: post___notes___thread-muting___create
export def "notes-thread-muting-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/thread-muting/create")
  let body = {noteId: $noteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/thread-muting/delete
#
# POST /notes/thread-muting/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/thread-muting/delete.ts — Source code
# operationId: post___notes___thread-muting___delete
export def "notes-thread-muting-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/thread-muting/delete")
  let body = {noteId: $noteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/timeline
#
# POST /notes/timeline
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/timeline.ts — Source code
# operationId: post___notes___timeline
export def "notes-timeline timeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --sinceDate: int
  --untilDate: int
  --allowPartial: oneof<nothing, bool> # default: false
  --includeMyRenotes: oneof<nothing, bool> # default: true
  --includeRenotedMyNotes: oneof<nothing, bool> # default: true
  --includeLocalRenotes: oneof<nothing, bool> # default: true
  --withFiles: oneof<nothing, bool> # default: false
  --withRenotes: oneof<nothing, bool> # default: true
  --dimension: int # nullable
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/timeline")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId, sinceDate: $sinceDate, untilDate: $untilDate, allowPartial: $allowPartial, includeMyRenotes: $includeMyRenotes, includeRenotedMyNotes: $includeRenotedMyNotes, includeLocalRenotes: $includeLocalRenotes, withFiles: $withFiles, withRenotes: $withRenotes, dimension: $dimension} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/translate
#
# POST /notes/translate
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/translate.ts — Source code
# operationId: post___notes___translate
export def "notes-translate translate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
  targetLang: string
]: any -> record<sourceLang: string, text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/translate")
  let body = {noteId: $noteId, targetLang: $targetLang} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/unrenote
#
# POST /notes/unrenote
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/unrenote.ts — Source code
# operationId: post___notes___unrenote
export def "notes-unrenote unrenote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/unrenote")
  let body = {noteId: $noteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notes/user-list-timeline
#
# POST /notes/user-list-timeline
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notes/user-list-timeline.ts — Source code
# operationId: post___notes___user-list-timeline
export def "notes-user-list-timeline user-list-timeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  listId: string # format: misskey:id
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --sinceDate: int
  --untilDate: int
  --allowPartial: oneof<nothing, bool> # default: false
  --includeMyRenotes: oneof<nothing, bool> # default: true
  --includeRenotedMyNotes: oneof<nothing, bool> # default: true
  --includeLocalRenotes: oneof<nothing, bool> # default: true
  --withRenotes: oneof<nothing, bool> # default: true
  --withFiles: oneof<nothing, bool> # Only show notes that have attached files. (default: false)
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes/user-list-timeline")
  let body = {listId: $listId, limit: $limit, sinceId: $sinceId, untilId: $untilId, sinceDate: $sinceDate, untilDate: $untilDate, allowPartial: $allowPartial, includeMyRenotes: $includeMyRenotes, includeRenotedMyNotes: $includeRenotedMyNotes, includeLocalRenotes: $includeLocalRenotes, withRenotes: $withRenotes, withFiles: $withFiles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notifications/create
#
# POST /notifications/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notifications/create.ts — Source code
# operationId: post___notifications___create
export def "notifications-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-body: string
  --header: string # nullable
  --icon: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/create")
  let body = {body: $body_body, header: $header, icon: $icon} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notifications/flush
#
# POST /notifications/flush
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notifications/flush.ts — Source code
# operationId: post___notifications___flush
export def "notifications-flush flush" [
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
  let full_url = (build-url $base "/notifications/flush")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# notifications/mark-all-as-read
#
# POST /notifications/mark-all-as-read
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notifications/mark-all-as-read.ts — Source code
# operationId: post___notifications___mark-all-as-read
export def "notifications-mark-all-as-read mark-all-as-read" [
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
  let full_url = (build-url $base "/notifications/mark-all-as-read")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# notifications/test-notification
#
# POST /notifications/test-notification
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/notifications/test-notification.ts — Source code
# operationId: post___notifications___test-notification
export def "notifications-test-notification test-notification" [
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
  let full_url = (build-url $base "/notifications/test-notification")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# page-push
#
# POST /page-push
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/page-push.ts — Source code
# operationId: post___page-push
export def "page-push page-push" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  pageId: string # format: misskey:id
  event: string
  --var: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/page-push")
  let body = {pageId: $pageId, event: $event, var: $var} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# pages/create
#
# POST /pages/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/pages/create.ts — Source code
# operationId: post___pages___create
export def "pages-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string
  name: string
  --summary: string # nullable
  content: list
  --body-variables: list
  script: string
  --eyeCatchingImageId: string # nullable, format: misskey:id
  --font: string@font-completer # default: sans-serif
  --alignCenter: oneof<nothing, bool> # default: false
  --hideTitleWhenPinned: oneof<nothing, bool> # default: false
  --visibility: string@visibility-completer
]: any -> record<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list<record>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: list<record>>, content: list<record>, variables: list<record>, title: string, name: string, summary: string, hideTitleWhenPinned: bool, alignCenter: bool, font: string, script: string, eyeCatchingImageId: string, eyeCatchingImage: record, attachedFiles: table<id: string, createdAt: string, name: string, type: string, md5: string, size: float, isSensitive: bool, isSensitiveByModerator: bool, blurhash: string, properties: record, url: string, thumbnailUrl: string, comment: string, folderId: string, folder: record, userId: string, user: record>, likedCount: float, isLiked: bool, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pages/create")
  let body = {title: $title, name: $name, summary: $summary, content: $content, variables: $body_variables, script: $script, eyeCatchingImageId: $eyeCatchingImageId, font: $font, alignCenter: $alignCenter, hideTitleWhenPinned: $hideTitleWhenPinned, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# pages/delete
#
# POST /pages/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/pages/delete.ts — Source code
# operationId: post___pages___delete
export def "pages-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  pageId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pages/delete")
  let body = {pageId: $pageId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# pages/featured
#
# POST /pages/featured
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/pages/featured.ts — Source code
# operationId: post___pages___featured
export def "pages-featured featured" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, content: list<record>, variables: list<record>, title: string, name: string, summary: string, hideTitleWhenPinned: bool, alignCenter: bool, font: string, script: string, eyeCatchingImageId: string, eyeCatchingImage: record, attachedFiles: list<record>, likedCount: float, isLiked: bool, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pages/featured")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# pages/like
#
# POST /pages/like
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/pages/like.ts — Source code
# operationId: post___pages___like
export def "pages-like like" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  pageId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pages/like")
  let body = {pageId: $pageId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# pages/show
#
# POST /pages/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/pages/show.ts — Source code
# operationId: post___pages___show
export def "pages-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageId: string # format: misskey:id
  --name: string
  --username: string
]: any -> record<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list<record>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: list<record>>, content: list<record>, variables: list<record>, title: string, name: string, summary: string, hideTitleWhenPinned: bool, alignCenter: bool, font: string, script: string, eyeCatchingImageId: string, eyeCatchingImage: record, attachedFiles: table<id: string, createdAt: string, name: string, type: string, md5: string, size: float, isSensitive: bool, isSensitiveByModerator: bool, blurhash: string, properties: record, url: string, thumbnailUrl: string, comment: string, folderId: string, folder: record, userId: string, user: record>, likedCount: float, isLiked: bool, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pages/show")
  let body = {pageId: $pageId, name: $name, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# pages/unlike
#
# POST /pages/unlike
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/pages/unlike.ts — Source code
# operationId: post___pages___unlike
export def "pages-unlike unlike" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  pageId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pages/unlike")
  let body = {pageId: $pageId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# pages/update
#
# POST /pages/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/pages/update.ts — Source code
# operationId: post___pages___update
export def "pages-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  pageId: string # format: misskey:id
  --title: string
  --name: string
  --summary: string # nullable
  --content: list
  --body-variables: list
  --script: string
  --eyeCatchingImageId: string # nullable, format: misskey:id
  --font: string@font-completer
  --alignCenter: oneof<nothing, bool>
  --hideTitleWhenPinned: oneof<nothing, bool>
  --visibility: string@visibility-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pages/update")
  let body = {pageId: $pageId, title: $title, name: $name, summary: $summary, content: $content, variables: $body_variables, script: $script, eyeCatchingImageId: $eyeCatchingImageId, font: $font, alignCenter: $alignCenter, hideTitleWhenPinned: $hideTitleWhenPinned, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ping
#
# POST /ping
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/ping.ts — Source code
# operationId: post___ping
export def "ping ping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<pong: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# pinned-users
#
# POST /pinned-users
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/pinned-users.ts — Source code
# operationId: post___pinned-users
export def "pinned-users pinned-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pinned-users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# promo/read
#
# POST /promo/read
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/promo/read.ts — Source code
# operationId: post___promo___read
export def "promo-read read" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  noteId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/promo/read")
  let body = {noteId: $noteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# renote-mute/create
#
# POST /renote-mute/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/renote-mute/create.ts — Source code
# operationId: post___renote-mute___create
export def "renote-mute-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/renote-mute/create")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# renote-mute/delete
#
# POST /renote-mute/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/renote-mute/delete.ts — Source code
# operationId: post___renote-mute___delete
export def "renote-mute-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/renote-mute/delete")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# renote-mute/list
#
# POST /renote-mute/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/renote-mute/list.ts — Source code
# operationId: post___renote-mute___list
export def "renote-mute-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 30
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, muteeId: string, mutee: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/renote-mute/list")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# request-reset-password
#
# POST /request-reset-password
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/request-reset-password.ts — Source code
# operationId: post___request-reset-password
export def "request-reset-password request-reset-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  username: string
  email: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/request-reset-password")
  let body = {username: $username, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# reset-db
#
# POST /reset-db
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/reset-db.ts — Source code
# operationId: post___reset-db
export def "reset-db reset-db" [
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
  let full_url = (build-url $base "/reset-db")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# reset-password
#
# POST /reset-password
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/reset-password.ts — Source code
# operationId: post___reset-password
export def "reset-password reset-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string
  password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reset-password")
  let body = {token: $body_token, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# retention
#
# GET /retention
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/retention.ts — Source code
# operationId: get___retention
export def "retention retention" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<createdAt: string, users: float, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/retention")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# retention
#
# POST /retention
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/retention.ts — Source code
# operationId: post___retention
export def "retention retention-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<createdAt: string, users: float, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/retention")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# reversi/cancel-match
#
# POST /reversi/cancel-match
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/reversi/cancel-match.ts — Source code
# operationId: post___reversi___cancel-match
export def "reversi-cancel-match cancel-match" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userId: string # nullable, format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reversi/cancel-match")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# reversi/games
#
# POST /reversi/games
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/reversi/games.ts — Source code
# operationId: post___reversi___games
export def "reversi-games games" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --my: oneof<nothing, bool> # default: false
]: any -> table<id: string, createdAt: string, startedAt: string, endedAt: string, isStarted: bool, isEnded: bool, user1Id: string, user2Id: string, user1: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, user2: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, winnerId: string, winner: record, surrenderedUserId: string, timeoutUserId: string, black: float, bw: string, noIrregularRules: bool, isLlotheo: bool, canPutEverywhere: bool, loopedBoard: bool, timeLimitForEachTurn: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reversi/games")
  let body = {limit: $limit, sinceId: $sinceId, untilId: $untilId, my: $my} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# reversi/invitations
#
# POST /reversi/invitations
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/reversi/invitations.ts — Source code
# operationId: post___reversi___invitations
export def "reversi-invitations invitations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list<record>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reversi/invitations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# reversi/match
#
# POST /reversi/match
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/reversi/match.ts — Source code
# operationId: post___reversi___match
export def "reversi-match match" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userId: string # nullable, format: misskey:id
  --noIrregularRules: oneof<nothing, bool> # default: false
  --multiple: oneof<nothing, bool> # default: false
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reversi/match")
  let body = {userId: $userId, noIrregularRules: $noIrregularRules, multiple: $multiple} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# reversi/show-game
#
# POST /reversi/show-game
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/reversi/show-game.ts — Source code
# operationId: post___reversi___show-game
export def "reversi-show-game show-game" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  gameId: string # format: misskey:id
]: any -> record<id: string, createdAt: string, startedAt: string, endedAt: string, isStarted: bool, isEnded: bool, form1: record, form2: record, user1Ready: bool, user2Ready: bool, user1Id: string, user2Id: string, user1: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list<record>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: list<record>>, user2: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list<record>, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record<name: string, softwareName: string, softwareVersion: string, iconUrl: string, faviconUrl: string, themeColor: string>, emojis: record, onlineStatus: string, badgeRoles: list<record>>, winnerId: string, winner: record, surrenderedUserId: string, timeoutUserId: string, black: float, bw: string, noIrregularRules: bool, isLlotheo: bool, canPutEverywhere: bool, loopedBoard: bool, timeLimitForEachTurn: float, logs: list<list<float>>, map: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reversi/show-game")
  let body = {gameId: $gameId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# reversi/surrender
#
# POST /reversi/surrender
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/reversi/surrender.ts — Source code
# operationId: post___reversi___surrender
export def "reversi-surrender surrender" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  gameId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reversi/surrender")
  let body = {gameId: $gameId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# reversi/verify
#
# POST /reversi/verify
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/reversi/verify.ts — Source code
# operationId: post___reversi___verify
export def "reversi-verify verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  gameId: string # format: misskey:id
  crc32: string
]: any -> record<desynced: bool, game: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reversi/verify")
  let body = {gameId: $gameId, crc32: $crc32} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# roles/list
#
# POST /roles/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/roles/list.ts — Source code
# operationId: post___roles___list
export def "roles-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# roles/notes
#
# POST /roles/notes
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/roles/notes.ts — Source code
# operationId: post___roles___notes
export def "roles-notes notes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  roleId: string # format: misskey:id
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --sinceDate: int
  --untilDate: int
  --dimension: int # nullable
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles/notes")
  let body = {roleId: $roleId, limit: $limit, sinceId: $sinceId, untilId: $untilId, sinceDate: $sinceDate, untilDate: $untilDate, dimension: $dimension} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# roles/show
#
# POST /roles/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/roles/show.ts — Source code
# operationId: post___roles___show
export def "roles-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  roleId: string # format: misskey:id
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles/show")
  let body = {roleId: $roleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# roles/users
#
# POST /roles/users
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/roles/users.ts — Source code
# operationId: post___roles___users
export def "roles-users users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  roleId: string # format: misskey:id
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --limit: int # default: 10
]: any -> table<id: string, user: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles/users")
  let body = {roleId: $roleId, sinceId: $sinceId, untilId: $untilId, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# stats
#
# GET /stats
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/stats.ts — Source code
# operationId: get___stats
export def "stats stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<notesCount: float, originalNotesCount: float, usersCount: float, originalUsersCount: float, instances: float, driveUsageLocal: float, driveUsageRemote: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# stats
#
# POST /stats
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/stats.ts — Source code
# operationId: post___stats
export def "stats stats-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<notesCount: float, originalNotesCount: float, usersCount: float, originalUsersCount: float, instances: float, driveUsageLocal: float, driveUsageRemote: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# sw/register
#
# POST /sw/register
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/sw/register.ts — Source code
# operationId: post___sw___register
export def "sw-register register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  endpoint: string
  --body-auth: string
  publickey: string
  --sendReadMessage: oneof<nothing, bool> # default: false
]: any -> record<state: string, key: string, userId: string, endpoint: string, sendReadMessage: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sw/register")
  let body = {endpoint: $endpoint, auth: $body_auth, publickey: $publickey, sendReadMessage: $sendReadMessage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# sw/show-registration
#
# POST /sw/show-registration
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/sw/show-registration.ts — Source code
# operationId: post___sw___show-registration
export def "sw-show-registration show-registration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  endpoint: string
]: any -> record<userId: string, endpoint: string, sendReadMessage: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sw/show-registration")
  let body = {endpoint: $endpoint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# sw/unregister
#
# POST /sw/unregister
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/sw/unregister.ts — Source code
# operationId: post___sw___unregister
export def "sw-unregister unregister" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  endpoint: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sw/unregister")
  let body = {endpoint: $endpoint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# sw/update-registration
#
# POST /sw/update-registration
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/sw/update-registration.ts — Source code
# operationId: post___sw___update-registration
export def "sw-update-registration update-registration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  endpoint: string
  --sendReadMessage: oneof<nothing, bool>
]: any -> record<userId: string, endpoint: string, sendReadMessage: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sw/update-registration")
  let body = {endpoint: $endpoint, sendReadMessage: $sendReadMessage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# test
#
# POST /test
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/test.ts — Source code
# operationId: post___test
export def "test test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --required: oneof<nothing, bool>
  --string: string
  --default: string # default: hello
  --nullableDefault: string # nullable, default: hello
  --id: string # format: misskey:id
]: any -> record<id: string, required: bool, string: string, default: string, nullableDefault: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/test")
  let body = {required: $required, string: $string, default: $default, nullableDefault: $nullableDefault, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# username/available
#
# POST /username/available
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/username/available.ts — Source code
# operationId: post___username___available
export def "username-available available" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  username: string
]: any -> record<available: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/username/available")
  let body = {username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users
#
# POST /users
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users.ts — Source code
# operationId: post___users
export def "users users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int # default: 0
  --body-sort: string@sort-completer-9
  --state: string@state-completer-2 # default: all
  --origin: string@origin-completer # default: local
  --hostname: string # The local host is represented with `null`. (nullable)
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = {limit: $limit, offset: $offset, sort: $body_sort, state: $state, origin: $origin, hostname: $hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/achievements
#
# POST /users/achievements
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/achievements.ts — Source code
# operationId: post___users___achievements
export def "users-achievements achievements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> table<name: string, unlockedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/achievements")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/clips
#
# POST /users/clips
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/clips.ts — Source code
# operationId: post___users___clips
export def "users-clips clips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, lastClippedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, name: string, description: string, isPublic: bool, favoritedCount: float, isFavorited: bool, notesCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/clips")
  let body = {userId: $userId, limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/featured-notes
#
# GET /users/featured-notes
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/featured-notes.ts — Source code
# operationId: get___users___featured-notes
export def "users-featured-notes featured-notes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --untilId: string # format: misskey:id
  userId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/featured-notes")
  let body = {limit: $limit, untilId: $untilId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/featured-notes
#
# POST /users/featured-notes
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/featured-notes.ts — Source code
# operationId: post___users___featured-notes
export def "users-featured-notes featured-notes-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --untilId: string # format: misskey:id
  userId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/featured-notes")
  let body = {limit: $limit, untilId: $untilId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/flashs
#
# POST /users/flashs
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/flashs.ts — Source code
# operationId: post___users___flashs
export def "users-flashs flashs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, title: string, summary: string, script: string, visibility: string, likedCount: float, isLiked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/flashs")
  let body = {userId: $userId, limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/followers
#
# POST /users/followers
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/followers.ts — Source code
# operationId: post___users___followers
export def "users-followers followers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --limit: int # default: 10
  --userId: string # format: misskey:id
  --username: string
  --host: string # The local host is represented with `null`. (nullable)
]: any -> table<id: string, createdAt: string, followeeId: string, followerId: string, followee: record, follower: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/followers")
  let body = {sinceId: $sinceId, untilId: $untilId, limit: $limit, userId: $userId, username: $username, host: $host} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/following
#
# POST /users/following
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/following.ts — Source code
# operationId: post___users___following
export def "users-following following" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --limit: int # default: 10
  --userId: string # format: misskey:id
  --username: string
  --host: string # The local host is represented with `null`. (nullable)
  --birthday: string # @deprecated use get-following-birthday-users instead. (nullable)
]: any -> table<id: string, createdAt: string, followeeId: string, followerId: string, followee: record, follower: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/following")
  let body = {sinceId: $sinceId, untilId: $untilId, limit: $limit, userId: $userId, username: $username, host: $host, birthday: $birthday} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/gallery/posts
#
# POST /users/gallery/posts
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/gallery/posts.ts — Source code
# operationId: post___users___gallery___posts
export def "users-gallery-posts posts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, title: string, description: string, fileIds: list<string>, files: list<record>, tags: list<string>, isSensitive: bool, likedCount: float, isLiked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/gallery/posts")
  let body = {userId: $userId, limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/get-following-birthday-users
#
# POST /users/get-following-birthday-users
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/get-following-birthday-users.ts — Source code
# operationId: post___users___get-following-birthday-users
# --birthday shape: {month?: int, day?: int, begin?: record, end?: record}
export def "users-get-following-birthday-users get-following-birthday-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int # default: 0
  birthday: record # shape: {month?: int, day?: int, begin?: record, end?: record}
]: any -> table<birthday: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/get-following-birthday-users")
  let body = {limit: $limit, offset: $offset, birthday: $birthday} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/get-frequently-replied-users
#
# POST /users/get-frequently-replied-users
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/get-frequently-replied-users.ts — Source code
# operationId: post___users___get-frequently-replied-users
export def "users-get-frequently-replied-users get-frequently-replied-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
  --limit: int # default: 10
]: any -> table<user: any, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/get-frequently-replied-users")
  let body = {userId: $userId, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/get-security-info
#
# POST /users/get-security-info
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/get-security-info.ts — Source code
# operationId: post___users___get-security-info
export def "users-get-security-info get-security-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string
  password: string
]: any -> record<twoFactorEnabled: bool, usePasswordLessLogin: bool, securityKeys: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/get-security-info")
  let body = {email: $email, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/get-skeb-status
#
# GET /users/get-skeb-status
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/get-skeb-status.ts — Source code
# operationId: get___users___get-skeb-status
export def "users-get-skeb-status get-skeb-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> record<screenName: string, isCreator: bool, isAcceptable: bool, creatorRequestCount: int, clientRequestCount: int, skills: table<amount: int, genre: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/get-skeb-status")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/get-skeb-status
#
# POST /users/get-skeb-status
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/get-skeb-status.ts — Source code
# operationId: post___users___get-skeb-status
export def "users-get-skeb-status get-skeb-status-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> record<screenName: string, isCreator: bool, isAcceptable: bool, creatorRequestCount: int, clientRequestCount: int, skills: table<amount: int, genre: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/get-skeb-status")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/lists/create
#
# POST /users/lists/create
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/lists/create.ts — Source code
# operationId: post___users___lists___create
export def "users-lists-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<id: string, createdAt: string, name: string, userIds: list<string>, isPublic: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/lists/create")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/lists/create-from-public
#
# POST /users/lists/create-from-public
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/lists/create-from-public.ts — Source code
# operationId: post___users___lists___create-from-public
export def "users-lists-create-from-public create-from-public" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  listId: string # format: misskey:id
]: any -> record<id: string, createdAt: string, name: string, userIds: list<string>, isPublic: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/lists/create-from-public")
  let body = {name: $name, listId: $listId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/lists/delete
#
# POST /users/lists/delete
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/lists/delete.ts — Source code
# operationId: post___users___lists___delete
export def "users-lists-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  listId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/lists/delete")
  let body = {listId: $listId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/lists/favorite
#
# POST /users/lists/favorite
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/lists/favorite.ts — Source code
# operationId: post___users___lists___favorite
export def "users-lists-favorite favorite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  listId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/lists/favorite")
  let body = {listId: $listId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/lists/get-memberships
#
# POST /users/lists/get-memberships
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/lists/get-memberships.ts — Source code
# operationId: post___users___lists___get-memberships
export def "users-lists-get-memberships get-memberships" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  listId: string # format: misskey:id
  --forPublic: oneof<nothing, bool> # default: false
  --limit: int # default: 30
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, withReplies: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/lists/get-memberships")
  let body = {listId: $listId, forPublic: $forPublic, limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/lists/list
#
# POST /users/lists/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/lists/list.ts — Source code
# operationId: post___users___lists___list
export def "users-lists-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, name: string, userIds: list<string>, isPublic: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/lists/list")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/lists/pull
#
# POST /users/lists/pull
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/lists/pull.ts — Source code
# operationId: post___users___lists___pull
export def "users-lists-pull pull" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  listId: string # format: misskey:id
  userId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/lists/pull")
  let body = {listId: $listId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/lists/push
#
# POST /users/lists/push
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/lists/push.ts — Source code
# operationId: post___users___lists___push
export def "users-lists-push push" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  listId: string # format: misskey:id
  userId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/lists/push")
  let body = {listId: $listId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/lists/show
#
# POST /users/lists/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/lists/show.ts — Source code
# operationId: post___users___lists___show
export def "users-lists-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  listId: string # format: misskey:id
  --forPublic: oneof<nothing, bool> # default: false
]: any -> record<id: string, createdAt: string, name: string, userIds: list<string>, isPublic: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/lists/show")
  let body = {listId: $listId, forPublic: $forPublic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/lists/unfavorite
#
# POST /users/lists/unfavorite
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/lists/unfavorite.ts — Source code
# operationId: post___users___lists___unfavorite
export def "users-lists-unfavorite unfavorite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  listId: string # format: misskey:id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/lists/unfavorite")
  let body = {listId: $listId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/lists/update
#
# POST /users/lists/update
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/lists/update.ts — Source code
# operationId: post___users___lists___update
export def "users-lists-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  listId: string # format: misskey:id
  --name: string
  --isPublic: oneof<nothing, bool>
]: any -> record<id: string, createdAt: string, name: string, userIds: list<string>, isPublic: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/lists/update")
  let body = {listId: $listId, name: $name, isPublic: $isPublic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/lists/update-membership
#
# POST /users/lists/update-membership
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/lists/update-membership.ts — Source code
# operationId: post___users___lists___update-membership
export def "users-lists-update-membership update-membership" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  listId: string # format: misskey:id
  userId: string # format: misskey:id
  --withReplies: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/lists/update-membership")
  let body = {listId: $listId, userId: $userId, withReplies: $withReplies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/notes
#
# POST /users/notes
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/notes.ts — Source code
# operationId: post___users___notes
export def "users-notes notes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
  --withReplies: oneof<nothing, bool> # default: false
  --withRenotes: oneof<nothing, bool> # default: true
  --withChannelNotes: oneof<nothing, bool> # default: false
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --sinceDate: int
  --untilDate: int
  --allowPartial: oneof<nothing, bool> # default: false
  --withFiles: oneof<nothing, bool> # default: false
]: any -> table<id: string, createdAt: string, deletedAt: string, text: string, cw: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, replyId: string, renoteId: string, reply: record, renote: record, isHidden: bool, visibility: string, mentions: list<string>, visibleUserIds: list<string>, fileIds: list<string>, files: list<record>, tags: list<string>, poll: record<expiresAt: string, multiple: bool, choices: list>, emojis: record, channelId: string, channel: record<id: string, name: string, color: string, isSensitive: bool, allowRenoteToExternal: bool, userId: string>, localOnly: bool, dimension: int, reactionAcceptance: string, reactionEmojis: record, reactions: record, reactionCount: float, renoteCount: float, repliesCount: float, uri: string, url: string, reactionAndUserPairCache: list<string>, clippedCount: float, myReaction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/notes")
  let body = {userId: $userId, withReplies: $withReplies, withRenotes: $withRenotes, withChannelNotes: $withChannelNotes, limit: $limit, sinceId: $sinceId, untilId: $untilId, sinceDate: $sinceDate, untilDate: $untilDate, allowPartial: $allowPartial, withFiles: $withFiles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/pages
#
# POST /users/pages
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/pages.ts — Source code
# operationId: post___users___pages
export def "users-pages pages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
]: any -> table<id: string, createdAt: string, updatedAt: string, userId: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, content: list<record>, variables: list<record>, title: string, name: string, summary: string, hideTitleWhenPinned: bool, alignCenter: bool, font: string, script: string, eyeCatchingImageId: string, eyeCatchingImage: record, attachedFiles: list<record>, likedCount: float, isLiked: bool, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/pages")
  let body = {userId: $userId, limit: $limit, sinceId: $sinceId, untilId: $untilId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/reactions
#
# POST /users/reactions
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/reactions.ts — Source code
# operationId: post___users___reactions
export def "users-reactions reactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
  --limit: int # default: 10
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --sinceDate: int
  --untilDate: int
]: any -> table<id: string, createdAt: string, user: record<id: string, name: string, username: string, host: string, avatarUrl: string, avatarBlurhash: string, avatarDecorations: list, isBot: bool, isCat: bool, requireSigninToViewContents: bool, makeNotesFollowersOnlyBefore: float, makeNotesHiddenBefore: float, instance: record, emojis: record, onlineStatus: string, badgeRoles: list>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/reactions")
  let body = {userId: $userId, limit: $limit, sinceId: $sinceId, untilId: $untilId, sinceDate: $sinceDate, untilDate: $untilDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/recommendation
#
# POST /users/recommendation
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/recommendation.ts — Source code
# operationId: post___users___recommendation
export def "users-recommendation recommendation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int # default: 0
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/recommendation")
  let body = {limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/relation
#
# POST /users/relation
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/relation.ts — Source code
# operationId: post___users___relation
export def "users-relation relation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/relation")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/report-abuse
#
# POST /users/report-abuse
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/report-abuse.ts — Source code
# operationId: post___users___report-abuse
export def "users-report-abuse report-abuse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
  comment: string
  --category: string@category-completer # default: other
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/report-abuse")
  let body = {userId: $userId, comment: $comment, category: $category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/search
#
# POST /users/search
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/search.ts — Source code
# operationId: post___users___search
export def "users-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-query: string
  --offset: int # default: 0
  --limit: int # default: 10
  --origin: string@origin-completer # default: combined
  --detail: oneof<nothing, bool> # default: true
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/search")
  let body = {query: $body_query, offset: $offset, limit: $limit, origin: $origin, detail: $detail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/search-by-username-and-host
#
# POST /users/search-by-username-and-host
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/search-by-username-and-host.ts — Source code
# operationId: post___users___search-by-username-and-host
export def "users-search-by-username-and-host search-by-username-and-host" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --detail: oneof<nothing, bool> # default: true
  --username: string # nullable
  --host: string # nullable
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/search-by-username-and-host")
  let body = {limit: $limit, detail: $detail, username: $username, host: $host} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/show
#
# POST /users/show
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/show.ts — Source code
# operationId: post___users___show
export def "users-show show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userId: string # format: misskey:id
  --userIds: list
  --username: string
  --host: string # The local host is represented with `null`. (nullable)
  --detailed: oneof<nothing, bool> # default: true
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/show")
  let body = {userId: $userId, userIds: $userIds, username: $username, host: $host, detailed: $detailed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/stats
#
# POST /users/stats
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/stats.ts — Source code
# operationId: post___users___stats
export def "users-stats stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
]: any -> record<notesCount: int, repliesCount: int, renotesCount: int, repliedCount: int, renotedCount: int, pollVotesCount: int, pollVotedCount: int, localFollowingCount: int, remoteFollowingCount: int, localFollowersCount: int, remoteFollowersCount: int, followingCount: int, followersCount: int, sentReactionsCount: int, receivedReactionsCount: int, noteFavoritesCount: int, pageLikesCount: int, pageLikedCount: int, driveFilesCount: int, driveUsage: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/stats")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# users/update-memo
#
# POST /users/update-memo
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/users/update-memo.ts — Source code
# operationId: post___users___update-memo
export def "users-update-memo update-memo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string # format: misskey:id
  --memo: string # A personal memo for the target user. If null or empty, delete the memo. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/update-memo")
  let body = {userId: $userId, memo: $memo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# v2/admin/emoji/list
#
# POST /v2/admin/emoji/list
# Docs: https://github.com/MisskeyIO/misskey/blob/io/packages/backend/src/server/api/endpoints/v2/admin/emoji/list.ts — Source code
# operationId: post___v2___admin___emoji___list
# --query shape: {updatedAtFrom?: string, updatedAtTo?: string, name?: string, host?: string, uri?: string, publicUrl?: string, originalUrl?: string, type?: string, aliases?: string, category?: string, license?: string, isSensitive?: bool, localOnly?: bool, hostType?: "local"|"remote"|"all", roleIds?: list}
export def "admin-emoji-list list-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-query: record # nullable — shape: {updatedAtFrom?: string, updatedAtTo?: string, name?: string, host?: string, uri?: string, publicUrl?: string, originalUrl?: string, type?: string, aliases?: string, category?: string, license?: string, isSensitive?: bool, localOnly?: bool, hostType?: "local"|"remote"|"all", roleIds?: list}
  --sinceId: string # format: misskey:id
  --untilId: string # format: misskey:id
  --limit: int # default: 10
  --page: int
  --sortKeys: list # default: [-id]
]: any -> record<emojis: table<id: string, updatedAt: string, name: string, host: string, publicUrl: string, originalUrl: string, uri: string, type: string, aliases: list, category: string, license: string, localOnly: bool, isSensitive: bool, roleIdsThatCanBeUsedThisEmojiAsReaction: list>, count: int, allCount: int, allPages: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/admin/emoji/list")
  let body = {query: $body_query, sinceId: $sinceId, untilId: $untilId, limit: $limit, page: $page, sortKeys: $sortKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
