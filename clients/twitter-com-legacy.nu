# Auto-generated client for Twitter API v1.1
# Source: https://api.apis.guru/v2/specs/twitter.com/legacy/1.1/swagger.json
# Auth: --token flag or $env.TWITTER_API_TOKEN

const BASE_URL = "https://api.twitter.com/1.1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWITTER_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://api.twitter.com/1.1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def align-completer [] { ["center" "left" "none" "right"] }
def display-coordinates-completer [] { ["" "false" "true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-settings-json get" } } | get name | first)
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

# Returns settings (including current trend, geo and sleep time information) for the authenticating user.
#
# GET /account/settings.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/account/settings
# operationId: account.settings.get
export def "account-settings-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trend-location-woeid: string # The Yahoo! Where On Earth ID to use as the user's default trend location. Global information is available by using 1 as the WOEID. The woeid must be one of the locations returned by GET trends/available. Example Values: 1
  --sleep-time-enabled: string # When set to true, t or 1, will enable sleep time for the user. Sleep time is the time when push or SMS notifications should not be sent to the user. Example Values: true
  --start-sleep-time: string # The hour that sleep time should begin if it is enabled. The value for this parameter should be provided in ISO8601 format (i.e. 00-23). The time is considered to be in the same timezone as the user's time_zone setting. Example Values: 13
  --end-sleep-time: string # The hour that sleep time should end if it is enabled. The value for this parameter should be provided in ISO8601 format (i.e. 00-23). The time is considered to be in the same timezone as the user's time_zone setting. Example Values: 13
  --time-zone: string # The timezone dates and times should be displayed in for the user. The timezone must be one of the Rails TimeZone names. Example Values: Europe/Copenhagen, Pacific/Tongatapu
  --lang: string # The language which Twitter should render in for this user. The language must be specified by the appropriate two letter ISO 639-1 representation. Currently supported languages are provided by GET help/languages. Example Values: it, en, es
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "trend_location_woeid" $trend_location_woeid "scalar") (serialize-qp "sleep_time_enabled" $sleep_time_enabled "scalar") (serialize-qp "start_sleep_time" $start_sleep_time "scalar") (serialize-qp "end_sleep_time" $end_sleep_time "scalar") (serialize-qp "time_zone" $time_zone "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/settings.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"trend_location_woeid": $trend_location_woeid, "sleep_time_enabled": $sleep_time_enabled, "start_sleep_time": $start_sleep_time, "end_sleep_time": $end_sleep_time, "time_zone": $time_zone, "lang": $lang} | compact), body: null}
}

# Updates the authenticating user's settings.
#
# POST /account/settings.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/account/settings
# operationId: account.settings.post
export def "account-settings-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trend-location-woeid: string # The Yahoo! Where On Earth ID to use as the user's default trend location. Global information is available by using 1 as the WOEID. The woeid must be one of the locations returned by GET trends/available. Example Values: 1
  --sleep-time-enabled: string # When set to true, t or 1, will enable sleep time for the user. Sleep time is the time when push or SMS notifications should not be sent to the user. Example Values: true
  --start-sleep-time: string # The hour that sleep time should begin if it is enabled. The value for this parameter should be provided in ISO8601 format (i.e. 00-23). The time is considered to be in the same timezone as the user's time_zone setting. Example Values: 13
  --end-sleep-time: string # The hour that sleep time should end if it is enabled. The value for this parameter should be provided in ISO8601 format (i.e. 00-23). The time is considered to be in the same timezone as the user's time_zone setting. Example Values: 13
  --time-zone: string # The timezone dates and times should be displayed in for the user. The timezone must be one of the Rails TimeZone names. Example Values: Europe/Copenhagen, Pacific/Tongatapu
  --lang: string # The language which Twitter should render in for this user. The language must be specified by the appropriate two letter ISO 639-1 representation. Currently supported languages are provided by GET help/languages. Example Values: it, en, es
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "trend_location_woeid" $trend_location_woeid "scalar") (serialize-qp "sleep_time_enabled" $sleep_time_enabled "scalar") (serialize-qp "start_sleep_time" $start_sleep_time "scalar") (serialize-qp "end_sleep_time" $end_sleep_time "scalar") (serialize-qp "time_zone" $time_zone "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/settings.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"trend_location_woeid": $trend_location_woeid, "sleep_time_enabled": $sleep_time_enabled, "start_sleep_time": $start_sleep_time, "end_sleep_time": $end_sleep_time, "time_zone": $time_zone, "lang": $lang} | compact), body: null}
}

# Sets which device Twitter delivers updates to for the authenticating user. Sending none as the device parameter will disable SMS updates.
#
# POST /account/update_delivery_device.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/account/update_delivery_device
# operationId: account.update_delivery_device
export def "account-update-delivery-device-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string # Must be one of: sms, none. Example Values: sms
  --include-entities: string # When set to either true, t or 1, each tweet will include a node called "entities,". This node offers a variety of metadata about the tweet in a discreet structure, including: user_mentions, urls, and hashtags. While entities are opt-in on timelines at present, they will be made a default component of output in the future. See Tweet Entities for more detail on entities. Example Values: true
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "device" $device "scalar") (serialize-qp "include_entities" $include_entities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/update_delivery_device.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"device": $device, "include_entities": $include_entities} | compact), body: null}
}

# Sets values that users are able to set under the Account tab of their settings page. Only the parameters specified will be updated.
#
# POST /account/update_profile.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/account/update_profile
# operationId: account.update_profile
export def "account-update-profile-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Full name associated with the profile. Maximum of 20 characters. Example Values: Marcel Molina
  --url: string # URL associated with the profile. Will be prepended with "http://" if not present. Maximum of 100 characters. Example Values: http://project.ioni.st
  --location: string # The city or country describing where the user of the account is located. The contents are not normalized or geocoded in any way. Maximum of 30 characters. Example Values: San Francisco, CA
  --description: string # A description of the user owning the account. Maximum of 160 characters. Example Values: Flipped my wig at age 22 and it never grew back. Also: I work at Twitter.
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "url" $url "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "include_entities" $include_entities "scalar") (serialize-qp "skip_status" $skip_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/update_profile.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "url": $url, "location": $location, "description": $description, "include_entities": $include_entities, "skip_status": $skip_status} | compact), body: null}
}

# Updates the authenticating user's profile background image. This method can also be used to enable or disable the profile background image. Although each parameter is marked as optional, at least one of image, tile or use must be provided when making this request.
#
# POST /account/update_profile_background_image.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/account/update_profile_background_image
# operationId: accounts.update_profile_background_image
export def "account-update-profile-background-image-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tile: string # Whether or not to tile the background image. If set to true, t or 1 the background image will be displayed tiled. The image will not be tiled otherwise.
  --qp-use: string # Determines whether to display the profile background image or not. When set to true, t or 1 the background image will be displayed if an image is being uploaded with the request, or has been uploaded previously. An error will be returned if you try to use a background image when one is not being uploaded or does not exist. If this parameter is defined but set to anything other than true, t or 1, the background image will stop being used.
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
  --content-type: string # Content type header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tile" $tile "scalar") (serialize-qp "use" $qp_use "scalar") (serialize-qp "include_entities" $include_entities "scalar") (serialize-qp "skip_status" $skip_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/update_profile_background_image.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tile": $tile, "use": $qp_use, "include_entities": $include_entities, "skip_status": $skip_status} | compact), body: null}
}

# Sets one or more hex values that control the color scheme of the authenticating user's profile page on twitter.com. Each parameter's value must be a valid hexidecimal value, and may be either three or six characters (ex: #fff or #ffffff).
#
# POST /account/update_profile_colors.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/account/update_profile_colors
# operationId: accounts.update_profile_colors
export def "account-update-profile-colors-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --profile-background-color: string # Profile background color. Example Values: 3D3D3D
  --profile-link-color: string # Profile link color.Example Values: 0000FF
  --profile-sidebar-border-color: string # Profile sidebar's border color. Example Values: 0F0F0F
  --profile-sidebar-fill-color: string # Profile sidebar's background color. Example Values: 00FF00
  --profile-text-color: string # Profile text color. Example Values: 000000
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "profile_background_color" $profile_background_color "scalar") (serialize-qp "profile_link_color" $profile_link_color "scalar") (serialize-qp "profile_sidebar_border_color" $profile_sidebar_border_color "scalar") (serialize-qp "profile_sidebar_fill_color" $profile_sidebar_fill_color "scalar") (serialize-qp "profile_text_color" $profile_text_color "scalar") (serialize-qp "include_entities" $include_entities "scalar") (serialize-qp "skip_status" $skip_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/update_profile_colors.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"profile_background_color": $profile_background_color, "profile_link_color": $profile_link_color, "profile_sidebar_border_color": $profile_sidebar_border_color, "profile_sidebar_fill_color": $profile_sidebar_fill_color, "profile_text_color": $profile_text_color, "include_entities": $include_entities, "skip_status": $skip_status} | compact), body: null}
}

# Updates the authenticating user's profile image. Note that this method expects raw multipart data, not a URL to an image. This method asynchronously processes the uploaded file before updating the user's profile image URL. You can either update your local cache the next time you request the user's information, or, at least 5 seconds after uploading the image, ask for the updated URL using GET users/profile_image/:screen_name (https://dev.twitter.com/docs/api/1/get/users/profile_image/:screen_name).
#
# POST /account/update_profile_image.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/account/update_profile_image
# operationId: accounts.update_profile_image
export def "account-update-profile-image-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
  --content-type: string # Content type header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip_status" $skip_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/update_profile_image.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip_status": $skip_status} | compact), body: null}
}

# Returns the current rate limits for methods belonging to the specified resource families. Each 1.1 API resource belongs to a "resource family" which is indicated in its method documentation. You can typically determine a method's resource family from the first component of the path after the resource version. This method responds with a map of methods belonging to the families specified by the resources parameter, the current remaining uses for each of those resources within the current rate limiting window, and its expiration time in epoch time. It also includes a rate_limit_context field that indicates the current access token context. You may also issue requests to this method without any parameters to receive a map of all rate limited GET methods. If your application only uses a few of methods, please explicitly provide a resources parameter with the specified resource families you work with.
#
# GET /application/rate_limit_status.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/application/rate_limit_status
# operationId: application.rate_limit_status
export def "application-rate-limit-status-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resources: string # A comma-separated list of resource families you want to know the current rate limit disposition for. For best performance, only specify the resource families pertinent to your application.Example Values: statuses,friends,trends,help
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resources" $resources "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/rate_limit_status.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"resources": $resources} | compact), body: null}
}

# Blocks the specified user from following the authenticating user. In addition the blocked user will not show in the authenticating users mentions or timeline (unless retweeted by another user). If a follow or friend relationship exists it is destroyed.
#
# POST /blocks/create.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/blocks/create
# operationId: blocks.create
export def "blocks-create-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_entities" $include_entities "scalar") (serialize-qp "skip_status" $skip_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/blocks/create.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_entities": $include_entities, "skip_status": $skip_status} | compact), body: null}
}

# Un-blocks the user specified in the ID parameter for the authenticating user. Returns the un-blocked user in the requested format when successful. If relationships existed before the block was instated, they will not be restored.
#
# POST /blocks/destroy.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/blocks/destroy
# operationId: blocks.destroy
export def "blocks-destroy-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_entities" $include_entities "scalar") (serialize-qp "skip_status" $skip_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/blocks/destroy.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_entities": $include_entities, "skip_status": $skip_status} | compact), body: null}
}

# Returns an array of numeric user ids the authenticating user is blocking.
#
# GET /blocks/ids.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/blocks/ids
# operationId: blocks.ids
export def "blocks-ids-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stringify-ids: string # Many programming environments will not consume our ids due to their size. Provide this option to have ids returned as strings instead. Read more about Twitter IDs, JSON and Snowflake. Example Values: true
  --cursor: string # Causes the list of blocked users to be broken into pages of no more than 5000 IDs at a time. The number of IDs returned is not guaranteed to be 5000 as suspended users are filtered out after connections are queried. If no cursor is provided, a value of -1 will be assumed, which is the first "page." The response from the API will include a previous_cursor and next_cursor to allow paging back and forth. See Using cursors to navigate collections for more information. Example Values: 12893764510938
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stringify_ids" $stringify_ids "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/blocks/ids.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"stringify_ids": $stringify_ids, "cursor": $cursor} | compact), body: null}
}

# Allows one to enable or disable retweets and device notifications from the specified user.
#
# GET /blocks/list.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/blocks/list
# operationId: blocks.list
export def "blocks-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
  --cursor: string # Causes the list of blocked users to be broken into pages of no more than 5000 IDs at a time. The number of IDs returned is not guaranteed to be 5000 as suspended users are filtered out after connections are queried. If no cursor is provided, a value of -1 will be assumed, which is the first "page." The response from the API will include a previous_cursor and next_cursor to allow paging back and forth. See Using cursors to navigate collections for more information. Example Values: 12893764510938
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_entities" $include_entities "scalar") (serialize-qp "skip_status" $skip_status "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/blocks/list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_entities": $include_entities, "skip_status": $skip_status, "cursor": $cursor} | compact), body: null}
}

# Returns the 20 most recent direct messages sent to the authenticating user. Includes detailed information about the sender and recipient user. You can request up to 200 direct messages per call, up to a maximum of 800 incoming DMs. Important: This method requires an access token with RWD (read, write and direct message) permissions. Consult The Application Permission Model for more information.
#
# GET /direct_messages.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/direct_messages
# operationId: direct_messages
export def "direct-messages-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: string # Specifies the number of direct messages to try and retrieve, up to a maximum of 200. The value of count is best thought of as a limit to the number of Tweets to return because suspended or deleted content is removed after the count has been applied. Example Values: 5
  --since-id: string # Returns results with an ID greater than (that is, more recent than) the specified ID. There are limits to the number of Tweets which can be accessed through the API. If the limit of Tweets has occured since the since_id, the since_id will be forced to the oldest ID available. Example Values: 12345
  --max-id: string # Returns results with an ID less than (that is, older than) or equal to the specified ID. Example Values: 54321
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
  --page: string # Specifies the page of results to retrieve. Example Values: 3
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "include_entities" $include_entities "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "skip_status" $skip_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/direct_messages.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"count": $count, "since_id": $since_id, "max_id": $max_id, "include_entities": $include_entities, "page": $page, "skip_status": $skip_status} | compact), body: null}
}

# Destroys the direct message specified in the required ID parameter. The authenticating user must be the recipient of the specified direct message. Important: This method requires an access token with RWD (read, write and direct message) permissions. Consult The Application Permission Model for more information.
#
# POST /direct_messages/destroy.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/direct_messages/destroy
# operationId: direct_messages.destroy
export def "direct-messages-destroy-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The ID of the direct message to delete. Example Values: 1270516771
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "include_entities" $include_entities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/direct_messages/destroy.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "include_entities": $include_entities} | compact), body: null}
}

# Sends a new direct message to the specified user from the authenticating user. Requires both the user and text parameters and must be a POST. Returns the sent message in the requested format if successful.
#
# POST /direct_messages/new.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/direct_messages/new
# operationId: direct_messages.new
export def "direct-messages-new-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # The text of your direct message. Be sure to URL encode as necessary, and keep the message under 140 characters. Example Values: Meet me behind the cafeteria after school
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/direct_messages/new.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"text": $text} | compact), body: null}
}

# Returns the 20 most recent direct messages sent by the authenticating user. Includes detailed information about the sender and recipient user. You can request up to 200 direct messages per call, up to a maximum of 800 outgoing DMs. Important: This method requires an access token with RWD (read, write and direct message) permissions. Consult The Application Permission Model for more information.
#
# GET /direct_messages/sent.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/direct_messages/sent
# operationId: direct_messages.sent
export def "direct-messages-sent-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: string # Specifies the number of direct messages to try and retrieve, up to a maximum of 200. The value of count is best thought of as a limit to the number of Tweets to return because suspended or deleted content is removed after the count has been applied. Example Values: 5
  --since-id: string # Returns results with an ID greater than (that is, more recent than) the specified ID. There are limits to the number of Tweets which can be accessed through the API. If the limit of Tweets has occured since the since_id, the since_id will be forced to the oldest ID available. Example Values: 12345
  --max-id: string # Returns results with an ID less than (that is, older than) or equal to the specified ID. Example Values: 54321
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
  --page: string # Specifies the page of results to retrieve. Example Values: 3
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "include_entities" $include_entities "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/direct_messages/sent.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"count": $count, "since_id": $since_id, "max_id": $max_id, "include_entities": $include_entities, "page": $page} | compact), body: null}
}

# Returns a single direct message, specified by an id parameter. Like the /1.1/direct_messages.format request, this method will include the user objects of the sender and recipient. Important: This method requires an access token with RWD (read, write and direct message) permissions. Consult The Application Permission Model for more information.
#
# GET /direct_messages/show.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/direct_messages/show
# operationId: direct_messages.show
export def "direct-messages-show-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The ID of the direct message. Example Values: 587424932
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/direct_messages/show.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id} | compact), body: null}
}

# Favorites the status specified in the ID parameter as the authenticating user. Returns the favorite status when successful. This process invoked by this method is asynchronous. The immediately returned status may not indicate the resultant favorited status of the tweet. A 200 OK response from this method will indicate whether the intended action was successful or not.
#
# POST /favorites/create.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/favorites/create
# operationId: favorites.create
export def "favorites-create-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The numerical ID of the desired status. Example Values: 123
  --include-entities: string # The entities node will be omitted when set to false. Example Values: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "include_entities" $include_entities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/favorites/create.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "include_entities": $include_entities} | compact), body: null}
}

# Un-favorites the status specified in the ID parameter as the authenticating user. Returns the un-favorited status in the requested format when successful. This process invoked by this method is asynchronous. The immediately returned status may not indicate the resultant favorited status of the tweet. A 200 OK response from this method will indicate whether the intended action was successful or not.
#
# POST /favorites/destroy.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/favorites/destroy
# operationId: favorites.destroy
export def "favorites-destroy-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The numerical ID of the desired status. Example Values: 123
  --include-entities: string # The entities node will be omitted when set to false. Example Values: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "include_entities" $include_entities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/favorites/destroy.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "include_entities": $include_entities} | compact), body: null}
}

# Returns the 20 most recent Tweets favorited by the authenticating or specified user.
#
# GET /favorites/list.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/favorites/list
# operationId: favorites.list
export def "favorites-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: string # Specifies the number of records to retrieve. Must be less than or equal to 200. Defaults to 20. Example Values: 5
  --since-id: string # Returns results with an ID greater than (that is, more recent than) the specified ID. There are limits to the number of Tweets which can be accessed through the API. If the limit of Tweets has occured since the since_id, the since_id will be forced to the oldest ID available. Example Values: 12345
  --max-id: string # Returns results with an ID less than (that is, older than) or equal to the specified ID. Example Values: 54321
  --include-entities: string # The entities node will be omitted when set to false. Example Values: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "include_entities" $include_entities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/favorites/list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"count": $count, "since_id": $since_id, "max_id": $max_id, "include_entities": $include_entities} | compact), body: null}
}

# Returns a cursored collection of user IDs for every user following the specified user. At this time, results are ordered with the most recent following first — however, this ordering is subject to unannounced change and eventual consistency issues. Results are given in groups of 5,000 user IDs and multiple "pages" of results can be navigated through using the next_cursor value in subsequent requests. See Using cursors to navigate collections for more information. This method is especially powerful when used in conjunction with GET users/lookup, a method that allows you to convert user IDs into full user objects in bulk.
#
# GET /followers/ids.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/followers/ids
# operationId: followers.ids
export def "followers-ids-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stringify-ids: string # Many programming environments will not consume our Tweet ids due to their size. Provide this option to have ids returned as strings instead. Example Values: true
  --cursor: string # Causes the list of connections to be broken into pages of no more than 5000 IDs at a time. The number of IDs returned is not guaranteed to be 5000 as suspended users are filtered out after connections are queried. If no cursor is provided, a value of -1 will be assumed, which is the first "page." The response from the API will include a previous_cursor and next_cursor to allow paging back and forth.Example Values: 12893764510938
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stringify_ids" $stringify_ids "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/followers/ids.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"stringify_ids": $stringify_ids, "cursor": $cursor} | compact), body: null}
}

# Returns a cursored collection of user IDs for every user the specified user is following (otherwise known as their "friends"). At this time, results are ordered with the most recent following first — however, this ordering is subject to unannounced change and eventual consistency issues. Results are given in groups of 5,000 user IDs and multiple "pages" of results can be navigated through using the next_cursor value in subsequent requests. See Using cursors to navigate collections for more information. This method is especially powerful when used in conjunction with GET users/lookup, a method that allows you to convert user IDs into full user objects in bulk.
#
# GET /friends/ids.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/friends/ids
# operationId: friends.ids
export def "friends-ids-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stringify-ids: string # Many programming environments will not consume our Tweet ids due to their size. Provide this option to have ids returned as strings instead. Example Values: true
  --cursor: string # Causes the list of connections to be broken into pages of no more than 5000 IDs at a time. The number of IDs returned is not guaranteed to be 5000 as suspended users are filtered out after connections are queried. If no cursor is provided, a value of -1 will be assumed, which is the first "page." The response from the API will include a previous_cursor and next_cursor to allow paging back and forth.Example Values: 12893764510938
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stringify_ids" $stringify_ids "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/friends/ids.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"stringify_ids": $stringify_ids, "cursor": $cursor} | compact), body: null}
}

# Allows the authenticating users to follow the user specified in the ID parameter. Returns the befriended user in the requested format when successful. Returns a string describing the failure condition when unsuccessful. If you are already friends with the user a HTTP 403 may be returned, though for performance reasons you may get a 200 OK message even if the friendship already exists. Actions taken in this method are asynchronous and changes will be eventually consistent.
#
# POST /friendships/create.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/friendships/create
# operationId: friendships.create
export def "friendships-create-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --follow: string # Enable notifications for the target user. Example Values: true
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "follow" $follow "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/friendships/create.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"follow": $follow} | compact), body: null}
}

# Allows the authenticating user to unfollow the user specified in the ID parameter. Returns the unfollowed user in the requested format when successful. Returns a string describing the failure condition when unsuccessful. Actions taken in this method are asynchronous and changes will be eventually consistent.
#
# POST /friendships/destroy.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/friendships/destroy
# operationId: friendships.destroy
export def "friendships-destroy-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/friendships/destroy.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the relationships of the authenticating user to the comma-separated list of up to 100 screen_names or user_ids provided. Values for connections can be: following, following_requested, followed_by, none.
#
# GET /friendships/incoming.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/friendships/incoming
# operationId: friendships.incoming
export def "friendships-incoming-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stringify-ids: string # Many programming environments will not consume our Tweet ids due to their size. Provide this option to have ids returned as strings instead. Example Values: true
  --cursor: string # Causes the list of connections to be broken into pages of no more than 5000 IDs at a time. The number of IDs returned is not guaranteed to be 5000 as suspended users are filtered out after connections are queried. If no cursor is provided, a value of -1 will be assumed, which is the first "page." The response from the API will include a previous_cursor and next_cursor to allow paging back and forth.Example Values: 12893764510938
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stringify_ids" $stringify_ids "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/friendships/incoming.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"stringify_ids": $stringify_ids, "cursor": $cursor} | compact), body: null}
}

# Returns the relationships of the authenticating user to the comma-separated list of up to 100 screen_names or user_ids provided. Values for connections can be: following, following_requested, followed_by, none.
#
# GET /friendships/lookup.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/friendships/lookup
# operationId: friendships.lookup
export def "friendships-lookup-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/friendships/lookup.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a collection of numeric IDs for every protected user for whom the authenticating user has a pending follow request.
#
# GET /friendships/outgoing.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/friendships/outgoing
# operationId: friendships.outgoing
export def "friendships-outgoing-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stringify-ids: string # Many programming environments will not consume our Tweet ids due to their size. Provide this option to have ids returned as strings instead. Example Values: true
  --cursor: string # Causes the list of connections to be broken into pages of no more than 5000 IDs at a time. The number of IDs returned is not guaranteed to be 5000 as suspended users are filtered out after connections are queried. If no cursor is provided, a value of -1 will be assumed, which is the first "page." The response from the API will include a previous_cursor and next_cursor to allow paging back and forth.Example Values: 12893764510938
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stringify_ids" $stringify_ids "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/friendships/outgoing.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"stringify_ids": $stringify_ids, "cursor": $cursor} | compact), body: null}
}

# Returns detailed information about the relationship between two arbitrary users.
#
# GET /friendships/show.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/friendships/show
# operationId: friendships.show
export def "friendships-show-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-id: string # The user_id of the subject user. Example Values: 3191321
  --source-screen-name: string # The screen_name of the subject user. Example Values: raffi
  --target-id: string # The user_id of the target user. Example Values: 20
  --target-screen-name: string # The screen_name of the target user. Example Values: noradio
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source_id" $source_id "scalar") (serialize-qp "source_screen_name" $source_screen_name "scalar") (serialize-qp "target_id" $target_id "scalar") (serialize-qp "target_screen_name" $target_screen_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/friendships/show.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"source_id": $source_id, "source_screen_name": $source_screen_name, "target_id": $target_id, "target_screen_name": $target_screen_name} | compact), body: null}
}

# Allows one to enable or disable retweets and device notifications from the specified user.
#
# POST /friendships/update.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/friendships/update
# operationId: friendships.update
export def "friendships-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string # Enable/disable device notifications from the target user. Example Values: true, false
  --retweets: string # Enable/disable retweets from the target user. Example Values: true, false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "device" $device "scalar") (serialize-qp "retweets" $retweets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/friendships/update.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"device": $device, "retweets": $retweets} | compact), body: null}
}

# Returns all the information about a known place.Example Values: df51dec6f4ee2b2c
#
# GET /geo/id/{place_id}.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/geo/id/%3Aplace_id
# operationId: geo.place_id
export def "geo-id get" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'place_id' must be non-empty" } }
  let full_url = (build-url $base ({place_id: (encode-path-segment $place_id)} | format pattern "/geo/id/{place_id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new place object at the given latitude and longitude. Before creating a place you need to query GET geo/similar_places with the latitude, longitude and name of the place you wish to create. The query will return an array of places which are similar to the one you wish to create, and a token. If the place you wish to create isn't in the returned array you can use the token with this method to create a new one.
#
# POST /geo/places.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/geo/place
# operationId: geo.places
export def "geo-places-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-street-address: string # This parameter searches for places which have this given street address. There are other well-known, and application specific attributes available. Custom attributes are also permitted. Learn more about Place Attributes. Example Values: 795%20Folsom%20St
  --callback: string # If supplied, the response will use the JSONP format with a callback of the given name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attribute:street_address" $attribute_street_address "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geo/places.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"attribute:street_address": $attribute_street_address, "callback": $callback} | compact), body: null}
}

# Given a latitude and a longitude, searches for up to 20 places that can be used as a place_id when updating a status. This request is an informative call and will deliver generalized results about geography
#
# GET /geo/reverse_geocode.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/geo/reverse_geocode
# operationId: geo.reverse_geocode
export def "geo-reverse-geocode-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: string # The latitude to search around. This parameter will be ignored unless it is inside the range -90.0 to +90.0 (North is positive) inclusive. It will also be ignored if there isn't a corresponding long parameter. Example Values: 37.7821120598956
  --long: string # The longitude to search around. The valid ranges for longitude is -180.0 to +180.0 (East is positive) inclusive. This parameter will be ignored if outside that range, if it is not a number, if geo_enabled is disabled, or if there not a corresponding lat parameter. Example Values: -122.400612831116
  --accuracy: string # A hint on the "region" in which to search. If a number, then this is a radius in meters, but it can also take a string that is suffixed with ft to specify feet. If this is not passed in, then it is assumed to be 0m. If coming from a device, in practice, this value is whatever accuracy the device has measuring its location (whether it be coming from a GPS, WiFi triangulation, etc.). Example Values: 5ft
  --granularity: string # This is the minimal granularity of place types to return and must be one of: poi, neighborhood, city, admin or country. If no granularity is provided for the request neighborhood is assumed. Setting this to city, for example, will find places which have a type of city, admin or country. Example Values: city
  --max-results: string # A hint as to the number of results to return. This does not guarantee that the number of results returned will equal max_results, but instead informs how many "nearby" results to return. Ideally, only pass in the number of places you intend to display to the user here. Example Values: 3
  --callback: string # If supplied, the response will use the JSONP format with a callback of the given name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "long" $long "scalar") (serialize-qp "accuracy" $accuracy "scalar") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geo/reverse_geocode.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lat": $lat, "long": $long, "accuracy": $accuracy, "granularity": $granularity, "max_results": $max_results, "callback": $callback} | compact), body: null}
}

# Search for places that can be attached to a statuses/update. Given a latitude and a longitude pair, an IP address, or a name, this request will return a list of all the valid places that can be used as the place_id when updating a status. Conceptually, a query can be made from the user's location, retrieve a list of places, have the user validate the location he or she is at, and then send the ID of this location with a call to POST statuses/update. This is the recommended method to use find places that can be attached to statuses/update. Unlike GET geo/reverse_geocode which provides raw data access, this endpoint can potentially re-order places with regards to the user who is authenticated. This approach is also preferred for interactive place matching with the user.
#
# GET /geo/search.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/geo/search
# operationId: geo.search
export def "geo-search-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accuracy: string # A hint on the "region" in which to search. If a number, then this is a radius in meters, but it can also take a string that is suffixed with ft to specify feet. If this is not passed in, then it is assumed to be 0m. If coming from a device, in practice, this value is whatever accuracy the device has measuring its location (whether it be coming from a GPS, WiFi triangulation, etc.). Example Values: 5ft
  --granularity: string # This is the minimal granularity of place types to return and must be one of: poi, neighborhood, city, admin or country. If no granularity is provided for the request neighborhood is assumed. Setting this to city, for example, will find places which have a type of city, admin or country. Example Values: city
  --contained-within: string # This is the place_id which you would like to restrict the search results to. Setting this value means only places within the given place_id will be found. Specify a place_id. For example, to scope all results to places within "San Francisco, CA USA", you would specify a place_id of "5a110d312052166f" Example Values: 247f43d441defc03
  --attribute-street-address: string # This parameter searches for places which have this given street address. There are other well-known, and application specific attributes available. Custom attributes are also permitted. Learn more about Place Attributes. Example Values: 795%20Folsom%20St
  --callback: string # If supplied, the response will use the JSONP format with a callback of the given name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accuracy" $accuracy "scalar") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "contained_within" $contained_within "scalar") (serialize-qp "attribute:street_address" $attribute_street_address "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geo/search.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accuracy": $accuracy, "granularity": $granularity, "contained_within": $contained_within, "attribute:street_address": $attribute_street_address, "callback": $callback} | compact), body: null}
}

# Locates places near the given coordinates which are similar in name. Conceptually you would use this method to get a list of known places to choose from first. Then, if the desired place doesn't exist, make a request to POST geo/place to create a new one. The token contained in the response is the token needed to be able to create a new place.
#
# GET /geo/similar_places.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/geo/similar_places
# operationId: geo.similar_places
export def "geo-similar-places-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contained-within: string # This is the place_id which you would like to restrict the search results to. Setting this value means only places within the given place_id will be found. Specify a place_id. For example, to scope all results to places within "San Francisco, CA USA", you would specify a place_id of "5a110d312052166f" Example Values: 247f43d441defc03
  --attribute-street-address: string # This parameter searches for places which have this given street address. There are other well-known, and application specific attributes available. Custom attributes are also permitted. Learn more about Place Attributes. Example Values: 795%20Folsom%20St
  --callback: string # If supplied, the response will use the JSONP format with a callback of the given name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contained_within" $contained_within "scalar") (serialize-qp "attribute:street_address" $attribute_street_address "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geo/similar_places.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"contained_within": $contained_within, "attribute:street_address": $attribute_street_address, "callback": $callback} | compact), body: null}
}

# Returns the current configuration used by Twitter including twitter.com slugs which are not usernames, maximum photo resolutions, and t.co URL lengths. It is recommended applications request this endpoint when they are loaded, but no more than once a day.
#
# GET /help/configuration.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/help/configuration
# operationId: help.configurations
export def "help-configuration-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/help/configuration.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the list of languages supported by Twitter along with their ISO 639-1 code. The ISO 639-1 code is the two letter value to use if you include lang with any of your requests.
#
# GET /help/languages.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/help/languages
# operationId: help.languages
export def "help-languages-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/help/languages.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns Twitter's Privacy Policy
#
# GET /help/privacy.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/help/privacy
# operationId: help.privacy
export def "help-privacy-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/help/privacy.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the Twitter Terms of Service in the requested format. These are not the same as the Developer Rules of the Road.
#
# GET /help/tos.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/help/tos
# operationId: help.tos
export def "help-tos-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/help/tos.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new list for the authenticated user. Note that you can't create more than 20 lists per account.
#
# POST /lists/create.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/create
# operationId: lists.create
export def "lists-create-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name for the list.A list's name must start with a letter and can consist only of 25 or fewer letters, numbers, "-", or "_" characters.
  --mode: string # Whether your list is public or private. Values can be public or private. If no mode is specified the list will be public.
  --description: string # The description to give the list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "description" $description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/create.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "mode": $mode, "description": $description} | compact), body: null}
}

# Deletes the specified list. The authenticated user must own the list to be able to destroy it.
#
# POST /lists/destroy.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/destroy
# operationId: lists.destroy
export def "lists-destroy-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner_screen_name" $owner_screen_name "scalar") (serialize-qp "owner_id" $owner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/destroy.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"owner_screen_name": $owner_screen_name, "owner_id": $owner_id} | compact), body: null}
}

# Returns all lists the authenticating or specified user subscribes to, including their own. The user is specified using the user_id or screen_name parameters. If no user is given, the authenticating user is used. This method used to be GET lists in version 1.0 of the API and has been renamed for consistency with other call.
#
# GET /lists/list.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/list
# operationId: lists.list
export def "lists-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --screen-name: string # The screen name of the user for whom to return results for. Helpful for disambiguating when a valid screen name is also a user ID. Example Values: noradio
  --user-id: string # The ID of the user for whom to return results for. Helpful for disambiguating when a valid user ID is also a valid screen name. Example Values: 12345 Note:: Specifies the ID of the user to get lists from. Helpful for disambiguating when a valid user ID is also a valid screen name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "screen_name" $screen_name "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"screen_name": $screen_name, "user_id": $user_id} | compact), body: null}
}

# Returns the members of the specified list. Private list members will only be shown if the authenticated user owns the specified list.
#
# GET /lists/members.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/members
# operationId: lists.members
export def "lists-members-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --include-entities: string # The entities node will be disincluded when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
  --cursor: string # Causes the collection of list members to be broken into "pages" of somewhat consistent size. If no cursor is provided, a value of -1 will be assumed, which is the first "page." The response from the API will include a previous_cursor and next_cursor to allow paging back and forth. See Using cursors to navigate collections for more information. Example Values: 12893764510938
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner_screen_name" $owner_screen_name "scalar") (serialize-qp "owner_id" $owner_id "scalar") (serialize-qp "include_entities" $include_entities "scalar") (serialize-qp "skip_status" $skip_status "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/members.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"owner_screen_name": $owner_screen_name, "owner_id": $owner_id, "include_entities": $include_entities, "skip_status": $skip_status, "cursor": $cursor} | compact), body: null}
}

# Add a member to a list. The authenticated user must own the list to be able to add members to it. Note that lists can't have more than 500 members.
#
# POST /lists/members/create.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/members/create
# operationId: lists.members.create
export def "lists-members-create-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner_screen_name" $owner_screen_name "scalar") (serialize-qp "owner_id" $owner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/members/create.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"owner_screen_name": $owner_screen_name, "owner_id": $owner_id} | compact), body: null}
}

# Adds multiple members to a list, by specifying a comma-separated list of member ids or screen names. The authenticated user must own the list to be able to add members to it. Note that lists can't have more than 500 members, and you are limited to adding up to 100 members to a list at a time with this method. Please note that there can be issues with lists that rapidly remove and add memberships. Take care when using these methods such that you are not too rapidly switching between removals and adds on the same list.
#
# POST /lists/members/create_all.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/members/create_all
# operationId: lists.members.create_all
export def "lists-members-create-all-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --user-id: string # A comma separated list of user IDs, up to 100 are allowed in a single request.
  --screen-name: string # A comma separated list of screen names, up to 100 are allowed in a single request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner_screen_name" $owner_screen_name "scalar") (serialize-qp "owner_id" $owner_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "screen_name" $screen_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/members/create_all.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"owner_screen_name": $owner_screen_name, "owner_id": $owner_id, "user_id": $user_id, "screen_name": $screen_name} | compact), body: null}
}

# Removes the specified member from the list. The authenticated user must be the list's owner to remove members from the list.
#
# POST /lists/members/destroy.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/members/destroy
# operationId: lists.members.destroy
export def "lists-members-destroy-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --list-id: string # The numerical id of the list.
  --slug: string # You can identify a list by its slug instead of its numerical id. If you decide to do so, note that you'll also have to specify the list owner using the owner_id or owner_screen_name parameters.
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --user-id: string # The ID of the user to remove from the list. Helpful for disambiguating when a valid user ID is also a valid screen name.
  --screen-name: string # The screen name of the user for whom to remove from the list. Helpful for disambiguating when a valid screen name is also a user ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "list_id" $list_id "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "owner_screen_name" $owner_screen_name "scalar") (serialize-qp "owner_id" $owner_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "screen_name" $screen_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/members/destroy.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"list_id": $list_id, "slug": $slug, "owner_screen_name": $owner_screen_name, "owner_id": $owner_id, "user_id": $user_id, "screen_name": $screen_name} | compact), body: null}
}

# Removes multiple members from a list, by specifying a comma-separated list of member ids or screen names. The authenticated user must own the list to be able to remove members from it. Note that lists can't have more than 500 members, and you are limited to removing up to 100 members to a list at a time with this method. Please note that there can be issues with lists that rapidly remove and add memberships. Take care when using these methods such that you are not too rapidly switching between removals and adds on the same list.
#
# POST /lists/members/destroy_all.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/members/destroy_all
# operationId: lists.members.destroy_all
export def "lists-members-destroy-all-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --screen-name: string # A comma separated list of screen names, up to 100 are allowed in a single request.
  --user-id: string # A comma separated list of user IDs, up to 100 are allowed in a single request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner_screen_name" $owner_screen_name "scalar") (serialize-qp "owner_id" $owner_id "scalar") (serialize-qp "screen_name" $screen_name "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/members/destroy_all.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"owner_screen_name": $owner_screen_name, "owner_id": $owner_id, "screen_name": $screen_name, "user_id": $user_id} | compact), body: null}
}

# Check if the specified user is a member of the specified list.
#
# GET /lists/members/show.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/members/show
# operationId: lists.members.show
export def "lists-members-show-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --include-entities: string # When set to either true, t or 1, each tweet will include a node called "entities". This node offers a variety of metadata about the tweet in a discreet structure, including: user_mentions, urls, and hashtags. While entities are opt-in on timelines at present, they will be made a default component of output in the future.
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner_screen_name" $owner_screen_name "scalar") (serialize-qp "owner_id" $owner_id "scalar") (serialize-qp "include_entities" $include_entities "scalar") (serialize-qp "skip_status" $skip_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/members/show.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"owner_screen_name": $owner_screen_name, "owner_id": $owner_id, "include_entities": $include_entities, "skip_status": $skip_status} | compact), body: null}
}

# Returns the lists the specified user has been added to. If user_id or screen_name are not provided the memberships for the authenticating user are returned.
#
# GET /lists/memberships.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/memberships
# operationId: lists.memberships
export def "lists-memberships-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The ID of the user for whom to return results for. Helpful for disambiguating when a valid user ID is also a valid screen name.
  --screen-name: string # The screen name of the user for whom to return results for. Helpful for disambiguating when a valid screen name is also a user ID.
  --cursor: string # Breaks the results into pages. A single page contains 20 lists. Provide a value of -1 to begin paging. Provide values as returned in the response body's next_cursor and previous_cursor attributes to page back and forth in the list.
  --filter-to-owned-lists: string # When set to true, t or 1, will return just lists the authenticating user owns, and the user represented by user_id or screen_name is a member of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "screen_name" $screen_name "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "filter_to_owned_lists" $filter_to_owned_lists "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/memberships.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"user_id": $user_id, "screen_name": $screen_name, "cursor": $cursor, "filter_to_owned_lists": $filter_to_owned_lists} | compact), body: null}
}

# Returns the specified list. Private lists will only be shown if the authenticated user owns the specified list.
#
# GET /lists/show.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/show
# operationId: lists.show
export def "lists-show-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner_screen_name" $owner_screen_name "scalar") (serialize-qp "owner_id" $owner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/show.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"owner_screen_name": $owner_screen_name, "owner_id": $owner_id} | compact), body: null}
}

# Returns tweet timeline for members of the specified list. Retweets are included by default. You can use the include_rts=false parameter to omit retweet objects.
#
# GET /lists/statuses.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/statuses
# operationId: lists.statuses
export def "lists-statuses-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --since-id: string # Returns results with an ID greater than (that is, more recent than) the specified ID. There are limits to the number of Tweets which can be accessed through the API. If the limit of Tweets has occured since the since_id, the since_id will be forced to the oldest ID available.
  --max-id: string # Returns results with an ID less than (that is, older than) or equal to the specified ID.
  --count: string # Specifies the number of results to retrieve per "page.
  --include-entities: string # Entities are ON by default in API 1.1, each tweet includes a node called "entities". This node offers a variety of metadata about the tweet in a discreet structure, including: user_mentions, urls, and hashtags. You can omit entities from the result by using include_entities=false
  --include-rts: string # When set to either true, t or 1, the list timeline will contain native retweets (if they exist) in addition to the standard stream of tweets. The output format of retweeted tweets is identical to the representation you see in home_timeline.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner_screen_name" $owner_screen_name "scalar") (serialize-qp "owner_id" $owner_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "include_entities" $include_entities "scalar") (serialize-qp "include_rts" $include_rts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/statuses.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"owner_screen_name": $owner_screen_name, "owner_id": $owner_id, "since_id": $since_id, "max_id": $max_id, "count": $count, "include_entities": $include_entities, "include_rts": $include_rts} | compact), body: null}
}

# Returns the subscribers of the specified list. Private list subscribers will only be shown if the authenticated user owns the specified list.
#
# GET /lists/subscribers.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/subscribers
# operationId: lists.subscribers
export def "lists-subscribers-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --cursor: string # Breaks the results into pages. A single page contains 20 lists. Provide a value of -1 to begin paging. Provide values as returned in the response body's next_cursor and previous_cursor attributes to page back and forth in the list.
  --include-entities: string # When set to either true, t or 1, each tweet will include a node called "entities". This node offers a variety of metadata about the tweet in a discreet structure, including: user_mentions, urls, and hashtags. While entities are opt-in on timelines at present, they will be made a default component of output in the future. See Tweet Entities for more details.
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner_screen_name" $owner_screen_name "scalar") (serialize-qp "owner_id" $owner_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "include_entities" $include_entities "scalar") (serialize-qp "skip_status" $skip_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/subscribers.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"owner_screen_name": $owner_screen_name, "owner_id": $owner_id, "cursor": $cursor, "include_entities": $include_entities, "skip_status": $skip_status} | compact), body: null}
}

# Subscribes the authenticated user to the specified list.
#
# POST /lists/subscribers/create.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/subscribers/create
# operationId: lists.subscribers.create
export def "lists-subscribers-create-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner_screen_name" $owner_screen_name "scalar") (serialize-qp "owner_id" $owner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/subscribers/create.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"owner_screen_name": $owner_screen_name, "owner_id": $owner_id} | compact), body: null}
}

# Unsubscribes the authenticated user from the specified list.
#
# POST /lists/subscribers/destroy.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/subscribers/destroy
# operationId: lists.subscribers.destroy
export def "lists-subscribers-destroy-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner_screen_name" $owner_screen_name "scalar") (serialize-qp "owner_id" $owner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/subscribers/destroy.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"owner_screen_name": $owner_screen_name, "owner_id": $owner_id} | compact), body: null}
}

# Check if the specified user is a subscriber of the specified list. Returns the user if they are subscriber.
#
# GET /lists/subscribers/show.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/subscribers/show
# operationId: lists.subscribers.show
export def "lists-subscribers-show-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --include-entities: string # When set to either true, t or 1, each tweet will include a node called "entities". This node offers a variety of metadata about the tweet in a discreet structure, including: user_mentions, urls, and hashtags. While entities are opt-in on timelines at present, they will be made a default component of output in the future. See Tweet Entities for more details.
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner_screen_name" $owner_screen_name "scalar") (serialize-qp "owner_id" $owner_id "scalar") (serialize-qp "include_entities" $include_entities "scalar") (serialize-qp "skip_status" $skip_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/subscribers/show.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"owner_screen_name": $owner_screen_name, "owner_id": $owner_id, "include_entities": $include_entities, "skip_status": $skip_status} | compact), body: null}
}

# Obtain a collection of the lists the specified user is subscribed to, 20 lists per page by default. Does not include the user's own lists.
#
# GET /lists/subscriptions.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/subscriptions
# operationId: lists.subscriptions
export def "lists-subscriptions-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: string # The amount of results to return per page. Defaults to 20. Maximum of 1,000 when using cursors.
  --cursor: string # Breaks the results into pages. A single page contains 20 lists. Provide a value of -1 to begin paging. Provide values as returned in the response body's next_cursor and previous_cursor attributes to page back and forth in the list. It is recommended to always use cursors when the method supports them.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/subscriptions.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"count": $count, "cursor": $cursor} | compact), body: null}
}

# Updates the specified list. The authenticated user must own the list to be able to update it.
#
# POST /lists/update.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/update
# operationId: lists.update
export def "lists-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --name: string # The name for the list.
  --mode: string # Whether your list is public or private. Values can be public or private. If no mode is specified the list will be public.
  --description: string # The description to give the list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner_screen_name" $owner_screen_name "scalar") (serialize-qp "owner_id" $owner_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "description" $description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/update.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"owner_screen_name": $owner_screen_name, "owner_id": $owner_id, "name": $name, "mode": $mode, "description": $description} | compact), body: null}
}

# Create a new saved search for the authenticated user. A user may only have 25 saved searches.
#
# POST /saved_searches/create.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/saved_searches/create
# operationId: saved_searches.create
export def "saved-searches-create-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The query of the search the user would like to save.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/saved_searches/create.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query} | compact), body: null}
}

# Destroys a saved search for the authenticating user. The authenticating user must be the owner of saved search id being destroyed.
#
# POST /saved_searches/destroy/{id}.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/saved_searches/destroy/%3Aid
# operationId: saved_searches.destroy
export def "saved-searches-destroy delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/saved_searches/destroy/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the authenticated user's saved search queries.
#
# GET /saved_searches/list.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/saved_searches/list
# operationId: saved_searches.list
export def "saved-searches-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/saved_searches/list.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the authenticated user's saved search queries.
#
# GET /saved_searches/show/{id}.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/saved_searches/show/%3Aid
# operationId: savedsearchesid
export def "saved-searches-show get-savedsearchesid" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/saved_searches/show/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a collection of relevant Tweets matching a specified query. Please note that Twitter's search service and, by extension, the Search API is not meant to be an exhaustive source of Tweets. Not all Tweets will be indexed or made available via the search interface. In API v1.1, the response format of the Search API has been improved to return Tweet objects more similar to the objects you'll find across the REST API and platform. You may need to tolerate some inconsistencies and variance in perspectival values (fields that pertain to the perspective of the authenticating user) and embedded user objects.
#
# GET /search/tweets.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/search/tweets
# operationId: search.tweets
export def "search-tweets-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # A UTF-8, URL-encoded search query of 1,000 characters maximum, including operators. Queries may additionally be limited by complexity.Example: @noradio.
  --geocode: string # Returns tweets by users located within a given radius of the given latitude/longitude. The location is preferentially taking from the Geotagging API, but will fall back to their Twitter profile. The parameter value is specified by "latitude,longitude,radius", where radius units must be specified as either "mi" (miles) or "km" (kilometers). Note that you cannot use the near operator via the API to geocode arbitrary locations; however you can use this geocode parameter to search near geocodes directly. A maximum of 1,000 distinct "sub-regions" will be considered when using the radius modifier.
  --lang: string # Restricts tweets to the given language, given by an ISO 639-1 code. Language detection is best-effort.Example Values: eu
  --locale: string # Specify the language of the query you are sending (only ja is currently effective). This is intended for language-specific consumers and the default should work in the majority of cases.Example Values: ja
  --result-type: string # Optional. Specifies what type of search results you would prefer to receive. The current default is "mixed." Valid values include: * mixed: Include both popular and real time results in the response. * recent: return only the most recent results in the response * popular: return only the most popular results in the response. Example Values: mixed, recent, popular
  --count: string # The number of tweets to return per page, up to a maximum of 100. Defaults to 15. This was formerly the "rpp" parameter in the old Search API. Example Values: 100
  --until: string # Returns tweets generated before the given date. Date should be formatted as YYYY-MM-DD. Keep in mind that the search index may not go back as far as the date you specify here. Example Values: 2012-09-01
  --since-id: string # Returns results with an ID greater than (that is, more recent than) the specified ID. There are limits to the number of Tweets which can be accessed through the API. If the limit of Tweets has occured since the since_id, the since_id will be forced to the oldest ID available. Example Values: 12345
  --max-id: string # Returns results with an ID less than (that is, older than) or equal to the specified ID. Example Values: 12345
  --include-entities: string # The entities node will be disincluded when set to false. Example Values: false
  --callback: string # If supplied, the response will use the JSONP format with a callback of the given name. The usefulness of this parameter is somewhat diminished by the requirement of authentication for requests to this endpoint. Example Values: processTweets
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "geocode" $geocode "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "result_type" $result_type "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "include_entities" $include_entities "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/tweets.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "geocode": $geocode, "lang": $lang, "locale": $locale, "result_type": $result_type, "count": $count, "until": $until, "since_id": $since_id, "max_id": $max_id, "include_entities": $include_entities, "callback": $callback} | compact), body: null}
}

# Destroys the status specified by the required ID parameter. The authenticating user must be the author of the specified status. Returns the destroyed status if successful.
#
# POST /statuses/destroy/{id}.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/statuses/destroy/:id
# operationId: statuses.destroy
export def "statuses-destroy delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trim-user: string # When set to either true, t or 1, each tweet returned in a timeline will include a user object including only the status authors numerical ID. Omit this parameter to receive the complete user object.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "trim_user" $trim_user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/statuses/destroy/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"trim_user": $trim_user} | compact), body: null}
}

# Returns a collection of the most recent Tweets and retweets posted by the authenticating user and the users they follow. The home timeline is central to how most users interact with the Twitter service. Up to 800 Tweets are obtainable on the home timeline. It is more volatile for users that follow many users or follow users who tweet frequently.
#
# GET /statuses/home_timeline.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/statuses/home_timeline
# operationId: statuses.home_timeline
export def "statuses-home-timeline-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Specifies the number of records to retrieve. Must be less than or equal to 200.
  --max-id: int # Returns results with an ID less than (that is, older than) or equal to the specified ID. (format: int64)
  --since-id: int # Returns results with an ID greater than (that is, more recent than) the specified ID. There are limits to the number of Tweets which can be accessed through the API. If the limit of Tweets has occured since the since_id, the since_id will be forced to the oldest ID available. (format: int64)
  --trim-user: string # When set to either true, t or 1, each tweet returned in a timeline will include a user object including only the status authors numerical ID. Omit this parameter to receive the complete user object.
  --exclude-replies: string # This parameter will prevent replies from appearing in the returned timeline. Using exclude_replies with the count parameter will mean you will receive up-to count tweets — this is because the count parameter retrieves that many tweets before filtering out retweets and replies.
  --contributor-details: string # This parameter enhances the contributors element of the status response to include the screen_name of the contributor. By default only the user_id of the contributor is included.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "trim_user" $trim_user "scalar") (serialize-qp "exclude_replies" $exclude_replies "scalar") (serialize-qp "contributor_details" $contributor_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statuses/home_timeline.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"count": $count, "max_id": $max_id, "since_id": $since_id, "trim_user": $trim_user, "exclude_replies": $exclude_replies, "contributor_details": $contributor_details} | compact), body: null}
}

# Returns the 20 most recent mentions (tweets containing a users's @screen_name) for the authenticating user.The timeline returned is the equivalent of the one seen when you view your mentions on twitter.com.This method can only return up to 800 statuses.This method will include retweets in the JSON response regardless of whether the include_rts parameter is set.
#
# GET /statuses/mentions_timeline.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/statuses/mentions_timeline
# operationId: statuses.mentions.timeline
export def "statuses-mentions-timeline-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Specifies the number of tweets to try and retrieve, up to a maximum of 200. The value of count is best thought of as a limit to the number of tweets to return because suspended or deleted content is removed after the count has been applied. We include retweets in the count, even if include_rts is not supplied. It is recommended you always send include_rts=1 when using this API method.
  --since-id: int # Returns results with an ID greater than (that is, more recent than) the specified ID. There are limits to the number of Tweets which can be accessed through the API. If the limit of Tweets has occured since the since_id, the since_id will be forced to the oldest ID available. (format: int64)
  --max-id: int # Returns results with an ID less than (that is, older than) or equal to the specified ID. (format: int64)
  --trim-user: string # When set to either true, t or 1, each tweet returned in a timeline will include a user object including only the status authors numerical ID. Omit this parameter to receive the complete user object.
  --contributor-details: string # This parameter enhances the contributors element of the status response to include the screen_name of the contributor. By default only the user_id of the contributor is included.
  --include-entities: oneof<nothing, bool> # The entities node will be disincluded when set to false.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "trim_user" $trim_user "scalar") (serialize-qp "contributor_details" $contributor_details "scalar") (serialize-qp "include_entities" $include_entities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statuses/mentions_timeline.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"count": $count, "since_id": $since_id, "max_id": $max_id, "trim_user": $trim_user, "contributor_details": $contributor_details, "include_entities": $include_entities} | compact), body: null}
}

# Returns information allowing the creation of an embedded representation of a Tweet on third party sites. See the oEmbed specification (http://oembed.com) for information about the response format. Either the id or url parameters must be specified in a request, it is not necessary to include both. While this endpoint allows a bit of customization for the final appearance of the embedded Tweet, be aware that the appearance of the rendered Tweet may change over time to be consistent with Twitter's Display Guidelines (https://dev.twitter.com/terms/display-guidelines). Do not rely on any class or id parameters to stay constant in the returned markup.
#
# GET /statuses/oembed.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/statuses/oembed
# operationId: statuses.oembed
export def "statuses-oembed-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxwidth: int # The maximum width in pixels that the embed should be rendered at. This value is constrained to be between 250 and 550 pixels. Note that Twitter does not support the oEmbed maxheight parameter. Tweets are fundamentally text, and are therefore of unpredictable height that cannot be scaled like an image or video. Relatedly, the oEmbed response will not provide a value for height. Implementations that need consistent heights for Tweets should refer to the hide_thread and hide_media parameters below.
  --hide-media: string # Specifies whether the embedded Tweet should automatically expand images which were uploaded via POST statuses/update_with_media. When set to either true, t or 1 images will not be expanded. Defaults to false.
  --hide-thread: string # Specifies whether the embedded Tweet should automatically show the original message in the case that the embedded Tweet is a reply. When set to either true, t or 1 the original Tweet will not be shown. Defaults to false.
  --omit-script: string # Specifies whether the embedded Tweet HTML should include a 'script' element pointing to widgets.js. In cases where a page already includes widgets.js, setting this value to true will prevent a redundant script element from being included. When set to either true, t or 1 the 'script'element will not be included in the embed HTML, meaning that pages must include a reference to widgets.js manually. Defaults to false.
  --align: string@align-completer # Specifies whether the embedded Tweet should be left aligned, right aligned, or centered in the page. Valid values are left, right, center, and none. Defaults to none, meaning no alignment styles are specified for the Tweet.
  --related: string # A value for the TWT related parameter, as described in Web Intents (https://dev.twitter.com/docs/intents). This value will be forwarded to all Web Intents calls. Example values: twitterapi, twittermedia, twitter.
  --lang: string # Language code for the rendered embed. This will affect the text and localization of the rendered HTML. Example value: fr
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxwidth" $maxwidth "scalar") (serialize-qp "hide_media" $hide_media "scalar") (serialize-qp "hide_thread" $hide_thread "scalar") (serialize-qp "omit_script" $omit_script "scalar") (serialize-qp "align" $align "scalar") (serialize-qp "related" $related "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statuses/oembed.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxwidth": $maxwidth, "hide_media": $hide_media, "hide_thread": $hide_thread, "omit_script": $omit_script, "align": $align, "related": $related, "lang": $lang} | compact), body: null}
}

# Retweets a tweet. Returns the original tweet with retweet details embedded.
#
# POST /statuses/retweet/{id}.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/statuses/retweet/:id
# operationId: statusesretweetid
export def "statuses-retweet create-statusesretweetid" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trim-user: string # When set to either true, t or 1, each tweet returned in a timeline will include a user object including only the status authors numerical ID. Omit this parameter to receive the complete user object.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "trim_user" $trim_user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/statuses/retweet/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"trim_user": $trim_user} | compact), body: null}
}

# Returns up to 100 of the first retweets of a given tweet.
#
# GET /statuses/retweets/{id}.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/statuses/retweets/:id
# operationId: statuses.retweets
export def "statuses-retweets get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: string # Specifies the number of records to retrieve. Must be less than or equal to 100.
  --trim-user: string # When set to either true, t or 1, each tweet returned in a timeline will include a user object including only the status authors numerical ID. Omit this parameter to receive the complete user object.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "trim_user" $trim_user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/statuses/retweets/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"count": $count, "trim_user": $trim_user} | compact), body: null}
}

# Returns a single status, specified by the id parameter below. The status's author will be returned inline.
#
# GET /statuses/show/{id}.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/statuses/show/:id
# operationId: statuses.show
export def "statuses-show get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trim-user: string # When set to either true, t or 1, each tweet returned in a timeline will include a user object including only the status authors numerical ID. Omit this parameter to receive the complete user object.
  --include-my-retweet: string # When set to either true, t or 1, any Tweets returned that have been retweeted by the authenticating user will include an additional current_user_retweet node, containing the ID of the source status for the retweet.
  --include-entities: string # The entities node will be disincluded when set to false.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "trim_user" $trim_user "scalar") (serialize-qp "include_my_retweet" $include_my_retweet "scalar") (serialize-qp "include_entities" $include_entities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/statuses/show/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"trim_user": $trim_user, "include_my_retweet": $include_my_retweet, "include_entities": $include_entities} | compact), body: null}
}

# Updates the authenticating user's status, also known as tweeting. To upload an image to accompany the tweet, use POST statuses/update_with_media (https://dev.twitter.com/docs/api/1/post/statuses/update_with_media). For each update attempt, the update text is compared with the authenticating user's recent tweets. Any attempt that would result in duplication will be blocked, resulting in a 403 error. Therefore, a user cannot submit the same status twice in a row. While not rate limited by the API a user is limited in the number of tweets they can create at a time. If the number of updates posted by the user reaches the current allowed limit this method will return an HTTP 403 error.
#
# POST /statuses/update.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/statuses/update
# operationId: statuses.update
export def "statuses-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # The text of your status update, typically up to 140 characters. URL encode as necessary. t.co link short-url wrapping (https://dev.twitter.com/docs/tco-link-wrapper/faq) may effect character counts. (default: Posting from @apigee's API test console. It's like a command line for the Twitter API! #apitools)
  --in-reply-to-status-id: string # The ID of an existing status that the update is in reply to. Note: This parameter will be ignored unless the author of the tweet this parameter references is mentioned within the status text. Therefore, you must include @username, where username is the author of the referenced tweet, within the update.
  --lat: string # The latitude of the location this tweet refers to. This parameter will be ignored unless it is inside the range -90.0 to +90.0 (North is positive) inclusive. It will also be ignored if there isn't a corresponding long parameter. (default: 37.426363)
  --long: string # The longitude of the location this tweet refers to. The valid ranges for longitude is -180.0 to +180.0 (East is positive) inclusive. This parameter will be ignored if outside that range, if it is not a number, if geo_enabled is disabled, or if there not a corresponding lat parameter. (default: -122.141114)
  --place-id: string # A place in the world. These IDs can be retrieved from GET geo/reverse_geocode (https://dev.twitter.com/docs/api/1/get/geo/reverse_geocode).
  --display-coordinates: string@display-coordinates-completer # Whether or not to put a pin on the exact coordinates a tweet has been sent from. (default: false)
  --trim-user: string # When set to either true, t or 1, each tweet returned in a timeline will include a user object including only the status authors numerical ID. Omit this parameter to receive the complete user object.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "in_reply_to_status_id" $in_reply_to_status_id "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "long" $long "scalar") (serialize-qp "place_id" $place_id "scalar") (serialize-qp "display_coordinates" $display_coordinates "scalar") (serialize-qp "trim_user" $trim_user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statuses/update.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"status": $status, "in_reply_to_status_id": $in_reply_to_status_id, "lat": $lat, "long": $long, "place_id": $place_id, "display_coordinates": $display_coordinates, "trim_user": $trim_user} | compact), body: null}
}

# Updates the authenticating user's status and attaches media for upload. Unlike POST statuses/update (https://dev.twitter.com/docs/api/1.1/post/statuses/update), this method expects raw multipart data. Your POST request's Content-Type should be set to multipart/form-data with the media[] parameter. The Tweet text will be rewritten to include the media URL(s), which will reduce the number of characters allowed in the Tweet text. If the URL(s) cannot be appended without text truncation, the tweet will be rejected and this method will return an HTTP 403 error. Important: Make sure that you're using upload.twitter.com as your host while posting statuses with media. It is strongly recommended to use SSL with this method.
#
# POST /statuses/update_with_media.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/statuses/update_with_media
# operationId: statuses.update_with_media
export def "statuses-update-with-media-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # The text of your status update. URL encode as necessary. t.co link wrapping (https://dev.twitter.com/docs/tco-link-wrapper/faq) may affect character counts if the post contains URLs. You must additionally account for the characters_reserved_per_media per uploaded media, additionally accounting for space characters in between finalized URLs. Note: Request the GET help/configuration (https://dev.twitter.com/docs/api/1.1/get/help/configuration) endpoint to get the current characters_reserved_per_media and max_media_per_upload values.
  --media: string # Up to max_media_per_upload files may be specified in the request, each named media[]. Supported image formats are PNG, JPG and GIF. Animated GIFs are not supported. Note: Request the GET help/configuration (https://dev.twitter.com/docs/api/1.1/get/help/configuration) endpoint to get the current max_media_per_upload and photo_size_limit values.
  --possibly-sensitive: string # Set to true for content which may not be suitable for every audience.
  --in-reply-to-status-id: string # The ID of an existing status that the update is in reply to. Note: This parameter will be ignored unless the author of the tweet this parameter references is mentioned within the status text. Therefore, you must include @username, where username is the author of the referenced tweet, within the update.
  --lat: string # The latitude of the location this tweet refers to. This parameter will be ignored unless it is inside the range -90.0 to +90.0 (North is positive) inclusive. It will also be ignored if there isn't a corresponding long parameter. Example value: 37.7821120598956.
  --long: string # The longitude of the location this tweet refers to. The valid ranges for longitude is -180.0 to +180.0 (East is positive) inclusive. This parameter will be ignored if outside that range, not a number, geo_enabled is disabled, or if there not a corresponding lat parameter. Example value: -122.400612831116.
  --place-id: string # A place in the world identified by a Twitter place ID. Place IDs can be retrieved from geo/reverse_geocode.
  --display-coordinates: string # Whether or not to put a pin on the exact coordinates a tweet has been sent from.
  --content-type: string # Content type.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "media" $media "scalar") (serialize-qp "possibly_sensitive" $possibly_sensitive "scalar") (serialize-qp "in_reply_to_status_id" $in_reply_to_status_id "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "long" $long "scalar") (serialize-qp "place_id" $place_id "scalar") (serialize-qp "display_coordinates" $display_coordinates "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statuses/update_with_media.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"status": $status, "media": $media, "possibly_sensitive": $possibly_sensitive, "in_reply_to_status_id": $in_reply_to_status_id, "lat": $lat, "long": $long, "place_id": $place_id, "display_coordinates": $display_coordinates} | compact), body: null}
}

# Returns the 20 most recent statuses posted by the authenticating user. It is also possible to request another user's timeline by using the screen_name or user_id parameter. The other users timeline will only be visible if they are not protected, or if the authenticating user's follow request was accepted by the protected user. The timeline returned is the equivalent of the one seen when you view a user's profile on twitter.com. This method can only return up to 3,200 of a user's most recent statuses. Native retweets of other statuses by the user is included in this total, regardless of whether include_rts is specified when requesting this resource. This method will not include retweets in the XML and JSON responses unless the include_rts parameter is set. The RSS and Atom responses will always include retweets as statuses prefixed with RT, regardless of provided parameters. Always specify either an user_id or screen_name when requesting a user timeline.
#
# GET /statuses/user_timeline.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/statuses/user_timeline
# operationId: statuses.user_timeline
export def "statuses-user-timeline-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Specifies the number of tweets to try and retrieve, up to a maximum of 200. The value of count is best thought of as a limit to the number of tweets to return because suspended or deleted content is removed after the count has been applied. We include retweets in the count, even if include_rts is not supplied. It is recommended you always send include_rts=1 when using this API method.
  --since-id: int # Returns results with an ID greater than (that is, more recent than) the specified ID. There are limits to the number of Tweets which can be accessed through the API. If the limit of Tweets has occured since the since_id, the since_id will be forced to the oldest ID available. (format: int64)
  --max-id: int # Returns results with an ID less than (that is, older than) or equal to the specified ID. (format: int64)
  --trim-user: string # When set to either true, t or 1, each tweet returned in a timeline will include a user object including only the status authors numerical ID. Omit this parameter to receive the complete user object.
  --exclude-replies: oneof<nothing, bool> # This parameter will prevent replies from appearing in the returned timeline. Using exclude_replies with the count parameter will mean you will receive up-to count tweets — this is because the count parameter retrieves that many tweets before filtering out retweets and replies. This parameter is only supported for JSON and XML responses.
  --contributor-details: oneof<nothing, bool> # This parameter enhances the contributors element of the status response to include the screen_name of the contributor. By default only the user_id of the contributor is included.
  --include-rts: oneof<nothing, bool> # When set to false, the timeline will strip any native retweets (though they will still count toward both the maximal length of the timeline and the slice selected by the count parameter). Note: If you're using the trim_user parameter in conjunction with include_rts, the retweets will still contain a full user object.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "trim_user" $trim_user "scalar") (serialize-qp "exclude_replies" $exclude_replies "scalar") (serialize-qp "contributor_details" $contributor_details "scalar") (serialize-qp "include_rts" $include_rts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statuses/user_timeline.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"count": $count, "since_id": $since_id, "max_id": $max_id, "trim_user": $trim_user, "exclude_replies": $exclude_replies, "contributor_details": $contributor_details, "include_rts": $include_rts} | compact), body: null}
}

# Returns the locations that Twitter has trending topic information for. The response is an array of "locations" that encode the location's WOEID and some other human-readable information such as a canonical name and country the location belongs in. A WOEID is a Yahoo! Where On Earth ID.
#
# GET /trends/available.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/trends/available
# operationId: trends.available
export def "trends-available-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/trends/available.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the locations that Twitter has trending topic information for, closest to a specified location. The response is an array of "locations" that encode the location's WOEID and some other human-readable information such as a canonical name and country the location belongs in. A WOEID is a Yahoo! Where On Earth ID.
#
# GET /trends/closest.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/trends/closest
# operationId: trends.closest
export def "trends-closest-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: string # If provided with a long parameter the available trend locations will be sorted by distance, nearest to furthest, to the co-ordinate pair. The valid ranges for longitude is -180.0 to +180.0 (West is negative, East is positive) inclusive. Example Values: 37.781157
  --long: string # If provided with a lat parameter the available trend locations will be sorted by distance, nearest to furthest, to the co-ordinate pair. The valid ranges for longitude is -180.0 to +180.0 (West is negative, East is positive) inclusive. Example Values: -122.400612831116
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "long" $long "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/trends/closest.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lat": $lat, "long": $long} | compact), body: null}
}

# Returns the top 10 trending topics for a specific WOEID, if trending information is available for it. The response is an array of "trend" objects that encode the name of the trending topic, the query parameter that can be used to search for the topic on Twitter Search, and the Twitter Search URL. This information is cached for 5 minutes. Requesting more frequently than that will not return any more data, and will count against your rate limit usage.
#
# GET /trends/place.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/trends/place
# operationId: trends.place
export def "trends-place-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The Yahoo! Where On Earth ID of the location to return trending information for. Global information is available by using 1 as the WOEID.
  --exclude: string # Setting this equal to hashtags will remove all hashtags from the trends list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/trends/place.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "exclude": $exclude} | compact), body: null}
}

# Returns a collection of users that the specified user can contribute to.
#
# GET /users/contributees.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/users/contributees
# operationId: users.contributees
export def "users-contributees-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-entities: string # The entities node will be disincluded when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_entities" $include_entities "scalar") (serialize-qp "skip_status" $skip_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/contributees.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_entities": $include_entities, "skip_status": $skip_status} | compact), body: null}
}

# Returns a collection of users who can contribute to the specified account.
#
# GET /users/contributors.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/users/contributors
# operationId: users.contributors
export def "users-contributors-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-entities: string # The entities node will be disincluded when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_entities" $include_entities "scalar") (serialize-qp "skip_status" $skip_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/contributors.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_entities": $include_entities, "skip_status": $skip_status} | compact), body: null}
}

# Returns fully-hydrated user objects for up to 100 users per request, as specified by comma-separated values passed to the user_id and/or screen_name parameters. This method is especially useful when used in conjunction with collections of user IDs returned from GET friends/ids and GET followers/ids. GET users/show is used to retrieve a single user object.
#
# GET /users/lookup.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/users/lookup
# operationId: users.lookup
export def "users-lookup-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --screen-name: string # A comma separated list of screen names, up to 100 are allowed in a single request. You are strongly encouraged to use a POST for larger (up to 100 screen names) requests. Example Values: twitterapi,twitter
  --user-id: string # A comma separated list of user IDs, up to 100 are allowed in a single request. You are strongly encouraged to use a POST for larger requests. Example Values: 783214,6253282
  --include-entities: string # The entities node that may appear within embedded statuses will be disincluded when set to false. Example Values: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "screen_name" $screen_name "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "include_entities" $include_entities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/lookup.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"screen_name": $screen_name, "user_id": $user_id, "include_entities": $include_entities} | compact), body: null}
}

# The user specified in the id is blocked by the authenticated user and reported as a spammer.
#
# POST /users/report_spam.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/report_spam
# operationId: users.report_spam
export def "users-report-spam-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/report_spam.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Provides a simple, relevance-based search interface to public user accounts on Twitter. Try querying by topical interest, full name, company name, location, or other criteria. Exact match searches are not supported. Only the first 1,000 matching results are available.
#
# GET /users/search.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/users/search
# operationId: users.search
export def "users-search-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The search query to run against people search. Example Values: Twitter%20API
  --page: string # Specifies the page of results to retrieve. Example Values: 3
  --count: string # The number of potential user results to retrieve per page. This value has a maximum of 20. Example Values: 5
  --include-entities: string # The entities node will be disincluded when set to false. Example Values: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "include_entities" $include_entities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/search.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "page": $page, "count": $count, "include_entities": $include_entities} | compact), body: null}
}

# Returns a variety of information about the user specified by the required user_id or screen_name parameter. The author's most recent Tweet will be returned inline when possible. GET users/lookup is used to retrieve a bulk collection of user objects.
#
# GET /users/show.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/users/show
# operationId: users.show
export def "users-show-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --screen-name: string # The screen name of the user for whom to return results for. Either a id or screen_name is required for this method. Example Values: noradio
  --user-id: string # The ID of the user for whom to return results for. Either an id or screen_name is required for this method. Example Values: 12345
  --include-entities: string # The entities node will be disincluded when set to false. Example Values: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "screen_name" $screen_name "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "include_entities" $include_entities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/show.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"screen_name": $screen_name, "user_id": $user_id, "include_entities": $include_entities} | compact), body: null}
}

# Access to Twitter's suggested user list. This returns the list of suggested user categories. The category can be used in GET users/suggestions/:slug to get the users in that category.
#
# GET /users/suggestions.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/users/suggestions
# operationId: users.suggestions
export def "users-suggestions-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Restricts the suggested categories to the requested language. The language must be specified by the appropriate two letter ISO 639-1 representation. Currently supported languages are provided by the GET help/languages API request. Unsupported language codes will receive English (en) results. If you use lang in this request, ensure you also include it when requesting the GET users/suggestions/:slug list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/suggestions.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang} | compact), body: null}
}

# Access the users in a given category of the Twitter suggested user list. It is recommended that applications cache this data for no more than one hour.
#
# GET /users/suggestions/{slug}.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/users/suggestions/%3Aslug
# operationId: users.suggestions.slug
export def "users-suggestions get" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Restricts the suggested categories to the requested language. The language must be specified by the appropriate two letter ISO 639-1 representation. Currently supported languages are provided by the GET help/languages API request. Unsupported language codes will receive English (en) results. If you use lang in this request, ensure you also include it when requesting the GET users/suggestions/:slug list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($slug | is-empty) { error make --unspanned { msg: "path parameter 'slug' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({slug: (encode-path-segment $slug)} | format pattern "/users/suggestions/{slug}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang} | compact), body: null}
}

# Access the users in a given category of the Twitter suggested user list and return their most recent status if they are not a protected user.
#
# GET /users/suggestions/{slug}/members.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/users/suggestions/%3Aslug/members
# operationId: users.suggestionsslugmembers
export def "users-suggestions-members-json get-suggestionsslugmembers" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($slug | is-empty) { error make --unspanned { msg: "path parameter 'slug' must be non-empty" } }
  let full_url = (build-url $base ({slug: (encode-path-segment $slug)} | format pattern "/users/suggestions/{slug}/members.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
