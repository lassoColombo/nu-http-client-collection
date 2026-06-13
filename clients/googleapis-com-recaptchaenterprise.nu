# Auto-generated client for reCAPTCHA Enterprise API vv1
# Source: https://api.apis.guru/v2/specs/googleapis.com/recaptchaenterprise/v1/openapi.json
# Auth: --token flag or $env.RECAPTCHA_ENTERPRISE_API_TOKEN

const BASE_URL = "https://recaptchaenterprise.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RECAPTCHA_ENTERPRISE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://recaptchaenterprise.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def annotation-completer [] { ["ANNOTATION_UNSPECIFIED" "FRAUDULENT" "LEGITIMATE" "PASSWORD_CORRECT" "PASSWORD_INCORRECT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "projects recaptchaenterpriseprojectskeysretrieveLegacySecretKey" } } | get name | first)
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

# Returns the secret key related to the specified public key. You must use the legacy secret key only in a 3rd party integration with legacy reCAPTCHA.
#
# GET /v1/{key}:retrieveLegacySecretKey
# operationId: recaptchaenterprise.projects.keys.retrieveLegacySecretKey
export def "projects recaptchaenterpriseprojectskeysretrieveLegacySecretKey" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<legacySecretKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($key):retrieveLegacySecretKey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the specified key.
#
# DELETE /v1/{name}
# operationId: recaptchaenterprise.projects.keys.delete
export def "projects recaptchaenterpriseprojectskeysdelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get some aggregated metrics for a Key. This data can be used to build dashboards.
#
# GET /v1/{name}
# operationId: recaptchaenterprise.projects.keys.getMetrics
export def "projects recaptchaenterpriseprojectskeysgetMetrics" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<challengeMetrics: table<failedCount: string, nocaptchaCount: string, pageloadCount: string, passedCount: string>, name: string, scoreMetrics: table<actionMetrics: record, overallMetrics: record>, startTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the specified key.
#
# PATCH /v1/{name}
# operationId: recaptchaenterprise.projects.keys.patch
# --androidSettings shape: {allowAllPackageNames?: bool, allowedPackageNames?: list, supportNonGoogleAppStoreDistribution?: bool}
# --iosSettings shape: {allowAllBundleIds?: bool, allowedBundleIds?: list}
# --testingOptions shape: {testingChallenge?: "TESTING_CHALLENGE_UNSPECIFIED"|"NOCAPTCHA"|"UNSOLVABLE_CHALLENGE", testingScore?: float}
# --wafSettings shape: {wafFeature?: "WAF_FEATURE_UNSPECIFIED"|"CHALLENGE_PAGE"|"SESSION_TOKEN"|"ACTION_TOKEN"|"EXPRESS", wafService?: "WAF_SERVICE_UNSPECIFIED"|"CA"|"FASTLY"}
# --webSettings shape: {allowAllDomains?: bool, allowAmpTraffic?: bool, allowedDomains?: list, challengeSecurityPreference?: "CHALLENGE_SECURITY_PREFERENCE_UNSPECIFIED"|"USABILITY"|"BALANCE"|"SECURITY", integrationType?: "INTEGRATION_TYPE_UNSPECIFIED"|"SCORE"|"CHECKBOX"|"INVISIBLE"}
export def "projects recaptchaenterpriseprojectskeyspatch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --updateMask: string # Optional. The mask to control which fields of the key get updated. If the mask is not present, all fields will be updated.
  --androidSettings: record # Settings specific to keys that can be used by Android apps. — shape: {allowAllPackageNames?: bool, allowedPackageNames?: list, supportNonGoogleAppStoreDistribution?: bool}
  --displayName: string # Human-readable display name of this key. Modifiable by user.
  --iosSettings: record # Settings specific to keys that can be used by iOS apps. — shape: {allowAllBundleIds?: bool, allowedBundleIds?: list}
  --labels: record # See Creating and managing labels.
  --body-name: string # The resource name for the Key in the format "projects/{project}/keys/{key}".
  --testingOptions: record # Options for user acceptance testing. — shape: {testingChallenge?: "TESTING_CHALLENGE_UNSPECIFIED"|"NOCAPTCHA"|"UNSOLVABLE_CHALLENGE", testingScore?: float}
  --wafSettings: record # Settings specific to keys that can be used for WAF (Web Application Firewall). — shape: {wafFeature?: "WAF_FEATURE_UNSPECIFIED"|"CHALLENGE_PAGE"|"SESSION_TOKEN"|"ACTION_TOKEN"|"EXPRESS", wafService?: "WAF_SERVICE_UNSPECIFIED"|"CA"|"FASTLY"}
  --webSettings: record # Settings specific to keys that can be used by websites. — shape: {allowAllDomains?: bool, allowAmpTraffic?: bool, allowedDomains?: list, challengeSecurityPreference?: "CHALLENGE_SECURITY_PREFERENCE_UNSPECIFIED"|"USABILITY"|"BALANCE"|"SECURITY", integrationType?: "INTEGRATION_TYPE_UNSPECIFIED"|"SCORE"|"CHECKBOX"|"INVISIBLE"}
]: any -> record<androidSettings: record<allowAllPackageNames: bool, allowedPackageNames: list<string>, supportNonGoogleAppStoreDistribution: bool>, createTime: string, displayName: string, iosSettings: record<allowAllBundleIds: bool, allowedBundleIds: list<string>>, labels: record, name: string, testingOptions: record<testingChallenge: string, testingScore: float>, wafSettings: record<wafFeature: string, wafService: string>, webSettings: record<allowAllDomains: bool, allowAmpTraffic: bool, allowedDomains: list<string>, challengeSecurityPreference: string, integrationType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "updateMask" $updateMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name)" $qp)
  let body = {androidSettings: $androidSettings, displayName: $displayName, iosSettings: $iosSettings, labels: $labels, name: $body_name, testingOptions: $testingOptions, wafSettings: $wafSettings, webSettings: $webSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Annotates a previously created Assessment to provide additional information on whether the event turned out to be authentic or fraudulent.
#
# POST /v1/{name}:annotate
# operationId: recaptchaenterprise.projects.assessments.annotate
# --transactionEvent shape: {eventTime?: string, eventType?: "TRANSACTION_EVENT_TYPE_UNSPECIFIED"|"MERCHANT_APPROVE"|"MERCHANT_DENY"|"MANUAL_REVIEW"|"AUTHORIZATION"|"AUTHORIZATION_DECLINE"|"PAYMENT_CAPTURE"|"PAYMENT_CAPTURE_DECLINE"|"CANCEL"|"CHARGEBACK_INQUIRY"|"CHARGEBACK_ALERT"|"FRAUD_NOTIFICATION"|"CHARGEBACK"|"CHARGEBACK_REPRESENTMENT"|"CHARGEBACK_REVERSE"|"REFUND_REQUEST"|"REFUND_DECLINE"|"REFUND"|"REFUND_REVERSE", reason?: string, value?: float}
export def "projects recaptchaenterpriseprojectsassessmentsannotate" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --annotation: string@annotation-completer # Optional. The annotation that will be assigned to the Event. This field can be left empty to provide reasons that apply to an event without concluding whether the event is legitimate or fraudulent.
  --hashedAccountId: string # Optional. Unique stable hashed user identifier to apply to the assessment. This is an alternative to setting the hashed_account_id in CreateAssessment, for example when the account identifier is not yet known in the initial request. It is recommended that the identifier is hashed using hmac-sha256 with stable secret. (format: byte)
  --reasons: list # Optional. Optional reasons for the annotation that will be assigned to the Event.
  --transactionEvent: record # Describes an event in the lifecycle of a payment transaction. — shape: {eventTime?: string, eventType?: "TRANSACTION_EVENT_TYPE_UNSPECIFIED"|"MERCHANT_APPROVE"|"MERCHANT_DENY"|"MANUAL_REVIEW"|"AUTHORIZATION"|"AUTHORIZATION_DECLINE"|"PAYMENT_CAPTURE"|"PAYMENT_CAPTURE_DECLINE"|"CANCEL"|"CHARGEBACK_INQUIRY"|"CHARGEBACK_ALERT"|"FRAUD_NOTIFICATION"|"CHARGEBACK"|"CHARGEBACK_REPRESENTMENT"|"CHARGEBACK_REVERSE"|"REFUND_REQUEST"|"REFUND_DECLINE"|"REFUND"|"REFUND_REVERSE", reason?: string, value?: float}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name):annotate" $qp)
  let body = {annotation: $annotation, hashedAccountId: $hashedAccountId, reasons: $reasons, transactionEvent: $transactionEvent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Migrates an existing key from reCAPTCHA to reCAPTCHA Enterprise. Once a key is migrated, it can be used from either product. SiteVerify requests are billed as CreateAssessment calls. You must be authenticated as one of the current owners of the reCAPTCHA Site Key, and your user must have the reCAPTCHA Enterprise Admin IAM role in the destination project.
#
# POST /v1/{name}:migrate
# operationId: recaptchaenterprise.projects.keys.migrate
export def "projects recaptchaenterpriseprojectskeysmigrate" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --skipBillingCheck: oneof<nothing, bool> # Optional. If true, skips the billing check. A reCAPTCHA Enterprise key or migrated key behaves differently than a reCAPTCHA (non-Enterprise version) key when you reach a quota limit (see https://cloud.google.com/recaptcha-enterprise/quotas#quota_limit). To avoid any disruption of your usage, we check that a billing account is present. If your usage of reCAPTCHA is under the free quota, you can safely skip the billing check and proceed with the migration. See https://cloud.google.com/recaptcha-enterprise/docs/billing-information.
]: any -> record<androidSettings: record<allowAllPackageNames: bool, allowedPackageNames: list<string>, supportNonGoogleAppStoreDistribution: bool>, createTime: string, displayName: string, iosSettings: record<allowAllBundleIds: bool, allowedBundleIds: list<string>>, labels: record, name: string, testingOptions: record<testingChallenge: string, testingScore: float>, wafSettings: record<wafFeature: string, wafService: string>, webSettings: record<allowAllDomains: bool, allowAmpTraffic: bool, allowedDomains: list<string>, challengeSecurityPreference: string, integrationType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name):migrate" $qp)
  let body = {skipBillingCheck: $skipBillingCheck} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates an Assessment of the likelihood an event is legitimate.
#
# POST /v1/{parent}/assessments
# operationId: recaptchaenterprise.projects.assessments.create
# --accountDefenderAssessment shape: {labels?: list}
# --accountVerification shape: {endpoints?: list, languageCode?: string, username?: string}
# --event shape: {expectedAction?: string, express?: bool, firewallPolicyEvaluation?: bool, hashedAccountId?: string, headers?: list, ja3?: string, requestedUri?: string, siteKey?: string, token?: string, transactionData?: record, userAgent?: string, userIpAddress?: string, wafTokenAssessment?: bool}
# --firewallPolicyAssessment shape: {error?: record, firewallPolicy?: record}
# --fraudPreventionAssessment shape: {behavioralTrustVerdict?: record, cardTestingVerdict?: record, stolenInstrumentVerdict?: record, transactionRisk?: float}
# --privatePasswordLeakVerification shape: {encryptedUserCredentialsHash?: string, lookupHashPrefix?: string}
# --riskAnalysis shape: {extendedVerdictReasons?: list, reasons?: list, score?: float}
# --tokenProperties shape: {action?: string, androidPackageName?: string, createTime?: string, hostname?: string, invalidReason?: "INVALID_REASON_UNSPECIFIED"|"UNKNOWN_INVALID_REASON"|"MALFORMED"|"EXPIRED"|"DUPE"|"MISSING"|"BROWSER_ERROR", iosBundleId?: string, valid?: bool}
export def "assessments recaptchaenterpriseprojectsassessmentscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --accountDefenderAssessment: record # Account defender risk assessment. — shape: {labels?: list}
  --accountVerification: record # Information about account verification, used for identity verification. — shape: {endpoints?: list, languageCode?: string, username?: string}
  --event: record # The event being assessed. — shape: {expectedAction?: string, express?: bool, firewallPolicyEvaluation?: bool, hashedAccountId?: string, headers?: list, ja3?: string, requestedUri?: string, siteKey?: string, token?: string, transactionData?: record, userAgent?: string, userIpAddress?: string, wafTokenAssessment?: bool}
  --firewallPolicyAssessment: record # Policy config assessment. — shape: {error?: record, firewallPolicy?: record}
  --fraudPreventionAssessment: record # Assessment for Fraud Prevention. — shape: {behavioralTrustVerdict?: record, cardTestingVerdict?: record, stolenInstrumentVerdict?: record, transactionRisk?: float}
  --privatePasswordLeakVerification: record # Private password leak verification info. — shape: {encryptedUserCredentialsHash?: string, lookupHashPrefix?: string}
  --riskAnalysis: record # Risk analysis result for an event. — shape: {extendedVerdictReasons?: list, reasons?: list, score?: float}
  --tokenProperties: record # Properties of the provided event token. — shape: {action?: string, androidPackageName?: string, createTime?: string, hostname?: string, invalidReason?: "INVALID_REASON_UNSPECIFIED"|"UNKNOWN_INVALID_REASON"|"MALFORMED"|"EXPIRED"|"DUPE"|"MISSING"|"BROWSER_ERROR", iosBundleId?: string, valid?: bool}
]: any -> record<accountDefenderAssessment: record<labels: list<string>>, accountVerification: record<endpoints: list<record>, languageCode: string, latestVerificationResult: string, username: string>, event: record<expectedAction: string, express: bool, firewallPolicyEvaluation: bool, hashedAccountId: string, headers: list<string>, ja3: string, requestedUri: string, siteKey: string, token: string, transactionData: record<billingAddress: record, cardBin: string, cardLastFour: string, currencyCode: string, gatewayInfo: record, items: list, merchants: list, paymentMethod: string, shippingAddress: record, shippingValue: float, transactionId: string, user: record, value: float>, userAgent: string, userIpAddress: string, wafTokenAssessment: bool>, firewallPolicyAssessment: record<error: record<code: int, details: list, message: string>, firewallPolicy: record<actions: list, condition: string, description: string, name: string, path: string>>, fraudPreventionAssessment: record<behavioralTrustVerdict: record<trust: float>, cardTestingVerdict: record<risk: float>, stolenInstrumentVerdict: record<risk: float>, transactionRisk: float>, name: string, privatePasswordLeakVerification: record<encryptedLeakMatchPrefixes: list<string>, encryptedUserCredentialsHash: string, lookupHashPrefix: string, reencryptedUserCredentialsHash: string>, riskAnalysis: record<extendedVerdictReasons: list<string>, reasons: list<string>, score: float>, tokenProperties: record<action: string, androidPackageName: string, createTime: string, hostname: string, invalidReason: string, iosBundleId: string, valid: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/assessments" $qp)
  let body = {accountDefenderAssessment: $accountDefenderAssessment, accountVerification: $accountVerification, event: $event, firewallPolicyAssessment: $firewallPolicyAssessment, fraudPreventionAssessment: $fraudPreventionAssessment, privatePasswordLeakVerification: $privatePasswordLeakVerification, riskAnalysis: $riskAnalysis, tokenProperties: $tokenProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the list of all firewall policies that belong to a project.
#
# GET /v1/{parent}/firewallpolicies
# operationId: recaptchaenterprise.projects.firewallpolicies.list
export def "firewallpolicies recaptchaenterpriseprojectsfirewallpolicieslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Optional. The maximum number of policies to return. Default is 10. Max limit is 1000.
  --pageToken: string # Optional. The next_page_token value returned from a previous. ListFirewallPoliciesRequest, if any.
]: nothing -> record<firewallPolicies: table<actions: list, condition: string, description: string, name: string, path: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/firewallpolicies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new FirewallPolicy, specifying conditions at which reCAPTCHA Enterprise actions can be executed. A project may have a maximum of 1000 policies.
#
# POST /v1/{parent}/firewallpolicies
# operationId: recaptchaenterprise.projects.firewallpolicies.create
# --actions item shape: {allow?: record, block?: record, redirect?: record, setHeader?: record, substitute?: record}
export def "firewallpolicies recaptchaenterpriseprojectsfirewallpoliciescreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --actions: list # The actions that the caller should take regarding user access. There should be at most one terminal action. A terminal action is any action that forces a response, such as AllowAction, BlockAction or SubstituteAction. Zero or more non-terminal actions such as SetHeader might be specified. A single policy can contain up to 16 actions. — item shape: {allow?: record, block?: record, redirect?: record, setHeader?: record, substitute?: record}
  --condition: string # A CEL (Common Expression Language) conditional expression that specifies if this policy applies to an incoming user request. If this condition evaluates to true and the requested path matched the path pattern, the associated actions should be executed by the caller. The condition string is checked for CEL syntax correctness on creation. For more information, see the [CEL spec](https://github.com/google/cel-spec) and its [language definition](https://github.com/google/cel-spec/blob/master/doc/langdef.md). A condition has a max length of 500 characters.
  --description: string # A description of what this policy aims to achieve, for convenience purposes. The description can at most include 256 UTF-8 characters.
  --name: string # The resource name for the FirewallPolicy in the format "projects/{project}/firewallpolicies/{firewallpolicy}".
  --path: string # The path for which this policy applies, specified as a glob pattern. For more information on glob, see the [manual page](https://man7.org/linux/man-pages/man7/glob.7.html). A path has a max length of 200 characters.
]: any -> record<actions: table<allow: record, block: record, redirect: record, setHeader: record, substitute: record>, condition: string, description: string, name: string, path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/firewallpolicies" $qp)
  let body = {actions: $actions, condition: $condition, description: $description, name: $name, path: $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the list of all keys that belong to a project.
#
# GET /v1/{parent}/keys
# operationId: recaptchaenterprise.projects.keys.list
export def "keys recaptchaenterpriseprojectskeyslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Optional. The maximum number of keys to return. Default is 10. Max limit is 1000.
  --pageToken: string # Optional. The next_page_token value returned from a previous. ListKeysRequest, if any.
]: nothing -> record<keys: table<androidSettings: record, createTime: string, displayName: string, iosSettings: record, labels: record, name: string, testingOptions: record, wafSettings: record, webSettings: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new reCAPTCHA Enterprise key.
#
# POST /v1/{parent}/keys
# operationId: recaptchaenterprise.projects.keys.create
# --androidSettings shape: {allowAllPackageNames?: bool, allowedPackageNames?: list, supportNonGoogleAppStoreDistribution?: bool}
# --iosSettings shape: {allowAllBundleIds?: bool, allowedBundleIds?: list}
# --testingOptions shape: {testingChallenge?: "TESTING_CHALLENGE_UNSPECIFIED"|"NOCAPTCHA"|"UNSOLVABLE_CHALLENGE", testingScore?: float}
# --wafSettings shape: {wafFeature?: "WAF_FEATURE_UNSPECIFIED"|"CHALLENGE_PAGE"|"SESSION_TOKEN"|"ACTION_TOKEN"|"EXPRESS", wafService?: "WAF_SERVICE_UNSPECIFIED"|"CA"|"FASTLY"}
# --webSettings shape: {allowAllDomains?: bool, allowAmpTraffic?: bool, allowedDomains?: list, challengeSecurityPreference?: "CHALLENGE_SECURITY_PREFERENCE_UNSPECIFIED"|"USABILITY"|"BALANCE"|"SECURITY", integrationType?: "INTEGRATION_TYPE_UNSPECIFIED"|"SCORE"|"CHECKBOX"|"INVISIBLE"}
export def "keys recaptchaenterpriseprojectskeyscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --androidSettings: record # Settings specific to keys that can be used by Android apps. — shape: {allowAllPackageNames?: bool, allowedPackageNames?: list, supportNonGoogleAppStoreDistribution?: bool}
  --displayName: string # Human-readable display name of this key. Modifiable by user.
  --iosSettings: record # Settings specific to keys that can be used by iOS apps. — shape: {allowAllBundleIds?: bool, allowedBundleIds?: list}
  --labels: record # See Creating and managing labels.
  --name: string # The resource name for the Key in the format "projects/{project}/keys/{key}".
  --testingOptions: record # Options for user acceptance testing. — shape: {testingChallenge?: "TESTING_CHALLENGE_UNSPECIFIED"|"NOCAPTCHA"|"UNSOLVABLE_CHALLENGE", testingScore?: float}
  --wafSettings: record # Settings specific to keys that can be used for WAF (Web Application Firewall). — shape: {wafFeature?: "WAF_FEATURE_UNSPECIFIED"|"CHALLENGE_PAGE"|"SESSION_TOKEN"|"ACTION_TOKEN"|"EXPRESS", wafService?: "WAF_SERVICE_UNSPECIFIED"|"CA"|"FASTLY"}
  --webSettings: record # Settings specific to keys that can be used by websites. — shape: {allowAllDomains?: bool, allowAmpTraffic?: bool, allowedDomains?: list, challengeSecurityPreference?: "CHALLENGE_SECURITY_PREFERENCE_UNSPECIFIED"|"USABILITY"|"BALANCE"|"SECURITY", integrationType?: "INTEGRATION_TYPE_UNSPECIFIED"|"SCORE"|"CHECKBOX"|"INVISIBLE"}
]: any -> record<androidSettings: record<allowAllPackageNames: bool, allowedPackageNames: list<string>, supportNonGoogleAppStoreDistribution: bool>, createTime: string, displayName: string, iosSettings: record<allowAllBundleIds: bool, allowedBundleIds: list<string>>, labels: record, name: string, testingOptions: record<testingChallenge: string, testingScore: float>, wafSettings: record<wafFeature: string, wafService: string>, webSettings: record<allowAllDomains: bool, allowAmpTraffic: bool, allowedDomains: list<string>, challengeSecurityPreference: string, integrationType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/keys" $qp)
  let body = {androidSettings: $androidSettings, displayName: $displayName, iosSettings: $iosSettings, labels: $labels, name: $name, testingOptions: $testingOptions, wafSettings: $wafSettings, webSettings: $webSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get memberships in a group of related accounts.
#
# GET /v1/{parent}/memberships
# operationId: recaptchaenterprise.projects.relatedaccountgroups.memberships.list
export def "memberships recaptchaenterpriseprojectsrelatedaccountgroupsmembershipslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Optional. The maximum number of accounts to return. The service might return fewer than this value. If unspecified, at most 50 accounts are returned. The maximum value is 1000; values above 1000 are coerced to 1000.
  --pageToken: string # Optional. A page token, received from a previous `ListRelatedAccountGroupMemberships` call. When paginating, all other parameters provided to `ListRelatedAccountGroupMemberships` must match the call that provided the page token.
]: nothing -> record<nextPageToken: string, relatedAccountGroupMemberships: table<hashedAccountId: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List groups of related accounts.
#
# GET /v1/{parent}/relatedaccountgroups
# operationId: recaptchaenterprise.projects.relatedaccountgroups.list
export def "relatedaccountgroups recaptchaenterpriseprojectsrelatedaccountgroupslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Optional. The maximum number of groups to return. The service might return fewer than this value. If unspecified, at most 50 groups are returned. The maximum value is 1000; values above 1000 are coerced to 1000.
  --pageToken: string # Optional. A page token, received from a previous `ListRelatedAccountGroups` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListRelatedAccountGroups` must match the call that provided the page token.
]: nothing -> record<nextPageToken: string, relatedAccountGroups: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/relatedaccountgroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search group memberships related to a given account.
#
# POST /v1/{project}/relatedaccountgroupmemberships:search
# operationId: recaptchaenterprise.projects.relatedaccountgroupmemberships.search
export def "relatedaccountgroupmemberships-search recaptchaenterpriseprojectsrelatedaccountgroupmembershipssearch" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --hashedAccountId: string # Optional. The unique stable hashed user identifier we should search connections to. The identifier should correspond to a `hashed_account_id` provided in a previous `CreateAssessment` or `AnnotateAssessment` call. (format: byte)
  --pageSize: int # Optional. The maximum number of groups to return. The service might return fewer than this value. If unspecified, at most 50 groups are returned. The maximum value is 1000; values above 1000 are coerced to 1000. (format: int32)
  --pageToken: string # Optional. A page token, received from a previous `SearchRelatedAccountGroupMemberships` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `SearchRelatedAccountGroupMemberships` must match the call that provided the page token.
]: any -> record<nextPageToken: string, relatedAccountGroupMemberships: table<hashedAccountId: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($project)/relatedaccountgroupmemberships:search" $qp)
  let body = {hashedAccountId: $hashedAccountId, pageSize: $pageSize, pageToken: $pageToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
