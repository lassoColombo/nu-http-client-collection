# Auto-generated client for Unofficial Lemmy OpenAPI Documentation vv0.19.11
# Source: https://raw.githubusercontent.com/MV-GH/lemmy_openapi_spec/master/lemmy_spec.yaml
# Auth: --token flag or $env.UNOFFICIAL_LEMMY_OPENAPI_DOCUMENTATION_TOKEN

const BASE_URL = "https://lemmy.ml/api/v3"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o UNOFFICIAL_LEMMY_OPENAPI_DOCUMENTATION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "cookie-auth" => { {headers: {Cookie: $"auth=($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://lemmy.ml/api/v3" "https://enterprise.lemmy.ml/api/v3" "https://ds9.lemmy.ml/api/v3" "https://voyager.lemmy.ml/api/v3"] }
def auth-scheme-completer [] { ["bearer" "cookie-auth"] }

# Completers for enum parameters
def default-post-listing-type-completer [] { ["All" "Local" "ModeratorView" "Subscribed"] }
def default-sort-type-completer [] { ["Active" "Controversial" "Hot" "MostComments" "New" "NewComments" "Old" "Scaled" "TopAll" "TopDay" "TopHour" "TopMonth" "TopNineMonths" "TopSixHour" "TopSixMonths" "TopThreeMonths" "TopTwelveHour" "TopWeek" "TopYear"] }
def registration-mode-completer [] { ["Closed" "Open" "RequireApplication"] }
def default-post-listing-mode-completer [] { ["Card" "List" "SmallCard"] }
def visibility-completer [] { ["LocalOnly" "Public"] }
def feature-type-completer [] { ["Community" "Local"] }
def default-listing-type-completer [] { ["All" "Local" "ModeratorView" "Subscribed"] }
def post-listing-mode-completer [] { ["Card" "List" "SmallCard"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "site get" } } | get name | first)
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

# Gets the site, and your user data.
#
# GET /site
export def "site get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<site_view: record<site: record<id: int, name: string, sidebar: string, published: string, updated: string, icon: string, banner: string, description: string, actor_id: string, last_refreshed_at: string, inbox_url: string, public_key: string, instance_id: int, content_warning: string>, local_site: record<id: int, site_id: int, site_setup: bool, enable_downvotes: bool, enable_nsfw: bool, community_creation_admin_only: bool, require_email_verification: bool, application_question: string, private_instance: bool, default_theme: string, default_post_listing_type: string, legal_information: string, hide_modlog_mod_names: bool, application_email_admins: bool, slur_filter_regex: string, actor_name_max_length: int, federation_enabled: bool, captcha_enabled: bool, captcha_difficulty: string, published: string, updated: string, registration_mode: string, reports_email_admins: bool, federation_signed_fetch: bool, default_post_listing_mode: string, default_sort_type: string>, local_site_rate_limit: record<local_site_id: int, message: int, message_per_second: int, post: int, post_per_second: int, register: int, register_per_second: int, image: int, image_per_second: int, comment: int, comment_per_second: int, search: int, search_per_second: int, published: string, updated: string, import_user_settings: int, import_user_settings_per_second: int>, counts: record<site_id: int, users: int, posts: int, comments: int, communities: int, users_active_day: int, users_active_week: int, users_active_month: int, users_active_half_year: int>>, admins: table<person: record, counts: record, is_admin: bool>, version: string, my_user: record<local_user_view: record<local_user: record, local_user_vote_display_mode: record, person: record, counts: record>, follows: list<record>, moderates: list<record>, community_blocks: list<record>, instance_blocks: list<record>, person_blocks: list<record>, discussion_languages: list<int>>, all_languages: table<id: int, code: string, name: string>, discussion_languages: list<int>, taglines: table<id: int, local_site_id: int, content: string, published: string, updated: string>, custom_emojis: table<custom_emoji: record, keywords: list>, blocked_urls: table<id: int, url: string, published: string, updated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/site")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create your site.
#
# POST /site
export def "site post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --sidebar: string
  --description: string
  --icon: string
  --banner: string
  --enable-downvotes: oneof<nothing, bool>
  --enable-nsfw: oneof<nothing, bool>
  --community-creation-admin-only: oneof<nothing, bool>
  --require-email-verification: oneof<nothing, bool>
  --application-question: string
  --private-instance: oneof<nothing, bool>
  --default-theme: string
  --default-post-listing-type: string@default-post-listing-type-completer
  --default-sort-type: string@default-sort-type-completer
  --legal-information: string
  --application-email-admins: oneof<nothing, bool>
  --hide-modlog-mod-names: oneof<nothing, bool>
  --discussion-languages: list
  --slur-filter-regex: string
  --actor-name-max-length: int
  --rate-limit-message: int
  --rate-limit-message-per-second: int
  --rate-limit-post: int
  --rate-limit-post-per-second: int
  --rate-limit-register: int
  --rate-limit-register-per-second: int
  --rate-limit-image: int
  --rate-limit-image-per-second: int
  --rate-limit-comment: int
  --rate-limit-comment-per-second: int
  --rate-limit-search: int
  --rate-limit-search-per-second: int
  --federation-enabled: oneof<nothing, bool>
  --federation-debug: oneof<nothing, bool>
  --captcha-enabled: oneof<nothing, bool>
  --captcha-difficulty: string
  --allowed-instances: list
  --blocked-instances: list
  --taglines: list
  --registration-mode: string@registration-mode-completer
  --content-warning: string
  --default-post-listing-mode: string@default-post-listing-mode-completer
]: any -> record<site_view: record<site: record<id: int, name: string, sidebar: string, published: string, updated: string, icon: string, banner: string, description: string, actor_id: string, last_refreshed_at: string, inbox_url: string, public_key: string, instance_id: int, content_warning: string>, local_site: record<id: int, site_id: int, site_setup: bool, enable_downvotes: bool, enable_nsfw: bool, community_creation_admin_only: bool, require_email_verification: bool, application_question: string, private_instance: bool, default_theme: string, default_post_listing_type: string, legal_information: string, hide_modlog_mod_names: bool, application_email_admins: bool, slur_filter_regex: string, actor_name_max_length: int, federation_enabled: bool, captcha_enabled: bool, captcha_difficulty: string, published: string, updated: string, registration_mode: string, reports_email_admins: bool, federation_signed_fetch: bool, default_post_listing_mode: string, default_sort_type: string>, local_site_rate_limit: record<local_site_id: int, message: int, message_per_second: int, post: int, post_per_second: int, register: int, register_per_second: int, image: int, image_per_second: int, comment: int, comment_per_second: int, search: int, search_per_second: int, published: string, updated: string, import_user_settings: int, import_user_settings_per_second: int>, counts: record<site_id: int, users: int, posts: int, comments: int, communities: int, users_active_day: int, users_active_week: int, users_active_month: int, users_active_half_year: int>>, taglines: table<id: int, local_site_id: int, content: string, published: string, updated: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/site")
  let body = {name: $name, sidebar: $sidebar, description: $description, icon: $icon, banner: $banner, enable_downvotes: $enable_downvotes, enable_nsfw: $enable_nsfw, community_creation_admin_only: $community_creation_admin_only, require_email_verification: $require_email_verification, application_question: $application_question, private_instance: $private_instance, default_theme: $default_theme, default_post_listing_type: $default_post_listing_type, default_sort_type: $default_sort_type, legal_information: $legal_information, application_email_admins: $application_email_admins, hide_modlog_mod_names: $hide_modlog_mod_names, discussion_languages: $discussion_languages, slur_filter_regex: $slur_filter_regex, actor_name_max_length: $actor_name_max_length, rate_limit_message: $rate_limit_message, rate_limit_message_per_second: $rate_limit_message_per_second, rate_limit_post: $rate_limit_post, rate_limit_post_per_second: $rate_limit_post_per_second, rate_limit_register: $rate_limit_register, rate_limit_register_per_second: $rate_limit_register_per_second, rate_limit_image: $rate_limit_image, rate_limit_image_per_second: $rate_limit_image_per_second, rate_limit_comment: $rate_limit_comment, rate_limit_comment_per_second: $rate_limit_comment_per_second, rate_limit_search: $rate_limit_search, rate_limit_search_per_second: $rate_limit_search_per_second, federation_enabled: $federation_enabled, federation_debug: $federation_debug, captcha_enabled: $captcha_enabled, captcha_difficulty: $captcha_difficulty, allowed_instances: $allowed_instances, blocked_instances: $blocked_instances, taglines: $taglines, registration_mode: $registration_mode, content_warning: $content_warning, default_post_listing_mode: $default_post_listing_mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit your site.
#
# PUT /site
export def "site put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --sidebar: string
  --description: string
  --icon: string
  --banner: string
  --enable-downvotes: oneof<nothing, bool>
  --enable-nsfw: oneof<nothing, bool>
  --community-creation-admin-only: oneof<nothing, bool>
  --require-email-verification: oneof<nothing, bool>
  --application-question: string
  --private-instance: oneof<nothing, bool>
  --default-theme: string
  --default-post-listing-type: string@default-post-listing-type-completer
  --default-sort-type: string@default-sort-type-completer
  --legal-information: string
  --application-email-admins: oneof<nothing, bool>
  --hide-modlog-mod-names: oneof<nothing, bool>
  --discussion-languages: list
  --slur-filter-regex: string
  --actor-name-max-length: int
  --rate-limit-message: int
  --rate-limit-message-per-second: int
  --rate-limit-post: int
  --rate-limit-post-per-second: int
  --rate-limit-register: int
  --rate-limit-register-per-second: int
  --rate-limit-image: int
  --rate-limit-image-per-second: int
  --rate-limit-comment: int
  --rate-limit-comment-per-second: int
  --rate-limit-search: int
  --rate-limit-search-per-second: int
  --federation-enabled: oneof<nothing, bool>
  --federation-debug: oneof<nothing, bool>
  --captcha-enabled: oneof<nothing, bool>
  --captcha-difficulty: string
  --allowed-instances: list
  --blocked-instances: list
  --blocked-urls: list
  --taglines: list
  --registration-mode: string@registration-mode-completer
  --reports-email-admins: oneof<nothing, bool>
  --content-warning: string
  --default-post-listing-mode: string@default-post-listing-mode-completer
]: any -> record<site_view: record<site: record<id: int, name: string, sidebar: string, published: string, updated: string, icon: string, banner: string, description: string, actor_id: string, last_refreshed_at: string, inbox_url: string, public_key: string, instance_id: int, content_warning: string>, local_site: record<id: int, site_id: int, site_setup: bool, enable_downvotes: bool, enable_nsfw: bool, community_creation_admin_only: bool, require_email_verification: bool, application_question: string, private_instance: bool, default_theme: string, default_post_listing_type: string, legal_information: string, hide_modlog_mod_names: bool, application_email_admins: bool, slur_filter_regex: string, actor_name_max_length: int, federation_enabled: bool, captcha_enabled: bool, captcha_difficulty: string, published: string, updated: string, registration_mode: string, reports_email_admins: bool, federation_signed_fetch: bool, default_post_listing_mode: string, default_sort_type: string>, local_site_rate_limit: record<local_site_id: int, message: int, message_per_second: int, post: int, post_per_second: int, register: int, register_per_second: int, image: int, image_per_second: int, comment: int, comment_per_second: int, search: int, search_per_second: int, published: string, updated: string, import_user_settings: int, import_user_settings_per_second: int>, counts: record<site_id: int, users: int, posts: int, comments: int, communities: int, users_active_day: int, users_active_week: int, users_active_month: int, users_active_half_year: int>>, taglines: table<id: int, local_site_id: int, content: string, published: string, updated: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/site")
  let body = {name: $name, sidebar: $sidebar, description: $description, icon: $icon, banner: $banner, enable_downvotes: $enable_downvotes, enable_nsfw: $enable_nsfw, community_creation_admin_only: $community_creation_admin_only, require_email_verification: $require_email_verification, application_question: $application_question, private_instance: $private_instance, default_theme: $default_theme, default_post_listing_type: $default_post_listing_type, default_sort_type: $default_sort_type, legal_information: $legal_information, application_email_admins: $application_email_admins, hide_modlog_mod_names: $hide_modlog_mod_names, discussion_languages: $discussion_languages, slur_filter_regex: $slur_filter_regex, actor_name_max_length: $actor_name_max_length, rate_limit_message: $rate_limit_message, rate_limit_message_per_second: $rate_limit_message_per_second, rate_limit_post: $rate_limit_post, rate_limit_post_per_second: $rate_limit_post_per_second, rate_limit_register: $rate_limit_register, rate_limit_register_per_second: $rate_limit_register_per_second, rate_limit_image: $rate_limit_image, rate_limit_image_per_second: $rate_limit_image_per_second, rate_limit_comment: $rate_limit_comment, rate_limit_comment_per_second: $rate_limit_comment_per_second, rate_limit_search: $rate_limit_search, rate_limit_search_per_second: $rate_limit_search_per_second, federation_enabled: $federation_enabled, federation_debug: $federation_debug, captcha_enabled: $captcha_enabled, captcha_difficulty: $captcha_difficulty, allowed_instances: $allowed_instances, blocked_instances: $blocked_instances, blocked_urls: $blocked_urls, taglines: $taglines, registration_mode: $registration_mode, reports_email_admins: $reports_email_admins, content_warning: $content_warning, default_post_listing_mode: $default_post_listing_mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the modlog.
#
# GET /modlog
export def "modlog get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --GetModlog: record
]: nothing -> record<removed_posts: table<mod_remove_post: record, moderator: record, post: record, community: record>, locked_posts: table<mod_lock_post: record, moderator: record, post: record, community: record>, featured_posts: table<mod_feature_post: record, moderator: record, post: record, community: record>, removed_comments: table<mod_remove_comment: record, moderator: record, comment: record, commenter: record, post: record, community: record>, removed_communities: table<mod_remove_community: record, moderator: record, community: record>, banned_from_community: table<mod_ban_from_community: record, moderator: record, community: record, banned_person: record>, banned: table<mod_ban: record, moderator: record, banned_person: record>, added_to_community: table<mod_add_community: record, moderator: record, community: record, modded_person: record>, transferred_to_community: table<mod_transfer_community: record, moderator: record, community: record, modded_person: record>, added: table<mod_add: record, moderator: record, modded_person: record>, admin_purged_persons: table<admin_purge_person: record, admin: record>, admin_purged_communities: table<admin_purge_community: record, admin: record>, admin_purged_posts: table<admin_purge_post: record, admin: record, community: record>, admin_purged_comments: table<admin_purge_comment: record, admin: record, post: record>, hidden_communities: table<mod_hide_community: record, admin: record, community: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GetModlog" $GetModlog "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/modlog" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search lemmy.
#
# GET /search
export def "search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Search: record
]: nothing -> record<type_: string, comments: table<comment: record, creator: record, post: record, community: record, counts: record, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, creator_blocked: bool, my_vote: int>, posts: table<post: record, creator: record, community: record, image_details: record, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, counts: record, subscribed: string, saved: bool, read: bool, hidden: bool, creator_blocked: bool, my_vote: int, unread_comments: int>, communities: table<community: record, subscribed: string, blocked: bool, counts: record, banned_from_community: bool>, users: table<person: record, counts: record, is_admin: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Search" $Search "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a non-local / federated object.
#
# GET /resolve_object
export def "resolve-object get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ResolveObject: record
]: nothing -> record<comment: record<comment: record<id: int, creator_id: int, post_id: int, content: string, removed: bool, published: string, updated: string, deleted: bool, ap_id: string, local: bool, path: string, distinguished: bool, language_id: int>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, counts: record<comment_id: int, score: int, upvotes: int, downvotes: int, published: string, child_count: int>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, creator_blocked: bool, my_vote: int>, post: record<post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, image_details: record<link: string, width: int, height: int, content_type: string>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, counts: record<post_id: int, comments: int, score: int, upvotes: int, downvotes: int, published: string, newest_comment_time: string>, subscribed: string, saved: bool, read: bool, hidden: bool, creator_blocked: bool, my_vote: int, unread_comments: int>, community: record<community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, subscribed: string, blocked: bool, counts: record<community_id: int, subscribers: int, posts: int, comments: int, published: string, users_active_day: int, users_active_week: int, users_active_month: int, users_active_half_year: int, subscribers_local: int>, banned_from_community: bool>, person: record<person: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, counts: record<person_id: int, post_count: int, comment_count: int>, is_admin: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ResolveObject" $ResolveObject "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/resolve_object" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get / fetch a community.
#
# GET /community
export def "community get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --GetCommunity: record
]: nothing -> record<community_view: record<community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, subscribed: string, blocked: bool, counts: record<community_id: int, subscribers: int, posts: int, comments: int, published: string, users_active_day: int, users_active_week: int, users_active_month: int, users_active_half_year: int, subscribers_local: int>, banned_from_community: bool>, site: record<id: int, name: string, sidebar: string, published: string, updated: string, icon: string, banner: string, description: string, actor_id: string, last_refreshed_at: string, inbox_url: string, public_key: string, instance_id: int, content_warning: string>, moderators: table<community: record, moderator: record>, discussion_languages: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GetCommunity" $GetCommunity "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/community" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new community.
#
# POST /community
export def "community post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  title: string
  --description: string
  --icon: string
  --banner: string
  --nsfw: oneof<nothing, bool>
  --posting-restricted-to-mods: oneof<nothing, bool>
  --discussion-languages: list
  --visibility: string@visibility-completer
]: any -> record<community_view: record<community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, subscribed: string, blocked: bool, counts: record<community_id: int, subscribers: int, posts: int, comments: int, published: string, users_active_day: int, users_active_week: int, users_active_month: int, users_active_half_year: int, subscribers_local: int>, banned_from_community: bool>, discussion_languages: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/community")
  let body = {name: $name, title: $title, description: $description, icon: $icon, banner: $banner, nsfw: $nsfw, posting_restricted_to_mods: $posting_restricted_to_mods, discussion_languages: $discussion_languages, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit a community.
#
# PUT /community
export def "community put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  community_id: int
  --title: string
  --description: string
  --icon: string
  --banner: string
  --nsfw: oneof<nothing, bool>
  --posting-restricted-to-mods: oneof<nothing, bool>
  --discussion-languages: list
  --visibility: string@visibility-completer
]: any -> record<community_view: record<community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, subscribed: string, blocked: bool, counts: record<community_id: int, subscribers: int, posts: int, comments: int, published: string, users_active_day: int, users_active_week: int, users_active_month: int, users_active_half_year: int, subscribers_local: int>, banned_from_community: bool>, discussion_languages: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/community")
  let body = {community_id: $community_id, title: $title, description: $description, icon: $icon, banner: $banner, nsfw: $nsfw, posting_restricted_to_mods: $posting_restricted_to_mods, discussion_languages: $discussion_languages, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Hide a community from public / "All" view. Admins only.
#
# PUT /community/hide
export def "community-hide put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  community_id: int
  --hidden: oneof<nothing, bool>
  --reason: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/community/hide")
  let body = {community_id: $community_id, hidden: $hidden, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List communities, with various filters.
#
# GET /community/list
export def "community-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ListCommunities: record
]: nothing -> record<communities: table<community: record, subscribed: string, blocked: bool, counts: record, banned_from_community: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ListCommunities" $ListCommunities "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/community/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Follow / subscribe to a community.
#
# POST /community/follow
export def "community-follow post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  community_id: int
  --follow: oneof<nothing, bool>
]: any -> record<community_view: record<community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, subscribed: string, blocked: bool, counts: record<community_id: int, subscribers: int, posts: int, comments: int, published: string, users_active_day: int, users_active_week: int, users_active_month: int, users_active_half_year: int, subscribers_local: int>, banned_from_community: bool>, discussion_languages: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/community/follow")
  let body = {community_id: $community_id, follow: $follow} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Block a community.
#
# POST /community/block
export def "community-block post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  community_id: int
  --block: oneof<nothing, bool>
]: any -> record<community_view: record<community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, subscribed: string, blocked: bool, counts: record<community_id: int, subscribers: int, posts: int, comments: int, published: string, users_active_day: int, users_active_week: int, users_active_month: int, users_active_half_year: int, subscribers_local: int>, banned_from_community: bool>, blocked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/community/block")
  let body = {community_id: $community_id, block: $block} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a community.
#
# POST /community/delete
export def "community-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  community_id: int
  --deleted: oneof<nothing, bool>
]: any -> record<community_view: record<community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, subscribed: string, blocked: bool, counts: record<community_id: int, subscribers: int, posts: int, comments: int, published: string, users_active_day: int, users_active_week: int, users_active_month: int, users_active_half_year: int, subscribers_local: int>, banned_from_community: bool>, discussion_languages: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/community/delete")
  let body = {community_id: $community_id, deleted: $deleted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# A moderator remove for a community.
#
# POST /community/remove
export def "community-remove post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  community_id: int
  --removed: oneof<nothing, bool>
  --reason: string
]: any -> record<community_view: record<community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, subscribed: string, blocked: bool, counts: record<community_id: int, subscribers: int, posts: int, comments: int, published: string, users_active_day: int, users_active_week: int, users_active_month: int, users_active_half_year: int, subscribers_local: int>, banned_from_community: bool>, discussion_languages: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/community/remove")
  let body = {community_id: $community_id, removed: $removed, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Transfer your community to an existing moderator.
#
# POST /community/transfer
export def "community-transfer post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  community_id: int
  person_id: int
]: any -> record<community_view: record<community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, subscribed: string, blocked: bool, counts: record<community_id: int, subscribers: int, posts: int, comments: int, published: string, users_active_day: int, users_active_week: int, users_active_month: int, users_active_half_year: int, subscribers_local: int>, banned_from_community: bool>, discussion_languages: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/community/transfer")
  let body = {community_id: $community_id, person_id: $person_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Ban a user from a community.
#
# POST /community/ban_user
export def "community-ban-user post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  community_id: int
  person_id: int
  --ban: oneof<nothing, bool>
  --remove-data: oneof<nothing, bool>
  --reason: string
  --expires: int
]: any -> record<person_view: record<person: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, counts: record<person_id: int, post_count: int, comment_count: int>, is_admin: bool>, banned: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/community/ban_user")
  let body = {community_id: $community_id, person_id: $person_id, ban: $ban, remove_data: $remove_data, reason: $reason, expires: $expires} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a moderator to your community.
#
# POST /community/mod
export def "community-mod post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  community_id: int
  person_id: int
  --added: oneof<nothing, bool>
]: any -> record<moderators: table<community: record, moderator: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/community/mod")
  let body = {community_id: $community_id, person_id: $person_id, added: $added} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch federated instances.
#
# GET /federated_instances
export def "federated-instances get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<federated_instances: record<linked: list<record>, allowed: list<record>, blocked: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/federated_instances")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get / fetch a post.
#
# GET /post
export def "post get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --GetPost: record
]: nothing -> record<post_view: record<post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, image_details: record<link: string, width: int, height: int, content_type: string>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, counts: record<post_id: int, comments: int, score: int, upvotes: int, downvotes: int, published: string, newest_comment_time: string>, subscribed: string, saved: bool, read: bool, hidden: bool, creator_blocked: bool, my_vote: int, unread_comments: int>, community_view: record<community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, subscribed: string, blocked: bool, counts: record<community_id: int, subscribers: int, posts: int, comments: int, published: string, users_active_day: int, users_active_week: int, users_active_month: int, users_active_half_year: int, subscribers_local: int>, banned_from_community: bool>, moderators: table<community: record, moderator: record>, cross_posts: table<post: record, creator: record, community: record, image_details: record, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, counts: record, subscribed: string, saved: bool, read: bool, hidden: bool, creator_blocked: bool, my_vote: int, unread_comments: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GetPost" $GetPost "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/post" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a post.
#
# PUT /post
export def "post put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  post_id: int
  --name: string
  --body-url: string
  --body-body: string
  --alt-text: string
  --nsfw: oneof<nothing, bool>
  --language-id: int
  --custom-thumbnail: string
]: any -> record<post_view: record<post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, image_details: record<link: string, width: int, height: int, content_type: string>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, counts: record<post_id: int, comments: int, score: int, upvotes: int, downvotes: int, published: string, newest_comment_time: string>, subscribed: string, saved: bool, read: bool, hidden: bool, creator_blocked: bool, my_vote: int, unread_comments: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/post")
  let body = {post_id: $post_id, name: $name, url: $body_url, body: $body_body, alt_text: $alt_text, nsfw: $nsfw, language_id: $language_id, custom_thumbnail: $custom_thumbnail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a post.
#
# POST /post
export def "post post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  community_id: int
  --body-url: string
  --body-body: string
  --alt-text: string
  --honeypot: string
  --nsfw: oneof<nothing, bool>
  --language-id: int
  --custom-thumbnail: string
]: any -> record<post_view: record<post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, image_details: record<link: string, width: int, height: int, content_type: string>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, counts: record<post_id: int, comments: int, score: int, upvotes: int, downvotes: int, published: string, newest_comment_time: string>, subscribed: string, saved: bool, read: bool, hidden: bool, creator_blocked: bool, my_vote: int, unread_comments: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/post")
  let body = {name: $name, community_id: $community_id, url: $body_url, body: $body_body, alt_text: $alt_text, honeypot: $honeypot, nsfw: $nsfw, language_id: $language_id, custom_thumbnail: $custom_thumbnail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get / fetch posts, with various filters.
#
# GET /post/list
export def "post-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --GetPosts: record
]: nothing -> record<posts: table<post: record, creator: record, community: record, image_details: record, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, counts: record, subscribed: string, saved: bool, read: bool, hidden: bool, creator_blocked: bool, my_vote: int, unread_comments: int>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GetPosts" $GetPosts "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/post/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a post.
#
# POST /post/delete
export def "post-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  post_id: int
  --deleted: oneof<nothing, bool>
]: any -> record<post_view: record<post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, image_details: record<link: string, width: int, height: int, content_type: string>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, counts: record<post_id: int, comments: int, score: int, upvotes: int, downvotes: int, published: string, newest_comment_time: string>, subscribed: string, saved: bool, read: bool, hidden: bool, creator_blocked: bool, my_vote: int, unread_comments: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/post/delete")
  let body = {post_id: $post_id, deleted: $deleted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# A moderator remove for a post.
#
# POST /post/remove
export def "post-remove post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  post_id: int
  --removed: oneof<nothing, bool>
  --reason: string
]: any -> record<post_view: record<post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, image_details: record<link: string, width: int, height: int, content_type: string>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, counts: record<post_id: int, comments: int, score: int, upvotes: int, downvotes: int, published: string, newest_comment_time: string>, subscribed: string, saved: bool, read: bool, hidden: bool, creator_blocked: bool, my_vote: int, unread_comments: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/post/remove")
  let body = {post_id: $post_id, removed: $removed, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark a post as read.
#
# POST /post/mark_as_read
export def "post-mark-as-read post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  post_ids: list
  --read: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/post/mark_as_read")
  let body = {post_ids: $post_ids, read: $read} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# A moderator can lock a post ( IE disable new comments ).
#
# POST /post/lock
export def "post-lock post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  post_id: int
  --locked: oneof<nothing, bool>
]: any -> record<post_view: record<post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, image_details: record<link: string, width: int, height: int, content_type: string>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, counts: record<post_id: int, comments: int, score: int, upvotes: int, downvotes: int, published: string, newest_comment_time: string>, subscribed: string, saved: bool, read: bool, hidden: bool, creator_blocked: bool, my_vote: int, unread_comments: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/post/lock")
  let body = {post_id: $post_id, locked: $locked} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# A moderator can feature a community post ( IE stick it to the top of a community ).
#
# POST /post/feature
export def "post-feature post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  post_id: int
  --featured: oneof<nothing, bool>
  feature_type: string@feature-type-completer
]: any -> record<post_view: record<post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, image_details: record<link: string, width: int, height: int, content_type: string>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, counts: record<post_id: int, comments: int, score: int, upvotes: int, downvotes: int, published: string, newest_comment_time: string>, subscribed: string, saved: bool, read: bool, hidden: bool, creator_blocked: bool, my_vote: int, unread_comments: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/post/feature")
  let body = {post_id: $post_id, featured: $featured, feature_type: $feature_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Like / vote on a post.
#
# POST /post/like
export def "post-like post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  post_id: int
  score: int
]: any -> record<post_view: record<post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, image_details: record<link: string, width: int, height: int, content_type: string>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, counts: record<post_id: int, comments: int, score: int, upvotes: int, downvotes: int, published: string, newest_comment_time: string>, subscribed: string, saved: bool, read: bool, hidden: bool, creator_blocked: bool, my_vote: int, unread_comments: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/post/like")
  let body = {post_id: $post_id, score: $score} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Save a post.
#
# PUT /post/save
export def "post-save put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  post_id: int
  --body-save: oneof<nothing, bool>
]: any -> record<post_view: record<post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, image_details: record<link: string, width: int, height: int, content_type: string>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, counts: record<post_id: int, comments: int, score: int, upvotes: int, downvotes: int, published: string, newest_comment_time: string>, subscribed: string, saved: bool, read: bool, hidden: bool, creator_blocked: bool, my_vote: int, unread_comments: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/post/save")
  let body = {post_id: $post_id, save: $body_save} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Report a post.
#
# POST /post/report
export def "post-report post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  post_id: int
  reason: string
]: any -> record<post_report_view: record<post_report: record<id: int, creator_id: int, post_id: int, original_post_name: string, original_post_url: string, original_post_body: string, reason: string, resolved: bool, resolver_id: int, published: string, updated: string>, post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, post_creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, creator_banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, read: bool, hidden: bool, creator_blocked: bool, my_vote: int, unread_comments: int, counts: record<post_id: int, comments: int, score: int, upvotes: int, downvotes: int, published: string, newest_comment_time: string>, resolver: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/post/report")
  let body = {post_id: $post_id, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resolve a post report. Only a mod can do this.
#
# PUT /post/report/resolve
export def "post-report-resolve put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  report_id: int
  --resolved: oneof<nothing, bool>
]: any -> record<post_report_view: record<post_report: record<id: int, creator_id: int, post_id: int, original_post_name: string, original_post_url: string, original_post_body: string, reason: string, resolved: bool, resolver_id: int, published: string, updated: string>, post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, post_creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, creator_banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, read: bool, hidden: bool, creator_blocked: bool, my_vote: int, unread_comments: int, counts: record<post_id: int, comments: int, score: int, upvotes: int, downvotes: int, published: string, newest_comment_time: string>, resolver: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/post/report/resolve")
  let body = {report_id: $report_id, resolved: $resolved} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List post reports.
#
# GET /post/report/list
export def "post-report-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ListPostReports: record
]: nothing -> record<post_reports: table<post_report: record, post: record, community: record, creator: record, post_creator: record, creator_banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, read: bool, hidden: bool, creator_blocked: bool, my_vote: int, unread_comments: int, counts: record, resolver: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ListPostReports" $ListPostReports "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/post/report/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch metadata for any given site.
#
# GET /post/site_metadata
export def "post-site-metadata get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --GetSiteMetadata: record
]: nothing -> record<metadata: record<title: string, description: string, image: string, embed_video_url: string, content_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GetSiteMetadata" $GetSiteMetadata "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/post/site_metadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get / fetch comment.
#
# GET /comment
export def "comment get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --GetComment: record
]: nothing -> record<comment_view: record<comment: record<id: int, creator_id: int, post_id: int, content: string, removed: bool, published: string, updated: string, deleted: bool, ap_id: string, local: bool, path: string, distinguished: bool, language_id: int>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, counts: record<comment_id: int, score: int, upvotes: int, downvotes: int, published: string, child_count: int>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, creator_blocked: bool, my_vote: int>, recipient_ids: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GetComment" $GetComment "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/comment" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a comment.
#
# POST /comment
export def "comment post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string
  post_id: int
  --parent-id: int
  --language-id: int
]: any -> record<comment_view: record<comment: record<id: int, creator_id: int, post_id: int, content: string, removed: bool, published: string, updated: string, deleted: bool, ap_id: string, local: bool, path: string, distinguished: bool, language_id: int>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, counts: record<comment_id: int, score: int, upvotes: int, downvotes: int, published: string, child_count: int>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, creator_blocked: bool, my_vote: int>, recipient_ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comment")
  let body = {content: $content, post_id: $post_id, parent_id: $parent_id, language_id: $language_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit a comment.
#
# PUT /comment
export def "comment put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  comment_id: int
  --content: string
  --language-id: int
]: any -> record<comment_view: record<comment: record<id: int, creator_id: int, post_id: int, content: string, removed: bool, published: string, updated: string, deleted: bool, ap_id: string, local: bool, path: string, distinguished: bool, language_id: int>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, counts: record<comment_id: int, score: int, upvotes: int, downvotes: int, published: string, child_count: int>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, creator_blocked: bool, my_vote: int>, recipient_ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comment")
  let body = {comment_id: $comment_id, content: $content, language_id: $language_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get / fetch comments.
#
# GET /comment/list
export def "comment-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --GetComments: record
]: nothing -> record<comments: table<comment: record, creator: record, post: record, community: record, counts: record, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, creator_blocked: bool, my_vote: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GetComments" $GetComments "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/comment/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a comment.
#
# POST /comment/delete
export def "comment-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  comment_id: int
  --deleted: oneof<nothing, bool>
]: any -> record<comment_view: record<comment: record<id: int, creator_id: int, post_id: int, content: string, removed: bool, published: string, updated: string, deleted: bool, ap_id: string, local: bool, path: string, distinguished: bool, language_id: int>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, counts: record<comment_id: int, score: int, upvotes: int, downvotes: int, published: string, child_count: int>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, creator_blocked: bool, my_vote: int>, recipient_ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comment/delete")
  let body = {comment_id: $comment_id, deleted: $deleted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# A moderator remove for a comment.
#
# POST /comment/remove
export def "comment-remove post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  comment_id: int
  --removed: oneof<nothing, bool>
  --reason: string
]: any -> record<comment_view: record<comment: record<id: int, creator_id: int, post_id: int, content: string, removed: bool, published: string, updated: string, deleted: bool, ap_id: string, local: bool, path: string, distinguished: bool, language_id: int>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, counts: record<comment_id: int, score: int, upvotes: int, downvotes: int, published: string, child_count: int>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, creator_blocked: bool, my_vote: int>, recipient_ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comment/remove")
  let body = {comment_id: $comment_id, removed: $removed, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark a comment as read.
#
# POST /comment/mark_as_read
export def "comment-mark-as-read post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  comment_reply_id: int
  --read: oneof<nothing, bool>
]: any -> record<comment_reply_view: record<comment_reply: record<id: int, recipient_id: int, comment_id: int, read: bool, published: string>, comment: record<id: int, creator_id: int, post_id: int, content: string, removed: bool, published: string, updated: string, deleted: bool, ap_id: string, local: bool, path: string, distinguished: bool, language_id: int>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, recipient: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, counts: record<comment_id: int, score: int, upvotes: int, downvotes: int, published: string, child_count: int>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, creator_blocked: bool, my_vote: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comment/mark_as_read")
  let body = {comment_reply_id: $comment_reply_id, read: $read} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Distinguishes a comment (speak as moderator)
#
# POST /comment/distinguish
export def "comment-distinguish post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  comment_id: int
  --distinguished: oneof<nothing, bool>
]: any -> record<comment_view: record<comment: record<id: int, creator_id: int, post_id: int, content: string, removed: bool, published: string, updated: string, deleted: bool, ap_id: string, local: bool, path: string, distinguished: bool, language_id: int>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, counts: record<comment_id: int, score: int, upvotes: int, downvotes: int, published: string, child_count: int>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, creator_blocked: bool, my_vote: int>, recipient_ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comment/distinguish")
  let body = {comment_id: $comment_id, distinguished: $distinguished} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Like / vote on a comment.
#
# POST /comment/like
export def "comment-like post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  comment_id: int
  score: int
]: any -> record<comment_view: record<comment: record<id: int, creator_id: int, post_id: int, content: string, removed: bool, published: string, updated: string, deleted: bool, ap_id: string, local: bool, path: string, distinguished: bool, language_id: int>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, counts: record<comment_id: int, score: int, upvotes: int, downvotes: int, published: string, child_count: int>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, creator_blocked: bool, my_vote: int>, recipient_ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comment/like")
  let body = {comment_id: $comment_id, score: $score} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Save a comment.
#
# PUT /comment/save
export def "comment-save put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  comment_id: int
  --body-save: oneof<nothing, bool>
]: any -> record<comment_view: record<comment: record<id: int, creator_id: int, post_id: int, content: string, removed: bool, published: string, updated: string, deleted: bool, ap_id: string, local: bool, path: string, distinguished: bool, language_id: int>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, counts: record<comment_id: int, score: int, upvotes: int, downvotes: int, published: string, child_count: int>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, creator_blocked: bool, my_vote: int>, recipient_ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comment/save")
  let body = {comment_id: $comment_id, save: $body_save} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Report a comment.
#
# POST /comment/report
export def "comment-report post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  comment_id: int
  reason: string
]: any -> record<comment_report_view: record<comment_report: record<id: int, creator_id: int, comment_id: int, original_comment_text: string, reason: string, resolved: bool, resolver_id: int, published: string, updated: string>, comment: record<id: int, creator_id: int, post_id: int, content: string, removed: bool, published: string, updated: string, deleted: bool, ap_id: string, local: bool, path: string, distinguished: bool, language_id: int>, post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, comment_creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, counts: record<comment_id: int, score: int, upvotes: int, downvotes: int, published: string, child_count: int>, creator_banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, creator_blocked: bool, subscribed: string, saved: bool, my_vote: int, resolver: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comment/report")
  let body = {comment_id: $comment_id, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resolve a comment report. Only a mod can do this.
#
# PUT /comment/report/resolve
export def "comment-report-resolve put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  report_id: int
  --resolved: oneof<nothing, bool>
]: any -> record<comment_report_view: record<comment_report: record<id: int, creator_id: int, comment_id: int, original_comment_text: string, reason: string, resolved: bool, resolver_id: int, published: string, updated: string>, comment: record<id: int, creator_id: int, post_id: int, content: string, removed: bool, published: string, updated: string, deleted: bool, ap_id: string, local: bool, path: string, distinguished: bool, language_id: int>, post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, comment_creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, counts: record<comment_id: int, score: int, upvotes: int, downvotes: int, published: string, child_count: int>, creator_banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, creator_blocked: bool, subscribed: string, saved: bool, my_vote: int, resolver: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comment/report/resolve")
  let body = {report_id: $report_id, resolved: $resolved} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List comment reports.
#
# GET /comment/report/list
export def "comment-report-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ListCommentReports: record
]: nothing -> record<comment_reports: table<comment_report: record, comment: record, post: record, community: record, creator: record, comment_creator: record, counts: record, creator_banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, creator_blocked: bool, subscribed: string, saved: bool, my_vote: int, resolver: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ListCommentReports" $ListCommentReports "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/comment/report/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a private message.
#
# PUT /private_message
export def "private-message put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  private_message_id: int
  content: string
]: any -> record<private_message_view: record<private_message: record<id: int, creator_id: int, recipient_id: int, content: string, deleted: bool, read: bool, published: string, updated: string, ap_id: string, local: bool>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, recipient: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/private_message")
  let body = {private_message_id: $private_message_id, content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a private message.
#
# POST /private_message
export def "private-message post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string
  recipient_id: int
]: any -> record<private_message_view: record<private_message: record<id: int, creator_id: int, recipient_id: int, content: string, deleted: bool, read: bool, published: string, updated: string, ap_id: string, local: bool>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, recipient: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/private_message")
  let body = {content: $content, recipient_id: $recipient_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get / fetch private messages.
#
# GET /private_message/list
export def "private-message-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --GetPrivateMessages: record
]: nothing -> record<private_messages: table<private_message: record, creator: record, recipient: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GetPrivateMessages" $GetPrivateMessages "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/private_message/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a private message.
#
# POST /private_message/delete
export def "private-message-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  private_message_id: int
  --deleted: oneof<nothing, bool>
]: any -> record<private_message_view: record<private_message: record<id: int, creator_id: int, recipient_id: int, content: string, deleted: bool, read: bool, published: string, updated: string, ap_id: string, local: bool>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, recipient: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/private_message/delete")
  let body = {private_message_id: $private_message_id, deleted: $deleted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark a private message as read.
#
# POST /private_message/mark_as_read
export def "private-message-mark-as-read post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  private_message_id: int
  --read: oneof<nothing, bool>
]: any -> record<private_message_view: record<private_message: record<id: int, creator_id: int, recipient_id: int, content: string, deleted: bool, read: bool, published: string, updated: string, ap_id: string, local: bool>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, recipient: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/private_message/mark_as_read")
  let body = {private_message_id: $private_message_id, read: $read} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a report for a private message.
#
# POST /private_message/report
export def "private-message-report post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  private_message_id: int
  reason: string
]: any -> record<private_message_report_view: record<private_message_report: record<id: int, creator_id: int, private_message_id: int, original_pm_text: string, reason: string, resolved: bool, resolver_id: int, published: string, updated: string>, private_message: record<id: int, creator_id: int, recipient_id: int, content: string, deleted: bool, read: bool, published: string, updated: string, ap_id: string, local: bool>, private_message_creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, resolver: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/private_message/report")
  let body = {private_message_id: $private_message_id, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resolve a report for a private message.
#
# PUT /private_message/report/resolve
export def "private-message-report-resolve put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  report_id: int
  --resolved: oneof<nothing, bool>
]: any -> record<private_message_report_view: record<private_message_report: record<id: int, creator_id: int, private_message_id: int, original_pm_text: string, reason: string, resolved: bool, resolver_id: int, published: string, updated: string>, private_message: record<id: int, creator_id: int, recipient_id: int, content: string, deleted: bool, read: bool, published: string, updated: string, ap_id: string, local: bool>, private_message_creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, resolver: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/private_message/report/resolve")
  let body = {report_id: $report_id, resolved: $resolved} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List private message reports.
#
# GET /private_message/report/list
export def "private-message-report-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ListPrivateMessageReports: record
]: nothing -> record<private_message_reports: table<private_message_report: record, private_message: record, private_message_creator: record, creator: record, resolver: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ListPrivateMessageReports" $ListPrivateMessageReports "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/private_message/report/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details for a person.
#
# GET /user
export def "user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --GetPersonDetails: record
]: nothing -> record<person_view: record<person: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, counts: record<person_id: int, post_count: int, comment_count: int>, is_admin: bool>, site: record<id: int, name: string, sidebar: string, published: string, updated: string, icon: string, banner: string, description: string, actor_id: string, last_refreshed_at: string, inbox_url: string, public_key: string, instance_id: int, content_warning: string>, comments: table<comment: record, creator: record, post: record, community: record, counts: record, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, creator_blocked: bool, my_vote: int>, posts: table<post: record, creator: record, community: record, image_details: record, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, counts: record, subscribed: string, saved: bool, read: bool, hidden: bool, creator_blocked: bool, my_vote: int, unread_comments: int>, moderates: table<community: record, moderator: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GetPersonDetails" $GetPersonDetails "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Register a new user.
#
# POST /user/register
export def "user-register post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username: string
  password: string
  password_verify: string
  --show-nsfw: oneof<nothing, bool>
  --email: string
  --captcha-uuid: string
  --captcha-answer: string
  --honeypot: string
  --answer: string
]: any -> record<jwt: string, registration_created: bool, verify_email_sent: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/register")
  let body = {username: $username, password: $password, password_verify: $password_verify, show_nsfw: $show_nsfw, email: $email, captcha_uuid: $captcha_uuid, captcha_answer: $captcha_answer, honeypot: $honeypot, answer: $answer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a Captcha.
#
# GET /user/get_captcha
export def "user-get-captcha get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ok: record<png: string, wav: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/get_captcha")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get mentions for your user.
#
# GET /user/mention
export def "user-mention get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --GetPersonMentions: record
]: nothing -> record<mentions: table<person_mention: record, comment: record, creator: record, post: record, community: record, recipient: record, counts: record, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, creator_blocked: bool, my_vote: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GetPersonMentions" $GetPersonMentions "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/user/mention" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark a person mention as read.
#
# POST /user/mention/mark_as_read
export def "user-mention-mark-as-read post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  person_mention_id: int
  --read: oneof<nothing, bool>
]: any -> record<person_mention_view: record<person_mention: record<id: int, recipient_id: int, comment_id: int, read: bool, published: string>, comment: record<id: int, creator_id: int, post_id: int, content: string, removed: bool, published: string, updated: string, deleted: bool, ap_id: string, local: bool, path: string, distinguished: bool, language_id: int>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, post: record<id: int, name: string, url: string, body: string, creator_id: int, community_id: int, removed: bool, locked: bool, published: string, updated: string, deleted: bool, nsfw: bool, embed_title: string, embed_description: string, thumbnail_url: string, ap_id: string, local: bool, embed_video_url: string, language_id: int, featured_community: bool, featured_local: bool, url_content_type: string, alt_text: string>, community: record<id: int, name: string, title: string, description: string, removed: bool, published: string, updated: string, deleted: bool, nsfw: bool, actor_id: string, local: bool, icon: string, banner: string, hidden: bool, posting_restricted_to_mods: bool, instance_id: int, visibility: string>, recipient: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, counts: record<comment_id: int, score: int, upvotes: int, downvotes: int, published: string, child_count: int>, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, creator_blocked: bool, my_vote: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/mention/mark_as_read")
  let body = {person_mention_id: $person_mention_id, read: $read} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get comment replies.
#
# GET /user/replies
export def "user-replies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --GetReplies: record
]: nothing -> record<replies: table<comment_reply: record, comment: record, creator: record, post: record, community: record, recipient: record, counts: record, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, creator_blocked: bool, my_vote: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GetReplies" $GetReplies "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/user/replies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ban a person from your site.
#
# POST /user/ban
export def "user-ban post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  person_id: int
  --ban: oneof<nothing, bool>
  --remove-data: oneof<nothing, bool>
  --reason: string
  --expires: int
]: any -> record<person_view: record<person: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, counts: record<person_id: int, post_count: int, comment_count: int>, is_admin: bool>, banned: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/ban")
  let body = {person_id: $person_id, ban: $ban, remove_data: $remove_data, reason: $reason, expires: $expires} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of banned users
#
# GET /user/banned
# operationId: getBannedPersons
export def "user-banned get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<banned: table<person: record, counts: record, is_admin: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/banned")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Block a person.
#
# POST /user/block
export def "user-block post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  person_id: int
  --block: oneof<nothing, bool>
]: any -> record<person_view: record<person: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, counts: record<person_id: int, post_count: int, comment_count: int>, is_admin: bool>, blocked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/block")
  let body = {person_id: $person_id, block: $block} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Log into lemmy.
#
# POST /user/login
export def "user-login post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username_or_email: string
  password: string
  --totp-2fa-token: string
]: any -> record<jwt: string, registration_created: bool, verify_email_sent: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/login")
  let body = {username_or_email: $username_or_email, password: $password, totp_2fa_token: $totp_2fa_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete your account.
#
# POST /user/delete_account
export def "user-delete-account post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  password: string
  --delete-content: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/delete_account")
  let body = {password: $password, delete_content: $delete_content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset your password.
#
# POST /user/password_reset
# operationId: resetPassword
export def "user-password-reset resetPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/password_reset")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change your password from an email / token based reset.
#
# POST /user/password_change
# operationId: changePasswordAfterReset
export def "user-password-change changePasswordAfterReset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string
  password: string
  password_verify: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/password_change")
  let body = {token: $body_token, password: $password, password_verify: $password_verify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark all replies as read.
#
# POST /user/mark_all_as_read
# operationId: markAllAsRead
export def "user-mark-all-as-read markAllAsRead" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<replies: table<comment_reply: record, comment: record, creator: record, post: record, community: record, recipient: record, counts: record, creator_banned_from_community: bool, banned_from_community: bool, creator_is_moderator: bool, creator_is_admin: bool, subscribed: string, saved: bool, creator_blocked: bool, my_vote: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/mark_all_as_read")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Save your user settings.
#
# PUT /user/save_user_settings
export def "user-save-user-settings put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-nsfw: oneof<nothing, bool>
  --blur-nsfw: oneof<nothing, bool>
  --auto-expand: oneof<nothing, bool>
  --theme: string
  --default-sort-type: string@default-sort-type-completer
  --default-listing-type: string@default-listing-type-completer
  --interface-language: string
  --avatar: string
  --banner: string
  --display-name: string
  --email: string
  --bio: string
  --matrix-user-id: string
  --show-avatars: oneof<nothing, bool>
  --send-notifications-to-email: oneof<nothing, bool>
  --bot-account: oneof<nothing, bool>
  --show-bot-accounts: oneof<nothing, bool>
  --show-read-posts: oneof<nothing, bool>
  --discussion-languages: list
  --open-links-in-new-tab: oneof<nothing, bool>
  --infinite-scroll-enabled: oneof<nothing, bool>
  --post-listing-mode: string@post-listing-mode-completer
  --enable-keyboard-navigation: oneof<nothing, bool>
  --enable-animated-images: oneof<nothing, bool>
  --collapse-bot-comments: oneof<nothing, bool>
  --show-scores: oneof<nothing, bool>
  --show-upvotes: oneof<nothing, bool>
  --show-downvotes: oneof<nothing, bool>
  --show-upvote-percentage: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/save_user_settings")
  let body = {show_nsfw: $show_nsfw, blur_nsfw: $blur_nsfw, auto_expand: $auto_expand, theme: $theme, default_sort_type: $default_sort_type, default_listing_type: $default_listing_type, interface_language: $interface_language, avatar: $avatar, banner: $banner, display_name: $display_name, email: $email, bio: $bio, matrix_user_id: $matrix_user_id, show_avatars: $show_avatars, send_notifications_to_email: $send_notifications_to_email, bot_account: $bot_account, show_bot_accounts: $show_bot_accounts, show_read_posts: $show_read_posts, discussion_languages: $discussion_languages, open_links_in_new_tab: $open_links_in_new_tab, infinite_scroll_enabled: $infinite_scroll_enabled, post_listing_mode: $post_listing_mode, enable_keyboard_navigation: $enable_keyboard_navigation, enable_animated_images: $enable_animated_images, collapse_bot_comments: $collapse_bot_comments, show_scores: $show_scores, show_upvotes: $show_upvotes, show_downvotes: $show_downvotes, show_upvote_percentage: $show_upvote_percentage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change your user password.
#
# PUT /user/change_password
# operationId: changePassword
export def "user-change-password changePassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  new_password: string
  new_password_verify: string
  old_password: string
]: any -> record<jwt: string, registration_created: bool, verify_email_sent: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/change_password")
  let body = {new_password: $new_password, new_password_verify: $new_password_verify, old_password: $old_password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get counts for your reports
#
# GET /user/report_count
export def "user-report-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --GetReportCount: record
]: nothing -> record<community_id: int, comment_reports: int, post_reports: int, private_message_reports: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GetReportCount" $GetReportCount "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/user/report_count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get your unread counts
#
# GET /user/unread_count
export def "user-unread-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<replies: int, mentions: int, private_messages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/unread_count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify your email
#
# POST /user/verify_email
export def "user-verify-email post" [
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
  let full_url = (build-url $base "/user/verify_email")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Leave the Site admins.
#
# POST /user/leave_admin
# operationId: leaveAdmin
export def "user-leave-admin leaveAdmin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<site_view: record<site: record<id: int, name: string, sidebar: string, published: string, updated: string, icon: string, banner: string, description: string, actor_id: string, last_refreshed_at: string, inbox_url: string, public_key: string, instance_id: int, content_warning: string>, local_site: record<id: int, site_id: int, site_setup: bool, enable_downvotes: bool, enable_nsfw: bool, community_creation_admin_only: bool, require_email_verification: bool, application_question: string, private_instance: bool, default_theme: string, default_post_listing_type: string, legal_information: string, hide_modlog_mod_names: bool, application_email_admins: bool, slur_filter_regex: string, actor_name_max_length: int, federation_enabled: bool, captcha_enabled: bool, captcha_difficulty: string, published: string, updated: string, registration_mode: string, reports_email_admins: bool, federation_signed_fetch: bool, default_post_listing_mode: string, default_sort_type: string>, local_site_rate_limit: record<local_site_id: int, message: int, message_per_second: int, post: int, post_per_second: int, register: int, register_per_second: int, image: int, image_per_second: int, comment: int, comment_per_second: int, search: int, search_per_second: int, published: string, updated: string, import_user_settings: int, import_user_settings_per_second: int>, counts: record<site_id: int, users: int, posts: int, comments: int, communities: int, users_active_day: int, users_active_week: int, users_active_month: int, users_active_half_year: int>>, admins: table<person: record, counts: record, is_admin: bool>, version: string, my_user: record<local_user_view: record<local_user: record, local_user_vote_display_mode: record, person: record, counts: record>, follows: list<record>, moderates: list<record>, community_blocks: list<record>, instance_blocks: list<record>, person_blocks: list<record>, discussion_languages: list<int>>, all_languages: table<id: int, code: string, name: string>, discussion_languages: list<int>, taglines: table<id: int, local_site_id: int, content: string, published: string, updated: string>, custom_emojis: table<custom_emoji: record, keywords: list>, blocked_urls: table<id: int, url: string, published: string, updated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/leave_admin")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark donation dialog as shown.
#
# POST /user/donation_dialog_shown
# operationId: markDonationDialogShown
export def "user-donation-dialog-shown markDonationDialogShown" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/donation_dialog_shown")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an admin to your site.
#
# POST /admin/add
export def "admin-add post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  person_id: int
  --added: oneof<nothing, bool>
]: any -> record<admins: table<person: record, counts: record, is_admin: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/add")
  let body = {person_id: $person_id, added: $added} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the unread registration applications count.
#
# GET /admin/registration_application/count
export def "admin-registration-application-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<registration_applications: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/registration_application/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the registration applications.
#
# GET /admin/registration_application/list
export def "admin-registration-application-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ListRegistrationApplications: record
]: nothing -> record<registration_applications: table<registration_application: record, creator_local_user: record, creator: record, admin: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ListRegistrationApplications" $ListRegistrationApplications "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/registration_application/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Approve a registration application
#
# PUT /admin/registration_application/approve
export def "admin-registration-application-approve put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: int
  --approve: oneof<nothing, bool>
  --deny-reason: string
]: any -> record<registration_application: record<registration_application: record<id: int, local_user_id: int, answer: string, admin_id: int, deny_reason: string, published: string>, creator_local_user: record<id: int, person_id: int, email: string, show_nsfw: bool, theme: string, default_sort_type: string, default_listing_type: string, interface_language: string, show_avatars: bool, send_notifications_to_email: bool, show_scores: bool, show_bot_accounts: bool, show_read_posts: bool, email_verified: bool, accepted_application: bool, open_links_in_new_tab: bool, blur_nsfw: bool, auto_expand: bool, infinite_scroll_enabled: bool, admin: bool, post_listing_mode: string, totp_2fa_enabled: bool, enable_keyboard_navigation: bool, enable_animated_images: bool, collapse_bot_comments: bool, last_donation_notification: string>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, admin: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/registration_application/approve")
  let body = {id: $id, approve: $approve, deny_reason: $deny_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Purge / Delete a person from the database.
#
# POST /admin/purge/person
export def "admin-purge-person post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  person_id: int
  --reason: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/purge/person")
  let body = {person_id: $person_id, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Purge / Delete a community from the database.
#
# POST /admin/purge/community
export def "admin-purge-community post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  community_id: int
  --reason: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/purge/community")
  let body = {community_id: $community_id, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Purge / Delete a post from the database.
#
# POST /admin/purge/post
export def "admin-purge-post post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  post_id: int
  --reason: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/purge/post")
  let body = {post_id: $post_id, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Purge / Delete a comment from the database.
#
# POST /admin/purge/comment
export def "admin-purge-comment post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  comment_id: int
  --reason: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/purge/comment")
  let body = {comment_id: $comment_id, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit an existing custom emoji
#
# PUT /custom_emoji
export def "custom-emoji put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: int
  category: string
  image_url: string
  alt_text: string
  keywords: list
]: any -> record<custom_emoji: record<custom_emoji: record<id: int, local_site_id: int, shortcode: string, image_url: string, alt_text: string, category: string, published: string, updated: string>, keywords: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_emoji")
  let body = {id: $id, category: $category, image_url: $image_url, alt_text: $alt_text, keywords: $keywords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new custom emoji
#
# POST /custom_emoji
export def "custom-emoji post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  category: string
  shortcode: string
  image_url: string
  alt_text: string
  keywords: list
]: any -> record<custom_emoji: record<custom_emoji: record<id: int, local_site_id: int, shortcode: string, image_url: string, alt_text: string, category: string, published: string, updated: string>, keywords: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_emoji")
  let body = {category: $category, shortcode: $shortcode, image_url: $image_url, alt_text: $alt_text, keywords: $keywords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a custom emoji
#
# POST /custom_emoji/delete
export def "custom-emoji-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_emoji/delete")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Block an instance.
#
# POST /site/block
export def "site-block post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  instance_id: int
  --block: oneof<nothing, bool>
]: any -> record<blocked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/site/block")
  let body = {instance_id: $instance_id, block: $block} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a TOTP / two-factor secret. Afterwards you need to call `/user/totp/update` with a valid token to enable it.
#
# POST /user/totp/generate
export def "user-totp-generate post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<totp_secret_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/totp/generate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable / Disable TOTP / two-factor authentication. To enable, you need to first call `/user/totp/generate` and then pass a valid token to this. Disabling is only possible if 2FA was previously enabled. Again it is necessary to pass a valid token.
#
# POST /user/totp/update
export def "user-totp-update post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  totp_token: string
  --enabled: oneof<nothing, bool>
]: any -> record<enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/totp/update")
  let body = {totp_token: $totp_token, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export a backup of your user settings, including your saved content, followed communities, and blocks.
#
# GET /user/export_settings
export def "user-export-settings get" [
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
  let full_url = (build-url $base "/user/export_settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import a backup of your user settings.
#
# POST /user/import_settings
export def "user-import-settings post" [
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
  let full_url = (build-url $base "/user/import_settings")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List login tokens for your user
#
# GET /user/list_logins
# operationId: listLogins
export def "user-list-logins listLogins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<user_id: int, published: string, ip: string, user_agent: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/list_logins")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns an error message if your auth token is invalid
#
# GET /user/validate_auth
# operationId: validateAuth
export def "user-validate-auth validateAuth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/validate_auth")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invalidate the currently used auth token.
#
# POST /user/logout
# operationId: logout
export def "user-logout logout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a post's likes. Admin-only.
#
# GET /post/like/list
export def "post-like-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  post_id: int
  --page: int
  --limit: int
]: any -> record<post_likes: table<creator: record, creator_banned_from_community: bool, score: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/post/like/list")
  let body = {post_id: $post_id, page: $page, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a comment's likes. Admin-only.
#
# GET /comment/like/list
export def "comment-like-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  comment_id: int
  --page: int
  --limit: int
]: any -> record<comment_likes: table<creator: record, creator_banned_from_community: bool, score: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comment/like/list")
  let body = {comment_id: $comment_id, page: $page, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all the media for your user
#
# GET /account/list_media
export def "account-list-media get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int
  --limit: int
]: any -> record<images: table<local_image: record, person: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/list_media")
  let body = {page: $page, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all the media known to your instance.
#
# GET /admin/list_all_media
# operationId: listAllMedia
export def "admin-list-all-media listAllMedia" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int
  --limit: int
]: any -> record<images: table<local_image: record, person: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/list_all_media")
  let body = {page: $page, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Hide a post from list views.
#
# POST /post/hide
export def "post-hide post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  post_ids: list
  --hide: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/post/hide")
  let body = {post_ids: $post_ids, hide: $hide} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the application a user submitted when they first registered their account
#
# GET /admin/registration_application
export def "admin-registration-application get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  person_id: int
]: any -> record<registration_application: record<registration_application: record<id: int, local_user_id: int, answer: string, admin_id: int, deny_reason: string, published: string>, creator_local_user: record<id: int, person_id: int, email: string, show_nsfw: bool, theme: string, default_sort_type: string, default_listing_type: string, interface_language: string, show_avatars: bool, send_notifications_to_email: bool, show_scores: bool, show_bot_accounts: bool, show_read_posts: bool, email_verified: bool, accepted_application: bool, open_links_in_new_tab: bool, blur_nsfw: bool, auto_expand: bool, infinite_scroll_enabled: bool, admin: bool, post_listing_mode: string, totp_2fa_enabled: bool, enable_keyboard_navigation: bool, enable_animated_images: bool, collapse_bot_comments: bool, last_donation_notification: string>, creator: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>, admin: record<id: int, name: string, display_name: string, avatar: string, banned: bool, published: string, updated: string, actor_id: string, bio: string, local: bool, banner: string, deleted: bool, matrix_user_id: string, bot_account: bool, ban_expires: string, instance_id: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/registration_application")
  let body = {person_id: $person_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
