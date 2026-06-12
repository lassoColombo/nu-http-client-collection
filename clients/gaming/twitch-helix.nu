# Auto-generated client for Twitch API Swagger UI (Unofficial) vhelix
# Source: https://raw.githubusercontent.com/DmitryScaletta/twitch-api-swagger/main/openapi.json
# Auth: --token flag or $env.TWITCH_API_SWAGGER_UI_UNOFFICIAL_TOKEN

const BASE_URL = "https://api.twitch.tv/helix"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWITCH_API_SWAGGER_UI_UNOFFICIAL_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.twitch.tv/helix"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["overview_v2"] }
def period-completer [] { ["all" "day" "month" "week" "year"] }
def status-completer [] { ["CANCELED" "FULFILLED" "UNFULFILLED"] }
def sort-completer [] { ["NEWEST" "OLDEST"] }
def status-completer-1 [] { ["CANCELED" "FULFILLED"] }
def non-moderator-chat-delay-duration-completer [] { ["2" "4" "6"] }
def color-completer [] { ["blue" "green" "orange" "primary" "purple"] }
def color-completer-1 [] { ["blue" "blue_violet" "cadet_blue" "chocolate" "coral" "dodger_blue" "firebrick" "golden_rod" "green" "hot_pink" "orange_red" "red" "sea_green" "spring_green" "yellow_green"] }
def fulfillment-status-completer [] { ["CLAIMED" "FULFILLED"] }
def segment-completer [] { ["broadcaster" "developer" "global"] }
def type-completer-1 [] { ["automod.message.hold" "automod.message.update" "automod.settings.update" "automod.terms.update" "channel.ad_break.begin" "channel.ban" "channel.bits.use" "channel.channel_points_automatic_reward_redemption.add" "channel.channel_points_custom_reward.add" "channel.channel_points_custom_reward.remove" "channel.channel_points_custom_reward.update" "channel.channel_points_custom_reward_redemption.add" "channel.channel_points_custom_reward_redemption.update" "channel.charity_campaign.donate" "channel.charity_campaign.progress" "channel.charity_campaign.start" "channel.charity_campaign.stop" "channel.chat.clear" "channel.chat.clear_user_messages" "channel.chat.message" "channel.chat.message_delete" "channel.chat.notification" "channel.chat.user_message_hold" "channel.chat.user_message_update" "channel.chat_settings.update" "channel.cheer" "channel.follow" "channel.goal.begin" "channel.goal.end" "channel.goal.progress" "channel.guest_star_guest.update" "channel.guest_star_session.begin" "channel.guest_star_session.end" "channel.guest_star_settings.update" "channel.hype_train.begin" "channel.hype_train.end" "channel.hype_train.progress" "channel.moderate" "channel.moderator.add" "channel.moderator.remove" "channel.poll.begin" "channel.poll.end" "channel.poll.progress" "channel.prediction.begin" "channel.prediction.end" "channel.prediction.lock" "channel.prediction.progress" "channel.raid" "channel.shared_chat.begin" "channel.shared_chat.end" "channel.shared_chat.update" "channel.shield_mode.begin" "channel.shield_mode.end" "channel.shoutout.create" "channel.shoutout.receive" "channel.subscribe" "channel.subscription.end" "channel.subscription.gift" "channel.subscription.message" "channel.suspicious_user.message" "channel.suspicious_user.update" "channel.unban" "channel.unban_request.create" "channel.unban_request.resolve" "channel.update" "channel.vip.add" "channel.vip.remove" "channel.warning.acknowledge" "channel.warning.send" "conduit.shard.disabled" "drop.entitlement.grant" "extension.bits_transaction.create" "stream.offline" "stream.online" "user.authorization.grant" "user.authorization.revoke" "user.update" "user.whisper.message"] }
def status-completer-2 [] { ["authorization_revoked" "beta_maintenance" "chat_user_banned" "enabled" "moderator_removed" "notification_failures_exceeded" "user_removed" "version_removed" "webhook_callback_verification_failed" "webhook_callback_verification_pending" "websocket_connection_unused" "websocket_disconnected" "websocket_failed_ping_pong" "websocket_failed_to_reconnect" "websocket_internal_error" "websocket_network_error" "websocket_network_timeout" "websocket_received_inbound_traffic"] }
def group-layout-completer [] { ["HORIZONTAL_LAYOUT" "SCREENSHARE_LAYOUT" "TILED_LAYOUT" "VERTICAL_LAYOUT"] }
def action-completer [] { ["ALLOW" "DENY"] }
def status-completer-3 [] { ["ACTIVE_MONITORING" "RESTRICTED"] }
def status-completer-4 [] { ["ARCHIVED" "TERMINATED"] }
def status-completer-5 [] { ["CANCELED" "LOCKED" "RESOLVED"] }
def type-completer-2 [] { ["all" "live"] }
def source-context-completer [] { ["chat" "whisper"] }
def reason-completer [] { ["harassment" "other" "spam"] }
def period-completer-1 [] { ["all" "day" "month" "week"] }
def sort-completer-1 [] { ["time" "trending" "views"] }
def type-completer-3 [] { ["all" "archive" "highlight" "upload"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "channels-commercial start-commercial" } } | get name | first)
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

# Starts a commercial on the specified channel.
#
# POST /channels/commercial
# Docs: https://dev.twitch.tv/docs/api/reference#start-commercial — Start Commercial
# operationId: start-commercial
export def "channels-commercial start-commercial" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  broadcaster_id: string # The ID of the partner or affiliate broadcaster that wants to run the commercial. This ID must match the user ID found in the OAuth token.
  length: int # The length of the commercial to run, in seconds. Twitch tries to serve a commercial that’s the requested length, but it may be shorter or longer. The maximum length you should request is 180 seconds. (format: int32)
]: any -> record<data: table<length: int, message: string, retry_after: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/commercial")
  let body = {broadcaster_id: $broadcaster_id, length: $length} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns ad schedule related information.
#
# GET /channels/ads
# Docs: https://dev.twitch.tv/docs/api/reference#get-ad-schedule — Get Ad Schedule
# operationId: get-ad-schedule
export def "channels-ads get-ad-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # Provided `broadcaster_id` must match the `user_id` in the auth token.
]: nothing -> record<data: table<snooze_count: int, snooze_refresh_at: int, next_ad_at: int, duration: int, last_ad_at: int, preroll_free_time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels/ads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pushes back the timestamp of the upcoming automatic mid-roll ad by 5 minutes.
#
# POST /channels/ads/schedule/snooze
# Docs: https://dev.twitch.tv/docs/api/reference#snooze-next-ad — Snooze Next Ad
# operationId: snooze-next-ad
export def "channels-ads-schedule-snooze snooze-next-ad" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # Provided `broadcaster_id` must match the `user_id` in the auth token.
]: nothing -> record<data: table<snooze_count: int, snooze_refresh_at: int, next_ad_at: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels/ads/schedule/snooze" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an analytics report for one or more extensions.
#
# GET /analytics/extensions
# Docs: https://dev.twitch.tv/docs/api/reference#get-extension-analytics — Get Extension Analytics
# operationId: get-extension-analytics
export def "analytics-extensions get-extension-analytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --extension-id: string # The extension's client ID. If specified, the response contains a report for the specified extension. If not specified, the response includes a report for each extension that the authenticated user owns.
  --type: string@type-completer # The type of analytics report to get. Possible values are:      * overview\_v2
  --started-at: string # The reporting window's start date, in RFC3339 format. Set the time portion to zeroes (for example, 2021-10-22T00:00:00Z).      The start date must be on or after January 31, 2018\. If you specify an earlier date, the API ignores it and uses January 31, 2018\. If you specify a start date, you must specify an end date. If you don't specify a start and end date, the report includes all available data since January 31, 2018.      The report contains one row of data for each day in the reporting window. (format: date-time)
  --ended-at: string # The reporting window's end date, in RFC3339 format. Set the time portion to zeroes (for example, 2021-10-27T00:00:00Z). The report is inclusive of the end date.      Specify an end date only if you provide a start date. Because it can take up to two days for the data to be available, you must specify an end date that's earlier than today minus one to two days. If not, the API ignores your end date and uses an end date that is today minus one to two days. (format: date-time)
  --first: int # The maximum number of report URLs to return per page in the response. The minimum page size is 1 URL per page and the maximum is 100 URLs per page. The default is 20.      **NOTE**: While you may specify a maximum value of 100, the response will contain at most 20 URLs per page. (format: int32)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)      This parameter is ignored if the _extension\_id_ parameter is set.
]: nothing -> record<data: table<extension_id: string, URL: string, type: string, date_range: record>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extension_id" $extension_id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "started_at" $started_at "scalar") (serialize-qp "ended_at" $ended_at "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/analytics/extensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an analytics report for one or more games.
#
# GET /analytics/games
# Docs: https://dev.twitch.tv/docs/api/reference#get-game-analytics — Get Game Analytics
# operationId: get-game-analytics
export def "analytics-games get-game-analytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --game-id: string # The game’s client ID. If specified, the response contains a report for the specified game. If not specified, the response includes a report for each of the authenticated user’s games.
  --type: string@type-completer # The type of analytics report to get. Possible values are:      * overview\_v2
  --started-at: string # The reporting window’s start date, in RFC3339 format. Set the time portion to zeroes (for example, 2021-10-22T00:00:00Z). If you specify a start date, you must specify an end date.      The start date must be within one year of today’s date. If you specify an earlier date, the API ignores it and uses a date that’s one year prior to today’s date. If you don’t specify a start and end date, the report includes all available data for the last 365 days from today.      The report contains one row of data for each day in the reporting window. (format: date-time)
  --ended-at: string # The reporting window’s end date, in RFC3339 format. Set the time portion to zeroes (for example, 2021-10-22T00:00:00Z). The report is inclusive of the end date.      Specify an end date only if you provide a start date. Because it can take up to two days for the data to be available, you must specify an end date that’s earlier than today minus one to two days. If not, the API ignores your end date and uses an end date that is today minus one to two days. (format: date-time)
  --first: int # The maximum number of report URLs to return per page in the response. The minimum page size is 1 URL per page and the maximum is 100 URLs per page. The default is 20.      **NOTE**: While you may specify a maximum value of 100, the response will contain at most 20 URLs per page. (format: int32)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)      This parameter is ignored if _game\_id_ parameter is set.
]: nothing -> record<data: table<game_id: string, URL: string, type: string, date_range: record>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "game_id" $game_id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "started_at" $started_at "scalar") (serialize-qp "ended_at" $ended_at "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/analytics/games" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Bits leaderboard for the authenticated broadcaster.
#
# GET /bits/leaderboard
# Docs: https://dev.twitch.tv/docs/api/reference#get-bits-leaderboard — Get Bits Leaderboard
# operationId: get-bits-leaderboard
export def "bits-leaderboard get-bits-leaderboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # The number of results to return. The minimum count is 1 and the maximum is 100\. The default is 10. (format: int32)
  --period: string@period-completer # The time period over which data is aggregated (uses the PST time zone). Possible values are:      * day — A day spans from 00:00:00 on the day specified in _started\_at_ and runs through 00:00:00 of the next day. * week — A week spans from 00:00:00 on the Monday of the week specified in _started\_at_ and runs through 00:00:00 of the next Monday. * month — A month spans from 00:00:00 on the first day of the month specified in _started\_at_ and runs through 00:00:00 of the first day of the next month. * year — A year spans from 00:00:00 on the first day of the year specified in _started\_at_ and runs through 00:00:00 of the first day of the next year. * all — Default. The lifetime of the broadcaster's channel.
  --started-at: string # The start date, in RFC3339 format, used for determining the aggregation period. Specify this parameter only if you specify the _period_ query parameter. The start date is ignored if _period_ is all.      Note that the date is converted to PST before being used, so if you set the start time to `2022-01-01T00:00:00.0Z` and _period_ to month, the actual reporting period is December 2021, not January 2022\. If you want the reporting period to be January 2022, you must set the start time to `2022-01-01T08:00:00.0Z` or `2022-01-01T00:00:00.0-08:00`.      If your start date uses the ‘+’ offset operator (for example, `2022-01-01T00:00:00.0+05:00`), you must URL encode the start date. (format: date-time)
  --user-id: string # An ID that identifies a user that cheered bits in the channel. If _count_ is greater than 1, the response may include users ranked above and below the specified user. To get the leaderboard’s top leaders, don’t specify a user ID.
]: nothing -> record<data: table<user_id: string, user_login: string, user_name: string, rank: int, score: int>, date_range: record<started_at: string, ended_at: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "started_at" $started_at "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bits/leaderboard" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of Cheermotes that users can use to cheer Bits.
#
# GET /bits/cheermotes
# Docs: https://dev.twitch.tv/docs/api/reference#get-cheermotes — Get Cheermotes
# operationId: get-cheermotes
export def "bits-cheermotes get-cheermotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose custom Cheermotes you want to get. Specify the broadcaster’s ID if you want to include the broadcaster’s Cheermotes in the response (not all broadcasters upload Cheermotes). If not specified, the response contains only global Cheermotes.      If the broadcaster uploaded Cheermotes, the `type` field in the response is set to **channel\_custom**.
]: nothing -> record<data: table<prefix: string, tiers: list, type: string, order: int, last_updated: string, is_charitable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bits/cheermotes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an extension’s list of transactions.
#
# GET /extensions/transactions
# Docs: https://dev.twitch.tv/docs/api/reference#get-extension-transactions — Get Extension Transactions
# operationId: get-extension-transactions
export def "extensions-transactions get-extension-transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --extension-id: string # The ID of the extension whose list of transactions you want to get.
  --id: list # A transaction ID used to filter the list of transactions. Specify this parameter for each transaction you want to get. For example, `id=1234&id=5678`. You may specify a maximum of 100 IDs.
  --first: int # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100 items per page. The default is 20. (format: int32)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<id: string, timestamp: string, broadcaster_id: string, broadcaster_login: string, broadcaster_name: string, user_id: string, user_login: string, user_name: string, product_type: string, product_data: record>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extension_id" $extension_id "scalar") (serialize-qp "id" $id "multi") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extensions/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about one or more channels.
#
# GET /channels
# Docs: https://dev.twitch.tv/docs/api/reference#get-channel-information — Get Channel Information
# operationId: get-channel-information
export def "channels get-channel-information" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: list # The ID of the broadcaster whose channel you want to get. To specify more than one ID, include this parameter for each broadcaster you want to get. For example, `broadcaster_id=1234&broadcaster_id=5678`. You may specify a maximum of 100 IDs. The API ignores duplicate IDs and IDs that are not found.
]: nothing -> record<data: table<broadcaster_id: string, broadcaster_login: string, broadcaster_name: string, broadcaster_language: string, game_name: string, game_id: string, title: string, delay: int, tags: list, content_classification_labels: list, is_branded_content: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a channel’s properties.
#
# PATCH /channels
# Docs: https://dev.twitch.tv/docs/api/reference#modify-channel-information — Modify Channel Information
# operationId: modify-channel-information
# --content_classification_labels item shape: {id: "DebatedSocialIssuesAndPolitics"|"DrugsIntoxication"|"SexualThemes"|"ViolentGraphic"|"Gambling"|"ProfanityVulgarity", is_enabled: bool}
export def "channels modify-channel-information" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose channel you want to update. This ID must match the user ID in the user access token.
  --game-id: string # The ID of the game that the user plays. The game is not updated if the ID isn’t a game ID that Twitch recognizes. To unset this field, use “0” or “” (an empty string).
  --broadcaster-language: string # The user’s preferred language. Set the value to an ISO 639-1 two-letter language code (for example, _en_ for English). Set to “other” if the user’s preferred language is not a Twitch supported language. The language isn’t updated if the language code isn’t a Twitch supported language.
  --title: string # The title of the user’s stream. You may not set this field to an empty string.
  --delay: int # The number of seconds you want your broadcast buffered before streaming it live. The delay helps ensure fairness during competitive play. Only users with Partner status may set this field. The maximum delay is 900 seconds (15 minutes). (format: int32)
  --tags: list # A list of channel-defined tags to apply to the channel. To remove all tags from the channel, set tags to an empty array. Tags help identify the content that the channel streams. [Learn More](https://help.twitch.tv/s/article/guide-to-tags)      A channel may specify a maximum of 10 tags. Each tag is limited to a maximum of 25 characters and may not be an empty string or contain spaces or special characters. Tags are case insensitive. For readability, consider using camelCasing or PascalCasing.
  --content-classification-labels: list # List of labels that should be set as the Channel’s CCLs. — item shape: {id: "DebatedSocialIssuesAndPolitics"|"DrugsIntoxication"|"SexualThemes"|"ViolentGraphic"|"Gambling"|"ProfanityVulgarity", is_enabled: bool}
  --is-branded-content: oneof<nothing, bool> # Boolean flag indicating if the channel has branded content.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels" $qp)
  let body = {game_id: $game_id, broadcaster_language: $broadcaster_language, title: $title, delay: $delay, tags: $tags, content_classification_labels: $content_classification_labels, is_branded_content: $is_branded_content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the broadcaster’s list editors.
#
# GET /channels/editors
# Docs: https://dev.twitch.tv/docs/api/reference#get-channel-editors — Get Channel Editors
# operationId: get-channel-editors
export def "channels-editors get-channel-editors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that owns the channel. This ID must match the user ID in the access token.
]: nothing -> record<data: table<user_id: string, user_name: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels/editors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of broadcasters that the specified user follows. You can also use this endpoint to see whether a user follows a specific broadcaster.
#
# GET /channels/followed
# Docs: https://dev.twitch.tv/docs/api/reference#get-followed-channels — Get Followed Channels
# operationId: get-followed-channels
export def "channels-followed get-followed-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # A user’s ID. Returns the list of broadcasters that this user follows. This ID must match the user ID in the user OAuth token.
  --broadcaster-id: string # A broadcaster’s ID. Use this parameter to see whether the user follows this broadcaster. If specified, the response contains this broadcaster if the user follows them. If not specified, the response contains all broadcasters that the user follows.
  --first: int # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100\. The default is 20. (format: int32)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read more](https://dev.twitch.tv/docs/api/guide#pagination).
]: nothing -> record<data: table<broadcaster_id: string, broadcaster_login: string, broadcaster_name: string, followed_at: string>, pagination: record<cursor: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels/followed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of users that follow the specified broadcaster. You can also use this endpoint to see whether a specific user follows the broadcaster.
#
# GET /channels/followers
# Docs: https://dev.twitch.tv/docs/api/reference#get-channel-followers — Get Channel Followers
# operationId: get-channel-followers
export def "channels-followers get-channel-followers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # A user’s ID. Use this parameter to see whether the user follows this broadcaster. If specified, the response contains this user if they follow the broadcaster. If not specified, the response contains all users that follow the broadcaster.      Using this parameter requires both a user access token with the **moderator:read:followers** scope and the user ID in the access token match the broadcaster\_id or be the user ID for a moderator of the specified broadcaster.
  --broadcaster-id: string # The broadcaster’s ID. Returns the list of users that follow this broadcaster.
  --first: int # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100\. The default is 20. (format: int32)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read more](https://dev.twitch.tv/docs/api/guide#pagination).
]: nothing -> record<data: table<followed_at: string, user_id: string, user_login: string, user_name: string>, pagination: record<cursor: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels/followers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Custom Reward in the broadcaster’s channel.
#
# POST /channel_points/custom_rewards
# Docs: https://dev.twitch.tv/docs/api/reference#create-custom-rewards — Create Custom Rewards
# operationId: create-custom-rewards
export def "channel-points-custom-rewards create-custom-rewards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster to add the custom reward to. This ID must match the user ID found in the OAuth token.
  title: string # The custom reward’s title. The title may contain a maximum of 45 characters and it must be unique amongst all of the broadcaster’s custom rewards.
  cost: int # The cost of the reward, in Channel Points. The minimum is 1 point. (format: int64)
  --prompt: string # The prompt shown to the viewer when they redeem the reward. Specify a prompt if `is_user_input_required` is **true**. The prompt is limited to a maximum of 200 characters.
  --is-enabled: oneof<nothing, bool> # A Boolean value that determines whether the reward is enabled. Viewers see only enabled rewards. The default is **true**.
  --background-color: string # The background color to use for the reward. Specify the color using Hex format (for example, #9147FF).
  --is-user-input-required: oneof<nothing, bool> # A Boolean value that determines whether the user needs to enter information when redeeming the reward. See the `prompt` field. The default is **false**.
  --is-max-per-stream-enabled: oneof<nothing, bool> # A Boolean value that determines whether to limit the maximum number of redemptions allowed per live stream (see the `max_per_stream` field). The default is **false**.
  --max-per-stream: int # The maximum number of redemptions allowed per live stream. Applied only if `is_max_per_stream_enabled` is **true**. The minimum value is 1. (format: int32)
  --is-max-per-user-per-stream-enabled: oneof<nothing, bool> # A Boolean value that determines whether to limit the maximum number of redemptions allowed per user per stream (see the `max_per_user_per_stream` field). The default is **false**.
  --max-per-user-per-stream: int # The maximum number of redemptions allowed per user per stream. Applied only if `is_max_per_user_per_stream_enabled` is **true**. The minimum value is 1. (format: int32)
  --is-global-cooldown-enabled: oneof<nothing, bool> # A Boolean value that determines whether to apply a cooldown period between redemptions (see the `global_cooldown_seconds` field for the duration of the cooldown period). The default is **false**.
  --global-cooldown-seconds: int # The cooldown period, in seconds. Applied only if the `is_global_cooldown_enabled` field is **true**. The minimum value is 1; however, the minimum value is 60 for it to be shown in the Twitch UX. (format: int32)
  --should-redemptions-skip-request-queue: oneof<nothing, bool> # A Boolean value that determines whether redemptions should be set to FULFILLED status immediately when a reward is redeemed. If **false**, status is set to UNFULFILLED and follows the normal request queue process. The default is **false**.
]: any -> record<data: table<broadcaster_id: string, broadcaster_login: string, broadcaster_name: string, id: string, title: string, prompt: string, cost: int, image: record, default_image: record, background_color: string, is_enabled: bool, is_user_input_required: bool, max_per_stream_setting: record, max_per_user_per_stream_setting: record, global_cooldown_setting: record, is_paused: bool, is_in_stock: bool, should_redemptions_skip_request_queue: bool, redemptions_redeemed_current_stream: int, cooldown_expires_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channel_points/custom_rewards" $qp)
  let body = {title: $title, cost: $cost, prompt: $prompt, is_enabled: $is_enabled, background_color: $background_color, is_user_input_required: $is_user_input_required, is_max_per_stream_enabled: $is_max_per_stream_enabled, max_per_stream: $max_per_stream, is_max_per_user_per_stream_enabled: $is_max_per_user_per_stream_enabled, max_per_user_per_stream: $max_per_user_per_stream, is_global_cooldown_enabled: $is_global_cooldown_enabled, global_cooldown_seconds: $global_cooldown_seconds, should_redemptions_skip_request_queue: $should_redemptions_skip_request_queue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a custom reward that the broadcaster created.
#
# DELETE /channel_points/custom_rewards
# Docs: https://dev.twitch.tv/docs/api/reference#delete-custom-reward — Delete Custom Reward
# operationId: delete-custom-reward
export def "channel-points-custom-rewards delete-custom-reward" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that created the custom reward. This ID must match the user ID found in the OAuth token.
  --id: string # The ID of the custom reward to delete.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channel_points/custom_rewards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of custom rewards that the specified broadcaster created.
#
# GET /channel_points/custom_rewards
# Docs: https://dev.twitch.tv/docs/api/reference#get-custom-reward — Get Custom Reward
# operationId: get-custom-reward
export def "channel-points-custom-rewards get-custom-reward" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose custom rewards you want to get. This ID must match the user ID found in the OAuth token.
  --id: list # A list of IDs to filter the rewards by. To specify more than one ID, include this parameter for each reward you want to get. For example, `id=1234&id=5678`. You may specify a maximum of 50 IDs.      Duplicate IDs are ignored. The response contains only the IDs that were found. If none of the IDs were found, the response is 404 Not Found.
  --only-manageable-rewards: oneof<nothing, bool> # A Boolean value that determines whether the response contains only the custom rewards that the app may manage (the app is identified by the ID in the Client-Id header). Set to **true** to get only the custom rewards that the app may manage. The default is **false**.
]: nothing -> record<data: table<broadcaster_id: string, broadcaster_login: string, broadcaster_name: string, id: string, title: string, prompt: string, cost: int, image: record, default_image: record, background_color: string, is_enabled: bool, is_user_input_required: bool, max_per_stream_setting: record, max_per_user_per_stream_setting: record, global_cooldown_setting: record, is_paused: bool, is_in_stock: bool, should_redemptions_skip_request_queue: bool, redemptions_redeemed_current_stream: int, cooldown_expires_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "id" $id "multi") (serialize-qp "only_manageable_rewards" $only_manageable_rewards "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channel_points/custom_rewards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a custom reward.
#
# PATCH /channel_points/custom_rewards
# Docs: https://dev.twitch.tv/docs/api/reference#update-custom-reward — Update Custom Reward
# operationId: update-custom-reward
export def "channel-points-custom-rewards update-custom-reward" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that’s updating the reward. This ID must match the user ID found in the OAuth token.
  --id: string # The ID of the reward to update.
  --title: string # The reward’s title. The title may contain a maximum of 45 characters and it must be unique amongst all of the broadcaster’s custom rewards.
  --prompt: string # The prompt shown to the viewer when they redeem the reward. Specify a prompt if `is_user_input_required` is **true**. The prompt is limited to a maximum of 200 characters.
  --cost: int # The cost of the reward, in channel points. The minimum is 1 point. (format: int64)
  --background-color: string # The background color to use for the reward. Specify the color using Hex format (for example, \\#00E5CB).
  --is-enabled: oneof<nothing, bool> # A Boolean value that indicates whether the reward is enabled. Set to **true** to enable the reward. Viewers see only enabled rewards.
  --is-user-input-required: oneof<nothing, bool> # A Boolean value that determines whether users must enter information to redeem the reward. Set to **true** if user input is required. See the `prompt` field.
  --is-max-per-stream-enabled: oneof<nothing, bool> # A Boolean value that determines whether to limit the maximum number of redemptions allowed per live stream (see the `max_per_stream` field). Set to **true** to limit redemptions.
  --max-per-stream: int # The maximum number of redemptions allowed per live stream. Applied only if `is_max_per_stream_enabled` is **true**. The minimum value is 1. (format: int64)
  --is-max-per-user-per-stream-enabled: oneof<nothing, bool> # A Boolean value that determines whether to limit the maximum number of redemptions allowed per user per stream (see `max_per_user_per_stream`). The minimum value is 1\. Set to **true** to limit redemptions.
  --max-per-user-per-stream: int # The maximum number of redemptions allowed per user per stream. Applied only if `is_max_per_user_per_stream_enabled` is **true**. (format: int64)
  --is-global-cooldown-enabled: oneof<nothing, bool> # A Boolean value that determines whether to apply a cooldown period between redemptions. Set to **true** to apply a cooldown period. For the duration of the cooldown period, see `global_cooldown_seconds`.
  --global-cooldown-seconds: int # The cooldown period, in seconds. Applied only if `is_global_cooldown_enabled` is **true**. The minimum value is 1; however, for it to be shown in the Twitch UX, the minimum value is 60. (format: int64)
  --is-paused: oneof<nothing, bool> # A Boolean value that determines whether to pause the reward. Set to **true** to pause the reward. Viewers can’t redeem paused rewards..
  --should-redemptions-skip-request-queue: oneof<nothing, bool> # A Boolean value that determines whether redemptions should be set to FULFILLED status immediately when a reward is redeemed. If **false**, status is set to UNFULFILLED and follows the normal request queue process.
]: any -> record<data: table<broadcaster_id: string, broadcaster_login: string, broadcaster_name: string, id: string, title: string, prompt: string, cost: int, image: record, default_image: record, background_color: string, is_enabled: bool, is_user_input_required: bool, max_per_stream_setting: record, max_per_user_per_stream_setting: record, global_cooldown_setting: record, is_paused: bool, is_in_stock: bool, should_redemptions_skip_request_queue: bool, redemptions_redeemed_current_stream: int, cooldown_expires_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channel_points/custom_rewards" $qp)
  let body = {title: $title, prompt: $prompt, cost: $cost, background_color: $background_color, is_enabled: $is_enabled, is_user_input_required: $is_user_input_required, is_max_per_stream_enabled: $is_max_per_stream_enabled, max_per_stream: $max_per_stream, is_max_per_user_per_stream_enabled: $is_max_per_user_per_stream_enabled, max_per_user_per_stream: $max_per_user_per_stream, is_global_cooldown_enabled: $is_global_cooldown_enabled, global_cooldown_seconds: $global_cooldown_seconds, is_paused: $is_paused, should_redemptions_skip_request_queue: $should_redemptions_skip_request_queue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of redemptions for a custom reward.
#
# GET /channel_points/custom_rewards/redemptions
# Docs: https://dev.twitch.tv/docs/api/reference#get-custom-reward-redemption — Get Custom Reward Redemption
# operationId: get-custom-reward-redemption
export def "channel-points-custom-rewards-redemptions get-custom-reward-redemption" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that owns the custom reward. This ID must match the user ID found in the user OAuth token.
  --reward-id: string # The ID that identifies the custom reward whose redemptions you want to get.
  --status: string@status-completer # The status of the redemptions to return. The possible case-sensitive values are:      * CANCELED * FULFILLED * UNFULFILLED    **NOTE**: This field is required only if you don’t specify the _id_ query parameter.      **NOTE**: Canceled and fulfilled redemptions are returned for only a few days after they’re canceled or fulfilled.
  --id: list # A list of IDs to filter the redemptions by. To specify more than one ID, include this parameter for each redemption you want to get. For example, `id=1234&id=5678`. You may specify a maximum of 50 IDs.      Duplicate IDs are ignored. The response contains only the IDs that were found. If none of the IDs were found, the response is 404 Not Found.
  --qp-sort: string@sort-completer # The order to sort redemptions by. The possible case-sensitive values are:      * OLDEST * NEWEST    The default is OLDEST.
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read more](https://dev.twitch.tv/docs/api/guide#pagination)
  --first: int # The maximum number of redemptions to return per page in the response. The minimum page size is 1 redemption per page and the maximum is 50\. The default is 20. (format: int32)
]: nothing -> record<data: table<broadcaster_id: string, broadcaster_login: string, broadcaster_name: string, id: string, user_id: string, user_name: string, user_login: string, reward: record, user_input: string, status: string, redeemed_at: string>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "reward_id" $reward_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "id" $id "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "first" $first "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channel_points/custom_rewards/redemptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a redemption’s status.
#
# PATCH /channel_points/custom_rewards/redemptions
# Docs: https://dev.twitch.tv/docs/api/reference#update-redemption-status — Update Redemption Status
# operationId: update-redemption-status
export def "channel-points-custom-rewards-redemptions update-redemption-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # A list of IDs that identify the redemptions to update. To specify more than one ID, include this parameter for each redemption you want to update. For example, `id=1234&id=5678`. You may specify a maximum of 50 IDs.
  --broadcaster-id: string # The ID of the broadcaster that’s updating the redemption. This ID must match the user ID in the user access token.
  --reward-id: string # The ID that identifies the reward that’s been redeemed.
  status: string@status-completer-1 # The status to set the redemption to. Possible values are:      * CANCELED * FULFILLED    Setting the status to CANCELED refunds the user’s channel points.
]: any -> record<data: table<broadcaster_id: string, broadcaster_login: string, broadcaster_name: string, id: string, user_id: string, user_name: string, user_login: string, reward: record, user_input: string, status: string, redeemed_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi") (serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "reward_id" $reward_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channel_points/custom_rewards/redemptions" $qp)
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets information about the broadcaster’s active charity campaign.
#
# GET /charity/campaigns
# Docs: https://dev.twitch.tv/docs/api/reference#get-charity-campaign — Get Charity Campaign
# operationId: get-charity-campaign
export def "charity-campaigns get-charity-campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that’s currently running a charity campaign. This ID must match the user ID in the access token.
]: nothing -> record<data: table<id: string, broadcaster_id: string, broadcaster_login: string, broadcaster_name: string, charity_name: string, charity_description: string, charity_logo: string, charity_website: string, current_amount: record, target_amount: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/charity/campaigns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of donations that users have made to the broadcaster’s active charity campaign.
#
# GET /charity/donations
# Docs: https://dev.twitch.tv/docs/api/reference#get-charity-campaign-donations — Get Charity Campaign Donations
# operationId: get-charity-campaign-donations
export def "charity-donations get-charity-campaign-donations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that’s currently running a charity campaign. This ID must match the user ID in the access token.
  --first: int # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100\. The default is 20. (format: int32)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<id: string, campaign_id: string, user_id: string, user_login: string, user_name: string, amount: record>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/charity/donations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of users that are connected to the broadcaster’s chat session.
#
# GET /chat/chatters
# Docs: https://dev.twitch.tv/docs/api/reference#get-chatters — Get Chatters
# operationId: get-chatters
export def "chat-chatters get-chatters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose list of chatters you want to get.
  --moderator-id: string # The ID of the broadcaster or one of the broadcaster’s moderators. This ID must match the user ID in the user access token.
  --first: int # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 1,000\. The default is 100. (format: int32)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<user_id: string, user_login: string, user_name: string>, pagination: record<cursor: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chat/chatters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the broadcaster’s list of custom emotes.
#
# GET /chat/emotes
# Docs: https://dev.twitch.tv/docs/api/reference#get-channel-emotes — Get Channel Emotes
# operationId: get-channel-emotes
export def "chat-emotes get-channel-emotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # An ID that identifies the broadcaster whose emotes you want to get.
]: nothing -> record<data: table<id: string, name: string, images: record, tier: string, emote_type: string, emote_set_id: string, format: list, scale: list, theme_mode: list>, template: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chat/emotes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all global emotes.
#
# GET /chat/emotes/global
# Docs: https://dev.twitch.tv/docs/api/reference#get-global-emotes — Get Global Emotes
# operationId: get-global-emotes
export def "chat-emotes-global get-global-emotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<id: string, name: string, images: record, format: list, scale: list, theme_mode: list>, template: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chat/emotes/global")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets emotes for one or more specified emote sets.
#
# GET /chat/emotes/set
# Docs: https://dev.twitch.tv/docs/api/reference#get-emote-sets — Get Emote Sets
# operationId: get-emote-sets
export def "chat-emotes-set get-emote-sets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --emote-set-id: list # An ID that identifies the emote set to get. Include this parameter for each emote set you want to get. For example, `emote_set_id=1234&emote_set_id=5678`. You may specify a maximum of 25 IDs. The response contains only the IDs that were found and ignores duplicate IDs.      To get emote set IDs, use the [Get Channel Emotes](https://dev.twitch.tv/docs/api/reference#get-channel-emotes) API.
]: nothing -> record<data: table<id: string, name: string, images: record, emote_type: string, emote_set_id: string, owner_id: string, format: list, scale: list, theme_mode: list>, template: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "emote_set_id" $emote_set_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/chat/emotes/set" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the broadcaster’s list of custom chat badges.
#
# GET /chat/badges
# Docs: https://dev.twitch.tv/docs/api/reference#get-channel-chat-badges — Get Channel Chat Badges
# operationId: get-channel-chat-badges
export def "chat-badges get-channel-chat-badges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose chat badges you want to get.
]: nothing -> record<data: table<set_id: string, versions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chat/badges" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Twitch’s list of chat badges.
#
# GET /chat/badges/global
# Docs: https://dev.twitch.tv/docs/api/reference#get-global-chat-badges — Get Global Chat Badges
# operationId: get-global-chat-badges
export def "chat-badges-global get-global-chat-badges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<set_id: string, versions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chat/badges/global")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the broadcaster’s chat settings.
#
# GET /chat/settings
# Docs: https://dev.twitch.tv/docs/api/reference#get-chat-settings — Get Chat Settings
# operationId: get-chat-settings
export def "chat-settings get-chat-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose chat settings you want to get.
  --moderator-id: string # The ID of the broadcaster or one of the broadcaster’s moderators.      This field is required only if you want to include the `non_moderator_chat_delay` and `non_moderator_chat_delay_duration` settings in the response.      If you specify this field, this ID must match the user ID in the user access token.
]: nothing -> record<data: table<broadcaster_id: string, emote_mode: bool, follower_mode: bool, follower_mode_duration: int, moderator_id: string, non_moderator_chat_delay: bool, non_moderator_chat_delay_duration: int, slow_mode: bool, slow_mode_wait_time: int, subscriber_mode: bool, unique_chat_mode: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chat/settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the broadcaster’s chat settings.
#
# PATCH /chat/settings
# Docs: https://dev.twitch.tv/docs/api/reference#update-chat-settings — Update Chat Settings
# operationId: update-chat-settings
export def "chat-settings update-chat-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose chat settings you want to update.
  --moderator-id: string # The ID of a user that has permission to moderate the broadcaster’s chat room, or the broadcaster’s ID if they’re making the update. This ID must match the user ID in the user access token.
  --emote-mode: oneof<nothing, bool> # A Boolean value that determines whether chat messages must contain only emotes.      Set to **true** if only emotes are allowed; otherwise, **false**. The default is **false**.
  --follower-mode: oneof<nothing, bool> # A Boolean value that determines whether the broadcaster restricts the chat room to followers only.      Set to **true** if the broadcaster restricts the chat room to followers only; otherwise, **false**. The default is **true**.      To specify how long users must follow the broadcaster before being able to participate in the chat room, see the `follower_mode_duration` field.
  --follower-mode-duration: int # The length of time, in minutes, that users must follow the broadcaster before being able to participate in the chat room. Set only if `follower_mode` is **true**. Possible values are: 0 (no restriction) through 129600 (3 months). The default is 0. (format: int32)
  --non-moderator-chat-delay: oneof<nothing, bool> # A Boolean value that determines whether the broadcaster adds a short delay before chat messages appear in the chat room. This gives chat moderators and bots a chance to remove them before viewers can see the message.      Set to **true** if the broadcaster applies a delay; otherwise, **false**. The default is **false**.      To specify the length of the delay, see the `non_moderator_chat_delay_duration` field.
  --non-moderator-chat-delay-duration: int@non-moderator-chat-delay-duration-completer # The amount of time, in seconds, that messages are delayed before appearing in chat. Set only if `non_moderator_chat_delay` is **true**. Possible values are:      * 2 — 2 second delay (recommended) * 4 — 4 second delay * 6 — 6 second delay (format: int32)
  --slow-mode: oneof<nothing, bool> # A Boolean value that determines whether the broadcaster limits how often users in the chat room are allowed to send messages. Set to **true** if the broadcaster applies a wait period between messages; otherwise, **false**. The default is **false**.      To specify the delay, see the `slow_mode_wait_time` field.
  --slow-mode-wait-time: int # The amount of time, in seconds, that users must wait between sending messages. Set only if `slow_mode` is **true**.      Possible values are: 3 (3 second delay) through 120 (2 minute delay). The default is 30 seconds. (format: int32)
  --subscriber-mode: oneof<nothing, bool> # A Boolean value that determines whether only users that subscribe to the broadcaster’s channel may talk in the chat room.      Set to **true** if the broadcaster restricts the chat room to subscribers only; otherwise, **false**. The default is **false**.
  --unique-chat-mode: oneof<nothing, bool> # A Boolean value that determines whether the broadcaster requires users to post only unique messages in the chat room.      Set to **true** if the broadcaster allows only unique messages; otherwise, **false**. The default is **false**.
]: any -> record<data: table<broadcaster_id: string, emote_mode: bool, follower_mode: bool, follower_mode_duration: int, moderator_id: string, non_moderator_chat_delay: bool, non_moderator_chat_delay_duration: int, slow_mode: bool, slow_mode_wait_time: int, subscriber_mode: bool, unique_chat_mode: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chat/settings" $qp)
  let body = {emote_mode: $emote_mode, follower_mode: $follower_mode, follower_mode_duration: $follower_mode_duration, non_moderator_chat_delay: $non_moderator_chat_delay, non_moderator_chat_delay_duration: $non_moderator_chat_delay_duration, slow_mode: $slow_mode, slow_mode_wait_time: $slow_mode_wait_time, subscriber_mode: $subscriber_mode, unique_chat_mode: $unique_chat_mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# NEW Retrieves the active shared chat session for a channel.
#
# GET /shared_chat/session
# Docs: https://dev.twitch.tv/docs/api/reference#get-shared-chat-session — Get Shared Chat Session
# operationId: get-shared-chat-session
export def "shared-chat-session get-shared-chat-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The User ID of the channel broadcaster.
]: nothing -> record<data: table<session_id: string, host_broadcaster_id: string, participants: list, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shared_chat/session" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves emotes available to the user across all channels.
#
# GET /chat/emotes/user
# Docs: https://dev.twitch.tv/docs/api/reference#get-user-emotes — Get User Emotes
# operationId: get-user-emotes
export def "chat-emotes-user get-user-emotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The ID of the user. This ID must match the user ID in the user access token.
  --after: string # The cursor used to get the next page of results. The Pagination object in the response contains the cursor’s value.
  --broadcaster-id: string # The User ID of a broadcaster you wish to get follower emotes of. Using this query parameter will guarantee inclusion of the broadcaster’s follower emotes in the response body.       **Note:** If the user specified in `user_id` is subscribed to the broadcaster specified, their follower emotes will appear in the response body regardless if this query parameter is used.
]: nothing -> record<data: table<id: string, name: string, emote_type: string, emote_set_id: string, owner_id: string, format: list, scale: list, theme_mode: list>, template: string, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chat/emotes/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends an announcement to the broadcaster’s chat room.
#
# POST /chat/announcements
# Docs: https://dev.twitch.tv/docs/api/reference#send-chat-announcement — Send Chat Announcement
# operationId: send-chat-announcement
export def "chat-announcements send-chat-announcement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that owns the chat room to send the announcement to.
  --moderator-id: string # The ID of a user who has permission to moderate the broadcaster’s chat room, or the broadcaster’s ID if they’re sending the announcement. This ID must match the user ID in the user access token.
  message: string # The announcement to make in the broadcaster’s chat room. Announcements are limited to a maximum of 500 characters; announcements longer than 500 characters are truncated.
  --color: string@color-completer # The color used to highlight the announcement. Possible case-sensitive values are:      * blue * green * orange * purple * primary (default)    If `color` is set to _primary_ or is not set, the channel’s accent color is used to highlight the announcement (see **Profile Accent Color** under [profile settings](https://www.twitch.tv/settings/profile), **Channel and Videos**, and **Brand**). (default: primary)
  --source-only: oneof<nothing, bool> # Determines if the chat announcement is sent only to the source channel defined by broadcaster\_id during a shared chat session. This has no effect if the announcement is not sent sent during a shared chat session. The default value is `false`. NOTE: This parameter can only be set when utilizing an App Access Token. It cannot be specified when a User Access Token is used, and will instead result in an HTTP 400 error.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chat/announcements" $qp)
  let body = {message: $message, color: $color, source-only: $source_only} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sends a Shoutout to the specified broadcaster.
#
# POST /chat/shoutouts
# Docs: https://dev.twitch.tv/docs/api/reference#send-a-shoutout — Send a Shoutout
# operationId: send-a-shoutout
export def "chat-shoutouts send-a-shoutout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-broadcaster-id: string # The ID of the broadcaster that’s sending the Shoutout.
  --to-broadcaster-id: string # The ID of the broadcaster that’s receiving the Shoutout.
  --moderator-id: string # The ID of the broadcaster or a user that is one of the broadcaster’s moderators. This ID must match the user ID in the access token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from_broadcaster_id" $from_broadcaster_id "scalar") (serialize-qp "to_broadcaster_id" $to_broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chat/shoutouts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends a message to the broadcaster’s chat room.
#
# POST /chat/messages
# Docs: https://dev.twitch.tv/docs/api/reference#send-chat-message — Send Chat Message
# operationId: send-chat-message
export def "chat-messages send-chat-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  broadcaster_id: string # The ID of the broadcaster whose chat room the message will be sent to.
  sender_id: string # The ID of the user sending the message. This ID must match the user ID in the user access token.
  message: string # The message to send. The message is limited to a maximum of 500 characters. Chat messages can also include emoticons. To include emoticons, use the name of the emote. The names are case sensitive. Don’t include colons around the name (e.g., :bleedPurple:). If Twitch recognizes the name, Twitch converts the name to the emote before writing the chat message to the chat room
  --reply-parent-message-id: string # The ID of the chat message being replied to.
  --for-source-only: oneof<nothing, bool> # **NOTE:** This parameter can only be set when utilizing an App Access Token. It cannot be specified when a User Access Token is used, and will instead result in an HTTP 400 error.      Determines if the chat message is sent only to the source channel (defined by _broadcaster\_id_) during a shared chat session. This has no effect if the message is not sent during a shared chat session.      If this parameter is not set, the default value when using an App Access Token is `false`. On May 19, 2025 the default value for this parameter will be updated to `true`, and chat messages sent using an App Access Token will only be shared with the source channel by default. If you prefer to send a chat message to both channels in a shared chat session, make sure this parameter is explicitly set to `false` in your API request before May 19.
]: any -> record<data: table<message_id: string, is_sent: bool, drop_reason: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chat/messages")
  let body = {broadcaster_id: $broadcaster_id, sender_id: $sender_id, message: $message, reply_parent_message_id: $reply_parent_message_id, for_source_only: $for_source_only} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the color used for the user’s name in chat.
#
# GET /chat/color
# Docs: https://dev.twitch.tv/docs/api/reference#get-user-chat-color — Get User Chat Color
# operationId: get-user-chat-color
export def "chat-color get-user-chat-color" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: list # The ID of the user whose username color you want to get. To specify more than one user, include the _user\_id_ parameter for each user to get. For example, `&user_id=1234&user_id=5678`. The maximum number of IDs that you may specify is 100.      The API ignores duplicate IDs and IDs that weren’t found.
]: nothing -> record<data: table<user_id: string, user_login: string, user_name: string, color: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/chat/color" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the color used for the user’s name in chat.
#
# PUT /chat/color
# Docs: https://dev.twitch.tv/docs/api/reference#update-user-chat-color — Update User Chat Color
# operationId: update-user-chat-color
export def "chat-color update-user-chat-color" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The ID of the user whose chat color you want to update. This ID must match the user ID in the access token.
  --color: string@color-completer-1 # The color to use for the user's name in chat. All users may specify one of the following named color values.      * blue * blue\_violet * cadet\_blue * chocolate * coral * dodger\_blue * firebrick * golden\_rod * green * hot\_pink * orange\_red * red * sea\_green * spring\_green * yellow\_green    Turbo and Prime users may specify a named color or a Hex color code like #9146FF. If you use a Hex color code, remember to URL encode it.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "color" $color "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chat/color" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a clip from the broadcaster’s stream.
#
# POST /clips
# Docs: https://dev.twitch.tv/docs/api/reference#create-clip — Create Clip
# operationId: create-clip
export def "clips create-clip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose stream you want to create a clip from.
  --title: string # The title of the clip.
  --duration: float # The length of the clip in seconds. Possible values range from 5 to 60 inclusively with a precision of 0.1\. The default is 30. (format: float)
]: nothing -> record<data: table<id: string, edit_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "duration" $duration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/clips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets one or more video clips.
#
# GET /clips
# Docs: https://dev.twitch.tv/docs/api/reference#get-clips — Get Clips
# operationId: get-clips
export def "clips get-clips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # An ID that identifies the broadcaster whose video clips you want to get. Use this parameter to get clips that were captured from the broadcaster’s streams.
  --game-id: string # An ID that identifies the game whose clips you want to get. Use this parameter to get clips that were captured from streams that were playing this game.
  --id: list # An ID that identifies the clip to get. To specify more than one ID, include this parameter for each clip you want to get. For example, `id=foo&id=bar`. You may specify a maximum of 100 IDs. The API ignores duplicate IDs and IDs that aren’t found.
  --started-at: string # The start date used to filter clips. The API returns only clips within the start and end date window. Specify the date and time in RFC3339 format. (format: date-time)
  --ended-at: string # The end date used to filter clips. If not specified, the time window is the start date plus one week. Specify the date and time in RFC3339 format. (format: date-time)
  --first: int # The maximum number of clips to return per page in the response. The minimum page size is 1 clip per page and the maximum is 100\. The default is 20. (format: int32)
  --before: string # The cursor used to get the previous page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
  --is-featured: oneof<nothing, bool> # A Boolean value that determines whether the response includes featured clips. If **true**, returns only clips that are featured. If **false**, returns only clips that aren’t featured. All clips are returned if this parameter is not present.
]: nothing -> record<data: table<id: string, url: string, embed_url: string, broadcaster_id: string, broadcaster_name: string, creator_id: string, creator_name: string, video_id: string, game_id: string, language: string, title: string, view_count: int, created_at: string, thumbnail_url: string, duration: float, vod_offset: int, is_featured: bool>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "game_id" $game_id "scalar") (serialize-qp "id" $id "multi") (serialize-qp "started_at" $started_at "scalar") (serialize-qp "ended_at" $ended_at "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "is_featured" $is_featured "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/clips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# NEW  Creates a clip from the broadcaster’s VOD.
#
# POST /videos/clips
# Docs: https://dev.twitch.tv/docs/api/reference#create-clip-from-vod — Create Clip From VOD
# operationId: create-clip-from-vod
export def "videos-clips create-clip-from-vod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --editor-id: string # The user ID of the editor for the channel you want to create a clip for. If using the broadcaster’s auth token, this is the same as broadcaster\_id. This must match the user\_id in the user access token.
  --broadcaster-id: string # The user ID for the channel you want to create a clip for.
  --vod-id: string # ID of the VOD the user wants to clip.
  --vod-offset: int # Offset in the VOD to create the clip. See notes above. (format: int32)
  --duration: float # The length of the clip, in seconds. Precision is 0.1\. Defaults to 30\. Min: 5 seconds, Max: 60 seconds. (format: float)
  --title: string # The title of the clip.
]: nothing -> record<data: table<id: string, edit_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "editor_id" $editor_id "scalar") (serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "vod_id" $vod_id "scalar") (serialize-qp "vod_offset" $vod_offset "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "title" $title "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/videos/clips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# NEW Provides URLs to download the video file(s) for the specified clips.
#
# GET /clips/downloads
# Docs: https://dev.twitch.tv/docs/api/reference#get-clips-download — Get Clips Download
# operationId: get-clips-download
export def "clips-downloads get-clips-download" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --editor-id: string # The User ID of the editor for the channel you want to download a clip for. If using the broadcaster’s auth token, this is the same as `broadcaster_id`. This must match the `user_id` in the user access token.
  --broadcaster-id: string # The ID of the broadcaster you want to download clips for.
  --clip-id: list # The ID that identifies the clip you want to download. Include this parameter for each clip you want to download, up to a maximum of 10 clips. For example, `clip_id=SleepyGiftedPeppermintNerfRedBlaster-KbkBXYt3lOk3jy8-&clip_id=WimpyAltruisticKleeKeyboardCat-EiY5yMrEwZ4i4gwC`.
]: nothing -> record<data: table<clip_id: string, landscape_download_url: string, portrait_download_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "editor_id" $editor_id "scalar") (serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "clip_id" $clip_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/clips/downloads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the conduits for a client ID.
#
# GET /eventsub/conduits
# Docs: https://dev.twitch.tv/docs/api/reference#get-conduits — Get Conduits
# operationId: get-conduits
export def "eventsub-conduits get-conduits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<id: string, shard_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/eventsub/conduits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new conduit.
#
# POST /eventsub/conduits
# Docs: https://dev.twitch.tv/docs/api/reference#create-conduits — Create Conduits
# operationId: create-conduits
export def "eventsub-conduits create-conduits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  shard_count: int # The number of shards to create for this conduit. (format: int32)
]: any -> record<data: table<id: string, shard_count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/eventsub/conduits")
  let body = {shard_count: $shard_count} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a conduit’s shard count.
#
# PATCH /eventsub/conduits
# Docs: https://dev.twitch.tv/docs/api/reference#update-conduits — Update Conduits
# operationId: update-conduits
export def "eventsub-conduits update-conduits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # Conduit ID.
  shard_count: int # The new number of shards for this conduit. (format: int32)
]: any -> record<data: table<id: string, shard_count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/eventsub/conduits")
  let body = {id: $id, shard_count: $shard_count} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a specified conduit.
#
# DELETE /eventsub/conduits
# Docs: https://dev.twitch.tv/docs/api/reference#delete-conduit — Delete Conduit
# operationId: delete-conduit
export def "eventsub-conduits delete-conduit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Conduit ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/eventsub/conduits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a lists of all shards for a conduit.
#
# GET /eventsub/conduits/shards
# Docs: https://dev.twitch.tv/docs/api/reference#get-conduit-shards — Get Conduit Shards
# operationId: get-conduit-shards
export def "eventsub-conduits-shards get-conduit-shards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conduit-id: string # Conduit ID.
  --status: string # Status to filter by.
  --after: string # The cursor used to get the next page of results. The pagination object in the response contains the cursor’s value.
]: nothing -> record<data: table<id: string, status: string, transport: record>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "conduit_id" $conduit_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/eventsub/conduits/shards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates shard(s) for a conduit.
#
# PATCH /eventsub/conduits/shards
# Docs: https://dev.twitch.tv/docs/api/reference#update-conduit-shards — Update Conduit Shards
# operationId: update-conduit-shards
# --shards item shape: {id: string, transport: record}
export def "eventsub-conduits-shards update-conduit-shards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  conduit_id: string # Conduit ID.
  shards: list # List of shards to update. — item shape: {id: string, transport: record}
]: any -> record<data: table<id: string, status: string, transport: record>, errors: table<id: string, message: string, code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/eventsub/conduits/shards")
  let body = {conduit_id: $conduit_id, shards: $shards} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets information about Twitch content classification labels.
#
# GET /content_classification_labels
# Docs: https://dev.twitch.tv/docs/api/reference#get-content-classification-labels — Get Content Classification Labels
# operationId: get-content-classification-labels
export def "content-classification-labels get-content-classification-labels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # Locale for the Content Classification Labels. You may specify a maximum of 1 locale. Default: `“en-US”`   Supported locales: `"bg-BG", "cs-CZ", "da-DK", "da-DK", "de-DE", "el-GR", "en-GB", "en-US", "es-ES", "es-MX", "fi-FI", "fr-FR", "hu-HU", "it-IT", "ja-JP", "ko-KR", "nl-NL", "no-NO", "pl-PL", "pt-BT", "pt-PT", "ro-RO", "ru-RU", "sk-SK", "sv-SE", "th-TH", "tr-TR", "vi-VN", "zh-CN", "zh-TW"`
]: nothing -> record<data: table<id: string, description: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/content_classification_labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an organization’s list of entitlements that have been granted to a game, a user, or both.
#
# GET /entitlements/drops
# Docs: https://dev.twitch.tv/docs/api/reference#get-drops-entitlements — Get Drops Entitlements
# operationId: get-drops-entitlements
export def "entitlements-drops get-drops-entitlements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # An ID that identifies the entitlement to get. Include this parameter for each entitlement you want to get. For example, `id=1234&id=5678`. You may specify a maximum of 100 IDs.
  --user-id: string # An ID that identifies a user that was granted entitlements.
  --game-id: string # An ID that identifies a game that offered entitlements.
  --fulfillment-status: string@fulfillment-status-completer # The entitlement’s fulfillment status. Used to filter the list to only those with the specified status. Possible values are:       * CLAIMED * FULFILLED
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
  --first: int # The maximum number of entitlements to return per page in the response. The minimum page size is 1 entitlement per page and the maximum is 1000\. The default is 20. (format: int32)
]: nothing -> record<data: table<id: string, benefit_id: string, timestamp: string, user_id: string, game_id: string, fulfillment_status: string, last_updated: string>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "game_id" $game_id "scalar") (serialize-qp "fulfillment_status" $fulfillment_status "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "first" $first "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entitlements/drops" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the Drop entitlement’s fulfillment status.
#
# PATCH /entitlements/drops
# Docs: https://dev.twitch.tv/docs/api/reference#update-drops-entitlements — Update Drops Entitlements
# operationId: update-drops-entitlements
export def "entitlements-drops update-drops-entitlements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --entitlement-ids: list # A list of IDs that identify the entitlements to update. You may specify a maximum of 100 IDs.
  --fulfillment-status: string@fulfillment-status-completer # The fulfillment status to set the entitlements to. Possible values are:      * CLAIMED — The user claimed the benefit. * FULFILLED — The developer granted the benefit that the user claimed.
]: any -> record<data: table<status: string, ids: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/entitlements/drops")
  let body = {entitlement_ids: $entitlement_ids, fulfillment_status: $fulfillment_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the specified configuration segment from the specified extension.
#
# GET /extensions/configurations
# Docs: https://dev.twitch.tv/docs/api/reference#get-extension-configuration-segment — Get Extension Configuration Segment
# operationId: get-extension-configuration-segment
export def "extensions-configurations get-extension-configuration-segment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that installed the extension. This parameter is required if you set the _segment_ parameter to broadcaster or developer. Do not specify this parameter if you set _segment_ to global.
  --extension-id: string # The ID of the extension that contains the configuration segment you want to get.
  --segment: string@segment-completer # The type of configuration segment to get. Possible case-sensitive values are:       * broadcaster * developer * global    You may specify one or more segments. To specify multiple segments, include the `segment` parameter for each segment to get. For example, `segment=broadcaster&segment=developer`. Ignores duplicate segments.
]: nothing -> record<data: table<segment: string, broadcaster_id: string, content: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "extension_id" $extension_id "scalar") (serialize-qp "segment" $segment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extensions/configurations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a configuration segment.
#
# PUT /extensions/configurations
# Docs: https://dev.twitch.tv/docs/api/reference#set-extension-configuration-segment — Set Extension Configuration Segment
# operationId: set-extension-configuration-segment
export def "extensions-configurations set-extension-configuration-segment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  extension_id: string # The ID of the extension to update.
  segment: string@segment-completer # The configuration segment to update. Possible case-sensitive values are:      * broadcaster * developer * global
  --broadcaster-id: string # The ID of the broadcaster that installed the extension. Include this field only if the `segment` is set to developer or broadcaster.
  --content: string # The contents of the segment. This string may be a plain-text string or a string-encoded JSON object.
  --version: string # The version number that identifies this definition of the segment’s data. If not specified, the latest definition is updated.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/extensions/configurations")
  let body = {extension_id: $extension_id, segment: $segment, broadcaster_id: $broadcaster_id, content: $content, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the extension’s required_configuration string.
#
# PUT /extensions/required_configuration
# Docs: https://dev.twitch.tv/docs/api/reference#set-extension-required-configuration — Set Extension Required Configuration
# operationId: set-extension-required-configuration
export def "extensions-required-configuration set-extension-required-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that installed the extension on their channel.
  extension_id: string # The ID of the extension to update.
  extension_version: string # The version of the extension to update.
  required_configuration: string # The required\_configuration string to use with the extension.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extensions/required_configuration" $qp)
  let body = {extension_id: $extension_id, extension_version: $extension_version, required_configuration: $required_configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sends a message to one or more viewers.
#
# POST /extensions/pubsub
# Docs: https://dev.twitch.tv/docs/api/reference#send-extension-pubsub-message — Send Extension PubSub Message
# operationId: send-extension-pubsub-message
export def "extensions-pubsub send-extension-pubsub-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  target: list # The target of the message. Possible values are:      * broadcast * global * whisper-<user-id>    If `is_global_broadcast` is **true**, you must set this field to global. The broadcast and global values are mutually exclusive; specify only one of them.
  broadcaster_id: string # The ID of the broadcaster to send the message to. Don’t include this field if `is_global_broadcast` is set to **true**.
  --is-global-broadcast: oneof<nothing, bool> # A Boolean value that determines whether the message should be sent to all channels where your extension is active. Set to **true** if the message should be sent to all channels. The default is **false**.
  message: string # The message to send. The message can be a plain-text string or a string-encoded JSON object. The message is limited to a maximum of 5 KB.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/extensions/pubsub")
  let body = {target: $target, broadcaster_id: $broadcaster_id, is_global_broadcast: $is_global_broadcast, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of broadcasters that are streaming live and have installed or activated the extension.
#
# GET /extensions/live
# Docs: https://dev.twitch.tv/docs/api/reference#get-extension-live-channels — Get Extension Live Channels
# operationId: get-extension-live-channels
export def "extensions-live get-extension-live-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --extension-id: string # The ID of the extension to get. Returns the list of broadcasters that are live and that have installed or activated this extension.
  --first: int # The specific maximum number of items per page in the response. The actual number returned may be less than this limit. [Read More](https://dev.twitch.tv/docs/api/guide#pagination) (format: int32)
  --after: string # The cursor used to get the next page of results. The `pagination` field in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<broadcaster_id: string, broadcaster_name: string, game_name: string, game_id: string, title: string>, pagination: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extension_id" $extension_id "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extensions/live" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an extension’s list of shared secrets.
#
# GET /extensions/jwt/secrets
# Docs: https://dev.twitch.tv/docs/api/reference#get-extension-secrets — Get Extension Secrets
# operationId: get-extension-secrets
export def "extensions-jwt-secrets get-extension-secrets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<format_version: int, secrets: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/extensions/jwt/secrets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a shared secret used to sign and verify JWT tokens.
#
# POST /extensions/jwt/secrets
# Docs: https://dev.twitch.tv/docs/api/reference#create-extension-secret — Create Extension Secret
# operationId: create-extension-secret
export def "extensions-jwt-secrets create-extension-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --extension-id: string # The ID of the extension to apply the shared secret to.
  --delay: int # The amount of time, in seconds, to delay activating the secret. The delay should provide enough time for instances of the extension to gracefully switch over to the new secret. The minimum delay is 300 seconds (5 minutes). The default is 300 seconds. (format: int32)
]: nothing -> record<data: table<format_version: int, secrets: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extension_id" $extension_id "scalar") (serialize-qp "delay" $delay "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extensions/jwt/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends a message to the specified broadcaster’s chat room.
#
# POST /extensions/chat
# Docs: https://dev.twitch.tv/docs/api/reference#send-extension-chat-message — Send Extension Chat Message
# operationId: send-extension-chat-message
export def "extensions-chat send-extension-chat-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that has activated the extension.
  text: string # The message. The message may contain a maximum of 280 characters.
  extension_id: string # The ID of the extension that’s sending the chat message.
  extension_version: string # The extension’s version number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extensions/chat" $qp)
  let body = {text: $text, extension_id: $extension_id, extension_version: $extension_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets information about an extension.
#
# GET /extensions
# Docs: https://dev.twitch.tv/docs/api/reference#get-extensions — Get Extensions
# operationId: get-extensions
export def "extensions get-extensions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --extension-id: string # The ID of the extension to get.
  --extension-version: string # The version of the extension to get. If not specified, it returns the latest, released version. If you don’t have a released version, you must specify a version; otherwise, the list is empty.
]: nothing -> record<data: table<author_name: string, bits_enabled: bool, can_install: bool, configuration_location: string, description: string, eula_tos_url: string, has_chat_support: bool, icon_url: string, icon_urls: record, id: string, name: string, privacy_policy_url: string, request_identity_link: bool, screenshot_urls: list, state: string, subscriptions_support_level: string, summary: string, support_email: string, version: string, viewer_summary: string, views: record, allowlisted_config_urls: list, allowlisted_panel_urls: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extension_id" $extension_id "scalar") (serialize-qp "extension_version" $extension_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a released extension.
#
# GET /extensions/released
# Docs: https://dev.twitch.tv/docs/api/reference#get-released-extensions — Get Released Extensions
# operationId: get-released-extensions
export def "extensions-released get-released-extensions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --extension-id: string # The ID of the extension to get.
  --extension-version: string # The version of the extension to get. If not specified, it returns the latest version.
]: nothing -> record<data: table<author_name: string, bits_enabled: bool, can_install: bool, configuration_location: string, description: string, eula_tos_url: string, has_chat_support: bool, icon_url: string, icon_urls: record, id: string, name: string, privacy_policy_url: string, request_identity_link: bool, screenshot_urls: list, state: string, subscriptions_support_level: string, summary: string, support_email: string, version: string, viewer_summary: string, views: record, allowlisted_config_urls: list, allowlisted_panel_urls: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extension_id" $extension_id "scalar") (serialize-qp "extension_version" $extension_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extensions/released" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of Bits products that belongs to the extension.
#
# GET /bits/extensions
# Docs: https://dev.twitch.tv/docs/api/reference#get-extension-bits-products — Get Extension Bits Products
# operationId: get-extension-bits-products
export def "bits-extensions get-extension-bits-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --should-include-all: oneof<nothing, bool> # A Boolean value that determines whether to include disabled or expired Bits products in the response. The default is **false**.
]: nothing -> record<data: table<sku: string, cost: record, in_development: bool, display_name: string, expiration: string, is_broadcast: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "should_include_all" $should_include_all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bits/extensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds or updates a Bits product that the extension created.
#
# PUT /bits/extensions
# Docs: https://dev.twitch.tv/docs/api/reference#update-extension-bits-product — Update Extension Bits Product
# operationId: update-extension-bits-product
# --cost shape: {amount: int, type: "bits"}
export def "bits-extensions update-extension-bits-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  sku: string # The product's SKU. The SKU must be unique within an extension. The product's SKU cannot be changed. The SKU may contain only alphanumeric characters, dashes (-), underscores (\_), and periods (.) and is limited to a maximum of 255 characters. No spaces.
  cost: record # An object that contains the product's cost information. — shape: {amount: int, type: "bits"}
  display_name: string # The product's name as displayed in the extension. The maximum length is 255 characters.
  --in-development: oneof<nothing, bool> # A Boolean value that indicates whether the product is in development. Set to **true** if the product is in development and not available for public use. The default is **false**.
  --expiration: string # The date and time, in RFC3339 format, when the product expires. If not set, the product does not expire. To disable the product, set the expiration date to a date in the past. (format: date-time)
  --is-broadcast: oneof<nothing, bool> # A Boolean value that determines whether Bits product purchase events are broadcast to all instances of the extension on a channel. The events are broadcast via the `onTransactionComplete` helper callback. The default is **false**.
]: any -> record<data: table<sku: string, cost: record, in_development: bool, display_name: string, expiration: string, is_broadcast: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bits/extensions")
  let body = {sku: $sku, cost: $cost, display_name: $display_name, in_development: $in_development, expiration: $expiration, is_broadcast: $is_broadcast} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates an EventSub subscription.
#
# POST /eventsub/subscriptions
# Docs: https://dev.twitch.tv/docs/api/reference#create-eventsub-subscription — Create EventSub Subscription
# operationId: create-eventsub-subscription
# --transport shape: {method: "webhook"|"websocket"|"conduit", callback?: string, secret?: string, session_id?: string, conduit_id?: string}
export def "eventsub-subscriptions create-eventsub-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-1 # The type of subscription to create. For a list of subscriptions that you can create, see [Subscription Types](https://dev.twitch.tv/docs/eventsub/eventsub-subscription-types#subscription-types). Set this field to the value in the **Name** column of the Subscription Types table.
  version: string # The version number that identifies the definition of the subscription type that you want the response to use.
  condition: record # A JSON object that contains the parameter values that are specific to the specified subscription type. For the object’s required and optional fields, see the subscription type’s documentation.
  transport: record # The transport details that you want Twitch to use when sending you notifications. — shape: {method: "webhook"|"websocket"|"conduit", callback?: string, secret?: string, session_id?: string, conduit_id?: string}
]: any -> record<data: table<id: string, status: string, type: string, version: string, condition: record, created_at: string, transport: record, cost: int>, total: int, total_cost: int, max_total_cost: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/eventsub/subscriptions")
  let body = {type: $type, version: $version, condition: $condition, transport: $transport} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an EventSub subscription.
#
# DELETE /eventsub/subscriptions
# Docs: https://dev.twitch.tv/docs/api/reference#delete-eventsub-subscription — Delete EventSub Subscription
# operationId: delete-eventsub-subscription
export def "eventsub-subscriptions delete-eventsub-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The ID of the subscription to delete.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/eventsub/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of EventSub subscriptions that the client in the access token created.
#
# GET /eventsub/subscriptions
# Docs: https://dev.twitch.tv/docs/api/reference#get-eventsub-subscriptions — Get EventSub Subscriptions
# operationId: get-eventsub-subscriptions
export def "eventsub-subscriptions get-eventsub-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-2 # Filter subscriptions by its status. Possible values are:      * enabled — The subscription is enabled. * webhook\_callback\_verification\_pending — The subscription is pending verification of the specified callback URL. * webhook\_callback\_verification\_failed — The specified callback URL failed verification. * notification\_failures\_exceeded — The notification delivery failure rate was too high. * authorization\_revoked — The authorization was revoked for one or more users specified in the **Condition** object. * moderator\_removed — The moderator that authorized the subscription is no longer one of the broadcaster's moderators. * user\_removed — One of the users specified in the **Condition** object was removed. * chat\_user\_banned - The user specified in the **Condition** object was banned from the broadcaster's chat. * version\_removed — The subscription to subscription type and version is no longer supported. * beta\_maintenance — The subscription to the beta subscription type was removed due to maintenance. * websocket\_disconnected — The client closed the connection. * websocket\_failed\_ping\_pong — The client failed to respond to a ping message. * websocket\_received\_inbound\_traffic — The client sent a non-pong message. Clients may only send pong messages (and only in response to a ping message). * websocket\_connection\_unused — The client failed to subscribe to events within the required time. * websocket\_internal\_error — The Twitch WebSocket server experienced an unexpected error. * websocket\_network\_timeout — The Twitch WebSocket server timed out writing the message to the client. * websocket\_network\_error — The Twitch WebSocket server experienced a network error writing the message to the client. * websocket\_failed\_to\_reconnect - The client failed to reconnect to the Twitch WebSocket server within the required time after a Reconnect Message.
  --type: string@type-completer-1 # Filter subscriptions by subscription type. For a list of subscription types, see [Subscription Types](https://dev.twitch.tv/docs/eventsub/eventsub-subscription-types#subscription-types).
  --user-id: string # Filter subscriptions by user ID. The response contains subscriptions where this ID matches a user ID that you specified in the **Condition** object when you [created the subscription](https://dev.twitch.tv/docs/api/reference#create-eventsub-subscription).
  --subscription-id: string # Returns an array with the subscription matching the ID (as long as it is owned by the client making the request), or an empty array if there is no matching subscription.
  --after: string # The cursor used to get the next page of results. The `pagination` object in the response contains the cursor's value.
]: nothing -> record<data: table<id: string, status: string, type: string, version: string, condition: record, created_at: string, transport: record, cost: int>, total: int, total_cost: int, max_total_cost: int, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "subscription_id" $subscription_id "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/eventsub/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about all broadcasts on Twitch.
#
# GET /games/top
# Docs: https://dev.twitch.tv/docs/api/reference#get-top-games — Get Top Games
# operationId: get-top-games
export def "games-top get-top-games" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first: int # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100 items per page. The default is 20. (format: int32)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
  --before: string # The cursor used to get the previous page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<id: string, name: string, box_art_url: string, igdb_id: string>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/games/top" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about specified games.
#
# GET /games
# Docs: https://dev.twitch.tv/docs/api/reference#get-games — Get Games
# operationId: get-games
export def "games get-games" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # The ID of the category or game to get. Include this parameter for each category or game you want to get. For example, `&id=1234&id=5678`. You may specify a maximum of 100 IDs. The endpoint ignores duplicate and invalid IDs or IDs that weren’t found.
  --name: list # The name of the category or game to get. The name must exactly match the category’s or game’s title. Include this parameter for each category or game you want to get. For example, `&name=foo&name=bar`. You may specify a maximum of 100 names. The endpoint ignores duplicate names and names that weren’t found.
  --igdb-id: list # The [IGDB](https://www.igdb.com/) ID of the game to get. Include this parameter for each game you want to get. For example, `&igdb_id=1234&igdb_id=5678`. You may specify a maximum of 100 IDs. The endpoint ignores duplicate and invalid IDs or IDs that weren’t found.
]: nothing -> record<data: table<id: string, name: string, box_art_url: string, igdb_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi") (serialize-qp "name" $name "multi") (serialize-qp "igdb_id" $igdb_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/games" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the broadcaster’s list of active goals.
#
# GET /goals
# Docs: https://dev.twitch.tv/docs/api/reference#get-creator-goals — Get Creator Goals
# operationId: get-creator-goals
export def "goals get-creator-goals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that created the goals. This ID must match the user ID in the user access token.
]: nothing -> record<data: table<id: string, broadcaster_id: string, broadcaster_name: string, broadcaster_login: string, type: string, description: string, current_amount: int, target_amount: int, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/goals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# BETA Gets the channel settings for configuration of the Guest Star feature for a particular host.
#
# GET /guest_star/channel_settings
# Docs: https://dev.twitch.tv/docs/api/reference#get-channel-guest-star-settings — Get Channel Guest Star Settings
# operationId: get-channel-guest-star-settings
export def "guest-star-channel-settings get-channel-guest-star-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster you want to get guest star settings for.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s chat room. This ID must match the user ID in the user access token.
]: nothing -> record<is_moderator_send_live_enabled: bool, slot_count: int, is_browser_source_audio_enabled: bool, group_layout: string, browser_source_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/guest_star/channel_settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# BETA Mutates the channel settings for configuration of the Guest Star feature for a particular host.
#
# PUT /guest_star/channel_settings
# Docs: https://dev.twitch.tv/docs/api/reference#update-channel-guest-star-settings — Update Channel Guest Star Settings
# operationId: update-channel-guest-star-settings
export def "guest-star-channel-settings update-channel-guest-star-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster you want to update Guest Star settings for.
  --is-moderator-send-live-enabled: oneof<nothing, bool> # Flag determining if Guest Star moderators have access to control whether a guest is live once assigned to a slot.
  --slot-count: int # Number of slots the Guest Star call interface will allow the host to add to a call. Required to be between 1 and 6. (format: int32)
  --is-browser-source-audio-enabled: oneof<nothing, bool> # Flag determining if Browser Sources subscribed to sessions on this channel should output audio
  --group-layout: string@group-layout-completer # This setting determines how the guests within a session should be laid out within the browser source. Can be one of the following values:       * `TILED_LAYOUT`: All live guests are tiled within the browser source with the same size. * `SCREENSHARE_LAYOUT`: All live guests are tiled within the browser source with the same size. If there is an active screen share, it is sized larger than the other guests. * `HORIZONTAL_LAYOUT`: All live guests are arranged in a horizontal bar within the browser source * `VERTICAL_LAYOUT`: All live guests are arranged in a vertical bar within the browser source
  --regenerate-browser-sources: oneof<nothing, bool> # Flag determining if Guest Star should regenerate the auth token associated with the channel’s browser sources. Providing a true value for this will immediately invalidate all browser sources previously configured in your streaming software.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/guest_star/channel_settings" $qp)
  let body = {is_moderator_send_live_enabled: $is_moderator_send_live_enabled, slot_count: $slot_count, is_browser_source_audio_enabled: $is_browser_source_audio_enabled, group_layout: $group_layout, regenerate_browser_sources: $regenerate_browser_sources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# BETA Gets information about an ongoing Guest Star session for a particular channel.
#
# GET /guest_star/session
# Docs: https://dev.twitch.tv/docs/api/reference#get-guest-star-session — Get Guest Star Session
# operationId: get-guest-star-session
export def "guest-star-session get-guest-star-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # ID for the user hosting the Guest Star session.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s chat room. This ID must match the user ID in the user access token.
]: nothing -> record<data: table<id: string, guests: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/guest_star/session" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# BETA Programmatically creates a Guest Star session on behalf of the broadcaster.
#
# POST /guest_star/session
# Docs: https://dev.twitch.tv/docs/api/reference#create-guest-star-session — Create Guest Star Session
# operationId: create-guest-star-session
export def "guest-star-session create-guest-star-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster you want to create a Guest Star session for. Provided `broadcaster_id` must match the `user_id` in the auth token.
]: nothing -> record<data: table<id: string, guests: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/guest_star/session" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# BETA Programmatically ends a Guest Star session on behalf of the broadcaster.
#
# DELETE /guest_star/session
# Docs: https://dev.twitch.tv/docs/api/reference#end-guest-star-session — End Guest Star Session
# operationId: end-guest-star-session
export def "guest-star-session end-guest-star-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster you want to end a Guest Star session for. Provided `broadcaster_id` must match the `user_id` in the auth token.
  --session-id: string # ID for the session to end on behalf of the broadcaster.
]: nothing -> record<data: table<id: string, guests: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "session_id" $session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/guest_star/session" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# BETA Provides the caller with a list of pending invites to a Guest Star session.
#
# GET /guest_star/invites
# Docs: https://dev.twitch.tv/docs/api/reference#get-guest-star-invites — Get Guest Star Invites
# operationId: get-guest-star-invites
export def "guest-star-invites get-guest-star-invites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster running the Guest Star session.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s chat room. This ID must match the `user_id` in the user access token.
  --session-id: string # The session ID to query for invite status.
]: nothing -> record<data: table<user_id: string, invited_at: string, status: string, is_video_enabled: bool, is_audio_enabled: bool, is_video_available: bool, is_audio_available: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar") (serialize-qp "session_id" $session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/guest_star/invites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# BETA Sends an invite to a specified guest on behalf of the broadcaster for a Guest Star session in progress.
#
# POST /guest_star/invites
# Docs: https://dev.twitch.tv/docs/api/reference#send-guest-star-invite — Send Guest Star Invite
# operationId: send-guest-star-invite
export def "guest-star-invites send-guest-star-invite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster running the Guest Star session.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s chat room. This ID must match the `user_id` in the user access token.
  --session-id: string # The session ID for the invite to be sent on behalf of the broadcaster.
  --guest-id: string # Twitch User ID for the guest to invite to the Guest Star session.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar") (serialize-qp "session_id" $session_id "scalar") (serialize-qp "guest_id" $guest_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/guest_star/invites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# BETA Revokes a previously sent invite for a Guest Star session.
#
# DELETE /guest_star/invites
# Docs: https://dev.twitch.tv/docs/api/reference#delete-guest-star-invite — Delete Guest Star Invite
# operationId: delete-guest-star-invite
export def "guest-star-invites delete-guest-star-invite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster running the Guest Star session.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s chat room. This ID must match the `user_id` in the user access token.
  --session-id: string # The ID of the session for the invite to be revoked on behalf of the broadcaster.
  --guest-id: string # Twitch User ID for the guest to revoke the Guest Star session invite from.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar") (serialize-qp "session_id" $session_id "scalar") (serialize-qp "guest_id" $guest_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/guest_star/invites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# BETA Allows a previously invited user to be assigned a slot within the active Guest Star session.
#
# POST /guest_star/slot
# Docs: https://dev.twitch.tv/docs/api/reference#assign-guest-star-slot — Assign Guest Star Slot
# operationId: assign-guest-star-slot
export def "guest-star-slot assign-guest-star-slot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster running the Guest Star session.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s chat room. This ID must match the `user_id` in the user access token.
  --session-id: string # The ID of the Guest Star session in which to assign the slot.
  --guest-id: string # The Twitch User ID corresponding to the guest to assign a slot in the session. This user must already have an invite to this session, and have indicated that they are ready to join.
  --slot-id: string # The slot assignment to give to the user. Must be a numeric identifier between “1” and “N” where N is the max number of slots for the session. Max number of slots allowed for the session is reported by [Get Channel Guest Star Settings](https://dev.twitch.tv/docs/api/reference#get-channel-guest-star-settings).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar") (serialize-qp "session_id" $session_id "scalar") (serialize-qp "guest_id" $guest_id "scalar") (serialize-qp "slot_id" $slot_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/guest_star/slot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# BETA Allows a user to update the assigned slot for a particular user within the active Guest Star session.
#
# PATCH /guest_star/slot
# Docs: https://dev.twitch.tv/docs/api/reference#update-guest-star-slot — Update Guest Star Slot
# operationId: update-guest-star-slot
export def "guest-star-slot update-guest-star-slot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster running the Guest Star session.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s chat room. This ID must match the `user_id` in the user access token.
  --session-id: string # The ID of the Guest Star session in which to update slot settings.
  --source-slot-id: string # The slot assignment previously assigned to a user.
  --destination-slot-id: string # The slot to move this user assignment to. If the destination slot is occupied, the user assigned will be swapped into `source_slot_id`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar") (serialize-qp "session_id" $session_id "scalar") (serialize-qp "source_slot_id" $source_slot_id "scalar") (serialize-qp "destination_slot_id" $destination_slot_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/guest_star/slot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# BETA Allows a caller to remove a slot assignment from a user participating in an active Guest Star session.
#
# DELETE /guest_star/slot
# Docs: https://dev.twitch.tv/docs/api/reference#delete-guest-star-slot — Delete Guest Star Slot
# operationId: delete-guest-star-slot
export def "guest-star-slot delete-guest-star-slot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster running the Guest Star session.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s chat room. This ID must match the user ID in the user access token.
  --session-id: string # The ID of the Guest Star session in which to remove the slot assignment.
  --guest-id: string # The Twitch User ID corresponding to the guest to remove from the session.
  --slot-id: string # The slot ID representing the slot assignment to remove from the session.
  --should-reinvite-guest: string # Flag signaling that the guest should be reinvited to the session, sending them back to the invite queue.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar") (serialize-qp "session_id" $session_id "scalar") (serialize-qp "guest_id" $guest_id "scalar") (serialize-qp "slot_id" $slot_id "scalar") (serialize-qp "should_reinvite_guest" $should_reinvite_guest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/guest_star/slot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# BETA Allows a user to update slot settings for a particular guest within a Guest Star session.
#
# PATCH /guest_star/slot_settings
# Docs: https://dev.twitch.tv/docs/api/reference#update-guest-star-slot-settings — Update Guest Star Slot Settings
# operationId: update-guest-star-slot-settings
export def "guest-star-slot-settings update-guest-star-slot-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster running the Guest Star session.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s chat room. This ID must match the user ID in the user access token.
  --session-id: string # The ID of the Guest Star session in which to update a slot’s settings.
  --slot-id: string # The slot assignment that has previously been assigned to a user.
  --is-audio-enabled: oneof<nothing, bool> # Flag indicating whether the slot is allowed to share their audio with the rest of the session. If false, the slot will be muted in any views containing the slot.
  --is-video-enabled: oneof<nothing, bool> # Flag indicating whether the slot is allowed to share their video with the rest of the session. If false, the slot will have no video shared in any views containing the slot.
  --is-live: oneof<nothing, bool> # Flag indicating whether the user assigned to this slot is visible/can be heard from any public subscriptions. Generally, this determines whether or not the slot is enabled in any broadcasting software integrations.
  --volume: int # Value from 0-100 that controls the audio volume for shared views containing the slot. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar") (serialize-qp "session_id" $session_id "scalar") (serialize-qp "slot_id" $slot_id "scalar") (serialize-qp "is_audio_enabled" $is_audio_enabled "scalar") (serialize-qp "is_video_enabled" $is_video_enabled "scalar") (serialize-qp "is_live" $is_live "scalar") (serialize-qp "volume" $volume "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/guest_star/slot_settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# NEW Gets the status of a Hype Train for the specified broadcaster.
#
# GET /hypetrain/status
# Docs: https://dev.twitch.tv/docs/api/reference#get-hype-train-status — Get Hype Train Status
# operationId: get-hype-train-status
export def "hypetrain-status get-hype-train-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The User ID of the channel broadcaster.
]: nothing -> record<data: table<current: record>, all_time_high: record<level: int, total: int, achieved_at: string>, shared_all_time_high: record<level: int, total: int, achieved_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hypetrain/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks whether AutoMod would flag the specified message for review.
#
# POST /moderation/enforcements/status
# Docs: https://dev.twitch.tv/docs/api/reference#check-automod-status — Check AutoMod Status
# operationId: check-automod-status
# --data item shape: {msg_id: string, msg_text: string}
export def "moderation-enforcements-status check-automod-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose AutoMod settings and list of blocked terms are used to check the message. This ID must match the user ID in the access token.
  data: list # The list of messages to check. The list must contain at least one message and may contain up to a maximum of 100 messages. — item shape: {msg_id: string, msg_text: string}
]: any -> record<data: table<msg_id: string, is_permitted: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/enforcements/status" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Allow or deny the message that AutoMod flagged for review.
#
# POST /moderation/automod/message
# Docs: https://dev.twitch.tv/docs/api/reference#manage-held-automod-messages — Manage Held AutoMod Messages
# operationId: manage-held-automod-messages
export def "moderation-automod-message manage-held-automod-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_id: string # The moderator who is approving or denying the held message. This ID must match the user ID in the access token.
  msg_id: string # The ID of the message to allow or deny.
  action: string@action-completer # The action to take for the message. Possible values are:      * ALLOW * DENY
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/moderation/automod/message")
  let body = {user_id: $user_id, msg_id: $msg_id, action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the broadcaster’s AutoMod settings.
#
# GET /moderation/automod/settings
# Docs: https://dev.twitch.tv/docs/api/reference#get-automod-settings — Get AutoMod Settings
# operationId: get-automod-settings
export def "moderation-automod-settings get-automod-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose AutoMod settings you want to get.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s chat room. This ID must match the user ID in the user access token.
]: nothing -> record<data: table<broadcaster_id: string, moderator_id: string, overall_level: int, disability: int, aggression: int, sexuality_sex_or_gender: int, misogyny: int, bullying: int, swearing: int, race_ethnicity_or_religion: int, sex_based_terms: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/automod/settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the broadcaster’s AutoMod settings.
#
# PUT /moderation/automod/settings
# Docs: https://dev.twitch.tv/docs/api/reference#update-automod-settings — Update AutoMod Settings
# operationId: update-automod-settings
export def "moderation-automod-settings update-automod-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose AutoMod settings you want to update.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s chat room. This ID must match the user ID in the user access token.
  --aggression: int # The Automod level for hostility involving aggression. (format: int32)
  --bullying: int # The Automod level for hostility involving name calling or insults. (format: int32)
  --disability: int # The Automod level for discrimination against disability. (format: int32)
  --misogyny: int # The Automod level for discrimination against women. (format: int32)
  --overall-level: int # The default AutoMod level for the broadcaster. (format: int32)
  --race-ethnicity-or-religion: int # The Automod level for racial discrimination. (format: int32)
  --sex-based-terms: int # The Automod level for sexual content. (format: int32)
  --sexuality-sex-or-gender: int # The AutoMod level for discrimination based on sexuality, sex, or gender. (format: int32)
  --swearing: int # The Automod level for profanity. (format: int32)
]: any -> record<data: table<broadcaster_id: string, moderator_id: string, overall_level: int, disability: int, aggression: int, sexuality_sex_or_gender: int, misogyny: int, bullying: int, swearing: int, race_ethnicity_or_religion: int, sex_based_terms: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/automod/settings" $qp)
  let body = {aggression: $aggression, bullying: $bullying, disability: $disability, misogyny: $misogyny, overall_level: $overall_level, race_ethnicity_or_religion: $race_ethnicity_or_religion, sex_based_terms: $sex_based_terms, sexuality_sex_or_gender: $sexuality_sex_or_gender, swearing: $swearing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all users that the broadcaster banned or put in a timeout.
#
# GET /moderation/banned
# Docs: https://dev.twitch.tv/docs/api/reference#get-banned-users — Get Banned Users
# operationId: get-banned-users
export def "moderation-banned get-banned-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose list of banned users you want to get. This ID must match the user ID in the access token.
  --user-id: list # A list of user IDs used to filter the results. To specify more than one ID, include this parameter for each user you want to get. For example, `user_id=1234&user_id=5678`. You may specify a maximum of 100 IDs.      The returned list includes only those users that were banned or put in a timeout. The list is returned in the same order that you specified the IDs.
  --first: int # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100 items per page. The default is 20. (format: int32)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
  --before: string # The cursor used to get the previous page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<user_id: string, user_login: string, user_name: string, expires_at: string, created_at: string, reason: string, moderator_id: string, moderator_login: string, moderator_name: string>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "user_id" $user_id "multi") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/banned" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bans a user from participating in a broadcaster’s chat room or puts them in a timeout.
#
# POST /moderation/bans
# Docs: https://dev.twitch.tv/docs/api/reference#ban-user — Ban User
# operationId: ban-user
# --data shape: {user_id: string, duration?: int, reason?: string}
export def "moderation-bans ban-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose chat room the user is being banned from.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s chat room. This ID must match the user ID in the user access token.
  data: record # Identifies the user and type of ban. — shape: {user_id: string, duration?: int, reason?: string}
]: any -> record<data: table<broadcaster_id: string, moderator_id: string, user_id: string, created_at: string, end_time: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/bans" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes the ban or timeout that was placed on the specified user.
#
# DELETE /moderation/bans
# Docs: https://dev.twitch.tv/docs/api/reference#unban-user — Unban User
# operationId: unban-user
export def "moderation-bans unban-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose chat room the user is banned from chatting in.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s chat room. This ID must match the user ID in the user access token.
  --user-id: string # The ID of the user to remove the ban or timeout from.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/bans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of unban requests for a broadcaster’s channel.
#
# GET /moderation/unban_requests
# Docs: https://dev.twitch.tv/docs/api/reference#get-unban-requests — Get Unban Requests
# operationId: get-unban-requests
export def "moderation-unban-requests get-unban-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose channel is receiving unban requests.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s unban requests. This ID must match the user ID in the user access token.
  --status: string # Filter by a status.      * pending * approved * denied * acknowledged * canceled
  --user-id: string # The ID used to filter what unban requests are returned.
  --after: string # Cursor used to get next page of results. Pagination object in response contains cursor value.
  --first: int # The maximum number of items to return per page in response (format: int32)
]: nothing -> record<data: table<id: string, broadcaster_id: string, broadcaster_name: string, broadcaster_login: string, moderator_id: string, moderator_login: string, moderator_name: string, user_id: string, user_login: string, user_name: string, text: string, status: string, created_at: string, resolved_at: string, resolution_text: string>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "first" $first "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/unban_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resolves an unban request by approving or denying it.
#
# PATCH /moderation/unban_requests
# Docs: https://dev.twitch.tv/docs/api/reference#resolve-unban-requests — Resolve Unban Requests
# operationId: resolve-unban-requests
export def "moderation-unban-requests resolve-unban-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose channel is approving or denying the unban request.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s unban requests. This ID must match the user ID in the user access token.
  --unban-request-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s unban requests. This ID must match the user ID in the user access token.
  --status: string # Resolution status.       * approved * denied
  --resolution-text: string # Message supplied by the unban request resolver. The message is limited to a maximum of 500 characters.
]: nothing -> record<data: table<id: string, broadcaster_id: string, broadcaster_login: string, broadcaster_name: string, moderator_id: string, moderator_login: string, moderator_name: string, user_id: string, user_login: string, user_name: string, text: string, status: string, created_at: string, resolved_at: string, resolution_text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar") (serialize-qp "unban_request_id" $unban_request_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "resolution_text" $resolution_text "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/unban_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the broadcaster’s list of non-private, blocked words or phrases.
#
# GET /moderation/blocked_terms
# Docs: https://dev.twitch.tv/docs/api/reference#get-blocked-terms — Get Blocked Terms
# operationId: get-blocked-terms
export def "moderation-blocked-terms get-blocked-terms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose blocked terms you’re getting.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s chat room. This ID must match the user ID in the user access token.
  --first: int # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100 items per page. The default is 20. (format: int32)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value.
]: nothing -> record<data: table<broadcaster_id: string, moderator_id: string, id: string, text: string, created_at: string, updated_at: string, expires_at: string>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/blocked_terms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a word or phrase to the broadcaster’s list of blocked terms.
#
# POST /moderation/blocked_terms
# Docs: https://dev.twitch.tv/docs/api/reference#add-blocked-term — Add Blocked Term
# operationId: add-blocked-term
export def "moderation-blocked-terms add-blocked-term" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that owns the list of blocked terms.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s chat room. This ID must match the user ID in the user access token.
  text: string # The word or phrase to block from being used in the broadcaster’s chat room. The term must contain a minimum of 2 characters and may contain up to a maximum of 500 characters.      Terms may include a wildcard character (\*). The wildcard character must appear at the beginning or end of a word or set of characters. For example, \*foo or foo\*.      If the blocked term already exists, the response contains the existing blocked term.
]: any -> record<data: table<broadcaster_id: string, moderator_id: string, id: string, text: string, created_at: string, updated_at: string, expires_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/blocked_terms" $qp)
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes the word or phrase from the broadcaster’s list of blocked terms.
#
# DELETE /moderation/blocked_terms
# Docs: https://dev.twitch.tv/docs/api/reference#remove-blocked-term — Remove Blocked Term
# operationId: remove-blocked-term
export def "moderation-blocked-terms remove-blocked-term" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that owns the list of blocked terms.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s chat room. This ID must match the user ID in the user access token.
  --id: string # The ID of the blocked term to remove from the broadcaster’s list of blocked terms.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/blocked_terms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a single chat message or all chat messages from the broadcaster’s chat room.
#
# DELETE /moderation/chat
# Docs: https://dev.twitch.tv/docs/api/reference#delete-chat-messages — Delete Chat Messages
# operationId: delete-chat-messages
export def "moderation-chat delete-chat-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that owns the chat room to remove messages from.
  --moderator-id: string # The ID of the broadcaster or a user that has permission to moderate the broadcaster’s chat room. This ID must match the user ID in the user access token.
  --message-id: string # The ID of the message to remove. The `id` tag in the [PRIVMSG](https://dev.twitch.tv/docs/irc/tags#privmsg-tags) tag contains the message’s ID. Restrictions:      * The message must have been created within the last 6 hours. * The message must not belong to the broadcaster. * The message must not belong to another moderator.    If not specified, the request removes all messages in the broadcaster’s chat room.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar") (serialize-qp "message_id" $message_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/chat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of channels that the specified user has moderator privileges in.
#
# GET /moderation/channels
# Docs: https://dev.twitch.tv/docs/api/reference#get-moderated-channels — Get Moderated Channels
# operationId: get-moderated-channels
export def "moderation-channels get-moderated-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # A user’s ID. Returns the list of channels that this user has moderator privileges in. This ID must match the user ID in the user OAuth token
  --after: string # The cursor used to get the next page of results. The Pagination object in the response contains the cursor’s value.
  --first: int # The maximum number of items to return per page in the response.      Minimum page size is 1 item per page and the maximum is 100\. The default is 20. (format: int32)
]: nothing -> record<data: table<broadcaster_id: string, broadcaster_login: string, broadcaster_name: string>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "first" $first "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all users allowed to moderate the broadcaster’s chat room.
#
# GET /moderation/moderators
# Docs: https://dev.twitch.tv/docs/api/reference#get-moderators — Get Moderators
# operationId: get-moderators
export def "moderation-moderators get-moderators" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose list of moderators you want to get. This ID must match the user ID in the access token.
  --user-id: list # A list of user IDs used to filter the results. To specify more than one ID, include this parameter for each moderator you want to get. For example, `user_id=1234&user_id=5678`. You may specify a maximum of 100 IDs.      The returned list includes only the users from the list who are moderators in the broadcaster’s channel. The list is returned in the same order as you specified the IDs.
  --first: string # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100 items per page. The default is 20.
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<user_id: string, user_login: string, user_name: string>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "user_id" $user_id "multi") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/moderators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a moderator to the broadcaster’s chat room.
#
# POST /moderation/moderators
# Docs: https://dev.twitch.tv/docs/api/reference#add-channel-moderator — Add Channel Moderator
# operationId: add-channel-moderator
export def "moderation-moderators add-channel-moderator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that owns the chat room. This ID must match the user ID in the access token.
  --user-id: string # The ID of the user to add as a moderator in the broadcaster’s chat room.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/moderators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a moderator from the broadcaster’s chat room.
#
# DELETE /moderation/moderators
# Docs: https://dev.twitch.tv/docs/api/reference#remove-channel-moderator — Remove Channel Moderator
# operationId: remove-channel-moderator
export def "moderation-moderators remove-channel-moderator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that owns the chat room. This ID must match the user ID in the access token.
  --user-id: string # The ID of the user to remove as a moderator from the broadcaster’s chat room.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/moderators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of the broadcaster’s VIPs.
#
# GET /channels/vips
# Docs: https://dev.twitch.tv/docs/api/reference#get-vips — Get VIPs
# operationId: get-vips
export def "channels-vips get-vips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: list # Filters the list for specific VIPs. To specify more than one user, include the _user\_id_ parameter for each user to get. For example, `&user_id=1234&user_id=5678`. The maximum number of IDs that you may specify is 100\. Ignores the ID of those users in the list that aren’t VIPs.
  --broadcaster-id: string # The ID of the broadcaster whose list of VIPs you want to get. This ID must match the user ID in the access token.
  --first: int # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100\. The default is 20. (format: int32)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<user_id: string, user_name: string, user_login: string>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "multi") (serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels/vips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds the specified user as a VIP in the broadcaster’s channel.
#
# POST /channels/vips
# Docs: https://dev.twitch.tv/docs/api/reference#add-channel-vip — Add Channel VIP
# operationId: add-channel-vip
export def "channels-vips add-channel-vip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The ID of the user to give VIP status to.
  --broadcaster-id: string # The ID of the broadcaster that’s adding the user as a VIP. This ID must match the user ID in the access token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels/vips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes the specified user as a VIP in the broadcaster’s channel.
#
# DELETE /channels/vips
# Docs: https://dev.twitch.tv/docs/api/reference#remove-channel-vip — Remove Channel VIP
# operationId: remove-channel-vip
export def "channels-vips remove-channel-vip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The ID of the user to remove VIP status from.
  --broadcaster-id: string # The ID of the broadcaster who owns the channel where the user has VIP status.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels/vips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Activates or deactivates the broadcaster’s Shield Mode.
#
# PUT /moderation/shield_mode
# Docs: https://dev.twitch.tv/docs/api/reference#update-shield-mode-status — Update Shield Mode Status
# operationId: update-shield-mode-status
export def "moderation-shield-mode update-shield-mode-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose Shield Mode you want to activate or deactivate.
  --moderator-id: string # The ID of the broadcaster or a user that is one of the broadcaster’s moderators. This ID must match the user ID in the access token.
  --is-active: oneof<nothing, bool> # A Boolean value that determines whether to activate Shield Mode. Set to **true** to activate Shield Mode; otherwise, **false** to deactivate Shield Mode.
]: any -> record<data: table<is_active: bool, moderator_id: string, moderator_login: string, moderator_name: string, last_activated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/shield_mode" $qp)
  let body = {is_active: $is_active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the broadcaster’s Shield Mode activation status.
#
# GET /moderation/shield_mode
# Docs: https://dev.twitch.tv/docs/api/reference#get-shield-mode-status — Get Shield Mode Status
# operationId: get-shield-mode-status
export def "moderation-shield-mode get-shield-mode-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose Shield Mode activation status you want to get.
  --moderator-id: string # The ID of the broadcaster or a user that is one of the broadcaster’s moderators. This ID must match the user ID in the access token.
]: nothing -> record<data: table<is_active: bool, moderator_id: string, moderator_login: string, moderator_name: string, last_activated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/shield_mode" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Warns a user in the specified broadcaster’s chat room, preventing them from chat interaction until the warning is acknowledged.
#
# POST /moderation/warnings
# Docs: https://dev.twitch.tv/docs/api/reference#warn-chat-user — Warn Chat User
# operationId: warn-chat-user
# --data shape: {user_id: string, reason: string}
export def "moderation-warnings warn-chat-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the channel in which the warning will take effect.
  --moderator-id: string # The ID of the twitch user who requested the warning.
  data: record # A list that contains information about the warning. — shape: {user_id: string, reason: string}
]: any -> record<data: table<broadcaster_id: string, user_id: string, moderator_id: string, reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/warnings" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# NEW Adds a suspicious user status to a chatter on the broadcaster’s channel.
#
# POST /moderation/suspicious_users
# Docs: https://dev.twitch.tv/docs/api/reference#add-suspicious-status-to-chat-user — Add Suspicious Status to Chat User
# operationId: add-suspicious-status-to-chat-user
export def "moderation-suspicious-users add-suspicious-status-to-chat-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The user ID of the broadcaster, indicating the channel where the status is being applied.
  --moderator-id: string # The user ID of the moderator who is applying the status.
  user_id: string # The ID of the user being given the suspicious status.
  status: string@status-completer-3 # The type of suspicious status. Possible values are: ACTIVE\_MONITORING, RESTRICTED
]: any -> record<data: table<user_id: string, broadcaster_id: string, moderator_id: string, updated_at: string, status: string, types: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/suspicious_users" $qp)
  let body = {user_id: $user_id, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# NEW Remove a suspicious user status from a chatter on broadcaster’s channel.
#
# DELETE /moderation/suspicious_users
# Docs: https://dev.twitch.tv/docs/api/reference#remove-suspicious-status-from-chat-user — Remove Suspicious Status From Chat User
# operationId: remove-suspicious-status-from-chat-user
export def "moderation-suspicious-users remove-suspicious-status-from-chat-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The user ID of the broadcaster, indicating the channel where the status is being removed.
  --moderator-id: string # The user ID of the moderator who is removing the status.
  --user-id: string # The ID of the user having the suspicious status removed.
]: nothing -> record<data: table<user_id: string, broadcaster_id: string, moderator_id: string, updated_at: string, status: string, types: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "moderator_id" $moderator_id "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/suspicious_users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of polls that the broadcaster created.
#
# GET /polls
# Docs: https://dev.twitch.tv/docs/api/reference#get-polls — Get Polls
# operationId: get-polls
export def "polls get-polls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that created the polls. This ID must match the user ID in the user access token.
  --id: list # A list of IDs that identify the polls to return. To specify more than one ID, include this parameter for each poll you want to get. For example, `id=1234&id=5678`. You may specify a maximum of 20 IDs.      Specify this parameter only if you want to filter the list that the request returns. The endpoint ignores duplicate IDs and those not owned by this broadcaster.
  --first: string # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 20 items per page. The default is 20.
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<id: string, broadcaster_id: string, broadcaster_name: string, broadcaster_login: string, title: string, choices: list, bits_voting_enabled: bool, bits_per_vote: int, channel_points_voting_enabled: bool, channel_points_per_vote: int, status: string, duration: int, started_at: string, ended_at: string>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "id" $id "multi") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/polls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a poll that viewers in the broadcaster’s channel can vote on.
#
# POST /polls
# Docs: https://dev.twitch.tv/docs/api/reference#create-poll — Create Poll
# operationId: create-poll
# --choices item shape: {title: string}
export def "polls create-poll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  broadcaster_id: string # The ID of the broadcaster that’s running the poll. This ID must match the user ID in the user access token.
  title: string # The question that viewers will vote on. For example, _What game should I play next?_ The question may contain a maximum of 60 characters.
  choices: list # A list of choices that viewers may choose from. The list must contain a minimum of 2 choices and up to a maximum of 5 choices. — item shape: {title: string}
  duration: int # The length of time (in seconds) that the poll will run for. The minimum is 15 seconds and the maximum is 1800 seconds (30 minutes). (format: int32)
  --channel-points-voting-enabled: oneof<nothing, bool> # A Boolean value that indicates whether viewers may cast additional votes using Channel Points. If **true**, the viewer may cast more than one vote but each additional vote costs the number of Channel Points specified in `channel_points_per_vote`. The default is **false** (viewers may cast only one vote). For information about Channel Points, see [Channel Points Guide](https://help.twitch.tv/s/article/channel-points-guide).
  --channel-points-per-vote: int # The number of points that the viewer must spend to cast one additional vote. The minimum is 1 and the maximum is 1000000\. Set only if `ChannelPointsVotingEnabled` is **true**. (format: int32)
]: any -> record<data: table<id: string, broadcaster_id: string, broadcaster_name: string, broadcaster_login: string, title: string, choices: list, bits_voting_enabled: bool, bits_per_vote: int, channel_points_voting_enabled: bool, channel_points_per_vote: int, status: string, duration: int, started_at: string, ended_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/polls")
  let body = {broadcaster_id: $broadcaster_id, title: $title, choices: $choices, duration: $duration, channel_points_voting_enabled: $channel_points_voting_enabled, channel_points_per_vote: $channel_points_per_vote} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# End an active poll.
#
# PATCH /polls
# Docs: https://dev.twitch.tv/docs/api/reference#end-poll — End Poll
# operationId: end-poll
export def "polls end-poll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  broadcaster_id: string # The ID of the broadcaster that’s running the poll. This ID must match the user ID in the user access token.
  id: string # The ID of the poll to update.
  status: string@status-completer-4 # The status to set the poll to. Possible case-sensitive values are:      * TERMINATED — Ends the poll before the poll is scheduled to end. The poll remains publicly visible. * ARCHIVED — Ends the poll before the poll is scheduled to end, and then archives it so it's no longer publicly visible.
]: any -> record<data: table<id: string, broadcaster_id: string, broadcaster_name: string, broadcaster_login: string, title: string, choices: list, bits_voting_enabled: bool, bits_per_vote: int, channel_points_voting_enabled: bool, channel_points_per_vote: int, status: string, duration: int, started_at: string, ended_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/polls")
  let body = {broadcaster_id: $broadcaster_id, id: $id, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of Channel Points Predictions that the broadcaster created.
#
# GET /predictions
# Docs: https://dev.twitch.tv/docs/api/reference#get-predictions — Get Predictions
# operationId: get-predictions
export def "predictions get-predictions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose predictions you want to get. This ID must match the user ID in the user access token.
  --id: list # The ID of the prediction to get. To specify more than one ID, include this parameter for each prediction you want to get. For example, `id=1234&id=5678`. You may specify a maximum of 25 IDs. The endpoint ignores duplicate IDs and those not owned by the broadcaster.
  --first: string # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 25 items per page. The default is 20.
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<id: string, broadcaster_id: string, broadcaster_name: string, broadcaster_login: string, title: string, winning_outcome_id: string, outcomes: list, prediction_window: int, status: string, created_at: string, ended_at: string, locked_at: string>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "id" $id "multi") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/predictions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Channel Points Prediction.
#
# POST /predictions
# Docs: https://dev.twitch.tv/docs/api/reference#create-prediction — Create Prediction
# operationId: create-prediction
# --outcomes item shape: {title: string}
export def "predictions create-prediction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  broadcaster_id: string # The ID of the broadcaster that’s running the prediction. This ID must match the user ID in the user access token.
  title: string # The question that the broadcaster is asking. For example, _Will I finish this entire pizza?_ The title is limited to a maximum of 45 characters.
  outcomes: list # The list of possible outcomes that the viewers may choose from. The list must contain a minimum of 2 choices and up to a maximum of 10 choices. — item shape: {title: string}
  prediction_window: int # The length of time (in seconds) that the prediction will run for. The minimum is 30 seconds and the maximum is 1800 seconds (30 minutes). (format: int32)
]: any -> record<data: table<id: string, broadcaster_id: string, broadcaster_name: string, broadcaster_login: string, title: string, winning_outcome_id: string, outcomes: list, prediction_window: int, status: string, created_at: string, ended_at: string, locked_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/predictions")
  let body = {broadcaster_id: $broadcaster_id, title: $title, outcomes: $outcomes, prediction_window: $prediction_window} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Locks, resolves, or cancels a Channel Points Prediction.
#
# PATCH /predictions
# Docs: https://dev.twitch.tv/docs/api/reference#end-prediction — End Prediction
# operationId: end-prediction
export def "predictions end-prediction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  broadcaster_id: string # The ID of the broadcaster that’s running the prediction. This ID must match the user ID in the user access token.
  id: string # The ID of the prediction to update.
  status: string@status-completer-5 # The status to set the prediction to. Possible case-sensitive values are:      * RESOLVED — The winning outcome is determined and the Channel Points are distributed to the viewers who predicted the correct outcome. * CANCELED — The broadcaster is canceling the prediction and sending refunds to the participants. * LOCKED — The broadcaster is locking the prediction, which means viewers may no longer make predictions.    The broadcaster can update an active prediction to LOCKED, RESOLVED, or CANCELED; and update a locked prediction to RESOLVED or CANCELED.      The broadcaster has up to 24 hours after the prediction window closes to resolve the prediction. If not, Twitch sets the status to CANCELED and returns the points.
  --winning-outcome-id: string # The ID of the winning outcome. You must set this parameter if you set `status` to RESOLVED.
]: any -> record<data: table<id: string, broadcaster_id: string, broadcaster_name: string, broadcaster_login: string, title: string, winning_outcome_id: string, outcomes: list, prediction_window: int, status: string, created_at: string, ended_at: string, locked_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/predictions")
  let body = {broadcaster_id: $broadcaster_id, id: $id, status: $status, winning_outcome_id: $winning_outcome_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Raid another channel by sending the broadcaster’s viewers to the targeted channel.
#
# POST /raids
# Docs: https://dev.twitch.tv/docs/api/reference#start-a-raid — Start a raid
# operationId: start-a-raid
export def "raids start-a-raid" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-broadcaster-id: string # The ID of the broadcaster that’s sending the raiding party. This ID must match the user ID in the user access token.
  --to-broadcaster-id: string # The ID of the broadcaster to raid.
]: nothing -> record<data: table<created_at: string, is_mature: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from_broadcaster_id" $from_broadcaster_id "scalar") (serialize-qp "to_broadcaster_id" $to_broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/raids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel a pending raid.
#
# DELETE /raids
# Docs: https://dev.twitch.tv/docs/api/reference#cancel-a-raid — Cancel a raid
# operationId: cancel-a-raid
export def "raids cancel-a-raid" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that initiated the raid. This ID must match the user ID in the user access token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/raids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the broadcaster’s streaming schedule.
#
# GET /schedule
# Docs: https://dev.twitch.tv/docs/api/reference#get-channel-stream-schedule — Get Channel Stream Schedule
# operationId: get-channel-stream-schedule
export def "schedule get-channel-stream-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that owns the streaming schedule you want to get.
  --id: list # The ID of the scheduled segment to return. To specify more than one segment, include the ID of each segment you want to get. For example, `id=1234&id=5678`. You may specify a maximum of 100 IDs.
  --start-time: string # The UTC date and time that identifies when in the broadcaster’s schedule to start returning segments. If not specified, the request returns segments starting after the current UTC date and time. Specify the date and time in RFC3339 format (for example, `2022-09-01T00:00:00Z`). (format: date-time)
  --utc-offset: string # Not supported.
  --first: int # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 25 items per page. The default is 20. (format: int32)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: record<segments: list<record>, broadcaster_id: string, broadcaster_name: string, broadcaster_login: string, vacation: record<start_time: string, end_time: string>, pagination: record<cursor: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "id" $id "multi") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "utc_offset" $utc_offset "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedule" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the broadcaster’s streaming schedule as an iCalendar.
#
# GET /schedule/icalendar
# Docs: https://dev.twitch.tv/docs/api/reference#get-channel-icalendar — Get Channel iCalendar
# operationId: get-channel-icalendar
export def "schedule-icalendar get-channel-icalendar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that owns the streaming schedule you want to get.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedule/icalendar" $qp)
  let accept_val = "text/calendar"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the broadcaster’s schedule settings, such as scheduling a vacation.
#
# PATCH /schedule/settings
# Docs: https://dev.twitch.tv/docs/api/reference#update-channel-stream-schedule — Update Channel Stream Schedule
# operationId: update-channel-stream-schedule
export def "schedule-settings update-channel-stream-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose schedule settings you want to update. The ID must match the user ID in the user access token.
  --is-vacation-enabled: oneof<nothing, bool> # A Boolean value that indicates whether the broadcaster has scheduled a vacation. Set to **true** to enable Vacation Mode and add vacation dates, or **false** to cancel a previously scheduled vacation.
  --vacation-start-time: string # The UTC date and time of when the broadcaster’s vacation starts. Specify the date and time in RFC3339 format (for example, 2021-05-16T00:00:00Z). Required if _is\_vacation\_enabled_ is **true**. (format: date-time)
  --vacation-end-time: string # The UTC date and time of when the broadcaster’s vacation ends. Specify the date and time in RFC3339 format (for example, 2021-05-30T23:59:59Z). Required if _is\_vacation\_enabled_ is **true**. (format: date-time)
  --timezone: string # The time zone that the broadcaster broadcasts from. Specify the time zone using [IANA time zone database](https://www.iana.org/time-zones) format (for example, America/New\_York). Required if _is\_vacation\_enabled_ is **true**.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "is_vacation_enabled" $is_vacation_enabled "scalar") (serialize-qp "vacation_start_time" $vacation_start_time "scalar") (serialize-qp "vacation_end_time" $vacation_end_time "scalar") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedule/settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a single or recurring broadcast to the broadcaster’s streaming schedule.
#
# POST /schedule/segment
# Docs: https://dev.twitch.tv/docs/api/reference#create-channel-stream-schedule-segment — Create Channel Stream Schedule Segment
# operationId: create-channel-stream-schedule-segment
export def "schedule-segment create-channel-stream-schedule-segment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that owns the schedule to add the broadcast segment to. This ID must match the user ID in the user access token.
  start_time: string # The date and time that the broadcast segment starts. Specify the date and time in RFC3339 format (for example, 2021-07-01T18:00:00Z). (format: date-time)
  timezone: string # The time zone where the broadcast takes place. Specify the time zone using [IANA time zone database](https://www.iana.org/time-zones) format (for example, America/New\_York).
  duration: string # The length of time, in minutes, that the broadcast is scheduled to run. The duration must be in the range 30 through 1380 (23 hours).
  --is-recurring: oneof<nothing, bool> # A Boolean value that determines whether the broadcast recurs weekly. Is **true** if the broadcast recurs weekly. Only partners and affiliates may add non-recurring broadcasts.
  --category-id: string # The ID of the category that best represents the broadcast’s content. To get the category ID, use the [Search Categories](https://dev.twitch.tv/docs/api/reference#search-categories) endpoint.
  --title: string # The broadcast’s title. The title may contain a maximum of 140 characters.
]: any -> record<data: record<segments: list<record>, broadcaster_id: string, broadcaster_name: string, broadcaster_login: string, vacation: record<start_time: string, end_time: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedule/segment" $qp)
  let body = {start_time: $start_time, timezone: $timezone, duration: $duration, is_recurring: $is_recurring, category_id: $category_id, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a scheduled broadcast segment.
#
# PATCH /schedule/segment
# Docs: https://dev.twitch.tv/docs/api/reference#update-channel-stream-schedule-segment — Update Channel Stream Schedule Segment
# operationId: update-channel-stream-schedule-segment
export def "schedule-segment update-channel-stream-schedule-segment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster who owns the broadcast segment to update. This ID must match the user ID in the user access token.
  --id: string # The ID of the broadcast segment to update.
  --start-time: string # The date and time that the broadcast segment starts. Specify the date and time in RFC3339 format (for example, 2022-08-02T06:00:00Z).      **NOTE**: Only partners and affiliates may update a broadcast’s start time and only for non-recurring segments. (format: date-time)
  --duration: string # The length of time, in minutes, that the broadcast is scheduled to run. The duration must be in the range 30 through 1380 (23 hours).
  --category-id: string # The ID of the category that best represents the broadcast’s content. To get the category ID, use the [Search Categories](https://dev.twitch.tv/docs/api/reference#search-categories) endpoint.
  --title: string # The broadcast’s title. The title may contain a maximum of 140 characters.
  --is-canceled: oneof<nothing, bool> # A Boolean value that indicates whether the broadcast is canceled. Set to **true** to cancel the segment.      **NOTE**: For recurring segments, the API cancels the first segment after the current UTC date and time and not the specified segment (unless the specified segment is the next segment after the current UTC date and time).
  --timezone: string # The time zone where the broadcast takes place. Specify the time zone using [IANA time zone database](https://www.iana.org/time-zones) format (for example, America/New\_York).
]: any -> record<data: record<segments: list<record>, broadcaster_id: string, broadcaster_name: string, broadcaster_login: string, vacation: record<start_time: string, end_time: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedule/segment" $qp)
  let body = {start_time: $start_time, duration: $duration, category_id: $category_id, title: $title, is_canceled: $is_canceled, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a broadcast from the broadcaster’s streaming schedule.
#
# DELETE /schedule/segment
# Docs: https://dev.twitch.tv/docs/api/reference#delete-channel-stream-schedule-segment — Delete Channel Stream Schedule Segment
# operationId: delete-channel-stream-schedule-segment
export def "schedule-segment delete-channel-stream-schedule-segment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that owns the streaming schedule. This ID must match the user ID in the user access token.
  --id: string # The ID of the broadcast segment to remove.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedule/segment" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the games or categories that match the specified query.
#
# GET /search/categories
# Docs: https://dev.twitch.tv/docs/api/reference#search-categories — Search Categories
# operationId: search-categories
export def "search-categories search-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # The URI-encoded search string. For example, encode _#archery_ as `%23archery` and search strings like _angel of death_ as `angel%20of%20death`.
  --first: int # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100 items per page. The default is 20. (format: int32)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<box_art_url: string, name: string, id: string>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the channels that match the specified query and have streamed content within the past 6 months.
#
# GET /search/channels
# Docs: https://dev.twitch.tv/docs/api/reference#search-channels — Search Channels
# operationId: search-channels
export def "search-channels search-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # The URI-encoded search string. For example, encode search strings like _angel of death_ as `angel%20of%20death`.
  --live-only: oneof<nothing, bool> # A Boolean value that determines whether the response includes only channels that are currently streaming live. Set to **true** to get only channels that are streaming live; otherwise, **false** to get live and offline channels. The default is **false**.
  --first: int # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100 items per page. The default is 20. (format: int32)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<broadcaster_language: string, broadcaster_login: string, display_name: string, game_id: string, game_name: string, id: string, is_live: bool, tag_ids: list, tags: list, thumbnail_url: string, title: string, started_at: string>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "live_only" $live_only "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the channel’s stream key.
#
# GET /streams/key
# Docs: https://dev.twitch.tv/docs/api/reference#get-stream-key — Get Stream Key
# operationId: get-stream-key
export def "streams-key get-stream-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster that owns the channel. The ID must match the user ID in the access token.
]: nothing -> record<data: table<stream_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/streams/key" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of all streams.
#
# GET /streams
# Docs: https://dev.twitch.tv/docs/api/reference#get-streams — Get Streams
# operationId: get-streams
export def "streams get-streams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: list # A user ID used to filter the list of streams. Returns only the streams of those users that are broadcasting. You may specify a maximum of 100 IDs. To specify multiple IDs, include the _user\_id_ parameter for each user. For example, `&user_id=1234&user_id=5678`.
  --user-login: list # A user login name used to filter the list of streams. Returns only the streams of those users that are broadcasting. You may specify a maximum of 100 login names. To specify multiple names, include the _user\_login_ parameter for each user. For example, `&user_login=foo&user_login=bar`.
  --game-id: list # A game (category) ID used to filter the list of streams. Returns only the streams that are broadcasting the game (category). You may specify a maximum of 100 IDs. To specify multiple IDs, include the _game\_id_ parameter for each game. For example, `&game_id=9876&game_id=5432`.
  --type: string@type-completer-2 # The type of stream to filter the list of streams by. Possible values are:      * all * live    The default is _all_.
  --language: list # A language code used to filter the list of streams. Returns only streams that broadcast in the specified language. Specify the language using an ISO 639-1 two-letter language code or _other_ if the broadcast uses a language not in the list of [supported stream languages](https://help.twitch.tv/s/article/languages-on-twitch#streamlang).      You may specify a maximum of 100 language codes. To specify multiple languages, include the _language_ parameter for each language. For example, `&language=de&language=fr`.
  --first: int # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100 items per page. The default is 20. (format: int32)
  --before: string # The cursor used to get the previous page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<id: string, user_id: string, user_login: string, user_name: string, game_id: string, game_name: string, type: string, title: string, viewer_count: int, started_at: string, language: string, thumbnail_url: string, tag_ids: list, tags: list, is_mature: bool>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "multi") (serialize-qp "user_login" $user_login "multi") (serialize-qp "game_id" $game_id "multi") (serialize-qp "type" $type "scalar") (serialize-qp "language" $language "multi") (serialize-qp "first" $first "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/streams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of broadcasters that the user follows and that are streaming live.
#
# GET /streams/followed
# Docs: https://dev.twitch.tv/docs/api/reference#get-followed-streams — Get Followed Streams
# operationId: get-followed-streams
export def "streams-followed get-followed-streams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The ID of the user whose list of followed streams you want to get. This ID must match the user ID in the access token.
  --first: int # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100 items per page. The default is 100. (format: int32)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<id: string, user_id: string, user_login: string, user_name: string, game_id: string, game_name: string, type: string, title: string, viewer_count: int, started_at: string, language: string, thumbnail_url: string, tag_ids: list, tags: list, is_mature: bool>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/streams/followed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a marker to a live stream.
#
# POST /streams/markers
# Docs: https://dev.twitch.tv/docs/api/reference#create-stream-marker — Create Stream Marker
# operationId: create-stream-marker
export def "streams-markers create-stream-marker" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_id: string # The ID of the broadcaster that’s streaming content. This ID must match the user ID in the access token or the user in the access token must be one of the broadcaster’s editors.
  --description: string # A short description of the marker to help the user remember why they marked the location. The maximum length of the description is 140 characters.
]: any -> record<data: table<id: string, created_at: string, position_seconds: int, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/streams/markers")
  let body = {user_id: $user_id, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of markers from the user’s most recent stream or from the specified VOD/video.
#
# GET /streams/markers
# Docs: https://dev.twitch.tv/docs/api/reference#get-stream-markers — Get Stream Markers
# operationId: get-stream-markers
export def "streams-markers get-stream-markers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # A user ID. The request returns the markers from this user’s most recent video. This ID must match the user ID in the access token or the user in the access token must be one of the broadcaster’s editors.      This parameter and the _video\_id_ query parameter are mutually exclusive.
  --video-id: string # A video on demand (VOD)/video ID. The request returns the markers from this VOD/video. The user in the access token must own the video or the user must be one of the broadcaster’s editors.      This parameter and the _user\_id_ query parameter are mutually exclusive.
  --first: string # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100 items per page. The default is 20.
  --before: string # The cursor used to get the previous page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<user_id: string, user_name: string, user_login: string, videos: list>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "video_id" $video_id "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/streams/markers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of users that subscribe to the specified broadcaster.
#
# GET /subscriptions
# Docs: https://dev.twitch.tv/docs/api/reference#get-broadcaster-subscriptions — Get Broadcaster Subscriptions
# operationId: get-broadcaster-subscriptions
export def "subscriptions get-broadcaster-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The broadcaster’s ID. This ID must match the user ID in the access token.
  --user-id: list # Filters the list to include only the specified subscribers. To specify more than one subscriber, include this parameter for each subscriber. For example, `&user_id=1234&user_id=5678`. You may specify a maximum of 100 subscribers.
  --first: string # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100 items per page. The default is 20.
  --after: string # The cursor used to get the next page of results. Do not specify if you set the _user\_id_ query parameter. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
  --before: string # The cursor used to get the previous page of results. Do not specify if you set the _user\_id_ query parameter. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<broadcaster_id: string, broadcaster_login: string, broadcaster_name: string, gifter_id: string, gifter_login: string, gifter_name: string, is_gift: bool, plan_name: string, tier: string, user_id: string, user_name: string, user_login: string>, pagination: record<cursor: string>, points: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "user_id" $user_id "multi") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks whether the user subscribes to the broadcaster’s channel.
#
# GET /subscriptions/user
# Docs: https://dev.twitch.tv/docs/api/reference#check-user-subscription — Check User Subscription
# operationId: check-user-subscription
export def "subscriptions-user check-user-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of a partner or affiliate broadcaster.
  --user-id: string # The ID of the user that you’re checking to see whether they subscribe to the broadcaster in _broadcaster\_id_. This ID must match the user ID in the access Token.
]: nothing -> record<data: table<broadcaster_id: string, broadcaster_login: string, broadcaster_name: string, gifter_id: string, gifter_login: string, gifter_name: string, is_gift: bool, tier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of all stream tags that Twitch defines. You can also filter the list by one or more tag IDs.
#
# GET /tags/streams
# DEPRECATED
# Docs: https://dev.twitch.tv/docs/api/reference#get-all-stream-tags — Get All Stream Tags
# operationId: get-all-stream-tags
@deprecated
export def "tags-streams get-all-stream-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-id: list # The ID of the tag to get. Used to filter the list of tags. To specify more than one tag, include the _tag\_id_ parameter for each tag to get. For example, `tag_id=1234&tag_id=5678`. The maximum number of IDs you may specify is 100\. Ignores invalid IDs but not duplicate IDs.
  --first: int # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100\. The default is 20. (format: int32)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<tag_id: string, is_auto: bool, localization_names: record, localization_descriptions: record>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag_id" $tag_id "multi") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tags/streams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of stream tags that the broadcaster or Twitch added to their channel.
#
# GET /streams/tags
# DEPRECATED
# Docs: https://dev.twitch.tv/docs/api/reference#get-stream-tags — Get Stream Tags
# operationId: get-stream-tags
@deprecated
export def "streams-tags get-stream-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose stream tags you want to get.
]: nothing -> record<data: table<tag_id: string, is_auto: bool, localization_names: record, localization_descriptions: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/streams/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of Twitch teams that the broadcaster is a member of.
#
# GET /teams/channel
# Docs: https://dev.twitch.tv/docs/api/reference#get-channel-teams — Get Channel Teams
# operationId: get-channel-teams
export def "teams-channel get-channel-teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose teams you want to get.
]: nothing -> record<data: table<broadcaster_id: string, broadcaster_login: string, broadcaster_name: string, background_image_url: string, banner: string, created_at: string, updated_at: string, info: string, thumbnail_url: string, team_name: string, team_display_name: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams/channel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about the specified Twitch team.
#
# GET /teams
# Docs: https://dev.twitch.tv/docs/api/reference#get-teams — Get Teams
# operationId: get-teams
export def "teams get-teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the team to get. This parameter and the _id_ parameter are mutually exclusive; you must specify the team’s name or ID but not both.
  --id: string # The ID of the team to get. This parameter and the _name_ parameter are mutually exclusive; you must specify the team’s name or ID but not both.
]: nothing -> record<data: table<users: list, background_image_url: string, banner: string, created_at: string, updated_at: string, info: string, thumbnail_url: string, team_name: string, team_display_name: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about one or more users.
#
# GET /users
# Docs: https://dev.twitch.tv/docs/api/reference#get-users — Get Users
# operationId: get-users
export def "users get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # The ID of the user to get. To specify more than one user, include the _id_ parameter for each user to get. For example, `id=1234&id=5678`. The maximum number of IDs you may specify is 100.
  --login: list # The login name of the user to get. To specify more than one user, include the _login_ parameter for each user to get. For example, `login=foo&login=bar`. The maximum number of login names you may specify is 100.
]: nothing -> record<data: table<id: string, login: string, display_name: string, type: string, broadcaster_type: string, description: string, profile_image_url: string, offline_image_url: string, view_count: int, email: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi") (serialize-qp "login" $login "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the user’s information.
#
# PUT /users
# Docs: https://dev.twitch.tv/docs/api/reference#update-user — Update User
# operationId: update-user
export def "users update-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The string to update the channel’s description to. The description is limited to a maximum of 300 characters.      To remove the description, specify this parameter but don’t set it’s value (for example, `?description=`).
]: nothing -> record<data: table<id: string, login: string, display_name: string, type: string, broadcaster_type: string, description: string, profile_image_url: string, offline_image_url: string, view_count: int, email: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "description" $description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# NEW Gets the authorization scopes that the specified user has granted the application.
#
# GET /authorization/users
# Docs: https://dev.twitch.tv/docs/api/reference#get-authorization-by-user — Get Authorization By User
# operationId: get-authorization-by-user
export def "authorization-users get-authorization-by-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: list # The ID of the user(s) you want to check authorization for. To specify more than one user, include the user\_id parameter for each user to get. For example, `user_id=1234&user_id=5678`. The maximum number of IDs you may specify is 10.
]: nothing -> record<data: table<user_id: string, user_name: string, user_login: string, scopes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/authorization/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of users that the broadcaster has blocked.
#
# GET /users/blocks
# Docs: https://dev.twitch.tv/docs/api/reference#get-user-block-list — Get User Block List
# operationId: get-user-block-list
export def "users-blocks get-user-block-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcaster-id: string # The ID of the broadcaster whose list of blocked users you want to get.
  --first: int # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100\. The default is 20. (format: int32)
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)
]: nothing -> record<data: table<user_id: string, user_login: string, display_name: string>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "broadcaster_id" $broadcaster_id "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/blocks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Blocks the specified user from interacting with or having contact with the broadcaster.
#
# PUT /users/blocks
# Docs: https://dev.twitch.tv/docs/api/reference#block-user — Block User
# operationId: block-user
export def "users-blocks block-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-user-id: string # The ID of the user to block. The API ignores the request if the broadcaster has already blocked the user.
  --source-context: string@source-context-completer # The location where the harassment took place that is causing the brodcaster to block the user. Possible values are:      * chat * whisper    .
  --reason: string@reason-completer # The reason that the broadcaster is blocking the user. Possible values are:      * harassment * spam * other
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "target_user_id" $target_user_id "scalar") (serialize-qp "source_context" $source_context "scalar") (serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/blocks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes the user from the broadcaster’s list of blocked users.
#
# DELETE /users/blocks
# Docs: https://dev.twitch.tv/docs/api/reference#unblock-user — Unblock User
# operationId: unblock-user
export def "users-blocks unblock-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-user-id: string # The ID of the user to remove from the broadcaster’s list of blocked users. The API ignores the request if the broadcaster hasn’t blocked the user.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "target_user_id" $target_user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/blocks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of all extensions (both active and inactive) that the broadcaster has installed.
#
# GET /users/extensions/list
# Docs: https://dev.twitch.tv/docs/api/reference#get-user-extensions — Get User Extensions
# operationId: get-user-extensions
export def "users-extensions-list get-user-extensions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<id: string, version: string, name: string, can_activate: bool, type: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/extensions/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the active extensions that the broadcaster has installed for each configuration.
#
# GET /users/extensions
# Docs: https://dev.twitch.tv/docs/api/reference#get-user-active-extensions — Get User Active Extensions
# operationId: get-user-active-extensions
export def "users-extensions get-user-active-extensions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The ID of the broadcaster whose active extensions you want to get.      This parameter is required if you specify an app access token and is optional if you specify a user access token. If you specify a user access token and don’t specify this parameter, the API uses the user ID from the access token.
]: nothing -> record<data: record<panel: record, overlay: record, component: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/extensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an installed extension’s information.
#
# PUT /users/extensions
# Docs: https://dev.twitch.tv/docs/api/reference#update-user-extensions — Update User Extensions
# operationId: update-user-extensions
# --data shape: {panel?: record, overlay?: record, component?: record}
export def "users-extensions update-user-extensions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: any # The extensions to update. The `data` field is a dictionary of extension types. The dictionary’s possible keys are: panel, overlay, or component. The key’s value is a dictionary of extensions.      For the extension’s dictionary, the key is a sequential number beginning with 1\. For panel and overlay extensions, the key’s value is an object that contains the following fields: `active` (true/false), `id` (the extension’s ID), and `version` (the extension’s version).      For component extensions, the key’s value includes the above fields plus the `x` and `y` fields, which identify the coordinate where the extension is placed. — shape: {panel?: record, overlay?: record, component?: record}
]: any -> record<data: record<panel: record, overlay: record, component: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/extensions")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets information about one or more published videos.
#
# GET /videos
# Docs: https://dev.twitch.tv/docs/api/reference#get-videos — Get Videos
# operationId: get-videos
export def "videos get-videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # A list of IDs that identify the videos you want to get. To get more than one video, include this parameter for each video you want to get. For example, `id=1234&id=5678`. You may specify a maximum of 100 IDs. The endpoint ignores duplicate IDs and IDs that weren't found (if there's at least one valid ID).      The _id_, _user\_id_, and _game\_id_ parameters are mutually exclusive.
  --user-id: string # The ID of the user whose list of videos you want to get.      The _id_, _user\_id_, and _game\_id_ parameters are mutually exclusive.
  --game-id: string # A category or game ID. The response contains a maximum of 500 videos that show this content. To get category/game IDs, use the [Search Categories](https://dev.twitch.tv/docs/api/reference#search-categories) endpoint.      The _id_, _user\_id_, and _game\_id_ parameters are mutually exclusive.
  --language: string # A filter used to filter the list of videos by the language that the video owner broadcasts in. For example, to get videos that were broadcast in German, set this parameter to the ISO 639-1 two-letter code for German (i.e., DE). For a list of supported languages, see [Supported Stream Language](https://help.twitch.tv/s/article/languages-on-twitch#streamlang). If the language is not supported, use “other.”      Specify this parameter only if you specify the _game\_id_ query parameter.
  --period: string@period-completer-1 # A filter used to filter the list of videos by when they were published. For example, videos published in the last week. Possible values are:      * all * day * month * week    The default is "all," which returns videos published in all periods.      Specify this parameter only if you specify the _game\_id_ or _user\_id_ query parameter.
  --qp-sort: string@sort-completer-1 # The order to sort the returned videos in. Possible values are:      * time — Sort the results in descending order by when they were created (i.e., latest video first). * trending — Sort the results in descending order by biggest gains in viewership (i.e., highest trending video first). * views — Sort the results in descending order by most views (i.e., highest number of views first).    The default is "time."      Specify this parameter only if you specify the _game\_id_ or _user\_id_ query parameter.
  --type: string@type-completer-3 # A filter used to filter the list of videos by the video's type. Possible case-sensitive values are:      * all * archive — On-demand videos (VODs) of past streams. * highlight — Highlight reels of past streams. * upload — External videos that the broadcaster uploaded using the Video Producer.    The default is "all," which returns all video types.      Specify this parameter only if you specify the _game\_id_ or _user\_id_ query parameter.
  --first: string # The maximum number of items to return per page in the response. The minimum page size is 1 item per page and the maximum is 100\. The default is 20.      Specify this parameter only if you specify the _game\_id_ or _user\_id_ query parameter.
  --after: string # The cursor used to get the next page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)      Specify this parameter only if you specify the _user\_id_ query parameter.
  --before: string # The cursor used to get the previous page of results. The **Pagination** object in the response contains the cursor’s value. [Read More](https://dev.twitch.tv/docs/api/guide#pagination)      Specify this parameter only if you specify the _user\_id_ query parameter.
]: nothing -> record<data: table<id: string, stream_id: string, user_id: string, user_login: string, user_name: string, title: string, description: string, created_at: string, published_at: string, url: string, thumbnail_url: string, viewable: string, view_count: int, language: string, type: string, duration: string, muted_segments: list>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "game_id" $game_id "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes one or more videos.
#
# DELETE /videos
# Docs: https://dev.twitch.tv/docs/api/reference#delete-videos — Delete Videos
# operationId: delete-videos
export def "videos delete-videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # The list of videos to delete. To specify more than one video, include the _id_ parameter for each video to delete. For example, `id=1234&id=5678`. You can delete a maximum of 5 videos per request. Ignores invalid video IDs.      If the user doesn’t have permission to delete one of the videos in the list, none of the videos are deleted.
]: nothing -> record<data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends a whisper message to the specified user.
#
# POST /whispers
# Docs: https://dev.twitch.tv/docs/api/reference#send-whisper — Send Whisper
# operationId: send-whisper
export def "whispers send-whisper" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-user-id: string # The ID of the user sending the whisper. This user must have a verified phone number. This ID must match the user ID in the user access token.
  --to-user-id: string # The ID of the user to receive the whisper.
  message: string # The whisper message to send. The message must not be empty.      The maximum message lengths are:      * 500 characters if the user you're sending the message to hasn't whispered you before. * 10,000 characters if the user you're sending the message to has whispered you before.    Messages that exceed the maximum length are truncated.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from_user_id" $from_user_id "scalar") (serialize-qp "to_user_id" $to_user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/whispers" $qp)
  let body = {message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
