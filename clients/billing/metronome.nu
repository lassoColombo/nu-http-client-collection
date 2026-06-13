# Auto-generated client for Metronome v1.0.0
# Source: https://docs.metronome.com/openapi.json
# Auth: --token flag or $env.METRONOME_TOKEN

const BASE_URL = "https://api.metronome.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o METRONOME_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.metronome.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alert-type-completer [] { ["invoice_total_reached" "low_remaining_commit_balance_reached" "low_remaining_commit_percentage_reached" "low_remaining_contract_credit_and_commit_balance_reached" "low_remaining_contract_credit_balance_reached" "low_remaining_contract_credit_percentage_reached" "low_remaining_days_for_commit_segment_reached" "low_remaining_days_for_contract_credit_segment_reached" "low_remaining_seat_balance_reached" "monthly_invoice_total_spend_threshold_reached" "spend_threshold_reached" "usage_threshold_reached"] }
def aggregation-type-completer [] { ["COUNT" "Count" "LATEST" "Latest" "MAX" "Max" "SUM" "Sum" "UNIQUE" "Unique" "count" "latest" "max" "sum" "unique"] }
def plans-or-contracts-completer [] { ["CONTRACTS" "PLANS"] }
def usage-type-completer [] { ["LATEST" "Latest" "MAX" "Max" "latest" "max"] }
def window-size-completer [] { ["DAY" "Day" "HOUR" "Hour" "NONE" "None" "day" "hour" "none"] }
def aggregate-completer [] { ["COUNT" "Count" "LATEST" "Latest" "MAX" "Max" "SUM" "Sum" "UNIQUE" "Unique" "count" "latest" "max" "sum" "unique"] }
def billable-status-completer [] { ["billable" "unbillable"] }
def type-completer [] { ["SCHEDULED" "USAGE" "USAGE_CONSOLIDATED"] }
def sort-completer [] { ["date_asc" "date_desc"] }
def window-size-completer-1 [] { ["DAY" "Day" "HOUR" "Hour" "day" "hour"] }
def window-size-completer-2 [] { ["DAY" "Day" "NONE" "None" "day" "none"] }
def mode-completer [] { ["merge" "replace"] }
def billing-provider-completer [] { ["aws_marketplace" "azure_marketplace" "gcp_marketplace"] }
def delivery-method-completer [] { ["aws_sns" "aws_sqs" "direct_to_billing_provider"] }
def avalara-environment-completer [] { ["PRODUCTION" "SANDBOX"] }
def provider-completer [] { ["netsuite"] }
def dashboard-completer [] { ["commits_and_credits" "invoices" "usage"] }
def entity-completer [] { ["alert" "billable_metric" "charge" "commit" "contract" "contract_credit" "contract_product" "customer" "discount" "invoice" "package_commit" "package_credit" "package_scheduled_charge" "package_subscription" "product" "professional_service" "rate_card" "scheduled_charge" "subscription"] }
def archive-filter-completer [] { ["ALL" "ARCHIVED" "NOT_ARCHIVED"] }
def type-completer-1 [] { ["COMPOSITE" "FIXED" "PROFESSIONAL_SERVICE" "PRO_SERVICE" "SUBSCRIPTION" "USAGE" "composite" "fixed" "pro_service" "professional_service" "subscription" "usage"] }
def sql-breakdown-granularity-completer [] { ["HOUR" "SERVICE_PERIOD" "hour" "service_period"] }
def composite-scope-completer [] { ["CONTRACT" "CUSTOMER" "contract" "customer"] }
def billing-frequency-completer [] { ["ANNUAL" "MONTHLY" "QUARTERLY" "WEEKLY" "annual" "monthly" "quarterly" "weekly"] }
def rate-type-completer [] { ["CUSTOM" "FLAT" "PERCENTAGE" "SUBSCRIPTION" "TIERED" "TIERED_PERCENTAGE" "custom" "flat" "percentage" "subscription" "tiered" "tiered_percentage"] }
def multiplier-override-prioritization-completer [] { ["EXPLICIT" "LOWEST_MULTIPLIER" "explicit" "lowest_multiplier"] }
def scheduled-charges-on-usage-invoices-completer [] { ["ALL"] }
def type-completer-2 [] { ["POSTPAID" "PREPAID" "postpaid" "prepaid"] }
def rate-type-completer-1 [] { ["COMMIT_RATE" "LIST_RATE" "commit_rate" "list_rate"] }
def outcome-completer [] { ["FAILED" "PAID" "failed" "paid"] }
def invoice-inclusion-mode-completer [] { ["FINALIZED" "FINALIZED_AND_DRAFT"] }
def billing-provider-completer-1 [] { ["aws_marketplace" "azure_marketplace" "gcp_marketplace" "netsuite" "stripe"] }
def delivery-method-completer-1 [] { ["aws_sns" "aws_sqs" "direct_to_billing_provider" "tackle"] }
def archive-filter-completer-1 [] { ["ALL" "ARCHIVED" "NOT_ARCHIVED" "all" "archived" "not_archived"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "alerts-archive archiveAlert-v1" } } | get name | first)
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

# Archive a threshold notification
#
# POST /v1/alerts/archive
# operationId: archiveAlert-v1
export def "alerts-archive archiveAlert-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # The Metronome ID of the threshold notification (format: uuid)
  --release-uniqueness-key: oneof<nothing, bool> # If true, resets the uniqueness key on this threshold notification so it can be re-used
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/alerts/archive")
  let body = {id: $id, release_uniqueness_key: $release_uniqueness_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a threshold notification
#
# POST /v1/alerts/create
# operationId: createAlert-v1
# --custom_field_filters item shape: {entity: "Contract"|"Commit"|"ContractCredit"|"ContractCreditOrCommit", key: string, value: string}
# --group_values item shape: {key: string, value?: string}
# --seat_filter shape: {seat_group_key: string, seat_group_value?: string}
# --alert_specifiers item shape: {custom_field_filters?: list, exclude?: list}
export def "alerts-create createAlert-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  alert_type: string@alert-type-completer # Type of the threshold notification
  name: string # Name of the threshold notification
  --uniqueness-key: string # Prevents the creation of duplicates. If a request to create a record is made with a previously used uniqueness key, a new record will not be created and the request will fail with a 409 error.
  threshold: float # Threshold value of the notification policy.  Depending upon the notification type, this number may represent a financial amount, the days remaining, or a percentage reached.
  --credit-type-id: string # ID of the credit's currency, defaults to USD. If the specific notification type requires a pricing unit/currency, find the ID in the [Metronome app](https://app.metronome.com/offering/pricing-units). (format: uuid)
  --customer-id: string # If provided, will create this threshold notification for this specific customer. To create a notification for all customers, do not specify a `customer_id`. (format: uuid)
  --billable-metric-id: string # For threshold notifications of type `usage_threshold_reached`, specifies which billable metric to track the usage for. (format: uuid)
  --credit-grant-type-filters: list # An array of strings, representing a way to filter the credit grant this threshold notification applies to, by looking at the credit_grant_type field on the credit grant. This field is only defined for CreditPercentage and CreditBalance notifications
  --evaluate-on-create: oneof<nothing, bool> # If true, the threshold notification will evaluate immediately on customers that already meet the notification threshold. If false, it will only evaluate on future customers that trigger the threshold. Defaults to true.
  --custom-field-filters: list # A list of custom field filters for threshold notification types that support advanced filtering. Only present for contract invoices. — item shape: {entity: "Contract"|"Commit"|"ContractCredit"|"ContractCreditOrCommit", key: string, value: string}
  --invoice-types-filter: list # Only supported for invoice_total_reached threshold notifications. A list of invoice types to evaluate.
  --group-values: list # Only present for `spend_threshold_reached` notifications. Scope notification to a specific group key on individual line items. — item shape: {key: string, value?: string}
  --seat-filter: record # Required for `low_remaining_seat_balance_reached` notifications. The alert is scoped to this seat group key-value pair. — shape: {seat_group_key: string, seat_group_value?: string}
  --alert-specifiers: list # Can be used with only `low_remaining_contract_credit_and_commit_balance_reached` notifications. Defines the balances that are considered when evaluating the alert. — item shape: {custom_field_filters?: list, exclude?: list}
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/alerts/create")
  let body = {alert_type: $alert_type, name: $name, uniqueness_key: $uniqueness_key, threshold: $threshold, credit_type_id: $credit_type_id, customer_id: $customer_id, billable_metric_id: $billable_metric_id, credit_grant_type_filters: $credit_grant_type_filters, evaluate_on_create: $evaluate_on_create, custom_field_filters: $custom_field_filters, invoice_types_filter: $invoice_types_filter, group_values: $group_values, seat_filter: $seat_filter, alert_specifiers: $alert_specifiers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a billable metric
#
# POST /v1/billable-metrics/create
# operationId: createBillableMetricV1-v1
# --event_type_filter shape: {in_values?: list, not_in_values?: list}
# --property_filters item shape: {name: string, exists?: bool, in_values?: list, not_in_values?: list}
export def "billable-metrics-create createBillableMetricV1-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The display name of the billable metric.
  --sql: string # The SQL query associated with the billable metric. This field is mutually exclusive with aggregation_type, event_type_filter, property_filters, aggregation_key, and group_keys. If provided, these other fields must be omitted.
  --event-type-filter: record # An optional filtering rule to match the 'event_type' property of an event. — shape: {in_values?: list, not_in_values?: list}
  --property-filters: list # A list of filters to match events to this billable metric. Each filter defines a rule on an event property. All rules must pass for the event to match the billable metric. — item shape: {name: string, exists?: bool, in_values?: list, not_in_values?: list}
  --aggregation-type: string@aggregation-type-completer # Specifies the type of aggregation performed on matching events.
  --aggregation-key: string # A key that specifies which property of the event is used to aggregate data. This key must be one of the property filter names and is not applicable when the aggregation type is 'count'.
  --group-keys: list # Property names that are used to group usage costs on an invoice. Each entry represents a set of properties used to slice events into distinct buckets.
  --custom-fields: record # Custom fields to be added eg. { "key1": "value1", "key2": "value2" }
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/billable-metrics/create")
  let body = {name: $name, sql: $sql, event_type_filter: $event_type_filter, property_filters: $property_filters, aggregation_type: $aggregation_type, aggregation_key: $aggregation_key, group_keys: $group_keys, custom_fields: $custom_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archive a billable metric
#
# POST /v1/billable-metrics/archive
# operationId: archiveBillableMetric-v1
export def "billable-metrics-archive archiveBillableMetric-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: uuid
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/billable-metrics/archive")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a threshold notification
#
# POST /v1/customer-alerts/get
# operationId: getCustomerAlert-v1
# --group_values item shape: {key: string, value: string}
# --seat_filter shape: {seat_group_key: string, seat_group_value: string}
# --alert_specifiers item shape: {custom_field_filters: list, exclude?: list}
# --custom_field_filters item shape: {entity: "Contract"|"Commit"|"ContractCredit"|"ContractCreditOrCommit", key: string, value: string}
export def "customer-alerts-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # The Metronome ID of the customer (format: uuid)
  alert_id: string # The Metronome ID of the threshold notification (format: uuid)
  --plans-or-contracts: string@plans-or-contracts-completer # When parallel threshold notifications are enabled during migration, this flag denotes whether to fetch notifications for plans or contracts.
  --group-values: list # Only present for `spend_threshold_reached` notifications. Retrieve the notification for a specific group key-value pair. — item shape: {key: string, value: string}
  --seat-filter: record # Only allowed for `low_remaining_seat_balance_reached` notifications. This filters alerts by the seat group key-value pair. — shape: {seat_group_key: string, seat_group_value: string}
  --alert-specifiers: list # Can be used with only `low_remaining_contract_credit_and_commit_balance_reached` notifications. Used to filter the alert by the custom field key-value pair. — item shape: {custom_field_filters: list, exclude?: list}
  --custom-field-filters: list # Used to filter the alert by the custom field key-value pair. — item shape: {entity: "Contract"|"Commit"|"ContractCredit"|"ContractCreditOrCommit", key: string, value: string}
  --webhook-notification-id: string # Indicates that this API request was triggered by a webhook notification with the provided ID.
]: any -> record<data: record<customer_status: string, triggered_by: string, alert: record<id: string, name: string, uniqueness_key: string, type: string, status: string, credit_type: record, threshold: float, updated_at: string, credit_grant_type_filters: list, custom_field_filters: list, group_key_filter: record, invoice_types_filter: list, group_values: list, seat_filter: record, alert_specifiers: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customer-alerts/get")
  let body = {customer_id: $customer_id, alert_id: $alert_id, plans_or_contracts: $plans_or_contracts, group_values: $group_values, seat_filter: $seat_filter, alert_specifiers: $alert_specifiers, custom_field_filters: $custom_field_filters, webhook_notification_id: $webhook_notification_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all threshold notifications
#
# POST /v1/customer-alerts/list
# operationId: listCustomerAlerts-v1
export def "customer-alerts-list listCustomerAlerts-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-page: string # Cursor that indicates where the next page of results should start.
  customer_id: string # The Metronome ID of the customer (format: uuid)
  --alert-statuses: list # Optionally filter by threshold notification status. If absent, only enabled notifications will be returned.
]: any -> record<data: table<customer_status: string, triggered_by: string, alert: record>, next_page: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next_page" $next_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/customer-alerts/list" $qp)
  let body = {customer_id: $customer_id, alert_statuses: $alert_statuses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset a threshold notification
#
# POST /v1/customer-alerts/reset
# operationId: resetCustomerAlerts-v1
export def "customer-alerts-reset resetCustomerAlerts-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # The Metronome ID of the customer (format: uuid)
  alert_id: string # The Metronome ID of the threshold notification (format: uuid)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customer-alerts/reset")
  let body = {customer_id: $customer_id, alert_id: $alert_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set the billing provider API key
#
# POST /v1/client/billing-config/{billing_provider_type}/apiKey
# DEPRECATED
# operationId: setBillingProviderApiKey-v1
@deprecated
export def "client-billing-config-api-key setBillingProviderApiKey-v1" [
  billing_provider_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string # API key to set for the billing provider.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/billing-config/($billing_provider_type)/apiKey")
  let body = {api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set the client webhook secret
#
# POST /v1/client/config/webhook_secret
# operationId: setClientWebhookSecret-v1
export def "client-config-webhook-secret setClientWebhookSecret-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  webhook_secret: string # The client webhook secret used to verify webhook results
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/client/config/webhook_secret")
  let body = {webhook_secret: $webhook_secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Stripe billing settings
#
# POST /v1/client/billing-config/stripe
# operationId: createStripeBillingSettings-v1
export def "client-billing-config-stripe createStripeBillingSettings-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  stripe_api_key: string # API key used to call the Stripe APIs
  --anrok-api-key: string # API key used to call the Anrok APIs (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/client/billing-config/stripe")
  let body = {stripe_api_key: $stripe_api_key, anrok_api_key: $anrok_api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Stripe billing settings
#
# PATCH /v1/client/billing-config/stripe
# operationId: updateStripeBillingSettings-v1
export def "client-billing-config-stripe updateStripeBillingSettings-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stripe-api-key: string # API key used to call the Stripe APIs
  --anrok-api-key: string # API key used to call the Anrok APIs (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/client/billing-config/stripe")
  let body = {stripe_api_key: $stripe_api_key, anrok_api_key: $anrok_api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Stripe billing settings
#
# DELETE /v1/client/billing-config/stripe
# operationId: deleteStripeBillingSettings-v1
export def "client-billing-config-stripe delete" [
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
  let full_url = (build-url $base "/v1/client/billing-config/stripe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List pricing units
#
# GET /v1/credit-types/list
# operationId: listCreditTypes-v1
export def "credit-types-list listCreditTypes-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results that should be returned
  --next-page: string # Cursor that indicates where the next page of results should start.
]: nothing -> record<data: table<name: string, id: string, is_currency: bool>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "next_page" $next_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/credit-types/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ingest events
#
# POST /v1/ingest
# operationId: ingest-v1
export def "ingest ingest-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ingest")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get seats usage data
#
# POST /v1/usage/seats
# operationId: getSeatsUsage-v1
export def "usage-seats post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results that should be returned
  --next-page: string # Cursor that indicates where the next page of results should start.
  customer_id: string # format: uuid
  seat_metric_id: string # format: uuid
  usage_type: string@usage-type-completer # The type of usage to return, max or latest value.
  window_size: string@window-size-completer # A window_size of "day" or "hour" will return the usage for the specified period segmented into daily or hourly aggregates. A window_size of "none" will return a single usage aggregate for the entirety of the specified period.
  --starting-on: string # format: date-time
  --ending-before: string # format: date-time
  --current-period: oneof<nothing, bool> # If true, will return the usage for the current billing period. Will return an error if the customer is currently uncontracted or starting_on and ending_before are specified when this is true.
]: any -> record<data: table<starting_on: string, ending_before: string, value: float>, next_page: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "next_page" $next_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/usage/seats" $qp)
  let body = {customer_id: $customer_id, seat_metric_id: $seat_metric_id, usage_type: $usage_type, window_size: $window_size, starting_on: $starting_on, ending_before: $ending_before, current_period: $current_period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get usage data with paginated groupings
#
# POST /v1/usage/groups
# operationId: getPagedUsage-v1
# --group_by shape: {key: string, values?: list}
@deprecated --flag group-by
export def "usage-groups post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results that should be returned
  --next-page: string # Cursor that indicates where the next page of results should start.
  customer_id: string # format: uuid
  billable_metric_id: string # format: uuid
  window_size: string@window-size-completer # A window_size of "day" or "hour" will return the usage for the specified period segmented into daily or hourly aggregates. A window_size of "none" will return a single usage aggregate for the entirety of the specified period.
  --starting-on: string # format: date-time
  --ending-before: string # format: date-time
  --group-by: record # Use group_key and group_filters instead. Use a single group key to group by. Compound group keys are not supported. (DEPRECATED) — shape: {key: string, values?: list}
  --group-key: list # Group key to group usage by. Supports both simple (single key) and compound (multiple keys) group keys.  For simple group keys, provide a single key e.g. `["region"]`. For compound group keys, provide multiple keys e.g. `["region", "team"]`.  For streaming metrics, the keys must be defined as a simple or compound group key on the billable metric. For compound group keys, all keys must match an exact compound group key definition — partial matches are not allowed.  Cannot be used together with `group_by`.  (e.g. [region, team])
  --group-filters: record # Object mapping group keys to arrays of values to filter on. Only usage matching these filter values will be returned. Keys must be present in group_key. Omit a key or use an empty array to include all values for that dimension.  (e.g. {region: [us-east1, us-west1], team: [UI]})
  --current-period: oneof<nothing, bool> # If true, will return the usage for the current billing period. Will return an error if the customer is currently uncontracted or starting_on and ending_before are specified when this is true.
]: any -> record<data: table<starting_on: string, ending_before: string, group_key: string, group_value: string, group: record, value: float>, next_page: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "next_page" $next_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/usage/groups" $qp)
  let body = {customer_id: $customer_id, billable_metric_id: $billable_metric_id, window_size: $window_size, starting_on: $starting_on, ending_before: $ending_before, group_by: $group_by, group_key: $group_key, group_filters: $group_filters, current_period: $current_period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get batched usage data
#
# POST /v1/usage
# operationId: getUsageBatch-v1
# --billable_metrics item shape: {id: string, group_by?: record}
export def "usage post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-page: string # Cursor that indicates where the next page of results should start.
  --customer-ids: list # A list of Metronome customer IDs to fetch usage for. If absent, usage for all customers will be returned.
  --billable-metrics: list # A list of billable metrics to fetch usage for. If absent, all billable metrics will be returned. — item shape: {id: string, group_by?: record}
  window_size: string@window-size-completer # A window_size of "day" or "hour" will return the usage for the specified period segmented into daily or hourly aggregates. A window_size of "none" will return a single usage aggregate for the entirety of the specified period.
  starting_on: string # format: date-time
  ending_before: string # format: date-time
]: any -> record<data: table<customer_id: string, billable_metric_id: string, billable_metric_name: string, start_timestamp: string, end_timestamp: string, value: float, groups: record>, next_page: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next_page" $next_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/usage" $qp)
  let body = {customer_ids: $customer_ids, billable_metrics: $billable_metrics, window_size: $window_size, starting_on: $starting_on, ending_before: $ending_before} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search events
#
# POST /v1/events/search
# operationId: searchEvents-v1
export def "events-search searchEvents-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  transactionIds: list # The transaction IDs of the events to retrieve
]: any -> table<id: string, customer_id: string, event_type: string, properties: record, timestamp: string, transaction_id: string, is_duplicate: bool, processed_at: string, matched_customer: record<id: string, name: string>, matched_billable_metrics: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/events/search")
  let body = {transactionIds: $transactionIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a billable metric
#
# GET /v1/billable-metrics/{billable_metric_id}
# operationId: getBillableMetric-v1
export def "billable-metrics get" [
  billable_metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, name: string, event_type_filter: record<in_values: list, not_in_values: list>, property_filters: list<record>, aggregation_type: string, aggregation_key: string, group_keys: list<list>, custom_fields: record, sql: string, archived_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/billable-metrics/($billable_metric_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a billable metric
#
# PUT /v1/billable-metrics/{billable_metric_id}
# operationId: updateBillableMetric-v1
export def "billable-metrics updateBillableMetric-v1" [
  billable_metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The new name of the metric
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/billable-metrics/($billable_metric_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all billable metrics
#
# GET /v1/billable-metrics
# operationId: listAllBillableMetrics-v1
export def "billable-metrics listAllBillableMetrics-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results that should be returned
  --next-page: string # Cursor that indicates where the next page of results should start.
  --include-archived: oneof<nothing, bool> # If true, the list of returned metrics will include archived metrics
]: nothing -> record<data: table<id: string, name: string, event_type_filter: record, property_filters: list, aggregation_type: string, aggregation_key: string, group_keys: list, custom_fields: record, sql: string, archived_at: string>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "next_page" $next_page "scalar") (serialize-qp "include_archived" $include_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/billable-metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a billable metric
#
# POST /v1/billable-metrics
# operationId: createBillableMetric-v1
export def "billable-metrics createBillableMetric-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  aggregate: string@aggregate-completer
  --aggregate-key: string
  filter: record # JSON Schema filter to apply to the metric
  --group-keys: list
  --group-values: list
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/billable-metrics")
  let body = {name: $name, aggregate: $aggregate, aggregate_key: $aggregate_key, filter: $filter, group_keys: $group_keys, group_values: $group_values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set customer billable status
#
# POST /v1/customers/setBillableStatus
# operationId: setCustomerBillableStatus-v1
export def "customers-set-billable-status setCustomerBillableStatus-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  billable_status: string@billable-status-completer
  effective_at: string # For usage invoices, any invoices where the service periods starts on or after this date will be included. For all other invoice types, only invoices where the issue_date falls on or after this date will be included. (format: date-time)
]: any -> record<data: record<id: string, current_billable_status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customers/setBillableStatus")
  let body = {customer_id: $customer_id, billable_status: $billable_status, effective_at: $effective_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archive a customer
#
# POST /v1/customers/archive
# operationId: archiveCustomer-v1
export def "customers-archive archiveCustomer-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: uuid
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customers/archive")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a customer
#
# GET /v1/customers/{customer_id}
# operationId: getCustomer-v1
export def "customers get" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, external_id: string, ingest_aliases: list<string>, name: string, customer_config: record<salesforce_account_id: string>, custom_fields: record, created_at: string, archived_at: string, updated_at: string, current_billable_status: record<value: string, effective_at: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/customers/($customer_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get billable metrics for a customer
#
# GET /v1/customers/{customer_id}/billable-metrics
# operationId: listBillableMetrics-v1
export def "customers-billable-metrics listBillableMetrics-v1" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results that should be returned
  --next-page: string # Cursor that indicates where the next page of results should start.
  --on-current-plan: oneof<nothing, bool> # If true, the list of metrics will be filtered to just ones that are on the customer's current plan
  --include-archived: oneof<nothing, bool> # If true, the list of returned metrics will include archived metrics
]: nothing -> record<data: table<group_by: list, group_keys: list, name: string, id: string, aggregate: string, aggregate_keys: list, filter: record, aggregation_key: string, event_type_filter: record, property_filters: list, custom_fields: record, sql: string, archived_at: string, aggregation_type: string>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "next_page" $next_page "scalar") (serialize-qp "on_current_plan" $on_current_plan "scalar") (serialize-qp "include_archived" $include_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/customers/($customer_id)/billable-metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List customers
#
# GET /v1/customers
# operationId: listCustomers-v1
export def "customers listCustomers-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results that should be returned
  --next-page: string # Cursor that indicates where the next page of results should start.
  --ingest-alias: string # Filter the customer list by ingest_alias
  --customer-ids: list # Filter the customer list by customer_id.  Up to 100 ids can be provided.
  --only-archived: oneof<nothing, bool> # Filter the customer list to only return archived customers. By default, only active customers are returned.
  --salesforce-account-ids: list # Filter the customer list by salesforce_account_id.  Up to 100 ids can be provided.
]: nothing -> record<data: table<id: string, external_id: string, ingest_aliases: list, name: string, customer_config: record, custom_fields: record, created_at: string, archived_at: string, updated_at: string, current_billable_status: record>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "next_page" $next_page "scalar") (serialize-qp "ingest_alias" $ingest_alias "scalar") (serialize-qp "customer_ids" $customer_ids "multi") (serialize-qp "only_archived" $only_archived "scalar") (serialize-qp "salesforce_account_ids" $salesforce_account_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/customers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a customer
#
# POST /v1/customers
# operationId: createCustomer-v1
# --customer_billing_provider_configurations item shape: {billing_provider: "aws_marketplace"|"azure_marketplace"|"gcp_marketplace"|"stripe"|"netsuite", tax_provider?: "anrok"|"avalara"|"stripe", configuration?: record, delivery_method_id?: string, delivery_method?: "direct_to_billing_provider"|"aws_sqs"|"tackle"|"aws_sns"}
# --customer_revenue_system_configurations item shape: {provider: "netsuite", configuration?: record, delivery_method_id?: string, delivery_method?: "direct_to_billing_provider"}
export def "customers createCustomer-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ingest-aliases: list # Aliases that can be used to refer to this customer in usage events
  --external-id: string # (deprecated, use ingest_aliases instead) an alias that can be used to refer to this customer in usage events
  name: string # This will be truncated to 160 characters if the provided name is longer.
  --customer-billing-provider-configurations: list # item shape: {billing_provider: "aws_marketplace"|"azure_marketplace"|"gcp_marketplace"|"stripe"|"netsuite", tax_provider?: "anrok"|"avalara"|"stripe", configuration?: record, delivery_method_id?: string, delivery_method?: "direct_to_billing_provider"|"aws_sqs"|"tackle"|"aws_sns"}
  --customer-revenue-system-configurations: list # item shape: {provider: "netsuite", configuration?: record, delivery_method_id?: string, delivery_method?: "direct_to_billing_provider"}
  --custom-fields: record # Custom fields to be added eg. { "key1": "value1", "key2": "value2" }
]: any -> record<data: record<id: string, external_id: string, ingest_aliases: list<string>, name: string, custom_fields: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customers")
  let body = {ingest_aliases: $ingest_aliases, external_id: $external_id, name: $name, customer_billing_provider_configurations: $customer_billing_provider_configurations, customer_revenue_system_configurations: $customer_revenue_system_configurations, custom_fields: $custom_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or update customer ingest aliases
#
# POST /v1/customers/{customer_id}/setIngestAliases
# operationId: setIngestAliases-v1
export def "customers-set-ingest-aliases setIngestAliases-v1" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ingest_aliases: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/customers/($customer_id)/setIngestAliases")
  let body = {ingest_aliases: $ingest_aliases} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a customer name
#
# POST /v1/customers/{customer_id}/setName
# operationId: setCustomerName-v1
export def "customers-set-name setCustomerName-v1" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The new name for the customer. This will be truncated to 160 characters if the provided name is longer.
]: any -> record<data: record<id: string, external_id: string, ingest_aliases: list<string>, name: string, custom_fields: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/customers/($customer_id)/setName")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a customer configuration
#
# POST /v1/customers/{customer_id}/updateConfig
# operationId: updateCustomerConfig-v1
export def "customers-update-config updateCustomerConfig-v1" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --salesforce-account-id: string # The Salesforce account ID for the customer (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/customers/($customer_id)/updateConfig")
  let body = {salesforce_account_id: $salesforce_account_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get purchased seats
#
# GET /v1/customers/{customer_id}/purchasedSeats
# operationId: getPurchasedSeats-v1
export def "customers-purchased-seats get" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<charge_id: string, seat_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/customers/($customer_id)/purchasedSeats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoice seats
#
# POST /v1/customers/{customer_id}/invoices/invoice_seats
# operationId: chargeSeats-v1
# --seat_charges item shape: {charge_id: string, seat_count: int, current_seat_count?: int}
export def "customers-invoices-invoice-seats chargeSeats-v1" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  seat_charges: list # item shape: {charge_id: string, seat_count: int, current_seat_count?: int}
]: any -> record<id: string, customer_id: string, customer_custom_fields: record, netsuite_sales_order_id: string, salesforce_opportunity_id: string, net_payment_terms_days: float, credit_type: record<name: string, id: string>, line_items: table<name: string, quantity: float, total: float, unit_price: float, list_price: record, product_id: string, product_custom_fields: record, product_tags: list, product_type: string, type: string, netsuite_item_id: string, is_prorated: bool, credit_type: record, starting_at: string, ending_before: string, commit_id: string, applied_commit_or_credit: record, commit_custom_fields: record, commit_segment_id: string, commit_type: string, commit_netsuite_sales_order_id: string, commit_netsuite_item_id: string, postpaid_commit: record, reseller_type: string, custom_fields: record, pricing_group_values: record, presentation_group_values: record, metadata: string, netsuite_invoice_billing_start: string, netsuite_invoice_billing_end: string, professional_service_id: string, professional_service_custom_fields: record, scheduled_charge_id: string, scheduled_charge_custom_fields: record, subscription_custom_fields: record, subscription_id: string, tier: record, discount_id: string, discount_custom_fields: record, origin: record>, start_timestamp: string, end_timestamp: string, issued_at: string, created_at: string, status: string, total: float, type: string, external_invoice: record<billing_provider_type: string, invoice_id: string, issued_at_timestamp: string, external_status: string, pdf_url: string, tax: record<total_tax_amount: float, total_taxable_amount: float, transaction_id: string>, invoiced_total: float, invoiced_sub_total: float, billing_provider_error: string, external_payment_id: string>, revenue_system_invoices: table<revenue_system_provider: string, revenue_system_external_entity_id: string, sync_status: string, revenue_system_external_entity_type: string, error_message: string>, contract_id: string, contract_custom_fields: record, amendment_id: string, correction_record: record<reason: string, memo: string, corrected_invoice_id: string, corrected_external_invoice: record<billing_provider_type: string, invoice_id: string, issued_at_timestamp: string, external_status: string, pdf_url: string, tax: record, invoiced_total: float, invoiced_sub_total: float, billing_provider_error: string, external_payment_id: string>>, reseller_royalty: record<reseller_type: string, netsuite_reseller_id: string, fraction: string, aws_options: record<aws_account_number: string, aws_payer_reference_id: string, aws_offer_id: string>, gcp_options: record<gcp_account_id: string, gcp_offer_id: string>>, custom_fields: record, billable_status: string, constituent_invoices: table<contract_id: string, invoice_id: string, customer_id: string>, payer: record<contract_id: string, customer_id: string>, regenerated_from_invoice_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/customers/($customer_id)/invoices/invoice_seats")
  let body = {seat_charges: $seat_charges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List invoices
#
# GET /v1/customers/{customer_id}/invoices
# operationId: listInvoices-v1
export def "customers-invoices listInvoices-v1" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results that should be returned
  --next-page: string # Cursor that indicates where the next page of results should start.
  --status: string # Invoice status, e.g. DRAFT, FINALIZED, or VOID
  --type: string@type-completer # Filter invoices by type. Defaults to returning all invoice types.
  --skip-zero-qty-line-items: oneof<nothing, bool> # If set, all zero quantity line items will be filtered out of the response
  --qp-sort: string@sort-completer # Invoice sort order by issued_at, e.g. date_asc or date_desc.  Defaults to date_asc.
  --credit-type-id: string # Only return invoices for the specified credit type
  --contract-id: string # Only return invoices for the specified contract (format: uuid)
  --starting-on: string # RFC 3339 timestamp (inclusive). Invoices will only be returned for billing periods that start at or after this time. (format: date-time)
  --ending-before: string # RFC 3339 timestamp (exclusive). Invoices will only be returned for billing periods that end before this time. (format: date-time)
  --webhook-notification-id: string # Indicates that this API request was triggered by a webhook notification with the provided ID.
]: nothing -> record<data: table<id: string, customer_id: string, customer_custom_fields: record, netsuite_sales_order_id: string, salesforce_opportunity_id: string, net_payment_terms_days: float, credit_type: record, line_items: list, start_timestamp: string, end_timestamp: string, issued_at: string, created_at: string, status: string, total: float, type: string, external_invoice: record, revenue_system_invoices: list, contract_id: string, contract_custom_fields: record, amendment_id: string, correction_record: record, reseller_royalty: record, custom_fields: record, billable_status: string, constituent_invoices: list, payer: record, regenerated_from_invoice_id: string>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "next_page" $next_page "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "skip_zero_qty_line_items" $skip_zero_qty_line_items "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "credit_type_id" $credit_type_id "scalar") (serialize-qp "contract_id" $contract_id "scalar") (serialize-qp "starting_on" $starting_on "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "webhook_notification_id" $webhook_notification_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/customers/($customer_id)/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List invoice breakdowns
#
# GET /v1/customers/{customer_id}/invoices/breakdowns
# operationId: listBreakdownInvoices-v1
export def "customers-invoices-breakdowns listBreakdownInvoices-v1" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-page: string # Cursor that indicates where the next page of results should start.
  --status: string # Invoice status, e.g. DRAFT or FINALIZED
  --skip-zero-qty-line-items: oneof<nothing, bool> # If set, all zero quantity line items will be filtered out of the response
  --limit: int # Max number of results that should be returned. For daily breakdowns, the response can return up to 35 days worth of breakdowns. For hourly breakdowns, the response can return up to 24 hours. If there are more results, a cursor to the next page is returned.
  --window-size: string@window-size-completer-1 # The granularity of the breakdowns to return. Defaults to day.
  --qp-sort: string@sort-completer # Invoice sort order by issued_at, e.g. date_asc or date_desc.  Defaults to date_asc.
  --credit-type-id: string # Only return invoices for the specified credit type
  --starting-on: string # RFC 3339 timestamp. Breakdowns will only be returned for time windows that start on or after this time. (format: date-time, e.g. 2024-01-01T00:00:00Z)
  --ending-before: string # RFC 3339 timestamp. Breakdowns will only be returned for time windows that end on or before this time. (format: date-time, e.g. 2024-02-01T00:00:00Z)
]: nothing -> record<data: table<id: string, customer_id: string, customer_custom_fields: record, netsuite_sales_order_id: string, salesforce_opportunity_id: string, net_payment_terms_days: float, credit_type: record, line_items: list, start_timestamp: string, end_timestamp: string, issued_at: string, created_at: string, status: string, total: float, type: string, external_invoice: record, revenue_system_invoices: list, contract_id: string, contract_custom_fields: record, amendment_id: string, correction_record: record, reseller_royalty: record, custom_fields: record, billable_status: string, constituent_invoices: list, payer: record, regenerated_from_invoice_id: string, breakdown_start_timestamp: string, breakdown_end_timestamp: string>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next_page" $next_page "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "skip_zero_qty_line_items" $skip_zero_qty_line_items "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "window_size" $window_size "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "credit_type_id" $credit_type_id "scalar") (serialize-qp "starting_on" $starting_on "scalar") (serialize-qp "ending_before" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/customers/($customer_id)/invoices/breakdowns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an invoice PDF
#
# GET /v1/customers/{customer_id}/invoices/{invoice_id}/pdf
# operationId: getInvoicePdf-v1
export def "customers-invoices-pdf get" [
  customer_id: string
  invoice_id: string
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
  let full_url = (build-url $base $"/v1/customers/($customer_id)/invoices/($invoice_id)/pdf")
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an invoice
#
# GET /v1/customers/{customer_id}/invoices/{invoice_id}
# operationId: getInvoice-v1
export def "customers-invoices get" [
  customer_id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-zero-qty-line-items: oneof<nothing, bool> # If set, all zero quantity line items will be filtered out of the response
]: nothing -> record<data: record<id: string, customer_id: string, customer_custom_fields: record, netsuite_sales_order_id: string, salesforce_opportunity_id: string, net_payment_terms_days: float, credit_type: record<name: string, id: string>, line_items: list<record>, start_timestamp: string, end_timestamp: string, issued_at: string, created_at: string, status: string, total: float, type: string, external_invoice: record<billing_provider_type: string, invoice_id: string, issued_at_timestamp: string, external_status: string, pdf_url: string, tax: record, invoiced_total: float, invoiced_sub_total: float, billing_provider_error: string, external_payment_id: string>, revenue_system_invoices: list<record>, contract_id: string, contract_custom_fields: record, amendment_id: string, correction_record: record<reason: string, memo: string, corrected_invoice_id: string, corrected_external_invoice: record>, reseller_royalty: record<reseller_type: string, netsuite_reseller_id: string, fraction: string, aws_options: record, gcp_options: record>, custom_fields: record, billable_status: string, constituent_invoices: list<record>, payer: record<contract_id: string, customer_id: string>, regenerated_from_invoice_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip_zero_qty_line_items" $skip_zero_qty_line_items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/customers/($customer_id)/invoices/($invoice_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List spend invoice breakdowns
#
# POST /v1/customers/{customer_id}/invoices/spend-breakdowns
# operationId: listSpendBreakdownInvoices-v1
export def "customers-invoices-spend-breakdowns listSpendBreakdownInvoices-v1" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-list-prices: oneof<nothing, bool> # If set, list prices will be returned for each contract usage and subscription line item.
  starting_on: string # RFC 3339 timestamp. Breakdowns will only be returned for time windows that start on or after this time. (format: date-time)
  ending_before: string # RFC 3339 timestamp. Breakdowns will only be returned for time windows that end on or before this time. (format: date-time)
  --skip-zero-qty-line-items: oneof<nothing, bool> # If set, all zero quantity line items will be filtered out of the response.
  --credit-type-id: string # If provided, only invoices with the specified credit type id will be included in the response. (format: uuid)
  --body-sort: string@sort-completer # Invoice sort order by issued_at, e.g. date_asc or date_desc.  Defaults to date_asc. (default: date_asc)
  --window-size: string@window-size-completer-2 # The granularity of the breakdowns to return. Defaults to "day".
  --group-keys: list # A list of keys that can be used to additionally segment the values of the billable metric when making usage queries. Must be valid keys that are present in the billable metrics or an empty list. The value will be ignored and the default keys will be used if: billable metric is MAX type; product uses tiered pricing model; product has quantity rounding enabled; there are contract overrides based on presentation group keys
  --group-filters: record # An object where the keys are the group keys and the values are arrays of group values. If the values is an empty array, the returned usage data will be aggregated across all values for that key. The value will be ignored and the default keys will be used if: billable metric is MAX type; product uses tiered pricing model; product has quantity rounding enabled; there are contract overrides based on presentation group keys
  --limit: int # Max number of results that should be returned. For daily and "none" breakdowns, the response can return up to 35 days worth of breakdowns. If there are more results, a cursor to the next page is returned. (default: 100)
  --next-page: string # Cursor that indicates where the next page of results should start.
]: any -> record<data: table<id: string, customer_id: string, credit_type: record, line_items: list, start_timestamp: string, end_timestamp: string, issued_at: string, created_at: string, status: string, type: string, contract_id: string, breakdown_start_timestamp: string, breakdown_end_timestamp: string>, next_page: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_list_prices" $include_list_prices "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/customers/($customer_id)/invoices/spend-breakdowns" $qp)
  let body = {starting_on: $starting_on, ending_before: $ending_before, skip_zero_qty_line_items: $skip_zero_qty_line_items, credit_type_id: $credit_type_id, sort: $body_sort, window_size: $window_size, group_keys: $group_keys, group_filters: $group_filters, limit: $limit, next_page: $next_page} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Void an invoice
#
# POST /v1/invoices/void
# operationId: voidInvoice-v1
export def "invoices-void voidInvoice-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # The invoice id to void (format: uuid)
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/invoices/void")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Regenerate an invoice
#
# POST /v1/invoices/regenerate
# operationId: regenerateInvoice-v1
export def "invoices-regenerate regenerateInvoice-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # The invoice id to regenerate (format: uuid)
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/invoices/regenerate")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Preview events
#
# POST /v1/customers/{customer_id}/previewEvents
# operationId: previewCustomerEvents-v1
# --events item shape: {event_type: string, timestamp?: string, properties?: record, transaction_id?: string}
export def "customers-preview-events previewCustomerEvents-v1" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  events: list # Array of usage events to include in the preview calculation. Must contain at least one event in `merge` mode. — item shape: {event_type: string, timestamp?: string, properties?: record, transaction_id?: string}
  --mode: string@mode-completer # Controls how the provided events are combined with existing usage data. Use `replace` to calculate the preview as if these are the only events for the customer, ignoring all historical usage.  Use `merge` to combine these events with the customer's existing usage.  Defaults to `replace`.  (default: replace)
  --skip-zero-qty-line-items: oneof<nothing, bool> # When `true`, line items with zero quantity are excluded from the response. (default: false)
]: any -> record<data: table<id: string, customer_id: string, customer_custom_fields: record, netsuite_sales_order_id: string, salesforce_opportunity_id: string, net_payment_terms_days: float, credit_type: record, line_items: list, start_timestamp: string, end_timestamp: string, issued_at: string, created_at: string, status: string, total: float, type: string, external_invoice: record, revenue_system_invoices: list, contract_id: string, contract_custom_fields: record, amendment_id: string, correction_record: record, reseller_royalty: record, custom_fields: record, billable_status: string, constituent_invoices: list, payer: record, regenerated_from_invoice_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/customers/($customer_id)/previewEvents")
  let body = {events: $events, mode: $mode, skip_zero_qty_line_items: $skip_zero_qty_line_items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set up account-level billing provider
#
# POST /v1/setUpBillingProvider
# operationId: setUpBillingProvider-v1
export def "set-up-billing-provider setUpBillingProvider-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  billing_provider: string@billing-provider-completer
  delivery_method: string@delivery-method-completer
  configuration: record # Account-level configuration for the billing provider. The structure of this object is specific to the billing provider and delivery provider combination. See examples below.
]: any -> record<data: record<delivery_method_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/setUpBillingProvider")
  let body = {billing_provider: $billing_provider, delivery_method: $delivery_method, configuration: $configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upsert Anrok API token
#
# POST /v1/upsertAnrokApiToken
# operationId: upsertAnrokApiToken-v1
export def "upsert-anrok-api-token upsertAnrokApiToken-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  delivery_method_ids: list # The delivery method IDs of the billing provider configurations to update, can be found in the response of the `/listConfiguredBillingProviders` endpoint. (format: uuid)
  anrok_api_token: string # The Anrok API token that is added to the configuration.
]: any -> record<data: record<success: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/upsertAnrokApiToken")
  let body = {delivery_method_ids: $delivery_method_ids, anrok_api_token: $anrok_api_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upsert Avalara credentials
#
# POST /v1/upsertAvalaraCredentials
# operationId: upsertAvalaraCredentials-v1
export def "upsert-avalara-credentials upsertAvalaraCredentials-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  delivery_method_ids: list # The delivery method IDs of the billing provider configurations to update, can be found in the response of the `/listConfiguredBillingProviders` endpoint. (format: uuid)
  avalara_environment: string@avalara-environment-completer # The Avalara environment to use (SANDBOX or PRODUCTION).
  avalara_username: string # The username for the Avalara account.
  avalara_password: string # The password for the Avalara account.
  --commit-transactions: oneof<nothing, bool> # Commit transactions if you want Metronome tax calculations used for reporting and tax filings.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/upsertAvalaraCredentials")
  let body = {delivery_method_ids: $delivery_method_ids, avalara_environment: $avalara_environment, avalara_username: $avalara_username, avalara_password: $avalara_password, commit_transactions: $commit_transactions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Rotate the HMAC secret used to sign delta stream messages
#
# POST /v1/rotateDeltaStreamSecret
# operationId: rotateDeltaStreamSecret-v1
export def "rotate-delta-stream-secret rotateDeltaStreamSecret-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --starting-on: string # When the new secret shold start being used, scheduled up to a month ahead of time. If not provided, deefaults to 10 minutes from now. (format: date-time)
]: any -> record<secret: string, starting_on: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/rotateDeltaStreamSecret")
  let body = {starting_on: $starting_on} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List account-level billing providers
#
# POST /v1/listConfiguredBillingProviders
# operationId: listConfiguredBillingProviders-v1
export def "list-configured-billing-providers listConfiguredBillingProviders-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-page: string # The cursor to the next page of results (nullable, format: uuid)
]: any -> record<data: table<billing_provider: string, delivery_method_id: string, delivery_method: string, delivery_method_configuration: record>, next_page: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/listConfiguredBillingProviders")
  let body = {next_page: $next_page} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch billing provider configurations for a customer
#
# POST /v1/getCustomerBillingProviderConfigurations
# operationId: getCustomerBillingProviderConfigurations-v1
export def "get-customer-billing-provider-configurations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  --include-archived: oneof<nothing, bool>
]: any -> record<data: table<id: string, billing_provider: string, customer_id: string, configuration: record, delivery_method_id: string, delivery_method: string, delivery_method_configuration: record, archived_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/getCustomerBillingProviderConfigurations")
  let body = {customer_id: $customer_id, include_archived: $include_archived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch revenue system configurations for a customer
#
# POST /v1/getCustomerRevenueSystemConfigurations
# operationId: getCustomerRevenueSystemConfigurations-v1
export def "get-customer-revenue-system-configurations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  --provider: string@provider-completer
  --include-archived: oneof<nothing, bool> # Whether to include archived configurations
]: any -> record<data: table<id: string, customer_id: string, delivery_method_id: string, provider: string, configuration: record, delivery_method: string, delivery_method_configuration: record, archived_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/getCustomerRevenueSystemConfigurations")
  let body = {customer_id: $customer_id, provider: $provider, include_archived: $include_archived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set billing provider configurations for a customer
#
# POST /v1/setCustomerBillingProviderConfigurations
# operationId: setCustomerBillingProviderConfigurations-v1
# --data item shape: {billing_provider: "aws_marketplace"|"stripe"|"netsuite"|"custom"|"azure_marketplace"|"quickbooks_online"|"workday"|"gcp_marketplace"|"metronome", customer_id: string, tax_provider?: "anrok"|"avalara"|"stripe", configuration?: record, delivery_method_id?: string, delivery_method?: "direct_to_billing_provider"|"aws_sqs"|"tackle"|"aws_sns"}
export def "set-customer-billing-provider-configurations setCustomerBillingProviderConfigurations-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {billing_provider: "aws_marketplace"|"stripe"|"netsuite"|"custom"|"azure_marketplace"|"quickbooks_online"|"workday"|"gcp_marketplace"|"metronome", customer_id: string, tax_provider?: "anrok"|"avalara"|"stripe", configuration?: record, delivery_method_id?: string, delivery_method?: "direct_to_billing_provider"|"aws_sqs"|"tackle"|"aws_sns"}
]: any -> record<data: table<id: string, billing_provider: string, customer_id: string, configuration: record, delivery_method_id: string, tax_provider: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/setCustomerBillingProviderConfigurations")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archive billing provider configurations for a customer
#
# POST /v1/archiveCustomerBillingProviderConfigurations
# operationId: archiveCustomerBillingProviderConfigurations-v1
export def "archive-customer-billing-provider-configurations archiveCustomerBillingProviderConfigurations-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_billing_provider_configuration_ids: list # Array of billing provider configuration IDs to archive
  customer_id: string # The customer ID the billing provider configurations belong to (format: uuid)
]: any -> record<data: record<customer_billing_provider_configuration_ids: list<string>, customer_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/archiveCustomerBillingProviderConfigurations")
  let body = {customer_billing_provider_configuration_ids: $customer_billing_provider_configuration_ids, customer_id: $customer_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set revenue system configurations for a customer
#
# POST /v1/setCustomerRevenueSystemConfigurations
# operationId: setCustomerRevenueSystemConfigurations-v1
# --data item shape: {provider: "netsuite", customer_id: string, configuration: record, delivery_method_id?: string}
export def "set-customer-revenue-system-configurations setCustomerRevenueSystemConfigurations-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {provider: "netsuite", customer_id: string, configuration: record, delivery_method_id?: string}
]: any -> record<data: table<id: string, customer_id: string, delivery_method_id: string, provider: string, configuration: record, delivery_method: string, delivery_method_configuration: record, archived_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/setCustomerRevenueSystemConfigurations")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archive revenue system configurations for a customer
#
# POST /v1/archiveCustomerRevenueSystemConfigurations
# operationId: archiveCustomerRevenueSystemConfigurations-v1
export def "archive-customer-revenue-system-configurations archiveCustomerRevenueSystemConfigurations-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_revenue_system_configuration_ids: list # Array of revenue system configuration IDs to archive
  customer_id: string # The customer ID the revenue system configurations belong to (format: uuid)
]: any -> record<data: record<customer_revenue_system_configuration_ids: list<string>, customer_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/archiveCustomerRevenueSystemConfigurations")
  let body = {customer_revenue_system_configuration_ids: $customer_revenue_system_configuration_ids, customer_id: $customer_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an embeddable customer dashboard
#
# POST /v1/dashboards/getEmbeddableUrl
# operationId: embeddableDashboard-v1
# --dashboard_options item shape: {key: string, value: string}
# --color_overrides item shape: {name?: "Gray_dark"|"Gray_medium"|"Gray_light"|"Gray_extralight"|"White"|"Primary_medium"|"Primary_light"|"UsageLine_0"|"UsageLine_1"|"UsageLine_2"|"UsageLine_3"|"UsageLine_4"|"UsageLine_5"|"UsageLine_6"|"UsageLine_7"|"UsageLine_8"|"UsageLine_9"|"Primary_green"|"Primary_red"|"Progress_bar"|"Progress_bar_background", value?: string}
# --bm_group_key_overrides item shape: {group_key_name: string, display_name?: string, value_display_names?: record}
export def "dashboards-get-embeddable-url embeddableDashboard-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  dashboard: string@dashboard-completer # The type of dashboard to retrieve.
  --dashboard-options: list # Optional dashboard specific options — item shape: {key: string, value: string}
  --color-overrides: list # Optional list of colors to override — item shape: {name?: "Gray_dark"|"Gray_medium"|"Gray_light"|"Gray_extralight"|"White"|"Primary_medium"|"Primary_light"|"UsageLine_0"|"UsageLine_1"|"UsageLine_2"|"UsageLine_3"|"UsageLine_4"|"UsageLine_5"|"UsageLine_6"|"UsageLine_7"|"UsageLine_8"|"UsageLine_9"|"Primary_green"|"Primary_red"|"Progress_bar"|"Progress_bar_background", value?: string}
  --bm-group-key-overrides: list # Optional list of billable metric group key overrides — item shape: {group_key_name: string, display_name?: string, value_display_names?: record}
]: any -> record<data: record<url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dashboards/getEmbeddableUrl")
  let body = {customer_id: $customer_id, dashboard: $dashboard, dashboard_options: $dashboard_options, color_overrides: $color_overrides, bm_group_key_overrides: $bm_group_key_overrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Log events from integration services to Cloudwatch
#
# POST /v1/integrations/log
# operationId: integrationCloudwatchLogger-v1
# --dimensions item shape: {name: string, value: string}
export def "integrations-log integrationCloudwatchLogger-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  service_name: string
  metric_name: string
  dimensions: list # item shape: {name: string, value: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/integrations/log")
  let body = {service_name: $service_name, metric_name: $metric_name, dimensions: $dimensions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get audit logs
#
# GET /v1/auditLogs
# operationId: getAuditLogs-v1
export def "audit-logs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results that should be returned
  --next-page: string # Cursor that indicates where the next page of results should start.
  --starting-on: string # RFC 3339 timestamp of the earliest audit log to return. Cannot be used with 'next_page'. (format: date-time)
  --ending-before: string # RFC 3339 timestamp (exclusive). Cannot be used with 'next_page'. (format: date-time)
  --qp-sort: string@sort-completer # Sort order by timestamp, e.g. date_asc or date_desc. Defaults to date_asc.
  --resource-id: string # Optional parameter that can be used to filter which audit logs are returned. If you specify resource_id, you must also specify resource_type.
  --resource-type: string # Optional parameter that can be used to filter which audit logs are returned. If you specify resource_type, you must also specify resource_id.
]: nothing -> record<data: table<id: string, timestamp: string, actor: record, request: record, resource_type: string, resource_id: string, action: string, status: string, description: string>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "next_page" $next_page "scalar") (serialize-qp "starting_on" $starting_on "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "resource_id" $resource_id "scalar") (serialize-qp "resource_type" $resource_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/auditLogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get services
#
# GET /v1/services
# operationId: getServices-v1
export def "services get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<services: table<name: string, usage: string, ips: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/services")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a custom field key
#
# POST /v1/customFields/addKey
# operationId: addCustomFieldKey-v1
export def "custom-fields-add-key addCustomFieldKey-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  entity: string@entity-completer
  key: string
  --enforce-uniqueness: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customFields/addKey")
  let body = {entity: $entity, key: $key, enforce_uniqueness: $enforce_uniqueness} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a custom field key
#
# POST /v1/customFields/removeKey
# operationId: disableCustomFieldKey-v1
export def "custom-fields-remove-key disableCustomFieldKey-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  entity: string@entity-completer
  key: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customFields/removeKey")
  let body = {entity: $entity, key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set custom field values
#
# POST /v1/customFields/setValues
# operationId: setCustomFields-v1
export def "custom-fields-set-values setCustomFields-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  entity: string@entity-completer
  entity_id: string # format: uuid
  custom_fields: record # Custom fields to be added eg. { "key1": "value1", "key2": "value2" }
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customFields/setValues")
  let body = {entity: $entity, entity_id: $entity_id, custom_fields: $custom_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete custom fields
#
# POST /v1/customFields/deleteValues
# operationId: deleteCustomFields-v1
export def "custom-fields-delete-values post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  entity: string@entity-completer
  entity_id: string # format: uuid
  keys: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customFields/deleteValues")
  let body = {entity: $entity, entity_id: $entity_id, keys: $keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List custom field keys
#
# POST /v1/customFields/listKeys
# operationId: listCustomFieldKeys-v1
export def "custom-fields-list-keys listCustomFieldKeys-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-page: string # Cursor that indicates where the next page of results should start.
  --entities: list # Optional list of entity types to return keys for
]: any -> record<data: table<entity: string, key: string, enforce_uniqueness: bool>, next_page: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next_page" $next_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/customFields/listKeys" $qp)
  let body = {entities: $entities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a product
#
# POST /v1/contract-pricing/products/get
# operationId: getProduct-v1
export def "contract-pricing-products-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: uuid
]: any -> record<data: record<id: string, type: string, archived_at: string, initial: record<name: string, starting_at: string, netsuite_internal_item_id: string, created_at: string, created_by: string, netsuite_overage_item_id: string, billable_metric_id: string, composite_product_ids: list, quantity_conversion: record, quantity_rounding: record, composite_tags: list, is_refundable: bool, tags: list, composite_scope: string, exclude_free_usage: bool, include_composite_spend: bool, pricing_group_key: list, presentation_group_key: list>, current: record<name: string, starting_at: string, netsuite_internal_item_id: string, created_at: string, created_by: string, netsuite_overage_item_id: string, billable_metric_id: string, composite_product_ids: list, quantity_conversion: record, quantity_rounding: record, composite_tags: list, is_refundable: bool, tags: list, composite_scope: string, exclude_free_usage: bool, include_composite_spend: bool, pricing_group_key: list, presentation_group_key: list>, updates: list<record>, custom_fields: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contract-pricing/products/get")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List products
#
# POST /v1/contract-pricing/products/list
# operationId: listProducts-v1
export def "contract-pricing-products-list listProducts-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results that should be returned
  --next-page: string # Cursor that indicates where the next page of results should start.
  --archive-filter: string@archive-filter-completer # Filter options for the product list. If not provided, defaults to not archived.
]: any -> record<data: table<id: string, type: string, archived_at: string, initial: record, current: record, updates: list, custom_fields: record>, next_page: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "next_page" $next_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/contract-pricing/products/list" $qp)
  let body = {archive_filter: $archive_filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a product
#
# POST /v1/contract-pricing/products/create
# operationId: createProduct-v1
# --quantity_conversion shape: {name?: string, conversion_factor: float, operation: "multiply"|"divide"|"MULTIPLY"|"DIVIDE"}
# --quantity_rounding shape: {rounding_method: "round_up"|"round_down"|"round_half_up"|"ROUND_UP"|"ROUND_DOWN"|"ROUND_HALF_UP", decimal_places: float}
export def "contract-pricing-products-create createProduct-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # displayed on invoices
  type: string@type-completer-1
  --netsuite-internal-item-id: string # This field's availability is dependent on your client's configuration.
  --netsuite-overage-item-id: string # This field's availability is dependent on your client's configuration.
  --billable-metric-id: string # Required for USAGE products (format: uuid)
  --sql-breakdown-granularity: string@sql-breakdown-granularity-completer # Defines the breakdown behavior when calculating usage from SQL Billable Metrics. If set to 'service_period' (default), the usage will be evaluated once for all events the invoice service period and the usage will be applied at the last instant of the invoice. If set to 'hour', it will be broken down and evaluated for each hour. For most use cases, 'hour' is recommended. The setting has no effect for Streaming Billable Metrics.
  --composite-product-ids: list # Required for COMPOSITE products
  --composite-tags: list # Required for COMPOSITE products
  --is-refundable: oneof<nothing, bool> # This field's availability is dependent on your client's configuration. Defaults to true.
  --composite-scope: string@composite-scope-completer # Determines what spend contributes to calculating this charge. When composite scope is contract, calculates composite charge based on applicable spend per contract. When composite scope is customer, calculates composite charge based on applicable spend across all customer contracts. Defaults to contract.
  --exclude-free-usage: oneof<nothing, bool> # Beta feature only available for composite products. If true, products with $0 will not be included when computing composite usage. Defaults to false
  --include-composite-spend: oneof<nothing, bool> # Only for composite products. If true, allows a composite to incorporate spend from other composite products. Defaults to false
  --tags: list
  --pricing-group-key: list # For USAGE products only. If set, pricing for this product will be determined for each pricing_group_key value, as opposed to the product as a whole. The superset of values in the pricing group key and presentation group key must be set as one compound group key on the billable metric.
  --presentation-group-key: list # For USAGE products only. Groups usage line items on invoices. The superset of values in the pricing group key and presentation group key must be set as one compound group key on the billable metric.
  --quantity-conversion: record # Optional. Only valid for USAGE products. If provided, the quantity will be converted using the provided conversion factor and operation. For example, if the operation is "multiply" and the conversion factor is 100, then the quantity will be multiplied by 100. This can be used in cases where data is sent in one unit and priced in another.  For example, data could be sent in MB and priced in GB. In this case, the conversion factor would be 1024 and the operation would be "divide". (nullable) — shape: {name?: string, conversion_factor: float, operation: "multiply"|"divide"|"MULTIPLY"|"DIVIDE"}
  --quantity-rounding: record # Optional. Only valid for USAGE products. If provided, the quantity will be rounded using the provided rounding method and decimal places. For example, if the method is "round up" and the decimal places is 0, then the quantity will be rounded up to the nearest integer. (nullable) — shape: {rounding_method: "round_up"|"round_down"|"round_half_up"|"ROUND_UP"|"ROUND_DOWN"|"ROUND_HALF_UP", decimal_places: float}
  --custom-fields: record # Custom fields to be added eg. { "key1": "value1", "key2": "value2" }
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contract-pricing/products/create")
  let body = {name: $name, type: $type, netsuite_internal_item_id: $netsuite_internal_item_id, netsuite_overage_item_id: $netsuite_overage_item_id, billable_metric_id: $billable_metric_id, sql_breakdown_granularity: $sql_breakdown_granularity, composite_product_ids: $composite_product_ids, composite_tags: $composite_tags, is_refundable: $is_refundable, composite_scope: $composite_scope, exclude_free_usage: $exclude_free_usage, include_composite_spend: $include_composite_spend, tags: $tags, pricing_group_key: $pricing_group_key, presentation_group_key: $presentation_group_key, quantity_conversion: $quantity_conversion, quantity_rounding: $quantity_rounding, custom_fields: $custom_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a product
#
# POST /v1/contract-pricing/products/update
# operationId: updateProduct-v1
# --quantity_conversion shape: {name?: string, conversion_factor: float, operation: "multiply"|"divide"|"MULTIPLY"|"DIVIDE"}
# --quantity_rounding shape: {rounding_method: "round_up"|"round_down"|"round_half_up"|"ROUND_UP"|"ROUND_DOWN"|"ROUND_HALF_UP", decimal_places: float}
export def "contract-pricing-products-update updateProduct-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  product_id: string # ID of the product to update (format: uuid)
  --name: string # displayed on invoices. If not provided, defaults to product's current name.
  starting_at: string # Timestamp representing when the update should go into effect. It must be on an hour boundary (e.g. 1:00, not 1:30). (format: date-time)
  --is-refundable: oneof<nothing, bool> # Defaults to product's current refundability status. This field's availability is dependent on your client's configuration.
  --exclude-free-usage: oneof<nothing, bool> # Beta feature only available for composite products. If true, products with $0 will not be included when computing composite usage. Defaults to false
  --include-composite-spend: oneof<nothing, bool> # Only for composite products. If true, allows a composite to incorporate spend from other composite products. Defaults to false
  --billable-metric-id: string # Available for USAGE products only. If not provided, defaults to product's current billable metric. (format: uuid)
  --sql-breakdown-granularity: string@sql-breakdown-granularity-completer # Defines the breakdown behavior when calculating usage from SQL Billable Metrics. If set to 'service_period' (default), the usage will be evaluated once for all events the invoice service period and the usage will be applied at the last instant of the invoice. If set to 'hour', it will be broken down and evaluated for each hour. For most use cases, 'hour' is recommended. The setting has no effect for Streaming Billable Metrics.
  --netsuite-internal-item-id: string # If not provided, defaults to product's current netsuite_internal_item_id. This field's availability is dependent on your client's configuration.
  --netsuite-overage-item-id: string # Available for USAGE and COMPOSITE products only. If not provided, defaults to product's current netsuite_overage_item_id. This field's availability is dependent on your client's configuration.
  --composite-product-ids: list # Available for COMPOSITE products only. If not provided, defaults to product's current composite_product_ids.
  --quantity-conversion: record # Optional. Only valid for USAGE products. If provided, the quantity will be converted using the provided conversion factor and operation. For example, if the operation is "multiply" and the conversion factor is 100, then the quantity will be multiplied by 100. This can be used in cases where data is sent in one unit and priced in another.  For example, data could be sent in MB and priced in GB. In this case, the conversion factor would be 1024 and the operation would be "divide". (nullable) — shape: {name?: string, conversion_factor: float, operation: "multiply"|"divide"|"MULTIPLY"|"DIVIDE"}
  --quantity-rounding: record # Optional. Only valid for USAGE products. If provided, the quantity will be rounded using the provided rounding method and decimal places. For example, if the method is "round up" and the decimal places is 0, then the quantity will be rounded up to the nearest integer. (nullable) — shape: {rounding_method: "round_up"|"round_down"|"round_half_up"|"ROUND_UP"|"ROUND_DOWN"|"ROUND_HALF_UP", decimal_places: float}
  --tags: list # If not provided, defaults to product's current tags
  --composite-tags: list # Available for COMPOSITE products only. If not provided, defaults to product's current composite_tags.
  --pricing-group-key: list # For USAGE products only. If set, pricing for this product will be determined for each pricing_group_key value, as opposed to the product as a whole. The superset of values in the pricing group key and presentation group key must be set as one compound group key on the billable metric.
  --presentation-group-key: list # For USAGE products only. Groups usage line items on invoices. The superset of values in the pricing group key and presentation group key must be set as one compound group key on the billable metric.
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contract-pricing/products/update")
  let body = {product_id: $product_id, name: $name, starting_at: $starting_at, is_refundable: $is_refundable, exclude_free_usage: $exclude_free_usage, include_composite_spend: $include_composite_spend, billable_metric_id: $billable_metric_id, sql_breakdown_granularity: $sql_breakdown_granularity, netsuite_internal_item_id: $netsuite_internal_item_id, netsuite_overage_item_id: $netsuite_overage_item_id, composite_product_ids: $composite_product_ids, quantity_conversion: $quantity_conversion, quantity_rounding: $quantity_rounding, tags: $tags, composite_tags: $composite_tags, pricing_group_key: $pricing_group_key, presentation_group_key: $presentation_group_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archive a product
#
# POST /v1/contract-pricing/products/archive
# operationId: archiveProductListItem-v1
export def "contract-pricing-products-archive archiveProductListItem-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  product_id: string # ID of the product to be archived (format: uuid)
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contract-pricing/products/archive")
  let body = {product_id: $product_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a rate schedule
#
# POST /v1/contract-pricing/rate-cards/getRateSchedule
# operationId: getRateSchedule-v1
# --selectors item shape: {billing_frequency?: "MONTHLY"|"Monthly"|"monthly"|"QUARTERLY"|"Quarterly"|"quarterly"|"ANNUAL"|"Annual"|"annual"|"WEEKLY"|"Weekly"|"weekly", product_id?: string, pricing_group_values?: record, partial_pricing_group_values?: record}
export def "contract-pricing-rate-cards-get-rate-schedule post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results that should be returned
  --next-page: string # Cursor that indicates where the next page of results should start.
  rate_card_id: string # ID of the rate card to get the schedule for (format: uuid)
  starting_at: string # inclusive starting point for the rates schedule (format: date-time)
  --ending-before: string # optional exclusive end date for the rates schedule. When not specified rates will show all future schedule segments. (format: date-time)
  --selectors: list # List of rate selectors, rates matching ANY of the selector will be included in the response Passing no selectors will result in all rates being returned. — item shape: {billing_frequency?: "MONTHLY"|"Monthly"|"monthly"|"QUARTERLY"|"Quarterly"|"quarterly"|"ANNUAL"|"Annual"|"annual"|"WEEKLY"|"Weekly"|"weekly", product_id?: string, pricing_group_values?: record, partial_pricing_group_values?: record}
]: any -> record<next_page: string, data: table<product_id: string, product_name: string, product_tags: list, product_custom_fields: record, pricing_group_values: record, starting_at: string, ending_before: string, entitled: bool, rate: record, commit_rate: record, billing_frequency: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "next_page" $next_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/contract-pricing/rate-cards/getRateSchedule" $qp)
  let body = {rate_card_id: $rate_card_id, starting_at: $starting_at, ending_before: $ending_before, selectors: $selectors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get rates
#
# POST /v1/contract-pricing/rate-cards/getRates
# operationId: getRates-v1
# --selectors item shape: {billing_frequency?: "MONTHLY"|"Monthly"|"monthly"|"QUARTERLY"|"Quarterly"|"quarterly"|"ANNUAL"|"Annual"|"annual"|"WEEKLY"|"Weekly"|"weekly", product_id?: string, product_tags?: list, pricing_group_values?: record, partial_pricing_group_values?: record}
export def "contract-pricing-rate-cards-get-rates post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results that should be returned
  --next-page: string # Cursor that indicates where the next page of results should start.
  rate_card_id: string # ID of the rate card to get the schedule for (format: uuid)
  at: string # inclusive starting point for the rates schedule (format: date-time)
  --selectors: list # List of rate selectors, rates matching ANY of the selector will be included in the response Passing no selectors will result in all rates being returned. — item shape: {billing_frequency?: "MONTHLY"|"Monthly"|"monthly"|"QUARTERLY"|"Quarterly"|"quarterly"|"ANNUAL"|"Annual"|"annual"|"WEEKLY"|"Weekly"|"weekly", product_id?: string, product_tags?: list, pricing_group_values?: record, partial_pricing_group_values?: record}
]: any -> record<next_page: string, data: table<product_id: string, product_name: string, product_tags: list, product_custom_fields: record, pricing_group_values: record, starting_at: string, ending_before: string, entitled: bool, rate: record, commit_rate: record, billing_frequency: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "next_page" $next_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/contract-pricing/rate-cards/getRates" $qp)
  let body = {rate_card_id: $rate_card_id, at: $at, selectors: $selectors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a rate card
#
# POST /v1/contract-pricing/rate-cards/get
# operationId: getRateCard-v1
export def "contract-pricing-rate-cards-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: uuid
]: any -> record<data: record<id: string, name: string, created_at: string, created_by: string, description: string, fiat_credit_type: record<name: string, id: string>, credit_type_conversions: list<record>, aliases: list<record>, custom_fields: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contract-pricing/rate-cards/get")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List rate cards
#
# POST /v1/contract-pricing/rate-cards/list
# operationId: listRateCards-v1
export def "contract-pricing-rate-cards-list listRateCards-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results that should be returned
  --next-page: string # Cursor that indicates where the next page of results should start.
  --body: record
]: any -> record<data: table<id: string, name: string, created_at: string, created_by: string, description: string, fiat_credit_type: record, credit_type_conversions: list, aliases: list, custom_fields: record>, next_page: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "next_page" $next_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/contract-pricing/rate-cards/list" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a rate card
#
# POST /v1/contract-pricing/rate-cards/create
# operationId: createRateCard-v1
# --credit_type_conversions item shape: {custom_credit_type_id: string, fiat_per_custom_credit: float}
# --aliases item shape: {name: string, starting_at?: string, ending_before?: string}
export def "contract-pricing-rate-cards-create createRateCard-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Used only in UI/API. It is not exposed to end customers.
  --description: string
  --fiat-credit-type-id: string # The Metronome ID of the credit type to associate with the rate card, defaults to USD (cents) if not passed. (format: uuid, e.g. 2714e483-4ff1-48e4-9e25-ac732e8f24f2)
  --credit-type-conversions: list # Required when using custom pricing units in rates. — item shape: {custom_credit_type_id: string, fiat_per_custom_credit: float}
  --aliases: list # Reference this alias when creating a contract. If the same alias is assigned to multiple rate cards, it will reference the rate card to which it was most recently assigned. It is not exposed to end customers. — item shape: {name: string, starting_at?: string, ending_before?: string}
  --custom-fields: record # Custom fields to be added eg. { "key1": "value1", "key2": "value2" }
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contract-pricing/rate-cards/create")
  let body = {name: $name, description: $description, fiat_credit_type_id: $fiat_credit_type_id, credit_type_conversions: $credit_type_conversions, aliases: $aliases, custom_fields: $custom_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a rate card
#
# POST /v1/contract-pricing/rate-cards/update
# operationId: updateRateCard-v1
# --aliases item shape: {name: string, starting_at?: string, ending_before?: string}
export def "contract-pricing-rate-cards-update updateRateCard-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  rate_card_id: string # ID of the rate card to update (format: uuid)
  --name: string # Used only in UI/API. It is not exposed to end customers.
  --description: string
  --aliases: list # Reference this alias when creating a contract. If the same alias is assigned to multiple rate cards, it will reference the rate card to which it was most recently assigned. It is not exposed to end customers. — item shape: {name: string, starting_at?: string, ending_before?: string}
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contract-pricing/rate-cards/update")
  let body = {rate_card_id: $rate_card_id, name: $name, description: $description, aliases: $aliases} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archive a rate card
#
# POST /v1/contract-pricing/rate-cards/archive
# operationId: archiveRateCard-v1
export def "contract-pricing-rate-cards-archive archiveRateCard-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # format: uuid
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contract-pricing/rate-cards/archive")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a rate
#
# POST /v1/contract-pricing/rate-cards/addRate
# operationId: addRate-v1
# --tiers item shape: {size?: float, price: float}
# --minimum_config shape: {minimum: float}
# --commit_rate shape: {rate_type: "FLAT"|"flat"|"PERCENTAGE"|"percentage"|"SUBSCRIPTION"|"subscription"|"TIERED"|"tiered"|"TIERED_PERCENTAGE"|"tiered_percentage"|"CUSTOM"|"custom", price?: float, tiers?: list, minimum_config?: record}
export def "contract-pricing-rate-cards-add-rate addRate-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  rate_card_id: string # ID of the rate card to update (format: uuid)
  product_id: string # ID of the product to add a rate for (format: uuid)
  --pricing-group-values: record # Optional. List of pricing group key value pairs which will be used to calculate the price.
  --billing-frequency: string@billing-frequency-completer # Optional. Frequency to bill subscriptions with. Required for subscription type products with Flat rate.
  starting_at: string # inclusive effective date (format: date-time)
  --ending-before: string # exclusive end date (format: date-time)
  --entitled: oneof<nothing, bool>
  rate_type: string@rate-type-completer
  --price: float # Default price. For FLAT and SUBSCRIPTION rate_type, this must be >=0. For PERCENTAGE rate_type, this is a decimal fraction, e.g. use 0.1 for 10%; this must be >=0 and <=1.
  --credit-type-id: string # The Metronome ID of the credit type to associate with price, defaults to USD (cents) if not passed. Used by all rate_types except type PERCENTAGE. PERCENTAGE rates use the credit type of associated rates. (format: uuid, e.g. 2714e483-4ff1-48e4-9e25-ac732e8f24f2)
  --quantity: float # Default quantity. For SUBSCRIPTION rate_type, this must be >=0.
  --is-prorated: oneof<nothing, bool> # Default proration configuration. Only valid for SUBSCRIPTION rate_type. Must be set to true.
  --tiers: list # Only set for TIERED rate_type. — item shape: {size?: float, price: float}
  --minimum-config: record # Only set for TIERED_PERCENTAGE or PERCENTAGE rate_type. Any commit-specific overrides will not apply if there is a minimum set on the rate/applied override. — shape: {minimum: float}
  --custom-rate: record # Only set for CUSTOM rate_type. This field is interpreted by custom rate processors.
  --commit-rate: record # A distinct rate on the rate card. You can choose to use this rate rather than list rate when consuming a credit or commit. — shape: {rate_type: "FLAT"|"flat"|"PERCENTAGE"|"percentage"|"SUBSCRIPTION"|"subscription"|"TIERED"|"tiered"|"TIERED_PERCENTAGE"|"tiered_percentage"|"CUSTOM"|"custom", price?: float, tiers?: list, minimum_config?: record}
]: any -> record<data: record<rate_type: string, price: float, custom_rate: record, quantity: float, is_prorated: bool, tiers: list<record>, pricing_group_values: record, credit_type: record<name: string, id: string>, commit_rate: record<rate_type: string, price: float, tiers: list, minimum_config: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contract-pricing/rate-cards/addRate")
  let body = {rate_card_id: $rate_card_id, product_id: $product_id, pricing_group_values: $pricing_group_values, billing_frequency: $billing_frequency, starting_at: $starting_at, ending_before: $ending_before, entitled: $entitled, rate_type: $rate_type, price: $price, credit_type_id: $credit_type_id, quantity: $quantity, is_prorated: $is_prorated, tiers: $tiers, minimum_config: $minimum_config, custom_rate: $custom_rate, commit_rate: $commit_rate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add rates
#
# POST /v1/contract-pricing/rate-cards/addRates
# operationId: addRates-v1
# --rates item shape: {product_id: string, pricing_group_values?: record, billing_frequency?: "MONTHLY"|"QUARTERLY"|"ANNUAL"|"WEEKLY"|"monthly"|"quarterly"|"annual"|"weekly", starting_at: string, ending_before?: string, entitled: bool, rate_type: "FLAT"|"flat"|"PERCENTAGE"|"percentage"|"SUBSCRIPTION"|"subscription"|"TIERED"|"tiered"|"TIERED_PERCENTAGE"|"tiered_percentage"|"CUSTOM"|"custom", price?: float, credit_type_id?: string, quantity?: float, is_prorated?: bool, tiers?: list, minimum_config?: record, custom_rate?: record, commit_rate?: record}
export def "contract-pricing-rate-cards-add-rates addRates-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  rate_card_id: string # format: uuid
  rates: list # item shape: {product_id: string, pricing_group_values?: record, billing_frequency?: "MONTHLY"|"QUARTERLY"|"ANNUAL"|"WEEKLY"|"monthly"|"quarterly"|"annual"|"weekly", starting_at: string, ending_before?: string, entitled: bool, rate_type: "FLAT"|"flat"|"PERCENTAGE"|"percentage"|"SUBSCRIPTION"|"subscription"|"TIERED"|"tiered"|"TIERED_PERCENTAGE"|"tiered_percentage"|"CUSTOM"|"custom", price?: float, credit_type_id?: string, quantity?: float, is_prorated?: bool, tiers?: list, minimum_config?: record, custom_rate?: record, commit_rate?: record}
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contract-pricing/rate-cards/addRates")
  let body = {rate_card_id: $rate_card_id, rates: $rates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set the rate card products order
#
# POST /v1/contract-pricing/rate-cards/setRateCardProductsOrder
# operationId: setRateCardProductsOrder-v1
export def "contract-pricing-rate-cards-set-rate-card-products-order setRateCardProductsOrder-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  rate_card_id: string # ID of the rate card to update (format: uuid)
  product_order: list
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contract-pricing/rate-cards/setRateCardProductsOrder")
  let body = {rate_card_id: $rate_card_id, product_order: $product_order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the rate card products order
#
# POST /v1/contract-pricing/rate-cards/moveRateCardProducts
# operationId: moveRateCardProducts-v1
# --product_moves item shape: {product_id: string, position: float}
export def "contract-pricing-rate-cards-move-rate-card-products moveRateCardProducts-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  rate_card_id: string # ID of the rate card to update (format: uuid)
  product_moves: list # item shape: {product_id: string, position: float}
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contract-pricing/rate-cards/moveRateCardProducts")
  let body = {rate_card_id: $rate_card_id, product_moves: $product_moves} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a contract (v1)
#
# POST /v1/contracts/get
# operationId: getContract-v1
export def "contracts-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  contract_id: string # format: uuid
  --include-ledgers: oneof<nothing, bool> # Include commit ledgers in the response. Setting this flag may cause the query to be slower.
  --include-balance: oneof<nothing, bool> # Include the balance of credits and commits in the response. Setting this flag may cause the query to be slower.
]: any -> record<data: record<id: string, archived_at: string, customer_id: string, package_id: string, uniqueness_key: string, initial: record<name: string, salesforce_opportunity_id: string, rate_card_id: string, starting_at: string, commits: list, credits: list, recurring_commits: list, recurring_credits: list, overrides: list, discounts: list, professional_services: list, scheduled_charges: list, scheduled_charges_on_usage_invoices: string, transitions: list, reseller_royalties: list, created_at: string, created_by: string, netsuite_sales_order_id: string, net_payment_terms_days: float, ending_before: string, total_contract_value: float, usage_filter: record, usage_statement_schedule: record, spend_threshold_configuration: record, prepaid_balance_threshold_configuration: record, spend_trackers: list, hierarchy_configuration: any>, current: record<name: string, salesforce_opportunity_id: string, rate_card_id: string, starting_at: string, commits: list, credits: list, recurring_commits: list, recurring_credits: list, overrides: list, discounts: list, professional_services: list, scheduled_charges: list, scheduled_charges_on_usage_invoices: string, transitions: list, reseller_royalties: list, created_at: string, created_by: string, netsuite_sales_order_id: string, net_payment_terms_days: float, ending_before: string, total_contract_value: float, usage_filter: record, usage_statement_schedule: record, spend_threshold_configuration: record, prepaid_balance_threshold_configuration: record, spend_trackers: list, hierarchy_configuration: any>, amendments: list<record>, custom_fields: record, customer_billing_provider_configuration: record<billing_provider: string, delivery_method: string, id: string, configuration: record, archived_at: string>, scheduled_charges_on_usage_invoices: string, subscriptions: list<record>, spend_threshold_configuration: record<is_enabled: bool, threshold_amount: float, commit: record, payment_gate_config: record, discount_configuration: record>, prepaid_balance_threshold_configuration: record<is_enabled: bool, threshold_amount: float, recharge_to_amount: float, custom_credit_type_id: string, commit: record, payment_gate_config: record, discount_configuration: record, threshold_balance_specifiers: list>, spend_trackers: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/get")
  let body = {customer_id: $customer_id, contract_id: $contract_id, include_ledgers: $include_ledgers, include_balance: $include_balance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List customer contracts (v1)
#
# POST /v1/contracts/list
# operationId: listContracts-v1
export def "contracts-list listContracts-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  --include-ledgers: oneof<nothing, bool> # Include commit ledgers in the response. Setting this flag may cause the query to be slower.
  --include-balance: oneof<nothing, bool> # Include the balance of credits and commits in the response. Setting this flag may cause the query to be slower.
  --include-archived: oneof<nothing, bool> # Include archived contracts in the response
  --starting-at: string # Optional RFC 3339 timestamp. If provided, the response will include only contracts where effective_at is on or after the provided date.  This cannot be provided if the covering_date filter is provided. (format: date-time)
  --covering-date: string # Optional RFC 3339 timestamp. If provided, the response will include only contracts effective on the provided date.  This cannot be provided if the starting_at filter is provided. (format: date-time)
]: any -> record<data: table<id: string, archived_at: string, customer_id: string, package_id: string, uniqueness_key: string, initial: record, current: record, amendments: list, custom_fields: record, customer_billing_provider_configuration: record, scheduled_charges_on_usage_invoices: string, subscriptions: list, spend_threshold_configuration: record, prepaid_balance_threshold_configuration: record, spend_trackers: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/list")
  let body = {customer_id: $customer_id, include_ledgers: $include_ledgers, include_balance: $include_balance, include_archived: $include_archived, starting_at: $starting_at, covering_date: $covering_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a contract
#
# POST /v1/contracts/create
# operationId: createContract-v1
# --commits item shape: {type: "PREPAID"|"prepaid"|"POSTPAID"|"postpaid", rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", name?: string, product_id: string, access_schedule?: record, invoice_schedule?: record, amount?: float, description?: string, rollover_fraction?: float, priority?: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, custom_fields?: record, temporary_id?: string, hierarchy_configuration?: record, spend_tracker_attributes?: any}
# --credits item shape: {name?: string, product_id: string, access_schedule: record, description?: string, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, priority?: float, custom_fields?: record, rollover_fraction?: float, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", hierarchy_configuration?: record}
# --recurring_commits item shape: {name?: string, product_id: string, access_amount: record, description?: string, rollover_fraction?: float, priority: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, temporary_id?: string, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", starting_at: string, ending_before?: string, commit_duration: record, recurrence_frequency?: "MONTHLY"|"monthly"|"QUARTERLY"|"quarterly"|"ANNUAL"|"annual"|"WEEKLY"|"weekly", proration?: "NONE"|"none"|"FIRST"|"first"|"LAST"|"last"|"FIRST_AND_LAST"|"first_and_last", subscription_config?: record, hierarchy_configuration?: record, invoice_amount?: record, proration_rounding?: record}
# --recurring_credits item shape: {name?: string, product_id: string, access_amount: record, description?: string, rollover_fraction?: float, priority: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, temporary_id?: string, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", starting_at: string, ending_before?: string, commit_duration: record, recurrence_frequency?: "MONTHLY"|"monthly"|"QUARTERLY"|"quarterly"|"ANNUAL"|"annual"|"WEEKLY"|"weekly", proration?: "NONE"|"none"|"FIRST"|"first"|"LAST"|"last"|"FIRST_AND_LAST"|"first_and_last", subscription_config?: record, hierarchy_configuration?: record, proration_rounding?: record}
# --overrides item shape: {starting_at: string, ending_before?: string, entitled?: bool, type?: "OVERWRITE"|"overwrite"|"MULTIPLIER"|"multiplier"|"TIERED"|"tiered", multiplier?: float, priority?: float, overwrite_rate?: record, product_id?: string, applicable_product_tags?: list, override_specifiers?: list, tiers?: list, is_commit_specific?: bool, target?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate"}
# --discounts item shape: {product_id: string, name?: string, schedule: record, netsuite_sales_order_id?: string, custom_fields?: record}
# --professional_services item shape: {description?: string, product_id: string, netsuite_sales_order_id?: string, unit_price: float, quantity: float, max_amount: float, custom_fields?: record}
# --reseller_royalties item shape: {reseller_type: "AWS"|"AWS_PRO_SERVICE"|"GCP"|"GCP_PRO_SERVICE", fraction: float, netsuite_reseller_id: string, applicable_product_ids?: list, applicable_product_tags?: list, starting_at: string, ending_before?: string, reseller_contract_value?: float, aws_options?: record, gcp_options?: record}
# --scheduled_charges item shape: {product_id: string, name?: string, schedule: record, netsuite_sales_order_id?: string, custom_fields?: record}
# --transition shape: {type: "SUPERSEDE"|"RENEWAL"|"supersede"|"renewal", from_contract_id: string, future_invoice_behavior?: record}
# --usage_filter shape: {group_key: string, group_values: list, starting_at?: string}
# --usage_statement_schedule shape: {frequency: "MONTHLY"|"monthly"|"QUARTERLY"|"quarterly"|"ANNUAL"|"annual"|"WEEKLY"|"weekly", day?: "FIRST_OF_MONTH"|"first_of_month"|"CONTRACT_START"|"contract_start"|"CUSTOM_DATE"|"custom_date", billing_anchor_date?: string, invoice_generation_starting_at?: string}
# --billing_provider_configuration shape: {billing_provider_configuration_id?: string, billing_provider?: "aws_marketplace"|"azure_marketplace"|"gcp_marketplace"|"stripe"|"netsuite", delivery_method?: "direct_to_billing_provider"|"aws_sqs"|"tackle"|"aws_sns"}
# --revenue_system_configuration shape: {revenue_system_configuration_id?: string, provider?: "netsuite", delivery_method?: "direct_to_billing_provider"}
# --spend_threshold_configuration shape: {is_enabled: bool, threshold_amount: float, commit: record, payment_gate_config: record, discount_configuration?: record}
# --prepaid_balance_threshold_configuration shape: {is_enabled: bool, threshold_amount: float, recharge_to_amount: float, custom_credit_type_id?: string, commit: record, payment_gate_config: record, discount_configuration?: record, threshold_balance_specifiers?: list}
# --spend_trackers item shape: {alias: string, credit_type_id: string, reset_frequency: "BILLING_PERIOD", applicable_spend_specifiers: list}
# --subscriptions item shape: {subscription_rate: record, name?: string, description?: string, collection_schedule: "ADVANCE"|"ARREARS"|"advance"|"arrears", proration: record, initial_quantity?: float, starting_at?: string, ending_before?: string, custom_fields?: record, temporary_id?: string, quantity_management_mode?: "SEAT_BASED"|"seat_based"|"QUANTITY_ONLY"|"quantity_only", seat_config?: record, billing_cycle_config?: record}
# --hierarchy_configuration shape: {parent?: record, payer?: "SELF"|"PARENT"|"self"|"parent", usage_statement_behavior?: "CONSOLIDATE"|"SEPARATE"|"consolidate"|"separate", parent_behavior?: record}
export def "contracts-create createContract-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  --package-id: string # If provided, provisions a customer on a package instead of creating a traditional contract. When specified, only customer_id, starting_at, package_id, uniqueness_key, transition, and custom_fields are allowed. (format: uuid)
  --package-alias: string # Selects the package linked to the specified alias as of the contract's start date. Mutually exclusive with package_id.
  --name: string
  --uniqueness-key: string # Prevents the creation of duplicates. If a request to create a record is made with a previously used uniqueness key, a new record will not be created and the request will fail with a 409 error.
  --netsuite-sales-order-id: string # This field's availability is dependent on your client's configuration.
  --salesforce-opportunity-id: string # This field's availability is dependent on your client's configuration.
  --net-payment-terms-days: float
  --rate-card-id: string # format: uuid
  --rate-card-alias: string # Selects the rate card linked to the specified alias as of the contract's start date.
  --total-contract-value: float # This field's availability is dependent on your client's configuration.
  starting_at: string # inclusive contract start time (format: date-time)
  --ending-before: string # exclusive contract end time (format: date-time)
  --commits: list # item shape: {type: "PREPAID"|"prepaid"|"POSTPAID"|"postpaid", rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", name?: string, product_id: string, access_schedule?: record, invoice_schedule?: record, amount?: float, description?: string, rollover_fraction?: float, priority?: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, custom_fields?: record, temporary_id?: string, hierarchy_configuration?: record, spend_tracker_attributes?: any}
  --credits: list # item shape: {name?: string, product_id: string, access_schedule: record, description?: string, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, priority?: float, custom_fields?: record, rollover_fraction?: float, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", hierarchy_configuration?: record}
  --recurring-commits: list # item shape: {name?: string, product_id: string, access_amount: record, description?: string, rollover_fraction?: float, priority: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, temporary_id?: string, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", starting_at: string, ending_before?: string, commit_duration: record, recurrence_frequency?: "MONTHLY"|"monthly"|"QUARTERLY"|"quarterly"|"ANNUAL"|"annual"|"WEEKLY"|"weekly", proration?: "NONE"|"none"|"FIRST"|"first"|"LAST"|"last"|"FIRST_AND_LAST"|"first_and_last", subscription_config?: record, hierarchy_configuration?: record, invoice_amount?: record, proration_rounding?: record}
  --recurring-credits: list # item shape: {name?: string, product_id: string, access_amount: record, description?: string, rollover_fraction?: float, priority: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, temporary_id?: string, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", starting_at: string, ending_before?: string, commit_duration: record, recurrence_frequency?: "MONTHLY"|"monthly"|"QUARTERLY"|"quarterly"|"ANNUAL"|"annual"|"WEEKLY"|"weekly", proration?: "NONE"|"none"|"FIRST"|"first"|"LAST"|"last"|"FIRST_AND_LAST"|"first_and_last", subscription_config?: record, hierarchy_configuration?: record, proration_rounding?: record}
  --multiplier-override-prioritization: string@multiplier-override-prioritization-completer # Defaults to LOWEST_MULTIPLIER, which applies the greatest discount to list prices automatically. EXPLICIT prioritization requires specifying priorities for each multiplier; the one with the lowest priority value will be prioritized first. If tiered overrides are used, prioritization must be explicit.
  --overrides: list # item shape: {starting_at: string, ending_before?: string, entitled?: bool, type?: "OVERWRITE"|"overwrite"|"MULTIPLIER"|"multiplier"|"TIERED"|"tiered", multiplier?: float, priority?: float, overwrite_rate?: record, product_id?: string, applicable_product_tags?: list, override_specifiers?: list, tiers?: list, is_commit_specific?: bool, target?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate"}
  --discounts: list # This field's availability is dependent on your client's configuration. — item shape: {product_id: string, name?: string, schedule: record, netsuite_sales_order_id?: string, custom_fields?: record}
  --professional-services: list # This field's availability is dependent on your client's configuration. — item shape: {description?: string, product_id: string, netsuite_sales_order_id?: string, unit_price: float, quantity: float, max_amount: float, custom_fields?: record}
  --reseller-royalties: list # This field's availability is dependent on your client's configuration. — item shape: {reseller_type: "AWS"|"AWS_PRO_SERVICE"|"GCP"|"GCP_PRO_SERVICE", fraction: float, netsuite_reseller_id: string, applicable_product_ids?: list, applicable_product_tags?: list, starting_at: string, ending_before?: string, reseller_contract_value?: float, aws_options?: record, gcp_options?: record}
  --scheduled-charges: list # item shape: {product_id: string, name?: string, schedule: record, netsuite_sales_order_id?: string, custom_fields?: record}
  --scheduled-charges-on-usage-invoices: string@scheduled-charges-on-usage-invoices-completer # Determines which scheduled and commit charges to consolidate onto the Contract's usage invoice. The charge's `timestamp` must match the usage invoice's `ending_before` date for consolidation to occur. This field cannot be modified after a Contract has been created. If this field is omitted, charges will appear on a separate invoice from usage charges.
  --transition: record # shape: {type: "SUPERSEDE"|"RENEWAL"|"supersede"|"renewal", from_contract_id: string, future_invoice_behavior?: record}
  --usage-filter: record # shape: {group_key: string, group_values: list, starting_at?: string}
  --usage-statement-schedule: record # shape: {frequency: "MONTHLY"|"monthly"|"QUARTERLY"|"quarterly"|"ANNUAL"|"annual"|"WEEKLY"|"weekly", day?: "FIRST_OF_MONTH"|"first_of_month"|"CONTRACT_START"|"contract_start"|"CUSTOM_DATE"|"custom_date", billing_anchor_date?: string, invoice_generation_starting_at?: string}
  --custom-fields: record # Custom fields to be added eg. { "key1": "value1", "key2": "value2" }
  --billing-provider-configuration: record # The billing provider configuration associated with a contract. Provide either an ID or the provider and delivery method. — shape: {billing_provider_configuration_id?: string, billing_provider?: "aws_marketplace"|"azure_marketplace"|"gcp_marketplace"|"stripe"|"netsuite", delivery_method?: "direct_to_billing_provider"|"aws_sqs"|"tackle"|"aws_sns"}
  --revenue-system-configuration: record # The revenue system configuration associated with a contract. Provide either an ID or the provider and delivery method. — shape: {revenue_system_configuration_id?: string, provider?: "netsuite", delivery_method?: "direct_to_billing_provider"}
  --spend-threshold-configuration: record # shape: {is_enabled: bool, threshold_amount: float, commit: record, payment_gate_config: record, discount_configuration?: record}
  --prepaid-balance-threshold-configuration: record # shape: {is_enabled: bool, threshold_amount: float, recharge_to_amount: float, custom_credit_type_id?: string, commit: record, payment_gate_config: record, discount_configuration?: record, threshold_balance_specifiers?: list}
  --spend-trackers: list # Spend trackers to attach to this contract. Aliases must be unique within a contract. — item shape: {alias: string, credit_type_id: string, reset_frequency: "BILLING_PERIOD", applicable_spend_specifiers: list}
  --subscriptions: list # Optional list of [subscriptions](https://docs.metronome.com/manage-product-access/create-subscription/) to add to the contract. — item shape: {subscription_rate: record, name?: string, description?: string, collection_schedule: "ADVANCE"|"ARREARS"|"advance"|"arrears", proration: record, initial_quantity?: float, starting_at?: string, ending_before?: string, custom_fields?: record, temporary_id?: string, quantity_management_mode?: "SEAT_BASED"|"seat_based"|"QUANTITY_ONLY"|"quantity_only", seat_config?: record, billing_cycle_config?: record}
  --hierarchy-configuration: record # shape: {parent?: record, payer?: "SELF"|"PARENT"|"self"|"parent", usage_statement_behavior?: "CONSOLIDATE"|"SEPARATE"|"consolidate"|"separate", parent_behavior?: record}
]: any -> record<data: record<id: string, contract: record<id: string, customer_id: string, created_at: string, created_by: string, name: string, package_id: string, uniqueness_key: string, rate_card_id: string, starting_at: string, ending_before: string, net_payment_terms_days: float, multiplier_override_prioritization: string, scheduled_charges_on_usage_invoices: string, custom_fields: record, usage_statement_schedule: record, usage_filter: list, commits: list, credits: list, has_more: record, recurring_commits: list, recurring_credits: list, overrides: list, scheduled_charges: list, transitions: list, subscriptions: list, customer_billing_provider_configuration: record, spend_threshold_configuration: record, prepaid_balance_threshold_configuration: record, hierarchy_configuration: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/create")
  let body = {customer_id: $customer_id, package_id: $package_id, package_alias: $package_alias, name: $name, uniqueness_key: $uniqueness_key, netsuite_sales_order_id: $netsuite_sales_order_id, salesforce_opportunity_id: $salesforce_opportunity_id, net_payment_terms_days: $net_payment_terms_days, rate_card_id: $rate_card_id, rate_card_alias: $rate_card_alias, total_contract_value: $total_contract_value, starting_at: $starting_at, ending_before: $ending_before, commits: $commits, credits: $credits, recurring_commits: $recurring_commits, recurring_credits: $recurring_credits, multiplier_override_prioritization: $multiplier_override_prioritization, overrides: $overrides, discounts: $discounts, professional_services: $professional_services, reseller_royalties: $reseller_royalties, scheduled_charges: $scheduled_charges, scheduled_charges_on_usage_invoices: $scheduled_charges_on_usage_invoices, transition: $transition, usage_filter: $usage_filter, usage_statement_schedule: $usage_statement_schedule, custom_fields: $custom_fields, billing_provider_configuration: $billing_provider_configuration, revenue_system_configuration: $revenue_system_configuration, spend_threshold_configuration: $spend_threshold_configuration, prepaid_balance_threshold_configuration: $prepaid_balance_threshold_configuration, spend_trackers: $spend_trackers, subscriptions: $subscriptions, hierarchy_configuration: $hierarchy_configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Amend a contract
#
# POST /v1/contracts/amend
# operationId: amendContract-v1
# --commits item shape: {type: "PREPAID"|"prepaid"|"POSTPAID"|"postpaid", rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", name?: string, product_id: string, access_schedule?: record, invoice_schedule?: record, amount?: float, description?: string, rollover_fraction?: float, priority?: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, custom_fields?: record, temporary_id?: string, hierarchy_configuration?: record, spend_tracker_attributes?: any}
# --credits item shape: {name?: string, product_id: string, access_schedule: record, description?: string, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, priority?: float, custom_fields?: record, rollover_fraction?: float, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", hierarchy_configuration?: record}
# --overrides item shape: {starting_at: string, ending_before?: string, entitled?: bool, type?: "OVERWRITE"|"overwrite"|"MULTIPLIER"|"multiplier"|"TIERED"|"tiered", multiplier?: float, priority?: float, overwrite_rate?: record, product_id?: string, applicable_product_tags?: list, override_specifiers?: list, tiers?: list, is_commit_specific?: bool, target?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate"}
# --discounts item shape: {product_id: string, name?: string, schedule: record, netsuite_sales_order_id?: string, custom_fields?: record}
# --professional_services item shape: {description?: string, product_id: string, netsuite_sales_order_id?: string, unit_price: float, quantity: float, max_amount: float, custom_fields?: record}
# --reseller_royalties item shape: {reseller_type: "AWS"|"AWS_PRO_SERVICE"|"GCP"|"GCP_PRO_SERVICE", fraction?: float, netsuite_reseller_id?: string, applicable_product_ids?: list, applicable_product_tags?: list, starting_at?: string, ending_before?: string, reseller_contract_value?: float, aws_options?: record, gcp_options?: record}
# --scheduled_charges item shape: {product_id: string, name?: string, schedule: record, netsuite_sales_order_id?: string, custom_fields?: record}
export def "contracts-amend amendContract-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # ID of the customer whose contract is to be amended (format: uuid)
  contract_id: string # ID of the contract to amend (format: uuid)
  --netsuite-sales-order-id: string # This field's availability is dependent on your client's configuration.
  --salesforce-opportunity-id: string # This field's availability is dependent on your client's configuration.
  --total-contract-value: float # This field's availability is dependent on your client's configuration.
  starting_at: string # inclusive start time for the amendment (format: date-time)
  --commits: list # item shape: {type: "PREPAID"|"prepaid"|"POSTPAID"|"postpaid", rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", name?: string, product_id: string, access_schedule?: record, invoice_schedule?: record, amount?: float, description?: string, rollover_fraction?: float, priority?: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, custom_fields?: record, temporary_id?: string, hierarchy_configuration?: record, spend_tracker_attributes?: any}
  --credits: list # item shape: {name?: string, product_id: string, access_schedule: record, description?: string, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, priority?: float, custom_fields?: record, rollover_fraction?: float, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", hierarchy_configuration?: record}
  --overrides: list # item shape: {starting_at: string, ending_before?: string, entitled?: bool, type?: "OVERWRITE"|"overwrite"|"MULTIPLIER"|"multiplier"|"TIERED"|"tiered", multiplier?: float, priority?: float, overwrite_rate?: record, product_id?: string, applicable_product_tags?: list, override_specifiers?: list, tiers?: list, is_commit_specific?: bool, target?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate"}
  --discounts: list # This field's availability is dependent on your client's configuration. — item shape: {product_id: string, name?: string, schedule: record, netsuite_sales_order_id?: string, custom_fields?: record}
  --professional-services: list # This field's availability is dependent on your client's configuration. — item shape: {description?: string, product_id: string, netsuite_sales_order_id?: string, unit_price: float, quantity: float, max_amount: float, custom_fields?: record}
  --reseller-royalties: list # This field's availability is dependent on your client's configuration. — item shape: {reseller_type: "AWS"|"AWS_PRO_SERVICE"|"GCP"|"GCP_PRO_SERVICE", fraction?: float, netsuite_reseller_id?: string, applicable_product_ids?: list, applicable_product_tags?: list, starting_at?: string, ending_before?: string, reseller_contract_value?: float, aws_options?: record, gcp_options?: record}
  --scheduled-charges: list # item shape: {product_id: string, name?: string, schedule: record, netsuite_sales_order_id?: string, custom_fields?: record}
  --custom-fields: record # Custom fields to be added eg. { "key1": "value1", "key2": "value2" }
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/amend")
  let body = {customer_id: $customer_id, contract_id: $contract_id, netsuite_sales_order_id: $netsuite_sales_order_id, salesforce_opportunity_id: $salesforce_opportunity_id, total_contract_value: $total_contract_value, starting_at: $starting_at, commits: $commits, credits: $credits, overrides: $overrides, discounts: $discounts, professional_services: $professional_services, reseller_royalties: $reseller_royalties, scheduled_charges: $scheduled_charges, custom_fields: $custom_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archive a contract
#
# POST /v1/contracts/archive
# operationId: archiveContract-v1
export def "contracts-archive archiveContract-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # ID of the customer whose contract is to be archived (format: uuid)
  contract_id: string # ID of the contract to archive (format: uuid)
  --void-invoices: oneof<nothing, bool> # If false, the existing finalized invoices will remain after the contract is archived.
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/archive")
  let body = {customer_id: $customer_id, contract_id: $contract_id, void_invoices: $void_invoices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set a contract usage filter
#
# POST /v1/contracts/setUsageFilter
# operationId: setUsageFilter-v1
export def "contracts-set-usage-filter setUsageFilter-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  contract_id: string # format: uuid
  group_key: string
  group_values: list
  starting_at: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/setUsageFilter")
  let body = {customer_id: $customer_id, contract_id: $contract_id, group_key: $group_key, group_values: $group_values, starting_at: $starting_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a manual balance entry
#
# POST /v1/contracts/addManualBalanceLedgerEntry
# operationId: addManualBalanceLedgerEntry-v1
export def "contracts-add-manual-balance-ledger-entry addManualBalanceLedgerEntry-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # ID of the customer whose balance is to be updated. (format: uuid)
  --contract-id: string # ID of the contract to update. Leave blank to update a customer level balance. (format: uuid)
  id: string # ID of the balance (commit or credit) to update. (format: uuid)
  segment_id: string # ID of the segment to update. (format: uuid)
  amount: float # Amount to add to the segment. A negative number will draw down from the balance.
  --per-group-amounts: record # If using individually configured commits/credits attached to seat managed subscriptions, the amount to add for each seat. Must sum to total amount.
  reason: string # Reason for the manual adjustment. This will be displayed in the ledger.
  --timestamp: string # RFC 3339 timestamp indicating when the manual adjustment takes place. If not provided, it will default to the start of the segment. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/addManualBalanceLedgerEntry")
  let body = {customer_id: $customer_id, contract_id: $contract_id, id: $id, segment_id: $segment_id, amount: $amount, per_group_amounts: $per_group_amounts, reason: $reason, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update invoice issue date
#
# POST /v1/contracts/updateInvoiceIssueDate
# operationId: updateInvoiceIssueDate-v1
export def "contracts-update-invoice-issue-date updateInvoiceIssueDate-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  invoice_id: string # ID of the invoice to update. The invoice must still be in DRAFT status. (format: uuid)
  issue_date: string # RFC 3339 timestamp. This will be the new issue date of the invoice. It must not be after the end date of the contract. (format: date-time)
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/updateInvoiceIssueDate")
  let body = {invoice_id: $invoice_id, issue_date: $issue_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the contract end date
#
# POST /v1/contracts/updateEndDate
# operationId: updateContractEndDate-v1
export def "contracts-update-end-date updateContractEndDate-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # ID of the customer whose contract is to be updated (format: uuid)
  contract_id: string # ID of the contract to update (format: uuid)
  --ending-before: string # RFC 3339 timestamp indicating when the contract will end (exclusive). If not provided, the contract will be updated to be open-ended. (format: date-time)
  --allow-ending-before-finalized-invoice: oneof<nothing, bool> # If true, allows setting the contract end date earlier than the end_timestamp of existing finalized invoices. Finalized invoices will be unchanged; if you want to incorporate the new end date, you can void and regenerate finalized usage invoices. Defaults to true.
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/updateEndDate")
  let body = {customer_id: $customer_id, contract_id: $contract_id, ending_before: $ending_before, allow_ending_before_finalized_invoice: $allow_ending_before_finalized_invoice} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the rate schedule for a contract
#
# POST /v1/contracts/getContractRateSchedule
# operationId: getContractRateSchedule-v1
# --selectors item shape: {billing_frequency?: "MONTHLY"|"Monthly"|"monthly"|"QUARTERLY"|"Quarterly"|"quarterly"|"ANNUAL"|"Annual"|"annual"|"WEEKLY"|"Weekly"|"weekly", product_id?: string, product_tags?: list, pricing_group_values?: record, partial_pricing_group_values?: record}
export def "contracts-get-contract-rate-schedule post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results that should be returned
  --next-page: string # Cursor that indicates where the next page of results should start.
  customer_id: string # ID of the customer for whose contract to get the rate schedule for. (format: uuid)
  contract_id: string # ID of the contract to get the rate schedule for. (format: uuid)
  --at: string # optional timestamp which overlaps with the returned rate schedule segments. When not specified, the current timestamp will be used. (format: date-time)
  --selectors: list # List of rate selectors, rates matching ANY of the selectors will be included in the response. Passing no selectors will result in all rates being returned. — item shape: {billing_frequency?: "MONTHLY"|"Monthly"|"monthly"|"QUARTERLY"|"Quarterly"|"quarterly"|"ANNUAL"|"Annual"|"annual"|"WEEKLY"|"Weekly"|"weekly", product_id?: string, product_tags?: list, pricing_group_values?: record, partial_pricing_group_values?: record}
]: any -> record<next_page: string, data: table<rate_card_id: string, product_id: string, product_name: string, product_tags: list, product_custom_fields: record, starting_at: string, ending_before: string, entitled: bool, pricing_group_values: record, list_rate: record, override_rate: record, commit_rate: record, billing_frequency: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "next_page" $next_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/contracts/getContractRateSchedule" $qp)
  let body = {customer_id: $customer_id, contract_id: $contract_id, at: $at, selectors: $selectors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get subscription quantity history
#
# POST /v1/contracts/getSubscriptionQuantityHistory
# operationId: getSubscriptionQuantityHistory-v1
export def "contracts-get-subscription-quantity-history post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  contract_id: string # format: uuid
  subscription_id: string # format: uuid
]: any -> record<data: record<subscription_id: string, fiat_credit_type_id: string, history: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/getSubscriptionQuantityHistory")
  let body = {customer_id: $customer_id, contract_id: $contract_id, subscription_id: $subscription_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get subscription seats history
#
# POST /v1/contracts/getSubscriptionSeatsHistory
# operationId: getSubscriptionSeatsHistory-v1
export def "contracts-get-subscription-seats-history post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  contract_id: string # format: uuid
  subscription_id: string # format: uuid
  --limit: int # Maximum number of seat schedule entries to return. Defaults to 10. Required range: 1 <= x <= 10. (nullable, default: 10)
  --cursor: string # Cursor for pagination. Use the value from the `next_page` field of the previous response to retrieve the next page of results. (nullable)
  --covering-date: string # Get the seats history segment for the covering date. Cannot be used with `starting_at` or `ending_before`. (nullable, format: date-time)
  --starting-at: string # Include seats history segments that are active at or after this timestamp. Use with `ending_before` to get a specific time range. If not set, there's no lower bound. (nullable, format: date-time)
  --ending-before: string # Include seats history segments that are active at or before this timestamp. Use with `starting_at` to get a specific time range. If not set, there's no upper bound. (nullable, format: date-time)
]: any -> record<data: table<starting_at: string, ending_before: string, total_quantity: int, assigned_seat_ids: list>, next_page: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/getSubscriptionSeatsHistory")
  let body = {customer_id: $customer_id, contract_id: $contract_id, subscription_id: $subscription_id, limit: $limit, cursor: $cursor, covering_date: $covering_date, starting_at: $starting_at, ending_before: $ending_before} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List commits
#
# POST /v1/contracts/customerCommits/list
# operationId: listCustomerCommits-v1
export def "contracts-customer-commits-list listCustomerCommits-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  --commit-id: string # format: uuid
  --covering-date: string # Include only commits that have access schedules that "cover" the provided date (format: date-time)
  --starting-at: string # Include only commits that have any access on or after the provided date (format: date-time)
  --effective-before: string # Include only commits that have any access before the provided date (exclusive) (format: date-time)
  --include-contract-commits: oneof<nothing, bool> # Include commits on the contract level.
  --include-archived: oneof<nothing, bool> # Include archived commits and commits from archived contracts.
  --include-ledgers: oneof<nothing, bool> # Include commit ledgers in the response. Setting this flag may cause the query to be slower.
  --include-balance: oneof<nothing, bool> # Include the balance in the response. Setting this flag may cause the query to be slower.
  --next-page: string # The next page token from a previous response.
  --limit: int # The maximum number of commits to return. Defaults to 25. (default: 25)
]: any -> record<data: table<id: string, contract: record, type: string, rate_type: string, name: string, priority: float, product: record, access_schedule: record, invoice_schedule: record, invoice_contract: record, recurring_commit_id: string, subscription_config: record, rolled_over_from: record, description: string, rollover_fraction: float, applicable_product_ids: list, applicable_product_tags: list, specifiers: list, applicable_contract_ids: list, netsuite_sales_order_id: string, amount: float, salesforce_opportunity_id: string, ledger: list, balance: float, custom_fields: record, uniqueness_key: string, archived_at: string, hierarchy_configuration: record, spend_tracker_attributes: record, created_at: string>, next_page: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/customerCommits/list")
  let body = {customer_id: $customer_id, commit_id: $commit_id, covering_date: $covering_date, starting_at: $starting_at, effective_before: $effective_before, include_contract_commits: $include_contract_commits, include_archived: $include_archived, include_ledgers: $include_ledgers, include_balance: $include_balance, next_page: $next_page, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a commit
#
# POST /v1/contracts/customerCommits/create
# operationId: createCustomerCommit-v1
# --access_schedule shape: {credit_type_id?: string, schedule_items: list}
# --invoice_schedule shape: {credit_type_id?: string, schedule_items?: list, recurring_schedule?: record, do_not_invoice?: bool}
# --specifiers item shape: {product_id?: string, product_tags?: list, pricing_group_values?: record, presentation_group_values?: record, exclude?: list}
export def "contracts-customer-commits-create createCustomerCommit-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  type: string@type-completer-2
  --rate-type: string@rate-type-completer-1
  --name: string # displayed on invoices
  --description: string # Used only in UI/API. It is not exposed to end customers.
  priority: float # If multiple credits or commits are applicable, the one with the lower priority will apply first.
  product_id: string # ID of the fixed product associated with the commit. This is required because products are used to invoice the commit amount. (format: uuid)
  access_schedule: record # shape: {credit_type_id?: string, schedule_items: list}
  --invoice-schedule: record # Must provide either schedule_items or recurring_schedule. — shape: {credit_type_id?: string, schedule_items?: list, recurring_schedule?: record, do_not_invoice?: bool}
  --invoice-contract-id: string # The contract that this commit will be billed on. This is required for "POSTPAID" commits and for "PREPAID" commits unless there is no invoice schedule above (i.e., the commit is 'free'), or if do_not_invoice is set to true. (format: uuid)
  --applicable-product-ids: list # Which products the commit applies to. If applicable_product_ids, applicable_product_tags or specifiers are not provided, the commit applies to all products.
  --applicable-product-tags: list # Which tags the commit applies to. If applicable_product_ids, applicable_product_tags or specifiers are not provided, the commit applies to all products.
  --applicable-contract-ids: list # Which contract the commit applies to. If not provided, the commit applies to all contracts.
  --specifiers: list # List of filters that determine what kind of customer usage draws down a commit or credit. A customer's usage needs to meet the condition of at least one of the specifiers to contribute to a commit's or credit's drawdown. This field cannot be used together with `applicable_product_ids` or `applicable_product_tags`. — item shape: {product_id?: string, product_tags?: list, pricing_group_values?: record, presentation_group_values?: record, exclude?: list}
  --netsuite-sales-order-id: string # This field's availability is dependent on your client's configuration.
  --salesforce-opportunity-id: string # This field's availability is dependent on your client's configuration.
  --custom-fields: record # Custom fields to be added eg. { "key1": "value1", "key2": "value2" }
  --uniqueness-key: string # Prevents the creation of duplicates. If a request to create a commit or credit is made with a uniqueness key that was previously used to create a commit or credit, a new record will not be created and the request will fail with a 409 error.
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/customerCommits/create")
  let body = {customer_id: $customer_id, type: $type, rate_type: $rate_type, name: $name, description: $description, priority: $priority, product_id: $product_id, access_schedule: $access_schedule, invoice_schedule: $invoice_schedule, invoice_contract_id: $invoice_contract_id, applicable_product_ids: $applicable_product_ids, applicable_product_tags: $applicable_product_tags, applicable_contract_ids: $applicable_contract_ids, specifiers: $specifiers, netsuite_sales_order_id: $netsuite_sales_order_id, salesforce_opportunity_id: $salesforce_opportunity_id, custom_fields: $custom_fields, uniqueness_key: $uniqueness_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the commit end date
#
# POST /v1/contracts/customerCommits/updateEndDate
# operationId: updateCommitEndDate-v1
export def "contracts-customer-commits-update-end-date updateCommitEndDate-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # ID of the customer whose commit is to be updated (format: uuid)
  commit_id: string # ID of the commit to update. Only supports "PREPAID" commits. (format: uuid)
  --access-ending-before: string # RFC 3339 timestamp indicating when access to the commit will end and it will no longer be possible to draw it down (exclusive). If not provided, the access will not be updated. (format: date-time)
  --invoices-ending-before: string # RFC 3339 timestamp indicating when the commit will stop being invoiced (exclusive). If not provided, the invoice schedule will not be updated. (format: date-time)
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/customerCommits/updateEndDate")
  let body = {customer_id: $customer_id, commit_id: $commit_id, access_ending_before: $access_ending_before, invoices_ending_before: $invoices_ending_before} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Release external payment gate threshold commit
#
# POST /v1/contracts/commits/threshold-billing/release
# operationId: releaseExternalPaymentGateThresholdCommit-v1
export def "contracts-commits-threshold-billing-release releaseExternalPaymentGateThresholdCommit-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  workflow_id: string # ID of the workflow to continue (format: uuid)
  outcome: string@outcome-completer # The outcome of the external payment gate
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/commits/threshold-billing/release")
  let body = {workflow_id: $workflow_id, outcome: $outcome} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable trueup for commit
#
# POST /v1/contracts/commits/disableTrueup
# operationId: disableCommitTrueup-v1
export def "contracts-commits-disable-trueup disableCommitTrueup-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # ID of the customer whose commit is to be updated (format: uuid)
  commit_id: string # ID of the commit to update (format: uuid)
  contract_id: string # ID of the contract that the commit is on (format: uuid)
  --amendment-id: string # If applicable, the amendment ID that the commit is on (format: uuid)
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/commits/disableTrueup")
  let body = {customer_id: $customer_id, commit_id: $commit_id, contract_id: $contract_id, amendment_id: $amendment_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List credits
#
# POST /v1/contracts/customerCredits/list
# operationId: listCustomerCredits-v1
export def "contracts-customer-credits-list listCustomerCredits-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  --credit-id: string # format: uuid
  --covering-date: string # Return only credits that have access schedules that "cover" the provided date (format: date-time)
  --starting-at: string # Include only credits that have any access on or after the provided date (format: date-time)
  --effective-before: string # Include only credits that have any access before the provided date (exclusive) (format: date-time)
  --include-contract-credits: oneof<nothing, bool> # Include credits on the contract level.
  --include-archived: oneof<nothing, bool> # Include archived credits and credits from archived contracts.
  --include-ledgers: oneof<nothing, bool> # Include credit ledgers in the response. Setting this flag may cause the query to be slower.
  --include-balance: oneof<nothing, bool> # Include the balance in the response. Setting this flag may cause the query to be slower.
  --next-page: string # The next page token from a previous response.
  --limit: int # The maximum number of commits to return. Defaults to 25. (default: 25)
]: any -> record<data: table<id: string, contract: record, type: string, name: string, priority: float, product: record, access_schedule: record, description: string, recurring_credit_id: string, subscription_config: record, applicable_product_ids: list, applicable_product_tags: list, specifiers: list, applicable_contract_ids: list, netsuite_sales_order_id: string, salesforce_opportunity_id: string, ledger: list, balance: float, custom_fields: record, rate_type: string, uniqueness_key: string, hierarchy_configuration: record, rolled_over_from: record>, next_page: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/customerCredits/list")
  let body = {customer_id: $customer_id, credit_id: $credit_id, covering_date: $covering_date, starting_at: $starting_at, effective_before: $effective_before, include_contract_credits: $include_contract_credits, include_archived: $include_archived, include_ledgers: $include_ledgers, include_balance: $include_balance, next_page: $next_page, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a credit
#
# POST /v1/contracts/customerCredits/create
# operationId: createCustomerCredit-v1
# --access_schedule shape: {credit_type_id?: string, schedule_items: list}
# --specifiers item shape: {product_id?: string, product_tags?: list, pricing_group_values?: record, presentation_group_values?: record, exclude?: list}
export def "contracts-customer-credits-create createCustomerCredit-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  --name: string # displayed on invoices
  --description: string # Used only in UI/API. It is not exposed to end customers.
  priority: float # If multiple credits or commits are applicable, the one with the lower priority will apply first.
  product_id: string # format: uuid
  access_schedule: record # shape: {credit_type_id?: string, schedule_items: list}
  --applicable-product-ids: list # Which products the credit applies to. If both applicable_product_ids and applicable_product_tags are not provided, the credit applies to all products.
  --applicable-product-tags: list # Which tags the credit applies to. If both applicable_product_ids and applicable_product_tags are not provided, the credit applies to all products.
  --specifiers: list # List of filters that determine what kind of customer usage draws down a commit or credit. A customer's usage needs to meet the condition of at least one of the specifiers to contribute to a commit's or credit's drawdown. This field cannot be used together with `applicable_product_ids` or `applicable_product_tags`. — item shape: {product_id?: string, product_tags?: list, pricing_group_values?: record, presentation_group_values?: record, exclude?: list}
  --applicable-contract-ids: list # Which contract the credit applies to. If not provided, the credit applies to all contracts.
  --netsuite-sales-order-id: string # This field's availability is dependent on your client's configuration.
  --salesforce-opportunity-id: string # This field's availability is dependent on your client's configuration.
  --custom-fields: record # Custom fields to be added eg. { "key1": "value1", "key2": "value2" }
  --rate-type: string@rate-type-completer-1
  --uniqueness-key: string # Prevents the creation of duplicates. If a request to create a commit or credit is made with a uniqueness key that was previously used to create a commit or credit, a new record will not be created and the request will fail with a 409 error.
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/customerCredits/create")
  let body = {customer_id: $customer_id, name: $name, description: $description, priority: $priority, product_id: $product_id, access_schedule: $access_schedule, applicable_product_ids: $applicable_product_ids, applicable_product_tags: $applicable_product_tags, specifiers: $specifiers, applicable_contract_ids: $applicable_contract_ids, netsuite_sales_order_id: $netsuite_sales_order_id, salesforce_opportunity_id: $salesforce_opportunity_id, custom_fields: $custom_fields, rate_type: $rate_type, uniqueness_key: $uniqueness_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the credit end date
#
# POST /v1/contracts/customerCredits/updateEndDate
# operationId: updateCreditEndDate-v1
export def "contracts-customer-credits-update-end-date updateCreditEndDate-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # ID of the customer whose credit is to be updated (format: uuid)
  credit_id: string # ID of the commit to update (format: uuid)
  access_ending_before: string # RFC 3339 timestamp indicating when access to the credit will end and it will no longer be possible to draw it down (exclusive). (format: date-time)
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/customerCredits/updateEndDate")
  let body = {customer_id: $customer_id, credit_id: $credit_id, access_ending_before: $access_ending_before} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List balances
#
# POST /v1/contracts/customerBalances/list
# operationId: listCustomerBalances-v1
export def "contracts-customer-balances-list listCustomerBalances-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  --id: string # format: uuid
  --covering-date: string # Return only balances that have access schedules that "cover" the provided date (format: date-time)
  --starting-at: string # Include only balances that have any access on or after the provided date (format: date-time)
  --effective-before: string # Include only balances that have any access before the provided date (exclusive) (format: date-time)
  --include-contract-balances: oneof<nothing, bool> # Include balances on the contract level.
  --include-archived: oneof<nothing, bool> # Include archived credits and credits from archived contracts.
  --include-ledgers: oneof<nothing, bool> # Include ledgers in the response. Setting this flag may cause the query to be slower.
  --include-balance: oneof<nothing, bool> # Include the balance of credits and commits in the response. Setting this flag may cause the query to be slower.
  --next-page: string # The next page token from a previous response.
  --limit: int # The maximum number of commits to return. Defaults to 25. (default: 25)
  --exclude-zero-balances: oneof<nothing, bool> # Exclude balances with zero amounts from the response.
  --webhook-notification-id: string # Indicates that this API request was triggered by a webhook notification with the provided ID.
]: any -> record<data: list<any>, next_page: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/customerBalances/list")
  let body = {customer_id: $customer_id, id: $id, covering_date: $covering_date, starting_at: $starting_at, effective_before: $effective_before, include_contract_balances: $include_contract_balances, include_archived: $include_archived, include_ledgers: $include_ledgers, include_balance: $include_balance, next_page: $next_page, limit: $limit, exclude_zero_balances: $exclude_zero_balances, webhook_notification_id: $webhook_notification_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the net balance of a customer
#
# POST /v1/contracts/customerBalances/getNetBalance
# operationId: getNetBalance-v1
# --filters item shape: {balance_types?: list, ids?: list, custom_fields?: record}
export def "contracts-customer-balances-get-net-balance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # The ID of the customer. (format: uuid)
  --credit-type-id: string # The ID of the credit type (can be fiat or a custom pricing unit) to get the balance for. Defaults to USD (cents) if not specified. (format: uuid)
  --filters: list # Balance filters are OR'd together, so if a given commit or credit matches any of the filters, it will be included in the net balance. — item shape: {balance_types?: list, ids?: list, custom_fields?: record}
  --invoice-inclusion-mode: string@invoice-inclusion-mode-completer # Controls which invoices are considered when calculating the remaining balance. `FINALIZED` considers only deductions from finalized invoices. `FINALIZED_AND_DRAFT` also includes deductions from pending draft invoices. (default: FINALIZED_AND_DRAFT)
]: any -> record<data: record<balance: float, credit_type_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/customerBalances/getNetBalance")
  let body = {customer_id: $customer_id, credit_type_id: $credit_type_id, filters: $filters, invoice_inclusion_mode: $invoice_inclusion_mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List seat balances
#
# POST /v1/contracts/seatBalances/list
# operationId: listSeatBalances-v1
export def "contracts-seat-balances-list listSeatBalances-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # The customer ID to retrieve seat balances for (format: uuid)
  contract_id: string # The contract ID to retrieve seat balances for (format: uuid)
  --subscription-ids: list # Optional filter to only include seats from specific subscriptions. If subscriptions ids are not mapped to SEAT_BASED subscriptions, error will be returned.
  --seat-ids: list # Optional filter to only include specific seats.
  --skip-missing-seat-ids: oneof<nothing, bool> # When true, any seat_ids not found in contract subscriptions will be silently omitted from the response instead of returning a 400 error. (default: false)
  --include-credits-and-commits: oneof<nothing, bool> # Include credits and commits in the response (default: false)
  --include-ledgers: oneof<nothing, bool> # Include ledger entries for each commit and commit. `include_credits_and_commits` must be set to `true` for `include_ledgers=true` to apply. (default: false)
  --starting-at: string # Include only commits or credits with access effective on or after this date (cannot be used with covering_date). (format: date-time)
  --effective-before: string # Include only commits or credits with access effective on or before this date (cannot be used with covering_date). (format: date-time)
  --covering-date: string # Include only commits or credits with access that cover this specific date (cannot be used with starting_at or ending_before). (format: date-time)
  --limit: int # Maximum number of seats to return. Range: 1-100. Default: 25. When `include_credits_and_commits = true`, if the total commits/credits across all seats exceeds 100, a limit of 100 applies to the total credits and commits. Seats are included greedily to maximize the number of seats returned. Example: if seat 1 has 98 commits and seat 2 has 10 commits, both seats will be returned (total: 108 commits). Each returned seat includes all of its associated credits and commits.
  --cursor: string # Page token from a previous response to retrieve the next page
]: any -> record<data: table<seat_id: string, balances: list, commits: list, credits: list>, pagination: record<seats_included: float, seats_available_for_next_page: float, next_page: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/seatBalances/list")
  let body = {customer_id: $customer_id, contract_id: $contract_id, subscription_ids: $subscription_ids, seat_ids: $seat_ids, skip_missing_seat_ids: $skip_missing_seat_ids, include_credits_and_commits: $include_credits_and_commits, include_ledgers: $include_ledgers, starting_at: $starting_at, effective_before: $effective_before, covering_date: $covering_date, limit: $limit, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Schedule ProService invoice
#
# POST /v1/contracts/scheduleProServicesInvoice
# operationId: scheduleProServicesInvoice-v1
# --line_items item shape: {professional_service_id: string, amendment_id?: string, unit_price?: float, quantity?: float, amount?: float, netsuite_invoice_billing_start?: string, netsuite_invoice_billing_end?: string, metadata?: string}
export def "contracts-schedule-pro-services-invoice scheduleProServicesInvoice-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  contract_id: string # format: uuid
  issued_at: string # The date the invoice is issued (format: date-time)
  --netsuite-invoice-header-start: string # The start date of the invoice header in Netsuite (format: date-time)
  --netsuite-invoice-header-end: string # The end date of the invoice header in Netsuite (format: date-time)
  line_items: list # Each line requires an amount or both unit_price and quantity. — item shape: {professional_service_id: string, amendment_id?: string, unit_price?: float, quantity?: float, amount?: float, netsuite_invoice_billing_start?: string, netsuite_invoice_billing_end?: string, metadata?: string}
]: any -> record<data: table<id: string, customer_id: string, customer_custom_fields: record, netsuite_sales_order_id: string, salesforce_opportunity_id: string, net_payment_terms_days: float, credit_type: record, line_items: list, start_timestamp: string, end_timestamp: string, issued_at: string, created_at: string, status: string, total: float, type: string, external_invoice: record, revenue_system_invoices: list, contract_id: string, contract_custom_fields: record, amendment_id: string, correction_record: record, reseller_royalty: record, custom_fields: record, billable_status: string, constituent_invoices: list, payer: record, regenerated_from_invoice_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/scheduleProServicesInvoice")
  let body = {customer_id: $customer_id, contract_id: $contract_id, issued_at: $issued_at, netsuite_invoice_header_start: $netsuite_invoice_header_start, netsuite_invoice_header_end: $netsuite_invoice_header_end, line_items: $line_items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create historical invoices
#
# POST /v1/contracts/createHistoricalInvoices
# operationId: createHistoricalContractUsageInvoices-v1
# --invoices item shape: {customer_id: string, contract_id: string, credit_type_id: string, inclusive_start_date: string, exclusive_end_date: string, issue_date: string, breakdown_granularity?: "hour"|"day"|"HOUR"|"DAY"|"Hour"|"Day", usage_line_items: list, billable_status?: "billable"|"unbillable", custom_fields?: record}
export def "contracts-create-historical-invoices createHistoricalContractUsageInvoices-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  invoices: list # item shape: {customer_id: string, contract_id: string, credit_type_id: string, inclusive_start_date: string, exclusive_end_date: string, issue_date: string, breakdown_granularity?: "hour"|"day"|"HOUR"|"DAY"|"Hour"|"Day", usage_line_items: list, billable_status?: "billable"|"unbillable", custom_fields?: record}
  --preview: oneof<nothing, bool>
]: any -> record<data: table<id: string, customer_id: string, customer_custom_fields: record, netsuite_sales_order_id: string, salesforce_opportunity_id: string, net_payment_terms_days: float, credit_type: record, line_items: list, start_timestamp: string, end_timestamp: string, issued_at: string, created_at: string, status: string, total: float, type: string, external_invoice: record, revenue_system_invoices: list, contract_id: string, contract_custom_fields: record, amendment_id: string, correction_record: record, reseller_royalty: record, custom_fields: record, billable_status: string, constituent_invoices: list, payer: record, regenerated_from_invoice_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/createHistoricalInvoices")
  let body = {invoices: $invoices, preview: $preview} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a customer and provision a contract.
#
# POST /v1/composite/createCustomerWithContract
# operationId: createCustomerWithContract-v1
# --customer shape: {ingest_aliases?: list, name: string, customer_billing_provider_configurations?: list, customer_revenue_system_configurations?: list, custom_fields?: record}
# --contract shape: {name?: string, uniqueness_key?: string, netsuite_sales_order_id?: string, salesforce_opportunity_id?: string, net_payment_terms_days?: float, rate_card_id?: string, rate_card_alias?: string, total_contract_value?: float, starting_at: string, ending_before?: string, commits?: list, credits?: list, recurring_commits?: list, recurring_credits?: list, multiplier_override_prioritization?: "LOWEST_MULTIPLIER"|"lowest_multiplier"|"EXPLICIT"|"explicit", overrides?: list, discounts?: list, reseller_royalties?: list, professional_services?: list, scheduled_charges?: list, scheduled_charges_on_usage_invoices?: "ALL", usage_filter?: record, usage_statement_schedule?: record, custom_fields?: record, billing_provider_configuration?: record, revenue_system_configuration?: record, spend_threshold_configuration?: record, prepaid_balance_threshold_configuration?: record, spend_trackers?: list, subscriptions?: list, hierarchy_configuration?: record}
export def "composite-create-customer-with-contract createCustomerWithContract-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer: record # shape: {ingest_aliases?: list, name: string, customer_billing_provider_configurations?: list, customer_revenue_system_configurations?: list, custom_fields?: record}
  contract: record # shape: {name?: string, uniqueness_key?: string, netsuite_sales_order_id?: string, salesforce_opportunity_id?: string, net_payment_terms_days?: float, rate_card_id?: string, rate_card_alias?: string, total_contract_value?: float, starting_at: string, ending_before?: string, commits?: list, credits?: list, recurring_commits?: list, recurring_credits?: list, multiplier_override_prioritization?: "LOWEST_MULTIPLIER"|"lowest_multiplier"|"EXPLICIT"|"explicit", overrides?: list, discounts?: list, reseller_royalties?: list, professional_services?: list, scheduled_charges?: list, scheduled_charges_on_usage_invoices?: "ALL", usage_filter?: record, usage_statement_schedule?: record, custom_fields?: record, billing_provider_configuration?: record, revenue_system_configuration?: record, spend_threshold_configuration?: record, prepaid_balance_threshold_configuration?: record, spend_trackers?: list, subscriptions?: list, hierarchy_configuration?: record}
]: any -> record<data: record<customer_id: string, ingest_aliases: list<string>, customer_name: string, custom_fields: record, contract_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/composite/createCustomerWithContract")
  let body = {customer: $customer, contract: $contract} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a customer's named schedule
#
# POST /v1/customers/getNamedSchedule
# operationId: getCustomerNamedSchedule-v1
export def "customers-get-named-schedule post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # ID of the customer whose named schedule is to be retrieved (format: uuid)
  schedule_name: string # The identifier for the schedule to be retrieved
  --covering-date: string # If provided, at most one schedule segment will be returned (the one that covers this date). If not provided, all segments will be returned. (format: date-time)
]: any -> record<data: table<value: any, starting_at: string, ending_before: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customers/getNamedSchedule")
  let body = {customer_id: $customer_id, schedule_name: $schedule_name, covering_date: $covering_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a customer's named schedule
#
# POST /v1/customers/updateNamedSchedule
# operationId: updateCustomerNamedSchedule-v1
export def "customers-update-named-schedule updateCustomerNamedSchedule-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # ID of the customer whose named schedule is to be updated (format: uuid)
  schedule_name: string # The identifier for the schedule to be updated
  starting_at: string # format: date-time
  --ending-before: string # format: date-time
  value: any # The value to set for the named schedule. The structure of this object is specific to the named schedule.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customers/updateNamedSchedule")
  let body = {customer_id: $customer_id, schedule_name: $schedule_name, starting_at: $starting_at, ending_before: $ending_before, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a contract's named schedule
#
# POST /v1/contracts/getNamedSchedule
# operationId: getContractNamedSchedule-v1
export def "contracts-get-named-schedule post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # ID of the customer whose named schedule is to be retrieved (format: uuid)
  contract_id: string # ID of the contract whose named schedule is to be retrieved (format: uuid)
  schedule_name: string # The identifier for the schedule to be retrieved
  --covering-date: string # If provided, at most one schedule segment will be returned (the one that covers this date). If not provided, all segments will be returned. (format: date-time)
  --properties: record # A set of key-value pairs that qualifies which schedule should be applied when looking up a schedule by name.
]: any -> record<data: table<value: any, starting_at: string, ending_before: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/getNamedSchedule")
  let body = {customer_id: $customer_id, contract_id: $contract_id, schedule_name: $schedule_name, covering_date: $covering_date, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List contract named schedules
#
# POST /v1/contracts/listNamedSchedules
# operationId: listContractsNamedSchedules-v1
export def "contracts-list-named-schedules listContractsNamedSchedules-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # ID of the customer to list contract named schedules for (format: uuid)
  --contract-id: string # Optional ID of a contract to scope the results to a single contract (format: uuid)
  --schedule-name: string # Optional filter to scope the results to a single schedule name
  --properties: record # Optional key-value filters. A schedule matches when it contains at least this subset of properties.
  --covering-date: string # If provided, result contains at most one segment covering this date for each schedule. (format: date-time)
  --limit: int # Maximum number of named schedules to return.
  --next-page: string # Cursor for pagination. Use the value from a previous response's next_page.
]: any -> record<data: table<contract_id: string, schedule_name: string, properties: record, segments: list>, next_page: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/listNamedSchedules")
  let body = {customer_id: $customer_id, contract_id: $contract_id, schedule_name: $schedule_name, properties: $properties, covering_date: $covering_date, limit: $limit, next_page: $next_page} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a contract's named schedule
#
# POST /v1/contracts/updateNamedSchedule
# operationId: updateContractNamedSchedule-v1
export def "contracts-update-named-schedule updateContractNamedSchedule-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # ID of the customer whose named schedule is to be updated (format: uuid)
  contract_id: string # ID of the contract whose named schedule is to be updated (format: uuid)
  schedule_name: string # The identifier for the schedule to be updated
  starting_at: string # format: date-time
  --ending-before: string # format: date-time
  value: any # The value to set for the named schedule. The structure of this object is specific to the named schedule.
  --properties: record # A set of key-value pairs that qualifies which schedule should be applied when looking up a schedule by name.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contracts/updateNamedSchedule")
  let body = {customer_id: $customer_id, contract_id: $contract_id, schedule_name: $schedule_name, starting_at: $starting_at, ending_before: $ending_before, value: $value, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a rate card's named schedule
#
# POST /v1/contract-pricing/rate-cards/getNamedSchedule
# operationId: getRateCardNamedSchedule-v1
export def "contract-pricing-rate-cards-get-named-schedule post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  rate_card_id: string # ID of the rate card whose named schedule is to be retrieved (format: uuid)
  schedule_name: string # The identifier for the schedule to be retrieved
  --covering-date: string # If provided, at most one schedule segment will be returned (the one that covers this date). If not provided, all segments will be returned. (format: date-time)
]: any -> record<data: table<value: any, starting_at: string, ending_before: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contract-pricing/rate-cards/getNamedSchedule")
  let body = {rate_card_id: $rate_card_id, schedule_name: $schedule_name, covering_date: $covering_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a rate card's named schedule
#
# POST /v1/contract-pricing/rate-cards/updateNamedSchedule
# operationId: updateRateCardNamedSchedule-v1
export def "contract-pricing-rate-cards-update-named-schedule updateRateCardNamedSchedule-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  rate_card_id: string # ID of the rate card whose named schedule is to be updated (format: uuid)
  schedule_name: string # The identifier for the schedule to be updated
  starting_at: string # format: date-time
  --ending-before: string # format: date-time
  value: any # The value to set for the named schedule. The structure of this object is specific to the named schedule.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contract-pricing/rate-cards/updateNamedSchedule")
  let body = {rate_card_id: $rate_card_id, schedule_name: $schedule_name, starting_at: $starting_at, ending_before: $ending_before, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a customer's active recharge or prepaid balance threshold config
#
# POST /v1/threshold-billing/update-active-recharge-config
# operationId: updateActiveRechargeConfig-v1
export def "threshold-billing-update-active-recharge-config updateActiveRechargeConfig-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  --recharge-to-amount: float # the amount to recharge to
  --recharge-threshold: float # the threshold at which to recharge
  --enabled: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/threshold-billing/update-active-recharge-config")
  let body = {customer_id: $customer_id, recharge_to_amount: $recharge_to_amount, recharge_threshold: $recharge_threshold, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a package
#
# POST /v1/packages/create
# operationId: createPackage-v1
# --aliases item shape: {name: string, starting_at?: string, ending_before?: string}
# --duration shape: {value: int, unit: "DAYS"|"WEEKS"|"MONTHS"|"YEARS"}
# --commits item shape: {type: "PREPAID"|"prepaid"|"POSTPAID"|"postpaid", rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", name?: string, product_id: string, access_schedule: record, invoice_schedule?: any, description?: string, rollover_fraction?: float, priority?: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, temporary_id?: string, custom_fields?: record}
# --credits item shape: {name?: string, product_id: string, access_schedule: record, description?: string, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, priority?: float, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", custom_fields?: record}
# --recurring_commits item shape: {name?: string, product_id: string, access_amount: record, description?: string, rollover_fraction?: float, priority: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, temporary_id?: string, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", starting_at_offset: record, duration?: record, commit_duration: record, recurrence_frequency?: "MONTHLY"|"monthly"|"QUARTERLY"|"quarterly"|"ANNUAL"|"annual"|"WEEKLY"|"weekly", proration?: "NONE"|"none"|"FIRST"|"first"|"LAST"|"last"|"FIRST_AND_LAST"|"first_and_last", subscription_config?: record, invoice_amount?: record, proration_rounding?: record}
# --recurring_credits item shape: {name?: string, product_id: string, access_amount: record, description?: string, rollover_fraction?: float, priority: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, temporary_id?: string, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", starting_at_offset: record, duration?: record, commit_duration: record, recurrence_frequency?: "MONTHLY"|"monthly"|"QUARTERLY"|"quarterly"|"ANNUAL"|"annual"|"WEEKLY"|"weekly", proration?: "NONE"|"none"|"FIRST"|"first"|"LAST"|"last"|"FIRST_AND_LAST"|"first_and_last", subscription_config?: record, proration_rounding?: record}
# --overrides item shape: {starting_at_offset: record, duration?: record, entitled?: bool, type?: "OVERWRITE"|"overwrite"|"MULTIPLIER"|"multiplier"|"TIERED"|"tiered", multiplier?: float, priority?: float, overwrite_rate?: record, override_specifiers: list, tiers?: list, is_commit_specific?: bool, target?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate"}
# --scheduled_charges item shape: {product_id: string, name?: string, schedule: record, custom_fields?: record}
# --usage_statement_schedule shape: {frequency: "MONTHLY"|"monthly"|"QUARTERLY"|"quarterly"|"ANNUAL"|"annual"|"WEEKLY"|"weekly", day?: "FIRST_OF_MONTH"|"first_of_month"|"CONTRACT_START"|"contract_start", invoice_generation_starting_at_offset?: record}
# --spend_threshold_configuration shape: {is_enabled: bool, threshold_amount: float, commit: record, payment_gate_config: record, discount_configuration?: record}
# --prepaid_balance_threshold_configuration shape: {is_enabled: bool, threshold_amount: float, recharge_to_amount: float, custom_credit_type_id?: string, commit: record, payment_gate_config: record, discount_configuration?: record, threshold_balance_specifiers?: list}
# --spend_trackers item shape: {alias: string, credit_type_id: string, reset_frequency: "BILLING_PERIOD", applicable_spend_specifiers: list}
# --subscriptions item shape: {subscription_rate: record, name?: string, description?: string, collection_schedule: "ADVANCE"|"ARREARS"|"advance"|"arrears", proration: record, initial_quantity?: float, starting_at_offset?: record, duration?: record, temporary_id?: string, quantity_management_mode?: "SEAT_BASED"|"seat_based"|"QUANTITY_ONLY"|"quantity_only", seat_config?: record, custom_fields?: record, billing_cycle_config?: record}
export def "packages-create createPackage-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --contract-name: string
  --uniqueness-key: string # Prevents the creation of duplicates. If a request to create a record is made with a previously used uniqueness key, a new record will not be created and the request will fail with a 409 error.
  --net-payment-terms-days: float
  --rate-card-id: string # format: uuid
  --rate-card-alias: string # Selects the rate card linked to the specified alias as of the contract's start date.
  --aliases: list # Reference this alias when creating a contract. If the same alias is assigned to multiple packages, it will reference the package to which it was most recently assigned. It is not exposed to end customers. — item shape: {name: string, starting_at?: string, ending_before?: string}
  --duration: record # shape: {value: int, unit: "DAYS"|"WEEKS"|"MONTHS"|"YEARS"}
  --commits: list # item shape: {type: "PREPAID"|"prepaid"|"POSTPAID"|"postpaid", rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", name?: string, product_id: string, access_schedule: record, invoice_schedule?: any, description?: string, rollover_fraction?: float, priority?: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, temporary_id?: string, custom_fields?: record}
  --credits: list # item shape: {name?: string, product_id: string, access_schedule: record, description?: string, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, priority?: float, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", custom_fields?: record}
  --recurring-commits: list # item shape: {name?: string, product_id: string, access_amount: record, description?: string, rollover_fraction?: float, priority: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, temporary_id?: string, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", starting_at_offset: record, duration?: record, commit_duration: record, recurrence_frequency?: "MONTHLY"|"monthly"|"QUARTERLY"|"quarterly"|"ANNUAL"|"annual"|"WEEKLY"|"weekly", proration?: "NONE"|"none"|"FIRST"|"first"|"LAST"|"last"|"FIRST_AND_LAST"|"first_and_last", subscription_config?: record, invoice_amount?: record, proration_rounding?: record}
  --recurring-credits: list # item shape: {name?: string, product_id: string, access_amount: record, description?: string, rollover_fraction?: float, priority: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, temporary_id?: string, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", starting_at_offset: record, duration?: record, commit_duration: record, recurrence_frequency?: "MONTHLY"|"monthly"|"QUARTERLY"|"quarterly"|"ANNUAL"|"annual"|"WEEKLY"|"weekly", proration?: "NONE"|"none"|"FIRST"|"first"|"LAST"|"last"|"FIRST_AND_LAST"|"first_and_last", subscription_config?: record, proration_rounding?: record}
  --multiplier-override-prioritization: string@multiplier-override-prioritization-completer # Defaults to LOWEST_MULTIPLIER, which applies the greatest discount to list prices automatically. EXPLICIT prioritization requires specifying priorities for each multiplier; the one with the lowest priority value will be prioritized first. If tiered overrides are used, prioritization must be explicit.
  --overrides: list # item shape: {starting_at_offset: record, duration?: record, entitled?: bool, type?: "OVERWRITE"|"overwrite"|"MULTIPLIER"|"multiplier"|"TIERED"|"tiered", multiplier?: float, priority?: float, overwrite_rate?: record, override_specifiers: list, tiers?: list, is_commit_specific?: bool, target?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate"}
  --scheduled-charges: list # item shape: {product_id: string, name?: string, schedule: record, custom_fields?: record}
  --scheduled-charges-on-usage-invoices: string@scheduled-charges-on-usage-invoices-completer # Determines which scheduled and commit charges to consolidate onto the Contract's usage invoice. The charge's `timestamp` must match the usage invoice's `ending_before` date for consolidation to occur. This field cannot be modified after a Contract has been created. If this field is omitted, charges will appear on a separate invoice from usage charges.
  --usage-statement-schedule: record # shape: {frequency: "MONTHLY"|"monthly"|"QUARTERLY"|"quarterly"|"ANNUAL"|"annual"|"WEEKLY"|"weekly", day?: "FIRST_OF_MONTH"|"first_of_month"|"CONTRACT_START"|"contract_start", invoice_generation_starting_at_offset?: record}
  --billing-provider: string@billing-provider-completer-1
  --delivery-method: string@delivery-method-completer-1
  --spend-threshold-configuration: record # shape: {is_enabled: bool, threshold_amount: float, commit: record, payment_gate_config: record, discount_configuration?: record}
  --prepaid-balance-threshold-configuration: record # shape: {is_enabled: bool, threshold_amount: float, recharge_to_amount: float, custom_credit_type_id?: string, commit: record, payment_gate_config: record, discount_configuration?: record, threshold_balance_specifiers?: list}
  --spend-trackers: list # item shape: {alias: string, credit_type_id: string, reset_frequency: "BILLING_PERIOD", applicable_spend_specifiers: list}
  --subscriptions: list # item shape: {subscription_rate: record, name?: string, description?: string, collection_schedule: "ADVANCE"|"ARREARS"|"advance"|"arrears", proration: record, initial_quantity?: float, starting_at_offset?: record, duration?: record, temporary_id?: string, quantity_management_mode?: "SEAT_BASED"|"seat_based"|"QUANTITY_ONLY"|"quantity_only", seat_config?: record, custom_fields?: record, billing_cycle_config?: record}
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/packages/create")
  let body = {name: $name, contract_name: $contract_name, uniqueness_key: $uniqueness_key, net_payment_terms_days: $net_payment_terms_days, rate_card_id: $rate_card_id, rate_card_alias: $rate_card_alias, aliases: $aliases, duration: $duration, commits: $commits, credits: $credits, recurring_commits: $recurring_commits, recurring_credits: $recurring_credits, multiplier_override_prioritization: $multiplier_override_prioritization, overrides: $overrides, scheduled_charges: $scheduled_charges, scheduled_charges_on_usage_invoices: $scheduled_charges_on_usage_invoices, usage_statement_schedule: $usage_statement_schedule, billing_provider: $billing_provider, delivery_method: $delivery_method, spend_threshold_configuration: $spend_threshold_configuration, prepaid_balance_threshold_configuration: $prepaid_balance_threshold_configuration, spend_trackers: $spend_trackers, subscriptions: $subscriptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a package
#
# POST /v1/packages/get
# operationId: getPackage-v1
export def "packages-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  package_id: string # format: uuid
]: any -> record<data: record<id: string, uniqueness_key: string, name: string, rate_card_id: string, aliases: list<record>, duration: record<value: int, unit: string>, commits: list<record>, credits: list<record>, overrides: list<record>, scheduled_charges: list<record>, scheduled_charges_on_usage_invoices: string, created_at: string, created_by: string, net_payment_terms_days: float, usage_statement_schedule: record<frequency: string, day: string>, multiplier_override_prioritization: string, billing_provider: string, delivery_method: string, recurring_commits: list<record>, recurring_credits: list<record>, spend_threshold_configuration: record<is_enabled: bool, threshold_amount: float, commit: record, payment_gate_config: record, discount_configuration: record>, prepaid_balance_threshold_configuration: record<is_enabled: bool, threshold_amount: float, recharge_to_amount: float, custom_credit_type_id: string, commit: record, payment_gate_config: record, discount_configuration: record, threshold_balance_specifiers: list>, spend_trackers: list<record>, subscriptions: list<record>, contract_name: string, archived_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/packages/get")
  let body = {package_id: $package_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all packages
#
# POST /v1/packages/list
# operationId: listPackages-v1
export def "packages-list listPackages-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results that should be returned
  --next-page: string # Cursor that indicates where the next page of results should start.
  --archive-filter: string@archive-filter-completer-1 # Filter packages by archived status. Defaults to NOT_ARCHIVED.
]: any -> record<data: table<id: string, uniqueness_key: string, name: string, rate_card_id: string, aliases: list, duration: record, commits: list, credits: list, overrides: list, scheduled_charges: list, scheduled_charges_on_usage_invoices: string, created_at: string, created_by: string, net_payment_terms_days: float, usage_statement_schedule: record, multiplier_override_prioritization: string, billing_provider: string, delivery_method: string, recurring_commits: list, recurring_credits: list, spend_threshold_configuration: record, prepaid_balance_threshold_configuration: record, spend_trackers: list, subscriptions: list, contract_name: string, archived_at: string>, next_page: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "next_page" $next_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/packages/list" $qp)
  let body = {archive_filter: $archive_filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archive a package
#
# POST /v1/packages/archive
# operationId: archivePackage-v1
export def "packages-archive archivePackage-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  package_id: string # ID of the package to archive (format: uuid)
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/packages/archive")
  let body = {package_id: $package_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List contracts associated with a package
#
# POST /v1/packages/listContractsOnPackage
# operationId: listContractsOnPackage-v1
export def "packages-list-contracts-on-package listContractsOnPackage-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results that should be returned
  --next-page: string # Cursor that indicates where the next page of results should start.
  package_id: string # format: uuid
  --starting-at: string # Optional RFC 3339 timestamp. Only include contracts that started on or after this date. This cannot be provided if covering_date filter is provided. (format: date-time)
  --covering-date: string # Optional RFC 3339 timestamp. Only include contracts active on the provided date. This cannot be provided if starting_at filter is provided. (format: date-time)
  --include-archived: oneof<nothing, bool> # Default false. Determines whether to include archived contracts in the results
]: any -> record<data: table<customer_id: string, contract_id: string, starting_at: string, ending_before: string, archived_at: string>, next_page: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "next_page" $next_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/packages/listContractsOnPackage" $qp)
  let body = {package_id: $package_id, starting_at: $starting_at, covering_date: $covering_date, include_archived: $include_archived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a contract (v2)
#
# POST /v2/contracts/get
# operationId: getContract-v2
export def "contracts-get post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  contract_id: string # format: uuid
  --include-ledgers: oneof<nothing, bool> # Include commit/credit ledgers in the response. Setting this flag may cause the query to be slower. Cannot be used with as_of_date parameter.
  --as-of-date: string # Optional RFC 3339 timestamp. Return the contract as of this date. Cannot be used with include_ledgers parameter. (format: date-time)
  --include-balance: oneof<nothing, bool> # Include the balance of credits and commits in the response. Setting this flag may cause the query to be slower.
  --webhook-notification-id: string # Indicates that this API request was triggered by a webhook notification with the provided ID.
]: any -> record<data: record<id: string, customer_id: string, package_id: string, uniqueness_key: string, name: string, salesforce_opportunity_id: string, rate_card_id: string, starting_at: string, commits: list<record>, credits: list<record>, has_more: record<commits: bool, credits: bool>, overrides: list<record>, discounts: list<record>, professional_services: list<record>, scheduled_charges: list<record>, scheduled_charges_on_usage_invoices: string, transitions: list<record>, reseller_royalties: list<record>, created_at: string, created_by: string, netsuite_sales_order_id: string, net_payment_terms_days: float, ending_before: string, archived_at: string, total_contract_value: float, usage_filter: list<record>, usage_statement_schedule: record<frequency: string, billing_anchor_date: string>, multiplier_override_prioritization: string, custom_fields: record, customer_billing_provider_configuration: record<id: string, billing_provider: string, delivery_method: string>, recurring_commits: list<record>, recurring_credits: list<record>, spend_threshold_configuration: record<is_enabled: bool, threshold_amount: float, commit: record, payment_gate_config: record, discount_configuration: record>, prepaid_balance_threshold_configuration: record<is_enabled: bool, threshold_amount: float, recharge_to_amount: float, custom_credit_type_id: string, commit: record, payment_gate_config: record, discount_configuration: record, threshold_balance_specifiers: list>, spend_trackers: list<record>, subscriptions: list<record>, hierarchy_configuration: any, priority: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/contracts/get")
  let body = {customer_id: $customer_id, contract_id: $contract_id, include_ledgers: $include_ledgers, as_of_date: $as_of_date, include_balance: $include_balance, webhook_notification_id: $webhook_notification_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get contract edit history
#
# POST /v2/contracts/getEditHistory
# operationId: getContractEditHistory-v2
export def "contracts-get-edit-history post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  contract_id: string # format: uuid
]: any -> record<data: table<id: string, timestamp: string, uniqueness_key: string, add_overrides: list, add_pro_services: list, add_reseller_royalties: list, add_discounts: list, add_scheduled_charges: list, add_commits: list, add_credits: list, add_recurring_commits: list, add_recurring_credits: list, add_usage_filters: list, add_subscriptions: list, add_prepaid_balance_threshold_configuration: record, add_spend_threshold_configuration: record, update_contract_name: string, update_discounts: list, update_scheduled_charges: list, update_commits: list, update_credits: list, update_recurring_commits: list, update_recurring_credits: list, update_contract_end_date: string, update_refund_invoices: list, update_subscriptions: list, update_prepaid_balance_threshold_configuration: record, update_spend_threshold_configuration: record, archive_commits: list, archive_credits: list, archive_scheduled_charges: list, remove_overrides: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/contracts/getEditHistory")
  let body = {customer_id: $customer_id, contract_id: $contract_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List customer contracts (v2)
#
# POST /v2/contracts/list
# operationId: listContracts-v2
export def "contracts-list listContracts-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # format: uuid
  --include-ledgers: oneof<nothing, bool> # Include commit/credit ledgers in the response. Setting this flag may cause the response to be slower.
  --include-archived: oneof<nothing, bool> # Include archived contracts in the response.
  --include-balance: oneof<nothing, bool> # Include the balance of credits and commits in the response. Setting this flag may cause the response to be slower.
  --starting-at: string # Optional RFC 3339 timestamp. Only include contracts that started on or after this date. This cannot be provided if covering_date filter is provided. (format: date-time)
  --covering-date: string # Optional RFC 3339 timestamp. Only include contracts active on the provided date. This cannot be provided if starting_at filter is provided. (format: date-time)
]: any -> record<data: table<id: string, customer_id: string, package_id: string, uniqueness_key: string, name: string, salesforce_opportunity_id: string, rate_card_id: string, starting_at: string, commits: list, credits: list, has_more: record, overrides: list, discounts: list, professional_services: list, scheduled_charges: list, scheduled_charges_on_usage_invoices: string, transitions: list, reseller_royalties: list, created_at: string, created_by: string, netsuite_sales_order_id: string, net_payment_terms_days: float, ending_before: string, archived_at: string, total_contract_value: float, usage_filter: list, usage_statement_schedule: record, multiplier_override_prioritization: string, custom_fields: record, customer_billing_provider_configuration: record, recurring_commits: list, recurring_credits: list, spend_threshold_configuration: record, prepaid_balance_threshold_configuration: record, spend_trackers: list, subscriptions: list, hierarchy_configuration: any, priority: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/contracts/list")
  let body = {customer_id: $customer_id, include_ledgers: $include_ledgers, include_archived: $include_archived, include_balance: $include_balance, starting_at: $starting_at, covering_date: $covering_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Edit a contract
#
# POST /v2/contracts/edit
# operationId: editContract-v2
# --add_commits item shape: {type: "PREPAID"|"prepaid"|"POSTPAID"|"postpaid", rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", name?: string, product_id: string, access_schedule?: record, invoice_schedule?: record, amount?: float, description?: string, rollover_fraction?: float, priority?: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, custom_fields?: record, temporary_id?: string, payment_gate_config?: record, hierarchy_configuration?: record, spend_tracker_attributes?: any}
# --add_credits item shape: {name?: string, product_id: string, access_schedule: record, description?: string, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, priority?: float, custom_fields?: record, rollover_fraction?: float, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", hierarchy_configuration?: record}
# --add_recurring_commits item shape: {name?: string, product_id: string, access_amount: record, description?: string, rollover_fraction?: float, priority: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, temporary_id?: string, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", starting_at: string, ending_before?: string, commit_duration: record, recurrence_frequency?: "MONTHLY"|"monthly"|"QUARTERLY"|"quarterly"|"ANNUAL"|"annual"|"WEEKLY"|"weekly", proration?: "NONE"|"none"|"FIRST"|"first"|"LAST"|"last"|"FIRST_AND_LAST"|"first_and_last", hierarchy_configuration?: record, subscription_config?: record, invoice_amount?: record, proration_rounding?: record}
# --add_recurring_credits item shape: {name?: string, product_id: string, access_amount: record, description?: string, rollover_fraction?: float, priority: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, temporary_id?: string, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", starting_at: string, ending_before?: string, commit_duration: record, recurrence_frequency?: "MONTHLY"|"monthly"|"QUARTERLY"|"quarterly"|"ANNUAL"|"annual"|"WEEKLY"|"weekly", proration?: "NONE"|"none"|"FIRST"|"first"|"LAST"|"last"|"FIRST_AND_LAST"|"first_and_last", hierarchy_configuration?: record, subscription_config?: record, proration_rounding?: record}
# --add_discounts item shape: {product_id: string, name?: string, schedule: record, netsuite_sales_order_id?: string, custom_fields?: record}
# --add_overrides item shape: {starting_at: string, ending_before?: string, entitled?: bool, type?: "OVERWRITE"|"overwrite"|"MULTIPLIER"|"multiplier"|"TIERED"|"tiered", multiplier?: float, priority?: float, overwrite_rate?: record, product_id?: string, applicable_product_tags?: list, override_specifiers?: list, tiers?: list, is_commit_specific?: bool, target?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate"}
# --add_scheduled_charges item shape: {product_id: string, name?: string, schedule: record, netsuite_sales_order_id?: string, custom_fields?: record}
# --add_professional_services item shape: {description?: string, product_id: string, netsuite_sales_order_id?: string, unit_price: float, quantity: float, max_amount: float, custom_fields?: record}
# --add_reseller_royalties item shape: {reseller_type: "AWS"|"AWS_PRO_SERVICE"|"GCP"|"GCP_PRO_SERVICE", fraction?: float, netsuite_reseller_id?: string, applicable_product_ids?: list, applicable_product_tags?: list, starting_at?: string, ending_before?: string, reseller_contract_value?: float, aws_options?: record, gcp_options?: record}
# --add_subscriptions item shape: {subscription_rate: record, name?: string, description?: string, collection_schedule: "ADVANCE"|"ARREARS"|"advance"|"arrears", proration: record, initial_quantity?: float, starting_at?: string, ending_before?: string, custom_fields?: record, temporary_id?: string, quantity_management_mode?: "SEAT_BASED"|"seat_based"|"QUANTITY_ONLY"|"quantity_only", seat_config?: record, billing_cycle_config?: record}
# --add_spend_threshold_configuration shape: {is_enabled: bool, threshold_amount: float, commit: record, payment_gate_config: record, discount_configuration?: record}
# --add_prepaid_balance_threshold_configuration shape: {is_enabled: bool, threshold_amount: float, recharge_to_amount: float, custom_credit_type_id?: string, commit: record, payment_gate_config: record, discount_configuration?: record, threshold_balance_specifiers?: list}
# --add_billing_provider_configuration_update shape: {billing_provider_configuration: record, schedule: record}
# --add_revenue_system_configuration_update shape: {revenue_system_configuration: record, schedule: record}
# --add_spend_trackers item shape: {alias: string, credit_type_id: string, reset_frequency: "BILLING_PERIOD", applicable_spend_specifiers: list}
# --update_scheduled_charges item shape: {scheduled_charge_id: string, netsuite_sales_order_id?: string, invoice_schedule?: record}
# --update_commits item shape: {commit_id: string, name?: string, description?: string, access_schedule?: record, netsuite_sales_order_id?: string, rollover_fraction?: float, invoice_schedule?: record, applicable_product_ids?: list, applicable_product_tags?: list, product_id?: string, hierarchy_configuration?: record, priority?: float, rate_type?: "LIST_RATE"|"list_rate"|"COMMIT_RATE"|"commit_rate"}
# --update_credits item shape: {credit_id: string, name?: string, description?: string, access_schedule?: record, rollover_fraction?: float, netsuite_sales_order_id?: string, applicable_product_ids?: list, applicable_product_tags?: list, product_id?: string, priority?: float, hierarchy_configuration?: record, rate_type?: "LIST_RATE"|"list_rate"|"COMMIT_RATE"|"commit_rate"}
# --update_recurring_commits item shape: {recurring_commit_id: string, access_amount?: record, invoice_amount?: record, ending_before?: string, rate_type?: "LIST_RATE"|"list_rate"|"COMMIT_RATE"|"commit_rate", proration_rounding?: record}
# --update_recurring_credits item shape: {recurring_credit_id: string, access_amount?: record, ending_before?: string, rate_type?: "LIST_RATE"|"list_rate"|"COMMIT_RATE"|"commit_rate", proration_rounding?: record}
# --update_subscriptions item shape: {subscription_id: string, ending_before?: string, quantity_management_mode_update?: record, quantity_updates?: list, seat_updates?: record, proration_rounding?: record}
# --update_spend_threshold_configuration shape: {is_enabled?: bool, threshold_amount?: float, commit?: record, payment_gate_config?: record, discount_configuration?: any}
# --update_prepaid_balance_threshold_configuration shape: {is_enabled?: bool, threshold_amount?: float, recharge_to_amount?: float, custom_credit_type_id?: string, commit?: record, payment_gate_config?: record, discount_configuration?: any, threshold_balance_specifiers?: list}
# --archive_commits item shape: {id: string}
# --archive_credits item shape: {id: string}
# --archive_scheduled_charges item shape: {id: string}
# --remove_overrides item shape: {id: string}
export def "contracts-edit editContract-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # ID of the customer whose contract is being edited (format: uuid)
  contract_id: string # ID of the contract being edited (format: uuid)
  --uniqueness-key: string # Prevents the creation of duplicates. If a request to create a record is made with a previously used uniqueness key, a new record will not be created and the request will fail with a 409 error.
  --add-commits: list # item shape: {type: "PREPAID"|"prepaid"|"POSTPAID"|"postpaid", rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", name?: string, product_id: string, access_schedule?: record, invoice_schedule?: record, amount?: float, description?: string, rollover_fraction?: float, priority?: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, custom_fields?: record, temporary_id?: string, payment_gate_config?: record, hierarchy_configuration?: record, spend_tracker_attributes?: any}
  --add-credits: list # item shape: {name?: string, product_id: string, access_schedule: record, description?: string, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, priority?: float, custom_fields?: record, rollover_fraction?: float, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", hierarchy_configuration?: record}
  --add-recurring-commits: list # item shape: {name?: string, product_id: string, access_amount: record, description?: string, rollover_fraction?: float, priority: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, temporary_id?: string, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", starting_at: string, ending_before?: string, commit_duration: record, recurrence_frequency?: "MONTHLY"|"monthly"|"QUARTERLY"|"quarterly"|"ANNUAL"|"annual"|"WEEKLY"|"weekly", proration?: "NONE"|"none"|"FIRST"|"first"|"LAST"|"last"|"FIRST_AND_LAST"|"first_and_last", hierarchy_configuration?: record, subscription_config?: record, invoice_amount?: record, proration_rounding?: record}
  --add-recurring-credits: list # item shape: {name?: string, product_id: string, access_amount: record, description?: string, rollover_fraction?: float, priority: float, applicable_product_ids?: list, applicable_product_tags?: list, specifiers?: list, netsuite_sales_order_id?: string, temporary_id?: string, rate_type?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate", starting_at: string, ending_before?: string, commit_duration: record, recurrence_frequency?: "MONTHLY"|"monthly"|"QUARTERLY"|"quarterly"|"ANNUAL"|"annual"|"WEEKLY"|"weekly", proration?: "NONE"|"none"|"FIRST"|"first"|"LAST"|"last"|"FIRST_AND_LAST"|"first_and_last", hierarchy_configuration?: record, subscription_config?: record, proration_rounding?: record}
  --add-discounts: list # item shape: {product_id: string, name?: string, schedule: record, netsuite_sales_order_id?: string, custom_fields?: record}
  --add-overrides: list # item shape: {starting_at: string, ending_before?: string, entitled?: bool, type?: "OVERWRITE"|"overwrite"|"MULTIPLIER"|"multiplier"|"TIERED"|"tiered", multiplier?: float, priority?: float, overwrite_rate?: record, product_id?: string, applicable_product_tags?: list, override_specifiers?: list, tiers?: list, is_commit_specific?: bool, target?: "COMMIT_RATE"|"commit_rate"|"LIST_RATE"|"list_rate"}
  --add-scheduled-charges: list # item shape: {product_id: string, name?: string, schedule: record, netsuite_sales_order_id?: string, custom_fields?: record}
  --add-professional-services: list # This field's availability is dependent on your client's configuration. — item shape: {description?: string, product_id: string, netsuite_sales_order_id?: string, unit_price: float, quantity: float, max_amount: float, custom_fields?: record}
  --add-reseller-royalties: list # item shape: {reseller_type: "AWS"|"AWS_PRO_SERVICE"|"GCP"|"GCP_PRO_SERVICE", fraction?: float, netsuite_reseller_id?: string, applicable_product_ids?: list, applicable_product_tags?: list, starting_at?: string, ending_before?: string, reseller_contract_value?: float, aws_options?: record, gcp_options?: record}
  --add-subscriptions: list # Optional list of [subscriptions](https://docs.metronome.com/manage-product-access/create-subscription/) to add to the contract. — item shape: {subscription_rate: record, name?: string, description?: string, collection_schedule: "ADVANCE"|"ARREARS"|"advance"|"arrears", proration: record, initial_quantity?: float, starting_at?: string, ending_before?: string, custom_fields?: record, temporary_id?: string, quantity_management_mode?: "SEAT_BASED"|"seat_based"|"QUANTITY_ONLY"|"quantity_only", seat_config?: record, billing_cycle_config?: record}
  --add-spend-threshold-configuration: record # shape: {is_enabled: bool, threshold_amount: float, commit: record, payment_gate_config: record, discount_configuration?: record}
  --add-prepaid-balance-threshold-configuration: record # shape: {is_enabled: bool, threshold_amount: float, recharge_to_amount: float, custom_credit_type_id?: string, commit: record, payment_gate_config: record, discount_configuration?: record, threshold_balance_specifiers?: list}
  --add-billing-provider-configuration-update: record # shape: {billing_provider_configuration: record, schedule: record}
  --add-revenue-system-configuration-update: any # shape: {revenue_system_configuration: record, schedule: record}
  --add-spend-trackers: list # Spend trackers to add to this contract. Aliases must be unique within a contract. — item shape: {alias: string, credit_type_id: string, reset_frequency: "BILLING_PERIOD", applicable_spend_specifiers: list}
  --update-contract-name: string # Value to update the contract name to. If not provided, the contract name will remain unchanged. (nullable)
  --update-scheduled-charges: list # item shape: {scheduled_charge_id: string, netsuite_sales_order_id?: string, invoice_schedule?: record}
  --update-commits: list # item shape: {commit_id: string, name?: string, description?: string, access_schedule?: record, netsuite_sales_order_id?: string, rollover_fraction?: float, invoice_schedule?: record, applicable_product_ids?: list, applicable_product_tags?: list, product_id?: string, hierarchy_configuration?: record, priority?: float, rate_type?: "LIST_RATE"|"list_rate"|"COMMIT_RATE"|"commit_rate"}
  --update-credits: list # item shape: {credit_id: string, name?: string, description?: string, access_schedule?: record, rollover_fraction?: float, netsuite_sales_order_id?: string, applicable_product_ids?: list, applicable_product_tags?: list, product_id?: string, priority?: float, hierarchy_configuration?: record, rate_type?: "LIST_RATE"|"list_rate"|"COMMIT_RATE"|"commit_rate"}
  --update-recurring-commits: list # Edits to these recurring commits will only affect commits whose access schedules has not started. Expired commits, and commits with an active access schedule will remain unchanged. — item shape: {recurring_commit_id: string, access_amount?: record, invoice_amount?: record, ending_before?: string, rate_type?: "LIST_RATE"|"list_rate"|"COMMIT_RATE"|"commit_rate", proration_rounding?: record}
  --update-recurring-credits: list # Edits to these recurring credits will only affect credits whose access schedules has not started. Expired credits, and credits with an active access schedule will remain unchanged. — item shape: {recurring_credit_id: string, access_amount?: record, ending_before?: string, rate_type?: "LIST_RATE"|"list_rate"|"COMMIT_RATE"|"commit_rate", proration_rounding?: record}
  --update-subscriptions: list # Optional list of subscriptions to update. — item shape: {subscription_id: string, ending_before?: string, quantity_management_mode_update?: record, quantity_updates?: list, seat_updates?: record, proration_rounding?: record}
  --update-spend-threshold-configuration: record # shape: {is_enabled?: bool, threshold_amount?: float, commit?: record, payment_gate_config?: record, discount_configuration?: any}
  --update-prepaid-balance-threshold-configuration: record # shape: {is_enabled?: bool, threshold_amount?: float, recharge_to_amount?: float, custom_credit_type_id?: string, commit?: record, payment_gate_config?: record, discount_configuration?: any, threshold_balance_specifiers?: list}
  --update-contract-end-date: string # RFC 3339 timestamp indicating when the contract will end (exclusive). (nullable, format: date-time)
  --update-net-payment-terms-days: float # Number of days after issuance of invoice after which the invoice is due (e.g. Net 30). (nullable)
  --allow-contract-ending-before-finalized-invoice: oneof<nothing, bool> # If true, allows setting the contract end date earlier than the end_timestamp of existing finalized invoices. Finalized invoices will be unchanged; if you want to incorporate the new end date, you can void and regenerate finalized usage invoices. Defaults to true.
  --archive-commits: list # IDs of commits to archive — item shape: {id: string}
  --archive-credits: list # IDs of credits to archive — item shape: {id: string}
  --archive-scheduled-charges: list # IDs of scheduled charges to archive — item shape: {id: string}
  --archive-spend-trackers: list # Aliases of spend trackers to archive.
  --remove-overrides: list # IDs of overrides to remove — item shape: {id: string}
]: any -> record<data: record<id: string, edit: record<id: string, timestamp: string, uniqueness_key: string, add_overrides: list, add_pro_services: list, add_reseller_royalties: list, add_discounts: list, add_scheduled_charges: list, add_commits: list, add_credits: list, add_recurring_commits: list, add_recurring_credits: list, add_usage_filters: list, add_subscriptions: list, add_prepaid_balance_threshold_configuration: record, add_spend_threshold_configuration: record, update_contract_name: string, update_discounts: list, update_scheduled_charges: list, update_commits: list, update_credits: list, update_recurring_commits: list, update_recurring_credits: list, update_contract_end_date: string, update_refund_invoices: list, update_subscriptions: list, update_prepaid_balance_threshold_configuration: record, update_spend_threshold_configuration: record, archive_commits: list, archive_credits: list, archive_scheduled_charges: list, remove_overrides: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/contracts/edit")
  let body = {customer_id: $customer_id, contract_id: $contract_id, uniqueness_key: $uniqueness_key, add_commits: $add_commits, add_credits: $add_credits, add_recurring_commits: $add_recurring_commits, add_recurring_credits: $add_recurring_credits, add_discounts: $add_discounts, add_overrides: $add_overrides, add_scheduled_charges: $add_scheduled_charges, add_professional_services: $add_professional_services, add_reseller_royalties: $add_reseller_royalties, add_subscriptions: $add_subscriptions, add_spend_threshold_configuration: $add_spend_threshold_configuration, add_prepaid_balance_threshold_configuration: $add_prepaid_balance_threshold_configuration, add_billing_provider_configuration_update: $add_billing_provider_configuration_update, add_revenue_system_configuration_update: $add_revenue_system_configuration_update, add_spend_trackers: $add_spend_trackers, update_contract_name: $update_contract_name, update_scheduled_charges: $update_scheduled_charges, update_commits: $update_commits, update_credits: $update_credits, update_recurring_commits: $update_recurring_commits, update_recurring_credits: $update_recurring_credits, update_subscriptions: $update_subscriptions, update_spend_threshold_configuration: $update_spend_threshold_configuration, update_prepaid_balance_threshold_configuration: $update_prepaid_balance_threshold_configuration, update_contract_end_date: $update_contract_end_date, update_net_payment_terms_days: $update_net_payment_terms_days, allow_contract_ending_before_finalized_invoice: $allow_contract_ending_before_finalized_invoice, archive_commits: $archive_commits, archive_credits: $archive_credits, archive_scheduled_charges: $archive_scheduled_charges, archive_spend_trackers: $archive_spend_trackers, remove_overrides: $remove_overrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Edit a commit
#
# POST /v2/contracts/commits/edit
# operationId: editCommit-v2
# --access_schedule shape: {add_schedule_items?: list, update_schedule_items?: list, remove_schedule_items?: list}
# --invoice_schedule shape: {add_schedule_items?: list, update_schedule_items?: list, remove_schedule_items?: list}
# --specifiers item shape: {product_id?: string, product_tags?: list, pricing_group_values?: record, presentation_group_values?: record, exclude?: list}
# --hierarchy_configuration shape: {child_access: any}
export def "contracts-commits-edit editCommit-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # ID of the customer whose commit is being edited (format: uuid)
  commit_id: string # ID of the commit to edit (format: uuid)
  --name: string # Updated name for the commit
  --description: string # Updated description for the commit
  --access-schedule: record # shape: {add_schedule_items?: list, update_schedule_items?: list, remove_schedule_items?: list}
  --invoice-schedule: record # shape: {add_schedule_items?: list, update_schedule_items?: list, remove_schedule_items?: list}
  --invoice-contract-id: string # ID of contract to use for invoicing (format: uuid)
  --applicable-product-ids: list # Which products the commit applies to. If applicable_product_ids, applicable_product_tags or specifiers are not provided, the commit applies to all products. (nullable)
  --applicable-product-tags: list # Which tags the commit applies to. If applicable_product_ids, applicable_product_tags or specifiers are not provided, the commit applies to all products. (nullable)
  --specifiers: list # List of filters that determine what kind of customer usage draws down a commit or credit. A customer's usage needs to meet the condition of at least one of the specifiers to contribute to a commit's or credit's drawdown. This field cannot be used together with `applicable_product_ids` or `applicable_product_tags`. Instead, to target usage by product or product tag, pass those values in the body of `specifiers`. (nullable) — item shape: {product_id?: string, product_tags?: list, pricing_group_values?: record, presentation_group_values?: record, exclude?: list}
  --product-id: string # format: uuid
  --priority: float # If multiple commits are applicable, the one with the lower priority will apply first. (nullable)
  --rate-type: string@rate-type-completer-1 # If provided, updates the commit to use the specified rate type for current and future invoices. Previously finalized invoices will need to be voided and regenerated to reflect the rate type change.
  --hierarchy-configuration: record # shape: {child_access: any}
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/contracts/commits/edit")
  let body = {customer_id: $customer_id, commit_id: $commit_id, name: $name, description: $description, access_schedule: $access_schedule, invoice_schedule: $invoice_schedule, invoice_contract_id: $invoice_contract_id, applicable_product_ids: $applicable_product_ids, applicable_product_tags: $applicable_product_tags, specifiers: $specifiers, product_id: $product_id, priority: $priority, rate_type: $rate_type, hierarchy_configuration: $hierarchy_configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Edit a credit
#
# POST /v2/contracts/credits/edit
# operationId: editCredit-v2
# --access_schedule shape: {add_schedule_items?: list, update_schedule_items?: list, remove_schedule_items?: list}
# --specifiers item shape: {product_id?: string, product_tags?: list, pricing_group_values?: record, presentation_group_values?: record, exclude?: list}
# --hierarchy_configuration shape: {child_access: any}
export def "contracts-credits-edit editCredit-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # ID of the customer whose credit is being edited (format: uuid)
  credit_id: string # ID of the credit to edit (format: uuid)
  --name: string # Updated name for the credit
  --description: string # Updated description for the credit
  --access-schedule: record # shape: {add_schedule_items?: list, update_schedule_items?: list, remove_schedule_items?: list}
  --applicable-product-ids: list # Which products the credit applies to. If both applicable_product_ids and applicable_product_tags are not provided, the credit applies to all products. (nullable)
  --applicable-product-tags: list # Which tags the credit applies to. If both applicable_product_ids and applicable_product_tags are not provided, the credit applies to all products. (nullable)
  --specifiers: list # List of filters that determine what kind of customer usage draws down a commit or credit. A customer's usage needs to meet the condition of at least one of the specifiers to contribute to a commit's or credit's drawdown. This field cannot be used together with `applicable_product_ids` or `applicable_product_tags`. Instead, to target usage by product or product tag, pass those values in the body of `specifiers`. (nullable) — item shape: {product_id?: string, product_tags?: list, pricing_group_values?: record, presentation_group_values?: record, exclude?: list}
  --product-id: string # format: uuid
  --priority: float # If multiple commits are applicable, the one with the lower priority will apply first. (nullable)
  --rate-type: string@rate-type-completer-1 # If provided, updates the credit to use the specified rate type for current and future invoices. Previously finalized invoices will need to be voided and regenerated to reflect the rate type change.
  --hierarchy-configuration: record # shape: {child_access: any}
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/contracts/credits/edit")
  let body = {customer_id: $customer_id, credit_id: $credit_id, name: $name, description: $description, access_schedule: $access_schedule, applicable_product_ids: $applicable_product_ids, applicable_product_tags: $applicable_product_tags, specifiers: $specifiers, product_id: $product_id, priority: $priority, rate_type: $rate_type, hierarchy_configuration: $hierarchy_configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archive a commit
#
# POST /v2/contracts/commits/archive
# operationId: archiveCommit-v2
export def "contracts-commits-archive archiveCommit-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # ID of the customer whose commit is being archived (format: uuid)
  commit_id: string # ID of the commit to archive (format: uuid)
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/contracts/commits/archive")
  let body = {customer_id: $customer_id, commit_id: $commit_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archive a credit
#
# POST /v2/contracts/credits/archive
# operationId: archiveCredit-v2
export def "contracts-credits-archive archiveCredit-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  customer_id: string # ID of the customer whose credit is being archived (format: uuid)
  credit_id: string # ID of the credit to archive (format: uuid)
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/contracts/credits/archive")
  let body = {customer_id: $customer_id, credit_id: $credit_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create an offset lifecycle event notification configuration
#
# POST /v2/notifications/create
# operationId: createNotificationConfig-v2
# --policy shape: {type: string, offset: string}
export def "notifications-create createNotificationConfig-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name for this offset notification configuration.
  policy: record # shape: {type: string, offset: string}
  --uniqueness-key: string # Prevents the creation of duplicates. If a request to create a record is made with a previously used uniqueness key, a new record will not be created and the request will fail with a 409 error.
]: any -> record<data: record<id: string, name: string, type: string, policy: record<type: string, offset: string>, environment_type: string, created_at: string, created_by: string, archived_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/notifications/create")
  let body = {name: $name, policy: $policy, uniqueness_key: $uniqueness_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an offset lifecycle event notification configuration
#
# POST /v2/notifications/get
# operationId: getNotificationConfig-v2
export def "notifications-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # The ID of the notification configuration to retrieve (format: uuid)
]: any -> record<data: record<id: string, name: string, type: string, policy: record<type: string, offset: string>, environment_type: string, created_at: string, created_by: string, archived_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/notifications/get")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List offset lifecycle event notification configurations
#
# POST /v2/notifications/offset/list
# operationId: listOffsetNotificationConfigs-v2
export def "notifications-offset-list listOffsetNotificationConfigs-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float
  --cursor: string
  --archive-filter: string@archive-filter-completer # Filter options for the notification configurations. If not provided, defaults to NOT_ARCHIVED.
]: any -> record<data: table<id: string, name: string, type: string, policy: record, environment_type: string, created_at: string, created_by: string, archived_at: string>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/notifications/offset/list")
  let body = {limit: $limit, cursor: $cursor, archive_filter: $archive_filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List system notification event types
#
# POST /v2/notifications/system/list
# operationId: listSystemNotificationConfigs-v2
export def "notifications-system-list listSystemNotificationConfigs-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<type: string, is_enabled: bool, policy: record>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/notifications/system/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit an offset lifecycle event notification configuration
#
# POST /v2/notifications/edit
# operationId: editNotificationConfig-v2
export def "notifications-edit editNotificationConfig-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The ID of the notification configuration to edit. Not provided when updating the configuration for system events  (format: uuid)
  --is-enabled: oneof<nothing, bool> # Set to true to enable webhook messages for the notification indicated in the policy, false to disable. Only supported by system lifecycle events.
  policy: any # Updated policy configuration. The policy.type must match the existing lifecycle event type.
]: any -> record<data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/notifications/edit")
  let body = {id: $id, is_enabled: $is_enabled, policy: $policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archive an offset lifecycle event notification configuration
#
# POST /v2/notifications/archive
# operationId: archiveNotificationConfig-v2
export def "notifications-archive archiveNotificationConfig-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # The ID of the offset lifecycle event notification configuration to archive.  (format: uuid)
]: any -> record<data: record<id: string, name: string, type: string, policy: record<type: string, offset: string>, environment_type: string, created_at: string, created_by: string, archived_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/notifications/archive")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
