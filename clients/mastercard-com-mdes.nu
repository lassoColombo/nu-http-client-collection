# Auto-generated client for MDES Customer Service v2.0.7
# Source: https://api.apis.guru/v2/specs/mastercard.com/MDES/2.0.7/swagger.json
# Auth: --token flag or $env.MDES_CUSTOMER_SERVICE_TOKEN

const BASE_URL = "https://api.mastercard.com/mdes/csapi/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MDES_CUSTOMER_SERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.mastercard.com/mdes/csapi/v2"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accountholdermessaging post" } } | get name | first)
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

# Allows issuers to display customized messages per token within the Apple Pay wallet, below the digitized image of the card.
#
# POST /accountholdermessaging
# --AccountHolderMessagingRequest shape: {AuditInfo: any, IssuerApplicationMessageDisplay: string, MessageExpiration: string, MessageIdentifier: string, MessageLanguageCode: string, MessageText: string, TokenUniqueReference: string}
export def "accountholdermessaging post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-holder-messaging-request: any # shape: {AuditInfo: any, IssuerApplicationMessageDisplay: string, MessageExpiration: string, MessageIdentifier: string, MessageLanguageCode: string, MessageText: string, TokenUniqueReference: string}
]: any -> record<AccountHolderMessagingResponse: record<Token: record<TokenUniqueReference: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accountholdermessaging")
  let body = {"AccountHolderMessagingRequest": $account_holder_messaging_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Provides the ability to search for tokens based on Account PAN, Alternate Account Identifier, Token Unique Reference, Token, Payment App Instance Id or Comment Id. Returns all of the tokens associated with an account according to the scope of the indicated search request criteria. The response includes key state and informational data for each token, including the Token Unique Reference which is needed for subsequent token lifecycle management activities.<br><br>_Notes:_ The Search API request MUST include only one of the available search methods Account PAN, Token Unique Reference, Token, Payment App Instance Id, Comment Id, or Alternate Account Identifier. They cannot be used together in a single request.<br> Moreover, this function only retrieves results if the search criteria matches a current value from the token vault. In other words, if the search criteria is a PAN that has been replaced, the system will not retrieve any data. 
#
# POST /search
# --SearchRequest shape: {AccountPan?: string, AlternateAccountIdentifier?: string, AuditInfo: any, CommentId?: string, ExcludeDeletedIndicator?: "true"|"false", PaymentAppInstanceId?: string, Token?: string, TokenUniqueReference?: string}
export def "search post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-request: any # shape: {AccountPan?: string, AlternateAccountIdentifier?: string, AuditInfo: any, CommentId?: string, ExcludeDeletedIndicator?: "true"|"false", PaymentAppInstanceId?: string, Token?: string, TokenUniqueReference?: string}
]: any -> record<SearchResponse: record<Accounts: record<Account: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search")
  let body = {"SearchRequest": $search_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the overall system status of the Mastercard Digital Enablement Service.
#
# GET /systemstatus
export def "systemstatus get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<SystemStatusResponse: record<CommentText: string, LastStatusDateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/systemstatus")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Used to activate a token for a digitization that has been approved and provisioned, but requires additional cardholder authentication prior to activation. If the provisioning was not completed successfully, activation cannot be accomplished using Customer Service API. It is expected that a cardholder will complete the authentication process using an issuer's call center or using an issuer-supplied mobile application, and only then should the issuer use this API to activate the token.
#
# POST /token/activate
# --TokenActivateRequest shape: {AccountPan?: string, AuditInfo: any, CommentText?: string, PaymentAppInstanceId?: string, ReasonCode: string, TokenUniqueReference?: string}
export def "token-activate post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-activate-request: any # shape: {AccountPan?: string, AuditInfo: any, CommentText?: string, PaymentAppInstanceId?: string, ReasonCode: string, TokenUniqueReference?: string}
]: any -> record<TokenActivateResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token/activate")
  let body = {"TokenActivateRequest": $token_activate_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Used to retrieve the available Activation Methods for a token that is awaiting activation. Activation Methods are the means by which a cardholder may complete cardholder authentication with the issuer beyond the scope of MDES. It is possible that there are no Activation Methods for a token when an issuer did not provide any cardholder-specific information with the Tokenization Authorization Request (TAR) pre-digitization network message response.
#
# POST /token/activationmethods
# --TokenActivationMethodsRequest shape: {AuditInfo?: any, TokenUniqueReference: string}
export def "token-activationmethods post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-activation-methods-request: any # shape: {AuditInfo?: any, TokenUniqueReference: string}
]: any -> record<TokenActivationMethodsResponse: record<ActivationMethods: record<ActivationMethod: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token/activationmethods")
  let body = {"TokenActivationMethodsRequest": $token_activation_methods_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Used to retrieve all comments associated with a token. Typically the response includes comments created earlier by Issuer Customer Service representatives detailing additional information about a particular inquiry or event. There may also be comments with warnings of potential fraud. These comments are created automatically by the MDES system when a Token requestor indicates a high risk of fraud during digitization.
#
# POST /token/comments
# --TokenCommentsRequest shape: {AuditInfo?: any, TokenUniqueReference: string}
export def "token-comments post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-comments-request: any # shape: {AuditInfo?: any, TokenUniqueReference: string}
]: any -> record<TokenCommentsResponse: record<Comments: record<Comment: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token/comments")
  let body = {"TokenCommentsRequest": $token_comments_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Used to delete a token so that it may not initiate any new transactions. All authorizations for a deleted token will be declined. A deleted token may not be returned to an active state.
#
# POST /token/delete
# --TokenDeleteRequest shape: {AuditInfo: any, CommentText?: string, ReasonCode: string, TokenUniqueReference: string}
export def "token-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-delete-request: any # shape: {AuditInfo: any, CommentText?: string, ReasonCode: string, TokenUniqueReference: string}
]: any -> record<TokenDeleteResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token/delete")
  let body = {"TokenDeleteRequest": $token_delete_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Used to trigger the process of generating and sending a new Activation Code (for a specific token) to the cardholder via the requested Activation Method. When successful, a new Activation Code Expiration Date Time period will begin, and a new Activation Code will be sent to the issuer using the Activation Code Notification (ACN) pre-digitization network message. It can only be used to do this for Activation Methods that involve the external distribution of an Activation Code to the cardholder. For example, via email or SMS. It cannot be used to send a new activation code via the "Mobile Application" activation method, for instance. A new Activation Code can be sent even if the previous code has not expired. A new Activation Code can also be sent even after the previous code has expired; however, it can only be done up to 30 days after the token was created  (the number of days is subject to change at the discretion of Mastercard).
#
# POST /token/resendactivationcode
# --TokenResendActivationCodeRequest shape: {ActivationMethodId: string, AuditInfo: any, TokenUniqueReference: string}
export def "token-resendactivationcode post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-resend-activation-code-request: any # shape: {ActivationMethodId: string, AuditInfo: any, TokenUniqueReference: string}
]: any -> record<TokenResendActivationCodeResponse: record<Token: record<TokenUniqueReference: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token/resendactivationcode")
  let body = {"TokenResendActivationCodeRequest": $token_resend_activation_code_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Used to request that the Mobile PIN for a Mastercard Cloud-Based Payment token in a single issuer wallet is reset. The request is passed to the Credential Management System for processing. When the Mobile PIN is a token-level PIN (as opposed to a wallet-level PIN), the cardholder must choose a new PIN within 10 minutes of a Reset Mobile PIN action. Otherwise, the reset will need to be re-requested.
#
# POST /token/resetmobilepin
# --TokenResetMobilePinRequest shape: {AuditInfo: any, CommentText?: string, ReasonCode: string, TokenUniqueReference: string}
export def "token-resetmobilepin post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-reset-mobile-pin-request: any # shape: {AuditInfo: any, CommentText?: string, ReasonCode: string, TokenUniqueReference: string}
]: any -> record<TokenResetMobilePinResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token/resetmobilepin")
  let body = {"TokenResetMobilePinRequest": $token_reset_mobile_pin_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Used to retrieve the historical statuses and lifecycle events for a token, such as when it was initially activated, subsequently suspended or resumed, and finally deleted.
#
# POST /token/statushistory
# --TokenStatusHistoryRequest shape: {AuditInfo?: any, TokenUniqueReference: string}
export def "token-statushistory post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-status-history-request: any # shape: {AuditInfo?: any, TokenUniqueReference: string}
]: any -> record<TokenStatusHistoryResponse: record<Statuses: record<Status: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token/statushistory")
  let body = {"TokenStatusHistoryRequest": $token_status_history_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Used to suspend an active token so that it may not initiate any new transactions. All authorizations for a SUSPENDED token will be declined. Tokens may be suspended by multiple parties (suspenders) concurrently. The token status is updated from ACTIVE to SUSPENDED when the first suspender triggers a suspend action. Additional suspenders can add their suspend action to the list of suspenders. Suspenders can unsuspend only their own suspend action. All suspenders need to perform an unsuspend action to move a token from SUSPENDED to ACTIVE. The token status will only change when the last suspender has unsuspended the token. <br>For CoF tokens, the only two supported suspenders are issuer and token requestor. <br>For Apple Pay tokens, there are some differences in behavior versus the general principles. An issuer may add themselves as a suspender to a token already suspended by a cardholder, as above. However, a cardholder cannot suspend a token already suspended by the issuer. As a special case for Apple Pay, an issuer may unsuspend (override) a token already suspended by a cardholder. However, a cardholder cannot unsuspend a token already suspended by the issuer.
#
# POST /token/suspend
# --TokenSuspendRequest shape: {AuditInfo: any, CommentText?: string, ReasonCode: string, TokenUniqueReference: string}
export def "token-suspend post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-suspend-request: any # shape: {AuditInfo: any, CommentText?: string, ReasonCode: string, TokenUniqueReference: string}
]: any -> record<TokenSuspendResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token/suspend")
  let body = {"TokenSuspendRequest": $token_suspend_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Used to unsuspend or resume a suspended token and return it to the active state where it may initiate new transactions. Tokens may be suspended by multiple parties (suspenders) concurrently. The token status is updated from ACTIVE to SUSPENDED when the first suspender triggers a suspend action. Additional suspenders can add their suspend action to the list of suspenders. Suspenders can unsuspend only their own suspend action. All suspenders need to perform an unsuspend action to move a token from SUSPENDED to ACTIVE. The token status will only change when the last suspender has unsuspended the token. <br>For CoF tokens, the only two supported suspenders are issuer and token requestor.<br>For Apple Pay tokens, there are some differences in behavior versus the general principles. An issuer may add themselves as a suspender to a token already suspended by a cardholder, as above. However, a cardholder cannot suspend a token already suspended by the issuer. As a special case for Apple Pay, an issuer may unsuspend (override) a token already suspended by a cardholder. However, a cardholder cannot unsuspend a token already suspended by the issuer.
#
# POST /token/unsuspend
# --TokenUnsuspendRequest shape: {AuditInfo: any, CommentText?: string, ReasonCode: string, TokenUniqueReference: string}
export def "token-unsuspend post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-unsuspend-request: any # shape: {AuditInfo: any, CommentText?: string, ReasonCode: string, TokenUniqueReference: string}
]: any -> record<TokenUnsuspendResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token/unsuspend")
  let body = {"TokenUnsuspendRequest": $token_unsuspend_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Used to update Account PAN Mapping Information or Issuer Product Configuration ID associated to a provisioned token. To update a specific token, the API should be requested using the Token Unique Reference. To update all tokens mapped to a specific Account PAN, the API should be requested using the Account PAN. In either case, updates will only be applied to tokens in ACTIVE or SUSPENDED state, not those in IN PROGRESS or DELETED state. When updating Account PAN Mapping Information, the Account PAN, Expiration Date and Sequence Number, may be updated individually or in any combination. Only information provided will be updated. The account mapping will only update an Account PAN for a new Account PAN when they are both in the same Account Range.
#
# POST /token/update
# --TokenUpdateRequest shape: {AccountPanSequenceNumber?: string, AuditInfo: any, CommentText?: string, CurrentAccountPan?: string, ExpirationDate?: string, IssuerProductConfigurationId?: string, NewAccountPan?: string, TokenUniqueReference?: string, UpdateWalletProviderIndicator?: string}
export def "token-update post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-update-request: any # shape: {AccountPanSequenceNumber?: string, AuditInfo: any, CommentText?: string, CurrentAccountPan?: string, ExpirationDate?: string, IssuerProductConfigurationId?: string, NewAccountPan?: string, TokenUniqueReference?: string, UpdateWalletProviderIndicator?: string}
]: any -> record<TokenUpdateResponse: record<Tokens: record<Token: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token/update")
  let body = {"TokenUpdateRequest": $token_update_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Used to retrieve transactions performed by a token. It only returns transactions performed within the last 30 days, to help identify a particular token, or to identify a particular recent transaction. It is not intended to provide the full transaction history of a token or Account PAN.<br><br>_Notes:_ The Transaction History API response is not supported for static Card on File (CoF) tokens.<br>If a set of tokens has been re-mapped to a new FPAN, all digital transactions will be made available before or after the FPAN has been updated. MDES does not return the value of the FPAN which was mapped to the particular token at the time of the transaction. However, MDES will return the history of all transactions performed on that particular token in the last 30 days, based on old and/or new FPAN.
#
# POST /transactions
# --TransactionsRequest shape: {AuditInfo: any, TokenUniqueReference: string}
export def "transactions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --transactions-request: any # shape: {AuditInfo: any, TokenUniqueReference: string}
]: any -> record<TransactionsResponse: record<Transactions: record<Transaction: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions")
  let body = {"TransactionsRequest": $transactions_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Used after an issuer has performed additional cardholder authentication to indicate an increased level of token assurance. It will only be applied to tokens that actually have a Token Assurance Level, and those that are in ACTIVE or SUSPENDED state.
#
# POST /updatetokenassurance
# --UpdateTokenAssuranceRequest shape: {AuditInfo: any, CommentText?: string, TokenUniqueReference: string}
export def "updatetokenassurance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-token-assurance-request: any # shape: {AuditInfo: any, CommentText?: string, TokenUniqueReference: string}
]: any -> record<UpdateTokenAssuranceResponse: record<Token: record<CommentId: string, TokenUniqueReference: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/updatetokenassurance")
  let body = {"UpdateTokenAssuranceRequest": $update_token_assurance_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
