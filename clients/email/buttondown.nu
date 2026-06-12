# Auto-generated client for Buttondown API v1.0.0
# Source: https://raw.githubusercontent.com/buttondown/openapi/main/openapi.json
# Auth: --token flag or $env.BUTTONDOWN_API_TOKEN

const BASE_URL = "https://api.buttondown.com/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BUTTONDOWN_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.buttondown.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def trigger-completer [] { ["advertising_slot.inquiry" "advertising_slot.purchased" "automation.invoked" "bigcommerce.customer.created" "bigcommerce.customer.updated" "bigcommerce.order.created" "bigcommerce.order.updated" "date.day.started" "date.month.started" "date.week.started" "date.year.started" "email.created" "email.deleted" "email.sent" "email.status.changed" "email.updated" "export.completed" "export.created" "export.failed" "external_feed_item.created" "firewall.blocked" "form.created" "form.deleted" "form.updated" "memberful.member.updated" "memberful.subscription.created" "memberful.subscription.deleted" "mention.created" "note.created" "note.deleted" "patreon.member.updated" "patreon.membership.created" "patreon.membership.deleted" "shopify.customer.created" "shopify.customer.updated" "social_mention.created" "stripe.checkout.session.completed" "stripe.customer.updated" "stripe.subscription.activated" "stripe.subscription.churning" "stripe.subscription.deactivated" "subscriber.bounced" "subscriber.changed_email" "subscriber.churned" "subscriber.clicked" "subscriber.commented" "subscriber.complained" "subscriber.confirmed" "subscriber.created" "subscriber.deleted" "subscriber.delivered" "subscriber.opened" "subscriber.paid" "subscriber.paused" "subscriber.referred" "subscriber.referred.paid" "subscriber.rejected" "subscriber.replied" "subscriber.responded_to_survey" "subscriber.resumed" "subscriber.tags.changed" "subscriber.trial_ended" "subscriber.trial_started" "subscriber.type.changed" "subscriber.unsubscribed" "subscriber.updated" "subscriber.viewed_checkout_page" "survey.cleared_responses" "survey.created" "survey.deleted" "survey.updated"] }
def type-completer [] { ["add_notes" "apply_metadata" "apply_tags" "ban_subscribers" "cancel_stripe_subscriptions" "change_tags_colors" "delete_attachments" "delete_comments" "delete_emails" "delete_images" "delete_inbox_items" "delete_subscribers" "delete_survey_responses" "delete_surveys" "delete_tags" "gift_subscribers" "mark_comments_as_active" "mark_comments_as_spammy" "mark_inbox_items_read" "mark_subscribers_as_not_spammy" "modify_stripe_subscriptions" "pause_stripe_subscriptions" "reactivate_subscribers" "rename_metadata" "replay_events" "resubscribe_subscribers" "send_emails" "send_reminders" "unban_subscribers" "ungift_subscribers" "unsubscribe_subscribers" "update_archival_modes" "update_commenting_modes" "update_email_types" "update_survey_statuses"] }
def status-completer [] { ["active" "pending" "spammy"] }
def status-completer-1 [] { ["active" "spammy"] }
def ordering-completer [] { ["-creation_date" "creation_date"] }
def target-completer [] { ["email" "html"] }
def event-type-completer [] { ["activation_bounced" "activation_clicked" "activation_complained" "activation_deferred" "activation_delivered" "activation_opened" "activation_rejected" "activation_reminder_bounced" "activation_reminder_clicked" "activation_reminder_complained" "activation_reminder_deferred" "activation_reminder_delivered" "activation_reminder_opened" "activation_reminder_rejected" "attempted" "bounced" "clicked" "complained" "deferred" "delivered" "opened" "rejected" "replied" "sent" "subscription_confirmed_bounced" "subscription_confirmed_clicked" "subscription_confirmed_complained" "subscription_confirmed_deferred" "subscription_confirmed_delivered" "subscription_confirmed_opened" "subscription_confirmed_rejected" "unsubscribed"] }
def behavior-completer [] { ["draft" "emails"] }
def cadence-completer [] { ["daily" "every" "monthly" "weekly"] }
def announcement-bar-visibility-completer [] { ["disabled" "everyone" "free_only" "logged_out_only" "paid_only"] }
def model-type-completer [] { ["automation" "comment" "conversation" "email" "external_feed" "invitation" "socialmention" "stripe_customer" "subscriber" "survey" "tag" "webmention"] }
def cadence-completer-1 [] { ["email" "month" "one-time" "week" "year"] }
def style-completer [] { ["fixed" "pay-what-you-want" "usage-based"] }
def X-Buttondown-Collision-Behavior-completer [] { ["add" "fail" "no_op" "overwrite"] }
def status-completer-2 [] { ["disabled" "enabled"] }
def status-completer-3 [] { ["failed" "successful" "unattempted"] }
def event-type-completer-1 [] { ["advertising_slot.inquiry" "advertising_slot.purchased" "automation.invoked" "bigcommerce.customer.created" "bigcommerce.customer.updated" "bigcommerce.order.created" "bigcommerce.order.updated" "date.day.started" "date.month.started" "date.week.started" "date.year.started" "email.created" "email.deleted" "email.sent" "email.status.changed" "email.updated" "export.completed" "export.created" "export.failed" "external_feed_item.created" "firewall.blocked" "form.created" "form.deleted" "form.updated" "memberful.member.updated" "memberful.subscription.created" "memberful.subscription.deleted" "mention.created" "note.created" "note.deleted" "patreon.member.updated" "patreon.membership.created" "patreon.membership.deleted" "shopify.customer.created" "shopify.customer.updated" "social_mention.created" "stripe.checkout.session.completed" "stripe.customer.updated" "stripe.subscription.activated" "stripe.subscription.churning" "stripe.subscription.deactivated" "subscriber.bounced" "subscriber.changed_email" "subscriber.churned" "subscriber.clicked" "subscriber.commented" "subscriber.complained" "subscriber.confirmed" "subscriber.created" "subscriber.deleted" "subscriber.delivered" "subscriber.opened" "subscriber.paid" "subscriber.paused" "subscriber.referred" "subscriber.referred.paid" "subscriber.rejected" "subscriber.replied" "subscriber.responded_to_survey" "subscriber.resumed" "subscriber.tags.changed" "subscriber.trial_ended" "subscriber.trial_started" "subscriber.type.changed" "subscriber.unsubscribed" "subscriber.updated" "subscriber.viewed_checkout_page" "survey.cleared_responses" "survey.created" "survey.deleted" "survey.updated"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts-me account" } } | get name | first)
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

# Get Account
#
# GET /accounts/me
# operationId: get_account
export def "accounts-me account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<username: string, email_address: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Advertising Units
#
# GET /advertising_units
# operationId: list_advertising_units
export def "advertising-units units" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, status: string, slots: list, title: string, description: string, behavior: string, url: string, price: any, allows_html: bool, allows_image: bool, max_characters: any, submission_deadline_days: int>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/advertising_units" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Advertising Unit
#
# POST /advertising_units
# operationId: create_advertising_unit
export def "advertising-units unit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string # The title of the advertising unit.
  --description: string # A description of the advertising unit. (default: )
  --behavior: string # The behavior type of the advertising unit. (default: )
  --body-url: string # The URL for the advertising unit's landing page. (default: )
  --price: any # The price in the smallest currency unit.
  --allows-html: oneof<nothing, bool> # Whether the advertising unit accepts HTML content. (default: false)
  --allows-image: oneof<nothing, bool> # Whether the advertising unit accepts an image. (default: false)
  --max-characters: any # Maximum number of characters allowed for the ad content.
  --submission-deadline-days: int # Number of days before the slot date that content must be submitted. (default: 3)
]: any -> record<id: string, creation_date: string, status: string, slots: table<id: string, creation_date: string, date: string, status: string, invoice_url: any, sku_id: string, submission_url: string, sponsor_company: string, sponsor_email: string, sponsor_name: string, content: string, content_image_id: any, content_url: string, content_approved_at: any, content_rejected_at: any, content_rejection_reason: string, content_submitted_at: any, inquiry_message: string>, title: string, description: string, behavior: string, url: string, price: any, allows_html: bool, allows_image: bool, max_characters: any, submission_deadline_days: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/advertising_units")
  let body = {title: $title, description: $description, behavior: $behavior, url: $body_url, price: $price, allows_html: $allows_html, allows_image: $allows_image, max_characters: $max_characters, submission_deadline_days: $submission_deadline_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Advertising Unit
#
# PATCH /advertising_units/{id}
# operationId: update_advertising_unit
export def "advertising-units unit-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: any # The title of the advertising unit.
  --description: any # A description of the advertising unit.
  dates: list # The dates for this advertising unit's slots.
  --behavior: any # The behavior type of the advertising unit.
  --body-url: any # The URL for the advertising unit's landing page.
  --price: any # The price in the smallest currency unit.
  --allows-html: any # Whether the advertising unit accepts HTML content.
  --allows-image: any # Whether the advertising unit accepts an image.
  --max-characters: any # Maximum number of characters allowed for the ad content.
  --submission-deadline-days: any # Number of days before the slot date that content must be submitted.
]: any -> record<id: string, creation_date: string, status: string, slots: table<id: string, creation_date: string, date: string, status: string, invoice_url: any, sku_id: string, submission_url: string, sponsor_company: string, sponsor_email: string, sponsor_name: string, content: string, content_image_id: any, content_url: string, content_approved_at: any, content_rejected_at: any, content_rejection_reason: string, content_submitted_at: any, inquiry_message: string>, title: string, description: string, behavior: string, url: string, price: any, allows_html: bool, allows_image: bool, max_characters: any, submission_deadline_days: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/advertising_units/($id)")
  let body = {title: $title, description: $description, dates: $dates, behavior: $behavior, url: $body_url, price: $price, allows_html: $allows_html, allows_image: $allows_image, max_characters: $max_characters, submission_deadline_days: $submission_deadline_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Advertising Unit
#
# DELETE /advertising_units/{id}
# operationId: delete_advertising_unit
export def "advertising-units unit-by-id-1" [
  id: string
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
  let full_url = (build-url $base $"/advertising_units/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Advertising Slots
#
# GET /advertising_units/slots
# operationId: list_advertising_slots
export def "advertising-units-slots slots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, date: string, status: string, invoice_url: any, sku_id: string, submission_url: string, sponsor_company: string, sponsor_email: string, sponsor_name: string, content: string, content_image_id: any, content_url: string, content_approved_at: any, content_rejected_at: any, content_rejection_reason: string, content_submitted_at: any, inquiry_message: string>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/advertising_units/slots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Advertising Slot
#
# PATCH /advertising_units/slots/{id}
# operationId: update_advertising_slot
export def "advertising-units-slots slot" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: any # The ad content text.
  --content-approved-at: any # When the ad content was approved.
  --content-image-id: any # The ID of the image attached to this ad.
  --content-rejection-reason: any # The reason the ad content was rejected.
  --content-url: any # The URL the ad links to.
  --sponsor-company: any # The name of the sponsoring company.
  --sponsor-email: any # The email address of the sponsor contact.
  --sponsor-name: any # The name of the sponsor contact.
  --status: any # Set to 'approve', 'reject', 'hold_accept', or 'hold_decline' to update the slot status.
]: any -> record<id: string, creation_date: string, date: string, status: string, invoice_url: any, sku_id: string, submission_url: string, sponsor_company: string, sponsor_email: string, sponsor_name: string, content: string, content_image_id: any, content_url: string, content_approved_at: any, content_rejected_at: any, content_rejection_reason: string, content_submitted_at: any, inquiry_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/advertising_units/slots/($id)")
  let body = {content: $content, content_approved_at: $content_approved_at, content_image_id: $content_image_id, content_rejection_reason: $content_rejection_reason, content_url: $content_url, sponsor_company: $sponsor_company, sponsor_email: $sponsor_email, sponsor_name: $sponsor_name, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve Api Request
#
# GET /api_requests/{id}
# operationId: retrieve_api_request
export def "api-requests request" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, creation_date: string, status_code: int, path: string, method: string, source: string, version: string, ip_address: string, api_key_id: any, api_key_label: any, request_data: string, response_data: any, headers: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_requests/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Api Requests
#
# GET /api_requests
# operationId: list_api_requests
export def "api-requests requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key-id: list # If provided, only return requests made with the given [API key](https://docs.buttondown.com/api-authentication) ID(s). (default: [])
  --creation-date-gt: string # If provided, only return requests created after the given datetime. (format: date-time, e.g. 2024-01-01T00:00:00Z)
  --creation-date-lt: string # If provided, only return requests created before the given datetime. (format: date-time, e.g. 2024-12-31T23:59:59Z)
  --date-end: string # If provided, only return requests created on or before the given date. (format: date)
  --date-start: string # If provided, only return requests created on or after the given date. (format: date)
  --limit: int # The maximum number of results to return per page. (e.g. 100)
  --method: list # If provided, only return requests with the given HTTP method(s). (e.g. [GET, POST])
  --path: list # If provided, only return requests matching the given API path(s). (default: [])
  --qp-source: list # If provided, only return requests from the given source(s). (e.g. [api])
  --status-code: list # If provided, only return requests with the given HTTP status code(s). (e.g. [200, 404])
  --version: list # If provided, only return requests made with the given [API version](https://docs.buttondown.com/api-versioning)(s).
]: nothing -> record<results: table<id: string, creation_date: string, status_code: int, path: string, method: string, source: string, version: string, ip_address: string, api_key_id: any, api_key_label: any>, cursor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key_id" $api_key_id "multi") (serialize-qp "creation_date__gt" $creation_date_gt "scalar") (serialize-qp "creation_date__lt" $creation_date_lt "scalar") (serialize-qp "date__end" $date_end "scalar") (serialize-qp "date__start" $date_start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "method" $method "multi") (serialize-qp "path" $path "multi") (serialize-qp "source" $qp_source "multi") (serialize-qp "status_code" $status_code "multi") (serialize-qp "version" $version "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Attachment
#
# POST /attachments
# operationId: create_attachment
export def "attachments attachment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # format: binary
  --name: any
]: any -> record<id: string, creation_date: string, name: string, file: string, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attachments")
  let body = {file: $file, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# List Attachments
#
# GET /attachments
# operationId: list_attachments
export def "attachments attachments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list # If provided, only return attachments matching the given IDs. (e.g. [att_01h8xg4j3k2m1n0p9q8r7s6t5v])
  --page-size: int # The number of results per page. (default: 100)
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, name: string, file: string, size: int>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Attachment
#
# GET /attachments/{id}
# operationId: retrieve_attachment
export def "attachments attachment-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, creation_date: string, name: string, file: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/attachments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Attachment
#
# DELETE /attachments/{id}
# operationId: delete_attachment
export def "attachments attachment-by-id-1" [
  id: string
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
  let full_url = (build-url $base $"/attachments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Automations
#
# GET /automations
# operationId: list_automations
export def "automations automations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, name: string, status: string, trigger: string, actions: list, filters: record, metadata: record, should_evaluate_filter_after_delay: bool>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/automations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Automation
#
# POST /automations
# operationId: create_automation
# --actions item shape: {type: "add_tags"|"remove_tags"|"send_email"|"add_metadata"|"change_email_address"|"gift_premium_subscription"|"ungift_premium_subscription"|"send_discord_invitation"|"send_github_invitation"|"create_subscriber"|"unsubscribe_subscriber"|"shopify_unsubscribe"|"shopify_resubscribe"|"shopify_set_tags"|"shopify_create_customer"|"send_notification"|"forward_reply"|"create_arena_post"|"create_bluesky_post"|"create_linkedin_post"|"create_mastodon_post"|"create_tumblr_post"|"create_twitter_post"|"create_export"|"create_gift_subscriber"|"send_post_request"|"send_confirmation_reminder"|"update_email_type", metadata?: record, timing?: any}
export def "automations automation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the automation.
  trigger: string@trigger-completer # Various types of events that are recorded by Buttondown, both in terms of exogenous systems like Stripe and Memberful, and endogenous ones like email opens and clicks. (In general, if anything important ever happens that could be relevant to your newsletter, we have an event type for it!)  These event types power lots of things within Buttondown. They're used to trigger automations, webhooks, and analytics.  (Note that Buttondown also has a different thing we call "events"; those are `EmailEvents` and are used for tracking aggregate details about an email. Alas, we shouldn't have used the term "event" for two different things, but it's too late to go back now!)  In general, our event namespacing tries to hew to the following pattern:  `<source>.<object>.<action>`  When wondering which object we are referring to, default to the _more granular_ object.  For instance, an email being sent to a subscriber is `subscriber.delivered`, not `email.sent`.
  actions: list # The actions to perform when the trigger fires. — item shape: {type: "add_tags"|"remove_tags"|"send_email"|"add_metadata"|"change_email_address"|"gift_premium_subscription"|"ungift_premium_subscription"|"send_discord_invitation"|"send_github_invitation"|"create_subscriber"|"unsubscribe_subscriber"|"shopify_unsubscribe"|"shopify_resubscribe"|"shopify_set_tags"|"shopify_create_customer"|"send_notification"|"forward_reply"|"create_arena_post"|"create_bluesky_post"|"create_linkedin_post"|"create_mastodon_post"|"create_tumblr_post"|"create_twitter_post"|"create_export"|"create_gift_subscriber"|"send_post_request"|"send_confirmation_reminder"|"update_email_type", metadata?: record, timing?: any}
  --filters: any # Conditions that must be met for the automation to run. Omit or pass null for no filter.
  --metadata: record # Additional metadata for the automation.
  --should-evaluate-filter-after-delay: oneof<nothing, bool> # If true, filters are re-evaluated after the delay has passed. (default: false)
]: any -> record<id: string, creation_date: string, name: string, status: string, trigger: string, actions: table<type: string, metadata: record, timing: any>, filters: record<filters: list<record>, groups: list<any>, predicate: string>, metadata: record, should_evaluate_filter_after_delay: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/automations")
  let body = {name: $name, trigger: $trigger, actions: $actions, filters: $filters, metadata: $metadata, should_evaluate_filter_after_delay: $should_evaluate_filter_after_delay} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve Automation
#
# GET /automations/{id}
# operationId: retrieve_automation
export def "automations automation-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, creation_date: string, name: string, status: string, trigger: string, actions: table<type: string, metadata: record, timing: any>, filters: record<filters: list<record>, groups: list<any>, predicate: string>, metadata: record, should_evaluate_filter_after_delay: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Automation
#
# PATCH /automations/{id}
# operationId: update_automation
export def "automations automation-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: any # The name of the automation.
  --status: any # Whether the automation is enabled or disabled.
  --trigger: any # The event that causes this automation to run.
  --timing: any # When to execute the automation's actions.
  --actions: any # The actions to perform when the trigger fires.
  --filters: any # Conditions that must be met for the automation to run.
  --metadata: any # Additional metadata for the automation.
  --should-evaluate-filter-after-delay: any # If true, filters are re-evaluated after the delay has passed.
]: any -> record<id: string, creation_date: string, name: string, status: string, trigger: string, actions: table<type: string, metadata: record, timing: any>, filters: record<filters: list<record>, groups: list<any>, predicate: string>, metadata: record, should_evaluate_filter_after_delay: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($id)")
  let body = {name: $name, status: $status, trigger: $trigger, timing: $timing, actions: $actions, filters: $filters, metadata: $metadata, should_evaluate_filter_after_delay: $should_evaluate_filter_after_delay} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Automation
#
# DELETE /automations/{id}
# operationId: delete_automation
export def "automations automation-by-id-2" [
  id: string
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
  let full_url = (build-url $base $"/automations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke Automation
#
# POST /automations/{id}/invoke
# operationId: invoke_automation
export def "automations-invoke automation" [
  id: string
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
  let full_url = (build-url $base $"/automations/($id)/invoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Automation Analytics
#
# GET /automations/{id}/analytics
# operationId: retrieve_automation_analytics
export def "automations-analytics analytics" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<recipients: int, deliveries: int, opens: int, clicks: int, temporary_failures: int, permanent_failures: int, unsubscriptions: int, complaints: int, survey_responses: int, webmentions: int, page_views_lifetime: int, page_views_30: int, page_views_7: int, subscriptions: int, paid_subscriptions: int, replies: int, comments: int, social_mentions: int, temporary_failure_breakdown: table<code: string, count: int>, permanent_failure_breakdown: table<code: string, count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automations/($id)/analytics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Book
#
# POST /books
# operationId: create_book
export def "books book" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string # The title of the book.
  --body-url: string # The URL where the book can be purchased or viewed. (default: )
  --image-url: string # The URL of the book's cover image. (default: )
  --description: string # A description of the book. (default: )
  --year: any # The year the book was published.
  --isbn: string # The ISBN of the book. (default: )
  --shared: oneof<nothing, bool> # Whether the book is displayed publicly on the archive. (default: true)
]: any -> record<id: string, creation_date: string, title: string, url: string, image_url: string, description: string, year: any, isbn: string, shared: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/books")
  let body = {title: $title, url: $body_url, image_url: $image_url, description: $description, year: $year, isbn: $isbn, shared: $shared} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Books
#
# GET /books
# operationId: list_books
export def "books books" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, title: string, url: string, image_url: string, description: string, year: any, isbn: string, shared: bool>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Book
#
# GET /books/{id}
# operationId: retrieve_book
export def "books book-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, creation_date: string, title: string, url: string, image_url: string, description: string, year: any, isbn: string, shared: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/books/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Book
#
# PATCH /books/{id}
# operationId: update_book
export def "books book-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: any # The title of the book.
  --body-url: any # The URL where the book can be purchased or viewed.
  --image-url: any # The URL of the book's cover image.
  --description: any # A description of the book.
  --year: any # The year the book was published.
  --isbn: any # The ISBN of the book.
  --shared: any # Whether the book is displayed publicly on the archive.
]: any -> record<id: string, creation_date: string, title: string, url: string, image_url: string, description: string, year: any, isbn: string, shared: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/books/($id)")
  let body = {title: $title, url: $body_url, image_url: $image_url, description: $description, year: $year, isbn: $isbn, shared: $shared} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Book
#
# DELETE /books/{id}
# operationId: delete_book
export def "books book-by-id-2" [
  id: string
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
  let full_url = (build-url $base $"/books/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Bulk Action
#
# POST /bulk_actions
# operationId: create_bulk_action
export def "bulk-actions action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer # Represents the action being performed on a bulk of objects.  (Not to be coy, but these names should be self-explanatory.)
  metadata: record # Parameters for the bulk action. The exact shape depends on `type` — typically an `ids` list of object IDs to act on. (e.g. {ids: [611c8825-6f21-4544-bb47-9f50453e9cb0, 418c701a-efe3-4e3d-a404-e635a2f28775]})
]: any -> record<id: string, creation_date: string, type: string, metadata: record, status: string, completion_date: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bulk_actions")
  let body = {type: $type, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve Bulk Action
#
# GET /bulk_actions/{id}
# operationId: retrieve_bulk_action
export def "bulk-actions action-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, creation_date: string, type: string, metadata: record, status: string, completion_date: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bulk_actions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Comment
#
# POST /comments
# operationId: create_comment
export def "comments comment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # The text content of the comment.
  --parent-id: any # The ID of the parent comment, if this comment is a reply to another comment.
  --email-id: any # The ID of the email this comment is for. Required if parent_id is not provided.
  --subscriber-id: any # The ID of the subscriber to attribute the comment to. If not provided, the comment is attributed to the newsletter author.
]: any -> record<id: string, creation_date: string, email_id: string, subscriber_id: any, parent_id: any, text: string, status: string, subscriber: any, email: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comments")
  let body = {text: $text, parent_id: $parent_id, email_id: $email_id, subscriber_id: $subscriber_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Comments
#
# GET /comments
# operationId: list_comments
export def "comments comments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email-id: string # If provided, only return comments for the given [email](https://docs.buttondown.com/api-emails-introduction). (e.g. [em_01h8xg4j3k2m1n0p9q8r7s6t5v])
  --subscriber-id: string # If provided, only return comments for the given [subscriber](https://docs.buttondown.com/api-subscribers-introduction). (e.g. [sub_01h8xg4j3k2m1n0p9q8r7s6t5v])
  --parent-id: string # If provided, only return comments that are replies to the given parent comment. (e.g. [com_01h8xg4j3k2m1n0p9q8r7s6t5v])
  --expand: list # If provided, expand the given field. (Only supported fields: 'subscriber', 'email').
  --ordering: string # The ordering to apply to the results. (default: -creation_date, e.g. -creation_date)
  --status: string@status-completer # If provided, only return comments with the given status. Only the newsletter owner can filter by status; subscribers always see active comments.
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, email_id: string, subscriber_id: any, parent_id: any, text: string, status: string, subscriber: any, email: any>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email_id" $email_id "scalar") (serialize-qp "subscriber_id" $subscriber_id "scalar") (serialize-qp "parent_id" $parent_id "scalar") (serialize-qp "expand" $expand "multi") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Comment
#
# GET /comments/{id}
# operationId: retrieve_comment
export def "comments comment-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, creation_date: string, email_id: string, subscriber_id: any, parent_id: any, text: string, status: string, subscriber: any, email: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Comment
#
# PATCH /comments/{id}
# operationId: update_comment
export def "comments comment-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-1 # The new status for the comment. Use 'active' to approve or 'spammy' to mark as spam.
]: any -> record<id: string, creation_date: string, email_id: string, subscriber_id: any, parent_id: any, text: string, status: string, subscriber: any, email: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comments/($id)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Comment
#
# DELETE /comments/{id}
# operationId: delete_comment
export def "comments comment-by-id-2" [
  id: string
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
  let full_url = (build-url $base $"/comments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Coupons
#
# GET /coupons
# operationId: list_coupons
export def "coupons coupons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<coupon_id: string, percent_off: any, amount_off: any, name: any>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/coupons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Email
#
# POST /emails
# operationId: create_email
@deprecated --flag email-type
export def "emails email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachments: list # A list of attachment IDs present on the email. (See [Attachments](https://docs.buttondown.com/api-attachments-introduction) for more information.) (default: [])
  --publish-date: any # The date and time at which the email should be published in the future (for scheduled emails), or the date and time at which the email was published (for sent emails).
  subject: string # The subject line for the email. (e.g. The subject line for the email)
  --slug: any # A short, human-readable identifier for the email, used in the archive URL.
  --description: string # A human-readable description of the email, used for archives and SEO. (default: )
  --canonical-url: string # The URL of the original source of the content. (default: )
  --image: string # A primary image URL used when previewing the email on the web or in other contexts. (default: )
  --body-body: string # The body of the email, in either HTML or markdown format. Buttondown attempts to intelligently detect the format of the body automatically, but you can also specify the format explicitly by prepending the text with the `buttondown-editor-mode` comment: `<!-- buttondown-editor-mode: fancy -->` or `<!-- buttondown-editor-mode: plaintext -->`. (default: , e.g. This is an example of the body of an email.)
  --archival-mode: any # Controls who can view this email in the archive. (default: enabled)
  --email-type: any # The type of email. Defaults to `PUBLIC`. (DEPRECATED, default: public)
  --status: any # The status of the email (e.g. `draft`, `about_to_send`, `sent`, `scheduled`). (default: about_to_send)
  --metadata: record # A structured key-value blob that you can use to store arbitrary data on the object. Metadata can be nested — you can store objects and arrays within your metadata. (You can [read more about metadata.](https://docs.buttondown.com/metadata)) (default: {})
  --secondary-id: any # An informal 'number' for the email, used in some templates (e.g. 'This was issue #123').
  --filters: any # Tag-based filter rules determining which subscribers receive this email. (default: {filters: [], groups: [], predicate: and})
  --commenting-mode: any # Controls whether subscribers can comment on this email. (default: enabled)
  --related-email-ids: list # IDs of emails related to this one. Shown at the bottom of the email and archive pages.
  --featured: oneof<nothing, bool> # Designated whether or not this email should be highlighted within the archives. (default: false)
  --should-trigger-pay-per-email-billing: oneof<nothing, bool> # Whether this email should trigger pay-per-email billing for paid subscribers. Use this to differentiate between free updates and premium newsletters. (default: false)
]: any -> record<id: string, creation_date: string, absolute_url: string, analytics: any, callouts: list<string>, attachments: any, body: string, canonical_url: string, commenting_mode: string, description: string, archival_mode: string, email_type: record, featured: bool, filters: record<filters: list<record>, groups: list<any>, predicate: string>, image: string, metadata: record, modification_date: string, publish_date: any, related_email_ids: list<string>, secondary_id: any, should_trigger_pay_per_email_billing: bool, slug: any, source: string, status: string, subject: string, suppression_reason: any, template: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/emails")
  let body = {attachments: $attachments, publish_date: $publish_date, subject: $subject, slug: $slug, description: $description, canonical_url: $canonical_url, image: $image, body: $body_body, archival_mode: $archival_mode, email_type: $email_type, status: $status, metadata: $metadata, secondary_id: $secondary_id, filters: $filters, commenting_mode: $commenting_mode, related_email_ids: $related_email_ids, featured: $featured, should_trigger_pay_per_email_billing: $should_trigger_pay_per_email_billing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Emails
#
# GET /emails
# operationId: list_emails
@deprecated --flag email-type
export def "emails emails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: list # If provided, only return [emails](https://docs.buttondown.com/api-emails-introduction) with the given status.
  --status: list # If provided, only return [emails](https://docs.buttondown.com/api-emails-introduction) without the given status. (e.g. [draft])
  --ids: list # If provided, only return emails with the given IDs.
  --ordering: string # The ordering to apply to the results. (default: creation_date, e.g. -publish_date)
  --creation-date-start: string # If provided, only return emails created after the given date.
  --creation-date-end: string # If provided, only return emails created before the given date.
  --publish-date-start: string # If provided, only return emails published after the given date.
  --publish-date-end: string # If provided, only return emails published before the given date.
  --excluded-fields: list # If provided, exclude the given field(s) from the response. This can improve performance for large responses. (e.g. [body])
  --qp-source: list # If provided, only return emails from the given source(s). (e.g. [api])
  --archival-mode: list # If provided, only return emails with the given archival mode.
  --email-type: list # The type of emails to return. Defaults to all types. (DEPRECATED)
  --subject: string # If provided, only return emails with a subject that contains the given string.
  --attachments: list # If provided, only return emails with the given attachments.
  --snippet-id: list # If provided, only return emails that reference the given [snippets](https://docs.buttondown.com/api-snippets-introduction).
  --deliveries-start: int # If provided, only return emails with at least this many deliveries. (e.g. 100)
  --deliveries-end: int # If provided, only return emails with at most this many deliveries. (e.g. 1000)
  --click-rate-start: float # If provided, only return emails with a click rate greater than or equal to the given value. (e.g. 0.1)
  --click-rate-end: float # If provided, only return emails with a click rate less than or equal to the given value. (e.g. 0.5)
  --open-rate-start: float # If provided, only return emails with an open rate greater than or equal to the given value. (e.g. 0.2)
  --open-rate-end: float # If provided, only return emails with an open rate less than or equal to the given value. (e.g. 0.8)
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, absolute_url: string, analytics: any, callouts: list, attachments: any, body: string, canonical_url: string, commenting_mode: string, description: string, archival_mode: string, email_type: record, featured: bool, filters: record, image: string, metadata: record, modification_date: string, publish_date: any, related_email_ids: list, secondary_id: any, should_trigger_pay_per_email_billing: bool, slug: any, source: string, status: string, subject: string, suppression_reason: any, template: any>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "multi") (serialize-qp "-status" $status "multi") (serialize-qp "ids" $ids "multi") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "creation_date__start" $creation_date_start "scalar") (serialize-qp "creation_date__end" $creation_date_end "scalar") (serialize-qp "publish_date__start" $publish_date_start "scalar") (serialize-qp "publish_date__end" $publish_date_end "scalar") (serialize-qp "excluded_fields" $excluded_fields "multi") (serialize-qp "source" $qp_source "multi") (serialize-qp "archival_mode" $archival_mode "multi") (serialize-qp "email_type" $email_type "multi") (serialize-qp "subject" $subject "scalar") (serialize-qp "attachments" $attachments "multi") (serialize-qp "snippet_id" $snippet_id "multi") (serialize-qp "deliveries__start" $deliveries_start "scalar") (serialize-qp "deliveries__end" $deliveries_end "scalar") (serialize-qp "click_rate__start" $click_rate_start "scalar") (serialize-qp "click_rate__end" $click_rate_end "scalar") (serialize-qp "open_rate__start" $open_rate_start "scalar") (serialize-qp "open_rate__end" $open_rate_end "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/emails" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Email
#
# PATCH /emails/{id}
# operationId: update_email
@deprecated --flag email-type
export def "emails email-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachments: any # A list of attachment IDs present on the email. (See [Attachments](https://docs.buttondown.com/api-attachments-introduction) for more information.)
  --publish-date: any # The date and time at which the email should be published in the future (for scheduled emails), or the date and time at which the email was published (for sent emails). Pass `"none"` to clear a scheduled date.
  --subject: any # The subject line for the email. (e.g. The subject line for the email)
  --description: any # A human-readable description of the email, used for archives and SEO.
  --canonical-url: any # The URL of the original source of the content. (e.g. https://sheinhardtwig.com/2025/01/17/our-nbc-partnership)
  --body-body: any # The body of the email, in either HTML or markdown format. Buttondown attempts to intelligently detect the format of the body automatically, but you can also specify the format explicitly by prepending the text with the `buttondown-editor-mode` comment: `<!-- buttondown-editor-mode: fancy -->` or `<!-- buttondown-editor-mode: plaintext -->`. (e.g. This is an example of the body of an email.)
  --archival-mode: any # Controls who can view this email in the archive.
  --email-type: any # The type of email. Defaults to `PUBLIC`. (DEPRECATED)
  --status: any # The status of the email (e.g. `draft`, `about_to_send`, `sent`, `scheduled`).
  --suppression-reason: any # If the email has been suppressed from sending, the reason why.
  --metadata: any # A structured key-value blob that you can use to store arbitrary data on the object. Metadata can be nested — you can store objects and arrays within your metadata. (You can [read more about metadata.](https://docs.buttondown.com/metadata)) (default: {})
  --image: string # A primary image URL used when previewing the email on the web or in other contexts. (default: )
  --slug: any # A short, human-readable identifier for the email, used in the archive URL. (e.g. hello-world)
  --secondary-id: any # An informal 'number' for the email, used in some templates (e.g. 'This was issue #123').
  --filters: any # Tag-based filter rules determining which subscribers receive this email.
  --template: any # If present, this template overrides your newsletter's default email template. Pass `"none"` to clear an override.
  --commenting-mode: any # Controls whether subscribers can comment on this email.
  --related-email-ids: any # IDs of emails related to this one. Shown at the bottom of the email and archive pages.
  --featured: any # Designated whether or not this email should be highlighted within the archives.
  --should-trigger-pay-per-email-billing: any # Whether this email should trigger pay-per-email billing for paid subscribers. Use this to differentiate between free updates and premium newsletters.
]: any -> record<id: string, creation_date: string, absolute_url: string, analytics: any, callouts: list<string>, attachments: any, body: string, canonical_url: string, commenting_mode: string, description: string, archival_mode: string, email_type: record, featured: bool, filters: record<filters: list<record>, groups: list<any>, predicate: string>, image: string, metadata: record, modification_date: string, publish_date: any, related_email_ids: list<string>, secondary_id: any, should_trigger_pay_per_email_billing: bool, slug: any, source: string, status: string, subject: string, suppression_reason: any, template: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/emails/($id)")
  let body = {attachments: $attachments, publish_date: $publish_date, subject: $subject, description: $description, canonical_url: $canonical_url, body: $body_body, archival_mode: $archival_mode, email_type: $email_type, status: $status, suppression_reason: $suppression_reason, metadata: $metadata, image: $image, slug: $slug, secondary_id: $secondary_id, filters: $filters, template: $template, commenting_mode: $commenting_mode, related_email_ids: $related_email_ids, featured: $featured, should_trigger_pay_per_email_billing: $should_trigger_pay_per_email_billing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve Email
#
# GET /emails/{id}
# operationId: retrieve_email
export def "emails email-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, creation_date: string, absolute_url: string, analytics: any, callouts: list<string>, attachments: any, body: string, canonical_url: string, commenting_mode: string, description: string, archival_mode: string, email_type: record, featured: bool, filters: record<filters: list<record>, groups: list<any>, predicate: string>, image: string, metadata: record, modification_date: string, publish_date: any, related_email_ids: list<string>, secondary_id: any, should_trigger_pay_per_email_billing: bool, slug: any, source: string, status: string, subject: string, suppression_reason: any, template: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/emails/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Email
#
# DELETE /emails/{id}
# operationId: delete_email
export def "emails email-by-id-2" [
  id: string
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
  let full_url = (build-url $base $"/emails/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Email History
#
# GET /emails/{id}/history
# operationId: retrieve_email_history
export def "emails-history history" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # If provided, expand the given field.
  --field: string # The field to retrieve history for.
  --page: int # The page number of the paginated response. (e.g. 1)
  --ordering: string@ordering-completer # The ordering to apply to the results. (default: creation_date)
  --qp-query: string # If provided, only return history entries matching the given query.
  --page-size: int # The number of results per page. (default: 100)
]: nothing -> record<results: table<history_id: int, creation_date: string, value: string, user_id: any, user: any>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "multi") (serialize-qp "field" $field "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/emails/($id)/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Email History By Id
#
# GET /emails/{id}/history/body/{history_id}
# operationId: retrieve_email_history_by_id
export def "emails-history-body id" [
  id: string
  history_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # If provided, expand the given field.
]: nothing -> record<history_id: int, creation_date: string, value: string, user_id: any, user: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/emails/($id)/history/body/($history_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Email Analytics
#
# GET /emails/{id}/analytics
# operationId: retrieve_email_analytics
export def "emails-analytics analytics" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<recipients: int, deliveries: int, opens: int, clicks: int, temporary_failures: int, permanent_failures: int, unsubscriptions: int, complaints: int, survey_responses: int, webmentions: int, page_views_lifetime: int, page_views_30: int, page_views_7: int, subscriptions: int, paid_subscriptions: int, replies: int, comments: int, social_mentions: int, temporary_failure_breakdown: table<code: string, count: int>, permanent_failure_breakdown: table<code: string, count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/emails/($id)/analytics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Email Renders
#
# GET /emails/{id}/renders
# operationId: retrieve_email_renders
export def "emails-renders renders" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --target: string@target-completer # The target format for the rendered HTML. Use 'email' for rendered_html_for_email or 'html' for rendered_html_for_web.
]: nothing -> record<content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "target" $target "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/emails/($id)/renders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send Draft
#
# POST /emails/{id}/send-draft
# operationId: send_draft
export def "emails-send-draft draft" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscribers: any # A list of subscriber ids to which to send the email. (e.g. [bc5601f4-b180-4e02-8501-c18080662376, 24ee3338-daaf-42b0-bf7b-0cab38972fe5])
  --recipients: any # A list of email addresses to send the email to. (e.g. [telemachus@buttondown.email])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/emails/($id)/send-draft")
  let body = {subscribers: $subscribers, recipients: $recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Events
#
# GET /events
# operationId: list_events
export def "events events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-type: string@event-type-completer # If provided, only return events of the given type (e.g. `delivered`, `opened`, `clicked`).
  --ordering: string # The ordering to apply to the results. (default: -creation_date)
  --expand: list # If provided, expand the given field. (Only supported field: 'subscriber').
  --email-id: string # If provided, only return events for the given email.
  --automation-id: string # If provided, only return events for the given automation.
  --subscriber-id: string # If provided, only return events for the given subscriber.
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, subscriber_id: any, email_id: any, automation_id: any, metadata: record, event_type: string, subscriber: any, email: any, automation: any>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event_type" $event_type "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "expand" $expand "multi") (serialize-qp "email_id" $email_id "scalar") (serialize-qp "automation_id" $automation_id "scalar") (serialize-qp "subscriber_id" $subscriber_id "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Event
#
# GET /events/{id}
# operationId: get_event
export def "events event" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # If provided, expand the given field. (Only supported field: 'subscriber').
]: nothing -> record<id: string, creation_date: string, subscriber_id: any, email_id: any, automation_id: any, metadata: record, event_type: string, subscriber: any, email: any, automation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/events/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Export
#
# POST /exports
# operationId: create_export
export def "exports export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  collections: list # The [collections](https://docs.buttondown.com/api-exports-collections) of objects to export. (e.g. [subscribers])
  --parameters: any # Parameters to pass to the exporter. These are specific to the collection and format, and constrain the export. (e.g. {status: active})
  --format: any # The [format](https://docs.buttondown.com/api-exports-format) of the export files. (default: csv, e.g. csv)
  --columns: any # If provided, the export will only include these columns. (e.g. [id, email])
]: any -> record<id: string, creation_date: string, collections: list<string>, parameters: any, format: record, columns: any, url: any, completion_date: any, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/exports")
  let body = {collections: $collections, parameters: $parameters, format: $format, columns: $columns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Exports
#
# GET /exports
# operationId: list_exports
export def "exports exports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, collections: list, parameters: any, format: record, columns: any, url: any, completion_date: any, status: string>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/exports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Export
#
# GET /exports/{id}
# operationId: retrieve_export
export def "exports export-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, creation_date: string, collections: list<string>, parameters: any, format: record, columns: any, url: any, completion_date: any, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/exports/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create External Feed
#
# POST /external_feeds
# operationId: create_external_feed
# --filters shape: {filters: list, groups: list, predicate: "and"|"or"}
export def "external-feeds feed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # The URL of the RSS feed to poll for new items. (e.g. http://lorem-rss.herokuapp.com/feed)
  behavior: string@behavior-completer # An enumeration.
  cadence: string@cadence-completer # An enumeration.
  --cadence-metadata: any # Additional scheduling details for the selected cadence. `time` is required for `daily`/`weekly`/`monthly` cadences; `weekday` is required for `weekly`; `monthday` is required for `monthly`. See the [cadence metadata reference](https://docs.buttondown.com/api-external-feed-cadence-metadata) for allowed values.
  filters: record # Buttondown's filtering schema can be used for multiple things:  - Filtering [the audience of an email](/api-emails-create) to a specific subset - Creating [finely-tuned automations](/api-automation-introduction)  Filters are fractal; they can be nested in groups, and groups can be nested in other groups. This is accomplished through a tree-like structure. Every "FilterGroup" has a "predicate" field, which is either "and" or "or", which determines how the filters and groups within the group are combined, a "groups" field, which is a list of "FilterGroup" objects (that's that recursive bit!), and a "filters" field, which are the leaf-level filters themselves.  Let's say you want a simple filter: all subscribers who have a tag called "executive". You can do that like this:  ```json {     "filters": [{"field": "subscriber.tags", "operator": "contains", "value": "executive"}],     "groups": [],     "predicate": "and" } ```  Now, let's say you want to filter for subscribers who have a tag called "executive" and a tag called "general-electric". You can do that like this:  ```json {     "filters": [{"field": "subscriber.tags", "operator": "contains", "value": "executive"}, {"field": "subscriber.tags", "operator": "contains", "value": "general-electric"}],     "groups": [],     "predicate": "and" } ```  If you wanted to change that `and` to an `or`, you can do that like this:  ```json {     "filters": [{"field": "subscriber.tags", "operator": "contains", "value": "executive"}, {"field": "subscriber.tags", "operator": "contains", "value": "general-electric"}],     "groups": [],     "predicate": "or" } ```  Now, let's say you want to filter for subscribers who have a tag called "executive" _or_ a tag called "general-electric" and a tag called "admin". This is where the whole nested thing comes in handy. You can do that like this:  ```json {     "filters": [{"field": "subscriber.tags", "operator": "contains", "value": "executive"}],     "groups": [         {             "filters": [{"field": "subscriber.tags", "operator": "contains", "value": "admin"}, {"field": "subscriber.tags", "operator": "contains", "value": "general-electric"}],             "groups": [],             "predicate": "and"         }     ],     "predicate": "or" } ```  You can read more about the specific filter construction in the [Filter documentation](/api-emails-filter). — shape: {filters: list, groups: list, predicate: "and"|"or"}
  subject: string # The subject line template for emails generated from this feed.
  --body-body: string # The body template for emails generated from this feed.
  --label: string # An optional internal label for this feed. (default: )
  --metadata: record # Metadata to be passed to emails rendered by this RSS feed. (e.g. {foo: bar})
  --skip-old-items: oneof<nothing, bool> # Skip items with publish date older than one day from when they're discovered (default: false)
]: any -> record<id: string, creation_date: string, last_checked_date: any, status: string, behavior: string, cadence: string, cadence_metadata: record, filters: record<filters: list<record>, groups: list<any>, predicate: string>, url: string, subject: string, body: string, label: string, metadata: record, skip_old_items: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/external_feeds")
  let body = {url: $body_url, behavior: $behavior, cadence: $cadence, cadence_metadata: $cadence_metadata, filters: $filters, subject: $subject, body: $body_body, label: $label, metadata: $metadata, skip_old_items: $skip_old_items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List External Feed
#
# GET /external_feeds
# operationId: list_external_feed
export def "external-feeds feed-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, last_checked_date: any, status: string, behavior: string, cadence: string, cadence_metadata: record, filters: record, url: string, subject: string, body: string, label: string, metadata: record, skip_old_items: bool>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/external_feeds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update External Feed
#
# PATCH /external_feeds/{id}
# operationId: update_external_feed
export def "external-feeds feed-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --behavior: any
  --cadence: any
  --cadence-metadata: any # Additional scheduling details for the selected cadence. `time` is required for `daily`/`weekly`/`monthly` cadences; `weekday` is required for `weekly`; `monthday` is required for `monthly`. See the [cadence metadata reference](https://docs.buttondown.com/api-external-feed-cadence-metadata) for allowed values.
  --filters: any
  --subject: any
  --body-body: any
  --label: any # An optional internal label for this feed.
  --status: any # The current status of the external feed automation.
  --metadata: any # Metadata to be passed to emails rendered by this RSS feed. (e.g. {foo: bar})
  --skip-old-items: any # Skip items with publish date older than one day from when they're discovered
]: any -> record<id: string, creation_date: string, last_checked_date: any, status: string, behavior: string, cadence: string, cadence_metadata: record, filters: record<filters: list<record>, groups: list<any>, predicate: string>, url: string, subject: string, body: string, label: string, metadata: record, skip_old_items: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/external_feeds/($id)")
  let body = {behavior: $behavior, cadence: $cadence, cadence_metadata: $cadence_metadata, filters: $filters, subject: $subject, body: $body_body, label: $label, status: $status, metadata: $metadata, skip_old_items: $skip_old_items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete External Feed
#
# DELETE /external_feeds/{id}
# operationId: delete_external_feed
export def "external-feeds feed-by-id-1" [
  id: string
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
  let full_url = (build-url $base $"/external_feeds/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve External Feed
#
# GET /external_feeds/{id}
# operationId: retrieve_external_feed
export def "external-feeds feed-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, creation_date: string, last_checked_date: any, status: string, behavior: string, cadence: string, cadence_metadata: record, filters: record<filters: list<record>, groups: list<any>, predicate: string>, url: string, subject: string, body: string, label: string, metadata: record, skip_old_items: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/external_feeds/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Poll Items
#
# POST /external_feeds/{id}/items
# operationId: poll_items
export def "external-feeds-items items-by-id" [
  id: string
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
  let full_url = (build-url $base $"/external_feeds/($id)/items")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Items
#
# GET /external_feeds/{id}/items
# operationId: retrieve_items
export def "external-feeds-items items-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # If provided, expand the given field.
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, status: string, url: string, publish_date: string, title: string, description: string, content: string, author: string, email_id: any, email: any>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "multi") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/external_feeds/($id)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Form
#
# POST /forms
# operationId: create_form
export def "forms form" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string # The human-readable title of the form, shown in the UI and on the hosted form page. (e.g. Contact Form)
  slug: string # A URL-safe identifier used in the form's hosted URL (e.g. `/forms/{slug}`). Must be unique per newsletter. (e.g. contact)
  --body-body: string # Markdown body rendered above the subscribe fields on the hosted form page. (default: , e.g. )
  --css: string # Custom CSS applied to the hosted form page. (default: , e.g. )
  --success-body: string # Markdown shown to the subscriber after a successful submission. (default: , e.g. Thank you for your submission!)
  --surveys: list # IDs of surveys to attach to this form. Responses are associated with the submitting subscriber. (e.g. [])
  --admin: oneof<nothing, bool> # If true, the form acts as an admin-only signup form — it skips confirmation and can accept additional subscriber fields. (default: false, e.g. false)
  --status: any # The status of the form. Only `active` forms accept submissions. (default: active, e.g. active)
]: any -> record<id: string, creation_date: string, title: string, slug: string, body: string, css: string, success_body: string, surveys: list<string>, admin: bool, status: string, subscriber_count: int, confirmed_subscriber_count: int, page_view_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/forms")
  let body = {title: $title, slug: $slug, body: $body_body, css: $css, success_body: $success_body, surveys: $surveys, admin: $admin, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Forms
#
# GET /forms
# operationId: list_forms
export def "forms forms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: list # If provided, only return forms with the given status. (e.g. [active])
  --status: list # If provided, only return forms without the given status. (e.g. [disabled])
  --admin: oneof<nothing, bool> # If provided, filter by admin-only flag.
  --ordering: string # The ordering to apply to the results. (default: -creation_date, e.g. -creation_date)
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, title: string, slug: string, body: string, css: string, success_body: string, surveys: list, admin: bool, status: string, subscriber_count: int, confirmed_subscriber_count: int, page_view_count: int>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "multi") (serialize-qp "-status" $status "multi") (serialize-qp "admin" $admin "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/forms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Form
#
# GET /forms/{id}
# operationId: retrieve_form
export def "forms form-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, creation_date: string, title: string, slug: string, body: string, css: string, success_body: string, surveys: list<string>, admin: bool, status: string, subscriber_count: int, confirmed_subscriber_count: int, page_view_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/forms/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Form
#
# PATCH /forms/{id}
# operationId: update_form
export def "forms form-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: any # The human-readable title of the form, shown in the UI and on the hosted form page.
  --slug: any # A URL-safe identifier used in the form's hosted URL (e.g. `/forms/{slug}`). Must be unique per newsletter.
  --body-body: any # Markdown body rendered above the subscribe fields on the hosted form page.
  --css: any # Custom CSS applied to the hosted form page.
  --success-body: any # Markdown shown to the subscriber after a successful submission.
  --surveys: any # IDs of surveys to attach to this form. Responses are associated with the submitting subscriber.
  --admin: any # If true, the form acts as an admin-only signup form — it skips confirmation and can accept additional subscriber fields.
  --status: any # The status of the form. Only `active` forms accept submissions.
]: any -> record<id: string, creation_date: string, title: string, slug: string, body: string, css: string, success_body: string, surveys: list<string>, admin: bool, status: string, subscriber_count: int, confirmed_subscriber_count: int, page_view_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/forms/($id)")
  let body = {title: $title, slug: $slug, body: $body_body, css: $css, success_body: $success_body, surveys: $surveys, admin: $admin, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Form
#
# DELETE /forms/{id}
# operationId: delete_form
export def "forms form-by-id-2" [
  id: string
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
  let full_url = (build-url $base $"/forms/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Image
#
# POST /images
# operationId: create_image
export def "images image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  image: string # format: binary
  --metadata: string # default: {}
]: any -> record<id: string, creation_date: string, image: string, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/images")
  let body = {image: $image, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# List Images
#
# GET /images
# operationId: list_images
export def "images images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list # If provided, only return images matching the given IDs. (e.g. [img_01h8xg4j3k2m1n0p9q8r7s6t5v])
  --page: int # The page number to return. (default: 1)
  --page-size: int # The number of results per page. (default: 100)
]: nothing -> record<results: table<id: string, creation_date: string, image: string, metadata: record>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Image
#
# PATCH /images/{id}
# operationId: update_image
export def "images image-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata: record # A structured key-value blob that you can use to store arbitrary data on the object. Metadata can be nested — you can store objects and arrays within your metadata. (You can [read more about metadata.](https://docs.buttondown.com/metadata)) (default: {})
]: any -> record<id: string, creation_date: string, image: string, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($id)")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Image
#
# DELETE /images/{id}
# operationId: delete_image
export def "images image-by-id-1" [
  id: string
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
  let full_url = (build-url $base $"/images/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Imports
#
# GET /imports
# operationId: list_imports
export def "imports imports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, type: string, status: string, source: string, label: any, metadata: record, results: any>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/imports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Import
#
# POST /imports
# operationId: create_import
export def "imports import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # format: binary
  --metadata: any
]: any -> record<id: string, creation_date: string, type: string, status: string, source: string, label: any, metadata: record, results: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/imports")
  let body = {file: $file, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve Import
#
# GET /imports/{id}
# operationId: retrieve_import
export def "imports import-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, creation_date: string, type: string, status: string, source: string, label: any, metadata: record, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/imports/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Import
#
# PATCH /imports/{id}
# operationId: update_import
export def "imports import-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: any # An optional label for the import. (e.g. June 2025 migration)
  --metadata: any # Metadata about the import, such as detected column mappings. (e.g. {email_column: 0, metadata_columns: {name: 1}})
  --status: any # The status of the import. Set to 'in_progress' to begin executing the import. (e.g. in_progress)
]: any -> record<id: string, creation_date: string, type: string, status: string, source: string, label: any, metadata: record, results: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/imports/($id)")
  let body = {label: $label, metadata: $metadata, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Import
#
# DELETE /imports/{id}
# operationId: delete_import
export def "imports import-by-id-2" [
  id: string
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
  let full_url = (build-url $base $"/imports/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Newsletters
#
# GET /newsletters
# operationId: list_newsletters
export def "newsletters newsletters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, announcement_bar_background_color: string, announcement_bar_text: string, announcement_bar_visibility: record, api_key: string, archive_theme: record, auditing_mode: any, css: string, custom_churn_email_body: string, custom_churn_email_subject: string, custom_churn_email_template: any, custom_email_template: any, custom_expired_trial_notification_body: string, custom_expired_trial_notification_subject: string, custom_expired_trial_notification_template: any, custom_gift_subscription_email_body: string, custom_gift_subscription_email_subject: string, custom_gift_subscription_email_template: any, custom_gift_unsubscription_email_body: string, custom_gift_unsubscription_email_subject: string, custom_gift_unsubscription_email_template: any, custom_premium_confirmation_email_body: string, custom_premium_confirmation_email_subject: string, custom_premium_confirmation_email_template: any, custom_subscription_confirmation_email_subject: string, custom_subscription_confirmation_email_template: any, custom_subscription_confirmation_email_text: string, custom_subscription_confirmation_reminder_email_subject: string, custom_subscription_confirmation_reminder_email_text: string, custom_subscription_confirmed_email_subject: string, custom_subscription_confirmed_email_text: string, description: string, domain: string, email_address: string, email_domain: string, email_theme_configuration: record, enabled_features: list, footer: string, from_name: string, header: string, icon: any, icon_alt_text: string, image: any, locale: record, metadata: record, name: string, reply_to_address: string, sharing_networks: list, socials: list, sort: string, subscription_confirmation_redirect_url: string, subscription_redirect_url: string, template: record, test_mode: bool, theme_configuration: record, timezone: string, tint_color: string, username: string, web_css: string>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/newsletters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Newsletter
#
# POST /newsletters
# operationId: create_newsletter
# --socials item shape: {type: "generic"|"bluesky"|"bookbub"|"bookshop"|"facebook"|"github"|"goodreads"|"instagram"|"kofi"|"letterboxd"|"linkedin"|"linktree"|"mastodon"|"patreon"|"pinterest"|"threads"|"tiktok"|"twitch"|"twitter"|"youtube", url: string, label?: any}
export def "newsletters newsletter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --announcement-bar-background-color: any # The background color for the announcement bar on your archive page. Must be a valid hex color code. (default: , e.g. #FF6600)
  --announcement-bar-text: string # Text displayed in the announcement bar on your archive page. Useful for promotions, updates, or calls to action. (default: , e.g. Subscribe to get 20% off your first order!)
  --announcement-bar-visibility: any@announcement-bar-visibility-completer # Controls who sees the announcement bar on your archive page. (default: disabled, e.g. everyone)
  --archive-theme: any # The visual theme for your newsletter's archive page. See [archive themes](https://docs.buttondown.com/customizing-web-design) for previews. (default: modern, e.g. modern)
  --auditing-mode: any # The auditing mode for your newsletter, which controls spam and abuse protection. See [the Firewall](https://docs.buttondown.com/firewall) for more information. (e.g. enabled)
  --css: string # Custom CSS styling applied to your newsletter emails. See [CSS customization](https://docs.buttondown.com/customizing-email-design#adding-custom-css) for more information. (default: , e.g. .header { color: #000; })
  --custom-email-template: any # The identifier for a custom email template. See [email templates](https://docs.buttondown.com/customizing-email-design#buttondowns-default-templates) for available options. (e.g. modern)
  description: string # A brief description of your newsletter, displayed on your public archive page and used for SEO. (e.g. Stay up to date with the latest trends in wigs and hairpieces)
  --domain: string # The custom domain where your newsletter archives are hosted (e.g., 'newsletter.example.com'). See [custom domains](https://docs.buttondown.com/hosting-on-a-custom-domain) for setup instructions. (default: , e.g. sheinhardt.com)
  --email-address: any # The 'From' email address used when sending your newsletter. Must be verified before use. (e.g. newsletter@sheinhardt.com)
  --email-domain: string # The custom domain from which your newsletter emails are sent (e.g., 'mail.example.com'). See [sending domains](https://docs.buttondown.com/sending-from-a-custom-domain) for setup instructions. (default: , e.g. mail.sheinhardt.com)
  --email-theme-configuration: record # A dictionary of CSS token overrides for the email theme. (default: {}, e.g. {primary-color: #0069FF})
  --enabled-features: list # A list of features enabled for your newsletter. Common values include 'archives', 'portal', 'surveys', 'comments', 'paid_subscriptions', 'automations', 'webhooks', 'tracking', and 'referrals'. (default: [], e.g. [archives, portal, surveys])
  --footer: string # HTML content displayed at the bottom of your newsletter emails. Supports [template tags](https://docs.buttondown.com/template-tags). (default: , e.g. <p>Thanks for reading!</p>)
  --from-name: string # The display name shown in the 'From' field of your emails (e.g., 'Jane from Acme Newsletter'). (default: , e.g. Sheinhardt Wig Company)
  --header: string # HTML content displayed at the top of your newsletter emails. Supports [template tags](https://docs.buttondown.com/template-tags). (default: , e.g. <p>Welcome to our newsletter!</p>)
  --icon: string # URL to your newsletter's icon image, used as a favicon and in various UI contexts. (default: , e.g. https://example.com/icon.png)
  --icon-alt-text: string # Alt text for the newsletter icon, used by screen readers and shown when the image cannot load. (default: )
  --image: string # URL to your newsletter's header or branding image, displayed on archive pages and in social previews. (default: , e.g. https://example.com/header.jpg)
  --locale: any # The language/locale for your newsletter's UI elements (confirmation emails, unsubscribe pages, etc.). See [localization](https://docs.buttondown.com/localization) for supported locales. (default: en, e.g. en)
  --metadata: record # A structured key-value blob that you can use to store arbitrary data on the object. Metadata can be nested — you can store objects and arrays within your metadata. (You can [read more about metadata.](https://docs.buttondown.com/metadata)) (default: {}, e.g. {source: my-app, tier: pro})
  name: string # The display name of your newsletter, shown to subscribers and on your archive page. (e.g. Sheinhardt Wig Company)
  --reply-to-address: any # An alternative email address that receives replies to your newsletter emails, instead of the sending address. (e.g. newsletter@sheinhardt.com)
  --socials: list # A list of social media accounts linked to your newsletter, displayed on your archive page. Each entry has a `type`, `url`, and optional `label`. (default: [], e.g. [{label: , type: twitter, url: https://x.com/sheinhardt}]) — item shape: {type: "generic"|"bluesky"|"bookbub"|"bookshop"|"facebook"|"github"|"goodreads"|"instagram"|"kofi"|"letterboxd"|"linkedin"|"linktree"|"mastodon"|"patreon"|"pinterest"|"threads"|"tiktok"|"twitch"|"twitter"|"youtube", url: string, label?: any}
  --subscription-confirmation-redirect-url: string # A URL to redirect subscribers to after they confirm their subscription via double opt-in. (default: , e.g. https://example.com/confirmed)
  --subscription-redirect-url: string # A URL to redirect subscribers to immediately after they submit the subscription form (before confirmation). (default: , e.g. https://example.com/thanks)
  --template: any # The default email template for your newsletter. See [email templates](https://docs.buttondown.com/customizing-email-design#buttondowns-default-templates) for available options. (default: modern, e.g. modern)
  --test-mode: any # Whether test mode is enabled. When enabled, emails are not actually sent to subscribers, useful for testing automations and workflows.
  --theme-configuration: record # Custom theme configuration (variables) for your newsletter. These can be referenced in your CSS and templates to maintain consistent styling. (default: {}, e.g. {primary-color: #0069FF})
  --timezone: string # The timezone used for scheduling and displaying dates in your newsletter (e.g., 'America/New_York', 'Europe/London'). (default: Etc/UTC, e.g. America/New_York)
  --tint-color: string # The accent color for your newsletter, used in emails and on your archive page. Must be a valid hex color code. (default: #0069FF, e.g. #0069FF)
  username: string # The unique URL-safe identifier for your newsletter, used in your archive URL (e.g., 'buttondown.com/username'). (e.g. sheinhardt)
  --web-css: string # Custom CSS styling applied to your newsletter's web presence (archive pages, subscription forms, etc.). (default: , e.g. .container { max-width: 800px; })
]: any -> record<id: string, creation_date: string, announcement_bar_background_color: string, announcement_bar_text: string, announcement_bar_visibility: record, api_key: string, archive_theme: record, auditing_mode: any, css: string, custom_churn_email_body: string, custom_churn_email_subject: string, custom_churn_email_template: any, custom_email_template: any, custom_expired_trial_notification_body: string, custom_expired_trial_notification_subject: string, custom_expired_trial_notification_template: any, custom_gift_subscription_email_body: string, custom_gift_subscription_email_subject: string, custom_gift_subscription_email_template: any, custom_gift_unsubscription_email_body: string, custom_gift_unsubscription_email_subject: string, custom_gift_unsubscription_email_template: any, custom_premium_confirmation_email_body: string, custom_premium_confirmation_email_subject: string, custom_premium_confirmation_email_template: any, custom_subscription_confirmation_email_subject: string, custom_subscription_confirmation_email_template: any, custom_subscription_confirmation_email_text: string, custom_subscription_confirmation_reminder_email_subject: string, custom_subscription_confirmation_reminder_email_text: string, custom_subscription_confirmed_email_subject: string, custom_subscription_confirmed_email_text: string, description: string, domain: string, email_address: string, email_domain: string, email_theme_configuration: record, enabled_features: list<string>, footer: string, from_name: string, header: string, icon: any, icon_alt_text: string, image: any, locale: record, metadata: record, name: string, reply_to_address: string, sharing_networks: list<string>, socials: table<type: string, url: string, label: any>, sort: string, subscription_confirmation_redirect_url: string, subscription_redirect_url: string, template: record, test_mode: bool, theme_configuration: record, timezone: string, tint_color: string, username: string, web_css: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/newsletters")
  let body = {announcement_bar_background_color: $announcement_bar_background_color, announcement_bar_text: $announcement_bar_text, announcement_bar_visibility: $announcement_bar_visibility, archive_theme: $archive_theme, auditing_mode: $auditing_mode, css: $css, custom_email_template: $custom_email_template, description: $description, domain: $domain, email_address: $email_address, email_domain: $email_domain, email_theme_configuration: $email_theme_configuration, enabled_features: $enabled_features, footer: $footer, from_name: $from_name, header: $header, icon: $icon, icon_alt_text: $icon_alt_text, image: $image, locale: $locale, metadata: $metadata, name: $name, reply_to_address: $reply_to_address, socials: $socials, subscription_confirmation_redirect_url: $subscription_confirmation_redirect_url, subscription_redirect_url: $subscription_redirect_url, template: $template, test_mode: $test_mode, theme_configuration: $theme_configuration, timezone: $timezone, tint_color: $tint_color, username: $username, web_css: $web_css} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Newsletter
#
# PATCH /newsletters/{id}
# operationId: update_newsletter
export def "newsletters newsletter-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --announcement-bar-background-color: any # The background color for the announcement bar on your archive page. Must be a valid hex color code. (e.g. #FF6600)
  --announcement-bar-text: any # Text displayed in the announcement bar on your archive page. Useful for promotions, updates, or calls to action. (e.g. Subscribe to get 20% off your first order!)
  --announcement-bar-visibility: any@announcement-bar-visibility-completer # Controls who sees the announcement bar on your archive page. (e.g. everyone)
  --archive-theme: any # The visual theme for your newsletter's archive page. See [archive themes](https://docs.buttondown.com/customizing-web-design) for previews. (e.g. modern)
  --auditing-mode: any # The auditing mode for your newsletter, which controls spam and abuse protection. See [the Firewall](https://docs.buttondown.com/firewall) for more information. (e.g. enabled)
  --css: any # Custom CSS styling applied to your newsletter emails. See [CSS customization](https://docs.buttondown.com/customizing-email-design#adding-custom-css) for more information. (e.g. .header { color: #000; })
  --custom-churn-email-body: any # Custom body content for the email sent when a paid subscriber cancels. Supports template tags like `{{ subscriber.email }}` and `{{ newsletter.name }}`. (e.g. Hi {{ subscriber.email }},  We're sorry to see you go!)
  --custom-churn-email-subject: any # Custom subject line for the email sent when a paid subscriber cancels. Supports template tags like `{{ newsletter.name }}`. (e.g. You've canceled your premium subscription to {{ newsletter.name }})
  --custom-churn-email-template: any # The email template to use for churn emails. If not set, uses the newsletter's default template. (e.g. modern)
  --custom-email-template: any # The identifier for a custom email template. See [email templates](https://docs.buttondown.com/customizing-email-design#buttondowns-default-templates) for available options. (e.g. modern)
  --custom-expired-trial-notification-body: any # Custom body content for the email sent when a subscriber's free trial expires. Supports template tags.
  --custom-expired-trial-notification-subject: any # Custom subject line for the email sent when a subscriber's free trial expires. Supports template tags.
  --custom-expired-trial-notification-template: any # The email template to use for expired trial notification emails. If not set, uses the newsletter's default template. (e.g. modern)
  --custom-gift-subscription-email-body: any # Custom body content for the email sent when someone receives a gift subscription. Supports template tags.
  --custom-gift-subscription-email-subject: any # Custom subject line for the email sent when someone receives a gift subscription. Supports template tags.
  --custom-gift-subscription-email-template: any # The email template to use for gift subscription emails. If not set, uses the newsletter's default template. (e.g. modern)
  --custom-gift-unsubscription-email-body: any # Custom body content for the email sent when a gift subscription ends. Supports template tags.
  --custom-gift-unsubscription-email-subject: any # Custom subject line for the email sent when a gift subscription ends. Supports template tags.
  --custom-gift-unsubscription-email-template: any # The email template to use for gift unsubscription emails. If not set, uses the newsletter's default template. (e.g. modern)
  --custom-premium-confirmation-email-body: any # Custom body content for the email sent when a subscriber upgrades to a paid plan. Supports template tags.
  --custom-premium-confirmation-email-subject: any # Custom subject line for the email sent when a subscriber upgrades to a paid plan. Supports template tags.
  --custom-premium-confirmation-email-template: any # The email template to use for premium confirmation emails. If not set, uses the newsletter's default template. (e.g. modern)
  --custom-subscription-confirmation-email-subject: any # Custom subject line for the double opt-in confirmation email sent to new subscribers. Supports template tags.
  --custom-subscription-confirmation-email-text: any # Custom body content for the double opt-in confirmation email. Must contain `{{ confirmation_url }}` as an HTML or Markdown link.
  --custom-subscription-confirmation-email-template: any # The email template to use for subscription confirmation emails. If not set, uses the newsletter's default template. (e.g. modern)
  --custom-subscription-confirmation-reminder-email-subject: any # Custom subject line for the reminder email sent to subscribers who haven't confirmed. Supports template tags.
  --custom-subscription-confirmation-reminder-email-text: any # Custom body content for the reminder email sent to subscribers who haven't confirmed. Supports template tags.
  --custom-subscription-confirmed-email-subject: any # Custom subject line for the email sent after a subscriber confirms their subscription. Supports template tags.
  --custom-subscription-confirmed-email-text: any # Custom body content for the email sent after a subscriber confirms their subscription. Supports template tags.
  --description: any # A brief description of your newsletter, displayed on your public archive page and used for SEO. (e.g. Stay up to date with the latest trends in wigs and hairpieces)
  --domain: any # The custom domain where your newsletter archives are hosted (e.g., 'newsletter.example.com'). See [custom domains](https://docs.buttondown.com/hosting-on-a-custom-domain) for setup instructions. (e.g. sheinhardt.com)
  --email-address: any # The 'From' email address used when sending your newsletter. Must be verified before use. (e.g. newsletter@sheinhardt.com)
  --email-domain: any # The custom domain from which your newsletter emails are sent (e.g., 'mail.example.com'). See [sending domains](https://docs.buttondown.com/sending-from-a-custom-domain) for setup instructions. (e.g. mail.sheinhardt.com)
  --email-theme-configuration: any # A dictionary of CSS token overrides for the email theme. (e.g. {primary-color: #0069FF})
  --enabled-features: any # A list of features enabled for your newsletter. Common values include 'archives', 'portal', 'surveys', 'comments', 'paid_subscriptions', 'automations', 'webhooks', 'tracking', and 'referrals'. (e.g. [archives, portal, surveys])
  --footer: any # HTML content displayed at the bottom of your newsletter emails. Supports [template tags](https://docs.buttondown.com/template-tags). (e.g. <p>Thanks for reading!</p>)
  --from-name: any # The display name shown in the 'From' field of your emails (e.g., 'Jane from Acme Newsletter'). (e.g. Sheinhardt Wig Company)
  --header: any # HTML content displayed at the top of your newsletter emails. Supports [template tags](https://docs.buttondown.com/template-tags). (e.g. <p>Welcome to our newsletter!</p>)
  --icon: any # URL to your newsletter's icon image, used as a favicon and in various UI contexts. (e.g. https://example.com/icon.png)
  --icon-alt-text: any # Alt text for the newsletter icon, used by screen readers and shown when the image cannot load.
  --image: any # URL to your newsletter's header or branding image, displayed on archive pages and in social previews. (e.g. https://example.com/header.jpg)
  --locale: any # The language/locale for your newsletter's UI elements (confirmation emails, unsubscribe pages, etc.). See [localization](https://docs.buttondown.com/localization) for supported locales. (e.g. en)
  --metadata: any # A structured key-value blob that you can use to store arbitrary data on the object. Metadata can be nested — you can store objects and arrays within your metadata. (You can [read more about metadata.](https://docs.buttondown.com/metadata)) (e.g. {source: my-app, tier: pro})
  --name: any # The display name of your newsletter, shown to subscribers and on your archive page. (e.g. Sheinhardt Wig Company)
  --reply-to-address: any # An alternative email address that receives replies to your newsletter emails, instead of the sending address. (e.g. newsletter@sheinhardt.com)
  --socials: any # A list of social media accounts linked to your newsletter, displayed on your archive page. Each entry has a `type`, `url`, and optional `label`. (e.g. [{label: , type: twitter, url: https://x.com/sheinhardt}])
  --subscription-confirmation-redirect-url: any # A URL to redirect subscribers to after they confirm their subscription via double opt-in. (e.g. https://example.com/confirmed)
  --subscription-redirect-url: any # A URL to redirect subscribers to immediately after they submit the subscription form (before confirmation). (e.g. https://example.com/thanks)
  --template: any # The default email template for your newsletter. See [email templates](https://docs.buttondown.com/customizing-email-design#buttondowns-default-templates) for available options. (e.g. modern)
  --test-mode: any # Whether test mode is enabled. When enabled, emails are not actually sent to subscribers, useful for testing automations and workflows.
  --theme-configuration: any # Custom theme configuration (variables) for your newsletter. These can be referenced in your CSS and templates to maintain consistent styling. (e.g. {primary-color: #0069FF})
  --timezone: any # The timezone used for scheduling and displaying dates in your newsletter (e.g., 'America/New_York', 'Europe/London'). (e.g. America/New_York)
  --tint-color: any # The accent color for your newsletter, used in emails and on your archive page. Must be a valid hex color code. (e.g. #0069FF)
  --username: any # The unique URL-safe identifier for your newsletter, used in your archive URL (e.g., 'buttondown.com/username'). (e.g. sheinhardt)
  --web-css: any # Custom CSS styling applied to your newsletter's web presence (archive pages, subscription forms, etc.). (e.g. .container { max-width: 800px; })
]: any -> record<id: string, creation_date: string, announcement_bar_background_color: string, announcement_bar_text: string, announcement_bar_visibility: record, api_key: string, archive_theme: record, auditing_mode: any, css: string, custom_churn_email_body: string, custom_churn_email_subject: string, custom_churn_email_template: any, custom_email_template: any, custom_expired_trial_notification_body: string, custom_expired_trial_notification_subject: string, custom_expired_trial_notification_template: any, custom_gift_subscription_email_body: string, custom_gift_subscription_email_subject: string, custom_gift_subscription_email_template: any, custom_gift_unsubscription_email_body: string, custom_gift_unsubscription_email_subject: string, custom_gift_unsubscription_email_template: any, custom_premium_confirmation_email_body: string, custom_premium_confirmation_email_subject: string, custom_premium_confirmation_email_template: any, custom_subscription_confirmation_email_subject: string, custom_subscription_confirmation_email_template: any, custom_subscription_confirmation_email_text: string, custom_subscription_confirmation_reminder_email_subject: string, custom_subscription_confirmation_reminder_email_text: string, custom_subscription_confirmed_email_subject: string, custom_subscription_confirmed_email_text: string, description: string, domain: string, email_address: string, email_domain: string, email_theme_configuration: record, enabled_features: list<string>, footer: string, from_name: string, header: string, icon: any, icon_alt_text: string, image: any, locale: record, metadata: record, name: string, reply_to_address: string, sharing_networks: list<string>, socials: table<type: string, url: string, label: any>, sort: string, subscription_confirmation_redirect_url: string, subscription_redirect_url: string, template: record, test_mode: bool, theme_configuration: record, timezone: string, tint_color: string, username: string, web_css: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/newsletters/($id)")
  let body = {announcement_bar_background_color: $announcement_bar_background_color, announcement_bar_text: $announcement_bar_text, announcement_bar_visibility: $announcement_bar_visibility, archive_theme: $archive_theme, auditing_mode: $auditing_mode, css: $css, custom_churn_email_body: $custom_churn_email_body, custom_churn_email_subject: $custom_churn_email_subject, custom_churn_email_template: $custom_churn_email_template, custom_email_template: $custom_email_template, custom_expired_trial_notification_body: $custom_expired_trial_notification_body, custom_expired_trial_notification_subject: $custom_expired_trial_notification_subject, custom_expired_trial_notification_template: $custom_expired_trial_notification_template, custom_gift_subscription_email_body: $custom_gift_subscription_email_body, custom_gift_subscription_email_subject: $custom_gift_subscription_email_subject, custom_gift_subscription_email_template: $custom_gift_subscription_email_template, custom_gift_unsubscription_email_body: $custom_gift_unsubscription_email_body, custom_gift_unsubscription_email_subject: $custom_gift_unsubscription_email_subject, custom_gift_unsubscription_email_template: $custom_gift_unsubscription_email_template, custom_premium_confirmation_email_body: $custom_premium_confirmation_email_body, custom_premium_confirmation_email_subject: $custom_premium_confirmation_email_subject, custom_premium_confirmation_email_template: $custom_premium_confirmation_email_template, custom_subscription_confirmation_email_subject: $custom_subscription_confirmation_email_subject, custom_subscription_confirmation_email_text: $custom_subscription_confirmation_email_text, custom_subscription_confirmation_email_template: $custom_subscription_confirmation_email_template, custom_subscription_confirmation_reminder_email_subject: $custom_subscription_confirmation_reminder_email_subject, custom_subscription_confirmation_reminder_email_text: $custom_subscription_confirmation_reminder_email_text, custom_subscription_confirmed_email_subject: $custom_subscription_confirmed_email_subject, custom_subscription_confirmed_email_text: $custom_subscription_confirmed_email_text, description: $description, domain: $domain, email_address: $email_address, email_domain: $email_domain, email_theme_configuration: $email_theme_configuration, enabled_features: $enabled_features, footer: $footer, from_name: $from_name, header: $header, icon: $icon, icon_alt_text: $icon_alt_text, image: $image, locale: $locale, metadata: $metadata, name: $name, reply_to_address: $reply_to_address, socials: $socials, subscription_confirmation_redirect_url: $subscription_confirmation_redirect_url, subscription_redirect_url: $subscription_redirect_url, template: $template, test_mode: $test_mode, theme_configuration: $theme_configuration, timezone: $timezone, tint_color: $tint_color, username: $username, web_css: $web_css} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Newsletter
#
# DELETE /newsletters/{id}
# operationId: delete_newsletter
export def "newsletters newsletter-by-id-1" [
  id: string
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
  let full_url = (build-url $base $"/newsletters/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Note Endpoint
#
# POST /notes
# operationId: create_note_endpoint
export def "notes endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-body: string # The text content of the note. (e.g. This subscriber upgraded to a paid plan.)
  model_type: string@model-type-completer # The type of object this note is attached to (e.g., 'email', 'subscriber'). (e.g. email)
  model_id: string # The UUID or TypeID of the object this note is attached to. (e.g. 13121cd6-0dfc-424c-bb12-988b0a32fcb3)
  --metadata: record # A structured key-value blob that you can use to store arbitrary data on the object. Metadata can be nested — you can store objects and arrays within your metadata. (You can [read more about metadata.](https://docs.buttondown.com/metadata)) (default: {})
]: any -> record<id: string, creation_date: string, body: string, model_type: string, model_id: string, metadata: record, source: string, user_id: any, user: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes")
  let body = {body: $body_body, model_type: $model_type, model_id: $model_id, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Notes
#
# GET /notes
# operationId: list_notes
export def "notes notes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --model-type: string@model-type-completer # Filter notes by the type of object they are attached to.
  --model-id: string # Filter notes by the UUID or TypeID of the object they are attached to.
  --expand: list # If provided, expand the given field.
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, body: string, model_type: string, model_id: string, metadata: record, source: string, user_id: any, user: any>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model_type" $model_type "scalar") (serialize-qp "model_id" $model_id "scalar") (serialize-qp "expand" $expand "multi") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Note Endpoint
#
# DELETE /notes/{id}
# operationId: delete_note_endpoint
export def "notes endpoint-by-id" [
  id: string
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
  let full_url = (build-url $base $"/notes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ping
#
# GET /ping
# operationId: ping
export def "ping ping" [
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
  let full_url = (build-url $base "/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Prices
#
# GET /prices
# operationId: list_prices
export def "prices prices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # If provided, expand the given field.
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<amount: any, cadence: string, currency: string, description: any, maximum_amount: any, minimum_amount: any, product_id: any, style: string, suggested_amount: any, id: string, product: any>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "multi") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Price
#
# POST /prices
# operationId: create_price
export def "prices price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: any # The price amount in the smallest currency unit (e.g. cents).
  cadence: string@cadence-completer-1 # The billing cadence for this price.
  currency: string # The three-letter ISO currency code (e.g. 'usd').
  --description: any # An optional human-readable description of the price.
  --maximum-amount: any # The maximum amount for pay-what-you-want prices.
  --minimum-amount: any # The minimum amount for pay-what-you-want prices.
  --product-id: any # The ID of the Stripe product this price belongs to.
  style: string@style-completer # The pricing style: 'fixed', 'pay-what-you-want', or 'usage-based'.
  --suggested-amount: any # The suggested amount for pay-what-you-want prices.
]: any -> record<amount: any, cadence: string, currency: string, description: any, maximum_amount: any, minimum_amount: any, product_id: any, style: string, suggested_amount: any, id: string, product: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prices")
  let body = {amount: $amount, cadence: $cadence, currency: $currency, description: $description, maximum_amount: $maximum_amount, minimum_amount: $minimum_amount, product_id: $product_id, style: $style, suggested_amount: $suggested_amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search public emails
#
# GET /public/emails/{username}
# operationId: list_public_emails
export def "public-emails emails" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # If provided, only return emails matching the given query.
  --page: int # The page number to return. (default: 1)
]: nothing -> record<results: table<id: string, creation_date: string, subject: string, slug: any, publish_date: any, description: string, absolute_url: string>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/emails/($username)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Snippet
#
# POST /snippets
# operationId: create_snippet
export def "snippets snippet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  identifier: string # A unique, newsletter-scoped slug used to reference the snippet inside email content (e.g. `{{ snippets.footer }}`). Must be unique per newsletter. (e.g. footer)
  name: string # A human-readable name for the snippet, shown in the Buttondown UI. (e.g. Footer)
  --content: string # The body of the snippet, substituted wherever the snippet is referenced. Interpreted according to `mode`. (default: , e.g. Thanks for reading!)
  --mode: any # The editor mode for the snippet, which controls how `content` is rendered: `fancy` (Markdown), `plaintext`, or `naked` (raw HTML with no processing). (default: fancy, e.g. fancy)
]: any -> record<id: string, creation_date: string, identifier: string, name: string, content: string, mode: string, reference_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/snippets")
  let body = {identifier: $identifier, name: $name, content: $content, mode: $mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Snippets
#
# GET /snippets
# operationId: list_snippets
export def "snippets snippets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number of the paginated response. (e.g. [1])
]: nothing -> record<results: table<id: string, creation_date: string, identifier: string, name: string, content: string, mode: string, reference_count: int>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/snippets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Snippet
#
# GET /snippets/{id}
# operationId: retrieve_snippet
export def "snippets snippet-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, creation_date: string, identifier: string, name: string, content: string, mode: string, reference_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Snippet
#
# PATCH /snippets/{id}
# operationId: update_snippet
export def "snippets snippet-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identifier: any # A unique, newsletter-scoped slug used to reference the snippet inside email content (e.g. `{{ snippets.footer }}`). Must be unique per newsletter. (e.g. footer)
  --name: any # A human-readable name for the snippet, shown in the Buttondown UI. (e.g. Footer)
  --content: any # The body of the snippet, substituted wherever the snippet is referenced. Interpreted according to `mode`. (e.g. Thanks for reading!)
  --mode: any # The editor mode for the snippet, which controls how `content` is rendered: `fancy` (Markdown), `plaintext`, or `naked` (raw HTML with no processing). (e.g. fancy)
]: any -> record<id: string, creation_date: string, identifier: string, name: string, content: string, mode: string, reference_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($id)")
  let body = {identifier: $identifier, name: $name, content: $content, mode: $mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Snippet
#
# DELETE /snippets/{id}
# operationId: delete_snippet
export def "snippets snippet-by-id-2" [
  id: string
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
  let full_url = (build-url $base $"/snippets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Subscriber
#
# POST /subscribers
# operationId: create_subscriber
export def "subscribers subscriber" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Buttondown-Collision-Behavior: string@X-Buttondown-Collision-Behavior-completer # The behavior to apply when a subscriber with the same email address already exists. Defaults to "no_op", which will return a 400 error if a subscriber with the same email address already exists. Other values include:  - "overwrite", which will overwrite the existing subscriber's data with the new one. - "add", which will add the new subscriber data to the existing one.         
  --X-Buttondown-Bypass-Firewall: oneof<nothing, bool> # Bypass the firewall for this subscriber creation. Subject to aggressive rate limiting (5 per hour per newsletter).
  email_address: string # The email address of the subscriber. (format: email, e.g. telemachus@buttondown.email)
  --notes: string # Any notes you want to attach to the subscriber. These are not publicly visible. (default: , e.g. One of our first subscribers!)
  --metadata: record # A structured key-value blob that you can use to store arbitrary data on the object. Metadata can be nested — you can store objects and arrays within your metadata. (You can [read more about metadata.](https://docs.buttondown.com/metadata)) (default: {})
  --tags: list # A list of [tag](https://docs.buttondown.com/api-tags-introduction) names applied to the subscriber. Tags that don't already exist will be created. (default: [])
  --referrer-url: string # The URL the subscriber was referred from (e.g. where they submitted the subscription form). (default: )
  --utm-campaign: string # The UTM campaign the subscriber was attributed to at signup. (default: )
  --utm-medium: string # The UTM medium the subscriber was attributed to at signup. (default: )
  --utm-source: string # The UTM source the subscriber was attributed to at signup. (default: )
  --referring-subscriber-id: any # The ID of the subscriber that referred this subscriber.
  --type: any # The subscriber's lifecycle state — e.g. `regular` (active), `premium` (paid), `unactivated` (pending confirmation), `unsubscribed`, `removed`. (e.g. regular)
  --ip-address: any # The IP address of the subscriber. If provided, we will use this IP address to determine the subscriber's location and validate their legitimacy. (e.g. 127.0.0.1)
]: any -> record<id: string, creation_date: string, avatar_url: any, bounce_date: any, bounce_reason: any, churn_date: any, commenting_disabled: bool, country: any, email_address: string, gift_subscription_end_date: any, gift_subscription_message: any, ip_address: any, last_click_date: any, last_open_date: any, delivered_count: any, open_count: any, clicked_count: any, open_rate: any, click_rate: any, metadata: record, notes: string, purchased_by: any, purchased_message: any, referral_code: string, referrer_url: string, risk_score: any, secondary_id: int, source: string, stripe_coupon: any, stripe_customer_id: any, subscriber_import_id: any, tags: list<string>, transitions: table<date: string, type: string>, email_transitions: table<date: string, old_email_address: any, new_email_address: string>, form_id: any, firewall_reasons: table<code: string, reason: string>, type: string, undeliverability_date: any, undeliverability_reason: any, unsubscription_date: any, unsubscription_reason: any, upgrade_date: any, utm_campaign: string, utm_medium: string, utm_source: string, stripe_customer: any, stripe_subscription: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscribers")
  let body = {email_address: $email_address, notes: $notes, metadata: $metadata, tags: $tags, referrer_url: $referrer_url, utm_campaign: $utm_campaign, utm_medium: $utm_medium, utm_source: $utm_source, referring_subscriber_id: $referring_subscriber_id, type: $type, ip_address: $ip_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Buttondown-Collision-Behavior": $X_Buttondown_Collision_Behavior, "X-Buttondown-Bypass-Firewall": $X_Buttondown_Bypass_Firewall} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Subscribers
#
# GET /subscribers
# operationId: list_subscribers
export def "subscribers subscribers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bounce-date-end: string # If provided, only return subscribers who last bounced on or before the given date.
  --bounce-date-start: string # If provided, only return subscribers who last bounced on or after the given date.
  --bounce-reason: list # If provided, only return subscribers with the given bounce reason(s).
  --churn-date-end: string # If provided, only return subscribers who churned on or before the given date.
  --churn-date-start: string # If provided, only return subscribers who churned on or after the given date.
  --coupon: list # If provided, only return subscribers with the given coupon ID(s).
  --current-price: list # If provided, only return subscribers who are currently subscribed to the given price ID(s).
  --date-end: string # If provided, only return subscribers created before the given date.
  --date-start: string # If provided, only return subscribers created on or after the given date.
  --domain: list # If provided, only return subscribers whose email domain matches the given domain(s). (e.g. [gmail.com])
  --email-address: string # If provided, only return subscribers whose email address contains the given string.
  --expand: list # If provided, expand the given field. (Supported: 'stripe_customer', 'stripe_subscription'.)
  --form: list # If provided, only return subscribers that came through the given [form(s)](https://docs.buttondown.com/registration-forms). (e.g. [form_abc123])
  --ids: list # If provided, only return subscribers with the given IDs.
  --ip-address: list # If provided, only return subscribers with the given IP address(es).
  --last-click-date-end: string # If provided, only return subscribers whose last click was on or before the given date.
  --last-click-date-start: string # If provided, only return subscribers whose last click was on or after the given date.
  --last-open-date-end: string # If provided, only return subscribers whose last open was on or before the given date.
  --last-open-date-start: string # If provided, only return subscribers whose last open was on or after the given date.
  --domain: list # If provided, only return subscribers whose email domain does not match the given domain(s). (e.g. [gmail.com])
  --tag: string # If provided, only return subscribers without the given [tag](https://docs.buttondown.com/api-tags-introduction). (e.g. vip)
  --type: list # If provided, only return subscribers without the given type.
  --ordering: string # The ordering to apply to the results. (default: -creation_date, e.g. -creation_date)
  --price: list # If provided, only return subscribers who have at one point subscribed to the given price ID(s).
  --referral-code: list # If provided, only return subscribers with the given referral code(s).
  --referrer-url: list # If provided, only return subscribers whose referrer URL(s) contain the given string.
  --open-rate-end: float # If provided, only return subscribers with an open rate less than or equal to the given value.
  --open-rate-start: float # If provided, only return subscribers with an open rate greater than or equal to the given value.
  --click-rate-end: float # If provided, only return subscribers with a click rate less than or equal to the given value.
  --click-rate-start: float # If provided, only return subscribers with a click rate greater than or equal to the given value.
  --risk-score-end: float # If provided, only return subscribers with a [risk score](https://docs.buttondown.com/firewall) less than or equal to the given value.
  --risk-score-start: float # If provided, only return subscribers with a [risk score](https://docs.buttondown.com/firewall) greater than or equal to the given value.
  --qp-source: list # If provided, only return subscribers with the given source(s). (e.g. [api])
  --subscriber-import: list # If provided, only return subscribers that were imported by the given subscriber import. (e.g. [import_abc123])
  --tag: list # If provided, only return subscribers with the given [tag(s)](https://docs.buttondown.com/api-tags-introduction).
  --type: list # If provided, only return subscribers with the given type. (e.g. [regular])
  --undeliverability-date-end: string # If provided, only return subscribers who became undeliverable on or before the given date.
  --undeliverability-date-start: string # If provided, only return subscribers who became undeliverable on or after the given date.
  --undeliverability-reason: list # If provided, only return subscribers with the given undeliverability reason(s).
  --unsubscription-date-end: string # If provided, only return subscribers who unsubscribed on or before the given date.
  --unsubscription-date-start: string # If provided, only return subscribers who unsubscribed on or after the given date.
  --unsubscription-reason: list # If provided, only return subscribers with the given unsubscription reason(s). (e.g. [no longer interested])
  --upgrade-date-end: string # If provided, only return subscribers who upgraded on or before the given date.
  --upgrade-date-start: string # If provided, only return subscribers who upgraded on or after the given date.
  --utm-campaign: list # If provided, only return subscribers with the given UTM campaign(s). (e.g. [paid_campaign_2024])
  --utm-medium: list # If provided, only return subscribers with the given UTM medium(s). (e.g. [paid_campaign_2024])
  --utm-source: list # If provided, only return subscribers with the given UTM source(s). (e.g. [paid_campaign_2024])
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, avatar_url: any, bounce_date: any, bounce_reason: any, churn_date: any, commenting_disabled: bool, country: any, email_address: string, gift_subscription_end_date: any, gift_subscription_message: any, ip_address: any, last_click_date: any, last_open_date: any, delivered_count: any, open_count: any, clicked_count: any, open_rate: any, click_rate: any, metadata: record, notes: string, purchased_by: any, purchased_message: any, referral_code: string, referrer_url: string, risk_score: any, secondary_id: int, source: string, stripe_coupon: any, stripe_customer_id: any, subscriber_import_id: any, tags: list, transitions: list, email_transitions: list, form_id: any, firewall_reasons: list, type: string, undeliverability_date: any, undeliverability_reason: any, unsubscription_date: any, unsubscription_reason: any, upgrade_date: any, utm_campaign: string, utm_medium: string, utm_source: string, stripe_customer: any, stripe_subscription: any>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bounce_date__end" $bounce_date_end "scalar") (serialize-qp "bounce_date__start" $bounce_date_start "scalar") (serialize-qp "bounce_reason" $bounce_reason "multi") (serialize-qp "churn_date__end" $churn_date_end "scalar") (serialize-qp "churn_date__start" $churn_date_start "scalar") (serialize-qp "coupon" $coupon "multi") (serialize-qp "current_price" $current_price "multi") (serialize-qp "date__end" $date_end "scalar") (serialize-qp "date__start" $date_start "scalar") (serialize-qp "domain" $domain "multi") (serialize-qp "email_address" $email_address "scalar") (serialize-qp "expand" $expand "multi") (serialize-qp "form" $form "multi") (serialize-qp "ids" $ids "multi") (serialize-qp "ip_address" $ip_address "multi") (serialize-qp "last_click_date__end" $last_click_date_end "scalar") (serialize-qp "last_click_date__start" $last_click_date_start "scalar") (serialize-qp "last_open_date__end" $last_open_date_end "scalar") (serialize-qp "last_open_date__start" $last_open_date_start "scalar") (serialize-qp "-domain" $domain "multi") (serialize-qp "-tag" $tag "scalar") (serialize-qp "-type" $type "multi") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "price" $price "multi") (serialize-qp "referral_code" $referral_code "multi") (serialize-qp "referrer_url" $referrer_url "multi") (serialize-qp "open_rate__end" $open_rate_end "scalar") (serialize-qp "open_rate__start" $open_rate_start "scalar") (serialize-qp "click_rate__end" $click_rate_end "scalar") (serialize-qp "click_rate__start" $click_rate_start "scalar") (serialize-qp "risk_score__end" $risk_score_end "scalar") (serialize-qp "risk_score__start" $risk_score_start "scalar") (serialize-qp "source" $qp_source "multi") (serialize-qp "subscriber_import" $subscriber_import "multi") (serialize-qp "tag" $tag "multi") (serialize-qp "type" $type "multi") (serialize-qp "undeliverability_date__end" $undeliverability_date_end "scalar") (serialize-qp "undeliverability_date__start" $undeliverability_date_start "scalar") (serialize-qp "undeliverability_reason" $undeliverability_reason "multi") (serialize-qp "unsubscription_date__end" $unsubscription_date_end "scalar") (serialize-qp "unsubscription_date__start" $unsubscription_date_start "scalar") (serialize-qp "unsubscription_reason" $unsubscription_reason "multi") (serialize-qp "upgrade_date__end" $upgrade_date_end "scalar") (serialize-qp "upgrade_date__start" $upgrade_date_start "scalar") (serialize-qp "utm_campaign" $utm_campaign "multi") (serialize-qp "utm_medium" $utm_medium "multi") (serialize-qp "utm_source" $utm_source "multi") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscribers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Subscriber
#
# GET /subscribers/{id_or_email}
# operationId: retrieve_subscriber
export def "subscribers subscriber-by-id_or_email" [
  id_or_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # If provided, expand the given field. (default: [])
]: nothing -> record<id: string, creation_date: string, avatar_url: any, bounce_date: any, bounce_reason: any, churn_date: any, commenting_disabled: bool, country: any, email_address: string, gift_subscription_end_date: any, gift_subscription_message: any, ip_address: any, last_click_date: any, last_open_date: any, delivered_count: any, open_count: any, clicked_count: any, open_rate: any, click_rate: any, metadata: record, notes: string, purchased_by: any, purchased_message: any, referral_code: string, referrer_url: string, risk_score: any, secondary_id: int, source: string, stripe_coupon: any, stripe_customer_id: any, subscriber_import_id: any, tags: list<string>, transitions: table<date: string, type: string>, email_transitions: table<date: string, old_email_address: any, new_email_address: string>, form_id: any, firewall_reasons: table<code: string, reason: string>, type: string, undeliverability_date: any, undeliverability_reason: any, unsubscription_date: any, unsubscription_reason: any, upgrade_date: any, utm_campaign: string, utm_medium: string, utm_source: string, stripe_customer: any, stripe_subscription: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscribers/($id_or_email)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Subscriber
#
# DELETE /subscribers/{id_or_email}
# operationId: delete_subscriber
export def "subscribers subscriber-by-id_or_email-1" [
  id_or_email: string
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
  let full_url = (build-url $base $"/subscribers/($id_or_email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Subscriber
#
# PATCH /subscribers/{id_or_email}
# operationId: update_subscriber
export def "subscribers subscriber-by-id_or_email-2" [
  id_or_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --commenting-disabled: any # Whether this subscriber is prevented from commenting.
  --email-address: any # The email address of the subscriber. (e.g. telemachus@buttondown.email)
  --notes: any # Any notes you want to attach to the subscriber. These are not publicly visible. (e.g. One of our first subscribers!)
  --metadata: any # A structured key-value blob that you can use to store arbitrary data on the object. Metadata can be nested — you can store objects and arrays within your metadata. (You can [read more about metadata.](https://docs.buttondown.com/metadata)) (default: {})
  --tags: any # A list of [tag](https://docs.buttondown.com/api-tags-introduction) names applied to the subscriber. Tags that don't already exist will be created.
  --referrer-url: any # The URL the subscriber was referred from (e.g. where they submitted the subscription form). (default: )
  --type: any # The subscriber's lifecycle state — e.g. `regular` (active), `premium` (paid), `unactivated` (pending confirmation), `unsubscribed`, `removed`.
  --unsubscription-reason: any # Free-text reason the subscriber unsubscribed, if provided.
  --email-which-prompted-unsubscription-id: any # The ID of the email that prompted the subscriber to unsubscribe, if any.
]: any -> record<id: string, creation_date: string, avatar_url: any, bounce_date: any, bounce_reason: any, churn_date: any, commenting_disabled: bool, country: any, email_address: string, gift_subscription_end_date: any, gift_subscription_message: any, ip_address: any, last_click_date: any, last_open_date: any, delivered_count: any, open_count: any, clicked_count: any, open_rate: any, click_rate: any, metadata: record, notes: string, purchased_by: any, purchased_message: any, referral_code: string, referrer_url: string, risk_score: any, secondary_id: int, source: string, stripe_coupon: any, stripe_customer_id: any, subscriber_import_id: any, tags: list<string>, transitions: table<date: string, type: string>, email_transitions: table<date: string, old_email_address: any, new_email_address: string>, form_id: any, firewall_reasons: table<code: string, reason: string>, type: string, undeliverability_date: any, undeliverability_reason: any, unsubscription_date: any, unsubscription_reason: any, upgrade_date: any, utm_campaign: string, utm_medium: string, utm_source: string, stripe_customer: any, stripe_subscription: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscribers/($id_or_email)")
  let body = {commenting_disabled: $commenting_disabled, email_address: $email_address, notes: $notes, metadata: $metadata, tags: $tags, referrer_url: $referrer_url, type: $type, unsubscription_reason: $unsubscription_reason, email_which_prompted_unsubscription_id: $email_which_prompted_unsubscription_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send Reminder
#
# POST /subscribers/{id_or_email}/send-reminder
# operationId: send_reminder
export def "subscribers-send-reminder reminder" [
  id_or_email: string
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
  let full_url = (build-url $base $"/subscribers/($id_or_email)/send-reminder")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send Magic Link To Subscriber
#
# POST /subscribers/{id_or_email}/send-magic-link
# operationId: send_magic_link_to_subscriber
export def "subscribers-send-magic-link subscriber" [
  id_or_email: string
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
  let full_url = (build-url $base $"/subscribers/($id_or_email)/send-magic-link")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send Email To
#
# POST /subscribers/{id_or_email}/emails/{email_id}
# operationId: send_email_to
export def "subscribers-emails to" [
  id_or_email: string
  email_id: string
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
  let full_url = (build-url $base $"/subscribers/($id_or_email)/emails/($email_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Referrals
#
# GET /subscribers/{id_or_email}/referrals
# operationId: get_referrals
export def "subscribers-referrals referrals" [
  id_or_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, avatar_url: any, bounce_date: any, bounce_reason: any, churn_date: any, commenting_disabled: bool, country: any, email_address: string, gift_subscription_end_date: any, gift_subscription_message: any, ip_address: any, last_click_date: any, last_open_date: any, delivered_count: any, open_count: any, clicked_count: any, open_rate: any, click_rate: any, metadata: record, notes: string, purchased_by: any, purchased_message: any, referral_code: string, referrer_url: string, risk_score: any, secondary_id: int, source: string, stripe_coupon: any, stripe_customer_id: any, subscriber_import_id: any, tags: list, transitions: list, email_transitions: list, form_id: any, firewall_reasons: list, type: string, undeliverability_date: any, undeliverability_reason: any, unsubscription_date: any, unsubscription_reason: any, upgrade_date: any, utm_campaign: string, utm_medium: string, utm_source: string, stripe_customer: any, stripe_subscription: any>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscribers/($id_or_email)/referrals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Automations
#
# GET /subscribers/{id_or_email}/automations
# operationId: get_automations
export def "subscribers-automations automations" [
  id_or_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, name: string, status: string, automation_id: string, execution_date: string, actions: list>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscribers/($id_or_email)/automations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Automation Attempt
#
# PATCH /subscribers/{id_or_email}/automations/{automation_attempt_id}
# operationId: update_automation_attempt
export def "subscribers-automations attempt" [
  id_or_email: string
  automation_attempt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string # The status to set for the automation attempt. Only 'skipped' is allowed.
]: any -> record<id: string, name: string, status: string, automation_id: string, execution_date: string, actions: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscribers/($id_or_email)/automations/($automation_attempt_id)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Stripe Subscriptions
#
# GET /subscribers/{id_or_email}/stripe-subscriptions
# operationId: get_stripe_subscriptions
export def "subscribers-stripe-subscriptions subscriptions" [
  id_or_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<subscription_id: string, url: string, creation_date: string, ending_date: any, amount: any, currency: string, cadence: string, status: string, application_fee_percent: any, source: any, product: any>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscribers/($id_or_email)/stripe-subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Survey Responses
#
# GET /survey_responses
# operationId: retrieve_survey_responses
export def "survey-responses responses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email-id: list # If provided, only return responses submitted from the given email ID(s). (e.g. [em_01jv2m9q8r7s6t5w4x3y2z1abc])
  --automation-id: list # If provided, only return responses submitted from the given automation ID(s). (e.g. [aut_01jv2m9q8r7s6t5w4x3y2z1abc])
  --subscriber-id: list # If provided, only return responses made by the given [subscriber(s)](https://docs.buttondown.com/api-subscribers-introduction). (e.g. [sub_01jv2m9q8r7s6t5w4x3y2z1abc])
  --qp-source: list # If provided, only return responses submitted from the given arbitrary source string(s). (e.g. [landing-page])
  --survey-id: list # If provided, only return responses made to the given [survey(s)](https://docs.buttondown.com/api-surveys-introduction). (e.g. [srv_01jv2m9q8r7s6t5w4x3y2z1abc])
  --creation-date-start: string # If provided, only return responses made after the given date. (format: date)
  --creation-date-end: string # If provided, only return responses made before the given date. (format: date)
  --expand: list # If provided, expand the given field.
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, answer: string, text: string, survey_id: string, subscriber_id: string, email_id: any, automation_id: any, source: any, subscriber: any, survey: any, email: any, automation: any>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email_id" $email_id "multi") (serialize-qp "automation_id" $automation_id "multi") (serialize-qp "subscriber_id" $subscriber_id "multi") (serialize-qp "source" $qp_source "multi") (serialize-qp "survey_id" $survey_id "multi") (serialize-qp "creation_date__start" $creation_date_start "scalar") (serialize-qp "creation_date__end" $creation_date_end "scalar") (serialize-qp "expand" $expand "multi") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/survey_responses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Survey Response
#
# POST /survey_responses
# operationId: create_survey_response
export def "survey-responses response" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  subscriber_id: string # The subscriber who submitted the response. (e.g. [sub_01jv2m9q8r7s6t5w4x3y2z1abc])
  survey_id: string # The survey being answered. (e.g. [srv_01jv2m9q8r7s6t5w4x3y2z1abc])
  email_id: string # The email ID, automation ID, or arbitrary source string where the survey was answered. (e.g. em_01jv2m9q8r7s6t5w4x3y2z1abc)
  answer: int # The 1-based index of the selected answer in the survey's `answers` list. (e.g. 1)
]: any -> record<id: string, creation_date: string, answer: string, text: string, survey_id: string, subscriber_id: string, email_id: any, automation_id: any, source: any, subscriber: any, survey: any, email: any, automation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/survey_responses")
  let body = {subscriber_id: $subscriber_id, survey_id: $survey_id, email_id: $email_id, answer: $answer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Survey Response
#
# PATCH /survey_responses/{id}
# operationId: update_survey_response
export def "survey-responses response-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: any # The text response to update. Only applicable if the survey has freeform responses enabled.
]: any -> record<id: string, creation_date: string, answer: string, text: string, survey_id: string, subscriber_id: string, email_id: any, automation_id: any, source: any, subscriber: any, survey: any, email: any, automation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/survey_responses/($id)")
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Survey
#
# POST /surveys
# operationId: create_survey
export def "surveys survey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  identifier: string # A newsletter-scoped slug used to reference this survey when embedding it in emails. (e.g. color)
  question: string # The survey question shown to subscribers. (e.g. What's your favorite color?)
  answers: list # The list of pre-defined answer choices. Order is preserved unless `randomize_answers` is true. (e.g. [Red, Green, Blue])
  --notes: string # Internal notes about the survey. Not shown to subscribers. (default: , e.g. )
  --response-cadence: any # How often a given subscriber can respond — e.g. `once` (single response per subscriber) or `unlimited`. (default: once, e.g. once)
  --is-freeform-response-enabled: oneof<nothing, bool> # If true, subscribers can provide a freeform text response in addition to (or instead of) picking from `answers`. (default: false, e.g. false)
  --input-type: any # The UI control used to collect responses (e.g. `radio`, `checkbox`). (default: radio, e.g. radio)
  --randomize-answers: oneof<nothing, bool> # If true, the order of `answers` is shuffled each time the survey is rendered. (default: false, e.g. false)
]: any -> record<id: string, creation_date: string, identifier: string, question: string, response_count: int, answers: list<string>, notes: string, randomize_answers: bool, response_cadence: string, status: string, is_freeform_response_enabled: bool, input_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/surveys")
  let body = {identifier: $identifier, question: $question, answers: $answers, notes: $notes, response_cadence: $response_cadence, is_freeform_response_enabled: $is_freeform_response_enabled, input_type: $input_type, randomize_answers: $randomize_answers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Surveys
#
# GET /surveys
# operationId: list_surveys
export def "surveys surveys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: list # If provided, only return surveys with the given status. (e.g. [active])
  --status: list # If provided, only return surveys without the given status. (e.g. [inactive])
  --ordering: string # The ordering to apply to the results. (default: -creation_date, e.g. -creation_date)
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, identifier: string, question: string, response_count: int, answers: list, notes: string, randomize_answers: bool, response_cadence: string, status: string, is_freeform_response_enabled: bool, input_type: string>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "multi") (serialize-qp "-status" $status "multi") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/surveys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Survey
#
# GET /surveys/{id}
# operationId: retrieve_survey
export def "surveys survey-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, creation_date: string, identifier: string, question: string, response_count: int, answers: list<string>, notes: string, randomize_answers: bool, response_cadence: string, status: string, is_freeform_response_enabled: bool, input_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/surveys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Survey
#
# PATCH /surveys/{id}
# operationId: update_survey
export def "surveys survey-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: any # Internal notes about the survey. Not shown to subscribers.
  --answers: any # The list of pre-defined answer choices. Order is preserved unless `randomize_answers` is true. (e.g. [Red, Green, Blue])
  --response-cadence: any # How often a given subscriber can respond — e.g. `once` (single response per subscriber) or `unlimited`. (e.g. once)
  --status: any # The lifecycle status of the survey (e.g. `active`, `archived`).
  --is-freeform-response-enabled: any # If true, subscribers can provide a freeform text response in addition to (or instead of) picking from `answers`. (default: false)
  --input-type: any # The UI control used to collect responses (e.g. `radio`, `checkbox`).
  --randomize-answers: any # If true, the order of `answers` is shuffled each time the survey is rendered.
]: any -> record<id: string, creation_date: string, identifier: string, question: string, response_count: int, answers: list<string>, notes: string, randomize_answers: bool, response_cadence: string, status: string, is_freeform_response_enabled: bool, input_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/surveys/($id)")
  let body = {notes: $notes, answers: $answers, response_cadence: $response_cadence, status: $status, is_freeform_response_enabled: $is_freeform_response_enabled, input_type: $input_type, randomize_answers: $randomize_answers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Survey
#
# DELETE /surveys/{id}
# operationId: delete_survey
export def "surveys survey-by-id-2" [
  id: string
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
  let full_url = (build-url $base $"/surveys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Tag
#
# POST /tags
# operationId: create_tag
export def "tags tag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the tag. (e.g. VIP)
  color: string # The hex color code associated with the tag. (e.g. #FFD700)
  --description: any # An internal description of the tag, only visible to the newsletter author.
  --public-description: any # A public-facing description of the tag, visible to subscribers in the subscriber portal.
  --subscriber-editable: oneof<nothing, bool> # If true, subscribers can add or remove this tag from their own profile via the subscriber portal. (default: false, e.g. false)
]: any -> record<id: string, creation_date: string, name: string, color: string, description: any, public_description: any, subscriber_editable: bool, secondary_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tags")
  let body = {name: $name, color: $color, description: $description, public_description: $public_description, subscriber_editable: $subscriber_editable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Tags
#
# GET /tags
# operationId: list_tags
export def "tags tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list # If provided, only return tags matching the given IDs. (e.g. [tag_abc123])
  --page-size: int # The number of results per page. (default: 100)
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, name: string, color: string, description: any, public_description: any, subscriber_editable: bool, secondary_id: int>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Tag
#
# GET /tags/{id}
# operationId: retrieve_tag
export def "tags tag-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, creation_date: string, name: string, color: string, description: any, public_description: any, subscriber_editable: bool, secondary_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Tag
#
# PATCH /tags/{id}
# operationId: update_tag
export def "tags tag-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: any # The name of the tag. (e.g. VIP)
  --color: any # The hex color code associated with the tag. (e.g. #FFD700)
  --description: any # An internal description of the tag, only visible to the newsletter author.
  --public-description: any # A public-facing description of the tag, visible to subscribers in the subscriber portal.
  --secondary-id: any # The secondary ID of the tag, used as a human-readable numeric identifier.
  --subscriber-editable: any # If true, subscribers can add or remove this tag from their own profile via the subscriber portal.
]: any -> record<id: string, creation_date: string, name: string, color: string, description: any, public_description: any, subscriber_editable: bool, secondary_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($id)")
  let body = {name: $name, color: $color, description: $description, public_description: $public_description, secondary_id: $secondary_id, subscriber_editable: $subscriber_editable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Tag
#
# DELETE /tags/{id}
# operationId: delete_tag
export def "tags tag-by-id-2" [
  id: string
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
  let full_url = (build-url $base $"/tags/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Tag Analytics
#
# GET /tags/{id}/analytics
# operationId: retrieve_tag_analytics
export def "tags-analytics analytics" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_subscribers: int, click_rate: float, open_rate: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($id)/analytics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create User
#
# POST /users
# operationId: create_user
# --permissions shape: {subscriber?: any, email?: any, sending?: any, styling?: any, administrivia?: any, automations?: any, surveys?: any, forms?: any}
export def "users user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  permissions: record # shape: {subscriber?: any, email?: any, sending?: any, styling?: any, administrivia?: any, automations?: any, surveys?: any, forms?: any}
  email_address: string # The email address of the user.
]: any -> record<permissions: record<subscriber: record, email: record, sending: record, styling: record, administrivia: record, automations: record, surveys: record, forms: record>, email_address: string, id: string, creation_date: string, status: string, last_logged_in: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = {permissions: $permissions, email_address: $email_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Users
#
# GET /users
# operationId: list_users
export def "users users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<permissions: record, email_address: string, id: string, creation_date: string, status: string, last_logged_in: any>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve User
#
# GET /users/{id}
# operationId: retrieve_user
export def "users user-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<permissions: record<subscriber: record, email: record, sending: record, styling: record, administrivia: record, automations: record, surveys: record, forms: record>, email_address: string, id: string, creation_date: string, status: string, last_logged_in: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete User
#
# DELETE /users/{id}
# operationId: delete_user
export def "users user-by-id-1" [
  id: string
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
  let full_url = (build-url $base $"/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update User
#
# PATCH /users/{id}
# operationId: update_user
# --permissions shape: {subscriber?: any, email?: any, sending?: any, styling?: any, administrivia?: any, automations?: any, surveys?: any, forms?: any}
export def "users user-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  permissions: record # shape: {subscriber?: any, email?: any, sending?: any, styling?: any, administrivia?: any, automations?: any, surveys?: any, forms?: any}
]: any -> record<permissions: record<subscriber: record, email: record, sending: record, styling: record, administrivia: record, automations: record, surveys: record, forms: record>, email_address: string, id: string, creation_date: string, status: string, last_logged_in: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Webhook
#
# POST /webhooks
# operationId: create_webhook
export def "webhooks webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: any # Whether the webhook is enabled or not. (default: enabled, e.g. [enabled])
  event_types: list # The types of event for which the webhook will be triggered. (e.g. [[email.created, email.sent]])
  --body-url: string # The URL to which the webhook will send POST requests. (format: uri, e.g. [https://my.api/webhook])
  --description: string # An optional description of the webhook, for reference. (default: , e.g. [Trigger when an email is created to notify in Slack.])
  --signing-key: string # Optional HMAC signing key for webhook verification. When set, webhook requests will include an X-Buttondown-Signature header with sha256=<signature>. (default: , e.g. [])
]: any -> record<id: string, creation_date: string, status: string, event_types: list<string>, url: string, description: string, signing_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let body = {status: $status, event_types: $event_types, url: $body_url, description: $description, signing_key: $signing_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Webhooks
#
# GET /webhooks
# operationId: list_webhooks
export def "webhooks webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-2 # If provided, only return webhooks with the given status.
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, status: string, event_types: list, url: string, description: string, signing_key: string>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Webhook
#
# GET /webhooks/{id}
# operationId: retrieve_webhook
export def "webhooks webhook-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, creation_date: string, status: string, event_types: list<string>, url: string, description: string, signing_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Webhook
#
# PATCH /webhooks/{id}
# operationId: update_webhook
export def "webhooks webhook-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: any # Whether the webhook is enabled or not. (default: enabled, e.g. [enabled])
  event_types: list # The types of event for which the webhook will be triggered. (e.g. [[email.created, email.sent]])
  --body-url: string # The URL to which the webhook will send POST requests. (format: uri, e.g. [https://my.api/webhook])
  --description: string # An optional description of the webhook, for reference. (default: , e.g. [Trigger when an email is created to notify in Slack.])
  --signing-key: string # Optional HMAC signing key for webhook verification. When set, webhook requests will include an X-Buttondown-Signature header with sha256=<signature>. (default: , e.g. [])
]: any -> record<id: string, creation_date: string, status: string, event_types: list<string>, url: string, description: string, signing_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($id)")
  let body = {status: $status, event_types: $event_types, url: $body_url, description: $description, signing_key: $signing_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Webhook
#
# DELETE /webhooks/{id}
# operationId: delete_webhook
export def "webhooks webhook-by-id-2" [
  id: string
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
  let full_url = (build-url $base $"/webhooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Webhook Attempts
#
# GET /webhooks/{id}/attempts
# operationId: retrieve_webhook_attempts
export def "webhooks-attempts attempts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-3 # If provided, only return webhook attempts with the given status.
  --page: int # The page number of the paginated response. (default: 1, e.g. 1)
]: nothing -> record<results: table<id: string, creation_date: string, status: string, event_type: any, error_message: any, attempt_count: int, completion_date: any, duration_ms: any>, next: any, previous: any, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($id)/attempts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test Webhook
#
# POST /webhooks/{id}/test
# operationId: test_webhook
export def "webhooks-test webhook" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-type: string@event-type-completer-1 # The event type to send. Defaults to the webhook's first configured event type.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event_type" $event_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($id)/test" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
