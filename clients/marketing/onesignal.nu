# Auto-generated client for api.onesignal.com v11.6
# Source: https://documentation.onesignal.com/openapi.json
# Auth: --token flag or $env.API_ONESIGNAL_COM_TOKEN

const BASE_URL = "https://api.onesignal.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_ONESIGNAL_COM_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.onesignal.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def outcome-time-range-completer [] { ["1d" "1h" "1mo"] }
def outcome-attribution-completer [] { ["direct" "influenced" "total" "unattributed"] }
def channel-completer [] { ["email" "push" "sms"] }
def target-channel-completer [] { ["email" "push" "sms"] }
def huawei-category-completer [] { ["ACCOUNT" "DEVICE_REMINDER" "EXPRESS" "FINANCE" "HEALTH" "IM" "MAIL" "MARKETING" "SUBSCRIPTION" "TRAVEL" "VOIP" "WORK"] }
def huawei-msg-type-completer [] { ["data" "message"] }
def priority-completer [] { ["10" "5"] }
def ios-interruption-level-completer [] { ["active" "critical" "passive" "time_sensitive"] }
def ios-badgeType-completer [] { ["Increase" "None" "SetTo"] }
def event-completer [] { ["end" "update"] }
def event-completer-1 [] { ["start"] }
def ip-allowlist-mode-completer [] { ["disabled" "explicit"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apps view-apps" } } | get name | first)
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

# View apps
#
# GET /apps
# operationId: view-apps
export def "apps view-apps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your Organization API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> table<id: string, name: string, players: int, messageable_players: int, created_at: string, updated_at: string, organization_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an app
#
# POST /apps
# operationId: create-an-app
export def "apps create-an-app" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --Authorization: string # Your Organization API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  name: string # An internal name you set to help organize and track Apps. Maximum 128 characters. (default: NAME_OF_NEW_APP)
  organization_id: string # The [Organization ID](/docs/en/keys-and-ids#organization-id) that the app will be associated with. (default: YOUR_ORG_ID)
  --chrome-web-origin: string # The HTTPS [origin](https://developer.mozilla.org/en-US/docs/Glossary/Origin) URL for your website. Required for web push notifications.
  --site-name: string # The name of your website. Used for web push notification titles when omitted from the notification payload. Required for web push notifications. (default: SITE_NAME)
  --safari-site-origin: string # The HTTPS [origin](https://developer.mozilla.org/en-US/docs/Glossary/Origin) URL for your website. Required for web push notifications for Safari and should be the same as `chrome_web_origin`.
  --chrome-web-default-notification-icon: string # The full `https` URL to your default icon resource. The icon should be a `256x256px` PNG.
  --safari-icon-256-256: string # The full `https` URL to your default icon resource. The icon should be a `256x256px` PNG.
  --safari-apns-p12: string # A Base64 encoded p12 certificate for Safari Push Notifications. If omitted, we will assign one to your app for you.
  --safari-apns-p12-password: string # The password for the `safari_apns_p12` file if applicable.
  --fcm-v1-service-account-json: string # Your FCM Service Account JSON file converted to base64 format. See [Android: Firebase Credentials](/docs/android-firebase-credentials). Required for Android mobile push notifications.
  --apns-p8: string # A Base64 encoded p8 file for iOS mobile Push Notifications. Omit if using `apns_p12`. See [p8 Token-based connection to APNS](/docs/ios-p8-token-based-connection-to-apns).
  --apns-env: string # The [APS Environment Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/aps-environment) to specify whether this is a `production` or `development` environment. Defaults to `production`. Use with `apns_p8`.
  --apns-key-id: string # The APNS Key ID. Use with `apns_p8`. See [p8 Token-based connection to APNS](/docs/ios-p8-token-based-connection-to-apns).
  --apns-team-id: string # The APNS Team ID. Use with `apns_p8`. See [p8 Token-based connection to APNS](/docs/ios-p8-token-based-connection-to-apns).
  --apns-bundle-id: string # The Bundle ID for your app. Use with `apns_p8`. See [p8 Token-based connection to APNS](/docs/ios-p8-token-based-connection-to-apns).
  --apns-p12: string # A Base64 encoded p12 certificate for iOS mobile push notifications. Omit if using `apns_p8`. See [p12 APNS Authentication](/docs/ios-p12-generate-certificates).
  --apns-p12-password: string # The password for the `apns_p12` file if applicable.
  --additional-data-is-root-payload: oneof<nothing, bool> # If set to `true`, the `data` paramater in your push notification payload will be added to the root payload of the notification. Helpful for customizations that require access to the data outside of our [OSNotification payload `additionalData` property](/docs/osnotification-payload). (default: false)
]: any -> record<id: string, name: string, players: int, messageable_players: int, created_at: string, updated_at: string, organization_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps")
  let body = {name: $name, organization_id: $organization_id, chrome_web_origin: $chrome_web_origin, site_name: $site_name, safari_site_origin: $safari_site_origin, chrome_web_default_notification_icon: $chrome_web_default_notification_icon, safari_icon_256_256: $safari_icon_256_256, safari_apns_p12: $safari_apns_p12, safari_apns_p12_password: $safari_apns_p12_password, fcm_v1_service_account_json: $fcm_v1_service_account_json, apns_p8: $apns_p8, apns_env: $apns_env, apns_key_id: $apns_key_id, apns_team_id: $apns_team_id, apns_bundle_id: $apns_bundle_id, apns_p12: $apns_p12, apns_p12_password: $apns_p12_password, additional_data_is_root_payload: $additional_data_is_root_payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View an app
#
# GET /apps/{app_id}
# operationId: view-an-app
export def "apps view-an-app" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --Authorization: string # Your Organization API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record<id: string, name: string, players: int, messageable_players: int, created_at: string, updated_at: string, organization_id: string, fcm_v1_service_account_json: string, fcm_sender_id: string, chrome_web_key: string, chrome_web_origin: string, chrome_web_gcm_sender_id: string, chrome_web_default_notification_icon: string, chrome_web_sub_domain: string, apns_env: string, apns_certificates: string, apns_p8: string, apns_team_id: string, apns_key_id: string, apns_bundle_id: string, site_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)")
  let extra_headers = {"Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an app
#
# PUT /apps/{app_id}
# operationId: update-an-app
export def "apps update-an-app" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --Authorization: string # Your Organization API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  --name: string # An internal name you set to help organize and track Apps. Maximum 128 characters. (default: NAME_OF_NEW_APP)
  --organization-id: string # The [Organization ID](/docs/en/keys-and-ids#organization-id) that the app will be associated with. (default: YOUR_ORG_ID)
  --chrome-web-origin: string # The HTTPS [origin](https://developer.mozilla.org/en-US/docs/Glossary/Origin) URL for your website. Required for web push notifications.
  --site-name: string # The name of your website. Used for web push notification titles when omitted from the notification payload. Required for web push notifications. (default: SITE_NAME)
  --safari-site-origin: string # The HTTPS [origin](https://developer.mozilla.org/en-US/docs/Glossary/Origin) URL for your website. Required for web push notifications for Safari and should be the same as `chrome_web_origin`.
  --chrome-web-default-notification-icon: string # The full `https` URL to your default icon resource. The icon should be a `256x256px` PNG.
  --safari-icon-256-256: string # The full `https` URL to your default icon resource. The icon should be a `256x256px` PNG.
  --safari-apns-p12: string # A Base64 encoded p12 certificate for Safari Push Notifications. If omitted, we will assign one to your app for you.
  --safari-apns-p12-password: string # The password for the `safari_apns_p12` file if applicable.
  --fcm-v1-service-account-json: string # Your FCM Service Account JSON file converted to base64 format. See [Android: Firebase Credentials](/docs/android-firebase-credentials). Required for Android mobile push notifications.
  --apns-p8: string # A Base64 encoded p8 file for iOS mobile Push Notifications. Omit if using `apns_p12`. See [p8 Token-based connection to APNS](/docs/ios-p8-token-based-connection-to-apns).
  --apns-env: string # The [APS Environment Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/aps-environment) to specify whether this is a `production` or `development` environment. Defaults to `production`. Use with `apns_p8`.
  --apns-key-id: string # The APNS Key ID. Use with `apns_p8`. See [p8 Token-based connection to APNS](/docs/ios-p8-token-based-connection-to-apns).
  --apns-team-id: string # The APNS Team ID. Use with `apns_p8`. See [p8 Token-based connection to APNS](/docs/ios-p8-token-based-connection-to-apns).
  --apns-bundle-id: string # The Bundle ID for your app. Use with `apns_p8`. See [p8 Token-based connection to APNS](/docs/ios-p8-token-based-connection-to-apns).
  --apns-p12: string # A Base64 encoded p12 certificate for iOS mobile push notifications. Omit if using `apns_p8`. See [p12 APNS Authentication](/docs/ios-p12-generate-certificates).
  --apns-p12-password: string # The password for the `apns_p12` file if applicable.
  --additional-data-is-root-payload: oneof<nothing, bool> # If set to `true`, the `data` paramater in your push notification payload will be added to the root payload of the notification. Helpful for customizations that require access to the data outside of our [OSNotification payload `additionalData` property](/docs/osnotification-payload). (default: false)
]: any -> record<id: string, name: string, players: int, messageable_players: int, created_at: string, updated_at: string, organization_id: string, fcm_v1_service_account_json: string, fcm_sender_id: string, chrome_web_key: string, chrome_web_origin: string, chrome_web_gcm_sender_id: string, chrome_web_default_notification_icon: string, chrome_web_sub_domain: string, apns_env: string, apns_certificates: string, apns_p8: string, apns_team_id: string, apns_key_id: string, apns_bundle_id: string, site_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)")
  let body = {name: $name, organization_id: $organization_id, chrome_web_origin: $chrome_web_origin, site_name: $site_name, safari_site_origin: $safari_site_origin, chrome_web_default_notification_icon: $chrome_web_default_notification_icon, safari_icon_256_256: $safari_icon_256_256, safari_apns_p12: $safari_apns_p12, safari_apns_p12_password: $safari_apns_p12_password, fcm_v1_service_account_json: $fcm_v1_service_account_json, apns_p8: $apns_p8, apns_env: $apns_env, apns_key_id: $apns_key_id, apns_team_id: $apns_team_id, apns_bundle_id: $apns_bundle_id, apns_p12: $apns_p12, apns_p12_password: $apns_p12_password, additional_data_is_root_payload: $additional_data_is_root_payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Export subscriptions CSV
#
# POST /players/csv_export
# operationId: csv-export
export def "players-csv-export csv-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Your OneSignal App ID in UUID v4 format. See [Keys & IDs](/docs/en/keys-and-ids). (default: YOUR_APP_ID)
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  --extra-fields: list # Additional properties that you can include in the CSV. (default: [external_user_id, country, timezone_id])
  --last-active-since: string # A Unix timestamp (in seconds) used to filter Subscriptions based on recent activity. Only Subscriptions with a `last_session` timestamp after this value will be included in the export. Example: To export Subscriptions active since January 1st, 2024, use `1704067200`.
  --segment-name: string # The name of a specific segment to filter the export. Only subscriptions that belong to this segment will be included in the CSV. Omit this field to export all subscriptions in the app.
  --include-unsubscribed: oneof<nothing, bool> # When used with `segment_name`, set to `true` to include unsubscribed subscriptions in the export. By default, segment-filtered exports only return subscribed subscriptions. This parameter has no effect when `segment_name` is not provided. (default: false)
]: any -> record<csv_file_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_id" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/players/csv_export" $qp)
  let body = {extra_fields: $extra_fields, last_active_since: $last_active_since, segment_name: $segment_name, include_unsubscribed: $include_unsubscribed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Message history
#
# POST /notifications/{message_id}/history
# operationId: message-history
export def "notifications-history message-history" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  app_id: string # Your OneSignal App ID in UUID v4 format. See [Keys & IDs](/docs/en/keys-and-ids). (default: YOUR_APP_ID)
  events: string # Specifies the type of event to retrieve. `sent` — retrieves all subscriptions sent the specified message. Note: sent events are not recorded for messages targeting fewer than 1,000 recipients. `clicked` — retrieves all subscriptions that interacted with the message. Note: There isn't a recipient count threshold for tracking clicked event. (default: sent)
  --email: string # The email address in which to deliver the report.
]: any -> record<success: bool, destination_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/($message_id)/history")
  let body = {app_id: $app_id, events: $events, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create segment
#
# POST /apps/{app_id}/segments
# operationId: create-segments
export def "apps-segments create-segments" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  --Content-Type: string
  --id: string # UUID of the segment. If left empty, it will be assigned automatically.
  name: string # An internal name you set to help organize and track Segments. Maximum 128 characters. (default: YOUR_SEGMENT_NAME)
  --description: string # Optional human-readable description for the segment. Maximum 255 characters. (default: YOUR_SEGMENT_DESCRIPTION)
  filters: list # Filters define the segment based on user properties like tags, activity, or location using flexible AND/OR logic. Limited to 200 total entries, including fields and `OR` operators. See [Sending messages with the OneSignal API](/reference/create-message#filters).
]: any -> record<success: bool, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/segments")
  let body = {id: $id, name: $name, description: $description, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View segments
#
# GET /apps/{app_id}/segments
# operationId: view-segments
export def "apps-segments view-segments" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The index to start returning segments from. Defaults to `0`. Segments are sorted by their creation date (`created_at`) in ascending order. (format: int32, default: 0)
  --limit: int # The maximum number of segments to return. Default/Max: `300`. Ideal for controlling data volume in large-scale applications. (format: int32, default: 300)
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record<total_count: int, offset: int, limit: int, segments: table<id: string, name: string, description: string, created_at: string, updated_at: string, app_id: string, read_only: bool, is_active: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_id)/segments" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View segment
#
# GET /apps/{app_id}/segments/{segment_id}
# operationId: view-segment
export def "apps-segments view-segment" [
  app_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-segment-detail: oneof<nothing, bool> # Set to `true` to include segment metadata and filters in the response. (default: false)
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record<subscriber_count: int, payload: record<id: string, name: string, description: string, created_at: int, source: string, filters: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include-segment-detail" $include_segment_detail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_id)/segments/($segment_id)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update segment
#
# PATCH /apps/{app_id}/segments/{segment_id}
# operationId: update-segment
export def "apps-segments update-segment" [
  app_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  --Content-Type: string
  name: string # Required. The segment name. Maximum 128 characters. (default: YOUR_SEGMENT_NAME)
  --description: string # Optional human-readable description for the segment. Maximum 255 characters. Pass an empty string to clear; omit to leave unchanged. (default: YOUR_SEGMENT_DESCRIPTION)
  --filters: list # Optional. When provided, replaces all existing filters. Filters define the segment based on user properties like tags, activity, or location using flexible AND/OR logic. Limited to 200 total entries, including fields and `OR` operators. See [Create segment](/reference/create-segments) for filter syntax.
]: any -> record<success: bool, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/segments/($segment_id)")
  let body = {name: $name, description: $description, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete segment
#
# DELETE /apps/{app_id}/segments/{segment_id}
# operationId: delete-segments
export def "apps-segments delete-segments" [
  app_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/segments/($segment_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View outcomes
#
# GET /apps/{app_id}/outcomes?outcome_names={outcome_names}&outcome_time_range={outcome_time_range}&outcome_platforms={outcome_platforms}&outcome_attribution={outcome_attribution}
# operationId: view-outcomes
export def "apps-outcomes-outcome-names-outcome-names-outcome-time-range-outcome-time-range-outcome-platforms-outcome-platforms-outcome-attribution-outcome-attribution view-outcomes" [
  app_id: string
  outcome_names: any
  outcome_time_range: any
  outcome_platforms: any
  outcome_attribution: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --outcome-names: list # The name and aggregation type of the outcome(s) you want to fetch. Example: `my_outcome.count` or `my_outcome.sum`. For clicks, use `os__click.count`. For confirmed deliveries, use `os__confirmed_delivery.count`. For session duration, use `os__session_duration.count`.
  --outcome-time-range: string@outcome-time-range-completer # Time range for the returned data. Available values: `1h` (1 hour), `1d` (1 day), `1mo` (1 month) (default: 1h)
  --outcome-platforms: string # The platforms in which you want to pull the data represented as the `device_type` integer. (default: 0,1,2,5,8,11,14,17)
  --outcome-attribution: string@outcome-attribution-completer # Attribution type for the outcomes. (default: total)
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record<outcomes: table<id: string, value: int, aggregation: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outcome_names" $outcome_names "multi") (serialize-qp "outcome_time_range" $outcome_time_range "scalar") (serialize-qp "outcome_platforms" $outcome_platforms "scalar") (serialize-qp "outcome_attribution" $outcome_attribution "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_id)/outcomes?outcome_names=($outcome_names)&outcome_time_range=($outcome_time_range)&outcome_platforms=($outcome_platforms)&outcome_attribution=($outcome_attribution)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update subscription
#
# PATCH /apps/{app_id}/subscriptions/{subscription_id}
# operationId: update-subscription
# --subscription shape: {type: "Email"|"SMS"|"iOSPush"|"AndroidPush"|"HuaweiPush"|"FireOSPush"|"WindowsPush"|"macOSPush"|"ChromeExtensionPush"|"ChromePush"|"SafariLegacyPush"|"FirefoxPush"|"SafariPush", token: string, enabled?: bool, notification_types?: int, session_time?: int, session_count?: int, app_version?: string, device_model?: string, device_os?: string, test_type?: int, sdk?: string, web_auth?: string, web_p256?: string}
export def "apps-subscriptions update-subscription" [
  app_id: string
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription: record # The subscription's properties. — shape: {type: "Email"|"SMS"|"iOSPush"|"AndroidPush"|"HuaweiPush"|"FireOSPush"|"WindowsPush"|"macOSPush"|"ChromeExtensionPush"|"ChromePush"|"SafariLegacyPush"|"FirefoxPush"|"SafariPush", token: string, enabled?: bool, notification_types?: int, session_time?: int, session_count?: int, app_version?: string, device_model?: string, device_os?: string, test_type?: int, sdk?: string, web_auth?: string, web_p256?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/subscriptions/($subscription_id)")
  let body = {subscription: $subscription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete subscription
#
# DELETE /apps/{app_id}/subscriptions/{subscription_id}
# operationId: delete-subscription
export def "apps-subscriptions delete-subscription" [
  app_id: string
  subscription_id: string
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
  let full_url = (build-url $base $"/apps/($app_id)/subscriptions/($subscription_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update subscription By Token
#
# PATCH /apps/{app_id}/subscriptions_by_token/{token_type}/{token}
# operationId: update-subscription-by-token
# --subscription shape: {enabled?: bool, notification_types?: int, session_time?: int, session_count?: int, app_version?: string, device_model?: string, device_os?: string, test_type?: int, sdk?: string, web_auth?: string, web_p256?: string}
export def "apps-subscriptions-by-token update-subscription-by-token" [
  app_id: string
  token_type: string
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  --subscription: record # The subscription's properties. — shape: {enabled?: bool, notification_types?: int, session_time?: int, session_count?: int, app_version?: string, device_model?: string, device_os?: string, test_type?: int, sdk?: string, web_auth?: string, web_p256?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/subscriptions_by_token/($token_type)/($token)")
  let body = {subscription: $subscription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Subscription by alias
#
# POST /apps/{app_id}/users/by/{alias_label}/{alias_id}/subscriptions
# operationId: create-subscription
# --subscription shape: {type: "Email"|"SMS"|"iOSPush"|"AndroidPush"|"HuaweiPush"|"FireOSPush"|"WindowsPush"|"macOSPush"|"ChromeExtensionPush"|"ChromePush"|"SafariLegacyPush"|"FirefoxPush"|"SafariPush", token: string, enabled?: bool, notification_types?: int, session_time?: int, session_count?: int, app_version?: string, device_model?: string, device_os?: string, test_type?: int, sdk?: string, web_auth?: string, web_p256?: string}
export def "apps-users-by-subscriptions create-subscription" [
  app_id: string
  alias_label: string
  alias_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  subscription: record # The subscription's properties. — shape: {type: "Email"|"SMS"|"iOSPush"|"AndroidPush"|"HuaweiPush"|"FireOSPush"|"WindowsPush"|"macOSPush"|"ChromeExtensionPush"|"ChromePush"|"SafariLegacyPush"|"FirefoxPush"|"SafariPush", token: string, enabled?: bool, notification_types?: int, session_time?: int, session_count?: int, app_version?: string, device_model?: string, device_os?: string, test_type?: int, sdk?: string, web_auth?: string, web_p256?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/users/by/($alias_label)/($alias_id)/subscriptions")
  let body = {subscription: $subscription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update user
#
# PATCH /apps/{app_id}/users/by/{alias_label}/{alias_id}
# operationId: update-user
# --properties shape: {tags?: record, language?: string, timezone_id?: string, lat?: float, long?: float, country?: string, first_active?: int, last_active?: int, ip?: string, test_user_name?: string}
# --deltas shape: {session_time?: int, session_count?: int, purchases?: list}
export def "apps-users-by update-user" [
  app_id: string
  alias_label: string
  alias_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  --onesignal-subscription-id: string # Optional. Identifies a specific subscription to update. Some user properties, such as Session Time and Session Count, will update values on both the User and the Subscription.
  --properties: record # Represents user profile data for a given user, including tags, preferences, user activity, and other valuable properties. — shape: {tags?: record, language?: string, timezone_id?: string, lat?: float, long?: float, country?: string, first_active?: int, last_active?: int, ip?: string, test_user_name?: string}
  --deltas: record # User properties that change frequently and generally only increment. — shape: {session_time?: int, session_count?: int, purchases?: list}
]: any -> record<properties: record<language: string, timezone_id: string, lat: int, long: int, country: string, first_active: int, last_active: int, test_user_name: string, purchases: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/users/by/($alias_label)/($alias_id)")
  let body = {properties: $properties, deltas: $deltas} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "onesignal-subscription-id": $onesignal_subscription_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View user
#
# GET /apps/{app_id}/users/by/{alias_label}/{alias_id}
# operationId: view-user
export def "apps-users-by view-user" [
  app_id: string
  alias_label: string
  alias_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record<properties: record<tags: record<KEY: string>, country: string, first_active: int, last_active: int, test_user_name: string>, identity: record<external_id: string, onesignal_id: string>, subscriptions: table<id: string, app_id: string, type: string, token: string, enabled: bool, notification_types: int, session_time: int, session_count: int, sdk: string, device_model: string, device_os: string, rooted: bool, test_type: int, app_version: string, net_type: int, carrier: string, web_auth: string, web_p256: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/users/by/($alias_label)/($alias_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete user
#
# DELETE /apps/{app_id}/users/by/{alias_label}/{alias_id}
# operationId: delete-user
export def "apps-users-by delete-user" [
  app_id: string
  alias_label: string
  alias_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record<identity: record<onesignal_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/users/by/($alias_label)/($alias_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create user
#
# POST /apps/{app_id}/users
# operationId: create-user
# --properties shape: {tags?: record, language?: string, timezone_id?: string, lat?: float, long?: float, country?: string, first_active?: int, last_active?: int, ip?: string, test_user_name?: string}
# --identity shape: {external_id?: string}
# --subscriptions item shape: {type: "Email"|"SMS"|"iOSPush"|"AndroidPush"|"HuaweiPush"|"FireOSPush"|"WindowsPush"|"macOSPush"|"ChromePush"|"FirefoxPush"|"SafariPush", token: string, enabled?: bool, notification_types?: int, session_time?: int, session_count?: int, app_version?: string, device_model?: string, device_os?: string, test_type?: int, sdk?: string, web_auth?: string, web_p256?: string}
export def "apps-users create-user" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # Represents user profile data for a given user, including tags, preferences, user activity, and other valuable properties. — shape: {tags?: record, language?: string, timezone_id?: string, lat?: float, long?: float, country?: string, first_active?: int, last_active?: int, ip?: string, test_user_name?: string}
  --identity: record # Defines identifiers for the user. The `external_id` must be used and should be unique across users. — shape: {external_id?: string}
  --subscriptions: list # The subscriptions object allows for creating or transferring subscriptions to a specified user. See [Subscriptions](/docs/subscriptions). — item shape: {type: "Email"|"SMS"|"iOSPush"|"AndroidPush"|"HuaweiPush"|"FireOSPush"|"WindowsPush"|"macOSPush"|"ChromePush"|"FirefoxPush"|"SafariPush", token: string, enabled?: bool, notification_types?: int, session_time?: int, session_count?: int, app_version?: string, device_model?: string, device_os?: string, test_type?: int, sdk?: string, web_auth?: string, web_p256?: string}
]: any -> record<identity: record<onesignal_id: string>, properties: record<tags: record<first_name: string, last_name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/users")
  let body = {properties: $properties, identity: $identity, subscriptions: $subscriptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View user identity
#
# GET /apps/{app_id}/users/by/{alias_label}/{alias_id}/identity
# operationId: fetch-aliases
export def "apps-users-by-identity fetch-aliases" [
  app_id: string
  alias_label: string
  alias_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record<identity: record<onesignal_id: string, external_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/users/by/($alias_label)/($alias_id)/identity")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update alias
#
# PATCH /apps/{app_id}/users/by/{alias_label}/{alias_id}/identity
# operationId: create-alias
# --identity shape: {external_id?: string, onesignal_id?: string}
export def "apps-users-by-identity create-alias" [
  app_id: string
  alias_label: string
  alias_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  --identity: record # One or more aliases to be created for this user. — shape: {external_id?: string, onesignal_id?: string}
]: any -> record<identity: record<onesignal_id: string, custom_alias_label: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/users/by/($alias_label)/($alias_id)/identity")
  let body = {identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Transfer subscription
#
# PATCH /apps/{app_id}/subscriptions/{subscription_id}/owner
# operationId: transfer-subscription
# --identity shape: {external_id?: string, onesignal_id?: string}
export def "apps-subscriptions-owner transfer-subscription" [
  app_id: string
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: record # Identifies the user that this subscription is moved to. Must contain exactly one alias. — shape: {external_id?: string, onesignal_id?: string}
]: any -> record<identity: record<external_id: string, onesignal_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/subscriptions/($subscription_id)/owner")
  let body = {identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View user identity (by subscription)
#
# GET /apps/{app_id}/subscriptions/{subscription_id}/user/identity
# operationId: fetch-identity-by-subscription
export def "apps-subscriptions-user-identity fetch-identity-by-subscription" [
  app_id: string
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<identity: record<onesignal_id: string, external_id: string, custom_alias_label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/subscriptions/($subscription_id)/user/identity")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create alias (by subscription)
#
# PATCH /apps/{app_id}/subscriptions/{subscription_id}/user/identity
# operationId: create-alias-by-subscription
# --identity shape: {external_id?: string, onesignal_id?: string}
export def "apps-subscriptions-user-identity create-alias-by-subscription" [
  app_id: string
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: record # One or more aliases to be created for this user. — shape: {external_id?: string, onesignal_id?: string}
]: any -> record<identity: record<external_id: string, onesignal_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/subscriptions/($subscription_id)/user/identity")
  let body = {identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete alias
#
# DELETE /apps/{app_id}/users/by/{alias_label}/{alias_id}/identity/{alias_label_to_delete}
# operationId: delete-alias
export def "apps-users-by-identity delete-alias" [
  app_id: string
  alias_label: string
  alias_id: string
  alias_label_to_delete: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<identity: record<onesignal_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/users/by/($alias_label)/($alias_id)/identity/($alias_label_to_delete)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export audience activity CSV
#
# POST /notifications/{message_id}/export_events
# operationId: export-csv-of-events
export def "notifications-export-events export-csv-of-events" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Your OneSignal App ID in UUID v4 format. See [Keys & IDs](/docs/en/keys-and-ids). (default: YOUR_APP_ID)
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record<csv_file_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_id" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/notifications/($message_id)/export_events" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View template
#
# GET /templates/{template_id}?app_id={app_id}
# operationId: view-template
export def "templates view-template" [
  template_id: string
  app_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Your OneSignal App ID in UUID v4 format. See [Keys & IDs](/docs/en/keys-and-ids). (default: YOUR_APP_ID)
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  --Content-Type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_id" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/($template_id)?app_id=($app_id)" $qp)
  let extra_headers = {"Authorization": $Authorization, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete template
#
# DELETE /templates/{template_id}?app_id={app_id}
# operationId: delete-template
export def "templates delete-template" [
  template_id: string
  app_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Your OneSignal App ID in UUID v4 format. See [Keys & IDs](/docs/en/keys-and-ids). (default: YOUR_APP_ID)
  --Authorization: string # Your App's API key found in [Settings > Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_id" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/($template_id)?app_id=($app_id)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update template
#
# PATCH /templates/{template_id}?app_id={app_id}
# operationId: update-template
# --contents shape: {en: string}
export def "templates update-template" [
  template_id: string
  app_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Your OneSignal App ID in UUID v4 format. See [Keys & IDs](/docs/en/keys-and-ids). (default: YOUR_APP_ID)
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  name: string # An internal name you set to help organize and track Templates. Maximum 128 characters. (default: YOUR_TEMPLATE_NAME)
  --contents: record # The main message body with [language-specific values](/docs/en/multi-language-messaging#supported-languages). Supports [Message Personalization](/docs/message-personalization). — shape: {en: string}
  --isEmail: oneof<nothing, bool> # Required to be set `true` for email templates.
  --email-body: string # The body of the email in HTML format. Required for email templates. Supports [Message Personalization](/docs/message-personalization).
  --isSMS: oneof<nothing, bool> # Required to be set `true` for SMS templates.
  --dynamic-content: record # Add personalization to your templates programmatically. No need to upload a CSV. See [Dynamic Content](/docs/dynamic-content) for details. (e.g. {"campaign_id": {"A": {"title": "Custom Title A", "message": "Custom Message A", "url": "https://www.onesignal.com"}, "B": {"title": "Custom Title B", "message": "Custom Message B", "url": "https://www.onesignal.com/login"}}})
]: any -> record<id: string, name: string, channel: string, created_at: string, updated_at: string, content: record<isAndroid: bool, isIos: bool, isMacOSX: bool, isAdm: bool, isAlexa: bool, isWP: bool, isWP_WNS: bool, isChrome: bool, isChromeWeb: bool, isSafari: bool, isFirefox: bool, isEdge: bool, isHuawei: bool, headings: record, subtitle: record, contents: record, global_image: string, url: string, isEmail: bool, email_body: string, email_subject: string, email_preheader: string, email_from_address: string, email_from_name: string, email_reply_to_address: string, email_bcc: list<string>, disable_email_click_tracking: bool, isSMS: bool, sms_from: string, sms_media_urls: list<string>, huawei_badge_add_num: int, huawei_badge_class: string, huawei_badge_set_num: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_id" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/($template_id)?app_id=($app_id)" $qp)
  let body = {name: $name, contents: $contents, isEmail: $isEmail, email_body: $email_body, isSMS: $isSMS, dynamic_content: $dynamic_content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View templates
#
# GET /templates?app_id={app_id}&limit={limit}&offset={offset}
# operationId: view-templates
export def "templates-app-id-app-id-limit-limit-offset-offset view-templates" [
  app_id: any
  limit: any
  offset: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Your OneSignal App ID in UUID v4 format. See [Keys & IDs](/docs/en/keys-and-ids). (default: YOUR_APP_ID)
  --limit: int # The maximum number of templates returned per request. The default (if omitted) and maximum is 50 templates per request. (format: int32, default: 50)
  --offset: int # The pagination or "starting point" of the templates to be returned. Setting it to 0 with a limit of 50 will retrieve the first 50 templates. Increasing the offset by 50 will return the next set of templates, and so on. (format: int32, default: 0)
  --channel: string@channel-completer # Filter the fetched templates by the delivery channel. Available options are: `push`, `email`, and `SMS`.
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  --Content-Type: string
]: nothing -> record<limit: int, offset: int, templates: table<id: string, name: string, created_at: string, updated_at: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_id" $app_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "channel" $channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates?app_id=($app_id)&limit=($limit)&offset=($offset)" $qp)
  let extra_headers = {"Authorization": $Authorization, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create template
#
# POST /templates
# operationId: create-template
# --contents shape: {en: string}
export def "templates create-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  --Content-Type: string
  app_id: string # Your OneSignal App ID in UUID v4 format. See [Keys & IDs](/docs/en/keys-and-ids). (default: YOUR_APP_ID)
  name: string # An internal name you set to help organize and track Templates. Maximum 128 characters. (default: YOUR_TEMPLATE_NAME)
  --contents: record # The main message body with [language-specific values](/docs/en/multi-language-messaging#supported-languages). Required for push and SMS templates. Supports [Message Personalization](/docs/message-personalization). — shape: {en: string}
  --isEmail: oneof<nothing, bool> # Required to be set `true` for email templates.
  --email-subject: string # Required for email templates. The subject of the email. Supports [Message Personalization](/docs/message-personalization).
  --email-body: string # The body of the email in HTML format. Required for email templates. Supports [Message Personalization](/docs/message-personalization).
  --isSMS: oneof<nothing, bool> # Required to be set `true` for SMS templates.
  --dynamic-content: record # Add personalization to your templates programmatically. No need to upload a CSV. See [Dynamic Content](/docs/dynamic-content) for details. (e.g. {"campaign_id": {"A": {"title": "Custom Title A", "message": "Custom Message A", "url": "https://www.onesignal.com"}, "B": {"title": "Custom Title B", "message": "Custom Message B", "url": "https://www.onesignal.com/login"}}})
]: any -> record<id: string, name: string, channel: string, created_at: string, updated_at: string, content: record<isAndroid: bool, isIos: bool, isMacOSX: bool, isAdm: bool, isAlexa: bool, isWP: bool, isWP_WNS: bool, isChrome: bool, isChromeWeb: bool, isSafari: bool, isFirefox: bool, isEdge: bool, isHuawei: bool, headings: record, subtitle: record, contents: record, global_image: string, url: string, isEmail: bool, email_body: string, email_subject: string, email_preheader: string, email_from_address: string, email_from_name: string, email_reply_to_address: string, email_bcc: list<string>, disable_email_click_tracking: bool, isSMS: bool, sms_from: string, sms_media_urls: list<string>, huawei_badge_add_num: int, huawei_badge_class: string, huawei_badge_set_num: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates")
  let body = {app_id: $app_id, name: $name, contents: $contents, isEmail: $isEmail, email_subject: $email_subject, email_body: $email_body, isSMS: $isSMS, dynamic_content: $dynamic_content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unsubscribe email (with token)
#
# POST /apps/{app_id}/notifications/{notification_id}/unsubscribe?token={token}
# operationId: unsubscribe-with-token
export def "apps-notifications-unsubscribe-token-token unsubscribe-with-token" [
  app_id: string
  notification_id: string
  token: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # The unsubscribe token that is generated via liquid syntax `{{subscription.unsubscribe_token}}` when personalizing an email. See [Create a Custom Unsubscribe Page](/docs/create-custom-unsubscribe-page) for setup details.
]: nothing -> record<success: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_id)/notifications/($notification_id)/unsubscribe?token=($token)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Email
#
# POST /notifications?c=email
# operationId: email
# --include_aliases shape: {external_id?: list}
export def "notifications-cemail email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  app_id: string # Your OneSignal App ID in UUID v4 format. See [Keys & IDs](/docs/en/keys-and-ids). (default: YOUR_APP_ID)
  --include-aliases: record # Target up to 20,000 users by their `external_id`, `onesignal_id`, or your own custom alias. Use with `target_channel` to control the delivery channel. Not compatible with any other targeting parameters like `filters`, `include_subscription_ids`, `included_segments`, or `excluded_segments`. See [Sending messages with the OneSignal API](/reference/create-message#include-aliases). (format: json) — shape: {external_id?: list}
  --target-channel: string@target-channel-completer # The targeted delivery channel. Required when using `include_aliases`. Accepts `push`, `email`, or `sms`. (default: email)
  --include-subscription-ids: list # Target users' specific [subscriptions](/docs/subscriptions) by ID. Include up to 20,000 `subscription_id` per API call. Not compatible with any other targeting parameters like `filters`, `include_aliases`, `included_segments`, or `excluded_segments`. See [Sending messages with the OneSignal API](/reference/create-message).
  --email-to: list # Send email to specific users by their email address. Include up to 20,000 email addresses per API call. If the email address does not exist within the OneSignal App, then a new email Subscription will be created. Can only be used when sending [Email](/reference/email). Not compatible with any other targeting parameters like `filters`, `include_aliases`, `included_segments`, or `excluded_segments`. See [Sending messages with the OneSignal API](/reference/create-message).
  --included-segments: list # Target predefined [Segments](/docs/segmentation). Users that are in multiple segments will only be sent the message once. Can be combined with `excluded_segments`. Not compatible with any other targeting parameters like `filters`, `include_aliases`, or `include_subscription_ids`. See [Sending messages with the OneSignal API](/reference/create-message).
  --excluded-segments: list # Exclude users in predefined [Segments](/docs/segmentation). Overrides membership in any segment specified in the `included_segments`. Not compatible with any other targeting parameters like `filters`, `include_aliases`, or `include_subscription_ids`. See [Sending messages with the OneSignal API](/reference/create-message).
  --filters: list # Filters define the segment based on user properties like tags, activity, or location using flexible AND/OR logic. Limited to 200 total entries, including fields and `OR` operators. See [Sending messages with the OneSignal API](/reference/create-message#filters).
  email_subject: string # The subject of the email. Supports [Message Personalization](/docs/message-personalization). (default: This is your email subject.)
  --email-preheader: string # Preview text displayed after the email subject.
  email_body: string # The body of the email in HTML format. Required if `template_id` is not set. Supports [Message Personalization](/docs/message-personalization).
  --name: string # An internal name you set to help organize and track messages. Not shown to recipients. Maximum 128 characters.
  --template-id: string # The template ID in UUID v4 format set for the message if applicable. See [Templates](/docs/templates).
  --custom-data: record # Include user or context-specific data (e.g., cart items, OTPs, links) in a message. Use with `template_id`. See [Message Personalization](/docs/message-personalization). Max size: 2KB (Push/SMS), 10KB (Email).
  --email-from-name: string # The name the email is sent from. Defaults to the 'Sender Name' in the Email Settings of your OneSignal Dashboard. See [Email setup](/docs/email-setup) and [Senders](/docs/senders). (default: Your Company)
  --email-from-address: string # The full email address shown in the 'From' field of the email (e.g., `promotions@news.example.com`). This is what recipients see as the sender. If not specified, OneSignal uses the default 'Sender Email' set in your Dashboard's Email Settings. See [Senders](/docs/senders).
  --email-sender-domain: string # The authenticated sending domain used for email delivery. This domain must be verified in your DNS records and will determine which domain handles the mail transfer. It may not always exactly match the domain in the `email_from_address` (e.g., `email_from_address = news@example.com` while `email_sender_domain = mail.example.com`), but the root domain must align for DMARC compliance. If not specified, OneSignal uses the default sender email's domain configured in your Dashboard. See [Email setup](/docs/email-setup) and [Senders](/docs/senders).
  --email-reply-to-address: string # The email address users reply to. Defaults to the 'Reply-To' address in the Email Settings of your OneSignal Dashboard. See [Email setup](/docs/email-setup).
  --email-bcc: list # BCC recipients for the email. Maximum 5 addresses. Only supported when the email service provider is OneSignal Email. For every email sent, an additional billable email is sent to each BCC address.  See [BCC Emails](/docs/en/email-bcc).
  --include-unsubscribed: oneof<nothing, bool> # Used for important account-related, non-marking emails. If set to `true` it will send the email to unsubscribed email addresses. Defaults to `false`. See [Email unsubscribe links & headers](/docs/unsubscribe-links-email-subscriptions).
  --disable-email-click-tracking: oneof<nothing, bool> # If set to `true`, the URLs sent within the email will not include link tracking and will be the same as originally set; otherwise, all the URLs in the email will be tracked. See [Email unsubscribe links & headers](/docs/unsubscribe-links-email-subscriptions). Defaults to `false`.
  --send-after: string # Schedule delivery for a future date/time (in UTC). The format must be valid per the [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) standard and compatible with [`JavaScript’s Date() parser`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/Date#datestring). Example: `2025-09-24T14:00:00-07:00`
  --delayed-option: string # Controls how messages are delivered on a per-user basis: `'timezone'` — Sends at the same local time across time zones. `'last-active'` — Delivers based on each user’s most recent session. Not compatible with [Push Throttling](/docs/throttling). If enabled, set `throttle_rate_per_minute` to `0`.
  --delivery-time-of-day: string # Use with `delayed_option: 'timezone'` to set a consistent local delivery time. Accepted formats: `'9:00AM'` (12-hour), `'21:45'` (24-hour), `'09:45:30'` (HH:mm:ss).
  --idempotency-key: string # A unique identifier used to prevent duplicate messages from repeat API calls. See [Idempotent notification requests](/reference/idempotent-notification-requests). Any RFC 9562 UUID supported. Valid for 30 days. Previously called `external_id`.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications?c=email")
  let body = {app_id: $app_id, include_aliases: $include_aliases, target_channel: $target_channel, include_subscription_ids: $include_subscription_ids, email_to: $email_to, included_segments: $included_segments, excluded_segments: $excluded_segments, filters: $filters, email_subject: $email_subject, email_preheader: $email_preheader, email_body: $email_body, name: $name, template_id: $template_id, custom_data: $custom_data, email_from_name: $email_from_name, email_from_address: $email_from_address, email_sender_domain: $email_sender_domain, email_reply_to_address: $email_reply_to_address, email_bcc: $email_bcc, include_unsubscribed: $include_unsubscribed, disable_email_click_tracking: $disable_email_click_tracking, send_after: $send_after, delayed_option: $delayed_option, delivery_time_of_day: $delivery_time_of_day, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Push notification
#
# POST /notifications?c=push
# operationId: push-notification
# --include_aliases shape: {external_id?: list}
# --contents shape: {en: string}
# --headings shape: {en?: string}
# --subtitle shape: {en?: string}
# --ios_attachments shape: {id?: string}
# --buttons item shape: {id: string, text: string, icon?: string}
# --web_buttons item shape: {id: string, text: string, url: string}
export def "notifications-cpush push-notification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  app_id: string # Your OneSignal App ID in UUID v4 format. See [Keys & IDs](/docs/en/keys-and-ids). (default: YOUR_APP_ID)
  --include-aliases: record # Target up to 20,000 users by their `external_id`, `onesignal_id`, or your own custom alias. Use with `target_channel` to control the delivery channel. Not compatible with any other targeting parameters like `filters`, `include_subscription_ids`, `included_segments`, or `excluded_segments`. See [Sending messages with the OneSignal API](/reference/create-message#include-aliases). (format: json) — shape: {external_id?: list}
  --target-channel: string@target-channel-completer # The targeted delivery channel. Required when using `include_aliases`. Accepts `push`, `email`, or `sms`. (default: push)
  --include-subscription-ids: list # Target users' specific [subscriptions](/docs/subscriptions) by ID. Include up to 20,000 `subscription_id` per API call. Not compatible with any other targeting parameters like `filters`, `include_aliases`, `included_segments`, or `excluded_segments`. See [Sending messages with the OneSignal API](/reference/create-message).
  --included-segments: list # Target predefined [Segments](/docs/segmentation). Users that are in multiple segments will only be sent the message once. Can be combined with `excluded_segments`. Not compatible with any other targeting parameters like `filters`, `include_aliases`, or `include_subscription_ids`. See [Sending messages with the OneSignal API](/reference/create-message).
  --excluded-segments: list # Exclude users in predefined [Segments](/docs/segmentation). Overrides membership in any segment specified in the `included_segments`. Not compatible with any other targeting parameters like `filters`, `include_aliases`, or `include_subscription_ids`. See [Sending messages with the OneSignal API](/reference/create-message).
  --filters: list # Filters define the segment based on user properties like tags, activity, or location using flexible AND/OR logic. Limited to 200 total entries, including fields and `OR` operators. See [Sending messages with the OneSignal API](/reference/create-message#filters).
  contents: record # The main message body with [language-specific values](/docs/en/multi-language-messaging#supported-languages). Supports [Message Personalization](/docs/message-personalization). — shape: {en: string}
  --headings: record # The message title with [language-specific values](/docs/en/multi-language-messaging#supported-languages). Required for Huawei and Web Push. If not set for Web Push, it defaults to your 'Site Name'. Not required if using `template_id` or `content_available`. Supports [Message Personalization](/docs/message-personalization) and must include the same languages as `contents` to ensure localization consistency. — shape: {en?: string}
  --subtitle: record # iOS only. The subtitle with [language-specific values](/docs/en/multi-language-messaging#supported-languages). Supports [Message Personalization](/docs/message-personalization) and must include the same languages as `contents` to ensure localization consistency. — shape: {en?: string}
  --name: string # An internal name you set to help organize and track messages. Not shown to recipients. Maximum 128 characters.
  --template-id: string # The template ID in UUID v4 format set for the message if applicable. See [Templates](/docs/templates).
  --custom-data: record # Include user or context-specific data (e.g., cart items, OTPs, links) in a message. Use with `template_id`. See [Message Personalization](/docs/message-personalization). Max size: 2KB (Push/SMS), 10KB (Email).
  --ios-attachments: record # The local name or URL of the media attachment to include in your notification. Users can expand the notification to view images, videos, or other supported attachments. See [Images & Rich Media](/docs/rich-media). — shape: {id?: string}
  --big-picture: string # The local name or URL of the image to include in your Google Android notification. Users can expand the notification to view the images. See [Images & Rich Media](/docs/rich-media).
  --huawei-big-picture: string # The local name or URL of the image to include in your Huawei Android notification. Users can expand the notification to view the images. See [Images & Rich Media](/docs/rich-media).
  --adm-big-picture: string # The local name or URL of the image to include in your Amazon Android notification. Users can expand the notification to view the images. See [Images & Rich Media](/docs/rich-media).
  --chrome-web-image: string # The URL of the image to include in your Chrome notification. Users can expand the notification to view the images. Supported on Chrome for Windows and Android. macOS does not support this parameter and instead expands the `chrome_web_icon`. See [Images & Rich Media](/docs/rich-media).
  --small-icon: string # The local name of the small icon to display in the Google Android notification. See [Notification icons](/docs/notification-icons).
  --huawei-small-icon: string # The local name of the small icon to display in the Huawei Android notification. See [Notification icons](/docs/notification-icons).
  --adm-small-icon: string # The local name of the small icon to display in the Amazon Android notification. See [Notification icons](/docs/notification-icons).
  --large-icon: string # The local name or URL of the large icon to display in the Google Android notification. See [Notification icons](/docs/notification-icons).
  --huawei-large-icon: string # The local name or URL of the large icon to display in the Huawei Android notification. See [Notification icons](/docs/notification-icons).
  --adm-large-icon: string # The local name or URL of the large icon to display in the Amazon Android notification. See [Notification icons](/docs/notification-icons).
  --chrome-web-icon: string # The URL of the icon to display in the Chrome web notification. Defaults to the resource set in the OneSignal dashboard. See [Notification icons](/docs/notification-icons).
  --firefox-icon: string # The URL of the icon to display in the Firefox web notification. Defaults to the resource set in the OneSignal dashboard. See [Notification icons](/docs/notification-icons).
  --chrome-web-badge: string # The URL of the icon to display in the Android notification tray for Chrome web notifications. Defaults to the Chrome icon. See [Push](/docs/push#badges).
  --android-channel-id: string # The UUID of the [Android notification channel category](/docs/android-notification-categories) created within your OneSignal app.
  --existing-android-channel-id: string # The UUID of the [Android notification channel category](/docs/android-notification-categories) created within your Android app.
  --huawei-channel-id: string # The UUID of the [Android notification channel category](/docs/android-notification-categories) created within your OneSignal app.
  --huawei-existing-channel-id: string # The UUID of the [Android notification channel category](/docs/android-notification-categories) created within your Huawei app.
  --huawei-category: string@huawei-category-completer # The category you set for notifications sent to Huawei devices. The category chosen must align with an approved [self-classification application](https://developer.huawei.com/consumer/cn/doc/HMSCore-Guides/message-classification-0000001149358835#section1653845862216). Subject to daily send limitations ranging from 2 to 5, depending on the specific [third-level classifications](https://developer.huawei.com/consumer/cn/doc/development/HMSCore-Guides/message-restriction-description-0000001361648361#section199311418515) the message falls under. (default: MARKETING)
  --huawei-msg-type: string@huawei-msg-type-completer # The type of notification being sent to Huawei devices. Options: `message` - (default) For displayable notifications to the user. Notification will be shown even if the app is force quit. If the device is offline it will display the notification when it connects to the internet within the `ttl` timeframe (usually 3 days). Does not support [Confirmed receipt](/docs/confirmed-delivery#huawei), Huawei requires using their dashboard to track this. `data` - used for notifications containing data payloads you intend to process in the background. If the app is force quit, HMS Core will not start the app to process the notification. Supports [Confirmed receipt](/docs/confirmed-delivery#huawei). (default: message)
  --huawei-bi-tag: string # Define a tag for associating messages in a batch delivery, facilitating precise monitoring and analysis of delivery stats. This tag is returned to your server when Huawei's Push Kit sends a message receipt. You can set this parameter to track your push campaigns' performance and optimize your messaging strategy.
  --huawei-badge-class: string # Required for Huawei badge. The fully qualified class name of the app's entry Activity in the format `<package_name>.<ActivityName>` (e.g., `com.example.myapp.MainActivity`). Tells the Huawei system which app icon to apply the badge to. See [Badges](/docs/badges#huawei-badges).
  --huawei-badge-set-num: int # Sets the badge count to this exact number on Huawei devices. Range: 0–99. Set to `0` to clear the badge. If both `huawei_badge_set_num` and `huawei_badge_add_num` are provided, `huawei_badge_set_num` takes priority. Requires EMUI 10.0.0+ and Push SDK 10.1.0+. See [Badges](/docs/badges#huawei-badges). (format: int32)
  --huawei-badge-add-num: int # Increments the existing badge count by this number on Huawei devices. Range: 1–99. If omitted along with `huawei_badge_set_num`, defaults to incrementing by 1. See [Badges](/docs/badges#huawei-badges). (format: int32)
  --priority: int@priority-completer # Set the priority based on the urgency of the message. `10` - High priority. `5` - Normal priority. Recommended and default value is `10`. APNs and FCM use this parameter to determine how quickly a notification is delivered and processed, particularly in power-saving modes. If sending data/background notifications, `5` (Normal priority) is recommended. For details, see [APNs `apns-priority`](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/sending_notification_requests_to_apns) and [FCM `priority`](https://firebase.google.com/docs/cloud-messaging/android/message-priority). (format: int32, default: 10)
  --ios-interruption-level: string@ios-interruption-level-completer # The priority and delivery timing of iOS notifications based on their importance and the urgency with which they should interrupt the user. See [iOS Focus modes and interruption levels](/docs/ios-focus-modes-and-interruption-levels). (default: active)
  --ios-sound: string # The local name of the custom sound file to play when the notification is received instead of the default sound. See [Notification sounds](/docs/notification-sounds).
  --ios-badgeType: string@ios-badgeType-completer # Set or increment the badge count on iOS devices. Use with `ios_badgeCount`. See [Badges](/docs/badges). (default: None)
  --ios-badgeCount: int # Use with `ios_badgeType` to determine the numerical change to your app's badge count. See [Badges](/docs/badges). (format: int32)
  --android-accent-color: string # The ARGB Hex formatted color of the Android small icon background. For Android 8+ use [Android notification channel category](/docs/android-notification-categories) and `android_channel_id`.
  --huawei-accent-color: string # The ARGB Hex formatted color of the Huawei small icon background. For Android 8+ use [Android notification channel category](/docs/android-notification-categories) and `huawei_channel_id`.
  --body-url: string # The `https`URL that opens in the browser when a user interacts with the notification. See [URLs, Links and Deep Links](/docs/links). Supports [Message Personalization](/docs/message-personalization).
  --app-url: string # Similar to the `url` parameter but exclusively targets mobile platforms like iOS, Android. Accepts values other than `https` but must use `your-app-scheme://` protocol.
  --web-url: string # Use with `app_url` if your app and website need different URLs. Accepts URLs with protocol `https://`
  --target-content-identifier: string # Direct the notification to a specific user experience within your app, such as an App Clip, or target a particular window in applications that use multiple scenes. See [Apple's documentation](https://developer.apple.com/documentation/foundation/nsuseractivity/3238062-targetcontentidentifier).
  --buttons: list # Add a maximum of 3 Action Buttons to Android and iOS push notifications. See [Action Buttons](/docs/action-buttons). — item shape: {id: string, text: string, icon?: string}
  --web-buttons: list # Add a maximum of 2 Action Buttons to Chrome web push notifications. See [Action Buttons](/docs/action-buttons). — item shape: {id: string, text: string, url: string}
  --thread-id: string # An ID to group notifications on Apple devices. Notifications with the same identifier are organized together in the notification center.
  --ios-relevance-score: float # A value between `0` and `1`, to sort the notifications from your app. The highest score gets featured in the notification summary. See [iOS Relevance Score](/docs/ios-relevance-score) (format: double)
  --android-group: string # An ID to group notifications on Google Android devices. Notifications with the same identifier are organized together in the notification center.
  --adm-group: string # An ID to group notifications on Amazon Android devices. Notifications with the same identifier are organized together in the notification center.
  --ttl: int # The duration in seconds for which a notification remains valid if the device is offline. Any number between `0` and `2419200` (28 days). Defaults to 3 days. See [Push: Time to Live](/docs/push#time-to-live). (format: int32, default: 259200)
  --collapse-id: string # An ID that replaces older notifications with newer ones that have the same identifier. For mobile push only. See [Push: Collapse ID](/docs/push#collapse-id).
  --web-push-topic: string # An ID that prevents replacement of older notifications with newer ones that have different identifiers. For web push only. See [Push: Web Push Topic](/docs/push#web-push-topic).
  --data: record # Bundle a custom data map within your notification, which is then passed to your app. See [Push: Additional Data](/docs/push#additional-data). (format: json)
  --content-available: oneof<nothing, bool> # Allows for sending data/background notifications to the Android and iOS apps. Set to `true` and omit `contents`. Apple interprets this as `content-available=1`. See [Data & background notifications](/docs/data-notifications).
  --ios-category: string # Enable users to respond directly to a notification without launching the app. The [Category](https://developer.apple.com/documentation/usernotifications/unnotificationcategory) will activate the corresponding [Notification Content Extension](https://developer.apple.com/documentation/usernotificationsui/unnotificationcontentextension/) in your app when the push is interacted with.
  --apns-push-type-override: string # Use only for VoIP notifications. Corresponds to the [`apns-push-type`](https://developer.apple.com/documentation/usernotifications/sending-notification-requests-to-apns#Send-a-POST-request-to-APNs). OneSignal automatically sets this value to `alert` or `background` based on the notification content. Pass `voip` to initiate VoIP calls or alert the user to incoming VoIP calls.
  --isIos: oneof<nothing, bool> # Specifies if the notification should target iOS mobile apps only. Defaults to `true`. If set to `true`, all other platforms are disabled unless explicitly enabled.
  --isAndroid: oneof<nothing, bool> # Specifies if the notification should target Google Android mobile apps only. Defaults to `true`. If set to `true`, all other platforms are disabled unless explicitly enabled.
  --isHuawei: oneof<nothing, bool> # Specifies if the notification should target Huawei mobile apps only. Defaults to `true`. If set to `true`, all other platforms are disabled unless explicitly enabled.
  --isAnyWeb: oneof<nothing, bool> # Specifies if the notification should target web push only. Defaults to `true`. If set to `true`, all other platforms are disabled unless explicitly enabled.
  --isChromeWeb: oneof<nothing, bool> # Specifies if the notification should target Chrome only. Defaults to `true`. If set to `true`, all other platforms are disabled unless explicitly enabled.
  --isFirefox: oneof<nothing, bool> # Specifies if the notification should target Firefox only. Defaults to `true`. If set to `true`, all other platforms are disabled unless explicitly enabled.
  --isSafari: oneof<nothing, bool> # Specifies if the notification should target Safari only. Defaults to `true`. If set to `true`, all other platforms are disabled unless explicitly enabled
  --isWP-WNS: oneof<nothing, bool> # Specifies if the notification should target Windows apps only. Defaults to `true`. If set to `true`, all other platforms are disabled unless explicitly enabled
  --isAdm: oneof<nothing, bool> # Specifies if the notification should target Amazon devices only. Defaults to `true`. If set to `true`, all other platforms are disabled unless explicitly enabled
  --send-after: string # Schedule delivery for a future date/time (in UTC). The format must be valid per the [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) standard and compatible with [`JavaScript’s Date() parser`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/Date#datestring). Example: `2025-09-24T14:00:00-07:00`
  --delayed-option: string # Controls how messages are delivered on a per-user basis: `'timezone'` — Sends at the same local time across time zones. `'last-active'` — Delivers based on each user’s most recent session. Not compatible with [Push Throttling](/docs/throttling). If enabled, set `throttle_rate_per_minute` to `0`.
  --delivery-time-of-day: string # Use with `delayed_option: 'timezone'` to set a consistent local delivery time. Accepted formats: `'9:00AM'` (12-hour), `'21:45'` (24-hour), `'09:45:30'` (HH:mm:ss).
  --throttle-rate-per-minute: float # Overrides the throttle limit set in the OneSignal dashboard settings. Must be enabled through the dashboard. Only available with push notifications. See [Push Throttling](/docs/throttling). If `throttle_rate_per_minute` is set to `0`, then the message will be sent immediately without any rate limiting.
  --enable-frequency-cap: oneof<nothing, bool> # Overrides the frequency cap set in the OneSignal dashboard settings. Must be enabled through the dashboard first. Only available with push notifications. See [Frequency Capping](/docs/frequency-capping). Set to `false` to disable frequency capping.
  --idempotency-key: string # A unique identifier used to prevent duplicate messages from repeat API calls. See [Idempotent notification requests](/reference/idempotent-notification-requests). Any RFC 9562 UUID supported. Valid for 30 days. Previously called `external_id`.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications?c=push")
  let body = {app_id: $app_id, include_aliases: $include_aliases, target_channel: $target_channel, include_subscription_ids: $include_subscription_ids, included_segments: $included_segments, excluded_segments: $excluded_segments, filters: $filters, contents: $contents, headings: $headings, subtitle: $subtitle, name: $name, template_id: $template_id, custom_data: $custom_data, ios_attachments: $ios_attachments, big_picture: $big_picture, huawei_big_picture: $huawei_big_picture, adm_big_picture: $adm_big_picture, chrome_web_image: $chrome_web_image, small_icon: $small_icon, huawei_small_icon: $huawei_small_icon, adm_small_icon: $adm_small_icon, large_icon: $large_icon, huawei_large_icon: $huawei_large_icon, adm_large_icon: $adm_large_icon, chrome_web_icon: $chrome_web_icon, firefox_icon: $firefox_icon, chrome_web_badge: $chrome_web_badge, android_channel_id: $android_channel_id, existing_android_channel_id: $existing_android_channel_id, huawei_channel_id: $huawei_channel_id, huawei_existing_channel_id: $huawei_existing_channel_id, huawei_category: $huawei_category, huawei_msg_type: $huawei_msg_type, huawei_bi_tag: $huawei_bi_tag, huawei_badge_class: $huawei_badge_class, huawei_badge_set_num: $huawei_badge_set_num, huawei_badge_add_num: $huawei_badge_add_num, priority: $priority, ios_interruption_level: $ios_interruption_level, ios_sound: $ios_sound, ios_badgeType: $ios_badgeType, ios_badgeCount: $ios_badgeCount, android_accent_color: $android_accent_color, huawei_accent_color: $huawei_accent_color, url: $body_url, app_url: $app_url, web_url: $web_url, target_content_identifier: $target_content_identifier, buttons: $buttons, web_buttons: $web_buttons, thread_id: $thread_id, ios_relevance_score: $ios_relevance_score, android_group: $android_group, adm_group: $adm_group, ttl: $ttl, collapse_id: $collapse_id, web_push_topic: $web_push_topic, data: $data, content_available: $content_available, ios_category: $ios_category, apns_push_type_override: $apns_push_type_override, isIos: $isIos, isAndroid: $isAndroid, isHuawei: $isHuawei, isAnyWeb: $isAnyWeb, isChromeWeb: $isChromeWeb, isFirefox: $isFirefox, isSafari: $isSafari, isWP_WNS: $isWP_WNS, isAdm: $isAdm, send_after: $send_after, delayed_option: $delayed_option, delivery_time_of_day: $delivery_time_of_day, throttle_rate_per_minute: $throttle_rate_per_minute, enable_frequency_cap: $enable_frequency_cap, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# SMS
#
# POST /notifications?c=sms
# operationId: sms
# --contents shape: {en: string}
# --include_aliases shape: {external_id?: list}
export def "notifications-csms sms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  app_id: string # Your OneSignal App ID in UUID v4 format. See [Keys & IDs](/docs/en/keys-and-ids). (default: YOUR_APP_ID)
  contents: record # The main message body with [language-specific values](/docs/en/multi-language-messaging#supported-languages). Too many characters may result in multiple messages and increased costs. See [SMS](/docs/sms-messaging). Required unless using `template_id`. Supports [Message Personalization](/docs/message-personalization). You can add trackable links to your SMS via the API by including liquid syntax in your message contents. For example: {{'your_url' | track_link}} The liquid syntax block will be replaced with a trackable short link in the following format: 1sgnl.co/XXXX. Using trackable links allows you to see the click through rates of your SMS. — shape: {en: string}
  --include-aliases: record # Target up to 20,000 users by their `external_id`, `onesignal_id`, or your own custom alias. Use with `target_channel` to control the delivery channel. Not compatible with any other targeting parameters like `filters`, `include_subscription_ids`, `included_segments`, or `excluded_segments`. See [Sending messages with the OneSignal API](/reference/create-message#include-aliases). (format: json) — shape: {external_id?: list}
  target_channel: string@target-channel-completer # The targeted delivery channel. Required when using `include_aliases` and `included_segments` for SMS/RCS. Accepts `push`, `email`, or `sms`. (default: sms)
  --include-subscription-ids: list # Target users' specific [subscriptions](/docs/subscriptions) by ID. Include up to 20,000 `subscription_id` per API call. Not compatible with any other targeting parameters like `filters`, `include_aliases`, `included_segments`, or `excluded_segments`. See [Sending messages with the OneSignal API](/reference/create-message).
  --include-phone-numbers: list # Send SMS/MMS to specific users by their phone number in [E.164 format](/docs/sms-setup#what-is-e164-format). Can only be used when sending [SMS/MMS](/reference/sms). Include up to 20,000 phone numbers per API call. If the phone number does not exist within the OneSignal App, then a new SMS Subscription will be created. Not compatible with any other targeting parameters like `filters`, `include_aliases`, `included_segments`, or `excluded_segments`. See [Sending messages with the OneSignal API](/reference/create-message).
  --included-segments: list # Target predefined [Segments](/docs/segmentation). Users that are in multiple segments will only be sent the message once. Can be combined with `excluded_segments`. Requires `target_channel` to be set to `'sms'` or `isSms=true` when sending SMS/RCS. Not compatible with any other targeting parameters like `filters`, `include_aliases`, or `include_subscription_ids`. See [Sending messages with the OneSignal API](/reference/create-message).
  --excluded-segments: list # Exclude users in predefined [Segments](/docs/segmentation). Overrides membership in any segment specified in the `included_segments`. Not compatible with any other targeting parameters like `filters`, `include_aliases`, or `include_subscription_ids`. See [Sending messages with the OneSignal API](/reference/create-message).
  --filters: list # Filters define the segment based on user properties like tags, activity, or location using flexible AND/OR logic. Limited to 200 total entries, including fields and `OR` operators. See [Sending messages with the OneSignal API](/reference/create-message#filters).
  --sms-from: string # The [Messaging Service ID](/docs/en/sms-setup#step-2-create-senders) or phone number used to send the SMS or MMS. Its recommended to use Messaging Service SIDs (e.g., `MGxxxxxxxxxxxxxxx`) but also accepts E.164 phone numbers (e.g., `+12065551234`). Defaults to the sender selected in [SMS Setup](/docs/en/sms-setup). If using [per-sender opt-out](/docs/en/sms-consent-keyword-management), you must use a Messaging Service ID.
  --sms-media-urls: list # URLs for the media files to be sent as MMS. Additional rates apply. `sms_from` must support sending MMS messages. See [SMS](/docs/sms-messaging).
  --name: string # An internal name you set to help organize and track messages. Not shown to recipients. Maximum 128 characters.
  --template-id: string # The template ID in UUID v4 format set for the message if applicable. See [Templates](/docs/templates).
  --custom-data: record # Include user or context-specific data (e.g., cart items, OTPs, links) in a message. Use with `template_id`. See [Message Personalization](/docs/message-personalization). Max size: 2KB (Push/SMS), 10KB (Email).
  --send-after: string # Schedule delivery for a future date/time (in UTC). The format must be valid per the [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) standard and compatible with [`JavaScript’s Date() parser`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/Date#datestring). Example: `2025-09-24T14:00:00-07:00`
  --idempotency-key: string # A unique identifier used to prevent duplicate messages from repeat API calls. See [Idempotent notification requests](/reference/idempotent-notification-requests). Any RFC 9562 UUID supported. Valid for 30 days. Previously called `external_id`.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications?c=sms")
  let body = {app_id: $app_id, contents: $contents, include_aliases: $include_aliases, target_channel: $target_channel, include_subscription_ids: $include_subscription_ids, include_phone_numbers: $include_phone_numbers, included_segments: $included_segments, excluded_segments: $excluded_segments, filters: $filters, sms_from: $sms_from, sms_media_urls: $sms_media_urls, name: $name, template_id: $template_id, custom_data: $custom_data, send_after: $send_after, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Live Activity
#
# POST /apps/{app_id}/live_activities/{activity_id}/notifications
# operationId: update-live-activity-api
# --contents shape: {en: string}
export def "apps-live-activities-notifications update-live-activity-api" [
  app_id: string
  activity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  event: string@event-completer # The action to perform on the Live Activity. Options:`update` - Updates the content of an existing Live Activity without ending it. `end` — Ends the Live Activity and removes it from the user's view. See Apple's developer docs on [Starting and updating Live Activities](https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications).
  event_updates: record # The content used to update a running Live Activity. The object must conform to the `ContentState` interface defined within your app's Live Activity. See [Live Activities developer setup](/docs/live-activities-developer-setup). (format: json)
  name: string # An internal name you set to help organize and track messages. Not shown to recipients. Maximum 128 characters.
  --contents: record # The push message body with [language-specific values](/docs/en/multi-language-messaging#supported-languages). — shape: {en: string}
  --stale-date: int # A Unix timestamp (in seconds) that indicates the date the Live Activity is considered outdated. Once this time is reached, the system updates the Live Activity to [`ActivityState.stale`](https://developer.apple.com/documentation/activitykit/activitystate/stale) at which point you can update the Live Activity to indicate that its content is out of date. (format: int32)
  --dismissal-date: int # A Unix timestamp (in seconds) indicating when the Live Activity should be removed from user's device. Use with the `end` event. If not set, the Live Activity will be dismissed automatically after 4 hours. To dismiss the Live Activity immediately, the user must have allowed the Live Activity first. Then you can set a date that’s in the past — for example, `1663177260`. Alternatively, provide a date within a four-hour window to set a custom dismissal date before the default 4 hour period. See [Apple's documentation](https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications#End-the-Live-Activity-with-a-custom-dismissal-date) for more. (format: int32)
  --priority: int@priority-completer # Set the priority based on the urgency of the message. `10` - High priority. `5` - Normal priority. Apple allows a certain budget of High priority updates per hour. Exceeding the budget may throttle your messages. Apple recommends choosing a mix of priority `5` and `10` to prevent throttling. If your app needs more frequent updates, use `NSSupportsLiveActivitiesFrequentUpdates` entry as directed in [Apple's Developer Docs](https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications#Determine-the-update-frequency). (format: int32)
  --ios-sound: string # The name of a sound file in your app bundle to play when the Live Activity receives an update. If excluded, the system plays the default notification sound. Using the value `"nil"` will silence the sound.
  --ios-relevance-score: float # A value between `0` and `1`. If you start more than one Live Activity for your app, the Live Activity with the highest relevance score appears in the Dynamic Island. If Live Activities have the same relevance score, the system displays the Live Activity that started first. Additionally, the Relevance Score determines the order of your Live Activities on the Lock Screen. (format: double)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/live_activities/($activity_id)/notifications")
  let body = {event: $event, event_updates: $event_updates, name: $name, contents: $contents, stale_date: $stale_date, dismissal_date: $dismissal_date, priority: $priority, ios_sound: $ios_sound, ios_relevance_score: $ios_relevance_score} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View messages
#
# GET /notifications?app_id={app_id}&limit={limit}&offset={offset}&kind={kind}&template_id={template_id}&time_offset={time_offset}
# operationId: view-messages
export def "notifications-app-id-app-id-limit-limit-offset-offset-kind-kind-template-id-template-id-time-offset-time-offset view-messages" [
  app_id: any
  limit: any
  offset: any
  kind: any
  template_id: any
  time_offset: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Your OneSignal App ID in UUID v4 format. See [Keys & IDs](/docs/en/keys-and-ids). (default: YOUR_APP_ID)
  --limit: int # Specifies the maximum number of messages to return in a single query. The maximum and default is **50** messages per request. (format: int32)
  --offset: int # Controls the starting point for the notifications being returned. Default is **0**. Results are returned and sorted in descending order by `queued_at`. (format: int32)
  --kind: int # Specifies which push notifications to return based on how it was created. Use this to segment push by their creation method, allowing for targeted analysis or management of notification types. All push types are returned by default. `0` - Notifications created through the dashboard. `1` - Notifications sent via API calls. `3` - Notifications triggered through automated systems. (format: int32)
  --template-id: string # The template ID in UUID v4 format set for the message if applicable. See [Templates](/docs/templates).
  --time-offset: string # An ISO 8601 formatted timestamp or Base64 integer token (provided in the API response). See [`time_offset` Accepted Values](#time_offset-accepted-values).
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record<total_count: int, time_offset: string, next_time_offset: int, offset: int, limit: int, notifications: table<app_id: string, big_picture: string, canceled: bool, chrome_web_icon: string, chrome_web_image: string, name: string, contents: record, converted: int, data: record, delayed_option: string, delivery_time_of_day: string, remaining: int, errored: int, excluded_segments: list, failed: int, global_image: string, headings: record, id: string, included_segments: list, ios_badgeCount: int, ios_badgeType: string, queued_at: int, send_after: int, completed_at: int, successful: int, received: int, filters: record, template_id: string, url: string, web_url: string, app_url: string, platform_delivery_stats: record, throttle_rate_per_minute: float, fcap_status: string, outcomes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_id" $app_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "template_id" $template_id "scalar") (serialize-qp "time_offset" $time_offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/notifications?app_id=($app_id)&limit=($limit)&offset=($offset)&kind=($kind)&template_id=($template_id)&time_offset=($time_offset)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View message
#
# GET /notifications/{message_id}?app_id={app_id}
# operationId: view-message
export def "notifications view-message" [
  message_id: string
  app_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Your OneSignal App ID in UUID v4 format. See [Keys & IDs](/docs/en/keys-and-ids). (default: YOUR_APP_ID)
  --outcome-names: list # The name and aggregation type of the outcome(s) you want to fetch. Example: `my_outcome.count` or `my_outcome.sum`. For clicks, use `os__click.count`. For confirmed deliveries, use `os__confirmed_delivery.count`. For session duration, use `os__session_duration.count`.
  --outcome-time-range: string@outcome-time-range-completer # Time range for the returned data. Available values: `1h` (1 hour), `1d` (1 day), `1mo` (1 month) (default: 1h)
  --outcome-platforms: string # The platforms in which you want to pull the data represented as the `device_type` integer. (default: 0,1,2,5,8,11,14,17)
  --outcome-attribution: string@outcome-attribution-completer # Attribution type for the outcomes. (default: total)
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record<app_id: string, big_picture: string, canceled: bool, chrome_web_icon: string, chrome_web_image: string, name: string, contents: record<en: string>, converted: int, data: record, delayed_option: string, delivery_time_of_day: string, remaining: int, errored: int, excluded_segments: list<any>, failed: int, global_image: string, headings: record, id: string, included_segments: list<any>, ios_badgeCount: int, ios_badgeType: string, queued_at: int, send_after: int, completed_at: int, successful: int, received: int, filters: record, template_id: string, url: string, web_url: string, app_url: string, platform_delivery_stats: record, throttle_rate_per_minute: float, fcap_status: string, outcomes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_id" $app_id "scalar") (serialize-qp "outcome_names" $outcome_names "multi") (serialize-qp "outcome_time_range" $outcome_time_range "scalar") (serialize-qp "outcome_platforms" $outcome_platforms "scalar") (serialize-qp "outcome_attribution" $outcome_attribution "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/notifications/($message_id)?app_id=($app_id)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel message
#
# DELETE /notifications/{message_id}?app_id={app_id}
# operationId: cancel-message
export def "notifications cancel-message" [
  message_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/($message_id)?app_id=($app_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start Live Activity
#
# POST /apps/{app_id}/activities/activity/{activity_type}
# operationId: start-live-activity
# --include_aliases shape: {external_id?: list}
# --filters item shape: {field: string, key?: string, relation: string, value: string}
# --contents shape: {en: string}
# --headings shape: {en: string}
export def "apps-activities-activity start-live-activity" [
  app_id: string
  activity_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  --include-aliases: record # Target up to 20,000 users by their `external_id`, `onesignal_id`, or your own custom alias. Use with `target_channel` to control the delivery channel. Not compatible with any other targeting parameters like `filters`, `include_subscription_ids`, `included_segments`, or `excluded_segments`. See [Sending messages with the OneSignal API](/reference/create-message#include-aliases). (format: json) — shape: {external_id?: list}
  --include-subscription-ids: list # Target users' specific [subscriptions](/docs/subscriptions) by ID. Include up to 20,000 `subscription_id` per API call. Not compatible with any other targeting parameters like `filters`, `include_aliases`, `included_segments`, or `excluded_segments`. See [Sending messages with the OneSignal API](/reference/create-message).
  --included-segments: list # Target predefined [Segments](/docs/segmentation). Users that are in multiple segments will only be sent the message once. Can be combined with `excluded_segments`. Not compatible with any other targeting parameters like `filters`, `include_aliases`, or `include_subscription_ids`. See [Sending messages with the OneSignal API](/reference/create-message).
  --excluded-segments: list # Exclude users in predefined [Segments](/docs/segmentation). Overrides membership in any segment specified in the `included_segments`. Not compatible with any other targeting parameters like `filters`, `include_aliases`, or `include_subscription_ids`. See [Sending messages with the OneSignal API](/reference/create-message).
  --filters: list # Dynamically target users based on properties like tags, activity, or location using flexible AND/OR logic. Limited to 200 total entries, including fields and `OR` operators. Not compatible with other targeting parameters like `include_aliases`, `include_subscription_ids`, `included_segments`, or `excluded_segments`. See [Sending messages with the OneSignal API](/reference/create-message#filters). — item shape: {field: string, key?: string, relation: string, value: string}
  event: string@event-completer-1 # The action to perform on the Live Activity. This request only supports `start`. (default: start)
  activity_id: string # An identifier you set when starting the Live Activity to uniquely identify it and associated devices with the event. Save this value because it is required for the [Update Live Activity](/reference/update-live-activity) API. Consider using a UUID, CUID, or NanoID for this parameter.
  event_attributes: record # The static data to initialize the Live Activity. See [Live Activities developer setup](/docs/live-activities-developer-setup). (format: json)
  event_updates: record # The content used to update a running Live Activity. The object must conform to the `ContentState` interface defined within your app's Live Activity. See [Live Activities developer setup](/docs/live-activities-developer-setup). (format: json)
  name: string # An internal name you set to help organize and track messages. Not shown to recipients. Maximum 128 characters.
  contents: record # The push message body with [language-specific values](/docs/en/multi-language-messaging#supported-languages). — shape: {en: string}
  headings: record # The push title with [language-specific values](/docs/en/multi-language-messaging#supported-languages). — shape: {en: string}
  --stale-date: int # A Unix timestamp (in seconds) that indicates the date the Live Activity is considered outdated. Once this time is reached, the system updates the Live Activity to [`ActivityState.stale`](https://developer.apple.com/documentation/activitykit/activitystate/stale) at which point you can update the Live Activity to indicate that its content is out of date. (format: int32)
  --priority: int@priority-completer # Set the priority based on the urgency of the message. `10` - High priority. `5` - Normal priority. Apple allows a certain budget of High priority updates per hour. Exceeding the budget may throttle your messages. Apple recommends choosing a mix of priority `5` and `10` to prevent throttling. If your app needs more frequent updates, use `NSSupportsLiveActivitiesFrequentUpdates` entry as directed in [Apple's Developer Docs](https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications#Determine-the-update-frequency). (format: int32)
  --ios-sound: string # The name of a sound file in your app bundle to play when the Live Activity receives an update. If excluded, the system plays the default notification sound. Using the value `"nil"` will silence the sound.
  --ios-relevance-score: float # A value between `0` and `1`. If you start more than one Live Activity for your app, the Live Activity with the highest relevance score appears in the Dynamic Island. If Live Activities have the same relevance score, the system displays the Live Activity that started first. Additionally, the Relevance Score determines the order of your Live Activities on the Lock Screen. (format: double)
  --idempotency-key: string # A unique identifier used to prevent duplicate messages from repeat API calls. See [Idempotent notification requests](/reference/idempotent-notification-requests). Any RFC 9562 UUID supported. Valid for 30 days. Previously called `external_id`.
]: any -> record<notification_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/activities/activity/($activity_type)")
  let body = {include_aliases: $include_aliases, include_subscription_ids: $include_subscription_ids, included_segments: $included_segments, excluded_segments: $excluded_segments, filters: $filters, event: $event, activity_id: $activity_id, event_attributes: $event_attributes, event_updates: $event_updates, name: $name, contents: $contents, headings: $headings, stale_date: $stale_date, priority: $priority, ios_sound: $ios_sound, ios_relevance_score: $ios_relevance_score, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Copy template to another app
#
# POST /templates/{template_id}/copy_to_app?app_id={app_id}
# operationId: copy-template-to-another-app
export def "templates-copy-to-app-app-id-app-id copy-template-to-another-app" [
  template_id: string
  app_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Your OneSignal App ID in UUID v4 format. See [Keys & IDs](/docs/en/keys-and-ids). (default: YOUR_APP_ID)
  --Authorization: string # Your Organization API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  target_app_id: string # Specifies the OneSignal app ID that the template will be copied to. Cannot be the same as the `app_id`. (default: YOUR_OTHER_APP_ID)
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_id" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/($template_id)/copy_to_app?app_id=($app_id)" $qp)
  let body = {target_app_id: $target_app_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create inbox broadcast message
#
# POST /apps/{app_id}/inbox
# operationId: create-inbox-broadcast-message
# --contents shape: {en: string}
# --subjects shape: {en?: string}
# --data shape: {abc?: string, foo?: string}
# --custom_data shape: {key?: string}
export def "apps-inbox create-inbox-broadcast-message" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  --name: string # An internal name you set to help organize and track messages. Not shown to recipients. Maximum 128 characters.
  --img-url: string # The URL to an image that is associated with this message.
  --contents: record # The main message body with [language-specific values](/docs/en/multi-language-messaging#supported-languages). Supports [Message Personalization](/docs/message-personalization). — shape: {en: string}
  --subjects: record # The message's localized subjects, as a map of language codes to subjects. Each entry must have a language code as its key, mapped to the localized subject you would like users to receive for that language. Any language codes used must also be used within the contents property. This field supports tag substitutions and liquid syntax. Example: `{"en": "English Title", "es": "Spanish Title"}` — shape: {en?: string}
  --send-after: string # Schedule delivery for a future date/time (in UTC). The format must be valid per the [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) standard and compatible with [`JavaScript’s Date() parser`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/Date#datestring). Example: `2025-09-24T14:00:00-07:00`
  --data: record # This is an arbitrary string (which can contain encoded JSON if desired) that is passed through to messages. This is meant for use in client applications and is not processed in any special way by OneSignal. — shape: {abc?: string, foo?: string}
  --custom-data: record # Include user or context-specific data (e.g., cart items, OTPs, links) in a message. Use with `template_id`. See [Message Personalization](/docs/message-personalization). Max size: 2KB (Push/SMS), 10KB (Email). — shape: {key?: string}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/inbox")
  let body = {name: $name, img_url: $img_url, contents: $contents, subjects: $subjects, send_after: $send_after, data: $data, custom_data: $custom_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View broadcasts
#
# GET /apps/{app_id}/inbox?last_broadcast_id={broadcast_id}&limit={number}
# operationId: view-broadcasts
export def "apps-inbox-last-broadcast-id-broadcast-id-limit-number view-broadcasts" [
  app_id: string
  broadcast_id: any
  number: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-broadcast-id: string # The exclusive lower bound of broadcasts to retrieve
  --limit: int # The number of broadcasts to retrieve. (format: int32)
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "last_broadcast_id" $last_broadcast_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_id)/inbox?last_broadcast_id=($broadcast_id)&limit=($number)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View user broadcasts
#
# GET /apps/{app_id}/users/by/{alias_label}/{alias_id}/inbox?last_message_id={message_id}
# operationId: view-user-inbox-messages
export def "apps-users-by-inbox-last-message-id-message-id view-user-inbox-messages" [
  app_id: string
  alias_label: string
  alias_id: string
  message_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-message-id: string # The exclusive lower bound of broadcasts to retrieve.
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "last_message_id" $last_message_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_id)/users/by/($alias_label)/($alias_id)/inbox?last_message_id=($message_id)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk update or delete message state
#
# PATCH /apps/{app_id}/users/by/{alias_label}/{alias_id}/inbox?last_message_id={message_id}
# operationId: bulk-update-or-delete-message-state
export def "apps-users-by-inbox-last-message-id-message-id bulk-update-or-delete-message-state" [
  app_id: string
  alias_label: string
  alias_id: string
  message_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-message-id: string # The inclusive upper bound of messages to update.
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  --is-read: oneof<nothing, bool> # Indicates whether to mark message(s) as read.
  --is-deleted: oneof<nothing, bool> # Indicates whether to mark message(s) as deleted.
  --is-opened: oneof<nothing, bool> # Indicates whether to mark message(s) as opened.
]: any -> record<count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "last_message_id" $last_message_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_id)/users/by/($alias_label)/($alias_id)/inbox?last_message_id=($message_id)" $qp)
  let body = {is_read: $is_read, is_deleted: $is_deleted, is_opened: $is_opened} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View user unread message count
#
# GET /apps/{app_id}/users/by/{alias_label}/{alias_id}/inbox/unread_count
# operationId: view-user-unread-message-count
export def "apps-users-by-inbox-unread-count view-user-unread-message-count" [
  app_id: string
  alias_label: string
  alias_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/users/by/($alias_label)/($alias_id)/inbox/unread_count")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update message state
#
# PATCH /apps/{app_id}/users/by/{alias_label}/{alias_id}/inbox/{message_id}
# operationId: update-message-state
export def "apps-users-by-inbox update-message-state" [
  app_id: string
  alias_label: string
  alias_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your App API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  --is-read: oneof<nothing, bool> # Indicates whether to mark message(s) as read.
  --is-deleted: oneof<nothing, bool> # Indicates whether to mark message(s) as deleted.
  --is-opened: oneof<nothing, bool> # Indicates whether to mark message(s) as opened.
]: any -> record<count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/users/by/($alias_label)/($alias_id)/inbox/($message_id)")
  let body = {is_read: $is_read, is_deleted: $is_deleted, is_opened: $is_opened} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View API keys
#
# GET /apps/{app_id}/auth/tokens
# operationId: view-api-keys
export def "apps-auth-tokens view-api-keys" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --Authorization: string # Your Organization API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record<tokens: table<token_id: string, name: string, ip_allowlist_mode: string, ip_allowlist: list, created_at: string, updated_at: string, formatted_token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/auth/tokens")
  let extra_headers = {"Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create API key
#
# POST /apps/{app_id}/auth/tokens
# operationId: create-api-key
export def "apps-auth-tokens create-api-key" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --Authorization: string # Your Organization API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  name: string # An internal name you set to help organize and track API keys (Rich Authentication Tokens). Maximum 128 characters.
  --ip-allowlist-mode: string@ip-allowlist-mode-completer # Defaults to `disabled`, can be set to `explicit`. If set to `explicit`, a list of network addresses in the form of CIDRs has to be specified in the `ip_allowlist` parameter.
  --ip-allowlist: list # An array of allowed networks in CIDRs notation. Only IPs in those ranges will be permitted to use the API key.
]: any -> record<token_id: string, name: string, ip_allowlist_mode: string, ip_allowlist: list<string>, created_at: string, updated_at: string, formatted_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/auth/tokens")
  let body = {name: $name, ip_allowlist_mode: $ip_allowlist_mode, ip_allowlist: $ip_allowlist} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete API key
#
# DELETE /apps/{app_id}/auth/tokens/{token_id}
# operationId: delete-api-key
export def "apps-auth-tokens delete-api-key" [
  app_id: string
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --Authorization: string # Your Organization API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/auth/tokens/($token_id)")
  let extra_headers = {"Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update API key
#
# PATCH /apps/{app_id}/auth/tokens/{token_id}
# operationId: update-api-key
export def "apps-auth-tokens update-api-key" [
  app_id: string
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --Authorization: string # Your Organization's API key found in [Organizations > Keys & IDs](/docs/en/keys-and-ids).
  --name: string # An internal name you set to help organize and track API keys (Rich Authentication Tokens). Maximum 128 characters.
  --ip-allowlist-mode: string@ip-allowlist-mode-completer # Defaults to `disabled`, can be set to `explicit`. If set to `explicit`, a list of network addresses in the form of CIDRs has to be specified in the `ip_allowlist` parameter.
  --ip-allowlist: list # An array of allowed networks in CIDRs notation. Only IPs in those ranges will be permitted to use the API key.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/auth/tokens/($token_id)")
  let body = {name: $name, ip_allowlist_mode: $ip_allowlist_mode, ip_allowlist: $ip_allowlist} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Rotate API key
#
# POST /apps/{app_id}/auth/tokens/{token_id}/rotate
# operationId: rotate-api-key
export def "apps-auth-tokens-rotate rotate-api-key" [
  app_id: string
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --Authorization: string # Your Organization API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record<token_id: string, name: string, ip_allowlist_mode: string, ip_allowlist: list<string>, created_at: string, updated_at: string, formatted_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/auth/tokens/($token_id)/rotate")
  let extra_headers = {"Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Custom Events
#
# POST /apps/{app_id}/custom_events
# operationId: create-custom-events
# --events item shape: {name: string, external_id?: string, onesignal_id?: string, timestamp?: string, idempotency_key?: string, properties?: record}
export def "apps-custom-events create-custom-events" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Your app API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
  events: list # Array of event objects to be recorded. Maximum size for each event is `2024` bytes. Maximum size of request is `1` MB. — item shape: {name: string, external_id?: string, onesignal_id?: string, timestamp?: string, idempotency_key?: string, properties?: record}
]: any -> record<errors: table<event_user_id: string, event_id: string, error: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_id)/custom_events")
  let body = {events: $events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List audit logs
#
# GET /organizations/{organization_id}/audit_logs
# operationId: list-audit-logs
export def "organizations-audit-logs list-audit-logs" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-time: string # Start of the time range in ISO 8601 format (e.g. `2026-02-01T00:00:00Z`). Required unless `cursor` is provided. Must be within the last 90 days and no earlier than `2026-02-18T00:00:00Z`.
  --end-time: string # End of the time range in ISO 8601 format. Defaults to the current time. Must be after `start_time`.
  --cursor: string # Pagination cursor returned in a previous response as `next_cursor`. When provided, `start_time` and `end_time` are ignored.
  --limit: int # Maximum number of events to return per page. Minimum `1`, maximum `100`. Values outside this range are clamped automatically. (default: 100)
  --app-ids: list # Filter events by app UUID. Accepts up to 10 values. Org-level events are always included. Repeat the parameter for multiple values: `app_ids=uuid1&app_ids=uuid2`.
  --actions: list # Filter by action type (e.g. `notification.sent`, `segment.created`). Accepts up to 20 values. Repeat the parameter for multiple values: `actions=notification.sent&actions=segment.created`.
  --actor-ids: list # Filter by actor UUID (the user or service that performed the action). Accepts up to 10 values. Repeat the parameter for multiple values: `actor_ids=uuid1&actor_ids=uuid2`.
  --actor-emails: list # Filter by actor email address. Accepts up to 10 values. Repeat the parameter for multiple values: `actor_emails=a@example.com&actor_emails=b@example.com`.
  --target-types: list # Filter by the type of resource the action was performed on (e.g. `notification`, `segment`, `journey`). Accepts up to 10 values. Repeat the parameter for multiple values: `target_types=notification&target_types=segment`.
  --target-ids: list # Filter by the UUID of the resource the action was performed on. Accepts up to 10 values. Repeat the parameter for multiple values: `target_ids=uuid1&target_ids=uuid2`.
  --ip-addresses: list # Filter by the IP address the action originated from. Accepts up to 10 values. Repeat the parameter for multiple values: `ip_addresses=203.0.113.1&ip_addresses=203.0.113.2`.
  --Authorization: string # Your Organization API key with prefix `Key `. See [Keys & IDs](/docs/en/keys-and-ids).
]: nothing -> record<audit_logs: table<id: string, organization_id: string, app_id: string, action: string, occurred_at: string, version: int, actor: record, targets: list, context: record, metadata: record>, has_more: bool, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "app_ids" $app_ids "multi") (serialize-qp "actions" $actions "multi") (serialize-qp "actor_ids" $actor_ids "multi") (serialize-qp "actor_emails" $actor_emails "multi") (serialize-qp "target_types" $target_types "multi") (serialize-qp "target_ids" $target_ids "multi") (serialize-qp "ip_addresses" $ip_addresses "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/audit_logs" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
