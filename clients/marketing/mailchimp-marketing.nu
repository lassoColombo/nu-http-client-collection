# Auto-generated client for Mailchimp Marketing API v3.0.91
# Source: https://api.mailchimp.com/schema/3.0/Swagger.json?expand
# Auth: --token flag or $env.MAILCHIMP_MARKETING_API_TOKEN

const BASE_URL = "https://server.api.mailchimp.com/3.0"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MAILCHIMP_MARKETING_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://server.api.mailchimp.com/3.0"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/problem+json"] }
def sort-field-completer [] { ["created_at" "updated_at"] }
def sort-dir-completer [] { ["ASC" "DESC"] }
def merge-field-validation-mode-completer [] { ["ignore_required_checks" "strict"] }
def data-mode-completer [] { ["historical" "live"] }
def status-completer [] { ["paused" "save" "sending"] }
def type-completer [] { ["absplit" "plaintext" "regular" "rss" "variate"] }
def status-completer-1 [] { ["paused" "save" "schedule" "sending" "sent"] }
def sort-field-completer-1 [] { ["create_time" "send_time"] }
def content-type-completer [] { ["multichannel" "template"] }
def send-type-completer [] { ["html" "plaintext"] }
def shortcut-type-completer [] { ["to_new_subscribers" "to_non_clickers" "to_non_openers" "to_non_purchasers"] }
def has-unread-messages-completer [] { ["false" "true"] }
def is-read-completer [] { ["false" "true"] }
def sort-field-completer-2 [] { ["added_date" "name" "size"] }
def sort-field-completer-3 [] { ["date_created"] }
def sort-field-completer-4 [] { ["month"] }
def sort-field-completer-5 [] { ["display_order" "name"] }
def type-completer-1 [] { ["checkboxes" "dropdown" "hidden" "radio"] }
def exclude-type-completer [] { ["fuzzy" "saved" "static"] }
def status-completer-2 [] { ["archived" "cleaned" "pending" "subscribed" "transactional" "unsubscribed"] }
def interest-match-completer [] { ["all" "any" "none"] }
def sort-field-completer-6 [] { ["last_changed" "timestamp_opt" "timestamp_signup"] }
def status-completer-3 [] { ["cleaned" "pending" "subscribed" "transactional" "unsubscribed"] }
def status-if-new-completer [] { ["cleaned" "pending" "subscribed" "transactional" "unsubscribed"] }
def status-completer-4 [] { ["cleaned" "pending" "subscribed" "unsubscribed"] }
def sort-field-completer-7 [] { ["created_at" "note_id" "updated_at"] }
def type-completer-2 [] { ["address" "birthday" "date" "dropdown" "imageurl" "number" "phone" "radio" "text" "url" "zip"] }
def type-completer-3 [] { ["product" "signup"] }
def sort-field-completer-8 [] { ["total_clicks" "unique_clicks"] }
def sort-field-completer-9 [] { ["opens_count"] }
def sort-field-completer-10 [] { ["title" "total_purchased" "total_revenue"] }
def sort-field-completer-11 [] { ["date_created" "date_edited" "name"] }
def content-type-completer-1 [] { ["html" "multichannel" "template"] }
def type-completer-4 [] { ["fixed" "percentage"] }
def target-completer [] { ["per_item" "shipping" "total"] }
def tracking-code-completer [] { ["prec"] }
def sort-field-completer-12 [] { ["created_at" "end_time" "updated_at"] }
def respondent-familiarity-is-completer [] { ["known" "new" "unknown"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "root get" } } | get name | first)
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

# List api root resources
#
# GET /
# operationId: getRoot
export def "root get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<account_id: string, login_id: string, account_name: string, email: string, first_name: string, last_name: string, username: string, avatar_url: string, role: string, member_since: string, pricing_plan_type: string, first_payment: string, account_timezone: string, account_industry: string, contact: record<company: string, addr1: string, addr2: string, city: string, state: string, zip: string, country: string>, pro_enabled: bool, last_login: string, total_subscribers: int, industry_stats: record<open_rate: float, bounce_rate: float, click_rate: float>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get latest chimp chatter
#
# GET /activity-feed/chimp-chatter
# operationId: getActivityFeedChimpChatter
export def "activity-feed-chimp-chatter get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<chimp_chatter: table<title: string, message: string, type: string, update_time: string, url: string, list_id: string, campaign_id: string>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity-feed/chimp-chatter" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List account exports
#
# GET /account-exports
# operationId: getAccountExports
export def "account-exports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<exports: table<export_id: int, started: string, finished: string, size_in_bytes: int, download_url: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account-exports" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add export
#
# POST /account-exports
# operationId: postAccountExport
export def "account-exports post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  include_stages: list # The stages of an account export to include. (e.g. ["audiences", "gallery_files"])
  --since-timestamp: string # An ISO 8601 date that will limit the export to only records created after a given time. For instance, the reports stage will contain any campaign sent after the given timestamp. Audiences, however, are excluded from this limit. (format: date-time, e.g. 2021-08-23T14:15:09Z)
]: any -> record<export_id: int, started: string, finished: string, size_in_bytes: int, download_url: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account-exports")
  let body = {include_stages: $include_stages, since_timestamp: $since_timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get account export info
#
# GET /account-exports/{export_id}
# operationId: getAccountExportId
export def "account-exports get" [
  export_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<export_id: int, started: string, finished: string, size_in_bytes: int, download_url: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/account-exports/($export_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of audiences
#
# GET /audiences
# operationId: getAudienceContacts
export def "audiences list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<audiences: table<id: string, name: string, stats: record, enabled_channels: list>, total_items: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/audiences" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get audience info
#
# GET /audiences/{audience_id}
# operationId: getAudienceId
export def "audiences get" [
  audience_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, name: string, stats: record<total_contacts: int>, enabled_channels: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/audiences/($audience_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Contacts
#
# GET /audiences/{audience_id}/contacts
# operationId: getAudienceContactList
export def "audiences-contacts list" [
  audience_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --cursor: string # Paginate through a collection of records by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request. Default value fetches the first "page" of results.
  --created-before: string # Restricts the response to contacts created at or before the specified time (inclusive). Uses ISO 8601 format: 2025-04-23T15:41:36+00:00. (format: date-time)
  --created-since: string # Restricts the response to contacts created after the specified time (exclusive). Uses ISO 8601 format: 2025-04-23T15:41:36+00:00. (format: date-time)
  --updated-before: string # Restricts the response to contacts updated at or before the specified time (inclusive). Uses ISO 8601 format: 2025-04-23T15:41:36+00:00. (format: date-time)
  --updated-since: string # Restricts the response to contacts updated after the specified time (exclusive). Uses ISO 8601 format: 2025-04-23T15:41:36+00:00. (format: date-time)
  --sort-field: string@sort-field-completer # Specifies the field to sort the returned contacts by.
  --sort-dir: string@sort-dir-completer # Determines the order direction for sorted results.
]: nothing -> record<contacts: table<id: string, audience_id: string, language: string, status: string, email_channel: record, sms_channel: record, merge_fields: record, tags: list, source: record, created_at: string, last_updated_at: string>, next_cursor: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "created_before" $created_before "scalar") (serialize-qp "created_since" $created_since "scalar") (serialize-qp "updated_before" $updated_before "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_dir" $sort_dir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/audiences/($audience_id)/contacts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Contact
#
# POST /audiences/{audience_id}/contacts
# operationId: createAudienceContact
# --email_channel shape: {email?: string, marketing_consent?: record}
# --sms_channel shape: {sms_phone?: string, marketing_consent?: record}
export def "audiences-contacts createAudienceContact" [
  audience_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --merge-field-validation-mode: string@merge-field-validation-mode-completer # Defines how merge field validation is handled. When set to `ignore_required_checks`, the API does not raise an error if required merge fields are missing from the request. When set to `strict`, the API enforces validation and returns an error if any required merge field is not provided. If this setting is omitted, `strict` is applied by default.
  --data-mode: string@data-mode-completer # Indicates the data processing mode. In `historical` mode, contact data changes do not trigger automations or webhooks. In `live mode`, such changes do trigger them.
  --language: string # The subscribers detected language. (e.g. EN)
  --email-channel: record # shape: {email?: string, marketing_consent?: record}
  --sms-channel: record # shape: {sms_phone?: string, marketing_consent?: record}
  --merge-fields: record # A dictionary of merge fields where the keys are the merge tags. See the [Merge Fields documentation](https://mailchimp.com/developer/marketing/docs/merge-fields/#structure) for more about the structure.
  --tags: list # An array of tag names to add to the contact. This operation is append-only; existing tags will be preserved, and only new tags from this array will be added. (e.g. [new_tag, another_tag])
  --update-existing: oneof<nothing, bool> # If a contact already exists, update them instead of returning a conflict error. When `true` and a matching contact is found (by email or phone), the existing contact is updated with the provided channel data. Defaults to `false`. (e.g. true)
]: any -> record<id: string, audience_id: string, language: string, status: string, email_channel: record<email: string, hashed_email: string, effective_subscription_status: record<value: string>, marketing_consent: record<status: string, captured_at: string, source: record>, source: record<name: string>>, sms_channel: record<sms_phone: string, hashed_sms_phone: string, effective_subscription_status: record<value: string>, marketing_consent: record<status: string, captured_at: string, source: record>, source: record<name: string>>, merge_fields: record, tags: list<string>, source: record<name: string>, created_at: string, last_updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "merge_field_validation_mode" $merge_field_validation_mode "scalar") (serialize-qp "data_mode" $data_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/audiences/($audience_id)/contacts" $qp)
  let body = {language: $language, email_channel: $email_channel, sms_channel: $sms_channel, merge_fields: $merge_fields, tags: $tags, update_existing: $update_existing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Contact
#
# GET /audiences/{audience_id}/contacts/{contact_id}
# operationId: getAudienceContact
export def "audiences-contacts get" [
  audience_id: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, audience_id: string, language: string, status: string, email_channel: record<email: string, hashed_email: string, effective_subscription_status: record<value: string>, marketing_consent: record<status: string, captured_at: string, source: record>, source: record<name: string>>, sms_channel: record<sms_phone: string, hashed_sms_phone: string, effective_subscription_status: record<value: string>, marketing_consent: record<status: string, captured_at: string, source: record>, source: record<name: string>>, merge_fields: record, tags: list<string>, source: record<name: string>, created_at: string, last_updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/audiences/($audience_id)/contacts/($contact_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Contact
#
# PATCH /audiences/{audience_id}/contacts/{contact_id}
# operationId: patchAudienceContact
# --email_channel shape: {email?: string, marketing_consent?: record}
# --sms_channel shape: {sms_phone?: string, marketing_consent?: record}
export def "audiences-contacts patch" [
  audience_id: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --merge-field-validation-mode: string@merge-field-validation-mode-completer # Defines how merge field validation is handled. When set to `ignore_required_checks`, the API does not raise an error if required merge fields are missing from the request. When set to `strict`, the API enforces validation and returns an error if any required merge field is not provided. If this setting is omitted, `strict` is applied by default.
  --data-mode: string@data-mode-completer # Indicates the data processing mode. In `historical` mode, contact data changes do not trigger automations or webhooks. In `live mode`, such changes do trigger them.
  --language: string # The subscribers detected language. (e.g. EN)
  --email-channel: record # shape: {email?: string, marketing_consent?: record}
  --sms-channel: record # shape: {sms_phone?: string, marketing_consent?: record}
  --merge-fields: record # A dictionary of merge fields where the keys are the merge tags. See the [Merge Fields documentation](https://mailchimp.com/developer/marketing/docs/merge-fields/#structure) for more about the structure.
  --tags: list # An array of tag names to add to the contact. This operation is append-only; existing tags will be preserved, and only new tags from this array will be added. (e.g. [tag_to_add_1, tag_to_add_2])
]: any -> record<id: string, audience_id: string, language: string, status: string, email_channel: record<email: string, hashed_email: string, effective_subscription_status: record<value: string>, marketing_consent: record<status: string, captured_at: string, source: record>, source: record<name: string>>, sms_channel: record<sms_phone: string, hashed_sms_phone: string, effective_subscription_status: record<value: string>, marketing_consent: record<status: string, captured_at: string, source: record>, source: record<name: string>>, merge_fields: record, tags: list<string>, source: record<name: string>, created_at: string, last_updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "merge_field_validation_mode" $merge_field_validation_mode "scalar") (serialize-qp "data_mode" $data_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/audiences/($audience_id)/contacts/($contact_id)" $qp)
  let body = {language: $language, email_channel: $email_channel, sms_channel: $sms_channel, merge_fields: $merge_fields, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive Contact
#
# POST /audiences/{audience_id}/contacts/{contact_id}/actions/archive
# operationId: postAudiencesContactsActionsArchive
export def "audiences-contacts-actions-archive post" [
  audience_id: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/audiences/($audience_id)/contacts/($contact_id)/actions/archive")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Forget Contact
#
# POST /audiences/{audience_id}/contacts/{contact_id}/actions/forget
# operationId: postAudiencesContactsActionsForget
export def "audiences-contacts-actions-forget post" [
  audience_id: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/audiences/($audience_id)/contacts/($contact_id)/actions/forget")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List authorized apps
#
# GET /authorized-apps
# operationId: getAuthorizedApps
export def "authorized-apps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<apps: table<id: int, name: string, description: string, users: list, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authorized-apps" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get authorized app info
#
# GET /authorized-apps/{app_id}
# operationId: getAuthorizedAppsId
export def "authorized-apps get" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: int, name: string, description: string, users: list<string>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/authorized-apps/($app_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List automations
#
# GET /automations
# operationId: getAutomations
export def "automations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --before-create-time: string # Restrict the response to automations created before this time. Uses the ISO 8601 time format: 2015-10-21T15:41:36+00:00. (format: date-time)
  --since-create-time: string # Restrict the response to automations created after this time. Uses the ISO 8601 time format: 2015-10-21T15:41:36+00:00. (format: date-time)
  --before-start-time: string # Restrict the response to automations started before this time. Uses the ISO 8601 time format: 2015-10-21T15:41:36+00:00. (format: date-time)
  --since-start-time: string # Restrict the response to automations started after this time. Uses the ISO 8601 time format: 2015-10-21T15:41:36+00:00. (format: date-time)
  --status: string@status-completer # Restrict the results to automations with the specified status.
]: nothing -> record<automations: table<id: string, create_time: string, start_time: string, status: string, emails_sent: int, recipients: record, settings: record, tracking: record, trigger_settings: record, report_summary: record, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "before_create_time" $before_create_time "scalar") (serialize-qp "since_create_time" $since_create_time "scalar") (serialize-qp "before_start_time" $before_start_time "scalar") (serialize-qp "since_start_time" $since_start_time "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/automations" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add automation
#
# POST /automations
# operationId: postAutomations
# --recipients shape: {list_id?: string, store_id?: string}
# --settings shape: {from_name?: string, reply_to?: string}
# --trigger_settings shape: {workflow_type: string}
export def "automations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  recipients: record # List settings for the Automation. — shape: {list_id?: string, store_id?: string}
  --settings: record # The settings for the Automation workflow. — shape: {from_name?: string, reply_to?: string}
  trigger_settings: record # Trigger settings for the Automation. — shape: {workflow_type: string}
]: any -> record<id: string, create_time: string, start_time: string, status: string, emails_sent: int, recipients: record<list_id: string, list_is_active: bool, list_name: string, segment_opts: record<saved_segment_id: int, match: string, conditions: list>, store_id: string>, settings: record<title: string, from_name: string, reply_to: string, use_conversation: bool, to_name: string, authenticate: bool, auto_footer: bool, inline_css: bool>, tracking: record<opens: bool, html_clicks: bool, text_clicks: bool, goal_tracking: bool, ecomm360: bool, google_analytics: string, clicktale: string, salesforce: record<campaign: bool, notes: bool>, capsule: record<notes: bool>>, trigger_settings: record<workflow_type: string, workflow_title: string, runtime: record<days: list, hours: record>, workflow_emails_count: int>, report_summary: record<opens: int, unique_opens: int, open_rate: float, clicks: int, subscriber_clicks: int, click_rate: float>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/automations")
  let body = {recipients: $recipients, settings: $settings, trigger_settings: $trigger_settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get automation info
#
# GET /automations/{workflow_id}
# operationId: getAutomationsId
export def "automations get" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, create_time: string, start_time: string, status: string, emails_sent: int, recipients: record<list_id: string, list_is_active: bool, list_name: string, segment_opts: record<saved_segment_id: int, match: string, conditions: list>, store_id: string>, settings: record<title: string, from_name: string, reply_to: string, use_conversation: bool, to_name: string, authenticate: bool, auto_footer: bool, inline_css: bool>, tracking: record<opens: bool, html_clicks: bool, text_clicks: bool, goal_tracking: bool, ecomm360: bool, google_analytics: string, clicktale: string, salesforce: record<campaign: bool, notes: bool>, capsule: record<notes: bool>>, trigger_settings: record<workflow_type: string, workflow_title: string, runtime: record<days: list, hours: record>, workflow_emails_count: int>, report_summary: record<opens: int, unique_opens: int, open_rate: float, clicks: int, subscriber_clicks: int, click_rate: float>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/automations/($workflow_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause automation emails
#
# POST /automations/{workflow_id}/actions/pause-all-emails
# operationId: postAutomationsIdActionsPauseAllEmails
export def "automations-actions-pause-all-emails post" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($workflow_id)/actions/pause-all-emails")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start automation emails
#
# POST /automations/{workflow_id}/actions/start-all-emails
# operationId: postAutomationsIdActionsStartAllEmails
export def "automations-actions-start-all-emails post" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($workflow_id)/actions/start-all-emails")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive automation
#
# POST /automations/{workflow_id}/actions/archive
# operationId: archiveAutomations
export def "automations-actions-archive archiveAutomations" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($workflow_id)/actions/archive")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List automated emails
#
# GET /automations/{workflow_id}/emails
# operationId: getAutomationsIdEmails
export def "automations-emails list" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<emails: table<id: string, web_id: int, workflow_id: string, position: int, delay: record, create_time: string, start_time: string, archive_url: string, status: string, emails_sent: int, send_time: string, content_type: string, needs_block_refresh: bool, has_logo_merge_tag: bool, recipients: record, settings: record, tracking: record, social_card: record, trigger_settings: record, report_summary: record, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($workflow_id)/emails")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get workflow email info
#
# GET /automations/{workflow_id}/emails/{workflow_email_id}
# operationId: getAutomationsIdEmailsId
export def "automations-emails get" [
  workflow_id: string
  workflow_email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, web_id: int, workflow_id: string, position: int, delay: record<amount: int, type: string, direction: string, action: string, action_description: string, full_description: string>, create_time: string, start_time: string, archive_url: string, status: string, emails_sent: int, send_time: string, content_type: string, needs_block_refresh: bool, has_logo_merge_tag: bool, recipients: record<list_id: string, list_is_active: bool, list_name: string, segment_text: string, recipient_count: int, segment_opts: record<saved_segment_id: int, prebuilt_segment_id: string, match: string, conditions: list>>, settings: record<subject_line: string, preview_text: string, title: string, from_name: string, reply_to: string, authenticate: bool, auto_footer: bool, inline_css: bool, auto_tweet: bool, auto_fb_post: list<string>, fb_comments: bool, template_id: int, drag_and_drop: bool>, tracking: record<opens: bool, html_clicks: bool, text_clicks: bool, goal_tracking: bool, ecomm360: bool, google_analytics: string, clicktale: string, salesforce: record<campaign: bool, notes: bool>, capsule: record<notes: bool>>, social_card: record<image_url: string, description: string, title: string>, trigger_settings: record<workflow_type: string, workflow_title: string, runtime: record<days: list, hours: record>, workflow_emails_count: int>, report_summary: record<opens: int, unique_opens: int, open_rate: float, clicks: int, subscriber_clicks: int, click_rate: float>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($workflow_id)/emails/($workflow_email_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete workflow email
#
# DELETE /automations/{workflow_id}/emails/{workflow_email_id}
# operationId: deleteAutomationsIdEmailsId
export def "automations-emails delete" [
  workflow_id: string
  workflow_email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($workflow_id)/emails/($workflow_email_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update workflow email
#
# PATCH /automations/{workflow_id}/emails/{workflow_email_id}
# operationId: patchAutomationEmailWorkflowId
# --settings shape: {subject_line?: string, preview_text?: string, title?: string, from_name?: string, reply_to?: string}
# --delay shape: {amount?: int, type?: "now"|"day"|"hour"|"week", direction?: "after", action: "signup"|"ecomm_abandoned_browse"|"ecomm_abandoned_cart"}
export def "automations-emails patch" [
  workflow_id: string
  workflow_email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --settings: record # Settings for the campaign including the email subject, from name, and from email address. — shape: {subject_line?: string, preview_text?: string, title?: string, from_name?: string, reply_to?: string}
  --delay: record # The delay settings for an automation email. — shape: {amount?: int, type?: "now"|"day"|"hour"|"week", direction?: "after", action: "signup"|"ecomm_abandoned_browse"|"ecomm_abandoned_cart"}
]: any -> record<id: string, web_id: int, workflow_id: string, position: int, delay: record<amount: int, type: string, direction: string, action: string, action_description: string, full_description: string>, create_time: string, start_time: string, archive_url: string, status: string, emails_sent: int, send_time: string, content_type: string, needs_block_refresh: bool, has_logo_merge_tag: bool, recipients: record<list_id: string, list_is_active: bool, list_name: string, segment_text: string, recipient_count: int, segment_opts: record<saved_segment_id: int, prebuilt_segment_id: string, match: string, conditions: list>>, settings: record<subject_line: string, preview_text: string, title: string, from_name: string, reply_to: string, authenticate: bool, auto_footer: bool, inline_css: bool, auto_tweet: bool, auto_fb_post: list<string>, fb_comments: bool, template_id: int, drag_and_drop: bool>, tracking: record<opens: bool, html_clicks: bool, text_clicks: bool, goal_tracking: bool, ecomm360: bool, google_analytics: string, clicktale: string, salesforce: record<campaign: bool, notes: bool>, capsule: record<notes: bool>>, social_card: record<image_url: string, description: string, title: string>, trigger_settings: record<workflow_type: string, workflow_title: string, runtime: record<days: list, hours: record>, workflow_emails_count: int>, report_summary: record<opens: int, unique_opens: int, open_rate: float, clicks: int, subscriber_clicks: int, click_rate: float>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($workflow_id)/emails/($workflow_email_id)")
  let body = {settings: $settings, delay: $delay} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List automated email subscribers
#
# GET /automations/{workflow_id}/emails/{workflow_email_id}/queue
# operationId: getAutomationsIdEmailsIdQueue
export def "automations-emails-queue list" [
  workflow_id: string
  workflow_email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<workflow_id: string, email_id: string, queue: table<id: string, workflow_id: string, email_id: string, list_id: string, email_address: string, next_send: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($workflow_id)/emails/($workflow_email_id)/queue")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add subscriber to workflow email
#
# POST /automations/{workflow_id}/emails/{workflow_email_id}/queue
# operationId: postAutomationsIdEmailsIdQueue
export def "automations-emails-queue post" [
  workflow_id: string
  workflow_email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  email_address: string # The list member's email address.
]: any -> record<id: string, workflow_id: string, email_id: string, list_id: string, list_is_active: bool, email_address: string, next_send: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($workflow_id)/emails/($workflow_email_id)/queue")
  let body = {email_address: $email_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get automated email subscriber
#
# GET /automations/{workflow_id}/emails/{workflow_email_id}/queue/{subscriber_hash}
# operationId: getAutomationsIdEmailsIdQueueId
export def "automations-emails-queue get" [
  workflow_id: string
  workflow_email_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, workflow_id: string, email_id: string, list_id: string, list_is_active: bool, email_address: string, next_send: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($workflow_id)/emails/($workflow_email_id)/queue/($subscriber_hash)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause automated email
#
# POST /automations/{workflow_id}/emails/{workflow_email_id}/actions/pause
# operationId: postAutomationsIdEmailsIdActionsPause
export def "automations-emails-actions-pause post" [
  workflow_id: string
  workflow_email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($workflow_id)/emails/($workflow_email_id)/actions/pause")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start automated email
#
# POST /automations/{workflow_id}/emails/{workflow_email_id}/actions/start
# operationId: postAutomationsIdEmailsIdActionsStart
export def "automations-emails-actions-start post" [
  workflow_id: string
  workflow_email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($workflow_id)/emails/($workflow_email_id)/actions/start")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List subscribers removed from workflow
#
# GET /automations/{workflow_id}/removed-subscribers
# operationId: getAutomationsIdRemovedSubscribers
export def "automations-removed-subscribers list" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<workflow_id: string, subscribers: table<id: string, workflow_id: string, list_id: string, email_address: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($workflow_id)/removed-subscribers")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove subscriber from workflow
#
# POST /automations/{workflow_id}/removed-subscribers
# operationId: postAutomationsIdRemovedSubscribers
export def "automations-removed-subscribers post" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  email_address: string # The list member's email address.
]: any -> record<id: string, workflow_id: string, list_id: string, email_address: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($workflow_id)/removed-subscribers")
  let body = {email_address: $email_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get subscriber removed from workflow
#
# GET /automations/{workflow_id}/removed-subscribers/{subscriber_hash}
# operationId: getAutomationsIdRemovedSubscribersId
export def "automations-removed-subscribers get" [
  workflow_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, workflow_id: string, list_id: string, email_address: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($workflow_id)/removed-subscribers/($subscriber_hash)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List batch requests
#
# GET /batches
# operationId: getBatches
export def "batches list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<batches: table<id: string, status: string, total_operations: int, finished_operations: int, errored_operations: int, submitted_at: string, completed_at: string, response_body_url: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/batches" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start batch operation
#
# POST /batches
# operationId: postBatches
# --operations item shape: {method: "GET"|"POST"|"PUT"|"PATCH"|"DELETE", headers?: record, path: string, params?: record, body?: string, operation_id?: string}
export def "batches post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  operations: list # An array of objects that describes operations to perform. — item shape: {method: "GET"|"POST"|"PUT"|"PATCH"|"DELETE", headers?: record, path: string, params?: record, body?: string, operation_id?: string}
]: any -> record<id: string, status: string, total_operations: int, finished_operations: int, errored_operations: int, submitted_at: string, completed_at: string, response_body_url: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batches")
  let body = {operations: $operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get batch operation status
#
# GET /batches/{batch_id}
# operationId: getBatchesId
export def "batches get" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, status: string, total_operations: int, finished_operations: int, errored_operations: int, submitted_at: string, completed_at: string, response_body_url: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/batches/($batch_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete batch request
#
# DELETE /batches/{batch_id}
# operationId: deleteBatchesId
export def "batches delete" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/batches/($batch_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List batch webhooks
#
# GET /batch-webhooks
# operationId: getBatchWebhooks
export def "batch-webhooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<webhooks: table<id: string, url: string, enabled: bool, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/batch-webhooks" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add batch webhook
#
# POST /batch-webhooks
# operationId: postBatchWebhooks
export def "batch-webhooks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-url: string # A valid URL for the Webhook. (e.g. http://yourdomain.com/webhook)
  --enabled: oneof<nothing, bool> # Whether the webhook receives requests or not. (e.g. true)
]: any -> record<id: string, url: string, enabled: bool, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batch-webhooks")
  let body = {url: $body_url, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get batch webhook info
#
# GET /batch-webhooks/{batch_webhook_id}
# operationId: getBatchWebhook
export def "batch-webhooks get" [
  batch_webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, url: string, enabled: bool, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/batch-webhooks/($batch_webhook_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update batch webhook
#
# PATCH /batch-webhooks/{batch_webhook_id}
# operationId: patchBatchWebhooks
export def "batch-webhooks patch" [
  batch_webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-url: string # A valid URL for the Webhook. (e.g. http://yourdomain.com/webhook)
  --enabled: oneof<nothing, bool> # Whether the webhook receives requests or not. (e.g. true)
]: any -> record<id: string, url: string, enabled: bool, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/batch-webhooks/($batch_webhook_id)")
  let body = {url: $body_url, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete batch webhook
#
# DELETE /batch-webhooks/{batch_webhook_id}
# operationId: deleteBatchWebhookId
export def "batch-webhooks delete" [
  batch_webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/batch-webhooks/($batch_webhook_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List template folders
#
# GET /template-folders
# operationId: getTemplateFolders
export def "template-folders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<folders: table<name: string, id: string, count: int, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/template-folders" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add template folder
#
# POST /template-folders
# operationId: postTemplateFolders
export def "template-folders post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The name of the folder.
]: any -> record<name: string, id: string, count: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/template-folders")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get template folder
#
# GET /template-folders/{folder_id}
# operationId: getTemplateFoldersId
export def "template-folders get" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<name: string, id: string, count: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/template-folders/($folder_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update template folder
#
# PATCH /template-folders/{folder_id}
# operationId: patchTemplateFoldersId
export def "template-folders patch" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The name of the folder.
]: any -> record<name: string, id: string, count: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/template-folders/($folder_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete template folder
#
# DELETE /template-folders/{folder_id}
# operationId: deleteTemplateFoldersId
export def "template-folders delete" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/template-folders/($folder_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List campaign folders
#
# GET /campaign-folders
# operationId: getCampaignFolders
export def "campaign-folders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<folders: table<name: string, id: string, count: int, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/campaign-folders" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add campaign folder
#
# POST /campaign-folders
# operationId: postCampaignFolders
export def "campaign-folders post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # Name to associate with the folder.
]: any -> record<name: string, id: string, count: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/campaign-folders")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get campaign folder
#
# GET /campaign-folders/{folder_id}
# operationId: getCampaignFoldersId
export def "campaign-folders get" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<name: string, id: string, count: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/campaign-folders/($folder_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update campaign folder
#
# PATCH /campaign-folders/{folder_id}
# operationId: patchCampaignFoldersId
export def "campaign-folders patch" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # Name to associate with the folder.
]: any -> record<name: string, id: string, count: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaign-folders/($folder_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete campaign folder
#
# DELETE /campaign-folders/{folder_id}
# operationId: deleteCampaignFoldersId
export def "campaign-folders delete" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaign-folders/($folder_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List campaigns
#
# GET /campaigns
# operationId: getCampaigns
export def "campaigns list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --type: string@type-completer # The campaign type.
  --status: string@status-completer-1 # The status of the campaign.
  --before-send-time: string # Restrict the response to campaigns sent before the set time. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00. (format: date-time)
  --since-send-time: string # Restrict the response to campaigns sent after the set time. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00. (format: date-time)
  --before-create-time: string # Restrict the response to campaigns created before the set time. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00. (format: date-time)
  --since-create-time: string # Restrict the response to campaigns created after the set time. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00. (format: date-time)
  --list-id: string # The unique id for the list.
  --folder-id: string # The unique folder id.
  --member-id: string # Retrieve campaigns sent to a particular list member. Member ID is The MD5 hash of the lowercase version of the list member’s email address.
  --sort-field: string@sort-field-completer-1 # Returns files sorted by the specified field.
  --sort-dir: string@sort-dir-completer # Determines the order direction for sorted results.
  --include-resend-shortcut-eligibility: oneof<nothing, bool> # Return the `resend_shortcut_eligibility` field in the response, which tells you if the campaign is eligible for the various Campaign Resend Shortcuts offered.
  --include-resend-shortcut-usage: oneof<nothing, bool> # Return the `resend_shortcut_usage` field in the response.  This includes information about campaigns related by a shortcut.
]: nothing -> record<campaigns: table<id: string, web_id: int, parent_campaign_id: string, type: string, create_time: string, archive_url: string, long_archive_url: string, status: string, emails_sent: int, send_time: string, content_type: string, needs_block_refresh: bool, resendable: bool, recipients: record, settings: record, variate_settings: record, tracking: record, rss_opts: record, ab_split_opts: record, social_card: record, report_summary: record, delivery_status: record, resend_shortcut_eligibility: record, resend_shortcut_usage: record, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "before_send_time" $before_send_time "scalar") (serialize-qp "since_send_time" $since_send_time "scalar") (serialize-qp "before_create_time" $before_create_time "scalar") (serialize-qp "since_create_time" $since_create_time "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "folder_id" $folder_id "scalar") (serialize-qp "member_id" $member_id "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "include_resend_shortcut_eligibility" $include_resend_shortcut_eligibility "scalar") (serialize-qp "include_resend_shortcut_usage" $include_resend_shortcut_usage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/campaigns" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add campaign
#
# POST /campaigns
# operationId: postCampaigns
# --recipients shape: {list_id: string, segment_opts?: record}
# --settings shape: {subject_line?: string, preview_text?: string, title?: string, from_name?: string, reply_to?: string, use_conversation?: bool, to_name?: string, folder_id?: string, authenticate?: bool, auto_footer?: bool, inline_css?: bool, auto_tweet?: bool, auto_fb_post?: list, fb_comments?: bool, template_id?: int}
# --variate_settings shape: {winner_criteria: "opens"|"clicks"|"manual"|"total_revenue", wait_time?: int, test_size?: int, subject_lines?: list, send_times?: list, from_names?: list, reply_to_addresses?: list}
# --tracking shape: {opens?: bool, html_clicks?: bool, text_clicks?: bool, goal_tracking?: bool, ecomm360?: bool, google_analytics?: string, clicktale?: string, salesforce?: record, capsule?: record}
# --rss_opts shape: {feed_url: string, frequency: "daily"|"weekly"|"monthly", schedule?: record, constrain_rss_img?: bool}
# --social_card shape: {image_url?: string, description?: string, title?: string}
export def "campaigns post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  type: string@type-completer # There are four types of [campaigns](https://mailchimp.com/help/getting-started-with-campaigns/) you can create in Mailchimp. A/B Split campaigns have been deprecated and variate campaigns should be used instead.
  --recipients: record # List settings for the campaign. — shape: {list_id: string, segment_opts?: record}
  --settings: record # The settings for your campaign, including subject, from name, reply-to address, and more. — shape: {subject_line?: string, preview_text?: string, title?: string, from_name?: string, reply_to?: string, use_conversation?: bool, to_name?: string, folder_id?: string, authenticate?: bool, auto_footer?: bool, inline_css?: bool, auto_tweet?: bool, auto_fb_post?: list, fb_comments?: bool, template_id?: int}
  --variate-settings: record # The settings specific to A/B test campaigns. — shape: {winner_criteria: "opens"|"clicks"|"manual"|"total_revenue", wait_time?: int, test_size?: int, subject_lines?: list, send_times?: list, from_names?: list, reply_to_addresses?: list}
  --tracking: record # The tracking options for a campaign. — shape: {opens?: bool, html_clicks?: bool, text_clicks?: bool, goal_tracking?: bool, ecomm360?: bool, google_analytics?: string, clicktale?: string, salesforce?: record, capsule?: record}
  --rss-opts: record # [RSS](https://mailchimp.com/help/share-your-blog-posts-with-mailchimp/) options, specific to an RSS campaign. — shape: {feed_url: string, frequency: "daily"|"weekly"|"monthly", schedule?: record, constrain_rss_img?: bool}
  --social-card: record # The preview for the campaign, rendered by social networks like Facebook and Twitter. [Learn more](https://mailchimp.com/help/enable-and-customize-social-cards/). — shape: {image_url?: string, description?: string, title?: string}
  --content-type: string@content-type-completer # How the campaign's content is put together. The old drag and drop editor uses 'template' while the new editor uses 'multichannel'. Defaults to template. (e.g. template)
]: any -> record<id: string, web_id: int, parent_campaign_id: string, type: string, create_time: string, archive_url: string, long_archive_url: string, status: string, emails_sent: int, send_time: string, content_type: string, needs_block_refresh: bool, resendable: bool, recipients: record<list_id: string, list_is_active: bool, list_name: string, segment_text: string, recipient_count: int, segment_opts: record<saved_segment_id: int, prebuilt_segment_id: string, match: string, conditions: list>>, settings: record<subject_line: string, preview_text: string, title: string, from_name: string, reply_to: string, use_conversation: bool, to_name: string, folder_id: string, authenticate: bool, auto_footer: bool, inline_css: bool, auto_tweet: bool, auto_fb_post: list<string>, fb_comments: bool, timewarp: bool, template_id: int, drag_and_drop: bool>, variate_settings: record<winning_combination_id: string, winning_campaign_id: string, winner_criteria: string, wait_time: int, test_size: int, subject_lines: list<string>, send_times: list<string>, from_names: list<string>, reply_to_addresses: list<string>, contents: list<string>, combinations: list<record>>, tracking: record<opens: bool, html_clicks: bool, text_clicks: bool, goal_tracking: bool, ecomm360: bool, google_analytics: string, clicktale: string, salesforce: record<campaign: bool, notes: bool>, capsule: record<notes: bool>>, rss_opts: record<feed_url: string, frequency: string, schedule: record<hour: int, daily_send: record, weekly_send_day: string, monthly_send_date: float>, last_sent: string, constrain_rss_img: bool>, ab_split_opts: record<split_test: string, pick_winner: string, wait_units: string, wait_time: int, split_size: int, from_name_a: string, from_name_b: string, reply_email_a: string, reply_email_b: string, subject_a: string, subject_b: string, send_time_a: string, send_time_b: string, send_time_winner: string>, social_card: record<image_url: string, description: string, title: string>, report_summary: record<opens: int, unique_opens: int, open_rate: float, clicks: int, subscriber_clicks: int, click_rate: float, ecommerce: record<total_orders: int, total_spent: float, total_revenue: float>>, delivery_status: record<enabled: bool, can_cancel: bool, status: string, emails_sent: int, emails_canceled: int>, resend_shortcut_eligibility: record<to_non_openers: record<is_eligible: bool, reason: string>, to_new_subscribers: record<is_eligible: bool, reason: string>, to_non_clickers: record<is_eligible: bool, reason: string>, to_non_purchasers: record<is_eligible: bool, reason: string>>, resend_shortcut_usage: record<shortcut_campaigns: list<record>, original_campaign: record<id: string, web_id: int, title: string, shortcut_type: string>>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/campaigns")
  let body = {type: $type, recipients: $recipients, settings: $settings, variate_settings: $variate_settings, tracking: $tracking, rss_opts: $rss_opts, social_card: $social_card, content_type: $content_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get campaign info
#
# GET /campaigns/{campaign_id}
# operationId: getCampaignsId
export def "campaigns get" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --include-resend-shortcut-eligibility: oneof<nothing, bool> # Return the `resend_shortcut_eligibility` field in the response, which tells you if the campaign is eligible for the various Campaign Resend Shortcuts offered.
  --include-resend-shortcut-usage: oneof<nothing, bool> # Return the `resend_shortcut_usage` field in the response.  This includes information about campaigns related by a shortcut.
]: nothing -> record<id: string, web_id: int, parent_campaign_id: string, type: string, create_time: string, archive_url: string, long_archive_url: string, status: string, emails_sent: int, send_time: string, content_type: string, needs_block_refresh: bool, resendable: bool, recipients: record<list_id: string, list_is_active: bool, list_name: string, segment_text: string, recipient_count: int, segment_opts: record<saved_segment_id: int, prebuilt_segment_id: string, match: string, conditions: list>>, settings: record<subject_line: string, preview_text: string, title: string, from_name: string, reply_to: string, use_conversation: bool, to_name: string, folder_id: string, authenticate: bool, auto_footer: bool, inline_css: bool, auto_tweet: bool, auto_fb_post: list<string>, fb_comments: bool, timewarp: bool, template_id: int, drag_and_drop: bool>, variate_settings: record<winning_combination_id: string, winning_campaign_id: string, winner_criteria: string, wait_time: int, test_size: int, subject_lines: list<string>, send_times: list<string>, from_names: list<string>, reply_to_addresses: list<string>, contents: list<string>, combinations: list<record>>, tracking: record<opens: bool, html_clicks: bool, text_clicks: bool, goal_tracking: bool, ecomm360: bool, google_analytics: string, clicktale: string, salesforce: record<campaign: bool, notes: bool>, capsule: record<notes: bool>>, rss_opts: record<feed_url: string, frequency: string, schedule: record<hour: int, daily_send: record, weekly_send_day: string, monthly_send_date: float>, last_sent: string, constrain_rss_img: bool>, ab_split_opts: record<split_test: string, pick_winner: string, wait_units: string, wait_time: int, split_size: int, from_name_a: string, from_name_b: string, reply_email_a: string, reply_email_b: string, subject_a: string, subject_b: string, send_time_a: string, send_time_b: string, send_time_winner: string>, social_card: record<image_url: string, description: string, title: string>, report_summary: record<opens: int, unique_opens: int, open_rate: float, clicks: int, subscriber_clicks: int, click_rate: float, ecommerce: record<total_orders: int, total_spent: float, total_revenue: float>>, delivery_status: record<enabled: bool, can_cancel: bool, status: string, emails_sent: int, emails_canceled: int>, resend_shortcut_eligibility: record<to_non_openers: record<is_eligible: bool, reason: string>, to_new_subscribers: record<is_eligible: bool, reason: string>, to_non_clickers: record<is_eligible: bool, reason: string>, to_non_purchasers: record<is_eligible: bool, reason: string>>, resend_shortcut_usage: record<shortcut_campaigns: list<record>, original_campaign: record<id: string, web_id: int, title: string, shortcut_type: string>>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "include_resend_shortcut_eligibility" $include_resend_shortcut_eligibility "scalar") (serialize-qp "include_resend_shortcut_usage" $include_resend_shortcut_usage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/campaigns/($campaign_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update campaign settings
#
# PATCH /campaigns/{campaign_id}
# operationId: patchCampaignsId
# --recipients shape: {list_id: string, segment_opts?: record}
# --settings shape: {subject_line: string, preview_text?: string, title?: string, from_name: string, reply_to: string, use_conversation?: bool, to_name?: string, folder_id?: string, authenticate?: bool, auto_footer?: bool, inline_css?: bool, auto_tweet?: bool, auto_fb_post?: list, fb_comments?: bool, template_id?: int}
# --variate_settings shape: {winner_criteria: "opens"|"clicks"|"manual"|"total_revenue", wait_time?: int, test_size?: int, subject_lines?: list, send_times?: list, from_names?: list, reply_to_addresses?: list}
# --tracking shape: {opens?: bool, html_clicks?: bool, text_clicks?: bool, goal_tracking?: bool, ecomm360?: bool, google_analytics?: string, clicktale?: string, salesforce?: record, capsule?: record}
# --rss_opts shape: {feed_url: string, frequency: "daily"|"weekly"|"monthly", schedule?: record, constrain_rss_img?: bool}
# --social_card shape: {image_url?: string, description?: string, title?: string}
export def "campaigns patch" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --recipients: record # List settings for the campaign. — shape: {list_id: string, segment_opts?: record}
  settings: record # The settings for your campaign, including subject, from name, reply-to address, and more. — shape: {subject_line: string, preview_text?: string, title?: string, from_name: string, reply_to: string, use_conversation?: bool, to_name?: string, folder_id?: string, authenticate?: bool, auto_footer?: bool, inline_css?: bool, auto_tweet?: bool, auto_fb_post?: list, fb_comments?: bool, template_id?: int}
  --variate-settings: record # The settings specific to A/B test campaigns. — shape: {winner_criteria: "opens"|"clicks"|"manual"|"total_revenue", wait_time?: int, test_size?: int, subject_lines?: list, send_times?: list, from_names?: list, reply_to_addresses?: list}
  --tracking: record # The tracking options for a campaign. — shape: {opens?: bool, html_clicks?: bool, text_clicks?: bool, goal_tracking?: bool, ecomm360?: bool, google_analytics?: string, clicktale?: string, salesforce?: record, capsule?: record}
  --rss-opts: record # [RSS](https://mailchimp.com/help/share-your-blog-posts-with-mailchimp/) options for a campaign. — shape: {feed_url: string, frequency: "daily"|"weekly"|"monthly", schedule?: record, constrain_rss_img?: bool}
  --social-card: record # The preview for the campaign, rendered by social networks like Facebook and Twitter. [Learn more](https://mailchimp.com/help/enable-and-customize-social-cards/). — shape: {image_url?: string, description?: string, title?: string}
]: any -> record<id: string, web_id: int, parent_campaign_id: string, type: string, create_time: string, archive_url: string, long_archive_url: string, status: string, emails_sent: int, send_time: string, content_type: string, needs_block_refresh: bool, resendable: bool, recipients: record<list_id: string, list_is_active: bool, list_name: string, segment_text: string, recipient_count: int, segment_opts: record<saved_segment_id: int, prebuilt_segment_id: string, match: string, conditions: list>>, settings: record<subject_line: string, preview_text: string, title: string, from_name: string, reply_to: string, use_conversation: bool, to_name: string, folder_id: string, authenticate: bool, auto_footer: bool, inline_css: bool, auto_tweet: bool, auto_fb_post: list<string>, fb_comments: bool, timewarp: bool, template_id: int, drag_and_drop: bool>, variate_settings: record<winning_combination_id: string, winning_campaign_id: string, winner_criteria: string, wait_time: int, test_size: int, subject_lines: list<string>, send_times: list<string>, from_names: list<string>, reply_to_addresses: list<string>, contents: list<string>, combinations: list<record>>, tracking: record<opens: bool, html_clicks: bool, text_clicks: bool, goal_tracking: bool, ecomm360: bool, google_analytics: string, clicktale: string, salesforce: record<campaign: bool, notes: bool>, capsule: record<notes: bool>>, rss_opts: record<feed_url: string, frequency: string, schedule: record<hour: int, daily_send: record, weekly_send_day: string, monthly_send_date: float>, last_sent: string, constrain_rss_img: bool>, ab_split_opts: record<split_test: string, pick_winner: string, wait_units: string, wait_time: int, split_size: int, from_name_a: string, from_name_b: string, reply_email_a: string, reply_email_b: string, subject_a: string, subject_b: string, send_time_a: string, send_time_b: string, send_time_winner: string>, social_card: record<image_url: string, description: string, title: string>, report_summary: record<opens: int, unique_opens: int, open_rate: float, clicks: int, subscriber_clicks: int, click_rate: float, ecommerce: record<total_orders: int, total_spent: float, total_revenue: float>>, delivery_status: record<enabled: bool, can_cancel: bool, status: string, emails_sent: int, emails_canceled: int>, resend_shortcut_eligibility: record<to_non_openers: record<is_eligible: bool, reason: string>, to_new_subscribers: record<is_eligible: bool, reason: string>, to_non_clickers: record<is_eligible: bool, reason: string>, to_non_purchasers: record<is_eligible: bool, reason: string>>, resend_shortcut_usage: record<shortcut_campaigns: list<record>, original_campaign: record<id: string, web_id: int, title: string, shortcut_type: string>>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)")
  let body = {recipients: $recipients, settings: $settings, variate_settings: $variate_settings, tracking: $tracking, rss_opts: $rss_opts, social_card: $social_card} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete campaign
#
# DELETE /campaigns/{campaign_id}
# operationId: deleteCampaignsId
export def "campaigns delete" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel campaign
#
# POST /campaigns/{campaign_id}/actions/cancel-send
# operationId: postCampaignsIdActionsCancelSend
export def "campaigns-actions-cancel-send post" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/actions/cancel-send")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replicate campaign
#
# POST /campaigns/{campaign_id}/actions/replicate
# operationId: postCampaignsIdActionsReplicate
export def "campaigns-actions-replicate post" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, web_id: int, parent_campaign_id: string, type: string, create_time: string, archive_url: string, long_archive_url: string, status: string, emails_sent: int, send_time: string, content_type: string, needs_block_refresh: bool, resendable: bool, recipients: record<list_id: string, list_name: string, segment_text: string, recipient_count: int, segment_opts: record<saved_segment_id: int, prebuilt_segment_id: string, match: string, conditions: list>>, settings: record<subject_line: string, preview_text: string, title: string, from_name: string, reply_to: string, use_conversation: bool, to_name: string, folder_id: string, authenticate: bool, auto_footer: bool, inline_css: bool, auto_tweet: bool, auto_fb_post: list<string>, fb_comments: bool, timewarp: bool, template_id: int, drag_and_drop: bool>, variate_settings: record<winning_combination_id: string, winning_campaign_id: string, winner_criteria: string, wait_time: int, test_size: int, subject_lines: list<string>, send_times: list<string>, from_names: list<string>, reply_to_addresses: list<string>, contents: list<string>, combinations: list<record>>, tracking: record<opens: bool, html_clicks: bool, text_clicks: bool, goal_tracking: bool, ecomm360: bool, google_analytics: string, clicktale: string, salesforce: record<campaign: bool, notes: bool>, capsule: record<notes: bool>>, rss_opts: record<feed_url: string, frequency: string, schedule: record<hour: int, daily_send: record, weekly_send_day: string, monthly_send_date: float>, last_sent: string, constrain_rss_img: bool>, ab_split_opts: record<split_test: string, pick_winner: string, wait_units: string, wait_time: int, split_size: int, from_name_a: string, from_name_b: string, reply_email_a: string, reply_email_b: string, subject_a: string, subject_b: string, send_time_a: string, send_time_b: string, send_time_winner: string>, social_card: record<image_url: string, description: string, title: string>, report_summary: record<opens: int, unique_opens: int, open_rate: float, clicks: int, subscriber_clicks: int, click_rate: float, ecommerce: record<total_orders: int, total_spent: float, total_revenue: float>>, delivery_status: record<enabled: bool, can_cancel: bool, status: string, emails_sent: int, emails_canceled: int>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/actions/replicate")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send campaign
#
# POST /campaigns/{campaign_id}/actions/send
# operationId: postCampaignsIdActionsSend
export def "campaigns-actions-send post" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/actions/send")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Schedule campaign
#
# POST /campaigns/{campaign_id}/actions/schedule
# operationId: postCampaignsIdActionsSchedule
# --batch_delivery shape: {batch_delay: int, batch_count: int}
export def "campaigns-actions-schedule post" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  schedule_time: string # The UTC date and time to schedule the campaign for delivery in ISO 8601 format. Campaigns may only be scheduled to send on the quarter-hour (:00, :15, :30, :45). (format: date-time)
  --timewarp: oneof<nothing, bool> # Choose whether the campaign should use [Timewarp](https://mailchimp.com/help/use-timewarp/) when sending. Campaigns scheduled with Timewarp are localized based on the recipients' time zones. For example, a Timewarp campaign with a `schedule_time` of 13:00 will be sent to each recipient at 1:00pm in their local time. Cannot be set to `true` for campaigns using [Batch Delivery](https://mailchimp.com/help/schedule-batch-delivery/).
  --batch-delivery: record # Choose whether the campaign should use [Batch Delivery](https://mailchimp.com/help/schedule-batch-delivery/). Cannot be set to `true` for campaigns using [Timewarp](https://mailchimp.com/help/use-timewarp/). — shape: {batch_delay: int, batch_count: int}
]: any -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/actions/schedule")
  let body = {schedule_time: $schedule_time, timewarp: $timewarp, batch_delivery: $batch_delivery} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unschedule campaign
#
# POST /campaigns/{campaign_id}/actions/unschedule
# operationId: postCampaignsIdActionsUnschedule
export def "campaigns-actions-unschedule post" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/actions/unschedule")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send test email
#
# POST /campaigns/{campaign_id}/actions/test
# operationId: postCampaignsIdActionsTest
export def "campaigns-actions-test post" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  test_emails: list # An array of email addresses to send the test email to.
  send_type: string@send-type-completer # Choose the type of test email to send.
]: any -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/actions/test")
  let body = {test_emails: $test_emails, send_type: $send_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Pause rss campaign
#
# POST /campaigns/{campaign_id}/actions/pause
# operationId: postCampaignsIdActionsPause
export def "campaigns-actions-pause post" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/actions/pause")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resume rss campaign
#
# POST /campaigns/{campaign_id}/actions/resume
# operationId: postCampaignsIdActionsResume
export def "campaigns-actions-resume post" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/actions/resume")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resend campaign
#
# POST /campaigns/{campaign_id}/actions/create-resend
# operationId: postCampaignsIdActionsCreateResend
export def "campaigns-actions-create-resend post" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --shortcut-type: string@shortcut-type-completer # Which campaign resend shortcut to use. Default is `to_non_openers`.
]: any -> record<id: string, web_id: int, parent_campaign_id: string, type: string, create_time: string, archive_url: string, long_archive_url: string, status: string, emails_sent: int, send_time: string, content_type: string, needs_block_refresh: bool, resendable: bool, recipients: record<list_id: string, list_name: string, segment_text: string, recipient_count: int, segment_opts: record<saved_segment_id: int, prebuilt_segment_id: string, match: string, conditions: list>>, settings: record<subject_line: string, preview_text: string, title: string, from_name: string, reply_to: string, use_conversation: bool, to_name: string, folder_id: string, authenticate: bool, auto_footer: bool, inline_css: bool, auto_tweet: bool, auto_fb_post: list<string>, fb_comments: bool, timewarp: bool, template_id: int, drag_and_drop: bool>, variate_settings: record<winning_combination_id: string, winning_campaign_id: string, winner_criteria: string, wait_time: int, test_size: int, subject_lines: list<string>, send_times: list<string>, from_names: list<string>, reply_to_addresses: list<string>, contents: list<string>, combinations: list<record>>, tracking: record<opens: bool, html_clicks: bool, text_clicks: bool, goal_tracking: bool, ecomm360: bool, google_analytics: string, clicktale: string, salesforce: record<campaign: bool, notes: bool>, capsule: record<notes: bool>>, rss_opts: record<feed_url: string, frequency: string, schedule: record<hour: int, daily_send: record, weekly_send_day: string, monthly_send_date: float>, last_sent: string, constrain_rss_img: bool>, ab_split_opts: record<split_test: string, pick_winner: string, wait_units: string, wait_time: int, split_size: int, from_name_a: string, from_name_b: string, reply_email_a: string, reply_email_b: string, subject_a: string, subject_b: string, send_time_a: string, send_time_b: string, send_time_winner: string>, social_card: record<image_url: string, description: string, title: string>, report_summary: record<opens: int, unique_opens: int, open_rate: float, clicks: int, subscriber_clicks: int, click_rate: float, ecommerce: record<total_orders: int, total_spent: float, total_revenue: float>>, delivery_status: record<enabled: bool, can_cancel: bool, status: string, emails_sent: int, emails_canceled: int>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/actions/create-resend")
  let body = {shortcut_type: $shortcut_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get campaign content
#
# GET /campaigns/{campaign_id}/content
# operationId: getCampaignsIdContent
export def "campaigns-content get" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<variate_contents: table<content_label: string, plain_text: string, html: string>, plain_text: string, html: string, archive_html: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/campaigns/($campaign_id)/content" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set campaign content
#
# PUT /campaigns/{campaign_id}/content
# operationId: putCampaignsIdContent
# --template shape: {id: int, sections?: record}
# --archive shape: {archive_content: string, archive_type?: "zip"|"tar.gz"|"tar.bz2"|"tar"|"tgz"|"tbz"}
# --variate_contents item shape: {content_label: string, plain_text?: string, html?: string, url?: string, template?: record, archive?: record}
export def "campaigns-content put" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --plain-text: string # The plain-text portion of the campaign. If left unspecified, we'll generate this automatically.
  --html: string # The raw HTML for the campaign.
  --body-url: string # When importing a campaign, the URL where the HTML lives.
  --template: record # Use this template to generate the HTML content of the campaign — shape: {id: int, sections?: record}
  --archive: record # Available when uploading an archive to create campaign content. The archive should include all campaign content and images. [Learn more](https://mailchimp.com/help/import-a-custom-html-template/). — shape: {archive_content: string, archive_type?: "zip"|"tar.gz"|"tar.bz2"|"tar"|"tgz"|"tbz"}
  --variate-contents: list # Content options for [Multivariate Campaigns](https://mailchimp.com/help/about-multivariate-campaigns/). Each content option must provide HTML content and may optionally provide plain text. For campaigns not testing content, only one object should be provided. — item shape: {content_label: string, plain_text?: string, html?: string, url?: string, template?: record, archive?: record}
]: any -> record<variate_contents: table<content_label: string, plain_text: string, html: string>, plain_text: string, html: string, archive_html: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/content")
  let body = {plain_text: $plain_text, html: $html, url: $body_url, template: $template, archive: $archive, variate_contents: $variate_contents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List campaign feedback
#
# GET /campaigns/{campaign_id}/feedback
# operationId: getCampaignsIdFeedback
export def "campaigns-feedback list" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<feedback: table<feedback_id: int, parent_id: int, block_id: int, message: string, is_complete: bool, created_by: string, created_at: string, updated_at: string, source: string, campaign_id: string, _links: list>, campaign_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/campaigns/($campaign_id)/feedback" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add campaign feedback
#
# POST /campaigns/{campaign_id}/feedback
# operationId: postCampaignsIdFeedback
export def "campaigns-feedback post" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --block-id: int # The block id for the editable block that the feedback addresses.
  message: string # The content of the feedback.
  --is-complete: oneof<nothing, bool> # The status of feedback.
]: any -> record<feedback_id: int, parent_id: int, block_id: int, message: string, is_complete: bool, created_by: string, created_at: string, updated_at: string, source: string, campaign_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/feedback")
  let body = {block_id: $block_id, message: $message, is_complete: $is_complete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get campaign feedback message
#
# GET /campaigns/{campaign_id}/feedback/{feedback_id}
# operationId: getCampaignsIdFeedbackId
export def "campaigns-feedback get" [
  campaign_id: string
  feedback_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<feedback_id: int, parent_id: int, block_id: int, message: string, is_complete: bool, created_by: string, created_at: string, updated_at: string, source: string, campaign_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/campaigns/($campaign_id)/feedback/($feedback_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update campaign feedback message
#
# PATCH /campaigns/{campaign_id}/feedback/{feedback_id}
# operationId: patchCampaignsIdFeedbackId
export def "campaigns-feedback patch" [
  campaign_id: string
  feedback_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --block-id: int # The block id for the editable block that the feedback addresses.
  --message: string # The content of the feedback.
  --is-complete: oneof<nothing, bool> # The status of feedback.
]: any -> record<feedback_id: int, parent_id: int, block_id: int, message: string, is_complete: bool, created_by: string, created_at: string, updated_at: string, source: string, campaign_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/feedback/($feedback_id)")
  let body = {block_id: $block_id, message: $message, is_complete: $is_complete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete campaign feedback message
#
# DELETE /campaigns/{campaign_id}/feedback/{feedback_id}
# operationId: deleteCampaignsIdFeedbackId
export def "campaigns-feedback delete" [
  campaign_id: string
  feedback_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/feedback/($feedback_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get campaign send checklist
#
# GET /campaigns/{campaign_id}/send-checklist
# operationId: getCampaignsIdSendChecklist
export def "campaigns-send-checklist get" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<is_ready: bool, items: table<type: string, id: int, heading: string, details: string>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/campaigns/($campaign_id)/send-checklist" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List connected sites
#
# GET /connected-sites
# operationId: getConnectedSites
export def "connected-sites list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<sites: table<foreign_id: string, store_id: string, platform: string, domain: string, site_script: record, is_pixel_enabled: bool, created_at: string, updated_at: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connected-sites" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add connected site
#
# POST /connected-sites
# operationId: postConnectedSites
export def "connected-sites post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  foreign_id: string # The unique identifier for the site. (e.g. MC001)
  domain: string # The connected site domain. (e.g. example.com)
]: any -> record<foreign_id: string, store_id: string, platform: string, domain: string, site_script: record<url: string, fragment: string>, is_pixel_enabled: bool, created_at: string, updated_at: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/connected-sites")
  let body = {foreign_id: $foreign_id, domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get connected site
#
# GET /connected-sites/{connected_site_id}
# operationId: getConnectedSitesId
export def "connected-sites get" [
  connected_site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<foreign_id: string, store_id: string, platform: string, domain: string, site_script: record<url: string, fragment: string>, is_pixel_enabled: bool, created_at: string, updated_at: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/connected-sites/($connected_site_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete connected site
#
# DELETE /connected-sites/{connected_site_id}
# operationId: deleteConnectedSitesId
export def "connected-sites delete" [
  connected_site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connected-sites/($connected_site_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify connected site script
#
# POST /connected-sites/{connected_site_id}/actions/verify-script-installation
# operationId: postConnectedSitesIdActionsVerifyScriptInstallation
export def "connected-sites-actions-verify-script-installation post" [
  connected_site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connected-sites/($connected_site_id)/actions/verify-script-installation")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable pixel for connected site
#
# POST /connected-sites/{connected_site_id}/actions/enable-pixel
# operationId: postConnectedSitesIdActionsEnablePixel
export def "connected-sites-actions-enable-pixel post" [
  connected_site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connected-sites/($connected_site_id)/actions/enable-pixel")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable pixel for connected site
#
# POST /connected-sites/{connected_site_id}/actions/disable-pixel
# operationId: postConnectedSitesIdActionsDisablePixel
export def "connected-sites-actions-disable-pixel post" [
  connected_site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connected-sites/($connected_site_id)/actions/disable-pixel")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List conversations
#
# GET /conversations
# DEPRECATED
# operationId: getConversations
@deprecated
export def "conversations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --has-unread-messages: string@has-unread-messages-completer # Whether the conversation has any unread messages.
  --list-id: string # The unique id for the list.
  --campaign-id: string # The unique id for the campaign.
]: nothing -> record<conversations: table<id: string, message_count: int, campaign_id: string, list_id: string, unread_messages: int, from_label: string, from_email: string, subject: string, last_message: record, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "has_unread_messages" $has_unread_messages "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "campaign_id" $campaign_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get conversation
#
# GET /conversations/{conversation_id}
# DEPRECATED
# operationId: getConversationsId
@deprecated
export def "conversations get" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, message_count: int, campaign_id: string, list_id: string, unread_messages: int, from_label: string, from_email: string, subject: string, last_message: record<from_label: string, from_email: string, subject: string, message: string, read: bool, timestamp: string>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/conversations/($conversation_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List messages
#
# GET /conversations/{conversation_id}/messages
# DEPRECATED
# operationId: getConversationsIdMessages
@deprecated
export def "conversations-messages list" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --is-read: string@is-read-completer # Whether a conversation message has been marked as read.
  --before-timestamp: string # Restrict the response to messages created before the set time. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00. (format: date-time)
  --since-timestamp: string # Restrict the response to messages created after the set time. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00. (format: date-time)
]: nothing -> record<conversation_messages: table<id: string, conversation_id: string, list_id: int, from_label: string, from_email: string, subject: string, message: string, read: bool, timestamp: string, _links: list>, conversation_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "is_read" $is_read "scalar") (serialize-qp "before_timestamp" $before_timestamp "scalar") (serialize-qp "since_timestamp" $since_timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/conversations/($conversation_id)/messages" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get message
#
# GET /conversations/{conversation_id}/messages/{message_id}
# DEPRECATED
# operationId: getConversationsIdMessagesId
@deprecated
export def "conversations-messages get" [
  conversation_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, conversation_id: string, list_id: int, from_label: string, from_email: string, subject: string, message: string, read: bool, timestamp: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/conversations/($conversation_id)/messages/($message_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Customer Journeys API trigger for a contact
#
# POST /customer-journeys/journeys/{journey_id}/steps/{step_id}/actions/trigger
# operationId: postCustomerJourneysJourneysIdStepsIdActionsTrigger
export def "customer-journeys-journeys-steps-actions-trigger post" [
  journey_id: int
  step_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  email_address: string # The list member's email address.
]: any -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customer-journeys/journeys/($journey_id)/steps/($step_id)/actions/trigger")
  let body = {email_address: $email_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List stored files
#
# GET /file-manager/files
# operationId: getFileManagerFiles
export def "file-manager-files list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --type: string # The file type for the File Manager file.
  --created-by: string # The Mailchimp account user who created the File Manager file.
  --before-created-at: string # Restrict the response to files created before the set date. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --since-created-at: string # Restrict the response to files created after the set date. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --sort-field: string@sort-field-completer-2 # Returns files sorted by the specified field.
  --sort-dir: string@sort-dir-completer # Determines the order direction for sorted results.
]: nothing -> record<files: table<id: int, folder_id: int, type: string, name: string, full_size_url: string, thumbnail_url: string, size: int, created_at: string, created_by: string, width: int, height: int, _links: list>, total_file_size: float, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "created_by" $created_by "scalar") (serialize-qp "before_created_at" $before_created_at "scalar") (serialize-qp "since_created_at" $since_created_at "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_dir" $sort_dir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/file-manager/files" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add file
#
# POST /file-manager/files
# operationId: postFileManagerFiles
export def "file-manager-files post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --folder-id: int # The id of the folder.
  name: string # The name of the file.
  file_data: string # The base64-encoded contents of the file.
]: any -> record<id: int, folder_id: int, type: string, name: string, full_size_url: string, thumbnail_url: string, size: int, created_at: string, created_by: string, width: int, height: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/file-manager/files")
  let body = {folder_id: $folder_id, name: $name, file_data: $file_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get file
#
# GET /file-manager/files/{file_id}
# operationId: getFileManagerFilesId
export def "file-manager-files get" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: int, folder_id: int, type: string, name: string, full_size_url: string, thumbnail_url: string, size: int, created_at: string, created_by: string, width: int, height: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/file-manager/files/($file_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update file
#
# PATCH /file-manager/files/{file_id}
# operationId: patchFileManagerFilesId
export def "file-manager-files patch" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --folder-id: int # The id of the folder. Setting `folder_id` to `0` will remove a file from its current folder.
  --name: string # The name of the file.
]: any -> record<id: int, folder_id: int, type: string, name: string, full_size_url: string, thumbnail_url: string, size: int, created_at: string, created_by: string, width: int, height: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/file-manager/files/($file_id)")
  let body = {folder_id: $folder_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete file
#
# DELETE /file-manager/files/{file_id}
# operationId: deleteFileManagerFilesId
export def "file-manager-files delete" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/file-manager/files/($file_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List folders
#
# GET /file-manager/folders
# operationId: getFileManagerFolders
export def "file-manager-folders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --created-by: string # The Mailchimp account user who created the File Manager file.
  --before-created-at: string # Restrict the response to files created before the set date. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --since-created-at: string # Restrict the response to files created after the set date. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
]: nothing -> record<folders: table<id: int, name: string, file_count: int, created_at: string, created_by: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "created_by" $created_by "scalar") (serialize-qp "before_created_at" $before_created_at "scalar") (serialize-qp "since_created_at" $since_created_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/file-manager/folders" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add folder
#
# POST /file-manager/folders
# operationId: postFileManagerFolders
export def "file-manager-folders post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The name of the folder.
]: any -> record<id: int, name: string, file_count: int, created_at: string, created_by: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/file-manager/folders")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get folder
#
# GET /file-manager/folders/{folder_id}
# operationId: getFileManagerFoldersId
export def "file-manager-folders get" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: int, name: string, file_count: int, created_at: string, created_by: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/file-manager/folders/($folder_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update folder
#
# PATCH /file-manager/folders/{folder_id}
# operationId: patchFileManagerFoldersId
export def "file-manager-folders patch" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The name of the folder.
]: any -> record<id: int, name: string, file_count: int, created_at: string, created_by: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/file-manager/folders/($folder_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete folder
#
# DELETE /file-manager/folders/{folder_id}
# operationId: deleteFileManagerFoldersId
export def "file-manager-folders delete" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/file-manager/folders/($folder_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List stored files
#
# GET /file-manager/folders/{folder_id}/files
# operationId: getFileManagerFoldersFiles
export def "file-manager-folders-files get" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --type: string # The file type for the File Manager file.
  --created-by: string # The Mailchimp account user who created the File Manager file.
  --before-created-at: string # Restrict the response to files created before the set date. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --since-created-at: string # Restrict the response to files created after the set date. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --sort-field: string@sort-field-completer-2 # Returns files sorted by the specified field.
  --sort-dir: string@sort-dir-completer # Determines the order direction for sorted results.
]: nothing -> record<files: table<id: int, folder_id: int, type: string, name: string, full_size_url: string, thumbnail_url: string, size: int, created_at: string, created_by: string, width: int, height: int, _links: list>, total_file_size: float, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "created_by" $created_by "scalar") (serialize-qp "before_created_at" $before_created_at "scalar") (serialize-qp "since_created_at" $since_created_at "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_dir" $sort_dir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/file-manager/folders/($folder_id)/files" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get lists info
#
# GET /lists
# operationId: getLists
export def "lists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --before-date-created: string # Restrict response to lists created before the set date. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --since-date-created: string # Restrict results to lists created after the set date. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --before-campaign-last-sent: string # Restrict results to lists created before the last campaign send date. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --since-campaign-last-sent: string # Restrict results to lists created after the last campaign send date. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --email: string # Restrict results to lists that include a specific subscriber's email address.
  --sort-field: string@sort-field-completer-3 # Returns files sorted by the specified field.
  --sort-dir: string@sort-dir-completer # Determines the order direction for sorted results.
  --has-ecommerce-store: oneof<nothing, bool> # Restrict results to lists that contain an active, connected, undeleted ecommerce store.
  --include-total-contacts: oneof<nothing, bool> # Return the total_contacts field in the stats response, which contains an approximate count of all contacts in any state.
]: nothing -> record<lists: table<id: string, web_id: int, name: string, contact: record, permission_reminder: string, use_archive_bar: bool, campaign_defaults: record, notify_on_subscribe: string, notify_on_unsubscribe: string, date_created: string, list_rating: int, email_type_option: bool, subscribe_url_short: string, subscribe_url_long: string, beamer_address: string, visibility: string, double_optin: bool, has_welcome: bool, marketing_permissions: bool, modules: list, stats: record, _links: list>, total_items: int, constraints: record<may_create: bool, max_instances: int, current_total_instances: int>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "before_date_created" $before_date_created "scalar") (serialize-qp "since_date_created" $since_date_created "scalar") (serialize-qp "before_campaign_last_sent" $before_campaign_last_sent "scalar") (serialize-qp "since_campaign_last_sent" $since_campaign_last_sent "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "has_ecommerce_store" $has_ecommerce_store "scalar") (serialize-qp "include_total_contacts" $include_total_contacts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add list
#
# POST /lists
# operationId: postLists
# --contact shape: {company: string, address1: string, address2?: string, city: string, state?: string, zip?: string, country: string, phone?: string}
# --campaign_defaults shape: {from_name: string, from_email: string, subject: string, language: string}
export def "lists post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The name of the list.
  contact: record # [Contact information displayed in campaign footers](https://mailchimp.com/help/about-campaign-footers/) to comply with international spam laws. — shape: {company: string, address1: string, address2?: string, city: string, state?: string, zip?: string, country: string, phone?: string}
  permission_reminder: string # The [permission reminder](https://mailchimp.com/help/edit-the-permission-reminder/) for the list.
  --use-archive-bar: oneof<nothing, bool> # Whether campaigns for this list use the [Archive Bar](https://mailchimp.com/help/about-email-campaign-archives-and-pages/) in archives by default. (default: false)
  campaign_defaults: record # [Default values for campaigns](https://mailchimp.com/help/edit-your-emails-subject-preview-text-from-name-or-from-email-address/) created for this list. — shape: {from_name: string, from_email: string, subject: string, language: string}
  --notify-on-subscribe: string # The email address to send [subscribe notifications](https://mailchimp.com/help/change-subscribe-and-unsubscribe-notifications/) to. (default: false)
  --notify-on-unsubscribe: string # The email address to send [unsubscribe notifications](https://mailchimp.com/help/change-subscribe-and-unsubscribe-notifications/) to. (default: false)
  --email-type-option: oneof<nothing, bool> # Whether the list supports [multiple formats for emails](https://mailchimp.com/help/change-audience-name-defaults/). When set to `true`, subscribers can choose whether they want to receive HTML or plain-text emails. When set to `false`, subscribers will receive HTML emails, with a plain-text alternative backup.
  --double-optin: oneof<nothing, bool> # Whether or not to require the subscriber to confirm subscription via email. (default: false)
  --marketing-permissions: oneof<nothing, bool> # Whether or not the list has marketing permissions (eg. GDPR) enabled. (default: false)
]: any -> record<id: string, web_id: int, name: string, contact: record<company: string, address1: string, address2: string, city: string, state: string, zip: string, country: string, phone: string>, permission_reminder: string, use_archive_bar: bool, campaign_defaults: record<from_name: string, from_email: string, subject: string, language: string>, notify_on_subscribe: string, notify_on_unsubscribe: string, date_created: string, list_rating: int, email_type_option: bool, subscribe_url_short: string, subscribe_url_long: string, beamer_address: string, visibility: string, double_optin: bool, has_welcome: bool, marketing_permissions: bool, modules: list<string>, stats: record<member_count: int, total_contacts: int, unsubscribe_count: int, cleaned_count: int, member_count_since_send: int, unsubscribe_count_since_send: int, cleaned_count_since_send: int, campaign_count: int, campaign_last_sent: string, merge_field_count: int, avg_sub_rate: float, avg_unsub_rate: float, target_sub_rate: float, open_rate: float, click_rate: float, last_sub_date: string, last_unsub_date: string>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lists")
  let body = {name: $name, contact: $contact, permission_reminder: $permission_reminder, use_archive_bar: $use_archive_bar, campaign_defaults: $campaign_defaults, notify_on_subscribe: $notify_on_subscribe, notify_on_unsubscribe: $notify_on_unsubscribe, email_type_option: $email_type_option, double_optin: $double_optin, marketing_permissions: $marketing_permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get list info
#
# GET /lists/{list_id}
# operationId: getListsId
export def "lists get" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --include-total-contacts: oneof<nothing, bool> # Return the total_contacts field in the stats response, which contains an approximate count of all contacts in any state.
]: nothing -> record<id: string, web_id: int, name: string, contact: record<company: string, address1: string, address2: string, city: string, state: string, zip: string, country: string, phone: string>, permission_reminder: string, use_archive_bar: bool, campaign_defaults: record<from_name: string, from_email: string, subject: string, language: string>, notify_on_subscribe: string, notify_on_unsubscribe: string, date_created: string, list_rating: int, email_type_option: bool, subscribe_url_short: string, subscribe_url_long: string, beamer_address: string, visibility: string, double_optin: bool, has_welcome: bool, marketing_permissions: bool, modules: list<string>, stats: record<member_count: int, total_contacts: int, unsubscribe_count: int, cleaned_count: int, member_count_since_send: int, unsubscribe_count_since_send: int, cleaned_count_since_send: int, campaign_count: int, campaign_last_sent: string, merge_field_count: int, avg_sub_rate: float, avg_unsub_rate: float, target_sub_rate: float, open_rate: float, click_rate: float, last_sub_date: string, last_unsub_date: string>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "include_total_contacts" $include_total_contacts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update lists
#
# PATCH /lists/{list_id}
# operationId: patchListsId
# --contact shape: {company: string, address1: string, address2?: string, city: string, state: string, zip: string, country: string, phone?: string}
# --campaign_defaults shape: {from_name: string, from_email: string, subject: string, language: string}
export def "lists patch" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The name of the list.
  contact: record # [Contact information displayed in campaign footers](https://mailchimp.com/help/about-campaign-footers/) to comply with international spam laws. — shape: {company: string, address1: string, address2?: string, city: string, state: string, zip: string, country: string, phone?: string}
  permission_reminder: string # The [permission reminder](https://mailchimp.com/help/edit-the-permission-reminder/) for the list.
  --use-archive-bar: oneof<nothing, bool> # Whether campaigns for this list use the [Archive Bar](https://mailchimp.com/help/about-email-campaign-archives-and-pages/) in archives by default. (default: false)
  campaign_defaults: record # [Default values for campaigns](https://mailchimp.com/help/edit-your-emails-subject-preview-text-from-name-or-from-email-address/) created for this list. — shape: {from_name: string, from_email: string, subject: string, language: string}
  --notify-on-subscribe: string # The email address to send [subscribe notifications](https://mailchimp.com/help/change-subscribe-and-unsubscribe-notifications/) to. (default: false)
  --notify-on-unsubscribe: string # The email address to send [unsubscribe notifications](https://mailchimp.com/help/change-subscribe-and-unsubscribe-notifications/) to. (default: false)
  --email-type-option: oneof<nothing, bool> # Whether the list supports [multiple formats for emails](https://mailchimp.com/help/change-audience-name-defaults/). When set to `true`, subscribers can choose whether they want to receive HTML or plain-text emails. When set to `false`, subscribers will receive HTML emails, with a plain-text alternative backup.
  --double-optin: oneof<nothing, bool> # Whether or not to require the subscriber to confirm subscription via email. (default: false)
  --marketing-permissions: oneof<nothing, bool> # Whether or not the list has marketing permissions (eg. GDPR) enabled. (default: false)
]: any -> record<id: string, web_id: int, name: string, contact: record<company: string, address1: string, address2: string, city: string, state: string, zip: string, country: string, phone: string>, permission_reminder: string, use_archive_bar: bool, campaign_defaults: record<from_name: string, from_email: string, subject: string, language: string>, notify_on_subscribe: string, notify_on_unsubscribe: string, date_created: string, list_rating: int, email_type_option: bool, subscribe_url_short: string, subscribe_url_long: string, beamer_address: string, visibility: string, double_optin: bool, has_welcome: bool, marketing_permissions: bool, modules: list<string>, stats: record<member_count: int, total_contacts: int, unsubscribe_count: int, cleaned_count: int, member_count_since_send: int, unsubscribe_count_since_send: int, cleaned_count_since_send: int, campaign_count: int, campaign_last_sent: string, merge_field_count: int, avg_sub_rate: float, avg_unsub_rate: float, target_sub_rate: float, open_rate: float, click_rate: float, last_sub_date: string, last_unsub_date: string>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)")
  let body = {name: $name, contact: $contact, permission_reminder: $permission_reminder, use_archive_bar: $use_archive_bar, campaign_defaults: $campaign_defaults, notify_on_subscribe: $notify_on_subscribe, notify_on_unsubscribe: $notify_on_unsubscribe, email_type_option: $email_type_option, double_optin: $double_optin, marketing_permissions: $marketing_permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete list
#
# DELETE /lists/{list_id}
# operationId: deleteListsId
export def "lists delete" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Batch subscribe or unsubscribe
#
# POST /lists/{list_id}
# operationId: postListsId
# --members item shape: {email_address?: string, email_type?: string, status?: "subscribed"|"unsubscribed"|"cleaned"|"pending"|"transactional", merge_fields?: record, interests?: record, language?: string, vip?: bool, location?: record, ip_signup?: string, timestamp_signup?: string, ip_opt?: string, timestamp_opt?: string}
export def "lists post-by-list_id" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --skip-merge-validation: oneof<nothing, bool> # If skip_merge_validation is true, member data will be accepted without merge field values, even if the merge field is usually required. This defaults to false.
  --skip-duplicate-check: oneof<nothing, bool> # If skip_duplicate_check is true, we will ignore duplicates sent in the request when using the batch sub/unsub on the lists endpoint. The status of the first appearance in the request will be saved. This defaults to false.
  members: list # An array of objects, each representing an email address and the subscription status for a specific list. Up to 500 members may be added or updated with each API call. — item shape: {email_address?: string, email_type?: string, status?: "subscribed"|"unsubscribed"|"cleaned"|"pending"|"transactional", merge_fields?: record, interests?: record, language?: string, vip?: bool, location?: record, ip_signup?: string, timestamp_signup?: string, ip_opt?: string, timestamp_opt?: string}
  --sync-tags: oneof<nothing, bool> # Whether this batch operation will replace all existing tags with tags in request.
  --update-existing: oneof<nothing, bool> # Whether this batch operation will change existing members' subscription status.
]: any -> record<new_members: table<id: string, contact_id: string, email_address: string, unique_email_id: string, email_type: string, status: string, merge_fields: record, interests: record, stats: record, ip_signup: string, timestamp_signup: string, ip_opt: string, timestamp_opt: string, member_rating: int, last_changed: string, language: string, vip: bool, email_client: string, location: record, last_note: record, tags_count: int, tags: list, list_id: string, _links: list>, updated_members: table<id: string, contact_id: string, email_address: string, unique_email_id: string, email_type: string, status: string, merge_fields: record, interests: record, stats: record, ip_signup: string, timestamp_signup: string, ip_opt: string, timestamp_opt: string, member_rating: int, last_changed: string, language: string, vip: bool, email_client: string, location: record, last_note: record, tags_count: int, tags: list, list_id: string, _links: list>, errors: table<email_address: string, error: string, error_code: string, field: string, field_message: string>, total_created: int, total_updated: int, error_count: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip_merge_validation" $skip_merge_validation "scalar") (serialize-qp "skip_duplicate_check" $skip_duplicate_check "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)" $qp)
  let body = {members: $members, sync_tags: $sync_tags, update_existing: $update_existing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List abuse reports
#
# GET /lists/{list_id}/abuse-reports
# operationId: getListsIdAbuseReports
export def "lists-abuse-reports list" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<abuse_reports: table<id: int, campaign_id: string, list_id: string, email_id: string, email_address: string, merge_fields: record, vip: bool, date: string, _links: list>, list_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/abuse-reports" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get abuse report
#
# GET /lists/{list_id}/abuse-reports/{report_id}
# operationId: getListsIdAbuseReportsId
export def "lists-abuse-reports get" [
  list_id: string
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<id: int, campaign_id: string, list_id: string, email_id: string, email_address: string, merge_fields: record, vip: bool, date: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/abuse-reports/($report_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List recent activity
#
# GET /lists/{list_id}/activity
# operationId: getListsIdActivity
export def "lists-activity get" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<activity: table<day: string, emails_sent: int, unique_opens: int, recipient_clicks: int, hard_bounce: int, soft_bounce: int, subs: int, unsubs: int, other_adds: int, other_removes: int, _links: list>, list_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/activity" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List top email clients
#
# GET /lists/{list_id}/clients
# operationId: getListsIdClients
export def "lists-clients get" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<clients: table<client: string, members: int>, list_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/clients" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List growth history data
#
# GET /lists/{list_id}/growth-history
# operationId: getListsIdGrowthHistory
export def "lists-growth-history list" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --sort-field: string@sort-field-completer-4 # Returns files sorted by the specified field.
  --sort-dir: string@sort-dir-completer # Determines the order direction for sorted results.
]: nothing -> record<history: table<list_id: string, month: string, existing: int, imports: int, optins: int, subscribed: int, unsubscribed: int, reconfirm: int, cleaned: int, pending: int, deleted: int, transactional: int, _links: list>, list_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_dir" $sort_dir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/growth-history" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get growth history by month
#
# GET /lists/{list_id}/growth-history/{month}
# operationId: getListsIdGrowthHistoryId
export def "lists-growth-history get" [
  list_id: string
  month: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<list_id: string, month: string, existing: int, imports: int, optins: int, subscribed: int, unsubscribed: int, reconfirm: int, cleaned: int, pending: int, deleted: int, transactional: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/growth-history/($month)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List interest categories
#
# GET /lists/{list_id}/interest-categories
# operationId: getListsIdInterestCategories
export def "lists-interest-categories list" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --type: string # Restrict results a type of interest group
  --sort-field: string@sort-field-completer-5 # Returns interest categories sorted by the specified field. Defaults to display_order.
  --sort-dir: string@sort-dir-completer # Determines the order direction for sorted results.
]: nothing -> record<list_id: string, categories: table<list_id: string, id: string, title: string, display_order: int, type: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_dir" $sort_dir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/interest-categories" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add interest category
#
# POST /lists/{list_id}/interest-categories
# operationId: postListsIdInterestCategories
export def "lists-interest-categories post" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  title: string # The text description of this category. This field appears on signup forms and is often phrased as a question.
  --display-order: int # The order that the categories are displayed in the list. Lower numbers display first.
  type: string@type-completer-1 # Determines how this category’s interests appear on signup forms.
]: any -> record<list_id: string, id: string, title: string, display_order: int, type: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/interest-categories")
  let body = {title: $title, display_order: $display_order, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get interest category info
#
# GET /lists/{list_id}/interest-categories/{interest_category_id}
# operationId: getListsIdInterestCategoriesId
export def "lists-interest-categories get" [
  list_id: string
  interest_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<list_id: string, id: string, title: string, display_order: int, type: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/interest-categories/($interest_category_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update interest category
#
# PATCH /lists/{list_id}/interest-categories/{interest_category_id}
# operationId: patchListsIdInterestCategoriesId
export def "lists-interest-categories patch" [
  list_id: string
  interest_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  title: string # The text description of this category. This field appears on signup forms and is often phrased as a question.
  --display-order: int # The order that the categories are displayed in the list. Lower numbers display first.
  type: string@type-completer-1 # Determines how this category’s interests appear on signup forms.
]: any -> record<list_id: string, id: string, title: string, display_order: int, type: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/interest-categories/($interest_category_id)")
  let body = {title: $title, display_order: $display_order, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete interest category
#
# DELETE /lists/{list_id}/interest-categories/{interest_category_id}
# operationId: deleteListsIdInterestCategoriesId
export def "lists-interest-categories delete" [
  list_id: string
  interest_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/interest-categories/($interest_category_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List interests in category
#
# GET /lists/{list_id}/interest-categories/{interest_category_id}/interests
# operationId: getListsIdInterestCategoriesIdInterests
export def "lists-interest-categories-interests list" [
  list_id: string
  interest_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<interests: table<category_id: string, list_id: string, id: string, name: string, subscriber_count: string, display_order: int, _links: list>, list_id: string, category_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/interest-categories/($interest_category_id)/interests" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add interest in category
#
# POST /lists/{list_id}/interest-categories/{interest_category_id}/interests
# operationId: postListsIdInterestCategoriesIdInterests
export def "lists-interest-categories-interests post" [
  list_id: string
  interest_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The name of the interest. This can be shown publicly on a subscription form.
  --display-order: int # The display order for interests.
]: any -> record<category_id: string, list_id: string, id: string, name: string, subscriber_count: string, display_order: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/interest-categories/($interest_category_id)/interests")
  let body = {name: $name, display_order: $display_order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get interest in category
#
# GET /lists/{list_id}/interest-categories/{interest_category_id}/interests/{interest_id}
# operationId: getListsIdInterestCategoriesIdInterestsId
export def "lists-interest-categories-interests get" [
  list_id: string
  interest_category_id: string
  interest_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<category_id: string, list_id: string, id: string, name: string, subscriber_count: string, display_order: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/interest-categories/($interest_category_id)/interests/($interest_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update interest in category
#
# PATCH /lists/{list_id}/interest-categories/{interest_category_id}/interests/{interest_id}
# operationId: patchListsIdInterestCategoriesIdInterestsId
export def "lists-interest-categories-interests patch" [
  list_id: string
  interest_category_id: string
  interest_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The name of the interest. This can be shown publicly on a subscription form.
  --display-order: int # The display order for interests.
]: any -> record<category_id: string, list_id: string, id: string, name: string, subscriber_count: string, display_order: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/interest-categories/($interest_category_id)/interests/($interest_id)")
  let body = {name: $name, display_order: $display_order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete interest in category
#
# DELETE /lists/{list_id}/interest-categories/{interest_category_id}/interests/{interest_id}
# operationId: deleteListsIdInterestCategoriesIdInterestsId
export def "lists-interest-categories-interests delete" [
  list_id: string
  interest_category_id: string
  interest_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/interest-categories/($interest_category_id)/interests/($interest_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List segments
#
# GET /lists/{list_id}/segments
# operationId: previewASegment
export def "lists-segments previewASegment" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --type: string # Limit results based on segment type.
  --since-created-at: string # Restrict results to segments created after the set time. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --before-created-at: string # Restrict results to segments created before the set time. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --include-cleaned: oneof<nothing, bool> # Include cleaned members in response (e.g. false)
  --include-transactional: oneof<nothing, bool> # Include transactional members in response (e.g. false)
  --include-unsubscribed: oneof<nothing, bool> # Include unsubscribed members in response (e.g. false)
  --since-updated-at: string # Restrict results to segments update after the set time. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --before-updated-at: string # Restrict results to segments update before the set time. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --exclude-type: string@exclude-type-completer # Exclude results based on segment type. For example, use `exclude_type=static` to exclude tags from the response.
]: nothing -> record<segments: table<id: int, name: string, member_count: int, type: string, created_at: string, updated_at: string, options: record, list_id: string, _links: list>, list_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "since_created_at" $since_created_at "scalar") (serialize-qp "before_created_at" $before_created_at "scalar") (serialize-qp "include_cleaned" $include_cleaned "scalar") (serialize-qp "include_transactional" $include_transactional "scalar") (serialize-qp "include_unsubscribed" $include_unsubscribed "scalar") (serialize-qp "since_updated_at" $since_updated_at "scalar") (serialize-qp "before_updated_at" $before_updated_at "scalar") (serialize-qp "exclude_type" $exclude_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/segments" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add segment
#
# POST /lists/{list_id}/segments
# operationId: postListsIdSegments
# --options shape: {match?: "any"|"all", conditions?: list}
export def "lists-segments post-by-list_id" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The name of the segment.
  --static-segment: list # An array of emails to be used for a static segment. Any emails provided that are not present on the list will be ignored. Passing an empty array will create a static segment without any subscribers. This field cannot be provided with the options field.
  --options: record # The [conditions of the segment](https://mailchimp.com/help/save-and-manage-segments/). Static and fuzzy segments don't have conditions. — shape: {match?: "any"|"all", conditions?: list}
]: any -> record<id: int, name: string, member_count: int, type: string, created_at: string, updated_at: string, options: record<match: string, conditions: list<any>>, list_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/segments")
  let body = {name: $name, static_segment: $static_segment, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get segment info
#
# GET /lists/{list_id}/segments/{segment_id}
# operationId: getListsIdSegmentsId
export def "lists-segments get" [
  list_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --include-cleaned: oneof<nothing, bool> # Include cleaned members in response (e.g. false)
  --include-transactional: oneof<nothing, bool> # Include transactional members in response (e.g. false)
  --include-unsubscribed: oneof<nothing, bool> # Include unsubscribed members in response (e.g. false)
]: nothing -> record<id: int, name: string, member_count: int, type: string, created_at: string, updated_at: string, options: record<match: string, conditions: list<any>>, list_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "include_cleaned" $include_cleaned "scalar") (serialize-qp "include_transactional" $include_transactional "scalar") (serialize-qp "include_unsubscribed" $include_unsubscribed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/segments/($segment_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete segment
#
# DELETE /lists/{list_id}/segments/{segment_id}
# operationId: deleteListsIdSegmentsId
export def "lists-segments delete" [
  list_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/segments/($segment_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update segment
#
# PATCH /lists/{list_id}/segments/{segment_id}
# operationId: patchListsIdSegmentsId
# --options shape: {match?: "any"|"all", conditions?: list}
export def "lists-segments patch" [
  list_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The name of the segment.
  --static-segment: list # An array of emails to be used for a static segment. Any emails provided that are not present on the list will be ignored. Passing an empty array for an existing static segment will reset that segment and remove all members. This field cannot be provided with the `options` field.
  --options: record # The [conditions of the segment](https://mailchimp.com/help/save-and-manage-segments/). Static and fuzzy segments don't have conditions. — shape: {match?: "any"|"all", conditions?: list}
]: any -> record<id: int, name: string, member_count: int, type: string, created_at: string, updated_at: string, options: record<match: string, conditions: list<any>>, list_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/segments/($segment_id)")
  let body = {name: $name, static_segment: $static_segment, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Batch add or remove members
#
# POST /lists/{list_id}/segments/{segment_id}
# operationId: postListsIdSegmentsId
export def "lists-segments post-by-list_id-segment_id" [
  list_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --members-to-add: list # An array of emails to be used for a static segment. Any emails provided that are not present on the list will be ignored. A maximum of 500 members can be sent.
  --members-to-remove: list # An array of emails to be used for a static segment. Any emails provided that are not present on the list will be ignored. A maximum of 500 members can be sent.
]: any -> record<members_added: table<id: string, contact_id: string, email_address: string, unique_email_id: string, email_type: string, status: string, merge_fields: record, interests: record, stats: record, ip_signup: string, timestamp_signup: string, ip_opt: string, timestamp_opt: string, member_rating: int, last_changed: string, language: string, vip: bool, email_client: string, location: record, last_note: record, tags_count: int, tags: list, list_id: string, _links: list>, members_removed: table<id: string, contact_id: string, email_address: string, unique_email_id: string, email_type: string, status: string, merge_fields: record, interests: record, stats: record, ip_signup: string, timestamp_signup: string, ip_opt: string, timestamp_opt: string, member_rating: int, last_changed: string, language: string, vip: bool, email_client: string, location: record, last_note: record, tags_count: int, tags: list, list_id: string, _links: list>, errors: table<email_addresses: list, error: string>, total_added: int, total_removed: int, error_count: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/segments/($segment_id)")
  let body = {members_to_add: $members_to_add, members_to_remove: $members_to_remove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List members in segment
#
# GET /lists/{list_id}/segments/{segment_id}/members
# operationId: getListsIdSegmentsIdMembers
export def "lists-segments-members get" [
  list_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --include-cleaned: oneof<nothing, bool> # Include cleaned members in response (e.g. false)
  --include-transactional: oneof<nothing, bool> # Include transactional members in response (e.g. false)
  --include-unsubscribed: oneof<nothing, bool> # Include unsubscribed members in response (e.g. false)
]: nothing -> record<members: table<id: string, email_address: string, full_name: string, unique_email_id: string, email_type: string, status: string, merge_fields: record, interests: record, stats: record, ip_signup: string, timestamp_signup: string, ip_opt: string, timestamp_opt: string, member_rating: int, last_changed: string, language: string, vip: bool, email_client: string, location: record, last_note: record, list_id: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "include_cleaned" $include_cleaned "scalar") (serialize-qp "include_transactional" $include_transactional "scalar") (serialize-qp "include_unsubscribed" $include_unsubscribed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/segments/($segment_id)/members" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add member to segment
#
# POST /lists/{list_id}/segments/{segment_id}/members
# operationId: postListsIdSegmentsIdMembers
export def "lists-segments-members post" [
  list_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  email_address: string # Email address for a subscriber.
]: any -> record<id: string, email_address: string, full_name: string, unique_email_id: string, email_type: string, status: string, merge_fields: record, interests: record, stats: record<avg_open_rate: float, avg_click_rate: float>, ip_signup: string, timestamp_signup: string, ip_opt: string, timestamp_opt: string, member_rating: int, last_changed: string, language: string, vip: bool, email_client: string, location: record<latitude: float, longitude: float, gmtoff: int, dstoff: int, country_code: string, timezone: string>, last_note: record<note_id: int, created_at: string, created_by: string, note: string>, list_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/segments/($segment_id)/members")
  let body = {email_address: $email_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove list member from segment
#
# DELETE /lists/{list_id}/segments/{segment_id}/members/{subscriber_hash}
# operationId: deleteListsIdSegmentsIdMembersId
export def "lists-segments-members delete" [
  list_id: string
  segment_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/segments/($segment_id)/members/($subscriber_hash)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for tags on a list by name.
#
# GET /lists/{list_id}/tag-search
# operationId: searchTagsByName
export def "lists-tag-search searchTagsByName" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --name: string # The search query used to filter tags.  The search query will be compared to each tag as a prefix, so all tags that have a name starting with this field will be returned.
]: nothing -> record<tags: table<id: int, name: string>, total_items: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/tag-search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List members info
#
# GET /lists/{list_id}/members
# operationId: getListsIdMembers
export def "lists-members list" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --email-type: string # The email type.
  --status: string@status-completer-2 # The subscriber's status.
  --since-timestamp-opt: string # Restrict results to subscribers who opted-in after the set timeframe. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --before-timestamp-opt: string # Restrict results to subscribers who opted-in before the set timeframe. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --since-last-changed: string # Restrict results to subscribers whose information changed after the set timeframe. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --before-last-changed: string # Restrict results to subscribers whose information changed before the set timeframe. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --unique-email-id: string # A unique identifier for the email address across all Mailchimp lists.
  --vip-only: oneof<nothing, bool> # A filter to return only the list's VIP members. Passing `true` will restrict results to VIP list members, passing `false` will return all list members.
  --interest-category-id: string # The unique id for the interest category.
  --interest-ids: string # Used to filter list members by interests. Must be accompanied by interest_category_id and interest_match. The value must be a comma separated list of interest ids present for any supplied interest categories.
  --interest-match: string@interest-match-completer # Used to filter list members by interests. Must be accompanied by interest_category_id and interest_ids. "any" will match a member with any of the interest supplied, "all" will only match members with every interest supplied, and "none" will match members without any of the interest supplied.
  --sort-field: string@sort-field-completer-6 # Returns files sorted by the specified field.
  --sort-dir: string@sort-dir-completer # Determines the order direction for sorted results.
  --since-last-campaign: oneof<nothing, bool> # Filter subscribers by those subscribed/unsubscribed/pending/cleaned since last email campaign send. Member status is required to use this filter.
  --unsubscribed-since: string # Filter subscribers by those unsubscribed since a specific date. Using any status other than unsubscribed with this filter will result in an error.
]: nothing -> record<members: table<id: string, email_address: string, unique_email_id: string, contact_id: string, full_name: string, web_id: int, email_type: string, status: string, unsubscribe_reason: string, consents_to_one_to_one_messaging: bool, sms_phone_number: string, sms_subscription_status: string, sms_subscription_last_updated: string, merge_fields: record, interests: record, stats: record, ip_signup: string, timestamp_signup: string, ip_opt: string, timestamp_opt: string, member_rating: int, last_changed: string, language: string, vip: bool, email_client: string, location: record, marketing_permissions: list, last_note: record, source: string, tags_count: int, tags: list, list_id: string, _links: list>, list_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "email_type" $email_type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "since_timestamp_opt" $since_timestamp_opt "scalar") (serialize-qp "before_timestamp_opt" $before_timestamp_opt "scalar") (serialize-qp "since_last_changed" $since_last_changed "scalar") (serialize-qp "before_last_changed" $before_last_changed "scalar") (serialize-qp "unique_email_id" $unique_email_id "scalar") (serialize-qp "vip_only" $vip_only "scalar") (serialize-qp "interest_category_id" $interest_category_id "scalar") (serialize-qp "interest_ids" $interest_ids "scalar") (serialize-qp "interest_match" $interest_match "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "since_last_campaign" $since_last_campaign "scalar") (serialize-qp "unsubscribed_since" $unsubscribed_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/members" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add member to list
#
# POST /lists/{list_id}/members
# operationId: postListsIdMembers
# --location shape: {latitude?: float, longitude?: float}
# --marketing_permissions item shape: {marketing_permission_id?: string, enabled?: bool}
export def "lists-members post" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --skip-merge-validation: oneof<nothing, bool> # If skip_merge_validation is true, member data will be accepted without merge field values, even if the merge field is usually required. This defaults to false.
  email_address: string # Email address for a subscriber.
  --email-type: string # Type of email this member asked to get ('html' or 'text').
  status: string@status-completer-3 # Subscriber's current status.
  --merge-fields: record # A dictionary of merge fields where the keys are the merge tags. See the [Merge Fields documentation](https://mailchimp.com/developer/marketing/docs/merge-fields/#structure) for more about the structure.
  --interests: record # The key of this object's properties is the ID of the interest in question.
  --language: string # If set/detected, the [subscriber's language](https://mailchimp.com/help/view-and-edit-contact-languages/).
  --vip: oneof<nothing, bool> # [VIP status](https://mailchimp.com/help/designate-and-send-to-vip-contacts/) for subscriber.
  --location: record # Subscriber location information. — shape: {latitude?: float, longitude?: float}
  --marketing-permissions: list # The marketing permissions for the subscriber. — item shape: {marketing_permission_id?: string, enabled?: bool}
  --ip-signup: string # IP address the subscriber signed up from.
  --timestamp-signup: string # The date and time the subscriber signed up for the list in ISO 8601 format. (format: date-time)
  --ip-opt: string # The IP address the subscriber used to confirm their opt-in status.
  --timestamp-opt: string # The date and time the subscriber confirmed their opt-in status in ISO 8601 format. (format: date-time)
  --tags: list # The tags that are associated with a member.
]: any -> record<id: string, email_address: string, unique_email_id: string, contact_id: string, full_name: string, web_id: int, email_type: string, status: string, unsubscribe_reason: string, consents_to_one_to_one_messaging: bool, sms_phone_number: string, sms_subscription_status: string, sms_subscription_last_updated: string, merge_fields: record, interests: record, stats: record<avg_open_rate: float, avg_click_rate: float, ecommerce_data: record<total_revenue: float, number_of_orders: float, currency_code: string>>, ip_signup: string, timestamp_signup: string, ip_opt: string, timestamp_opt: string, member_rating: int, last_changed: string, language: string, vip: bool, email_client: string, location: record<latitude: float, longitude: float, gmtoff: int, dstoff: int, country_code: string, timezone: string, region: string>, marketing_permissions: table<marketing_permission_id: string, text: string, enabled: bool>, last_note: record<note_id: int, created_at: string, created_by: string, note: string>, source: string, tags_count: int, tags: table<id: int, name: string>, list_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip_merge_validation" $skip_merge_validation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/members" $qp)
  let body = {email_address: $email_address, email_type: $email_type, status: $status, merge_fields: $merge_fields, interests: $interests, language: $language, vip: $vip, location: $location, marketing_permissions: $marketing_permissions, ip_signup: $ip_signup, timestamp_signup: $timestamp_signup, ip_opt: $ip_opt, timestamp_opt: $timestamp_opt, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get member info
#
# GET /lists/{list_id}/members/{subscriber_hash}
# operationId: getListsIdMembersId
export def "lists-members get" [
  list_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, email_address: string, unique_email_id: string, contact_id: string, full_name: string, web_id: int, email_type: string, status: string, unsubscribe_reason: string, consents_to_one_to_one_messaging: bool, sms_phone_number: string, sms_subscription_status: string, sms_subscription_last_updated: string, merge_fields: record, interests: record, stats: record<avg_open_rate: float, avg_click_rate: float, ecommerce_data: record<total_revenue: float, number_of_orders: float, currency_code: string>>, ip_signup: string, timestamp_signup: string, ip_opt: string, timestamp_opt: string, member_rating: int, last_changed: string, language: string, vip: bool, email_client: string, location: record<latitude: float, longitude: float, gmtoff: int, dstoff: int, country_code: string, timezone: string, region: string>, marketing_permissions: table<marketing_permission_id: string, text: string, enabled: bool>, last_note: record<note_id: int, created_at: string, created_by: string, note: string>, source: string, tags_count: int, tags: table<id: int, name: string>, list_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/members/($subscriber_hash)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or update list member
#
# PUT /lists/{list_id}/members/{subscriber_hash}
# operationId: putListsIdMembersId
# --location shape: {latitude?: float, longitude?: float}
# --marketing_permissions item shape: {marketing_permission_id?: string, enabled?: bool}
export def "lists-members put" [
  list_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --skip-merge-validation: oneof<nothing, bool> # If skip_merge_validation is true, member data will be accepted without merge field values, even if the merge field is usually required. This defaults to false.
  email_address: string # Email address for a subscriber. This value is required only if the email address is not already present on the list.
  status_if_new: string@status-if-new-completer # Subscriber's status. This value is required only if the email address is not already present on the list.
  --email-type: string # Type of email this member asked to get ('html' or 'text').
  --status: string@status-completer-3 # Subscriber's current status.
  --merge-fields: record # A dictionary of merge fields where the keys are the merge tags. See the [Merge Fields documentation](https://mailchimp.com/developer/marketing/docs/merge-fields/#structure) for more about the structure.
  --interests: record # The key of this object's properties is the ID of the interest in question.
  --language: string # If set/detected, the [subscriber's language](https://mailchimp.com/help/view-and-edit-contact-languages/).
  --vip: oneof<nothing, bool> # [VIP status](https://mailchimp.com/help/designate-and-send-to-vip-contacts/) for subscriber.
  --location: record # Subscriber location information. — shape: {latitude?: float, longitude?: float}
  --marketing-permissions: list # The marketing permissions for the subscriber. — item shape: {marketing_permission_id?: string, enabled?: bool}
  --ip-signup: string # IP address the subscriber signed up from.
  --timestamp-signup: string # The date and time the subscriber signed up for the list in ISO 8601 format. (format: date-time)
  --ip-opt: string # The IP address the subscriber used to confirm their opt-in status.
  --timestamp-opt: string # The date and time the subscriber confirmed their opt-in status in ISO 8601 format. (format: date-time)
]: any -> record<id: string, email_address: string, unique_email_id: string, contact_id: string, full_name: string, web_id: int, email_type: string, status: string, unsubscribe_reason: string, consents_to_one_to_one_messaging: bool, sms_phone_number: string, sms_subscription_status: string, sms_subscription_last_updated: string, merge_fields: record, interests: record, stats: record<avg_open_rate: float, avg_click_rate: float, ecommerce_data: record<total_revenue: float, number_of_orders: float, currency_code: string>>, ip_signup: string, timestamp_signup: string, ip_opt: string, timestamp_opt: string, member_rating: int, last_changed: string, language: string, vip: bool, email_client: string, location: record<latitude: float, longitude: float, gmtoff: int, dstoff: int, country_code: string, timezone: string, region: string>, marketing_permissions: table<marketing_permission_id: string, text: string, enabled: bool>, last_note: record<note_id: int, created_at: string, created_by: string, note: string>, source: string, tags_count: int, tags: table<id: int, name: string>, list_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip_merge_validation" $skip_merge_validation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/members/($subscriber_hash)" $qp)
  let body = {email_address: $email_address, status_if_new: $status_if_new, email_type: $email_type, status: $status, merge_fields: $merge_fields, interests: $interests, language: $language, vip: $vip, location: $location, marketing_permissions: $marketing_permissions, ip_signup: $ip_signup, timestamp_signup: $timestamp_signup, ip_opt: $ip_opt, timestamp_opt: $timestamp_opt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update list member
#
# PATCH /lists/{list_id}/members/{subscriber_hash}
# operationId: patchListsIdMembersId
# --location shape: {latitude?: float, longitude?: float}
# --marketing_permissions item shape: {marketing_permission_id?: string, enabled?: bool}
export def "lists-members patch" [
  list_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --skip-merge-validation: oneof<nothing, bool> # If skip_merge_validation is true, member data will be accepted without merge field values, even if the merge field is usually required. This defaults to false.
  --email-address: string # Email address for a subscriber.
  --email-type: string # Type of email this member asked to get ('html' or 'text').
  --status: string@status-completer-4 # Subscriber's current status.
  --merge-fields: record # A dictionary of merge fields where the keys are the merge tags. See the [Merge Fields documentation](https://mailchimp.com/developer/marketing/docs/merge-fields/#structure) for more about the structure.
  --interests: record # The key of this object's properties is the ID of the interest in question.
  --language: string # If set/detected, the [subscriber's language](https://mailchimp.com/help/view-and-edit-contact-languages/).
  --vip: oneof<nothing, bool> # [VIP status](https://mailchimp.com/help/designate-and-send-to-vip-contacts/) for subscriber.
  --location: record # Subscriber location information. — shape: {latitude?: float, longitude?: float}
  --marketing-permissions: list # The marketing permissions for the subscriber. — item shape: {marketing_permission_id?: string, enabled?: bool}
  --ip-signup: string # IP address the subscriber signed up from.
  --timestamp-signup: string # The date and time the subscriber signed up for the list in ISO 8601 format. (format: date-time)
  --ip-opt: string # The IP address the subscriber used to confirm their opt-in status.
  --timestamp-opt: string # The date and time the subscriber confirmed their opt-in status in ISO 8601 format. (format: date-time)
]: any -> record<id: string, email_address: string, unique_email_id: string, contact_id: string, full_name: string, web_id: int, email_type: string, status: string, unsubscribe_reason: string, consents_to_one_to_one_messaging: bool, sms_phone_number: string, sms_subscription_status: string, sms_subscription_last_updated: string, merge_fields: record, interests: record, stats: record<avg_open_rate: float, avg_click_rate: float, ecommerce_data: record<total_revenue: float, number_of_orders: float, currency_code: string>>, ip_signup: string, timestamp_signup: string, ip_opt: string, timestamp_opt: string, member_rating: int, last_changed: string, language: string, vip: bool, email_client: string, location: record<latitude: float, longitude: float, gmtoff: int, dstoff: int, country_code: string, timezone: string, region: string>, marketing_permissions: table<marketing_permission_id: string, text: string, enabled: bool>, last_note: record<note_id: int, created_at: string, created_by: string, note: string>, source: string, tags_count: int, tags: table<id: int, name: string>, list_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip_merge_validation" $skip_merge_validation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/members/($subscriber_hash)" $qp)
  let body = {email_address: $email_address, email_type: $email_type, status: $status, merge_fields: $merge_fields, interests: $interests, language: $language, vip: $vip, location: $location, marketing_permissions: $marketing_permissions, ip_signup: $ip_signup, timestamp_signup: $timestamp_signup, ip_opt: $ip_opt, timestamp_opt: $timestamp_opt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive list member
#
# DELETE /lists/{list_id}/members/{subscriber_hash}
# operationId: deleteListsIdMembersId
export def "lists-members delete" [
  list_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/members/($subscriber_hash)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View recent activity 50
#
# GET /lists/{list_id}/members/{subscriber_hash}/activity
# operationId: getListsIdMembersIdActivity
export def "lists-members-activity get" [
  list_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --action: list # A comma seperated list of actions to return.
]: nothing -> record<activity: table<action: string, timestamp: string, url: string, type: string, campaign_id: string, title: string, parent_campaign: string>, email_id: string, contact_id: string, list_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "action" $action "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/members/($subscriber_hash)/activity" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View recent activity
#
# GET /lists/{list_id}/members/{subscriber_hash}/activity-feed
# operationId: getListsIdMembersIdActivityFeed
export def "lists-members-activity-feed get" [
  list_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --activity-filters: list # A comma-separated list of activity filters that correspond to a set of activity types, e.g "?activity_filters=open,bounce,click".
]: nothing -> record<activity: list<any>, email_id: string, list_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "activity_filters" $activity_filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/members/($subscriber_hash)/activity-feed" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List member tags
#
# GET /lists/{list_id}/members/{subscriber_hash}/tags
# operationId: getListMemberTags
export def "lists-members-tags get" [
  list_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<tags: table<id: int, name: string, date_added: string>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/members/($subscriber_hash)/tags" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or remove member tags
#
# POST /lists/{list_id}/members/{subscriber_hash}/tags
# operationId: postListMemberTags
# --tags item shape: {name: string, status: "inactive"|"active"}
export def "lists-members-tags post" [
  list_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  tags: list # A list of tags assigned to the list member. — item shape: {name: string, status: "inactive"|"active"}
  --is-syncing: oneof<nothing, bool> # When is_syncing is true, automations based on the tags in the request will not fire
]: any -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/members/($subscriber_hash)/tags")
  let body = {tags: $tags, is_syncing: $is_syncing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List member events
#
# GET /lists/{list_id}/members/{subscriber_hash}/events
# operationId: getListsIdMembersIdEvents
export def "lists-members-events get" [
  list_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<events: table<occurred_at: string, name: string, properties: record>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/members/($subscriber_hash)/events" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add event
#
# POST /lists/{list_id}/members/{subscriber_hash}/events
# operationId: postListMemberEvents
export def "lists-members-events post" [
  list_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The name for this type of event ('purchased', 'visited', etc). Must be 2-30 characters in length
  --properties: record # An optional list of properties
  --is-syncing: oneof<nothing, bool> # Events created with the is_syncing value set to `true` will not trigger automations.
  --occurred-at: string # The date and time the event occurred in ISO 8601 format. (format: date-time)
]: any -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/members/($subscriber_hash)/events")
  let body = {name: $name, properties: $properties, is_syncing: $is_syncing, occurred_at: $occurred_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List member goal events
#
# GET /lists/{list_id}/members/{subscriber_hash}/goals
# operationId: getListsIdMembersIdGoals
export def "lists-members-goals get" [
  list_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<goals: table<goal_id: int, event: string, last_visited_at: string, data: string>, list_id: string, email_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/members/($subscriber_hash)/goals" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List recent member notes
#
# GET /lists/{list_id}/members/{subscriber_hash}/notes
# operationId: getListsIdMembersIdNotes
export def "lists-members-notes list" [
  list_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --sort-field: string@sort-field-completer-7 # Returns notes sorted by the specified field.
  --sort-dir: string@sort-dir-completer # Determines the order direction for sorted results.
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<notes: table<id: int, created_at: string, created_by: string, updated_at: string, note: string, list_id: string, email_id: string, contact_id: string, _links: list>, email_id: string, list_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/members/($subscriber_hash)/notes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add member note
#
# POST /lists/{list_id}/members/{subscriber_hash}/notes
# operationId: postListsIdMembersIdNotes
export def "lists-members-notes post" [
  list_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --note: string # The content of the note. Note length is limited to 1,000 characters.
]: any -> record<id: int, created_at: string, created_by: string, updated_at: string, note: string, list_id: string, email_id: string, contact_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/members/($subscriber_hash)/notes")
  let body = {note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get member note
#
# GET /lists/{list_id}/members/{subscriber_hash}/notes/{note_id}
# operationId: getListsIdMembersIdNotesId
export def "lists-members-notes get" [
  list_id: string
  subscriber_hash: string
  note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: int, created_at: string, created_by: string, updated_at: string, note: string, list_id: string, email_id: string, contact_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/members/($subscriber_hash)/notes/($note_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update note
#
# PATCH /lists/{list_id}/members/{subscriber_hash}/notes/{note_id}
# operationId: patchListsIdMembersIdNotesId
export def "lists-members-notes patch" [
  list_id: string
  subscriber_hash: string
  note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --note: string # The content of the note. Note length is limited to 1,000 characters.
]: any -> record<id: int, created_at: string, created_by: string, updated_at: string, note: string, list_id: string, email_id: string, contact_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/members/($subscriber_hash)/notes/($note_id)")
  let body = {note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete note
#
# DELETE /lists/{list_id}/members/{subscriber_hash}/notes/{note_id}
# operationId: deleteListsIdMembersIdNotesId
export def "lists-members-notes delete" [
  list_id: string
  subscriber_hash: string
  note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/members/($subscriber_hash)/notes/($note_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete list member
#
# POST /lists/{list_id}/members/{subscriber_hash}/actions/delete-permanent
# operationId: postListsIdMembersHashActionsDeletePermanent
export def "lists-members-actions-delete-permanent post" [
  list_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/members/($subscriber_hash)/actions/delete-permanent")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List merge fields
#
# GET /lists/{list_id}/merge-fields
# operationId: getListsIdMergeFields
export def "lists-merge-fields list" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --type: string # The merge field type.
  --required: oneof<nothing, bool> # Whether it's a required merge field.
]: nothing -> record<merge_fields: table<merge_id: int, tag: string, name: string, type: string, required: bool, default_value: string, public: bool, display_order: int, options: record, help_text: string, list_id: string, total_items: int, merge_field_limit: int, _links: list>, list_id: string, total_items: int, merge_field_limit: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "required" $required "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/merge-fields" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add merge field
#
# POST /lists/{list_id}/merge-fields
# operationId: postListsIdMergeFields
# --options shape: {default_country?: int, phone_format?: string, date_format?: string, choices?: list, size?: int}
export def "lists-merge-fields post" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --tag: string # The merge tag used for Mailchimp campaigns and [adding contact information](https://mailchimp.com/developer/marketing/docs/merge-fields/#add-merge-data-to-contacts).
  name: string # The name of the merge field (audience field).
  type: string@type-completer-2 # The [type](https://mailchimp.com/developer/marketing/docs/merge-fields/#structure) for the merge field.
  --required: oneof<nothing, bool> # Whether the merge field is required to import a contact.
  --default-value: string # The default value for the merge field if `null`.
  --public: oneof<nothing, bool> # Whether the merge field is displayed on the signup form.
  --display-order: int # The order that the merge field displays on the list signup form.
  --options: record # Extra options for some merge field types. — shape: {default_country?: int, phone_format?: string, date_format?: string, choices?: list, size?: int}
  --help-text: string # Extra text to help the subscriber fill out the form.
]: any -> record<merge_id: int, tag: string, name: string, type: string, required: bool, default_value: string, public: bool, display_order: int, options: record<default_country: int, phone_format: string, date_format: string, choices: list<string>, size: int>, help_text: string, list_id: string, total_items: int, merge_field_limit: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/merge-fields")
  let body = {tag: $tag, name: $name, type: $type, required: $required, default_value: $default_value, public: $public, display_order: $display_order, options: $options, help_text: $help_text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get merge field
#
# GET /lists/{list_id}/merge-fields/{merge_id}
# operationId: getListsIdMergeFieldsId
export def "lists-merge-fields get" [
  list_id: string
  merge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
]: nothing -> record<merge_id: int, tag: string, name: string, type: string, required: bool, default_value: string, public: bool, display_order: int, options: record<default_country: int, phone_format: string, date_format: string, choices: list<string>, size: int>, help_text: string, list_id: string, total_items: int, merge_field_limit: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/merge-fields/($merge_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update merge field
#
# PATCH /lists/{list_id}/merge-fields/{merge_id}
# operationId: patchListsIdMergeFieldsId
# --options shape: {default_country?: int, phone_format?: string, date_format?: string, choices?: list}
export def "lists-merge-fields patch" [
  list_id: string
  merge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --tag: string # The merge tag used for Mailchimp campaigns and [adding contact information](https://mailchimp.com/developer/marketing/docs/merge-fields/#add-merge-data-to-contacts).
  name: string # The name of the merge field (audience field).
  --required: oneof<nothing, bool> # Whether the merge field is required to import a contact.
  --default-value: string # The default value for the merge field if `null`.
  --public: oneof<nothing, bool> # Whether the merge field is displayed on the signup form.
  --display-order: int # The order that the merge field displays on the list signup form.
  --options: record # Extra options for some merge field types. — shape: {default_country?: int, phone_format?: string, date_format?: string, choices?: list}
  --help-text: string # Extra text to help the subscriber fill out the form.
]: any -> record<merge_id: int, tag: string, name: string, type: string, required: bool, default_value: string, public: bool, display_order: int, options: record<default_country: int, phone_format: string, date_format: string, choices: list<string>, size: int>, help_text: string, list_id: string, total_items: int, merge_field_limit: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/merge-fields/($merge_id)")
  let body = {tag: $tag, name: $name, required: $required, default_value: $default_value, public: $public, display_order: $display_order, options: $options, help_text: $help_text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete merge field
#
# DELETE /lists/{list_id}/merge-fields/{merge_id}
# operationId: deleteListsIdMergeFieldsId
export def "lists-merge-fields delete" [
  list_id: string
  merge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/merge-fields/($merge_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List webhooks
#
# GET /lists/{list_id}/webhooks
# operationId: getListsIdWebhooks
export def "lists-webhooks list" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<webhooks: table<id: string, url: string, events: record, sources: record, list_id: string, _links: list>, list_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/webhooks")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add webhook
#
# POST /lists/{list_id}/webhooks
# operationId: postListsIdWebhooks
# --events shape: {subscribe?: bool, unsubscribe?: bool, profile?: bool, cleaned?: bool, upemail?: bool, campaign?: bool, sms_subscribe?: bool, sms_unsubscribe?: bool, upsms?: bool, sms_campaign?: bool}
# --sources shape: {user?: bool, admin?: bool, api?: bool}
export def "lists-webhooks post" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-url: string # A valid URL for the Webhook. (e.g. http://yourdomain.com/webhook)
  --events: record # The events that can trigger the webhook and whether they are enabled. — shape: {subscribe?: bool, unsubscribe?: bool, profile?: bool, cleaned?: bool, upemail?: bool, campaign?: bool, sms_subscribe?: bool, sms_unsubscribe?: bool, upsms?: bool, sms_campaign?: bool}
  --sources: record # The possible sources of any events that can trigger the webhook and whether they are enabled. — shape: {user?: bool, admin?: bool, api?: bool}
]: any -> record<id: string, url: string, events: record<subscribe: bool, unsubscribe: bool, profile: bool, cleaned: bool, upemail: bool, campaign: bool, sms_subscribe: bool, sms_unsubscribe: bool, upsms: bool, sms_campaign: bool>, sources: record<user: bool, admin: bool, api: bool>, list_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/webhooks")
  let body = {url: $body_url, events: $events, sources: $sources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get webhook info
#
# GET /lists/{list_id}/webhooks/{webhook_id}
# operationId: getListsIdWebhooksId
export def "lists-webhooks get" [
  list_id: string
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, url: string, events: record<subscribe: bool, unsubscribe: bool, profile: bool, cleaned: bool, upemail: bool, campaign: bool, sms_subscribe: bool, sms_unsubscribe: bool, upsms: bool, sms_campaign: bool>, sources: record<user: bool, admin: bool, api: bool>, list_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/webhooks/($webhook_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete webhook
#
# DELETE /lists/{list_id}/webhooks/{webhook_id}
# operationId: deleteListsIdWebhooksId
export def "lists-webhooks delete" [
  list_id: string
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/webhooks/($webhook_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update webhook
#
# PATCH /lists/{list_id}/webhooks/{webhook_id}
# operationId: patchListsIdWebhooksId
# --events shape: {subscribe?: bool, unsubscribe?: bool, profile?: bool, cleaned?: bool, upemail?: bool, campaign?: bool, sms_subscribe?: bool, sms_unsubscribe?: bool, upsms?: bool, sms_campaign?: bool}
# --sources shape: {user?: bool, admin?: bool, api?: bool}
export def "lists-webhooks patch" [
  list_id: string
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-url: string # A valid URL for the Webhook. (e.g. http://yourdomain.com/webhook)
  --events: record # The events that can trigger the webhook and whether they are enabled. — shape: {subscribe?: bool, unsubscribe?: bool, profile?: bool, cleaned?: bool, upemail?: bool, campaign?: bool, sms_subscribe?: bool, sms_unsubscribe?: bool, upsms?: bool, sms_campaign?: bool}
  --sources: record # The possible sources of any events that can trigger the webhook and whether they are enabled. — shape: {user?: bool, admin?: bool, api?: bool}
]: any -> record<id: string, url: string, events: record<subscribe: bool, unsubscribe: bool, profile: bool, cleaned: bool, upemail: bool, campaign: bool, sms_subscribe: bool, sms_unsubscribe: bool, upsms: bool, sms_campaign: bool>, sources: record<user: bool, admin: bool, api: bool>, list_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/webhooks/($webhook_id)")
  let body = {url: $body_url, events: $events, sources: $sources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List signup forms
#
# GET /lists/{list_id}/signup-forms
# operationId: getListsIdSignupForms
export def "lists-signup-forms get" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<signup_forms: table<header: record, contents: list, styles: list, signup_form_url: string, list_id: string, _links: list>, list_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/signup-forms")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Customize signup form
#
# POST /lists/{list_id}/signup-forms
# operationId: postListsIdSignupForms
# --header shape: {image_url?: string, text?: string, image_width?: string, image_height?: string, image_alt?: string, image_link?: string, image_align?: "none"|"left"|"center"|"right", image_border_width?: string, image_border_style?: "none"|"solid"|"dotted"|"dashed"|"double"|"groove"|"outset"|"inset"|"ridge", image_border_color?: string, image_target?: "_blank"|"null"}
# --contents item shape: {section?: "signup_message"|"unsub_message"|"signup_thank_you_title", value?: string}
# --styles item shape: {selector?: "page_background"|"page_header"|"page_outer_wrapper"|"body_background"|"body_link_style"|"forms_buttons"|"forms_buttons_hovered"|"forms_field_label"|"forms_field_text"|"forms_required"|"forms_required_legend"|"forms_help_text"|"forms_errors"|"monkey_rewards_badge", options?: list}
export def "lists-signup-forms post" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --header: record # Options for customizing your signup form header. — shape: {image_url?: string, text?: string, image_width?: string, image_height?: string, image_alt?: string, image_link?: string, image_align?: "none"|"left"|"center"|"right", image_border_width?: string, image_border_style?: "none"|"solid"|"dotted"|"dashed"|"double"|"groove"|"outset"|"inset"|"ridge", image_border_color?: string, image_target?: "_blank"|"null"}
  --contents: list # The signup form body content. — item shape: {section?: "signup_message"|"unsub_message"|"signup_thank_you_title", value?: string}
  --styles: list # An array of objects, each representing an element style for the signup form. — item shape: {selector?: "page_background"|"page_header"|"page_outer_wrapper"|"body_background"|"body_link_style"|"forms_buttons"|"forms_buttons_hovered"|"forms_field_label"|"forms_field_text"|"forms_required"|"forms_required_legend"|"forms_help_text"|"forms_errors"|"monkey_rewards_badge", options?: list}
]: any -> record<header: record<image_url: string, text: string, image_width: string, image_height: string, image_alt: string, image_link: string, image_align: string, image_border_width: string, image_border_style: string, image_border_color: string, image_target: string>, contents: table<section: string, value: string>, styles: table<selector: string, options: list>, signup_form_url: string, list_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/signup-forms")
  let body = {header: $header, contents: $contents, styles: $styles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List locations
#
# GET /lists/{list_id}/locations
# operationId: getListsIdLocations
export def "lists-locations get" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<locations: table<country: string, cc: string, percent: float, total: int>, list_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($list_id)/locations" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get information about all surveys for a list
#
# GET /lists/{list_id}/surveys
# operationId: getListsIdSurveys
export def "lists-surveys list" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/surveys")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get survey
#
# GET /lists/{list_id}/surveys/{survey_id}
# operationId: getListsIdSurveysId
export def "lists-surveys get" [
  list_id: string
  survey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/surveys/($survey_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Publish a Survey
#
# POST /lists/{list_id}/surveys/{survey_id}/actions/publish
# operationId: postListsIdSurveysIdActionsPublish
export def "lists-surveys-actions-publish post" [
  list_id: string
  survey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/surveys/($survey_id)/actions/publish")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpublish a Survey
#
# POST /lists/{list_id}/surveys/{survey_id}/actions/unpublish
# operationId: postListsIdSurveysIdActionsUnpublish
export def "lists-surveys-actions-unpublish post" [
  list_id: string
  survey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/surveys/($survey_id)/actions/unpublish")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Survey Campaign
#
# POST /lists/{list_id}/surveys/{survey_id}/actions/create-email
# operationId: postListsIdSurveysIdActionsCreateEmail
export def "lists-surveys-actions-create-email post" [
  list_id: string
  survey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, web_id: int, parent_campaign_id: string, type: string, create_time: string, archive_url: string, long_archive_url: string, status: string, emails_sent: int, send_time: string, content_type: string, needs_block_refresh: bool, resendable: bool, recipients: record<list_id: string, list_name: string, segment_text: string, recipient_count: int, segment_opts: record<saved_segment_id: int, prebuilt_segment_id: string, match: string, conditions: list>>, settings: record<subject_line: string, preview_text: string, title: string, from_name: string, reply_to: string, use_conversation: bool, to_name: string, folder_id: string, authenticate: bool, auto_footer: bool, inline_css: bool, auto_tweet: bool, auto_fb_post: list<string>, fb_comments: bool, timewarp: bool, template_id: int, drag_and_drop: bool>, variate_settings: record<winning_combination_id: string, winning_campaign_id: string, winner_criteria: string, wait_time: int, test_size: int, subject_lines: list<string>, send_times: list<string>, from_names: list<string>, reply_to_addresses: list<string>, contents: list<string>, combinations: list<record>>, tracking: record<opens: bool, html_clicks: bool, text_clicks: bool, goal_tracking: bool, ecomm360: bool, google_analytics: string, clicktale: string, salesforce: record<campaign: bool, notes: bool>, capsule: record<notes: bool>>, rss_opts: record<feed_url: string, frequency: string, schedule: record<hour: int, daily_send: record, weekly_send_day: string, monthly_send_date: float>, last_sent: string, constrain_rss_img: bool>, ab_split_opts: record<split_test: string, pick_winner: string, wait_units: string, wait_time: int, split_size: int, from_name_a: string, from_name_b: string, reply_email_a: string, reply_email_b: string, subject_a: string, subject_b: string, send_time_a: string, send_time_b: string, send_time_winner: string>, social_card: record<image_url: string, description: string, title: string>, report_summary: record<opens: int, unique_opens: int, open_rate: float, clicks: int, subscriber_clicks: int, click_rate: float, ecommerce: record<total_orders: int, total_spent: float, total_revenue: float>>, delivery_status: record<enabled: bool, can_cancel: bool, status: string, emails_sent: int, emails_canceled: int>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($list_id)/surveys/($survey_id)/actions/create-email")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List landing pages
#
# GET /landing-pages
# operationId: getAllLandingPages
export def "landing-pages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --sort-dir: string@sort-dir-completer # Determines the order direction for sorted results.
  --sort-field: string@sort-field-completer # Returns files sorted by the specified field.
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
]: nothing -> record<landing_pages: table<id: string, name: string, title: string, description: string, template_id: int, status: string, list_id: string, store_id: string, web_id: int, created_by_source: string, url: string, created_at: string, published_at: string, unpublished_at: string, updated_at: string, tracking: record, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/landing-pages" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add landing page
#
# POST /landing-pages
# operationId: postAllLandingPages
# --tracking shape: {track_with_mailchimp?: bool, enable_restricted_data_processing?: bool}
export def "landing-pages post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --use-default-list: oneof<nothing, bool> # Will create the Landing Page using the account's Default List instead of requiring a list_id.
  --name: string # The name of this landing page.
  --title: string # The title of this landing page seen in the browser's title bar.
  --description: string # The description of this landing page.
  --store-id: string # The ID of the store associated with this landing page.
  --list-id: string # The list's ID associated with this landing page.
  --type: string@type-completer-3 # The type of template the landing page has. (e.g. signup)
  --template-id: int # The template_id of this landing page. (e.g. 1001)
  --tracking: record # The tracking settings applied to this landing page. — shape: {track_with_mailchimp?: bool, enable_restricted_data_processing?: bool}
]: any -> record<id: string, name: string, title: string, description: string, template_id: int, status: string, list_id: string, store_id: string, web_id: int, created_by_source: string, url: string, created_at: string, published_at: string, unpublished_at: string, updated_at: string, tracking: record<track_with_mailchimp: bool, enable_restricted_data_processing: bool>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "use_default_list" $use_default_list "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/landing-pages" $qp)
  let body = {name: $name, title: $title, description: $description, store_id: $store_id, list_id: $list_id, type: $type, template_id: $template_id, tracking: $tracking} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get landing page info
#
# GET /landing-pages/{page_id}
# operationId: getLandingPageId
export def "landing-pages get" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, name: string, title: string, description: string, template_id: int, status: string, list_id: string, store_id: string, web_id: int, created_by_source: string, url: string, created_at: string, published_at: string, unpublished_at: string, updated_at: string, tracking: record<track_with_mailchimp: bool, enable_restricted_data_processing: bool>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/landing-pages/($page_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update landing page
#
# PATCH /landing-pages/{page_id}
# operationId: patchLandingPageId
# --tracking shape: {track_with_mailchimp?: bool, enable_restricted_data_processing?: bool}
export def "landing-pages patch" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --name: string # The name of this landing page.
  --title: string # The title of this landing page seen in the browser's title bar.
  --description: string # The description of this landing page.
  --store-id: string # The ID of the store associated with this landing page.
  --list-id: string # The list's ID associated with this landing page.
  --tracking: record # The tracking settings applied to this landing page. — shape: {track_with_mailchimp?: bool, enable_restricted_data_processing?: bool}
]: any -> record<id: string, name: string, title: string, description: string, template_id: int, status: string, list_id: string, store_id: string, web_id: int, created_by_source: string, url: string, created_at: string, published_at: string, unpublished_at: string, updated_at: string, tracking: record<track_with_mailchimp: bool, enable_restricted_data_processing: bool>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/landing-pages/($page_id)")
  let body = {name: $name, title: $title, description: $description, store_id: $store_id, list_id: $list_id, tracking: $tracking} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete landing page
#
# DELETE /landing-pages/{page_id}
# operationId: deleteLandingPageId
export def "landing-pages delete" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/landing-pages/($page_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Publish landing page
#
# POST /landing-pages/{page_id}/actions/publish
# operationId: postLandingPageIdActionsPublish
export def "landing-pages-actions-publish post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/landing-pages/($page_id)/actions/publish")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpublish landing page
#
# POST /landing-pages/{page_id}/actions/unpublish
# operationId: postLandingPageIdActionsUnpublish
export def "landing-pages-actions-unpublish post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/landing-pages/($page_id)/actions/unpublish")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get landing page content
#
# GET /landing-pages/{page_id}/content
# operationId: getLandingPageIdContent
export def "landing-pages-content get" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<html: string, json: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/landing-pages/($page_id)/content" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List campaign reports
#
# GET /reports
# operationId: getReports
export def "reports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --type: string@type-completer # The campaign type.
  --before-send-time: string # Restrict the response to campaigns sent before the set time. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00. (format: date-time)
  --since-send-time: string # Restrict the response to campaigns sent after the set time. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00. (format: date-time)
]: nothing -> record<reports: table<id: string, campaign_title: string, type: string, list_id: string, list_is_active: bool, list_name: string, subject_line: string, preview_text: string, emails_sent: int, abuse_reports: int, unsubscribed: int, send_time: string, rss_last_send: string, bounces: record, forwards: record, opens: record, clicks: record, facebook_likes: record, industry_stats: record, list_stats: record, ab_split: record, timewarp: list, timeseries: list, share_report: record, ecommerce: record, delivery_status: record, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "before_send_time" $before_send_time "scalar") (serialize-qp "since_send_time" $since_send_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get campaign report
#
# GET /reports/{campaign_id}
# operationId: getReportsId
export def "reports get" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, campaign_title: string, type: string, list_id: string, list_is_active: bool, list_name: string, subject_line: string, preview_text: string, emails_sent: int, abuse_reports: int, unsubscribed: int, send_time: string, rss_last_send: string, bounces: record<hard_bounces: int, soft_bounces: int, syntax_errors: int>, forwards: record<forwards_count: int, forwards_opens: int>, opens: record<opens_total: int, proxy_excluded_opens: int, unique_opens: int, proxy_excluded_unique_opens: int, open_rate: float, proxy_excluded_open_rate: float, last_open: string>, clicks: record<clicks_total: int, unique_clicks: int, unique_subscriber_clicks: int, click_rate: float, last_click: string>, facebook_likes: record<recipient_likes: int, unique_likes: int, facebook_likes: int>, industry_stats: record<type: string, open_rate: float, click_rate: float, bounce_rate: float, unopen_rate: float, unsub_rate: float, abuse_rate: float>, list_stats: record<sub_rate: float, unsub_rate: float, open_rate: float, proxy_excluded_open_rate: float, click_rate: float>, ab_split: record<a: record<bounces: int, abuse_reports: int, unsubs: int, recipient_clicks: int, forwards: int, forwards_opens: int, opens: int, last_open: string, unique_opens: int>, b: record<bounces: int, abuse_reports: int, unsubs: int, recipient_clicks: int, forwards: int, forwards_opens: int, opens: int, last_open: string, unique_opens: int>>, timewarp: table<gmt_offset: int, opens: int, last_open: string, unique_opens: int, clicks: int, last_click: string, unique_clicks: int, bounces: int>, timeseries: table<timestamp: string, emails_sent: int, unique_opens: int, proxy_excluded_unique_opens: int, recipients_clicks: int>, share_report: record<share_url: string, share_password: string>, ecommerce: record<total_orders: int, total_spent: float, total_revenue: float, currency_code: string>, delivery_status: record<enabled: bool, can_cancel: bool, status: string, emails_sent: int, emails_canceled: int>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List abuse reports
#
# GET /reports/{campaign_id}/abuse-reports
# operationId: getReportsIdAbuseReportsId
export def "reports-abuse-reports list" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<abuse_reports: table<id: int, campaign_id: string, list_id: string, list_is_active: bool, email_id: string, email_address: string, merge_fields: record, vip: bool, date: string, _links: list>, campaign_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/abuse-reports" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get abuse report
#
# GET /reports/{campaign_id}/abuse-reports/{report_id}
# operationId: getReportsIdAbuseReportsIdId
export def "reports-abuse-reports get" [
  campaign_id: string
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: int, campaign_id: string, list_id: string, list_is_active: bool, email_id: string, email_address: string, merge_fields: record, vip: bool, date: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/abuse-reports/($report_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List campaign feedback
#
# GET /reports/{campaign_id}/advice
# operationId: getReportsIdAdvice
export def "reports-advice get" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<advice: table<type: string, message: string, _links: list>, campaign_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/advice" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List campaign details
#
# GET /reports/{campaign_id}/click-details
# operationId: getReportsIdClickDetails
export def "reports-click-details list" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --sort-field: string@sort-field-completer-8 # Returns click reports sorted by the specified field.
  --sort-dir: string@sort-dir-completer # Determines the order direction for sorted results.
]: nothing -> record<urls_clicked: table<id: string, url: string, total_clicks: int, click_percentage: float, unique_clicks: int, unique_click_percentage: float, last_click: string, ab_split: record, campaign_id: string, _links: list>, campaign_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_dir" $sort_dir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/click-details" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get campaign link details
#
# GET /reports/{campaign_id}/click-details/{link_id}
# operationId: getReportsIdClickDetailsId
export def "reports-click-details get" [
  campaign_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, url: string, total_clicks: int, click_percentage: float, unique_clicks: int, unique_click_percentage: float, last_click: string, ab_split: record<a: record<total_clicks_a: int, click_percentage_a: float, unique_clicks_a: int, unique_click_percentage_a: float>, b: record<total_clicks_b: int, click_percentage_b: float, unique_clicks_b: int, unique_click_percentage_b: float>>, campaign_id: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/click-details/($link_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List clicked link subscribers
#
# GET /reports/{campaign_id}/click-details/{link_id}/members
# operationId: getReportsIdClickDetailsIdMembers
export def "reports-click-details-members list" [
  campaign_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<members: table<email_id: string, email_address: string, merge_fields: record, vip: bool, clicks: int, campaign_id: string, url_id: string, list_id: string, list_is_active: bool, contact_status: string, _links: list>, campaign_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/click-details/($link_id)/members" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get clicked link subscriber
#
# GET /reports/{campaign_id}/click-details/{link_id}/members/{subscriber_hash}
# operationId: getReportsIdClickDetailsIdMembersId
export def "reports-click-details-members get" [
  campaign_id: string
  link_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<email_id: string, email_address: string, merge_fields: record, vip: bool, clicks: int, campaign_id: string, url_id: string, list_id: string, list_is_active: bool, contact_status: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/click-details/($link_id)/members/($subscriber_hash)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List campaign open details
#
# GET /reports/{campaign_id}/open-details
# operationId: getReportsIdOpenDetails
export def "reports-open-details list" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --since: string # Restrict results to campaign open events that occur after a specific time. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00. (e.g. 2016-04-12 12:00:00)
  --sort-field: string@sort-field-completer-9 # Returns open reports sorted by the specified field.
  --sort-dir: string@sort-dir-completer # Determines the order direction for sorted results.
]: nothing -> record<members: table<campaign_id: string, list_id: string, list_is_active: bool, contact_status: string, email_id: string, email_address: string, merge_fields: record, vip: bool, opens_count: int, proxy_excluded_opens_count: int, opens: list, _links: list>, campaign_id: string, total_opens: int, total_proxy_excluded_opens: int, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_dir" $sort_dir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/open-details" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get opened campaign subscriber
#
# GET /reports/{campaign_id}/open-details/{subscriber_hash}
# operationId: getReportsIdOpenDetailsIdMembersId
export def "reports-open-details get" [
  campaign_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<campaign_id: string, list_id: string, list_is_active: bool, contact_status: string, email_id: string, email_address: string, merge_fields: record, vip: bool, opens_count: int, proxy_excluded_opens_count: int, opens: table<timestamp: string, is_proxy_open: bool>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/open-details/($subscriber_hash)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List domain performance stats
#
# GET /reports/{campaign_id}/domain-performance
# operationId: getReportsIdDomainPerformance
export def "reports-domain-performance get" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<domains: table<domain: string, emails_sent: int, bounces: int, opens: int, clicks: int, unsubs: int, delivered: int, emails_pct: float, bounces_pct: float, opens_pct: float, clicks_pct: float, unsubs_pct: float>, total_sent: int, campaign_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/domain-performance" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List EepURL activity
#
# GET /reports/{campaign_id}/eepurl
# operationId: getReportsIdEepurl
export def "reports-eepurl get" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<twitter: record<tweets: int, first_tweet: string, last_tweet: string, retweets: int, statuses: list<record>>, clicks: record<clicks: int, first_click: string, last_click: string, locations: list<record>>, referrers: table<referrer: string, clicks: int, first_click: string, last_click: string>, eepurl: string, campaign_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/eepurl" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List email activity
#
# GET /reports/{campaign_id}/email-activity
# operationId: getReportsIdEmailActivity
export def "reports-email-activity list" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --since: string # Restrict results to email activity events that occur after a specific time. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
]: nothing -> record<emails: table<campaign_id: string, list_id: string, list_is_active: bool, email_id: string, email_address: string, activity: list, _links: list>, campaign_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/email-activity" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get subscriber email activity
#
# GET /reports/{campaign_id}/email-activity/{subscriber_hash}
# operationId: getReportsIdEmailActivityId
export def "reports-email-activity get" [
  campaign_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --since: string # Restrict results to email activity events that occur after a specific time. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
]: nothing -> record<campaign_id: string, list_id: string, list_is_active: bool, email_id: string, email_address: string, activity: table<action: string, type: string, timestamp: string, url: string, ip: string>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/email-activity/($subscriber_hash)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List top open activities
#
# GET /reports/{campaign_id}/locations
# operationId: getReportsIdLocations
export def "reports-locations get" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<locations: table<country_code: string, region: string, region_name: string, opens: int, proxy_excluded_opens: int>, campaign_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/locations" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List campaign recipients
#
# GET /reports/{campaign_id}/sent-to
# operationId: getReportsIdSentTo
export def "reports-sent-to list" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<sent_to: table<email_id: string, email_address: string, merge_fields: record, vip: bool, status: string, open_count: int, last_open: string, absplit_group: string, gmt_offset: int, campaign_id: string, list_id: string, list_is_active: bool, _links: list>, campaign_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/sent-to" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get campaign recipient info
#
# GET /reports/{campaign_id}/sent-to/{subscriber_hash}
# operationId: getReportsIdSentToId
export def "reports-sent-to get" [
  campaign_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<email_id: string, email_address: string, merge_fields: record, vip: bool, status: string, open_count: int, last_open: string, absplit_group: string, gmt_offset: int, campaign_id: string, list_id: string, list_is_active: bool, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/sent-to/($subscriber_hash)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List child campaign reports
#
# GET /reports/{campaign_id}/sub-reports
# operationId: getReportsIdSubReportsId
export def "reports-sub-reports get" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<reports: table<id: string, campaign_title: string, type: string, list_id: string, list_is_active: bool, list_name: string, subject_line: string, preview_text: string, emails_sent: int, abuse_reports: int, unsubscribed: int, send_time: string, rss_last_send: string, bounces: record, forwards: record, opens: record, clicks: record, facebook_likes: record, industry_stats: record, list_stats: record, ab_split: record, timewarp: list, timeseries: list, share_report: record, ecommerce: record, delivery_status: record, _links: list>, campaign_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/sub-reports" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List unsubscribed members
#
# GET /reports/{campaign_id}/unsubscribed
# operationId: getReportsIdUnsubscribed
export def "reports-unsubscribed list" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<unsubscribes: table<email_id: string, email_address: string, merge_fields: record, vip: bool, timestamp: string, reason: string, campaign_id: string, list_id: string, list_is_active: bool, _links: list>, campaign_id: string, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/unsubscribed" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get unsubscribed member
#
# GET /reports/{campaign_id}/unsubscribed/{subscriber_hash}
# operationId: getReportsIdUnsubscribedId
export def "reports-unsubscribed get" [
  campaign_id: string
  subscriber_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<email_id: string, email_address: string, merge_fields: record, vip: bool, timestamp: string, reason: string, campaign_id: string, list_id: string, list_is_active: bool, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/unsubscribed/($subscriber_hash)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List campaign product activity
#
# GET /reports/{campaign_id}/ecommerce-product-activity
# operationId: getReportsIdEcommerceProductActivity
export def "reports-ecommerce-product-activity get" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --sort-field: string@sort-field-completer-10 # Returns files sorted by the specified field.
]: nothing -> record<products: table<title: string, sku: string, image_url: string, total_revenue: float, total_purchased: float, currency_code: string, recommendation_total: int, recommendation_purchased: int>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort_field" $sort_field "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reports/($campaign_id)/ecommerce-product-activity" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List templates
#
# GET /templates
# operationId: getTemplates
export def "templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --created-by: string # The Mailchimp account user who created the template.
  --since-date-created: string # Restrict the response to templates created after the set date. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --before-date-created: string # Restrict the response to templates created before the set date. Uses ISO 8601 time format: 2015-10-21T15:41:36+00:00.
  --type: string # Limit results based on template type.
  --category: string # Limit results based on category.
  --folder-id: string # The unique folder id.
  --sort-field: string@sort-field-completer-11 # Returns user templates sorted by the specified field.
  --content-type: string@content-type-completer-1 # Limit results based on how the template's content is put together. Only templates of type `user` can be filtered by `content_type`. If you want to retrieve saved templates created with the legacy email editor, then filter `content_type` to `template`. If you'd rather pull your saved templates for the new editor, filter to `multichannel`. For code your own templates, filter to `html`.
  --sort-dir: string@sort-dir-completer # Determines the order direction for sorted results.
]: nothing -> record<templates: table<id: int, type: string, name: string, drag_and_drop: bool, responsive: bool, category: string, date_created: string, date_edited: string, created_by: string, edited_by: string, active: bool, folder_id: string, thumbnail: string, share_url: string, content_type: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "created_by" $created_by "scalar") (serialize-qp "since_date_created" $since_date_created "scalar") (serialize-qp "before_date_created" $before_date_created "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "folder_id" $folder_id "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "content_type" $content_type "scalar") (serialize-qp "sort_dir" $sort_dir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/templates" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add template
#
# POST /templates
# operationId: postTemplates
export def "templates post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The name of the template. (e.g. Freddie's Jokes)
  --folder-id: string # The id of the folder the template is currently in. (e.g. a4b830b)
  html: string # The raw HTML for the template. We  support the Mailchimp [Template Language](https://mailchimp.com/help/getting-started-with-mailchimps-template-language/) in any HTML code passed via the API.
]: any -> record<id: int, type: string, name: string, drag_and_drop: bool, responsive: bool, category: string, date_created: string, date_edited: string, created_by: string, edited_by: string, active: bool, folder_id: string, thumbnail: string, share_url: string, content_type: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates")
  let body = {name: $name, folder_id: $folder_id, html: $html} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get template info
#
# GET /templates/{template_id}
# operationId: getTemplatesId
export def "templates get" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: int, type: string, name: string, drag_and_drop: bool, responsive: bool, category: string, date_created: string, date_edited: string, created_by: string, edited_by: string, active: bool, folder_id: string, thumbnail: string, share_url: string, content_type: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/($template_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update template
#
# PATCH /templates/{template_id}
# operationId: patchTemplatesId
export def "templates patch" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The name of the template. (e.g. Freddie's Jokes)
  --folder-id: string # The id of the folder the template is currently in. (e.g. a4b830b)
  html: string # The raw HTML for the template. We  support the Mailchimp [Template Language](https://mailchimp.com/help/getting-started-with-mailchimps-template-language/) in any HTML code passed via the API.
]: any -> record<id: int, type: string, name: string, drag_and_drop: bool, responsive: bool, category: string, date_created: string, date_edited: string, created_by: string, edited_by: string, active: bool, folder_id: string, thumbnail: string, share_url: string, content_type: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)")
  let body = {name: $name, folder_id: $folder_id, html: $html} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete template
#
# DELETE /templates/{template_id}
# operationId: deleteTemplatesId
export def "templates delete" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View default content
#
# GET /templates/{template_id}/default-content
# operationId: getTemplatesIdDefaultContent
export def "templates-default-content get" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<sections: record, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/($template_id)/default-content" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List account orders
#
# GET /ecommerce/orders
# operationId: getEcommerceOrders
export def "ecommerce-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --campaign-id: string # Restrict results to orders with a specific `campaign_id` value.
  --outreach-id: string # Restrict results to orders with a specific `outreach_id` value.
  --customer-id: string # Restrict results to orders made by a specific customer.
  --has-outreach: oneof<nothing, bool> # Restrict results to orders that have an outreach attached. For example, an email campaign or Facebook ad.
]: nothing -> record<orders: table<id: string, customer: record, store_id: string, campaign_id: string, cart_id: string, landing_site: string, financial_status: string, fulfillment_status: string, currency_code: string, order_total: float, order_url: string, discount_total: float, tax_total: float, shipping_total: float, tracking_code: string, processed_at_foreign: string, cancelled_at_foreign: string, updated_at_foreign: string, shipping_address: record, billing_address: record, promos: list, lines: list, outreach: record, tracking_number: string, tracking_carrier: string, tracking_url: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "campaign_id" $campaign_id "scalar") (serialize-qp "outreach_id" $outreach_id "scalar") (serialize-qp "customer_id" $customer_id "scalar") (serialize-qp "has_outreach" $has_outreach "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ecommerce/orders" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List stores
#
# GET /ecommerce/stores
# operationId: getEcommerceStores
export def "ecommerce-stores list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<stores: table<id: string, list_id: string, name: string, platform: string, domain: string, is_syncing: bool, email_address: string, currency_code: string, money_format: string, primary_locale: string, timezone: string, phone: string, address: record, connected_site: record, automations: record, list_is_active: bool, created_at: string, updated_at: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ecommerce/stores" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add store
#
# POST /ecommerce/stores
# operationId: postEcommerceStores
# --address shape: {address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string, longitude?: float, latitude?: float}
export def "ecommerce-stores post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  id: string # The unique identifier for the store. (e.g. example_store)
  list_id: string # The unique identifier for the list associated with the store. The `list_id` for a specific store cannot change. (e.g. 1a2df69511)
  name: string # The name of the store. (e.g. Freddie's Cat Hat Emporium)
  --platform: string # The e-commerce platform of the store.
  --domain: string # The store domain. This parameter is required for Connected Sites and Google Ads. (e.g. example.com)
  --is-syncing: oneof<nothing, bool> # Whether to disable automations because the store is currently [syncing](https://mailchimp.com/developer/marketing/docs/e-commerce/#pausing-store-automations).
  --email-address: string # The email address for the store. (e.g. freddie@mailchimp.com)
  currency_code: string # The three-letter ISO 4217 code for the currency that the store accepts. (e.g. USD)
  --money-format: string # The currency format for the store. For example: `$`, `£`, etc. (e.g. $)
  --primary-locale: string # The primary locale for the store. For example: `en`, `de`, etc. (e.g. fr)
  --timezone: string # The timezone for the store. (e.g. Eastern)
  --phone: string # The store phone number. (e.g. +16155550128)
  --address: record # The store address. — shape: {address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string, longitude?: float, latitude?: float}
]: any -> record<id: string, list_id: string, name: string, platform: string, domain: string, is_syncing: bool, email_address: string, currency_code: string, money_format: string, primary_locale: string, timezone: string, phone: string, address: record<address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string, longitude: float, latitude: float>, connected_site: record<site_foreign_id: string, site_script: record<url: string, fragment: string>>, automations: record<abandoned_cart: record<is_supported: bool, id: string, status: string>, abandoned_browse: record<is_supported: bool, id: string, status: string>>, list_is_active: bool, created_at: string, updated_at: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ecommerce/stores")
  let body = {id: $id, list_id: $list_id, name: $name, platform: $platform, domain: $domain, is_syncing: $is_syncing, email_address: $email_address, currency_code: $currency_code, money_format: $money_format, primary_locale: $primary_locale, timezone: $timezone, phone: $phone, address: $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get store info
#
# GET /ecommerce/stores/{store_id}
# operationId: getEcommerceStoresId
export def "ecommerce-stores get" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, list_id: string, name: string, platform: string, domain: string, is_syncing: bool, email_address: string, currency_code: string, money_format: string, primary_locale: string, timezone: string, phone: string, address: record<address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string, longitude: float, latitude: float>, connected_site: record<site_foreign_id: string, site_script: record<url: string, fragment: string>>, automations: record<abandoned_cart: record<is_supported: bool, id: string, status: string>, abandoned_browse: record<is_supported: bool, id: string, status: string>>, list_is_active: bool, created_at: string, updated_at: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update store
#
# PATCH /ecommerce/stores/{store_id}
# operationId: patchEcommerceStoresId
# --address shape: {address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string, longitude?: float, latitude?: float}
export def "ecommerce-stores patch" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --name: string # The name of the store. (e.g. Freddie's Cat Hat Emporium)
  --platform: string # The e-commerce platform of the store.
  --domain: string # The store domain. (e.g. example.com)
  --is-syncing: oneof<nothing, bool> # Whether to disable automations because the store is currently [syncing](https://mailchimp.com/developer/marketing/docs/e-commerce/#pausing-store-automations).
  --email-address: string # The email address for the store. (e.g. freddie@mailchimp.com)
  --currency-code: string # The three-letter ISO 4217 code for the currency that the store accepts. (e.g. USD)
  --money-format: string # The currency format for the store. For example: `$`, `£`, etc. (e.g. $)
  --primary-locale: string # The primary locale for the store. For example: `en`, `de`, etc. (e.g. fr)
  --timezone: string # The timezone for the store. (e.g. Eastern)
  --phone: string # The store phone number. (e.g. +16155550128)
  --address: record # The store address. — shape: {address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string, longitude?: float, latitude?: float}
]: any -> record<id: string, list_id: string, name: string, platform: string, domain: string, is_syncing: bool, email_address: string, currency_code: string, money_format: string, primary_locale: string, timezone: string, phone: string, address: record<address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string, longitude: float, latitude: float>, connected_site: record<site_foreign_id: string, site_script: record<url: string, fragment: string>>, automations: record<abandoned_cart: record<is_supported: bool, id: string, status: string>, abandoned_browse: record<is_supported: bool, id: string, status: string>>, list_is_active: bool, created_at: string, updated_at: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)")
  let body = {name: $name, platform: $platform, domain: $domain, is_syncing: $is_syncing, email_address: $email_address, currency_code: $currency_code, money_format: $money_format, primary_locale: $primary_locale, timezone: $timezone, phone: $phone, address: $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete store
#
# DELETE /ecommerce/stores/{store_id}
# operationId: deleteEcommerceStoresId
export def "ecommerce-stores delete" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List carts
#
# GET /ecommerce/stores/{store_id}/carts
# operationId: getEcommerceStoresIdCarts
export def "ecommerce-stores-carts list" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<store_id: string, carts: table<id: string, customer: record, campaign_id: string, checkout_url: string, currency_code: string, order_total: float, tax_total: float, lines: list, created_at: string, updated_at: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/carts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add cart
#
# POST /ecommerce/stores/{store_id}/carts
# operationId: postEcommerceStoresIdCarts
# --customer shape: {id: string, email_address?: string, opt_in_status?: bool, company?: string, first_name?: string, last_name?: string, address?: record}
# --lines item shape: {id: string, product_id: string, product_variant_id: string, quantity: int, price: float}
export def "ecommerce-stores-carts post" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  id: string # A unique identifier for the cart.
  customer: record # Information about a specific customer. For existing customers include only the `id` parameter in the `customer` object body. — shape: {id: string, email_address?: string, opt_in_status?: bool, company?: string, first_name?: string, last_name?: string, address?: record}
  --campaign-id: string # A string that uniquely identifies the campaign for a cart. (e.g. 839488a60b)
  --checkout-url: string # The URL for the cart. This parameter is required for [Abandoned Cart](https://mailchimp.com/help/create-an-abandoned-cart-email/) automations.
  currency_code: string # The three-letter ISO 4217 code for the currency that the cart uses.
  order_total: float # The order total for the cart.
  --tax-total: float # The total tax for the cart.
  lines: list # An array of the cart's line items. — item shape: {id: string, product_id: string, product_variant_id: string, quantity: int, price: float}
]: any -> record<id: string, customer: record<id: string, email_address: string, sms_phone_number: string, opt_in_status: bool, company: string, first_name: string, last_name: string, orders_count: int, total_spent: float, address: record<address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string>, created_at: string, updated_at: string, _links: list<record>>, campaign_id: string, checkout_url: string, currency_code: string, order_total: float, tax_total: float, lines: table<id: string, product_id: string, product_title: string, product_variant_id: string, product_variant_title: string, quantity: int, price: float, _links: list>, created_at: string, updated_at: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/carts")
  let body = {id: $id, customer: $customer, campaign_id: $campaign_id, checkout_url: $checkout_url, currency_code: $currency_code, order_total: $order_total, tax_total: $tax_total, lines: $lines} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get cart info
#
# GET /ecommerce/stores/{store_id}/carts/{cart_id}
# operationId: getEcommerceStoresIdCartsId
export def "ecommerce-stores-carts get" [
  store_id: string
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, customer: record<id: string, email_address: string, sms_phone_number: string, opt_in_status: bool, company: string, first_name: string, last_name: string, orders_count: int, total_spent: float, address: record<address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string>, created_at: string, updated_at: string, _links: list<record>>, campaign_id: string, checkout_url: string, currency_code: string, order_total: float, tax_total: float, lines: table<id: string, product_id: string, product_title: string, product_variant_id: string, product_variant_title: string, quantity: int, price: float, _links: list>, created_at: string, updated_at: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/carts/($cart_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update cart
#
# PATCH /ecommerce/stores/{store_id}/carts/{cart_id}
# operationId: patchEcommerceStoresIdCartsId
# --customer shape: {opt_in_status?: bool, company?: string, first_name?: string, last_name?: string, address?: record}
# --lines item shape: {product_id?: string, product_variant_id?: string, quantity?: int, price?: float}
export def "ecommerce-stores-carts patch" [
  store_id: string
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --customer: record # Information about a specific customer. Orders for existing customers should include only the `id` parameter in the `customer` object body. — shape: {opt_in_status?: bool, company?: string, first_name?: string, last_name?: string, address?: record}
  --campaign-id: string # A string that uniquely identifies the campaign associated with a cart. (e.g. 839488a60b)
  --checkout-url: string # The URL for the cart. This parameter is required for [Abandoned Cart](https://mailchimp.com/help/create-an-abandoned-cart-email/) automations.
  --currency-code: string # The three-letter ISO 4217 code for the currency that the cart uses.
  --order-total: float # The order total for the cart.
  --tax-total: float # The total tax for the cart.
  --lines: list # An array of the cart's line items. — item shape: {product_id?: string, product_variant_id?: string, quantity?: int, price?: float}
]: any -> record<id: string, customer: record<id: string, email_address: string, sms_phone_number: string, opt_in_status: bool, company: string, first_name: string, last_name: string, orders_count: int, total_spent: float, address: record<address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string>, created_at: string, updated_at: string, _links: list<record>>, campaign_id: string, checkout_url: string, currency_code: string, order_total: float, tax_total: float, lines: table<id: string, product_id: string, product_title: string, product_variant_id: string, product_variant_title: string, quantity: int, price: float, _links: list>, created_at: string, updated_at: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/carts/($cart_id)")
  let body = {customer: $customer, campaign_id: $campaign_id, checkout_url: $checkout_url, currency_code: $currency_code, order_total: $order_total, tax_total: $tax_total, lines: $lines} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete cart
#
# DELETE /ecommerce/stores/{store_id}/carts/{cart_id}
# operationId: deleteEcommerceStoresIdCartsId
export def "ecommerce-stores-carts delete" [
  store_id: string
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/carts/($cart_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List cart line items
#
# GET /ecommerce/stores/{store_id}/carts/{cart_id}/lines
# operationId: getEcommerceStoresIdCartsIdLines
export def "ecommerce-stores-carts-lines list" [
  store_id: string
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<store_id: string, cart_id: string, lines: table<id: string, product_id: string, product_title: string, product_variant_id: string, product_variant_title: string, quantity: int, price: float, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/carts/($cart_id)/lines" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add cart line item
#
# POST /ecommerce/stores/{store_id}/carts/{cart_id}/lines
# operationId: postEcommerceStoresIdCartsIdLines
export def "ecommerce-stores-carts-lines post" [
  store_id: string
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  id: string # A unique identifier for the cart line item.
  product_id: string # A unique identifier for the product associated with the cart line item.
  product_variant_id: string # A unique identifier for the product variant associated with the cart line item.
  quantity: int # The quantity of a cart line item.
  price: float # The price of a cart line item.
]: any -> record<id: string, product_id: string, product_title: string, product_variant_id: string, product_variant_title: string, quantity: int, price: float, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/carts/($cart_id)/lines")
  let body = {id: $id, product_id: $product_id, product_variant_id: $product_variant_id, quantity: $quantity, price: $price} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get cart line item
#
# GET /ecommerce/stores/{store_id}/carts/{cart_id}/lines/{line_id}
# operationId: getEcommerceStoresIdCartsIdLinesId
export def "ecommerce-stores-carts-lines get" [
  store_id: string
  cart_id: string
  line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, product_id: string, product_title: string, product_variant_id: string, product_variant_title: string, quantity: int, price: float, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/carts/($cart_id)/lines/($line_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update cart line item
#
# PATCH /ecommerce/stores/{store_id}/carts/{cart_id}/lines/{line_id}
# operationId: patchEcommerceStoresIdCartsIdLinesId
export def "ecommerce-stores-carts-lines patch" [
  store_id: string
  cart_id: string
  line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --product-id: string # A unique identifier for the product associated with the cart line item.
  --product-variant-id: string # A unique identifier for the product variant associated with the cart line item.
  --quantity: int # The quantity of a cart line item.
  --price: float # The price of a cart line item.
]: any -> record<id: string, product_id: string, product_title: string, product_variant_id: string, product_variant_title: string, quantity: int, price: float, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/carts/($cart_id)/lines/($line_id)")
  let body = {product_id: $product_id, product_variant_id: $product_variant_id, quantity: $quantity, price: $price} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete cart line item
#
# DELETE /ecommerce/stores/{store_id}/carts/{cart_id}/lines/{line_id}
# operationId: deleteEcommerceStoresIdCartsLinesId
export def "ecommerce-stores-carts-lines delete" [
  store_id: string
  cart_id: string
  line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/carts/($cart_id)/lines/($line_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List customers
#
# GET /ecommerce/stores/{store_id}/customers
# operationId: getEcommerceStoresIdCustomers
export def "ecommerce-stores-customers list" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --email-address: string # Restrict the response to customers with the email address.
]: nothing -> record<store_id: string, customers: table<id: string, email_address: string, sms_phone_number: string, opt_in_status: bool, company: string, first_name: string, last_name: string, orders_count: int, total_spent: float, address: record, created_at: string, updated_at: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "email_address" $email_address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/customers" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add customer
#
# POST /ecommerce/stores/{store_id}/customers
# operationId: postEcommerceStoresIdCustomers
# --address shape: {address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string}
export def "ecommerce-stores-customers post" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  id: string # A unique identifier for the customer. Limited to 50 characters.
  --email-address: string # The customer's email address.
  --sms-phone-number: string # A US phone number for SMS contact.
  --opt-in-status: oneof<nothing, bool> # The customer's opt-in status. This value will never overwrite the opt-in status of a pre-existing Mailchimp list member, but will apply to list members that are added through the e-commerce API endpoints. Customers who don't opt in to your Mailchimp list [will be added as `Transactional` members](https://mailchimp.com/developer/marketing/docs/e-commerce/#customers).
  --company: string # The customer's company.
  --first-name: string # The customer's first name.
  --last-name: string # The customer's last name.
  --address: record # The customer's address. — shape: {address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string}
]: any -> record<id: string, email_address: string, sms_phone_number: string, opt_in_status: bool, company: string, first_name: string, last_name: string, orders_count: int, total_spent: float, address: record<address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string>, created_at: string, updated_at: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/customers")
  let body = {id: $id, email_address: $email_address, sms_phone_number: $sms_phone_number, opt_in_status: $opt_in_status, company: $company, first_name: $first_name, last_name: $last_name, address: $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get customer info
#
# GET /ecommerce/stores/{store_id}/customers/{customer_id}
# operationId: getEcommerceStoresIdCustomersId
export def "ecommerce-stores-customers get" [
  store_id: string
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, email_address: string, sms_phone_number: string, opt_in_status: bool, company: string, first_name: string, last_name: string, orders_count: int, total_spent: float, address: record<address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string>, created_at: string, updated_at: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/customers/($customer_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or update customer
#
# PUT /ecommerce/stores/{store_id}/customers/{customer_id}
# operationId: putEcommerceStoresIdCustomersId
# --address shape: {address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string}
export def "ecommerce-stores-customers put" [
  store_id: string
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  id: string # A unique identifier for the customer. Limited to 50 characters.
  --email-address: string # The customer's email address.
  --sms-phone-number: string # A US phone number for SMS contact.
  --opt-in-status: oneof<nothing, bool> # The customer's opt-in status. This value will never overwrite the opt-in status of a pre-existing Mailchimp list member, but will apply to list members that are added through the e-commerce API endpoints. Customers who don't opt in to your Mailchimp list [will be added as `Transactional` members](https://mailchimp.com/developer/marketing/docs/e-commerce/#customers).
  --company: string # The customer's company.
  --first-name: string # The customer's first name.
  --last-name: string # The customer's last name.
  --address: record # The customer's address. — shape: {address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string}
]: any -> record<id: string, email_address: string, sms_phone_number: string, opt_in_status: bool, company: string, first_name: string, last_name: string, orders_count: int, total_spent: float, address: record<address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string>, created_at: string, updated_at: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/customers/($customer_id)")
  let body = {id: $id, email_address: $email_address, sms_phone_number: $sms_phone_number, opt_in_status: $opt_in_status, company: $company, first_name: $first_name, last_name: $last_name, address: $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update customer
#
# PATCH /ecommerce/stores/{store_id}/customers/{customer_id}
# operationId: patchEcommerceStoresIdCustomersId
# --address shape: {address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string}
export def "ecommerce-stores-customers patch" [
  store_id: string
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --opt-in-status: oneof<nothing, bool> # The customer's opt-in status. This value will never overwrite the opt-in status of a pre-existing Mailchimp list member, but will apply to list members that are added through the e-commerce API endpoints. Customers who don't opt in to your Mailchimp list [will be added as `Transactional` members](https://mailchimp.com/developer/marketing/docs/e-commerce/#customers).
  --company: string # The customer's company.
  --first-name: string # The customer's first name.
  --last-name: string # The customer's last name.
  --address: record # The customer's address. — shape: {address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string}
]: any -> record<id: string, email_address: string, sms_phone_number: string, opt_in_status: bool, company: string, first_name: string, last_name: string, orders_count: int, total_spent: float, address: record<address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string>, created_at: string, updated_at: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/customers/($customer_id)")
  let body = {opt_in_status: $opt_in_status, company: $company, first_name: $first_name, last_name: $last_name, address: $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete customer
#
# DELETE /ecommerce/stores/{store_id}/customers/{customer_id}
# operationId: deleteEcommerceStoresIdCustomersId
export def "ecommerce-stores-customers delete" [
  store_id: string
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/customers/($customer_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List promo rules
#
# GET /ecommerce/stores/{store_id}/promo-rules
# operationId: getEcommerceStoresIdPromorules
export def "ecommerce-stores-promo-rules list" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<store_id: string, promo_rules: table<id: string, title: string, description: string, starts_at: string, ends_at: string, amount: float, type: string, target: string, enabled: bool, created_at_foreign: string, updated_at_foreign: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/promo-rules" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add promo rule
#
# POST /ecommerce/stores/{store_id}/promo-rules
# operationId: postEcommerceStoresIdPromorules
export def "ecommerce-stores-promo-rules post" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  id: string # A unique identifier for the promo rule. If Ecommerce platform does not support promo rule, use promo code id as promo rule id. Restricted to UTF-8 characters with max length 50.
  --title: string # The title that will show up in promotion campaign. Restricted to UTF-8 characters with max length of 100 bytes. (e.g. 50% off Total Order)
  description: string # The description of a promotion restricted to UTF-8 characters with max length 255. (e.g. Save BIG during our summer sale!)
  --starts-at: string # The date and time when the promotion is in effect in ISO 8601 format. (format: date-time)
  --ends-at: string # The date and time when the promotion ends. Must be after starts_at and in ISO 8601 format. (format: Promo date-time)
  amount: float # The amount of the promo code discount. If 'type' is 'fixed', the amount is treated as a monetary value. If 'type' is 'percentage', amount must be a decimal value between 0.0 and 1.0, inclusive. (format: float, e.g. 0.5)
  type: string@type-completer-4 # Type of discount. For free shipping set type to fixed.
  target: string@target-completer # The target that the discount applies to.
  --enabled: oneof<nothing, bool> # Whether the promo rule is currently enabled. (e.g. true)
  --created-at-foreign: string # The date and time the promotion was created in ISO 8601 format. (format: date-time)
  --updated-at-foreign: string # The date and time the promotion was updated in ISO 8601 format. (format: date-time)
]: any -> record<id: string, title: string, description: string, starts_at: string, ends_at: string, amount: float, type: string, target: string, enabled: bool, created_at_foreign: string, updated_at_foreign: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/promo-rules")
  let body = {id: $id, title: $title, description: $description, starts_at: $starts_at, ends_at: $ends_at, amount: $amount, type: $type, target: $target, enabled: $enabled, created_at_foreign: $created_at_foreign, updated_at_foreign: $updated_at_foreign} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get promo rule
#
# GET /ecommerce/stores/{store_id}/promo-rules/{promo_rule_id}
# operationId: getEcommerceStoresIdPromorulesId
export def "ecommerce-stores-promo-rules get" [
  store_id: string
  promo_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, title: string, description: string, starts_at: string, ends_at: string, amount: float, type: string, target: string, enabled: bool, created_at_foreign: string, updated_at_foreign: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/promo-rules/($promo_rule_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update promo rule
#
# PATCH /ecommerce/stores/{store_id}/promo-rules/{promo_rule_id}
# operationId: patchEcommerceStoresIdPromorulesId
export def "ecommerce-stores-promo-rules patch" [
  store_id: string
  promo_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --title: string # The title that will show up in promotion campaign. Restricted to UTF-8 characters with max length of 100 bytes. (e.g. 50% off Total Order)
  --description: string # The description of a promotion restricted to UTF-8 characters with max length 255. (e.g. Save BIG during our summer sale!)
  --starts-at: string # The date and time when the promotion is in effect in ISO 8601 format. (format: date-time)
  --ends-at: string # The date and time when the promotion ends. Must be after starts_at and in ISO 8601 format. (format: Promo date-time)
  --amount: float # The amount of the promo code discount. If 'type' is 'fixed', the amount is treated as a monetary value. If 'type' is 'percentage', amount must be a decimal value between 0.0 and 1.0, inclusive. (format: float, e.g. 0.5)
  --type: string@type-completer-4 # Type of discount. For free shipping set type to fixed.
  --target: string@target-completer # The target that the discount applies to.
  --enabled: oneof<nothing, bool> # Whether the promo rule is currently enabled. (e.g. true)
  --created-at-foreign: string # The date and time the promotion was created in ISO 8601 format. (format: date-time)
  --updated-at-foreign: string # The date and time the promotion was updated in ISO 8601 format. (format: date-time)
]: any -> record<id: string, title: string, description: string, starts_at: string, ends_at: string, amount: float, type: string, target: string, enabled: bool, created_at_foreign: string, updated_at_foreign: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/promo-rules/($promo_rule_id)")
  let body = {title: $title, description: $description, starts_at: $starts_at, ends_at: $ends_at, amount: $amount, type: $type, target: $target, enabled: $enabled, created_at_foreign: $created_at_foreign, updated_at_foreign: $updated_at_foreign} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete promo rule
#
# DELETE /ecommerce/stores/{store_id}/promo-rules/{promo_rule_id}
# operationId: deleteEcommerceStoresIdPromorulesId
export def "ecommerce-stores-promo-rules delete" [
  store_id: string
  promo_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/promo-rules/($promo_rule_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List promo codes
#
# GET /ecommerce/stores/{store_id}/promo-rules/{promo_rule_id}/promo-codes
# operationId: getEcommerceStoresIdPromocodes
export def "ecommerce-stores-promo-rules-promo-codes list" [
  promo_rule_id: string
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<store_id: string, promo_codes: table<id: string, code: string, redemption_url: string, usage_count: int, enabled: bool, created_at_foreign: string, updated_at_foreign: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/promo-rules/($promo_rule_id)/promo-codes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add promo code
#
# POST /ecommerce/stores/{store_id}/promo-rules/{promo_rule_id}/promo-codes
# operationId: postEcommerceStoresIdPromocodes
export def "ecommerce-stores-promo-rules-promo-codes post" [
  store_id: string
  promo_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  id: string # A unique identifier for the promo code. Restricted to UTF-8 characters with max length 50.
  code: string # The discount code. Restricted to UTF-8 characters with max length 50. (e.g. summersale)
  redemption_url: string # The url that should be used in the promotion campaign restricted to UTF-8 characters with max length 2000. (e.g. A url that applies promo code directly at checkout or a url that points to sale page or store url)
  --usage-count: int # Number of times promo code has been used.
  --enabled: oneof<nothing, bool> # Whether the promo code is currently enabled. (e.g. true)
  --created-at-foreign: string # The date and time the promotion was created in ISO 8601 format. (format: date-time)
  --updated-at-foreign: string # The date and time the promotion was updated in ISO 8601 format. (format: date-time)
]: any -> record<id: string, code: string, redemption_url: string, usage_count: int, enabled: bool, created_at_foreign: string, updated_at_foreign: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/promo-rules/($promo_rule_id)/promo-codes")
  let body = {id: $id, code: $code, redemption_url: $redemption_url, usage_count: $usage_count, enabled: $enabled, created_at_foreign: $created_at_foreign, updated_at_foreign: $updated_at_foreign} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get promo code
#
# GET /ecommerce/stores/{store_id}/promo-rules/{promo_rule_id}/promo-codes/{promo_code_id}
# operationId: getEcommerceStoresIdPromocodesId
export def "ecommerce-stores-promo-rules-promo-codes get" [
  store_id: string
  promo_rule_id: string
  promo_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, code: string, redemption_url: string, usage_count: int, enabled: bool, created_at_foreign: string, updated_at_foreign: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/promo-rules/($promo_rule_id)/promo-codes/($promo_code_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update promo code
#
# PATCH /ecommerce/stores/{store_id}/promo-rules/{promo_rule_id}/promo-codes/{promo_code_id}
# operationId: patchEcommerceStoresIdPromocodesId
export def "ecommerce-stores-promo-rules-promo-codes patch" [
  store_id: string
  promo_rule_id: string
  promo_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --code: string # The discount code. Restricted to UTF-8 characters with max length 50. (e.g. summersale)
  --redemption-url: string # The url that should be used in the promotion campaign restricted to UTF-8 characters with max length 2000. (e.g. A url that applies promo code directly at checkout or a url that points to sale page or store url)
  --usage-count: int # Number of times promo code has been used.
  --enabled: oneof<nothing, bool> # Whether the promo code is currently enabled. (e.g. true)
  --created-at-foreign: string # The date and time the promotion was created in ISO 8601 format. (format: date-time)
  --updated-at-foreign: string # The date and time the promotion was updated in ISO 8601 format. (format: date-time)
]: any -> record<id: string, code: string, redemption_url: string, usage_count: int, enabled: bool, created_at_foreign: string, updated_at_foreign: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/promo-rules/($promo_rule_id)/promo-codes/($promo_code_id)")
  let body = {code: $code, redemption_url: $redemption_url, usage_count: $usage_count, enabled: $enabled, created_at_foreign: $created_at_foreign, updated_at_foreign: $updated_at_foreign} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete promo code
#
# DELETE /ecommerce/stores/{store_id}/promo-rules/{promo_rule_id}/promo-codes/{promo_code_id}
# operationId: deleteEcommerceStoresIdPromocodesId
export def "ecommerce-stores-promo-rules-promo-codes delete" [
  store_id: string
  promo_rule_id: string
  promo_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/promo-rules/($promo_rule_id)/promo-codes/($promo_code_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List orders
#
# GET /ecommerce/stores/{store_id}/orders
# operationId: getEcommerceStoresIdOrders
export def "ecommerce-stores-orders list" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --customer-id: string # Restrict results to orders made by a specific customer.
  --has-outreach: oneof<nothing, bool> # Restrict results to orders that have an outreach attached. For example, an email campaign or Facebook ad.
  --campaign-id: string # Restrict results to orders with a specific `campaign_id` value.
  --outreach-id: string # Restrict results to orders with a specific `outreach_id` value.
]: nothing -> record<store_id: string, orders: table<id: string, customer: record, store_id: string, campaign_id: string, cart_id: string, landing_site: string, financial_status: string, fulfillment_status: string, currency_code: string, order_total: float, order_url: string, discount_total: float, tax_total: float, shipping_total: float, tracking_code: string, processed_at_foreign: string, cancelled_at_foreign: string, updated_at_foreign: string, shipping_address: record, billing_address: record, promos: list, lines: list, outreach: record, tracking_number: string, tracking_carrier: string, tracking_url: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "customer_id" $customer_id "scalar") (serialize-qp "has_outreach" $has_outreach "scalar") (serialize-qp "campaign_id" $campaign_id "scalar") (serialize-qp "outreach_id" $outreach_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/orders" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add order
#
# POST /ecommerce/stores/{store_id}/orders
# operationId: postEcommerceStoresIdOrders
# --customer shape: {id: string, email_address?: string, opt_in_status?: bool, company?: string, first_name?: string, last_name?: string, address?: record}
# --shipping_address shape: {name?: string, address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string, longitude?: float, latitude?: float, phone?: string, company?: string}
# --billing_address shape: {name?: string, address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string, longitude?: float, latitude?: float, phone?: string, company?: string}
# --promos item shape: {code: string, amount_discounted: float, type: "fixed"|"percentage"}
# --lines item shape: {id: string, product_id: string, product_variant_id: string, product?: record, quantity: int, price: float, discount?: float}
# --outreach shape: {id?: string}
export def "ecommerce-stores-orders post" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  id: string # A unique identifier for the order.
  customer: record # Information about a specific customer. For existing customers include only the `id` parameter in the `customer` object body. — shape: {id: string, email_address?: string, opt_in_status?: bool, company?: string, first_name?: string, last_name?: string, address?: record}
  --campaign-id: string # A string that uniquely identifies the campaign for an order. (e.g. 839488a60b)
  --cart-id: string # A cart id that the order was placed for. (e.g. cart-123)
  --landing-site: string # The URL for the page where the buyer landed when entering the shop. (e.g. http://www.example.com?source=abc)
  --financial-status: string # The order status. Use this parameter to trigger [Order Notifications](https://mailchimp.com/developer/marketing/docs/e-commerce/#order-notifications).
  --fulfillment-status: string # The fulfillment status for the order. Use this parameter to trigger [Order Notifications](https://mailchimp.com/developer/marketing/docs/e-commerce/#order-notifications).
  currency_code: string # The three-letter ISO 4217 code for the currency that the store accepts.
  order_total: float # The total for the order.
  --order-url: string # The URL for the order.
  --discount-total: float # The total amount of the discounts to be applied to the price of the order.
  --tax-total: float # The tax total for the order.
  --shipping-total: float # The shipping total for the order.
  --tracking-code: string@tracking-code-completer # The Mailchimp tracking code for the order. Uses the 'mc_tc' parameter in E-Commerce tracking URLs.
  --processed-at-foreign: string # The date and time the order was processed in ISO 8601 format. (format: date-time, e.g. 2015-07-15T19:28:00+00:00)
  --cancelled-at-foreign: string # The date and time the order was cancelled in ISO 8601 format. Note: passing a value for this parameter will cancel the order being created. (format: date-time, e.g. 2015-07-15T19:28:00+00:00)
  --updated-at-foreign: string # The date and time the order was updated in ISO 8601 format. (format: date-time, e.g. 2015-07-15T19:28:00+00:00)
  --shipping-address: record # The shipping address for the order. — shape: {name?: string, address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string, longitude?: float, latitude?: float, phone?: string, company?: string}
  --billing-address: record # The billing address for the order. — shape: {name?: string, address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string, longitude?: float, latitude?: float, phone?: string, company?: string}
  --promos: list # The promo codes applied on the order — item shape: {code: string, amount_discounted: float, type: "fixed"|"percentage"}
  lines: list # An array of the order's line items. — item shape: {id: string, product_id: string, product_variant_id: string, product?: record, quantity: int, price: float, discount?: float}
  --outreach: record # The outreach associated with this order. For example, an email campaign or Facebook ad. — shape: {id?: string}
  --tracking-number: string # The tracking number associated with the order.
  --tracking-carrier: string # The tracking carrier associated with the order.
  --tracking-url: string # The tracking URL associated with the order.
]: any -> record<id: string, customer: record<id: string, email_address: string, sms_phone_number: string, opt_in_status: bool, company: string, first_name: string, last_name: string, orders_count: int, total_spent: float, address: record<address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string>, created_at: string, updated_at: string, _links: list<record>>, store_id: string, campaign_id: string, cart_id: string, landing_site: string, financial_status: string, fulfillment_status: string, currency_code: string, order_total: float, order_url: string, discount_total: float, tax_total: float, shipping_total: float, tracking_code: string, processed_at_foreign: string, cancelled_at_foreign: string, updated_at_foreign: string, shipping_address: record<name: string, address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string, longitude: float, latitude: float, phone: string, company: string>, billing_address: record<name: string, address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string, longitude: float, latitude: float, phone: string, company: string>, promos: table<code: string, amount_discounted: float, type: string>, lines: table<id: string, product_id: string, product_title: string, product_variant_id: string, product_variant_title: string, image_url: string, quantity: int, price: float, discount: float, _links: list>, outreach: record<id: string, name: string, type: string, published_time: string>, tracking_number: string, tracking_carrier: string, tracking_url: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/orders")
  let body = {id: $id, customer: $customer, campaign_id: $campaign_id, cart_id: $cart_id, landing_site: $landing_site, financial_status: $financial_status, fulfillment_status: $fulfillment_status, currency_code: $currency_code, order_total: $order_total, order_url: $order_url, discount_total: $discount_total, tax_total: $tax_total, shipping_total: $shipping_total, tracking_code: $tracking_code, processed_at_foreign: $processed_at_foreign, cancelled_at_foreign: $cancelled_at_foreign, updated_at_foreign: $updated_at_foreign, shipping_address: $shipping_address, billing_address: $billing_address, promos: $promos, lines: $lines, outreach: $outreach, tracking_number: $tracking_number, tracking_carrier: $tracking_carrier, tracking_url: $tracking_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get order info
#
# GET /ecommerce/stores/{store_id}/orders/{order_id}
# operationId: getEcommerceStoresIdOrdersId
export def "ecommerce-stores-orders get" [
  store_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, customer: record<id: string, email_address: string, sms_phone_number: string, opt_in_status: bool, company: string, first_name: string, last_name: string, orders_count: int, total_spent: float, address: record<address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string>, created_at: string, updated_at: string, _links: list<record>>, store_id: string, campaign_id: string, cart_id: string, landing_site: string, financial_status: string, fulfillment_status: string, currency_code: string, order_total: float, order_url: string, discount_total: float, tax_total: float, shipping_total: float, tracking_code: string, processed_at_foreign: string, cancelled_at_foreign: string, updated_at_foreign: string, shipping_address: record<name: string, address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string, longitude: float, latitude: float, phone: string, company: string>, billing_address: record<name: string, address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string, longitude: float, latitude: float, phone: string, company: string>, promos: table<code: string, amount_discounted: float, type: string>, lines: table<id: string, product_id: string, product_title: string, product_variant_id: string, product_variant_title: string, image_url: string, quantity: int, price: float, discount: float, _links: list>, outreach: record<id: string, name: string, type: string, published_time: string>, tracking_number: string, tracking_carrier: string, tracking_url: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/orders/($order_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or update order
#
# PUT /ecommerce/stores/{store_id}/orders/{order_id}
# operationId: putEcommerceStoresIdOrdersId
# --customer shape: {id: string, email_address?: string, opt_in_status?: bool, company?: string, first_name?: string, last_name?: string, address?: record}
# --shipping_address shape: {name?: string, address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string, longitude?: float, latitude?: float, phone?: string, company?: string}
# --billing_address shape: {name?: string, address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string, longitude?: float, latitude?: float, phone?: string, company?: string}
# --promos item shape: {code: string, amount_discounted: float, type: "fixed"|"percentage"}
# --lines item shape: {id: string, product_id?: string, product_variant_id?: string, product?: record, quantity?: int, price?: float, discount?: float}
# --outreach shape: {id?: string}
export def "ecommerce-stores-orders put" [
  store_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  id: string # A unique identifier for the order.
  --customer: record # Information about a specific customer. For existing customers include only the `id` parameter in the `customer` object body. — shape: {id: string, email_address?: string, opt_in_status?: bool, company?: string, first_name?: string, last_name?: string, address?: record}
  --campaign-id: string # A string that uniquely identifies the campaign for an order. (e.g. 839488a60b)
  --cart-id: string # A cart id that the order was placed for. (e.g. cart-123)
  --landing-site: string # The URL for the page where the buyer landed when entering the shop. (e.g. http://www.example.com?source=abc)
  --financial-status: string # The order status. Use this parameter to trigger [Order Notifications](https://mailchimp.com/developer/marketing/docs/e-commerce/#order-notifications).
  --fulfillment-status: string # The fulfillment status for the order. Use this parameter to trigger [Order Notifications](https://mailchimp.com/developer/marketing/docs/e-commerce/#order-notifications).
  --currency-code: string # The three-letter ISO 4217 code for the currency that the store accepts.
  --order-total: float # The total for the order.
  --order-url: string # The URL for the order.
  --discount-total: float # The total amount of the discounts to be applied to the price of the order.
  --tax-total: float # The tax total for the order.
  --shipping-total: float # The shipping total for the order.
  --tracking-code: string@tracking-code-completer # The Mailchimp tracking code for the order. Uses the 'mc_tc' parameter in E-Commerce tracking URLs.
  --processed-at-foreign: string # The date and time the order was processed in ISO 8601 format. (format: date-time, e.g. 2024-09-10T17:27:43+00:00)
  --cancelled-at-foreign: string # The date and time the order was cancelled in ISO 8601 format. Note: passing a value for this parameter will cancel the order being created. (format: date-time, e.g. 2024-09-10T17:27:43+00:00)
  --updated-at-foreign: string # The date and time the order was updated in ISO 8601 format. (format: date-time, e.g. 2024-09-10T17:27:43+00:00)
  --shipping-address: record # The shipping address for the order. — shape: {name?: string, address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string, longitude?: float, latitude?: float, phone?: string, company?: string}
  --billing-address: record # The billing address for the order. — shape: {name?: string, address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string, longitude?: float, latitude?: float, phone?: string, company?: string}
  --promos: list # The promo codes applied on the order — item shape: {code: string, amount_discounted: float, type: "fixed"|"percentage"}
  --lines: list # An array of the order's line items. — item shape: {id: string, product_id?: string, product_variant_id?: string, product?: record, quantity?: int, price?: float, discount?: float}
  --outreach: record # The outreach associated with this order. For example, an email campaign or Facebook ad. — shape: {id?: string}
  --tracking-number: string # The tracking number associated with the order.
  --tracking-carrier: string # The tracking carrier associated with the order.
  --tracking-url: string # The tracking URL associated with the order.
]: any -> record<id: string, customer: record<id: string, email_address: string, sms_phone_number: string, opt_in_status: bool, company: string, first_name: string, last_name: string, orders_count: int, total_spent: float, address: record<address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string>, created_at: string, updated_at: string, _links: list<record>>, store_id: string, campaign_id: string, cart_id: string, landing_site: string, financial_status: string, fulfillment_status: string, currency_code: string, order_total: float, order_url: string, discount_total: float, tax_total: float, shipping_total: float, tracking_code: string, processed_at_foreign: string, cancelled_at_foreign: string, updated_at_foreign: string, shipping_address: record<name: string, address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string, longitude: float, latitude: float, phone: string, company: string>, billing_address: record<name: string, address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string, longitude: float, latitude: float, phone: string, company: string>, promos: table<code: string, amount_discounted: float, type: string>, lines: table<id: string, product_id: string, product_title: string, product_variant_id: string, product_variant_title: string, image_url: string, quantity: int, price: float, discount: float, _links: list>, outreach: record<id: string, name: string, type: string, published_time: string>, tracking_number: string, tracking_carrier: string, tracking_url: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/orders/($order_id)")
  let body = {id: $id, customer: $customer, campaign_id: $campaign_id, cart_id: $cart_id, landing_site: $landing_site, financial_status: $financial_status, fulfillment_status: $fulfillment_status, currency_code: $currency_code, order_total: $order_total, order_url: $order_url, discount_total: $discount_total, tax_total: $tax_total, shipping_total: $shipping_total, tracking_code: $tracking_code, processed_at_foreign: $processed_at_foreign, cancelled_at_foreign: $cancelled_at_foreign, updated_at_foreign: $updated_at_foreign, shipping_address: $shipping_address, billing_address: $billing_address, promos: $promos, lines: $lines, outreach: $outreach, tracking_number: $tracking_number, tracking_carrier: $tracking_carrier, tracking_url: $tracking_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update order
#
# PATCH /ecommerce/stores/{store_id}/orders/{order_id}
# operationId: patchEcommerceStoresIdOrdersId
# --customer shape: {opt_in_status?: bool, company?: string, first_name?: string, last_name?: string, address?: record}
# --shipping_address shape: {name?: string, address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string, longitude?: float, latitude?: float, phone?: string, company?: string}
# --billing_address shape: {name?: string, address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string, longitude?: float, latitude?: float, phone?: string, company?: string}
# --promos item shape: {code: string, amount_discounted: float, type: "fixed"|"percentage"}
# --lines item shape: {product_id?: string, product_variant_id?: string, quantity?: int, price?: float, discount?: float}
# --outreach shape: {id?: string}
export def "ecommerce-stores-orders patch" [
  store_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --customer: record # Information about a specific customer. Orders for existing customers should include only the `id` parameter in the `customer` object body. — shape: {opt_in_status?: bool, company?: string, first_name?: string, last_name?: string, address?: record}
  --campaign-id: string # A string that uniquely identifies the campaign associated with an order. (e.g. 839488a60b)
  --cart-id: string # A cart id that the order was placed for. (e.g. cart-123)
  --landing-site: string # The URL for the page where the buyer landed when entering the shop. (e.g. http://www.example.com?source=abc)
  --financial-status: string # The order status. Use this parameter to trigger [Order Notifications](https://mailchimp.com/developer/marketing/docs/e-commerce/#order-notifications).
  --fulfillment-status: string # The fulfillment status for the order. Use this parameter to trigger [Order Notifications](https://mailchimp.com/developer/marketing/docs/e-commerce/#order-notifications).
  --currency-code: string # The three-letter ISO 4217 code for the currency that the store accepts.
  --order-total: float # The order total associated with an order.
  --order-url: string # The URL for the order.
  --discount-total: float # The total amount of the discounts to be applied to the price of the order.
  --tax-total: float # The tax total associated with an order.
  --shipping-total: float # The shipping total for the order.
  --tracking-code: string@tracking-code-completer # The Mailchimp tracking code for the order. Uses the 'mc_tc' parameter in E-Commerce tracking URLs.
  --processed-at-foreign: string # The date and time the order was processed in ISO 8601 format. (format: date-time, e.g. 2015-07-15T19:28:00+00:00)
  --cancelled-at-foreign: string # The date and time the order was cancelled in ISO 8601 format. Note: passing a value for this parameter will cancel the order being edited. (format: date-time, e.g. 2015-07-15T19:28:00+00:00)
  --updated-at-foreign: string # The date and time the order was updated in ISO 8601 format. (format: date-time, e.g. 2015-07-15T19:28:00+00:00)
  --shipping-address: record # The shipping address for the order. — shape: {name?: string, address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string, longitude?: float, latitude?: float, phone?: string, company?: string}
  --billing-address: record # The billing address for the order. — shape: {name?: string, address1?: string, address2?: string, city?: string, province?: string, province_code?: string, postal_code?: string, country?: string, country_code?: string, longitude?: float, latitude?: float, phone?: string, company?: string}
  --promos: list # The promo codes applied on the order. Note: Patch will completely replace the value of promos with the new one provided. — item shape: {code: string, amount_discounted: float, type: "fixed"|"percentage"}
  --lines: list # An array of the order's line items. — item shape: {product_id?: string, product_variant_id?: string, quantity?: int, price?: float, discount?: float}
  --outreach: record # The outreach associated with this order. For example, an email campaign or Facebook ad. — shape: {id?: string}
  --tracking-number: string # The tracking number associated with the order.
  --tracking-carrier: string # The tracking carrier associated with the order.
  --tracking-url: string # The tracking URL associated with the order.
]: any -> record<id: string, customer: record<id: string, email_address: string, sms_phone_number: string, opt_in_status: bool, company: string, first_name: string, last_name: string, orders_count: int, total_spent: float, address: record<address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string>, created_at: string, updated_at: string, _links: list<record>>, store_id: string, campaign_id: string, cart_id: string, landing_site: string, financial_status: string, fulfillment_status: string, currency_code: string, order_total: float, order_url: string, discount_total: float, tax_total: float, shipping_total: float, tracking_code: string, processed_at_foreign: string, cancelled_at_foreign: string, updated_at_foreign: string, shipping_address: record<name: string, address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string, longitude: float, latitude: float, phone: string, company: string>, billing_address: record<name: string, address1: string, address2: string, city: string, province: string, province_code: string, postal_code: string, country: string, country_code: string, longitude: float, latitude: float, phone: string, company: string>, promos: table<code: string, amount_discounted: float, type: string>, lines: table<id: string, product_id: string, product_title: string, product_variant_id: string, product_variant_title: string, image_url: string, quantity: int, price: float, discount: float, _links: list>, outreach: record<id: string, name: string, type: string, published_time: string>, tracking_number: string, tracking_carrier: string, tracking_url: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/orders/($order_id)")
  let body = {customer: $customer, campaign_id: $campaign_id, cart_id: $cart_id, landing_site: $landing_site, financial_status: $financial_status, fulfillment_status: $fulfillment_status, currency_code: $currency_code, order_total: $order_total, order_url: $order_url, discount_total: $discount_total, tax_total: $tax_total, shipping_total: $shipping_total, tracking_code: $tracking_code, processed_at_foreign: $processed_at_foreign, cancelled_at_foreign: $cancelled_at_foreign, updated_at_foreign: $updated_at_foreign, shipping_address: $shipping_address, billing_address: $billing_address, promos: $promos, lines: $lines, outreach: $outreach, tracking_number: $tracking_number, tracking_carrier: $tracking_carrier, tracking_url: $tracking_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete order
#
# DELETE /ecommerce/stores/{store_id}/orders/{order_id}
# operationId: deleteEcommerceStoresIdOrdersId
export def "ecommerce-stores-orders delete" [
  store_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/orders/($order_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List order line items
#
# GET /ecommerce/stores/{store_id}/orders/{order_id}/lines
# operationId: getEcommerceStoresIdOrdersIdLines
export def "ecommerce-stores-orders-lines list" [
  store_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<store_id: string, order_id: string, lines: table<id: string, product_id: string, product_title: string, product_variant_id: string, product_variant_title: string, image_url: string, quantity: int, price: float, discount: float, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/orders/($order_id)/lines" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add order line item
#
# POST /ecommerce/stores/{store_id}/orders/{order_id}/lines
# operationId: postEcommerceStoresIdOrdersIdLines
# --product shape: {id: string, title: string, handle?: string, url?: string, description?: string, type?: string, vendor?: string, image_url?: string, variants: list, images?: list, published_at_foreign?: string}
export def "ecommerce-stores-orders-lines post" [
  store_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  id: string # A unique identifier for the order line item.
  product_id: string # A unique identifier for the product associated with the order line item.
  product_variant_id: string # A unique identifier for the product variant associated with the order line item.
  --product: record # Information about a specific product. — shape: {id: string, title: string, handle?: string, url?: string, description?: string, type?: string, vendor?: string, image_url?: string, variants: list, images?: list, published_at_foreign?: string}
  quantity: int # The quantity of an order line item.
  price: float # The price of an order line item.
  --discount: float # The total discount amount applied to this line item.
]: any -> record<id: string, product_id: string, product_title: string, product_variant_id: string, product_variant_title: string, image_url: string, quantity: int, price: float, discount: float, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/orders/($order_id)/lines")
  let body = {id: $id, product_id: $product_id, product_variant_id: $product_variant_id, product: $product, quantity: $quantity, price: $price, discount: $discount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get order line item
#
# GET /ecommerce/stores/{store_id}/orders/{order_id}/lines/{line_id}
# operationId: getEcommerceStoresIdOrdersIdLinesId
export def "ecommerce-stores-orders-lines get" [
  store_id: string
  order_id: string
  line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, product_id: string, product_title: string, product_variant_id: string, product_variant_title: string, image_url: string, quantity: int, price: float, discount: float, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/orders/($order_id)/lines/($line_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update order line item
#
# PATCH /ecommerce/stores/{store_id}/orders/{order_id}/lines/{line_id}
# operationId: patchEcommerceStoresIdOrdersIdLinesId
export def "ecommerce-stores-orders-lines patch" [
  store_id: string
  order_id: string
  line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --product-id: string # A unique identifier for the product associated with the order line item.
  --product-variant-id: string # A unique identifier for the product variant associated with the order line item.
  --quantity: int # The quantity of an order line item.
  --price: float # The price of an order line item.
  --discount: float # The total discount amount applied to this line item.
]: any -> record<id: string, product_id: string, product_title: string, product_variant_id: string, product_variant_title: string, image_url: string, quantity: int, price: float, discount: float, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/orders/($order_id)/lines/($line_id)")
  let body = {product_id: $product_id, product_variant_id: $product_variant_id, quantity: $quantity, price: $price, discount: $discount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete order line item
#
# DELETE /ecommerce/stores/{store_id}/orders/{order_id}/lines/{line_id}
# operationId: deleteEcommerceStoresIdOrdersIdLinesId
export def "ecommerce-stores-orders-lines delete" [
  store_id: string
  order_id: string
  line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/orders/($order_id)/lines/($line_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List product
#
# GET /ecommerce/stores/{store_id}/products
# operationId: getEcommerceStoresIdProducts
export def "ecommerce-stores-products list" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<store_id: string, products: table<id: string, currency_code: string, title: string, handle: string, url: string, description: string, type: string, vendor: string, image_url: string, variants: list, images: list, published_at_foreign: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/products" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add product
#
# POST /ecommerce/stores/{store_id}/products
# operationId: postEcommerceStoresIdProducts
# --variants item shape: {id: string, title: string, url?: string, sku?: string, price?: float, inventory_quantity?: int, image_url?: string, backorders?: string, visibility?: string}
# --images item shape: {id: string, url: string, variant_ids?: list}
export def "ecommerce-stores-products post" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  id: string # A unique identifier for the product.
  title: string # The title of a product. (e.g. Cat Hat)
  --handle: string # The handle of a product. (e.g. cat-hat)
  --body-url: string # The URL for a product.
  --description: string # The description of a product. (e.g. This is a cat hat.)
  --type: string # The type of product. (e.g. Accessories)
  --vendor: string # The vendor for a product.
  --image-url: string # The image URL for a product.
  variants: list # An array of the product's variants. At least one variant is required for each product. A variant can use the same `id` and `title` as the parent product. — item shape: {id: string, title: string, url?: string, sku?: string, price?: float, inventory_quantity?: int, image_url?: string, backorders?: string, visibility?: string}
  --images: list # An array of the product's images. — item shape: {id: string, url: string, variant_ids?: list}
  --published-at-foreign: string # The date and time the product was published. (format: date-time, e.g. 2015-07-15T19:28:00+00:00)
]: any -> record<id: string, currency_code: string, title: string, handle: string, url: string, description: string, type: string, vendor: string, image_url: string, variants: table<id: string, title: string, url: string, sku: string, price: float, inventory_quantity: int, image_url: string, backorders: string, visibility: string, created_at: string, updated_at: string, _links: list>, images: table<id: string, url: string, variant_ids: list, _links: list>, published_at_foreign: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/products")
  let body = {id: $id, title: $title, handle: $handle, url: $body_url, description: $description, type: $type, vendor: $vendor, image_url: $image_url, variants: $variants, images: $images, published_at_foreign: $published_at_foreign} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get product info
#
# GET /ecommerce/stores/{store_id}/products/{product_id}
# operationId: getEcommerceStoresIdProductsId
export def "ecommerce-stores-products get" [
  store_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, currency_code: string, title: string, handle: string, url: string, description: string, type: string, vendor: string, image_url: string, variants: table<id: string, title: string, url: string, sku: string, price: float, inventory_quantity: int, image_url: string, backorders: string, visibility: string, created_at: string, updated_at: string, _links: list>, images: table<id: string, url: string, variant_ids: list, _links: list>, published_at_foreign: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/products/($product_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update product
#
# PATCH /ecommerce/stores/{store_id}/products/{product_id}
# operationId: patchEcommerceStoresIdProductsId
# --variants item shape: {title?: string, url?: string, sku?: string, price?: float, inventory_quantity?: int, image_url?: string, backorders?: string, visibility?: string}
# --images item shape: {id?: string, url?: string, variant_ids?: list}
export def "ecommerce-stores-products patch" [
  store_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --title: string # The title of a product. (e.g. Cat Hat)
  --handle: string # The handle of a product. (e.g. cat-hat)
  --body-url: string # The URL for a product.
  --description: string # The description of a product. (e.g. This is a cat hat.)
  --type: string # The type of product. (e.g. Accessories)
  --vendor: string # The vendor for a product.
  --image-url: string # The image URL for a product.
  --variants: list # An array of the product's variants. At least one variant is required for each product. A variant can use the same `id` and `title` as the parent product. — item shape: {title?: string, url?: string, sku?: string, price?: float, inventory_quantity?: int, image_url?: string, backorders?: string, visibility?: string}
  --images: list # An array of the product's images. — item shape: {id?: string, url?: string, variant_ids?: list}
  --published-at-foreign: string # The date and time the product was published in ISO 8601 format. (format: date-time, e.g. 2015-07-15T19:28:00+00:00)
]: any -> record<id: string, currency_code: string, title: string, handle: string, url: string, description: string, type: string, vendor: string, image_url: string, variants: table<id: string, title: string, url: string, sku: string, price: float, inventory_quantity: int, image_url: string, backorders: string, visibility: string, created_at: string, updated_at: string, _links: list>, images: table<id: string, url: string, variant_ids: list, _links: list>, published_at_foreign: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/products/($product_id)")
  let body = {title: $title, handle: $handle, url: $body_url, description: $description, type: $type, vendor: $vendor, image_url: $image_url, variants: $variants, images: $images, published_at_foreign: $published_at_foreign} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create or update product
#
# PUT /ecommerce/stores/{store_id}/products/{product_id}
# operationId: putEcommerceStoresIdProductsId
# --variants item shape: {id: string, title: string, url?: string, sku?: string, price?: float, inventory_quantity?: int, image_url?: string, backorders?: string, visibility?: string}
# --images item shape: {id: string, url: string, variant_ids?: list}
export def "ecommerce-stores-products put" [
  store_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  id: string # A unique identifier for the product.
  --title: string # The title of a product. (e.g. Cat Hat)
  --handle: string # The handle of a product. (e.g. cat-hat)
  --body-url: string # The URL for a product.
  --description: string # The description of a product. (e.g. This is a cat hat.)
  --type: string # The type of product. (e.g. Accessories)
  --vendor: string # The vendor for a product.
  --image-url: string # The image URL for a product.
  --variants: list # An array of the product's variants. At least one variant is required for each product. A variant can use the same `id` and `title` as the parent product. — item shape: {id: string, title: string, url?: string, sku?: string, price?: float, inventory_quantity?: int, image_url?: string, backorders?: string, visibility?: string}
  --images: list # An array of the product's images. — item shape: {id: string, url: string, variant_ids?: list}
  --published-at-foreign: string # The date and time the product was published. (format: date-time, e.g. 2015-07-15T19:28:00+00:00)
]: any -> record<id: string, currency_code: string, title: string, handle: string, url: string, description: string, type: string, vendor: string, image_url: string, variants: table<id: string, title: string, url: string, sku: string, price: float, inventory_quantity: int, image_url: string, backorders: string, visibility: string, created_at: string, updated_at: string, _links: list>, images: table<id: string, url: string, variant_ids: list, _links: list>, published_at_foreign: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/products/($product_id)")
  let body = {id: $id, title: $title, handle: $handle, url: $body_url, description: $description, type: $type, vendor: $vendor, image_url: $image_url, variants: $variants, images: $images, published_at_foreign: $published_at_foreign} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete product
#
# DELETE /ecommerce/stores/{store_id}/products/{product_id}
# operationId: deleteEcommerceStoresIdProductsId
export def "ecommerce-stores-products delete" [
  store_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/products/($product_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List product variants
#
# GET /ecommerce/stores/{store_id}/products/{product_id}/variants
# operationId: getEcommerceStoresIdProductsIdVariants
export def "ecommerce-stores-products-variants list" [
  store_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<store_id: string, product_id: string, variants: table<id: string, title: string, url: string, sku: string, price: float, inventory_quantity: int, image_url: string, backorders: string, visibility: string, created_at: string, updated_at: string, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/products/($product_id)/variants" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add product variant
#
# POST /ecommerce/stores/{store_id}/products/{product_id}/variants
# operationId: postEcommerceStoresIdProductsIdVariants
export def "ecommerce-stores-products-variants post" [
  store_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  id: string # A unique identifier for the product variant.
  title: string # The title of a product variant. (e.g. Cat Hat)
  --body-url: string # The URL for a product variant.
  --sku: string # The stock keeping unit (SKU) of a product variant.
  --price: float # The price of a product variant.
  --inventory-quantity: int # The inventory quantity of a product variant.
  --image-url: string # The image URL for a product variant.
  --backorders: string # The backorders of a product variant.
  --visibility: string # The visibility of a product variant.
]: any -> record<id: string, title: string, url: string, sku: string, price: float, inventory_quantity: int, image_url: string, backorders: string, visibility: string, created_at: string, updated_at: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/products/($product_id)/variants")
  let body = {id: $id, title: $title, url: $body_url, sku: $sku, price: $price, inventory_quantity: $inventory_quantity, image_url: $image_url, backorders: $backorders, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get product variant info
#
# GET /ecommerce/stores/{store_id}/products/{product_id}/variants/{variant_id}
# operationId: getEcommerceStoresIdProductsIdVariantsId
export def "ecommerce-stores-products-variants get" [
  store_id: string
  product_id: string
  variant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, title: string, url: string, sku: string, price: float, inventory_quantity: int, image_url: string, backorders: string, visibility: string, created_at: string, updated_at: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/products/($product_id)/variants/($variant_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or update product variant
#
# PUT /ecommerce/stores/{store_id}/products/{product_id}/variants/{variant_id}
# operationId: putEcommerceStoresIdProductsIdVariantsId
export def "ecommerce-stores-products-variants put" [
  store_id: string
  product_id: string
  variant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  id: string # A unique identifier for the product variant.
  title: string # The title of a product variant. (e.g. Cat Hat)
  --body-url: string # The URL for a product variant.
  --sku: string # The stock keeping unit (SKU) of a product variant.
  --price: float # The price of a product variant.
  --inventory-quantity: int # The inventory quantity of a product variant.
  --image-url: string # The image URL for a product variant.
  --backorders: string # The backorders of a product variant.
  --visibility: string # The visibility of a product variant.
]: any -> record<id: string, title: string, url: string, sku: string, price: float, inventory_quantity: int, image_url: string, backorders: string, visibility: string, created_at: string, updated_at: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/products/($product_id)/variants/($variant_id)")
  let body = {id: $id, title: $title, url: $body_url, sku: $sku, price: $price, inventory_quantity: $inventory_quantity, image_url: $image_url, backorders: $backorders, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update product variant
#
# PATCH /ecommerce/stores/{store_id}/products/{product_id}/variants/{variant_id}
# operationId: patchEcommerceStoresIdProductsIdVariantsId
export def "ecommerce-stores-products-variants patch" [
  store_id: string
  product_id: string
  variant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --title: string # The title of a product variant. (e.g. Cat Hat)
  --body-url: string # The URL for a product variant.
  --sku: string # The stock keeping unit (SKU) of a product variant.
  --price: float # The price of a product variant.
  --inventory-quantity: int # The inventory quantity of a product variant.
  --image-url: string # The image URL for a product variant.
  --backorders: string # The backorders of a product variant.
  --visibility: string # The visibility of a product variant.
]: any -> record<id: string, title: string, url: string, sku: string, price: float, inventory_quantity: int, image_url: string, backorders: string, visibility: string, created_at: string, updated_at: string, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/products/($product_id)/variants/($variant_id)")
  let body = {title: $title, url: $body_url, sku: $sku, price: $price, inventory_quantity: $inventory_quantity, image_url: $image_url, backorders: $backorders, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete product variant
#
# DELETE /ecommerce/stores/{store_id}/products/{product_id}/variants/{variant_id}
# operationId: deleteEcommerceStoresIdProductsIdVariantsId
export def "ecommerce-stores-products-variants delete" [
  store_id: string
  product_id: string
  variant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/products/($product_id)/variants/($variant_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List product images
#
# GET /ecommerce/stores/{store_id}/products/{product_id}/images
# operationId: getEcommerceStoresIdProductsIdImages
export def "ecommerce-stores-products-images list" [
  store_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<store_id: string, product_id: string, images: table<id: string, url: string, variant_ids: list, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/products/($product_id)/images" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add product image
#
# POST /ecommerce/stores/{store_id}/products/{product_id}/images
# operationId: postEcommerceStoresIdProductsIdImages
export def "ecommerce-stores-products-images post" [
  store_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  id: string # A unique identifier for the product image.
  --body-url: string # The URL for a product image.
  --variant-ids: list # The list of product variants using the image.
]: any -> record<id: string, url: string, variant_ids: list<string>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/products/($product_id)/images")
  let body = {id: $id, url: $body_url, variant_ids: $variant_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get product image info
#
# GET /ecommerce/stores/{store_id}/products/{product_id}/images/{image_id}
# operationId: getEcommerceStoresIdProductsIdImagesId
export def "ecommerce-stores-products-images get" [
  store_id: string
  product_id: string
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, url: string, variant_ids: list<string>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/products/($product_id)/images/($image_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update product image
#
# PATCH /ecommerce/stores/{store_id}/products/{product_id}/images/{image_id}
# operationId: patchEcommerceStoresIdProductsIdImagesId
export def "ecommerce-stores-products-images patch" [
  store_id: string
  product_id: string
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: string # A unique identifier for the product image.
  --body-url: string # The URL for a product image.
  --variant-ids: list # The list of product variants using the image.
]: any -> record<id: string, url: string, variant_ids: list<string>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/products/($product_id)/images/($image_id)")
  let body = {id: $id, url: $body_url, variant_ids: $variant_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete product image
#
# DELETE /ecommerce/stores/{store_id}/products/{product_id}/images/{image_id}
# operationId: deleteEcommerceStoresIdProductsIdImagesId
export def "ecommerce-stores-products-images delete" [
  store_id: string
  product_id: string
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/stores/($store_id)/products/($product_id)/images/($image_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search campaigns
#
# GET /search-campaigns
# operationId: getSearchCampaigns
export def "search-campaigns get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --qp-query: string # The search query used to filter results.
]: nothing -> record<results: table<campaign: record, snippet: string>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search-campaigns" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List SMS campaigns
#
# GET /sms-campaigns
# operationId: getSmsCampaigns
export def "sms-campaigns list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<sms_campaigns: table<id: string, web_id: string, name: string, status: string, channel: string, list_id: int, recipient_count: int, create_time: string, send_time: string, updated_at: string, expire_time: string, is_send_now: bool, folder_id: string, segments: list, excluded_segments: list, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sms-campaigns" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add SMS campaign
#
# POST /sms-campaigns
# operationId: postSmsCampaigns
export def "sms-campaigns post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The name of the campaign.
  --list-id: int # The numeric ID of the list to send the campaign to.
  --folder-id: string # The ID of the folder to place this campaign in.
  --segments: list # The segment IDs to target for this campaign.
  --excluded-segments: list # The segment IDs to exclude from this campaign.
]: any -> record<id: string, web_id: string, name: string, status: string, channel: string, list_id: int, recipient_count: int, create_time: string, send_time: string, updated_at: string, expire_time: string, is_send_now: bool, folder_id: string, segments: list<int>, excluded_segments: list<int>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sms-campaigns")
  let body = {name: $name, list_id: $list_id, folder_id: $folder_id, segments: $segments, excluded_segments: $excluded_segments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get SMS campaign info
#
# GET /sms-campaigns/{sms_campaign_id}
# operationId: getSmsCampaignsId
export def "sms-campaigns get" [
  sms_campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, web_id: string, name: string, status: string, channel: string, list_id: int, recipient_count: int, create_time: string, send_time: string, updated_at: string, expire_time: string, is_send_now: bool, folder_id: string, segments: list<int>, excluded_segments: list<int>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/sms-campaigns/($sms_campaign_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update SMS campaign settings
#
# PATCH /sms-campaigns/{sms_campaign_id}
# operationId: patchSmsCampaignsId
export def "sms-campaigns patch" [
  sms_campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --name: string # The name of the campaign.
  --folder-id: string # The ID of the folder to place this campaign in.
  --segments: list # The segment IDs to target for this campaign.
  --excluded-segments: list # The segment IDs to exclude from this campaign.
]: any -> record<id: string, web_id: string, name: string, status: string, channel: string, list_id: int, recipient_count: int, create_time: string, send_time: string, updated_at: string, expire_time: string, is_send_now: bool, folder_id: string, segments: list<int>, excluded_segments: list<int>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sms-campaigns/($sms_campaign_id)")
  let body = {name: $name, folder_id: $folder_id, segments: $segments, excluded_segments: $excluded_segments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete SMS campaign
#
# DELETE /sms-campaigns/{sms_campaign_id}
# operationId: deleteSmsCampaignsId
export def "sms-campaigns delete" [
  sms_campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sms-campaigns/($sms_campaign_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send SMS campaign
#
# POST /sms-campaigns/{sms_campaign_id}/actions/send
# operationId: postSmsCampaignsIdActionsSend
export def "sms-campaigns-actions-send post" [
  sms_campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sms-campaigns/($sms_campaign_id)/actions/send")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Schedule SMS campaign
#
# POST /sms-campaigns/{sms_campaign_id}/actions/schedule
# operationId: postSmsCampaignsIdActionsSchedule
export def "sms-campaigns-actions-schedule post" [
  sms_campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  schedule_time: string # The UTC date and time to schedule the campaign to send. (format: date-time)
]: any -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sms-campaigns/($sms_campaign_id)/actions/schedule")
  let body = {schedule_time: $schedule_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel SMS campaign send
#
# POST /sms-campaigns/{sms_campaign_id}/actions/cancel-send
# operationId: postSmsCampaignsIdActionsCancelSend
export def "sms-campaigns-actions-cancel-send post" [
  sms_campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sms-campaigns/($sms_campaign_id)/actions/cancel-send")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get SMS campaign content
#
# GET /sms-campaigns/{sms_campaign_id}/content
# operationId: getSmsCampaignsIdContent
export def "sms-campaigns-content get" [
  sms_campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<message_body: string, estimated_segments: int, merge_fields: list<string>, media: table<url: string, mime_type: string>, source: record<type: string, id: string>, properties: record<content_type: string, sender: string, optout_message_language: string>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/sms-campaigns/($sms_campaign_id)/content" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set SMS campaign content
#
# PUT /sms-campaigns/{sms_campaign_id}/content
# operationId: putSmsCampaignsIdContent
# --media item shape: {url?: string, mime_type?: string}
export def "sms-campaigns-content put" [
  sms_campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  message_body: string # The SMS message body.
  --media: list # Attached images or files. — item shape: {url?: string, mime_type?: string}
]: any -> record<message_body: string, estimated_segments: int, merge_fields: list<string>, media: table<url: string, mime_type: string>, source: record<type: string, id: string>, properties: record<content_type: string, sender: string, optout_message_language: string>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sms-campaigns/($sms_campaign_id)/content")
  let body = {message_body: $message_body, media: $media} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search members
#
# GET /search-members
# operationId: getSearchMembers
export def "search-members get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --qp-query: string # The search query used to filter results. Query should be a valid email, or a string representing a contact's first or last name.
  --list-id: string # The unique id for the list.
]: nothing -> record<exact_matches: record<members: list<record>, total_items: int>, full_search: record<members: list<record>, total_items: int>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "query" $qp_query "scalar") (serialize-qp "list_id" $list_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search-members" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ping
#
# GET /ping
# operationId: getPing
export def "ping get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<health_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ping")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List facebook ads
#
# GET /facebook-ads
# operationId: getAllFacebookAds
export def "facebook-ads list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --sort-field: string@sort-field-completer-12 # Returns files sorted by the specified field.
  --sort-dir: string@sort-dir-completer # Determines the order direction for sorted results.
]: nothing -> record<facebook_ads: table<id: string, web_id: int, name: string, type: string, status: string, show_report: bool, create_time: string, start_time: string, updated_at: string, canceled_at: string, published_time: string, has_segment: bool, report_summary: record, recipients: record, thumbnail: string, email_source_name: string, paused_at: string, end_time: string, needs_attention: bool, was_canceled_by_facebook: bool, is_connected: bool, has_audience: bool, has_content: bool, channel: record, feedback: record, site: record, audience: record, budget: record, content: record, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_dir" $sort_dir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/facebook-ads" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get facebook ad info
#
# GET /facebook-ads/{outreach_id}
# operationId: getFacebookAdsId
export def "facebook-ads get" [
  outreach_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, web_id: int, name: string, type: string, status: string, show_report: bool, create_time: string, start_time: string, updated_at: string, canceled_at: string, published_time: string, has_segment: bool, report_summary: record<opens: int, proxy_excluded_opens: int, unique_opens: int, proxy_excluded_unique_opens: int, open_rate: float, proxy_excluded_open_rate: float, clicks: int, subscriber_clicks: int, click_rate: float, visits: int, unique_visits: int, conversion_rate: float, subscribes: int, ecommerce: record<total_revenue: float, currency_code: string, average_order_revenue: float>, impressions: float, reach: int, engagements: int, total_sent: int>, recipients: record<list_id: string, list_is_active: bool, list_name: string, segment_text: string, recipient_count: int, segment_opts: record<saved_segment_id: int, prebuilt_segment_id: string, match: string, conditions: list>>, thumbnail: string, email_source_name: string, paused_at: string, end_time: string, needs_attention: bool, was_canceled_by_facebook: bool, is_connected: bool, has_audience: bool, has_content: bool, channel: record<fb_placement_feed: bool, fb_placement_audience: bool, ig_placement_feed: bool>, feedback: record<content: string, audience: string, budget: string, compliance: string>, site: record<id: int, name: string, url: string>, audience: record<type: string, source_type: string, email_source: record<name: string, type: string, is_segment: bool, segment_type: string, list_name: string>, include_source_in_target: bool, lookalike_country_code: string, targeting_specs: record<gender: int, min_age: int, max_age: int, locations: record, interests: list>>, budget: record<duration: int, total_amount: float, currency_code: string>, content: record<title: string, link_url: string, message: string, description: string, image_url: string, call_to_action: string, attachments: list<record>>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/facebook-ads/($outreach_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List facebook ads reports
#
# GET /reporting/facebook-ads
# operationId: getReportingFacebookAds
export def "reporting-facebook-ads list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --sort-field: string@sort-field-completer-12 # Returns files sorted by the specified field.
  --sort-dir: string@sort-dir-completer # Determines the order direction for sorted results.
]: nothing -> record<facebook_ads: table<id: string, web_id: int, name: string, type: string, status: string, show_report: bool, create_time: string, start_time: string, updated_at: string, canceled_at: string, published_time: string, has_segment: bool, report_summary: record, recipients: record, thumbnail: string, email_source_name: string, paused_at: string, end_time: string, needs_attention: bool, was_canceled_by_facebook: bool, channel: record, audience: record, budget: record, audience_activity: record, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_dir" $sort_dir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reporting/facebook-ads" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get facebook ad report
#
# GET /reporting/facebook-ads/{outreach_id}
# operationId: getReportingFacebookAdsId
export def "reporting-facebook-ads get" [
  outreach_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, web_id: int, name: string, type: string, status: string, show_report: bool, create_time: string, start_time: string, updated_at: string, canceled_at: string, published_time: string, has_segment: bool, report_summary: record<reach: int, impressions: int, clicks: int, click_rate: float, unique_clicks: int, first_time_buyers: int, ecommerce: record<total_revenue: float, currency_code: string>, total_products_sold: int, total_orders: int, average_order_amount: record<amount: float, currency_code: string>, cost_per_click: record<amount: float, currency_code: string>, average_daily_budget: record<amount: float, currency_code: string>, likes: int, comments: int, shares: int, has_extended_ad_duration: bool, extended_at: record<datetime: string, timezone: string>, return_on_investment: float>, recipients: record<list_id: string, list_is_active: bool, list_name: string, segment_text: string, recipient_count: int, segment_opts: record<saved_segment_id: int, prebuilt_segment_id: string, match: string, conditions: list>>, thumbnail: string, email_source_name: string, paused_at: string, end_time: string, needs_attention: bool, was_canceled_by_facebook: bool, channel: record<fb_placement_feed: bool, fb_placement_audience: bool, ig_placement_feed: bool>, audience: record<type: string, source_type: string, email_source: record<name: string, type: string, is_segment: bool, segment_type: string, list_name: string>, include_source_in_target: bool, lookalike_country_code: string, targeting_specs: record<gender: int, min_age: int, max_age: int, locations: record, interests: list>>, budget: record<duration: int, total_amount: float, currency_code: string>, audience_activity: record<clicks: list<record>, impressions: list<record>, revenue: list<record>>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/reporting/facebook-ads/($outreach_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List facebook ecommerce report
#
# GET /reporting/facebook-ads/{outreach_id}/ecommerce-product-activity
# operationId: getReportingFacebookAdsIdEcommerceProductActivity
export def "reporting-facebook-ads-ecommerce-product-activity get" [
  outreach_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
  --sort-field: string@sort-field-completer-10 # Returns files sorted by the specified field.
]: nothing -> record<products: table<title: string, sku: string, image_url: string, total_revenue: float, total_purchased: float, currency_code: string, recommendation_total: int, recommendation_purchased: int>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort_field" $sort_field "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reporting/facebook-ads/($outreach_id)/ecommerce-product-activity" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get landing page report
#
# GET /reporting/landing-pages/{outreach_id}
# operationId: getReportingLandingPagesId
export def "reporting-landing-pages get" [
  outreach_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, name: string, title: string, url: string, published_at: string, unpublished_at: string, status: string, list_id: string, visits: int, unique_visits: int, subscribes: int, clicks: int, conversion_rate: float, timeseries: record<daily_stats: record<clicks: list, visits: list, unique_visits: list>, weekly_stats: record<clicks: list, visits: list, unique_visits: list>>, ecommerce: record<total_revenue: float, currency_code: string, total_orders: int, average_order_revenue: float>, web_id: int, list_name: string, signup_tags: table<tag_id: int, tag_name: string>, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/reporting/landing-pages/($outreach_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List landing pages reports
#
# GET /reporting/landing-pages
# operationId: getReportingLandingPages
export def "reporting-landing-pages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<landing_pages: table<id: string, name: string, title: string, url: string, published_at: string, unpublished_at: string, status: string, list_id: string, visits: int, unique_visits: int, subscribes: int, clicks: int, conversion_rate: float, timeseries: record, ecommerce: record, web_id: int, list_name: string, signup_tags: list, _links: list>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reporting/landing-pages" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List survey reports
#
# GET /reporting/surveys
# operationId: getReportingSurveys
export def "reporting-surveys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --count: int # The number of records to return. Default value is 10. Maximum value is 1000 (default: 10)
  --offset: int # Used for [pagination](https://mailchimp.com/developer/marketing/docs/methods-parameters/#pagination), this is the number of records from a collection to skip. Default value is 0. (default: 0)
]: nothing -> record<surveys: table<id: string, web_id: int, list_id: string, list_name: string, title: string, url: string, status: string, published_at: string, created_at: string, updated_at: string, total_responses: int>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reporting/surveys" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get survey report
#
# GET /reporting/surveys/{survey_id}
# operationId: getReportingSurveysId
export def "reporting-surveys get" [
  survey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, web_id: int, list_id: string, list_name: string, title: string, url: string, status: string, published_at: string, created_at: string, updated_at: string, total_responses: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/reporting/surveys/($survey_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List survey question reports
#
# GET /reporting/surveys/{survey_id}/questions
# operationId: getReportingSurveysIdQuestions
export def "reporting-surveys-questions list" [
  survey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<questions: table<id: string, survey_id: string, query: string, type: string, total_responses: int, is_required: bool, has_other: bool, other_label: string, average_rating: float, range_low_label: string, range_high_label: string, placeholder_label: string, subscribe_checkbox_enabled: bool, subscribe_checkbox_label: string, merge_field: record, options: list, contact_counts: record>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/reporting/surveys/($survey_id)/questions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get survey question report
#
# GET /reporting/surveys/{survey_id}/questions/{question_id}
# operationId: getReportingSurveysIdQuestionsId
export def "reporting-surveys-questions get" [
  survey_id: string
  question_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
]: nothing -> record<id: string, survey_id: string, query: string, type: string, total_responses: int, is_required: bool, has_other: bool, other_label: string, average_rating: float, range_low_label: string, range_high_label: string, placeholder_label: string, subscribe_checkbox_enabled: bool, subscribe_checkbox_label: string, merge_field: record<id: int, label: string, type: string>, options: table<label: string, id: string, count: int>, contact_counts: record<known: int, unknown: int, new: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/reporting/surveys/($survey_id)/questions/($question_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List answers for question
#
# GET /reporting/surveys/{survey_id}/questions/{question_id}/answers
# operationId: getReportingSurveysIdQuestionsIdAnswers
export def "reporting-surveys-questions-answers get" [
  survey_id: string
  question_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --respondent-familiarity-is: string@respondent-familiarity-is-completer # Filter survey responses by familiarity of the respondents.
]: nothing -> record<answers: table<id: string, value: string, response_id: string, submitted_at: string, contact: record, is_new_contact: bool>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "respondent_familiarity_is" $respondent_familiarity_is "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reporting/surveys/($survey_id)/questions/($question_id)/answers" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List survey responses
#
# GET /reporting/surveys/{survey_id}/responses
# operationId: getReportingSurveysIdResponses
export def "reporting-surveys-responses list" [
  survey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: list # A comma-separated list of fields to return. Reference parameters of sub-objects with dot notation.
  --exclude-fields: list # A comma-separated list of fields to exclude. Reference parameters of sub-objects with dot notation.
  --answered-question: int # The ID of the question that was answered.
  --chose-answer: string # The ID of the option chosen to filter responses on.
  --respondent-familiarity-is: string@respondent-familiarity-is-completer # Filter survey responses by familiarity of the respondents.
]: nothing -> record<responses: table<response_id: string, submitted_at: string, contact: record, is_new_contact: bool>, total_items: int, _links: table<rel: string, href: string, method: string, targetSchema: string, schema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "exclude_fields" $exclude_fields "csv") (serialize-qp "answered_question" $answered_question "scalar") (serialize-qp "chose_answer" $chose_answer "scalar") (serialize-qp "respondent_familiarity_is" $respondent_familiarity_is "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reporting/surveys/($survey_id)/responses" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get survey response
#
# GET /reporting/surveys/{survey_id}/responses/{response_id}
# operationId: getReportingSurveysIdResponsesId
export def "reporting-surveys-responses get" [
  survey_id: string
  response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<response_id: string, submitted_at: string, contact: record<email_id: string, contact_id: string, status: string, email: string, phone: string, full_name: string, consents_to_one_to_one_messaging: bool, avatar_url: string>, is_new_contact: bool, results: table<question_id: string, question_type: string, query: string, answer: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reporting/surveys/($survey_id)/responses/($response_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get domain info
#
# GET /verified-domains/{domain_name}
# operationId: getVerifiedDomain
export def "verified-domains get" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<domain: string, verified: bool, authenticated: bool, verification_email: string, verification_sent: string, status: string, is_free_email_provider: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/verified-domains/($domain_name)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete domain
#
# DELETE /verified-domains/{domain_name}
# operationId: deleteVerifiedDomain
export def "verified-domains delete" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, title: string, status: int, detail: string, instance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/verified-domains/($domain_name)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify domain
#
# POST /verified-domains/{domain_name}/actions/verify
# operationId: verifyDomain
export def "verified-domains-actions-verify verifyDomain" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  code: string # The code that was sent to the email address provided when adding a new domain to verify.
]: any -> record<domain: string, verified: bool, authenticated: bool, verification_email: string, verification_sent: string, status: string, is_free_email_provider: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/verified-domains/($domain_name)/actions/verify")
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List sending domains
#
# GET /verified-domains
# operationId: getVerifiedDomains
export def "verified-domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<domains: table<domain: string, verified: bool, authenticated: bool, verification_email: string, verification_sent: string, status: string, is_free_email_provider: bool>, total_items: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verified-domains")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add domain to account
#
# POST /verified-domains
# operationId: createVerifiedDomain
export def "verified-domains createVerifiedDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  verification_email: string # The e-mail address at the domain you want to verify. This will receive a two-factor challenge to be used in the verify action.
]: any -> record<domain: string, verified: bool, authenticated: bool, verification_email: string, verification_sent: string, status: string, is_free_email_provider: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verified-domains")
  let body = {verification_email: $verification_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
