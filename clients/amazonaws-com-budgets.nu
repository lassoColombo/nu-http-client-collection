# Auto-generated client for AWS Budgets v2016-10-20
# Source: https://api.apis.guru/v2/specs/amazonaws.com/budgets/2016-10-20/openapi.json
# Auth: --token flag or $env.AWS_BUDGETS_TOKEN

const BASE_URL = "https://budgets.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_BUDGETS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://budgets.amazonaws.com" "http://budgets.cn-north-1.amazonaws.com.cn" "http://budgets.cn-northwest-1.amazonaws.com.cn" "https://budgets.cn-north-1.amazonaws.com.cn" "https://budgets.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSBudgetServiceGateway.CreateBudget"] }
def notification-type-completer [] { ["ACTUAL" "FORECASTED"] }
def action-type-completer [] { ["APPLY_IAM_POLICY" "APPLY_SCP_POLICY" "RUN_SSM_DOCUMENTS"] }
def approval-model-completer [] { ["AUTOMATIC" "MANUAL"] }
def x-amz-target-completer-1 [] { ["AWSBudgetServiceGateway.CreateBudgetAction"] }
def x-amz-target-completer-2 [] { ["AWSBudgetServiceGateway.CreateNotification"] }
def x-amz-target-completer-3 [] { ["AWSBudgetServiceGateway.CreateSubscriber"] }
def x-amz-target-completer-4 [] { ["AWSBudgetServiceGateway.DeleteBudget"] }
def x-amz-target-completer-5 [] { ["AWSBudgetServiceGateway.DeleteBudgetAction"] }
def x-amz-target-completer-6 [] { ["AWSBudgetServiceGateway.DeleteNotification"] }
def x-amz-target-completer-7 [] { ["AWSBudgetServiceGateway.DeleteSubscriber"] }
def x-amz-target-completer-8 [] { ["AWSBudgetServiceGateway.DescribeBudget"] }
def x-amz-target-completer-9 [] { ["AWSBudgetServiceGateway.DescribeBudgetAction"] }
def x-amz-target-completer-10 [] { ["AWSBudgetServiceGateway.DescribeBudgetActionHistories"] }
def x-amz-target-completer-11 [] { ["AWSBudgetServiceGateway.DescribeBudgetActionsForAccount"] }
def x-amz-target-completer-12 [] { ["AWSBudgetServiceGateway.DescribeBudgetActionsForBudget"] }
def x-amz-target-completer-13 [] { ["AWSBudgetServiceGateway.DescribeBudgetNotificationsForAccount"] }
def x-amz-target-completer-14 [] { ["AWSBudgetServiceGateway.DescribeBudgetPerformanceHistory"] }
def x-amz-target-completer-15 [] { ["AWSBudgetServiceGateway.DescribeBudgets"] }
def x-amz-target-completer-16 [] { ["AWSBudgetServiceGateway.DescribeNotificationsForBudget"] }
def x-amz-target-completer-17 [] { ["AWSBudgetServiceGateway.DescribeSubscribersForNotification"] }
def execution-type-completer [] { ["APPROVE_BUDGET_ACTION" "RESET_BUDGET_ACTION" "RETRY_BUDGET_ACTION" "REVERSE_BUDGET_ACTION"] }
def x-amz-target-completer-18 [] { ["AWSBudgetServiceGateway.ExecuteBudgetAction"] }
def x-amz-target-completer-19 [] { ["AWSBudgetServiceGateway.UpdateBudget"] }
def x-amz-target-completer-20 [] { ["AWSBudgetServiceGateway.UpdateBudgetAction"] }
def x-amz-target-completer-21 [] { ["AWSBudgetServiceGateway.UpdateNotification"] }
def x-amz-target-completer-22 [] { ["AWSBudgetServiceGateway.UpdateSubscriber"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "create-budget" } } | get name | first)
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

# Creates a budget and, if included, notifications and subscribers. Only one of BudgetLimit or PlannedBudgetLimits can be present in the syntax at one time. Use the syntax that matches your case. The Request Syntax section shows the BudgetLimit syntax. For PlannedBudgetLimits, see the Examples (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_budgets_CreateBudget.html#API_CreateBudget_Examples) section.
#
# POST /
# operationId: CreateBudget
# --Budget shape: {BudgetName: string, BudgetLimit?: record, PlannedBudgetLimits?: record, CostFilters?: record, CostTypes?: record, TimeUnit: "DAILY"|"MONTHLY"|"QUARTERLY"|"ANNUALLY", TimePeriod?: record, CalculatedSpend?: record, BudgetType: "USAGE"|"COST"|"RI_UTILIZATION"|"RI_COVERAGE"|"SAVINGS_PLANS_UTILIZATION"|"SAVINGS_PLANS_COVERAGE", LastUpdatedTime?: string, AutoAdjustData?: record}
# --NotificationsWithSubscribers item shape: {Notification: record, Subscribers: list}
export def "create-budget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget: record # Represents the output of the CreateBudget operation. The content consists of the detailed metadata and data file information, and the current status of the budget object. This is the Amazon Resource Name (ARN) pattern for a budget: arn:aws:budgets::AccountId:budget/budgetName — shape: {BudgetName: string, BudgetLimit?: record, PlannedBudgetLimits?: record, CostFilters?: record, CostTypes?: record, TimeUnit: "DAILY"|"MONTHLY"|"QUARTERLY"|"ANNUALLY", TimePeriod?: record, CalculatedSpend?: record, BudgetType: "USAGE"|"COST"|"RI_UTILIZATION"|"RI_COVERAGE"|"SAVINGS_PLANS_UTILIZATION"|"SAVINGS_PLANS_COVERAGE", LastUpdatedTime?: string, AutoAdjustData?: record}
  --notifications-with-subscribers: list # A list of notifications, each with a list of subscribers. — item shape: {Notification: record, Subscribers: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.CreateBudget")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AccountId": $account_id, "Budget": $budget, "NotificationsWithSubscribers": $notifications_with_subscribers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a budget action.
#
# POST /
# operationId: CreateBudgetAction
# --ActionThreshold shape: {ActionThresholdValue: float, ActionThresholdType: "PERCENTAGE"|"ABSOLUTE_VALUE"}
# --Definition shape: {IamActionDefinition?: record, ScpActionDefinition?: record, SsmActionDefinition?: record}
# --Subscribers item shape: {SubscriptionType: "SNS"|"EMAIL", Address: string}
export def "create-budget-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-1 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
  notification_type: string@notification-type-completer # The type of a notification. It must be ACTUAL or FORECASTED.
  action_type: string@action-type-completer # The type of action. This defines the type of tasks that can be carried out by this action. This field also determines the format for definition.
  action_threshold: record # The trigger threshold of the action. — shape: {ActionThresholdValue: float, ActionThresholdType: "PERCENTAGE"|"ABSOLUTE_VALUE"}
  definition: record # Specifies all of the type-specific parameters. — shape: {IamActionDefinition?: record, ScpActionDefinition?: record, SsmActionDefinition?: record}
  execution_role_arn: string # The role passed for action execution and reversion. Roles and actions must be in the same account.
  approval_model: string@approval-model-completer # This specifies if the action needs manual or automatic approval.
  subscribers: list # A list of subscribers. — item shape: {SubscriptionType: "SNS"|"EMAIL", Address: string}
]: any -> record<AccountId: string, BudgetName: string, ActionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.CreateBudgetAction")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name, "NotificationType": $notification_type, "ActionType": $action_type, "ActionThreshold": $action_threshold, "Definition": $definition, "ExecutionRoleArn": $execution_role_arn, "ApprovalModel": $approval_model, "Subscribers": $subscribers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a notification. You must create the budget before you create the associated notification.
#
# POST /
# operationId: CreateNotification
# --Notification shape: {NotificationType: "ACTUAL"|"FORECASTED", ComparisonOperator: "GREATER_THAN"|"LESS_THAN"|"EQUAL_TO", Threshold: float, ThresholdType?: "PERCENTAGE"|"ABSOLUTE_VALUE", NotificationState?: "OK"|"ALARM"}
# --Subscribers item shape: {SubscriptionType: "SNS"|"EMAIL", Address: string}
export def "create-notification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-2 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
  notification: record # A notification that's associated with a budget. A budget can have up to ten notifications. Each notification must have at least one subscriber. A notification can have one SNS subscriber and up to 10 email subscribers, for a total of 11 subscribers. For example, if you have a budget for 200 dollars and you want to be notified when you go over 160 dollars, create a notification with the following parameters: A notificationType of ACTUAL A thresholdType of PERCENTAGE A comparisonOperator of GREATER_THAN A notification threshold of 80 — shape: {NotificationType: "ACTUAL"|"FORECASTED", ComparisonOperator: "GREATER_THAN"|"LESS_THAN"|"EQUAL_TO", Threshold: float, ThresholdType?: "PERCENTAGE"|"ABSOLUTE_VALUE", NotificationState?: "OK"|"ALARM"}
  subscribers: list # A list of subscribers. — item shape: {SubscriptionType: "SNS"|"EMAIL", Address: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.CreateNotification")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name, "Notification": $notification, "Subscribers": $subscribers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a subscriber. You must create the associated budget and notification before you create the subscriber.
#
# POST /
# operationId: CreateSubscriber
# --Notification shape: {NotificationType: "ACTUAL"|"FORECASTED", ComparisonOperator: "GREATER_THAN"|"LESS_THAN"|"EQUAL_TO", Threshold: float, ThresholdType?: "PERCENTAGE"|"ABSOLUTE_VALUE", NotificationState?: "OK"|"ALARM"}
# --Subscriber shape: {SubscriptionType: "SNS"|"EMAIL", Address: string}
export def "create-subscriber" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-3 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
  notification: record # A notification that's associated with a budget. A budget can have up to ten notifications. Each notification must have at least one subscriber. A notification can have one SNS subscriber and up to 10 email subscribers, for a total of 11 subscribers. For example, if you have a budget for 200 dollars and you want to be notified when you go over 160 dollars, create a notification with the following parameters: A notificationType of ACTUAL A thresholdType of PERCENTAGE A comparisonOperator of GREATER_THAN A notification threshold of 80 — shape: {NotificationType: "ACTUAL"|"FORECASTED", ComparisonOperator: "GREATER_THAN"|"LESS_THAN"|"EQUAL_TO", Threshold: float, ThresholdType?: "PERCENTAGE"|"ABSOLUTE_VALUE", NotificationState?: "OK"|"ALARM"}
  subscriber: record # The subscriber to a budget notification. The subscriber consists of a subscription type and either an Amazon SNS topic or an email address. For example, an email subscriber has the following parameters: A subscriptionType of EMAIL An address of example@example.com — shape: {SubscriptionType: "SNS"|"EMAIL", Address: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.CreateSubscriber")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name, "Notification": $notification, "Subscriber": $subscriber} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a budget. You can delete your budget at any time. Deleting a budget also deletes the notifications and subscribers that are associated with that budget.
#
# POST /
# operationId: DeleteBudget
export def "delete-budget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-4 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.DeleteBudget")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a budget action.
#
# POST /
# operationId: DeleteBudgetAction
export def "delete-budget-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-5 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
  action_id: string # A system-generated universally unique identifier (UUID) for the action.
]: any -> record<AccountId: string, BudgetName: string, Action: record<ActionId: string, BudgetName: string, NotificationType: string, ActionType: string, ActionThreshold: record<ActionThresholdValue: float, ActionThresholdType: string>, Definition: record<IamActionDefinition: record, ScpActionDefinition: record, SsmActionDefinition: record>, ExecutionRoleArn: string, ApprovalModel: string, Status: string, Subscribers: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.DeleteBudgetAction")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name, "ActionId": $action_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a notification. Deleting a notification also deletes the subscribers that are associated with the notification.
#
# POST /
# operationId: DeleteNotification
# --Notification shape: {NotificationType: "ACTUAL"|"FORECASTED", ComparisonOperator: "GREATER_THAN"|"LESS_THAN"|"EQUAL_TO", Threshold: float, ThresholdType?: "PERCENTAGE"|"ABSOLUTE_VALUE", NotificationState?: "OK"|"ALARM"}
export def "delete-notification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-6 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
  notification: record # A notification that's associated with a budget. A budget can have up to ten notifications. Each notification must have at least one subscriber. A notification can have one SNS subscriber and up to 10 email subscribers, for a total of 11 subscribers. For example, if you have a budget for 200 dollars and you want to be notified when you go over 160 dollars, create a notification with the following parameters: A notificationType of ACTUAL A thresholdType of PERCENTAGE A comparisonOperator of GREATER_THAN A notification threshold of 80 — shape: {NotificationType: "ACTUAL"|"FORECASTED", ComparisonOperator: "GREATER_THAN"|"LESS_THAN"|"EQUAL_TO", Threshold: float, ThresholdType?: "PERCENTAGE"|"ABSOLUTE_VALUE", NotificationState?: "OK"|"ALARM"}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.DeleteNotification")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name, "Notification": $notification} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a subscriber. Deleting the last subscriber to a notification also deletes the notification.
#
# POST /
# operationId: DeleteSubscriber
# --Notification shape: {NotificationType: "ACTUAL"|"FORECASTED", ComparisonOperator: "GREATER_THAN"|"LESS_THAN"|"EQUAL_TO", Threshold: float, ThresholdType?: "PERCENTAGE"|"ABSOLUTE_VALUE", NotificationState?: "OK"|"ALARM"}
# --Subscriber shape: {SubscriptionType: "SNS"|"EMAIL", Address: string}
export def "delete-subscriber" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-7 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
  notification: record # A notification that's associated with a budget. A budget can have up to ten notifications. Each notification must have at least one subscriber. A notification can have one SNS subscriber and up to 10 email subscribers, for a total of 11 subscribers. For example, if you have a budget for 200 dollars and you want to be notified when you go over 160 dollars, create a notification with the following parameters: A notificationType of ACTUAL A thresholdType of PERCENTAGE A comparisonOperator of GREATER_THAN A notification threshold of 80 — shape: {NotificationType: "ACTUAL"|"FORECASTED", ComparisonOperator: "GREATER_THAN"|"LESS_THAN"|"EQUAL_TO", Threshold: float, ThresholdType?: "PERCENTAGE"|"ABSOLUTE_VALUE", NotificationState?: "OK"|"ALARM"}
  subscriber: record # The subscriber to a budget notification. The subscriber consists of a subscription type and either an Amazon SNS topic or an email address. For example, an email subscriber has the following parameters: A subscriptionType of EMAIL An address of example@example.com — shape: {SubscriptionType: "SNS"|"EMAIL", Address: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.DeleteSubscriber")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name, "Notification": $notification, "Subscriber": $subscriber} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes a budget. The Request Syntax section shows the BudgetLimit syntax. For PlannedBudgetLimits, see the Examples (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_budgets_DescribeBudget.html#API_DescribeBudget_Examples) section.
#
# POST /
# operationId: DescribeBudget
export def "describe-budget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-8 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
]: any -> record<Budget: record<BudgetName: string, BudgetLimit: record<Amount: string, Unit: string>, PlannedBudgetLimits: record, CostFilters: record, CostTypes: record<IncludeTax: bool, IncludeSubscription: bool, UseBlended: bool, IncludeRefund: bool, IncludeCredit: bool, IncludeUpfront: bool, IncludeRecurring: bool, IncludeOtherSubscription: bool, IncludeSupport: bool, IncludeDiscount: bool, UseAmortized: bool>, TimeUnit: string, TimePeriod: record<Start: string, End: string>, CalculatedSpend: record<ActualSpend: record, ForecastedSpend: record>, BudgetType: string, LastUpdatedTime: string, AutoAdjustData: record<AutoAdjustType: string, HistoricalOptions: record, LastAutoAdjustTime: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.DescribeBudget")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes a budget action detail.
#
# POST /
# operationId: DescribeBudgetAction
export def "describe-budget-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-9 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
  action_id: string # A system-generated universally unique identifier (UUID) for the action.
]: any -> record<AccountId: string, BudgetName: string, Action: record<ActionId: string, BudgetName: string, NotificationType: string, ActionType: string, ActionThreshold: record<ActionThresholdValue: float, ActionThresholdType: string>, Definition: record<IamActionDefinition: record, ScpActionDefinition: record, SsmActionDefinition: record>, ExecutionRoleArn: string, ApprovalModel: string, Status: string, Subscribers: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.DescribeBudgetAction")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name, "ActionId": $action_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes a budget action history detail.
#
# POST /
# operationId: DescribeBudgetActionHistories
# --TimePeriod shape: {Start?: string, End?: string}
export def "describe-budget-action-histories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-10 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
  action_id: string # A system-generated universally unique identifier (UUID) for the action.
  --time-period: record # The period of time that's covered by a budget. The period has a start date and an end date. The start date must come before the end date. There are no restrictions on the end date. — shape: {Start?: string, End?: string}
  --max-results-body: int # An integer that represents how many entries a paginated response contains. The maximum is 100. (body field)
  --next-token-body: string # A generic string. (body field)
]: any -> record<ActionHistories: table<Timestamp: string, Status: string, EventType: string, ActionHistoryDetails: record>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.DescribeBudgetActionHistories")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name, "ActionId": $action_id, "TimePeriod": $time_period, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes all of the budget actions for an account.
#
# POST /
# operationId: DescribeBudgetActionsForAccount
export def "describe-budget-actions-for-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-11 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  --max-results-body: int # An integer that represents how many entries a paginated response contains. The maximum is 100. (body field)
  --next-token-body: string # A generic string. (body field)
]: any -> record<Actions: table<ActionId: string, BudgetName: string, NotificationType: string, ActionType: string, ActionThreshold: record, Definition: record, ExecutionRoleArn: string, ApprovalModel: string, Status: string, Subscribers: list>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.DescribeBudgetActionsForAccount")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AccountId": $account_id, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes all of the budget actions for a budget.
#
# POST /
# operationId: DescribeBudgetActionsForBudget
export def "describe-budget-actions-for-budget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-12 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
  --max-results-body: int # An integer that represents how many entries a paginated response contains. The maximum is 100. (body field)
  --next-token-body: string # A generic string. (body field)
]: any -> record<Actions: table<ActionId: string, BudgetName: string, NotificationType: string, ActionType: string, ActionThreshold: record, Definition: record, ExecutionRoleArn: string, ApprovalModel: string, Status: string, Subscribers: list>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.DescribeBudgetActionsForBudget")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the budget names and notifications that are associated with an account.
#
# POST /
# operationId: DescribeBudgetNotificationsForAccount
export def "describe-budget-notifications-for-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-13 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  --max-results-body: int # An integer that shows how many budget name entries a paginated response contains. (body field)
  --next-token-body: string # A generic string. (body field)
]: any -> record<BudgetNotificationsForAccount: table<Notifications: list, BudgetName: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.DescribeBudgetNotificationsForAccount")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AccountId": $account_id, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes the history for DAILY, MONTHLY, and QUARTERLY budgets. Budget history isn't available for ANNUAL budgets.
#
# POST /
# operationId: DescribeBudgetPerformanceHistory
# --TimePeriod shape: {Start?: string, End?: string}
export def "describe-budget-performance-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-14 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
  --time-period: record # The period of time that's covered by a budget. The period has a start date and an end date. The start date must come before the end date. There are no restrictions on the end date. — shape: {Start?: string, End?: string}
  --max-results-body: int # An integer that represents how many entries a paginated response contains. The maximum is 100. (body field)
  --next-token-body: string # A generic string. (body field)
]: any -> record<BudgetPerformanceHistory: record<BudgetName: string, BudgetType: string, CostFilters: record, CostTypes: record<IncludeTax: bool, IncludeSubscription: bool, UseBlended: bool, IncludeRefund: bool, IncludeCredit: bool, IncludeUpfront: bool, IncludeRecurring: bool, IncludeOtherSubscription: bool, IncludeSupport: bool, IncludeDiscount: bool, UseAmortized: bool>, TimeUnit: string, BudgetedAndActualAmountsList: list<record>>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.DescribeBudgetPerformanceHistory")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name, "TimePeriod": $time_period, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the budgets that are associated with an account. The Request Syntax section shows the BudgetLimit syntax. For PlannedBudgetLimits, see the Examples (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_budgets_DescribeBudgets.html#API_DescribeBudgets_Examples) section.
#
# POST /
# operationId: DescribeBudgets
export def "describe-budgets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-15 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  --max-results-body: int # An integer that represents how many entries a paginated response contains. The maximum is 100. (body field)
  --next-token-body: string # A generic string. (body field)
]: any -> record<Budgets: table<BudgetName: string, BudgetLimit: record, PlannedBudgetLimits: record, CostFilters: record, CostTypes: record, TimeUnit: string, TimePeriod: record, CalculatedSpend: record, BudgetType: string, LastUpdatedTime: string, AutoAdjustData: record>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.DescribeBudgets")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AccountId": $account_id, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the notifications that are associated with a budget.
#
# POST /
# operationId: DescribeNotificationsForBudget
export def "describe-notifications-for-budget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-16 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
  --max-results-body: int # An integer that represents how many entries a paginated response contains. The maximum is 100. (body field)
  --next-token-body: string # A generic string. (body field)
]: any -> record<Notifications: table<NotificationType: string, ComparisonOperator: string, Threshold: float, ThresholdType: string, NotificationState: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.DescribeNotificationsForBudget")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the subscribers that are associated with a notification.
#
# POST /
# operationId: DescribeSubscribersForNotification
# --Notification shape: {NotificationType: "ACTUAL"|"FORECASTED", ComparisonOperator: "GREATER_THAN"|"LESS_THAN"|"EQUAL_TO", Threshold: float, ThresholdType?: "PERCENTAGE"|"ABSOLUTE_VALUE", NotificationState?: "OK"|"ALARM"}
export def "describe-subscribers-for-notification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-17 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
  notification: record # A notification that's associated with a budget. A budget can have up to ten notifications. Each notification must have at least one subscriber. A notification can have one SNS subscriber and up to 10 email subscribers, for a total of 11 subscribers. For example, if you have a budget for 200 dollars and you want to be notified when you go over 160 dollars, create a notification with the following parameters: A notificationType of ACTUAL A thresholdType of PERCENTAGE A comparisonOperator of GREATER_THAN A notification threshold of 80 — shape: {NotificationType: "ACTUAL"|"FORECASTED", ComparisonOperator: "GREATER_THAN"|"LESS_THAN"|"EQUAL_TO", Threshold: float, ThresholdType?: "PERCENTAGE"|"ABSOLUTE_VALUE", NotificationState?: "OK"|"ALARM"}
  --max-results-body: int # An integer that represents how many entries a paginated response contains. The maximum is 100. (body field)
  --next-token-body: string # A generic string. (body field)
]: any -> record<Subscribers: table<SubscriptionType: string, Address: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.DescribeSubscribersForNotification")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name, "Notification": $notification, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Executes a budget action.
#
# POST /
# operationId: ExecuteBudgetAction
export def "execute-budget-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-18 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
  action_id: string # A system-generated universally unique identifier (UUID) for the action.
  execution_type: string@execution-type-completer # The type of execution.
]: any -> record<AccountId: string, BudgetName: string, ActionId: string, ExecutionType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.ExecuteBudgetAction")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name, "ActionId": $action_id, "ExecutionType": $execution_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates a budget. You can change every part of a budget except for the budgetName and the calculatedSpend. When you modify a budget, the calculatedSpend drops to zero until Amazon Web Services has new usage data to use for forecasting. Only one of BudgetLimit or PlannedBudgetLimits can be present in the syntax at one time. Use the syntax that matches your case. The Request Syntax section shows the BudgetLimit syntax. For PlannedBudgetLimits, see the Examples (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_budgets_UpdateBudget.html#API_UpdateBudget_Examples) section.
#
# POST /
# operationId: UpdateBudget
# --NewBudget shape: {BudgetName: string, BudgetLimit?: record, PlannedBudgetLimits?: record, CostFilters?: record, CostTypes?: record, TimeUnit: "DAILY"|"MONTHLY"|"QUARTERLY"|"ANNUALLY", TimePeriod?: record, CalculatedSpend?: record, BudgetType: "USAGE"|"COST"|"RI_UTILIZATION"|"RI_COVERAGE"|"SAVINGS_PLANS_UTILIZATION"|"SAVINGS_PLANS_COVERAGE", LastUpdatedTime?: string, AutoAdjustData?: record}
export def "update-budget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-19 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  new_budget: record # Represents the output of the CreateBudget operation. The content consists of the detailed metadata and data file information, and the current status of the budget object. This is the Amazon Resource Name (ARN) pattern for a budget: arn:aws:budgets::AccountId:budget/budgetName — shape: {BudgetName: string, BudgetLimit?: record, PlannedBudgetLimits?: record, CostFilters?: record, CostTypes?: record, TimeUnit: "DAILY"|"MONTHLY"|"QUARTERLY"|"ANNUALLY", TimePeriod?: record, CalculatedSpend?: record, BudgetType: "USAGE"|"COST"|"RI_UTILIZATION"|"RI_COVERAGE"|"SAVINGS_PLANS_UTILIZATION"|"SAVINGS_PLANS_COVERAGE", LastUpdatedTime?: string, AutoAdjustData?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.UpdateBudget")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AccountId": $account_id, "NewBudget": $new_budget} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates a budget action.
#
# POST /
# operationId: UpdateBudgetAction
# --ActionThreshold shape: {ActionThresholdValue: float, ActionThresholdType: "PERCENTAGE"|"ABSOLUTE_VALUE"}
# --Definition shape: {IamActionDefinition?: record, ScpActionDefinition?: record, SsmActionDefinition?: record}
# --Subscribers item shape: {SubscriptionType: "SNS"|"EMAIL", Address: string}
export def "update-budget-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-20 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
  action_id: string # A system-generated universally unique identifier (UUID) for the action.
  --notification-type: string@notification-type-completer # The type of a notification. It must be ACTUAL or FORECASTED.
  --action-threshold: record # The trigger threshold of the action. — shape: {ActionThresholdValue: float, ActionThresholdType: "PERCENTAGE"|"ABSOLUTE_VALUE"}
  --definition: record # Specifies all of the type-specific parameters. — shape: {IamActionDefinition?: record, ScpActionDefinition?: record, SsmActionDefinition?: record}
  --execution-role-arn: string # The role passed for action execution and reversion. Roles and actions must be in the same account.
  --approval-model: string@approval-model-completer # This specifies if the action needs manual or automatic approval.
  --subscribers: list # A list of subscribers. — item shape: {SubscriptionType: "SNS"|"EMAIL", Address: string}
]: any -> record<AccountId: string, BudgetName: string, OldAction: record<ActionId: string, BudgetName: string, NotificationType: string, ActionType: string, ActionThreshold: record<ActionThresholdValue: float, ActionThresholdType: string>, Definition: record<IamActionDefinition: record, ScpActionDefinition: record, SsmActionDefinition: record>, ExecutionRoleArn: string, ApprovalModel: string, Status: string, Subscribers: list<record>>, NewAction: record<ActionId: string, BudgetName: string, NotificationType: string, ActionType: string, ActionThreshold: record<ActionThresholdValue: float, ActionThresholdType: string>, Definition: record<IamActionDefinition: record, ScpActionDefinition: record, SsmActionDefinition: record>, ExecutionRoleArn: string, ApprovalModel: string, Status: string, Subscribers: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.UpdateBudgetAction")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name, "ActionId": $action_id, "NotificationType": $notification_type, "ActionThreshold": $action_threshold, "Definition": $definition, "ExecutionRoleArn": $execution_role_arn, "ApprovalModel": $approval_model, "Subscribers": $subscribers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates a notification.
#
# POST /
# operationId: UpdateNotification
# --OldNotification shape: {NotificationType: "ACTUAL"|"FORECASTED", ComparisonOperator: "GREATER_THAN"|"LESS_THAN"|"EQUAL_TO", Threshold: float, ThresholdType?: "PERCENTAGE"|"ABSOLUTE_VALUE", NotificationState?: "OK"|"ALARM"}
# --NewNotification shape: {NotificationType: "ACTUAL"|"FORECASTED", ComparisonOperator: "GREATER_THAN"|"LESS_THAN"|"EQUAL_TO", Threshold: float, ThresholdType?: "PERCENTAGE"|"ABSOLUTE_VALUE", NotificationState?: "OK"|"ALARM"}
export def "update-notification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-21 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
  old_notification: record # A notification that's associated with a budget. A budget can have up to ten notifications. Each notification must have at least one subscriber. A notification can have one SNS subscriber and up to 10 email subscribers, for a total of 11 subscribers. For example, if you have a budget for 200 dollars and you want to be notified when you go over 160 dollars, create a notification with the following parameters: A notificationType of ACTUAL A thresholdType of PERCENTAGE A comparisonOperator of GREATER_THAN A notification threshold of 80 — shape: {NotificationType: "ACTUAL"|"FORECASTED", ComparisonOperator: "GREATER_THAN"|"LESS_THAN"|"EQUAL_TO", Threshold: float, ThresholdType?: "PERCENTAGE"|"ABSOLUTE_VALUE", NotificationState?: "OK"|"ALARM"}
  new_notification: record # A notification that's associated with a budget. A budget can have up to ten notifications. Each notification must have at least one subscriber. A notification can have one SNS subscriber and up to 10 email subscribers, for a total of 11 subscribers. For example, if you have a budget for 200 dollars and you want to be notified when you go over 160 dollars, create a notification with the following parameters: A notificationType of ACTUAL A thresholdType of PERCENTAGE A comparisonOperator of GREATER_THAN A notification threshold of 80 — shape: {NotificationType: "ACTUAL"|"FORECASTED", ComparisonOperator: "GREATER_THAN"|"LESS_THAN"|"EQUAL_TO", Threshold: float, ThresholdType?: "PERCENTAGE"|"ABSOLUTE_VALUE", NotificationState?: "OK"|"ALARM"}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.UpdateNotification")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name, "OldNotification": $old_notification, "NewNotification": $new_notification} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates a subscriber.
#
# POST /
# operationId: UpdateSubscriber
# --Notification shape: {NotificationType: "ACTUAL"|"FORECASTED", ComparisonOperator: "GREATER_THAN"|"LESS_THAN"|"EQUAL_TO", Threshold: float, ThresholdType?: "PERCENTAGE"|"ABSOLUTE_VALUE", NotificationState?: "OK"|"ALARM"}
# --OldSubscriber shape: {SubscriptionType: "SNS"|"EMAIL", Address: string}
# --NewSubscriber shape: {SubscriptionType: "SNS"|"EMAIL", Address: string}
export def "update-subscriber" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-22 # required
  account_id: string # The account ID of the user. It's a 12-digit number.
  budget_name: string # A string that represents the budget name. The ":" and "\" characters aren't allowed.
  notification: record # A notification that's associated with a budget. A budget can have up to ten notifications. Each notification must have at least one subscriber. A notification can have one SNS subscriber and up to 10 email subscribers, for a total of 11 subscribers. For example, if you have a budget for 200 dollars and you want to be notified when you go over 160 dollars, create a notification with the following parameters: A notificationType of ACTUAL A thresholdType of PERCENTAGE A comparisonOperator of GREATER_THAN A notification threshold of 80 — shape: {NotificationType: "ACTUAL"|"FORECASTED", ComparisonOperator: "GREATER_THAN"|"LESS_THAN"|"EQUAL_TO", Threshold: float, ThresholdType?: "PERCENTAGE"|"ABSOLUTE_VALUE", NotificationState?: "OK"|"ALARM"}
  old_subscriber: record # The subscriber to a budget notification. The subscriber consists of a subscription type and either an Amazon SNS topic or an email address. For example, an email subscriber has the following parameters: A subscriptionType of EMAIL An address of example@example.com — shape: {SubscriptionType: "SNS"|"EMAIL", Address: string}
  new_subscriber: record # The subscriber to a budget notification. The subscriber consists of a subscription type and either an Amazon SNS topic or an email address. For example, an email subscriber has the following parameters: A subscriptionType of EMAIL An address of example@example.com — shape: {SubscriptionType: "SNS"|"EMAIL", Address: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSBudgetServiceGateway.UpdateSubscriber")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AccountId": $account_id, "BudgetName": $budget_name, "Notification": $notification, "OldSubscriber": $old_subscriber, "NewSubscriber": $new_subscriber} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
