# Auto-generated client for Amazon Pinpoint v2016-12-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/pinpoint/2016-12-01/openapi.json
# Auth: --token flag or $env.AMAZON_PINPOINT_TOKEN

const BASE_URL = "http://pinpoint.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_PINPOINT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["http://pinpoint.us-east-1.amazonaws.com" "http://pinpoint.us-east-2.amazonaws.com" "http://pinpoint.us-west-1.amazonaws.com" "http://pinpoint.us-west-2.amazonaws.com" "http://pinpoint.us-gov-west-1.amazonaws.com" "http://pinpoint.us-gov-east-1.amazonaws.com" "http://pinpoint.ca-central-1.amazonaws.com" "http://pinpoint.eu-north-1.amazonaws.com" "http://pinpoint.eu-west-1.amazonaws.com" "http://pinpoint.eu-west-2.amazonaws.com" "http://pinpoint.eu-west-3.amazonaws.com" "http://pinpoint.eu-central-1.amazonaws.com" "http://pinpoint.eu-south-1.amazonaws.com" "http://pinpoint.af-south-1.amazonaws.com" "http://pinpoint.ap-northeast-1.amazonaws.com" "http://pinpoint.ap-northeast-2.amazonaws.com" "http://pinpoint.ap-northeast-3.amazonaws.com" "http://pinpoint.ap-southeast-1.amazonaws.com" "http://pinpoint.ap-southeast-2.amazonaws.com" "http://pinpoint.ap-east-1.amazonaws.com" "http://pinpoint.ap-south-1.amazonaws.com" "http://pinpoint.sa-east-1.amazonaws.com" "http://pinpoint.me-south-1.amazonaws.com" "https://pinpoint.us-east-1.amazonaws.com" "https://pinpoint.us-east-2.amazonaws.com" "https://pinpoint.us-west-1.amazonaws.com" "https://pinpoint.us-west-2.amazonaws.com" "https://pinpoint.us-gov-west-1.amazonaws.com" "https://pinpoint.us-gov-east-1.amazonaws.com" "https://pinpoint.ca-central-1.amazonaws.com" "https://pinpoint.eu-north-1.amazonaws.com" "https://pinpoint.eu-west-1.amazonaws.com" "https://pinpoint.eu-west-2.amazonaws.com" "https://pinpoint.eu-west-3.amazonaws.com" "https://pinpoint.eu-central-1.amazonaws.com" "https://pinpoint.eu-south-1.amazonaws.com" "https://pinpoint.af-south-1.amazonaws.com" "https://pinpoint.ap-northeast-1.amazonaws.com" "https://pinpoint.ap-northeast-2.amazonaws.com" "https://pinpoint.ap-northeast-3.amazonaws.com" "https://pinpoint.ap-southeast-1.amazonaws.com" "https://pinpoint.ap-southeast-2.amazonaws.com" "https://pinpoint.ap-east-1.amazonaws.com" "https://pinpoint.ap-south-1.amazonaws.com" "https://pinpoint.sa-east-1.amazonaws.com" "https://pinpoint.me-south-1.amazonaws.com" "http://pinpoint.cn-north-1.amazonaws.com.cn" "http://pinpoint.cn-northwest-1.amazonaws.com.cn" "https://pinpoint.cn-north-1.amazonaws.com.cn" "https://pinpoint.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apps create" } } | get name | first)
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

# Creates an application.
#
# POST /v1/apps
# operationId: CreateApp
# --CreateApplicationRequest shape: {Name?: any, tags?: any}
export def "apps create" [
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
  create_application_request: record # Specifies the display name of an application and the tags to associate with the application. — shape: {Name?: any, tags?: any}
]: any -> record<ApplicationResponse: record<Arn: record, Id: record, Name: record, tags: record, CreationDate: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/apps")
  let req_body = {"CreateApplicationRequest": $create_application_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves information about all the applications that are associated with your Amazon Pinpoint account.
#
# GET /v1/apps
# operationId: GetApps
export def "apps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ApplicationsResponse: record<Item: record, NextToken: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page-size" $page_size "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page-size": $page_size, "token": $qp_token} | compact), body: null}
}

# Creates a new campaign for an application or updates the settings of an existing campaign for an application.
#
# POST /v1/apps/{application-id}/campaigns
# operationId: CreateCampaign
# --WriteCampaignRequest shape: {AdditionalTreatments?: any, CustomDeliveryConfiguration?: any, Description?: any, HoldoutPercent?: any, Hook?: any, IsPaused?: any, Limits?: any, MessageConfiguration?: any, Name?: any, Schedule?: any, SegmentId?: any, SegmentVersion?: any, tags?: any, TemplateConfiguration?: any, TreatmentDescription?: any, TreatmentName?: any, Priority?: any}
export def "apps-campaigns create" [
  application_id: string
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
  write_campaign_request: record # Specifies the configuration and other settings for a campaign. — shape: {AdditionalTreatments?: any, CustomDeliveryConfiguration?: any, Description?: any, HoldoutPercent?: any, Hook?: any, IsPaused?: any, Limits?: any, MessageConfiguration?: any, Name?: any, Schedule?: any, SegmentId?: any, SegmentVersion?: any, tags?: any, TemplateConfiguration?: any, TreatmentDescription?: any, TreatmentName?: any, Priority?: any}
]: any -> record<CampaignResponse: record<AdditionalTreatments: record, ApplicationId: record, Arn: record, CreationDate: record, CustomDeliveryConfiguration: record<DeliveryUri: record, EndpointTypes: record>, DefaultState: record<CampaignStatus: record>, Description: record, HoldoutPercent: record, Hook: record<LambdaFunctionName: record, Mode: record, WebUrl: record>, Id: record, IsPaused: record, LastModifiedDate: record, Limits: record<Daily: record, MaximumDuration: record, MessagesPerSecond: record, Total: record, Session: record>, MessageConfiguration: record<ADMMessage: record, APNSMessage: record, BaiduMessage: record, CustomMessage: record, DefaultMessage: record, EmailMessage: record, GCMMessage: record, SMSMessage: record, InAppMessage: record>, Name: record, Schedule: record<EndTime: record, EventFilter: record, Frequency: record, IsLocalTime: record, QuietTime: record, StartTime: record, Timezone: record>, SegmentId: record, SegmentVersion: record, State: record<CampaignStatus: record>, tags: record, TemplateConfiguration: record<EmailTemplate: record, PushTemplate: record, SMSTemplate: record, VoiceTemplate: record>, TreatmentDescription: record, TreatmentName: record, Version: record, Priority: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/campaigns"))
  let req_body = {"WriteCampaignRequest": $write_campaign_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
#
# GET /v1/apps/{application-id}/campaigns
# operationId: GetCampaigns
export def "apps-campaigns list" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<CampaignsResponse: record<Item: record, NextToken: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let qp = [(serialize-qp "page-size" $page_size "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/campaigns") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page-size": $page_size, "token": $qp_token} | compact), body: null}
}

# Creates a message template for messages that are sent through the email channel.
#
# POST /v1/templates/{template-name}/email
# operationId: CreateEmailTemplate
# --EmailTemplateRequest shape: {DefaultSubstitutions?: any, HtmlPart?: any, RecommenderId?: any, Subject?: any, tags?: any, TemplateDescription?: any, TextPart?: any}
export def "templates-email create" [
  template_name: string
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
  email_template_request: record # Specifies the content and settings for a message template that can be used in messages that are sent through the email channel. — shape: {DefaultSubstitutions?: any, HtmlPart?: any, RecommenderId?: any, Subject?: any, tags?: any, TemplateDescription?: any, TextPart?: any}
]: any -> record<CreateTemplateMessageBody: record<Arn: record, Message: record, RequestID: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/email"))
  let req_body = {"EmailTemplateRequest": $email_template_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a message template for messages that were sent through the email channel.
#
# DELETE /v1/templates/{template-name}/email
# operationId: DeleteEmailTemplate
export def "templates-email delete" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<MessageBody: record<Message: record, RequestID: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/email") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version} | compact), body: null}
}

# Retrieves the content and settings of a message template for messages that are sent through the email channel.
#
# GET /v1/templates/{template-name}/email
# operationId: GetEmailTemplate
export def "templates-email get" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<EmailTemplateResponse: record<Arn: record, CreationDate: record, DefaultSubstitutions: record, HtmlPart: record, LastModifiedDate: record, RecommenderId: record, Subject: record, tags: record, TemplateDescription: record, TemplateName: record, TemplateType: record, TextPart: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/email") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version} | compact), body: null}
}

# Updates an existing message template for messages that are sent through the email channel.
#
# PUT /v1/templates/{template-name}/email
# operationId: UpdateEmailTemplate
# --EmailTemplateRequest shape: {DefaultSubstitutions?: any, HtmlPart?: any, RecommenderId?: any, Subject?: any, tags?: any, TemplateDescription?: any, TextPart?: any}
export def "templates-email update" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-new-version: oneof<nothing, bool> # Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to (overwrite) the latest existing version of the template. If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to (overwrites) the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  email_template_request: record # Specifies the content and settings for a message template that can be used in messages that are sent through the email channel. — shape: {DefaultSubstitutions?: any, HtmlPart?: any, RecommenderId?: any, Subject?: any, tags?: any, TemplateDescription?: any, TextPart?: any}
]: any -> record<MessageBody: record<Message: record, RequestID: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let qp = [(serialize-qp "create-new-version" $create_new_version "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/email") $qp)
  let req_body = {"EmailTemplateRequest": $email_template_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"create-new-version": $create_new_version, "version": $version} | compact), body: $req_body}
}

# Creates an export job for an application.
#
# POST /v1/apps/{application-id}/jobs/export
# operationId: CreateExportJob
# --ExportJobRequest shape: {RoleArn?: any, S3UrlPrefix?: any, SegmentId?: any, SegmentVersion?: any}
export def "apps-jobs-export create" [
  application_id: string
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
  export_job_request: record # Specifies the settings for a job that exports endpoint definitions to an Amazon Simple Storage Service (Amazon S3) bucket. — shape: {RoleArn?: any, S3UrlPrefix?: any, SegmentId?: any, SegmentVersion?: any}
]: any -> record<ExportJobResponse: record<ApplicationId: record, CompletedPieces: record, CompletionDate: record, CreationDate: record, Definition: record<RoleArn: record, S3UrlPrefix: record, SegmentId: record, SegmentVersion: record>, FailedPieces: record, Failures: record, Id: record, JobStatus: record, TotalFailures: record, TotalPieces: record, TotalProcessed: record, Type: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/jobs/export"))
  let req_body = {"ExportJobRequest": $export_job_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves information about the status and settings of all the export jobs for an application.
#
# GET /v1/apps/{application-id}/jobs/export
# operationId: GetExportJobs
export def "apps-jobs-export list" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ExportJobsResponse: record<Item: record, NextToken: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let qp = [(serialize-qp "page-size" $page_size "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/jobs/export") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page-size": $page_size, "token": $qp_token} | compact), body: null}
}

# Creates an import job for an application.
#
# POST /v1/apps/{application-id}/jobs/import
# operationId: CreateImportJob
# --ImportJobRequest shape: {DefineSegment?: any, ExternalId?: any, Format?: any, RegisterEndpoints?: any, RoleArn?: any, S3Url?: any, SegmentId?: any, SegmentName?: any}
export def "apps-jobs-import create" [
  application_id: string
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
  import_job_request: record # Specifies the settings for a job that imports endpoint definitions from an Amazon Simple Storage Service (Amazon S3) bucket. — shape: {DefineSegment?: any, ExternalId?: any, Format?: any, RegisterEndpoints?: any, RoleArn?: any, S3Url?: any, SegmentId?: any, SegmentName?: any}
]: any -> record<ImportJobResponse: record<ApplicationId: record, CompletedPieces: record, CompletionDate: record, CreationDate: record, Definition: record<DefineSegment: record, ExternalId: record, Format: record, RegisterEndpoints: record, RoleArn: record, S3Url: record, SegmentId: record, SegmentName: record>, FailedPieces: record, Failures: record, Id: record, JobStatus: record, TotalFailures: record, TotalPieces: record, TotalProcessed: record, Type: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/jobs/import"))
  let req_body = {"ImportJobRequest": $import_job_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves information about the status and settings of all the import jobs for an application.
#
# GET /v1/apps/{application-id}/jobs/import
# operationId: GetImportJobs
export def "apps-jobs-import list" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ImportJobsResponse: record<Item: record, NextToken: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let qp = [(serialize-qp "page-size" $page_size "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/jobs/import") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page-size": $page_size, "token": $qp_token} | compact), body: null}
}

# Creates a new message template for messages using the in-app message channel.
#
# POST /v1/templates/{template-name}/inapp
# operationId: CreateInAppTemplate
# --InAppTemplateRequest shape: {Content?: any, CustomConfig?: any, Layout?: any, tags?: any, TemplateDescription?: any}
export def "templates-inapp create-in-app" [
  template_name: string
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
  in_app_template_request: record # InApp Template Request. — shape: {Content?: any, CustomConfig?: any, Layout?: any, tags?: any, TemplateDescription?: any}
]: any -> record<TemplateCreateMessageBody: record<Arn: record, Message: record, RequestID: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/inapp"))
  let req_body = {"InAppTemplateRequest": $in_app_template_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a message template for messages sent using the in-app message channel.
#
# DELETE /v1/templates/{template-name}/inapp
# operationId: DeleteInAppTemplate
export def "templates-inapp delete-in-app" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<MessageBody: record<Message: record, RequestID: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/inapp") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version} | compact), body: null}
}

# Retrieves the content and settings of a message template for messages sent through the in-app channel.
#
# GET /v1/templates/{template-name}/inapp
# operationId: GetInAppTemplate
export def "templates-inapp get-in-app" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<InAppTemplateResponse: record<Arn: record, Content: record, CreationDate: record, CustomConfig: record, LastModifiedDate: record, Layout: record, tags: record, TemplateDescription: record, TemplateName: record, TemplateType: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/inapp") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version} | compact), body: null}
}

# Updates an existing message template for messages sent through the in-app message channel.
#
# PUT /v1/templates/{template-name}/inapp
# operationId: UpdateInAppTemplate
# --InAppTemplateRequest shape: {Content?: any, CustomConfig?: any, Layout?: any, tags?: any, TemplateDescription?: any}
export def "templates-inapp update-in-app" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-new-version: oneof<nothing, bool> # Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to (overwrite) the latest existing version of the template. If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to (overwrites) the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  in_app_template_request: record # InApp Template Request. — shape: {Content?: any, CustomConfig?: any, Layout?: any, tags?: any, TemplateDescription?: any}
]: any -> record<MessageBody: record<Message: record, RequestID: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let qp = [(serialize-qp "create-new-version" $create_new_version "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/inapp") $qp)
  let req_body = {"InAppTemplateRequest": $in_app_template_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"create-new-version": $create_new_version, "version": $version} | compact), body: $req_body}
}

# Creates a journey for an application.
#
# POST /v1/apps/{application-id}/journeys
# operationId: CreateJourney
# --WriteJourneyRequest shape: {Activities?: any, CreationDate?: any, LastModifiedDate?: any, Limits?: any, LocalTime?: any, Name?: any, QuietTime?: any, RefreshFrequency?: any, Schedule?: any, StartActivity?: any, StartCondition?: any, State?: any, WaitForQuietTime?: any, RefreshOnSegmentUpdate?: any, JourneyChannelSettings?: any, SendingSchedule?: any, OpenHours?: any, ClosedDays?: any}
export def "apps-journeys create" [
  application_id: string
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
  write_journey_request: record # Specifies the configuration and other settings for a journey. — shape: {Activities?: any, CreationDate?: any, LastModifiedDate?: any, Limits?: any, LocalTime?: any, Name?: any, QuietTime?: any, RefreshFrequency?: any, Schedule?: any, StartActivity?: any, StartCondition?: any, State?: any, WaitForQuietTime?: any, RefreshOnSegmentUpdate?: any, JourneyChannelSettings?: any, SendingSchedule?: any, OpenHours?: any, ClosedDays?: any}
]: any -> record<JourneyResponse: record<Activities: record, ApplicationId: record, CreationDate: record, Id: record, LastModifiedDate: record, Limits: record<DailyCap: record, EndpointReentryCap: record, MessagesPerSecond: record, EndpointReentryInterval: record>, LocalTime: record, Name: record, QuietTime: record<End: record, Start: record>, RefreshFrequency: record, Schedule: record<EndTime: record, StartTime: record, Timezone: record>, StartActivity: record, StartCondition: record<Description: record, EventStartCondition: record, SegmentStartCondition: record>, State: record, tags: record, WaitForQuietTime: record, RefreshOnSegmentUpdate: record, JourneyChannelSettings: record<ConnectCampaignArn: record, ConnectCampaignExecutionRoleArn: record>, SendingSchedule: record, OpenHours: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>, ClosedDays: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/journeys"))
  let req_body = {"WriteJourneyRequest": $write_journey_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
#
# GET /v1/apps/{application-id}/journeys
# operationId: ListJourneys
export def "apps-journeys list" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<JourneysResponse: record<Item: record, NextToken: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let qp = [(serialize-qp "page-size" $page_size "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/journeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page-size": $page_size, "token": $qp_token} | compact), body: null}
}

# Creates a message template for messages that are sent through a push notification channel.
#
# POST /v1/templates/{template-name}/push
# operationId: CreatePushTemplate
# --PushNotificationTemplateRequest shape: {ADM?: any, APNS?: any, Baidu?: any, Default?: any, DefaultSubstitutions?: any, GCM?: any, RecommenderId?: any, tags?: any, TemplateDescription?: any}
export def "templates-push create" [
  template_name: string
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
  push_notification_template_request: record # Specifies the content and settings for a message template that can be used in messages that are sent through a push notification channel. — shape: {ADM?: any, APNS?: any, Baidu?: any, Default?: any, DefaultSubstitutions?: any, GCM?: any, RecommenderId?: any, tags?: any, TemplateDescription?: any}
]: any -> record<CreateTemplateMessageBody: record<Arn: record, Message: record, RequestID: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/push"))
  let req_body = {"PushNotificationTemplateRequest": $push_notification_template_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a message template for messages that were sent through a push notification channel.
#
# DELETE /v1/templates/{template-name}/push
# operationId: DeletePushTemplate
export def "templates-push delete" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<MessageBody: record<Message: record, RequestID: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/push") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version} | compact), body: null}
}

# Retrieves the content and settings of a message template for messages that are sent through a push notification channel.
#
# GET /v1/templates/{template-name}/push
# operationId: GetPushTemplate
export def "templates-push get" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<PushNotificationTemplateResponse: record<ADM: record<Action: record, Body: record, ImageIconUrl: record, ImageUrl: record, RawContent: record, SmallImageIconUrl: record, Sound: record, Title: record, Url: record>, APNS: record<Action: record, Body: record, MediaUrl: record, RawContent: record, Sound: record, Title: record, Url: record>, Arn: record, Baidu: record<Action: record, Body: record, ImageIconUrl: record, ImageUrl: record, RawContent: record, SmallImageIconUrl: record, Sound: record, Title: record, Url: record>, CreationDate: record, Default: record<Action: record, Body: record, Sound: record, Title: record, Url: record>, DefaultSubstitutions: record, GCM: record<Action: record, Body: record, ImageIconUrl: record, ImageUrl: record, RawContent: record, SmallImageIconUrl: record, Sound: record, Title: record, Url: record>, LastModifiedDate: record, RecommenderId: record, tags: record, TemplateDescription: record, TemplateName: record, TemplateType: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/push") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version} | compact), body: null}
}

# Updates an existing message template for messages that are sent through a push notification channel.
#
# PUT /v1/templates/{template-name}/push
# operationId: UpdatePushTemplate
# --PushNotificationTemplateRequest shape: {ADM?: any, APNS?: any, Baidu?: any, Default?: any, DefaultSubstitutions?: any, GCM?: any, RecommenderId?: any, tags?: any, TemplateDescription?: any}
export def "templates-push update" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-new-version: oneof<nothing, bool> # Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to (overwrite) the latest existing version of the template. If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to (overwrites) the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  push_notification_template_request: record # Specifies the content and settings for a message template that can be used in messages that are sent through a push notification channel. — shape: {ADM?: any, APNS?: any, Baidu?: any, Default?: any, DefaultSubstitutions?: any, GCM?: any, RecommenderId?: any, tags?: any, TemplateDescription?: any}
]: any -> record<MessageBody: record<Message: record, RequestID: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let qp = [(serialize-qp "create-new-version" $create_new_version "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/push") $qp)
  let req_body = {"PushNotificationTemplateRequest": $push_notification_template_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"create-new-version": $create_new_version, "version": $version} | compact), body: $req_body}
}

# Creates an Amazon Pinpoint configuration for a recommender model.
#
# POST /v1/recommenders
# operationId: CreateRecommenderConfiguration
# --CreateRecommenderConfiguration shape: {Attributes?: any, Description?: any, Name?: any, RecommendationProviderIdType?: any, RecommendationProviderRoleArn?: any, RecommendationProviderUri?: any, RecommendationTransformerUri?: any, RecommendationsDisplayName?: any, RecommendationsPerMessage?: any}
export def "recommenders create-configuration" [
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
  create_recommender_configuration: record # Specifies Amazon Pinpoint configuration settings for retrieving and processing recommendation data from a recommender model. — shape: {Attributes?: any, Description?: any, Name?: any, RecommendationProviderIdType?: any, RecommendationProviderRoleArn?: any, RecommendationProviderUri?: any, RecommendationTransformerUri?: any, RecommendationsDisplayName?: any, RecommendationsPerMessage?: any}
]: any -> record<RecommenderConfigurationResponse: record<Attributes: record, CreationDate: record, Description: record, Id: record, LastModifiedDate: record, Name: record, RecommendationProviderIdType: record, RecommendationProviderRoleArn: record, RecommendationProviderUri: record, RecommendationTransformerUri: record, RecommendationsDisplayName: record, RecommendationsPerMessage: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/recommenders")
  let req_body = {"CreateRecommenderConfiguration": $create_recommender_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves information about all the recommender model configurations that are associated with your Amazon Pinpoint account.
#
# GET /v1/recommenders
# operationId: GetRecommenderConfigurations
export def "recommenders get-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ListRecommenderConfigurationsResponse: record<Item: record, NextToken: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page-size" $page_size "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/recommenders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page-size": $page_size, "token": $qp_token} | compact), body: null}
}

# Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
#
# POST /v1/apps/{application-id}/segments
# operationId: CreateSegment
# --WriteSegmentRequest shape: {Dimensions?: any, Name?: any, SegmentGroups?: any, tags?: any}
export def "apps-segments create" [
  application_id: string
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
  write_segment_request: record # Specifies the configuration, dimension, and other settings for a segment. A WriteSegmentRequest object can include a Dimensions object or a SegmentGroups object, but not both. — shape: {Dimensions?: any, Name?: any, SegmentGroups?: any, tags?: any}
]: any -> record<SegmentResponse: record<ApplicationId: record, Arn: record, CreationDate: record, Dimensions: record<Attributes: record, Behavior: record, Demographic: record, Location: record, Metrics: record, UserAttributes: record>, Id: record, ImportDefinition: record<ChannelCounts: record, ExternalId: record, Format: record, RoleArn: record, S3Url: record, Size: record>, LastModifiedDate: record, Name: record, SegmentGroups: record<Groups: record, Include: record>, SegmentType: record, tags: record, Version: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/segments"))
  let req_body = {"WriteSegmentRequest": $write_segment_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
#
# GET /v1/apps/{application-id}/segments
# operationId: GetSegments
export def "apps-segments list" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<SegmentsResponse: record<Item: record, NextToken: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let qp = [(serialize-qp "page-size" $page_size "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/segments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page-size": $page_size, "token": $qp_token} | compact), body: null}
}

# Creates a message template for messages that are sent through the SMS channel.
#
# POST /v1/templates/{template-name}/sms
# operationId: CreateSmsTemplate
# --SMSTemplateRequest shape: {Body?: any, DefaultSubstitutions?: any, RecommenderId?: any, tags?: any, TemplateDescription?: any}
export def "templates-sms create" [
  template_name: string
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
  sms_template_request: record # Specifies the content and settings for a message template that can be used in text messages that are sent through the SMS channel. — shape: {Body?: any, DefaultSubstitutions?: any, RecommenderId?: any, tags?: any, TemplateDescription?: any}
]: any -> record<CreateTemplateMessageBody: record<Arn: record, Message: record, RequestID: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/sms"))
  let req_body = {"SMSTemplateRequest": $sms_template_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a message template for messages that were sent through the SMS channel.
#
# DELETE /v1/templates/{template-name}/sms
# operationId: DeleteSmsTemplate
export def "templates-sms delete" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<MessageBody: record<Message: record, RequestID: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/sms") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version} | compact), body: null}
}

# Retrieves the content and settings of a message template for messages that are sent through the SMS channel.
#
# GET /v1/templates/{template-name}/sms
# operationId: GetSmsTemplate
export def "templates-sms get" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<SMSTemplateResponse: record<Arn: record, Body: record, CreationDate: record, DefaultSubstitutions: record, LastModifiedDate: record, RecommenderId: record, tags: record, TemplateDescription: record, TemplateName: record, TemplateType: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/sms") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version} | compact), body: null}
}

# Updates an existing message template for messages that are sent through the SMS channel.
#
# PUT /v1/templates/{template-name}/sms
# operationId: UpdateSmsTemplate
# --SMSTemplateRequest shape: {Body?: any, DefaultSubstitutions?: any, RecommenderId?: any, tags?: any, TemplateDescription?: any}
export def "templates-sms update" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-new-version: oneof<nothing, bool> # Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to (overwrite) the latest existing version of the template. If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to (overwrites) the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  sms_template_request: record # Specifies the content and settings for a message template that can be used in text messages that are sent through the SMS channel. — shape: {Body?: any, DefaultSubstitutions?: any, RecommenderId?: any, tags?: any, TemplateDescription?: any}
]: any -> record<MessageBody: record<Message: record, RequestID: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let qp = [(serialize-qp "create-new-version" $create_new_version "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/sms") $qp)
  let req_body = {"SMSTemplateRequest": $sms_template_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"create-new-version": $create_new_version, "version": $version} | compact), body: $req_body}
}

# Creates a message template for messages that are sent through the voice channel.
#
# POST /v1/templates/{template-name}/voice
# operationId: CreateVoiceTemplate
# --VoiceTemplateRequest shape: {Body?: any, DefaultSubstitutions?: any, LanguageCode?: any, tags?: any, TemplateDescription?: any, VoiceId?: any}
export def "templates-voice create" [
  template_name: string
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
  voice_template_request: record # Specifies the content and settings for a message template that can be used in messages that are sent through the voice channel. — shape: {Body?: any, DefaultSubstitutions?: any, LanguageCode?: any, tags?: any, TemplateDescription?: any, VoiceId?: any}
]: any -> record<CreateTemplateMessageBody: record<Arn: record, Message: record, RequestID: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/voice"))
  let req_body = {"VoiceTemplateRequest": $voice_template_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a message template for messages that were sent through the voice channel.
#
# DELETE /v1/templates/{template-name}/voice
# operationId: DeleteVoiceTemplate
export def "templates-voice delete" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<MessageBody: record<Message: record, RequestID: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/voice") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version} | compact), body: null}
}

# Retrieves the content and settings of a message template for messages that are sent through the voice channel.
#
# GET /v1/templates/{template-name}/voice
# operationId: GetVoiceTemplate
export def "templates-voice get" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<VoiceTemplateResponse: record<Arn: record, Body: record, CreationDate: record, DefaultSubstitutions: record, LanguageCode: record, LastModifiedDate: record, tags: record, TemplateDescription: record, TemplateName: record, TemplateType: record, Version: record, VoiceId: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/voice") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"version": $version} | compact), body: null}
}

# Updates an existing message template for messages that are sent through the voice channel.
#
# PUT /v1/templates/{template-name}/voice
# operationId: UpdateVoiceTemplate
# --VoiceTemplateRequest shape: {Body?: any, DefaultSubstitutions?: any, LanguageCode?: any, tags?: any, TemplateDescription?: any, VoiceId?: any}
export def "templates-voice update" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-new-version: oneof<nothing, bool> # Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to (overwrite) the latest existing version of the template. If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to (overwrites) the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  voice_template_request: record # Specifies the content and settings for a message template that can be used in messages that are sent through the voice channel. — shape: {Body?: any, DefaultSubstitutions?: any, LanguageCode?: any, tags?: any, TemplateDescription?: any, VoiceId?: any}
]: any -> record<MessageBody: record<Message: record, RequestID: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  let qp = [(serialize-qp "create-new-version" $create_new_version "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/v1/templates/{template_name}/voice") $qp)
  let req_body = {"VoiceTemplateRequest": $voice_template_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"create-new-version": $create_new_version, "version": $version} | compact), body: $req_body}
}

# Disables the ADM channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/adm
# operationId: DeleteAdmChannel
export def "apps-channels-adm delete" [
  application_id: string
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
]: nothing -> record<ADMChannelResponse: record<ApplicationId: record, CreationDate: record, Enabled: record, HasCredential: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/adm"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the status and settings of the ADM channel for an application.
#
# GET /v1/apps/{application-id}/channels/adm
# operationId: GetAdmChannel
export def "apps-channels-adm get" [
  application_id: string
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
]: nothing -> record<ADMChannelResponse: record<ApplicationId: record, CreationDate: record, Enabled: record, HasCredential: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/adm"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
#
# PUT /v1/apps/{application-id}/channels/adm
# operationId: UpdateAdmChannel
# --ADMChannelRequest shape: {ClientId?: any, ClientSecret?: any, Enabled?: any}
export def "apps-channels-adm update" [
  application_id: string
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
  adm_channel_request: record # Specifies the status and settings of the ADM (Amazon Device Messaging) channel for an application. — shape: {ClientId?: any, ClientSecret?: any, Enabled?: any}
]: any -> record<ADMChannelResponse: record<ApplicationId: record, CreationDate: record, Enabled: record, HasCredential: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/adm"))
  let req_body = {"ADMChannelRequest": $adm_channel_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Disables the APNs channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/apns
# operationId: DeleteApnsChannel
export def "apps-channels-apns delete" [
  application_id: string
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
]: nothing -> record<APNSChannelResponse: record<ApplicationId: record, CreationDate: record, DefaultAuthenticationMethod: record, Enabled: record, HasCredential: record, HasTokenKey: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/apns"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the status and settings of the APNs channel for an application.
#
# GET /v1/apps/{application-id}/channels/apns
# operationId: GetApnsChannel
export def "apps-channels-apns get" [
  application_id: string
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
]: nothing -> record<APNSChannelResponse: record<ApplicationId: record, CreationDate: record, DefaultAuthenticationMethod: record, Enabled: record, HasCredential: record, HasTokenKey: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/apns"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
#
# PUT /v1/apps/{application-id}/channels/apns
# operationId: UpdateApnsChannel
# --APNSChannelRequest shape: {BundleId?: any, Certificate?: any, DefaultAuthenticationMethod?: any, Enabled?: any, PrivateKey?: any, TeamId?: any, TokenKey?: any, TokenKeyId?: any}
export def "apps-channels-apns update" [
  application_id: string
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
  apns_channel_request: record # Specifies the status and settings of the APNs (Apple Push Notification service) channel for an application. — shape: {BundleId?: any, Certificate?: any, DefaultAuthenticationMethod?: any, Enabled?: any, PrivateKey?: any, TeamId?: any, TokenKey?: any, TokenKeyId?: any}
]: any -> record<APNSChannelResponse: record<ApplicationId: record, CreationDate: record, DefaultAuthenticationMethod: record, Enabled: record, HasCredential: record, HasTokenKey: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/apns"))
  let req_body = {"APNSChannelRequest": $apns_channel_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/apns_sandbox
# operationId: DeleteApnsSandboxChannel
export def "apps-channels-apns-sandbox delete" [
  application_id: string
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
]: nothing -> record<APNSSandboxChannelResponse: record<ApplicationId: record, CreationDate: record, DefaultAuthenticationMethod: record, Enabled: record, HasCredential: record, HasTokenKey: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/apns_sandbox"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the status and settings of the APNs sandbox channel for an application.
#
# GET /v1/apps/{application-id}/channels/apns_sandbox
# operationId: GetApnsSandboxChannel
export def "apps-channels-apns-sandbox get" [
  application_id: string
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
]: nothing -> record<APNSSandboxChannelResponse: record<ApplicationId: record, CreationDate: record, DefaultAuthenticationMethod: record, Enabled: record, HasCredential: record, HasTokenKey: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/apns_sandbox"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
#
# PUT /v1/apps/{application-id}/channels/apns_sandbox
# operationId: UpdateApnsSandboxChannel
# --APNSSandboxChannelRequest shape: {BundleId?: any, Certificate?: any, DefaultAuthenticationMethod?: any, Enabled?: any, PrivateKey?: any, TeamId?: any, TokenKey?: any, TokenKeyId?: any}
export def "apps-channels-apns-sandbox update" [
  application_id: string
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
  apns_sandbox_channel_request: record # Specifies the status and settings of the APNs (Apple Push Notification service) sandbox channel for an application. — shape: {BundleId?: any, Certificate?: any, DefaultAuthenticationMethod?: any, Enabled?: any, PrivateKey?: any, TeamId?: any, TokenKey?: any, TokenKeyId?: any}
]: any -> record<APNSSandboxChannelResponse: record<ApplicationId: record, CreationDate: record, DefaultAuthenticationMethod: record, Enabled: record, HasCredential: record, HasTokenKey: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/apns_sandbox"))
  let req_body = {"APNSSandboxChannelRequest": $apns_sandbox_channel_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/apns_voip
# operationId: DeleteApnsVoipChannel
export def "apps-channels-apns-voip delete" [
  application_id: string
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
]: nothing -> record<APNSVoipChannelResponse: record<ApplicationId: record, CreationDate: record, DefaultAuthenticationMethod: record, Enabled: record, HasCredential: record, HasTokenKey: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/apns_voip"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the status and settings of the APNs VoIP channel for an application.
#
# GET /v1/apps/{application-id}/channels/apns_voip
# operationId: GetApnsVoipChannel
export def "apps-channels-apns-voip get" [
  application_id: string
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
]: nothing -> record<APNSVoipChannelResponse: record<ApplicationId: record, CreationDate: record, DefaultAuthenticationMethod: record, Enabled: record, HasCredential: record, HasTokenKey: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/apns_voip"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
#
# PUT /v1/apps/{application-id}/channels/apns_voip
# operationId: UpdateApnsVoipChannel
# --APNSVoipChannelRequest shape: {BundleId?: any, Certificate?: any, DefaultAuthenticationMethod?: any, Enabled?: any, PrivateKey?: any, TeamId?: any, TokenKey?: any, TokenKeyId?: any}
export def "apps-channels-apns-voip update" [
  application_id: string
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
  apns_voip_channel_request: record # Specifies the status and settings of the APNs (Apple Push Notification service) VoIP channel for an application. — shape: {BundleId?: any, Certificate?: any, DefaultAuthenticationMethod?: any, Enabled?: any, PrivateKey?: any, TeamId?: any, TokenKey?: any, TokenKeyId?: any}
]: any -> record<APNSVoipChannelResponse: record<ApplicationId: record, CreationDate: record, DefaultAuthenticationMethod: record, Enabled: record, HasCredential: record, HasTokenKey: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/apns_voip"))
  let req_body = {"APNSVoipChannelRequest": $apns_voip_channel_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/apns_voip_sandbox
# operationId: DeleteApnsVoipSandboxChannel
export def "apps-channels-apns-voip-sandbox delete" [
  application_id: string
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
]: nothing -> record<APNSVoipSandboxChannelResponse: record<ApplicationId: record, CreationDate: record, DefaultAuthenticationMethod: record, Enabled: record, HasCredential: record, HasTokenKey: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/apns_voip_sandbox"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
#
# GET /v1/apps/{application-id}/channels/apns_voip_sandbox
# operationId: GetApnsVoipSandboxChannel
export def "apps-channels-apns-voip-sandbox get" [
  application_id: string
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
]: nothing -> record<APNSVoipSandboxChannelResponse: record<ApplicationId: record, CreationDate: record, DefaultAuthenticationMethod: record, Enabled: record, HasCredential: record, HasTokenKey: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/apns_voip_sandbox"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
#
# PUT /v1/apps/{application-id}/channels/apns_voip_sandbox
# operationId: UpdateApnsVoipSandboxChannel
# --APNSVoipSandboxChannelRequest shape: {BundleId?: any, Certificate?: any, DefaultAuthenticationMethod?: any, Enabled?: any, PrivateKey?: any, TeamId?: any, TokenKey?: any, TokenKeyId?: any}
export def "apps-channels-apns-voip-sandbox update" [
  application_id: string
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
  apns_voip_sandbox_channel_request: record # Specifies the status and settings of the APNs (Apple Push Notification service) VoIP sandbox channel for an application. — shape: {BundleId?: any, Certificate?: any, DefaultAuthenticationMethod?: any, Enabled?: any, PrivateKey?: any, TeamId?: any, TokenKey?: any, TokenKeyId?: any}
]: any -> record<APNSVoipSandboxChannelResponse: record<ApplicationId: record, CreationDate: record, DefaultAuthenticationMethod: record, Enabled: record, HasCredential: record, HasTokenKey: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/apns_voip_sandbox"))
  let req_body = {"APNSVoipSandboxChannelRequest": $apns_voip_sandbox_channel_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an application.
#
# DELETE /v1/apps/{application-id}
# operationId: DeleteApp
export def "apps delete" [
  application_id: string
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
]: nothing -> record<ApplicationResponse: record<Arn: record, Id: record, Name: record, tags: record, CreationDate: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about an application.
#
# GET /v1/apps/{application-id}
# operationId: GetApp
export def "apps get" [
  application_id: string
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
]: nothing -> record<ApplicationResponse: record<Arn: record, Id: record, Name: record, tags: record, CreationDate: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Disables the Baidu channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/baidu
# operationId: DeleteBaiduChannel
export def "apps-channels-baidu delete" [
  application_id: string
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
]: nothing -> record<BaiduChannelResponse: record<ApplicationId: record, CreationDate: record, Credential: record, Enabled: record, HasCredential: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/baidu"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the status and settings of the Baidu channel for an application.
#
# GET /v1/apps/{application-id}/channels/baidu
# operationId: GetBaiduChannel
export def "apps-channels-baidu get" [
  application_id: string
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
]: nothing -> record<BaiduChannelResponse: record<ApplicationId: record, CreationDate: record, Credential: record, Enabled: record, HasCredential: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/baidu"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
#
# PUT /v1/apps/{application-id}/channels/baidu
# operationId: UpdateBaiduChannel
# --BaiduChannelRequest shape: {ApiKey?: any, Enabled?: any, SecretKey?: any}
export def "apps-channels-baidu update" [
  application_id: string
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
  baidu_channel_request: record # Specifies the status and settings of the Baidu (Baidu Cloud Push) channel for an application. — shape: {ApiKey?: any, Enabled?: any, SecretKey?: any}
]: any -> record<BaiduChannelResponse: record<ApplicationId: record, CreationDate: record, Credential: record, Enabled: record, HasCredential: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/baidu"))
  let req_body = {"BaiduChannelRequest": $baidu_channel_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a campaign from an application.
#
# DELETE /v1/apps/{application-id}/campaigns/{campaign-id}
# operationId: DeleteCampaign
export def "apps-campaigns delete" [
  application_id: string
  campaign_id: string
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
]: nothing -> record<CampaignResponse: record<AdditionalTreatments: record, ApplicationId: record, Arn: record, CreationDate: record, CustomDeliveryConfiguration: record<DeliveryUri: record, EndpointTypes: record>, DefaultState: record<CampaignStatus: record>, Description: record, HoldoutPercent: record, Hook: record<LambdaFunctionName: record, Mode: record, WebUrl: record>, Id: record, IsPaused: record, LastModifiedDate: record, Limits: record<Daily: record, MaximumDuration: record, MessagesPerSecond: record, Total: record, Session: record>, MessageConfiguration: record<ADMMessage: record, APNSMessage: record, BaiduMessage: record, CustomMessage: record, DefaultMessage: record, EmailMessage: record, GCMMessage: record, SMSMessage: record, InAppMessage: record>, Name: record, Schedule: record<EndTime: record, EventFilter: record, Frequency: record, IsLocalTime: record, QuietTime: record, StartTime: record, Timezone: record>, SegmentId: record, SegmentVersion: record, State: record<CampaignStatus: record>, tags: record, TemplateConfiguration: record<EmailTemplate: record, PushTemplate: record, SMSTemplate: record, VoiceTemplate: record>, TreatmentDescription: record, TreatmentName: record, Version: record, Priority: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), campaign_id: (encode-path-segment $campaign_id)} | format pattern "/v1/apps/{application_id}/campaigns/{campaign_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the status, configuration, and other settings for a campaign.
#
# GET /v1/apps/{application-id}/campaigns/{campaign-id}
# operationId: GetCampaign
export def "apps-campaigns get" [
  application_id: string
  campaign_id: string
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
]: nothing -> record<CampaignResponse: record<AdditionalTreatments: record, ApplicationId: record, Arn: record, CreationDate: record, CustomDeliveryConfiguration: record<DeliveryUri: record, EndpointTypes: record>, DefaultState: record<CampaignStatus: record>, Description: record, HoldoutPercent: record, Hook: record<LambdaFunctionName: record, Mode: record, WebUrl: record>, Id: record, IsPaused: record, LastModifiedDate: record, Limits: record<Daily: record, MaximumDuration: record, MessagesPerSecond: record, Total: record, Session: record>, MessageConfiguration: record<ADMMessage: record, APNSMessage: record, BaiduMessage: record, CustomMessage: record, DefaultMessage: record, EmailMessage: record, GCMMessage: record, SMSMessage: record, InAppMessage: record>, Name: record, Schedule: record<EndTime: record, EventFilter: record, Frequency: record, IsLocalTime: record, QuietTime: record, StartTime: record, Timezone: record>, SegmentId: record, SegmentVersion: record, State: record<CampaignStatus: record>, tags: record, TemplateConfiguration: record<EmailTemplate: record, PushTemplate: record, SMSTemplate: record, VoiceTemplate: record>, TreatmentDescription: record, TreatmentName: record, Version: record, Priority: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), campaign_id: (encode-path-segment $campaign_id)} | format pattern "/v1/apps/{application_id}/campaigns/{campaign_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the configuration and other settings for a campaign.
#
# PUT /v1/apps/{application-id}/campaigns/{campaign-id}
# operationId: UpdateCampaign
# --WriteCampaignRequest shape: {AdditionalTreatments?: any, CustomDeliveryConfiguration?: any, Description?: any, HoldoutPercent?: any, Hook?: any, IsPaused?: any, Limits?: any, MessageConfiguration?: any, Name?: any, Schedule?: any, SegmentId?: any, SegmentVersion?: any, tags?: any, TemplateConfiguration?: any, TreatmentDescription?: any, TreatmentName?: any, Priority?: any}
export def "apps-campaigns update" [
  application_id: string
  campaign_id: string
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
  write_campaign_request: record # Specifies the configuration and other settings for a campaign. — shape: {AdditionalTreatments?: any, CustomDeliveryConfiguration?: any, Description?: any, HoldoutPercent?: any, Hook?: any, IsPaused?: any, Limits?: any, MessageConfiguration?: any, Name?: any, Schedule?: any, SegmentId?: any, SegmentVersion?: any, tags?: any, TemplateConfiguration?: any, TreatmentDescription?: any, TreatmentName?: any, Priority?: any}
]: any -> record<CampaignResponse: record<AdditionalTreatments: record, ApplicationId: record, Arn: record, CreationDate: record, CustomDeliveryConfiguration: record<DeliveryUri: record, EndpointTypes: record>, DefaultState: record<CampaignStatus: record>, Description: record, HoldoutPercent: record, Hook: record<LambdaFunctionName: record, Mode: record, WebUrl: record>, Id: record, IsPaused: record, LastModifiedDate: record, Limits: record<Daily: record, MaximumDuration: record, MessagesPerSecond: record, Total: record, Session: record>, MessageConfiguration: record<ADMMessage: record, APNSMessage: record, BaiduMessage: record, CustomMessage: record, DefaultMessage: record, EmailMessage: record, GCMMessage: record, SMSMessage: record, InAppMessage: record>, Name: record, Schedule: record<EndTime: record, EventFilter: record, Frequency: record, IsLocalTime: record, QuietTime: record, StartTime: record, Timezone: record>, SegmentId: record, SegmentVersion: record, State: record<CampaignStatus: record>, tags: record, TemplateConfiguration: record<EmailTemplate: record, PushTemplate: record, SMSTemplate: record, VoiceTemplate: record>, TreatmentDescription: record, TreatmentName: record, Version: record, Priority: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), campaign_id: (encode-path-segment $campaign_id)} | format pattern "/v1/apps/{application_id}/campaigns/{campaign_id}"))
  let req_body = {"WriteCampaignRequest": $write_campaign_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Disables the email channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/email
# operationId: DeleteEmailChannel
export def "apps-channels-email delete" [
  application_id: string
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
]: nothing -> record<EmailChannelResponse: record<ApplicationId: record, ConfigurationSet: record, CreationDate: record, Enabled: record, FromAddress: record, HasCredential: record, Id: record, Identity: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, MessagesPerSecond: record, Platform: record, RoleArn: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/email"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the status and settings of the email channel for an application.
#
# GET /v1/apps/{application-id}/channels/email
# operationId: GetEmailChannel
export def "apps-channels-email get" [
  application_id: string
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
]: nothing -> record<EmailChannelResponse: record<ApplicationId: record, ConfigurationSet: record, CreationDate: record, Enabled: record, FromAddress: record, HasCredential: record, Id: record, Identity: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, MessagesPerSecond: record, Platform: record, RoleArn: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/email"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Enables the email channel for an application or updates the status and settings of the email channel for an application.
#
# PUT /v1/apps/{application-id}/channels/email
# operationId: UpdateEmailChannel
# --EmailChannelRequest shape: {ConfigurationSet?: any, Enabled?: any, FromAddress?: any, Identity?: any, RoleArn?: any}
export def "apps-channels-email update" [
  application_id: string
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
  email_channel_request: record # Specifies the status and settings of the email channel for an application. — shape: {ConfigurationSet?: any, Enabled?: any, FromAddress?: any, Identity?: any, RoleArn?: any}
]: any -> record<EmailChannelResponse: record<ApplicationId: record, ConfigurationSet: record, CreationDate: record, Enabled: record, FromAddress: record, HasCredential: record, Id: record, Identity: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, MessagesPerSecond: record, Platform: record, RoleArn: record, Version: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/email"))
  let req_body = {"EmailChannelRequest": $email_channel_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an endpoint from an application.
#
# DELETE /v1/apps/{application-id}/endpoints/{endpoint-id}
# operationId: DeleteEndpoint
export def "apps-endpoints delete" [
  application_id: string
  endpoint_id: string
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
]: nothing -> record<EndpointResponse: record<Address: record, ApplicationId: record, Attributes: record, ChannelType: record, CohortId: record, CreationDate: record, Demographic: record<AppVersion: record, Locale: record, Make: record, Model: record, ModelVersion: record, Platform: record, PlatformVersion: record, Timezone: record>, EffectiveDate: record, EndpointStatus: record, Id: record, Location: record<City: record, Country: record, Latitude: record, Longitude: record, PostalCode: record, Region: record>, Metrics: record, OptOut: record, RequestId: record, User: record<UserAttributes: record, UserId: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($endpoint_id | is-empty) { error make --unspanned { msg: "path parameter 'endpoint-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), endpoint_id: (encode-path-segment $endpoint_id)} | format pattern "/v1/apps/{application_id}/endpoints/{endpoint_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the settings and attributes of a specific endpoint for an application.
#
# GET /v1/apps/{application-id}/endpoints/{endpoint-id}
# operationId: GetEndpoint
export def "apps-endpoints get" [
  application_id: string
  endpoint_id: string
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
]: nothing -> record<EndpointResponse: record<Address: record, ApplicationId: record, Attributes: record, ChannelType: record, CohortId: record, CreationDate: record, Demographic: record<AppVersion: record, Locale: record, Make: record, Model: record, ModelVersion: record, Platform: record, PlatformVersion: record, Timezone: record>, EffectiveDate: record, EndpointStatus: record, Id: record, Location: record<City: record, Country: record, Latitude: record, Longitude: record, PostalCode: record, Region: record>, Metrics: record, OptOut: record, RequestId: record, User: record<UserAttributes: record, UserId: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($endpoint_id | is-empty) { error make --unspanned { msg: "path parameter 'endpoint-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), endpoint_id: (encode-path-segment $endpoint_id)} | format pattern "/v1/apps/{application_id}/endpoints/{endpoint_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes for an endpoint. If an update includes one or more values for a custom attribute, Amazon Pinpoint replaces (overwrites) any existing values with the new values.
#
# PUT /v1/apps/{application-id}/endpoints/{endpoint-id}
# operationId: UpdateEndpoint
# --EndpointRequest shape: {Address?: any, Attributes?: any, ChannelType?: any, Demographic?: any, EffectiveDate?: any, EndpointStatus?: any, Location?: any, Metrics?: any, OptOut?: any, RequestId?: any, User?: any}
export def "apps-endpoints update" [
  application_id: string
  endpoint_id: string
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
  endpoint_request: record # Specifies the channel type and other settings for an endpoint. — shape: {Address?: any, Attributes?: any, ChannelType?: any, Demographic?: any, EffectiveDate?: any, EndpointStatus?: any, Location?: any, Metrics?: any, OptOut?: any, RequestId?: any, User?: any}
]: any -> record<MessageBody: record<Message: record, RequestID: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($endpoint_id | is-empty) { error make --unspanned { msg: "path parameter 'endpoint-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), endpoint_id: (encode-path-segment $endpoint_id)} | format pattern "/v1/apps/{application_id}/endpoints/{endpoint_id}"))
  let req_body = {"EndpointRequest": $endpoint_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the event stream for an application.
#
# DELETE /v1/apps/{application-id}/eventstream
# operationId: DeleteEventStream
export def "apps-eventstream delete-event-stream" [
  application_id: string
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
]: nothing -> record<EventStream: record<ApplicationId: record, DestinationStreamArn: record, ExternalId: record, LastModifiedDate: record, LastUpdatedBy: record, RoleArn: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/eventstream"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the event stream settings for an application.
#
# GET /v1/apps/{application-id}/eventstream
# operationId: GetEventStream
export def "apps-eventstream get-event-stream" [
  application_id: string
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
]: nothing -> record<EventStream: record<ApplicationId: record, DestinationStreamArn: record, ExternalId: record, LastModifiedDate: record, LastUpdatedBy: record, RoleArn: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/eventstream"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new event stream for an application or updates the settings of an existing event stream for an application.
#
# POST /v1/apps/{application-id}/eventstream
# operationId: PutEventStream
# --WriteEventStream shape: {DestinationStreamArn?: any, RoleArn?: any}
export def "apps-eventstream update-event-stream" [
  application_id: string
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
  write_event_stream: record # Specifies the Amazon Resource Name (ARN) of an event stream to publish events to and the AWS Identity and Access Management (IAM) role to use when publishing those events. — shape: {DestinationStreamArn?: any, RoleArn?: any}
]: any -> record<EventStream: record<ApplicationId: record, DestinationStreamArn: record, ExternalId: record, LastModifiedDate: record, LastUpdatedBy: record, RoleArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/eventstream"))
  let req_body = {"WriteEventStream": $write_event_stream} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Disables the GCM channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/gcm
# operationId: DeleteGcmChannel
export def "apps-channels-gcm delete" [
  application_id: string
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
]: nothing -> record<GCMChannelResponse: record<ApplicationId: record, CreationDate: record, Credential: record, Enabled: record, HasCredential: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/gcm"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the status and settings of the GCM channel for an application.
#
# GET /v1/apps/{application-id}/channels/gcm
# operationId: GetGcmChannel
export def "apps-channels-gcm get" [
  application_id: string
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
]: nothing -> record<GCMChannelResponse: record<ApplicationId: record, CreationDate: record, Credential: record, Enabled: record, HasCredential: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/gcm"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
#
# PUT /v1/apps/{application-id}/channels/gcm
# operationId: UpdateGcmChannel
# --GCMChannelRequest shape: {ApiKey?: any, Enabled?: any}
export def "apps-channels-gcm update" [
  application_id: string
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
  gcm_channel_request: record # Specifies the status and settings of the GCM channel for an application. This channel enables Amazon Pinpoint to send push notifications through the Firebase Cloud Messaging (FCM), formerly Google Cloud Messaging (GCM), service. — shape: {ApiKey?: any, Enabled?: any}
]: any -> record<GCMChannelResponse: record<ApplicationId: record, CreationDate: record, Credential: record, Enabled: record, HasCredential: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/gcm"))
  let req_body = {"GCMChannelRequest": $gcm_channel_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a journey from an application.
#
# DELETE /v1/apps/{application-id}/journeys/{journey-id}
# operationId: DeleteJourney
export def "apps-journeys delete" [
  application_id: string
  journey_id: string
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
]: nothing -> record<JourneyResponse: record<Activities: record, ApplicationId: record, CreationDate: record, Id: record, LastModifiedDate: record, Limits: record<DailyCap: record, EndpointReentryCap: record, MessagesPerSecond: record, EndpointReentryInterval: record>, LocalTime: record, Name: record, QuietTime: record<End: record, Start: record>, RefreshFrequency: record, Schedule: record<EndTime: record, StartTime: record, Timezone: record>, StartActivity: record, StartCondition: record<Description: record, EventStartCondition: record, SegmentStartCondition: record>, State: record, tags: record, WaitForQuietTime: record, RefreshOnSegmentUpdate: record, JourneyChannelSettings: record<ConnectCampaignArn: record, ConnectCampaignExecutionRoleArn: record>, SendingSchedule: record, OpenHours: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>, ClosedDays: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($journey_id | is-empty) { error make --unspanned { msg: "path parameter 'journey-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), journey_id: (encode-path-segment $journey_id)} | format pattern "/v1/apps/{application_id}/journeys/{journey_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the status, configuration, and other settings for a journey.
#
# GET /v1/apps/{application-id}/journeys/{journey-id}
# operationId: GetJourney
export def "apps-journeys get" [
  application_id: string
  journey_id: string
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
]: nothing -> record<JourneyResponse: record<Activities: record, ApplicationId: record, CreationDate: record, Id: record, LastModifiedDate: record, Limits: record<DailyCap: record, EndpointReentryCap: record, MessagesPerSecond: record, EndpointReentryInterval: record>, LocalTime: record, Name: record, QuietTime: record<End: record, Start: record>, RefreshFrequency: record, Schedule: record<EndTime: record, StartTime: record, Timezone: record>, StartActivity: record, StartCondition: record<Description: record, EventStartCondition: record, SegmentStartCondition: record>, State: record, tags: record, WaitForQuietTime: record, RefreshOnSegmentUpdate: record, JourneyChannelSettings: record<ConnectCampaignArn: record, ConnectCampaignExecutionRoleArn: record>, SendingSchedule: record, OpenHours: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>, ClosedDays: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($journey_id | is-empty) { error make --unspanned { msg: "path parameter 'journey-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), journey_id: (encode-path-segment $journey_id)} | format pattern "/v1/apps/{application_id}/journeys/{journey_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the configuration and other settings for a journey.
#
# PUT /v1/apps/{application-id}/journeys/{journey-id}
# operationId: UpdateJourney
# --WriteJourneyRequest shape: {Activities?: any, CreationDate?: any, LastModifiedDate?: any, Limits?: any, LocalTime?: any, Name?: any, QuietTime?: any, RefreshFrequency?: any, Schedule?: any, StartActivity?: any, StartCondition?: any, State?: any, WaitForQuietTime?: any, RefreshOnSegmentUpdate?: any, JourneyChannelSettings?: any, SendingSchedule?: any, OpenHours?: any, ClosedDays?: any}
export def "apps-journeys update" [
  application_id: string
  journey_id: string
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
  write_journey_request: record # Specifies the configuration and other settings for a journey. — shape: {Activities?: any, CreationDate?: any, LastModifiedDate?: any, Limits?: any, LocalTime?: any, Name?: any, QuietTime?: any, RefreshFrequency?: any, Schedule?: any, StartActivity?: any, StartCondition?: any, State?: any, WaitForQuietTime?: any, RefreshOnSegmentUpdate?: any, JourneyChannelSettings?: any, SendingSchedule?: any, OpenHours?: any, ClosedDays?: any}
]: any -> record<JourneyResponse: record<Activities: record, ApplicationId: record, CreationDate: record, Id: record, LastModifiedDate: record, Limits: record<DailyCap: record, EndpointReentryCap: record, MessagesPerSecond: record, EndpointReentryInterval: record>, LocalTime: record, Name: record, QuietTime: record<End: record, Start: record>, RefreshFrequency: record, Schedule: record<EndTime: record, StartTime: record, Timezone: record>, StartActivity: record, StartCondition: record<Description: record, EventStartCondition: record, SegmentStartCondition: record>, State: record, tags: record, WaitForQuietTime: record, RefreshOnSegmentUpdate: record, JourneyChannelSettings: record<ConnectCampaignArn: record, ConnectCampaignExecutionRoleArn: record>, SendingSchedule: record, OpenHours: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>, ClosedDays: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($journey_id | is-empty) { error make --unspanned { msg: "path parameter 'journey-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), journey_id: (encode-path-segment $journey_id)} | format pattern "/v1/apps/{application_id}/journeys/{journey_id}"))
  let req_body = {"WriteJourneyRequest": $write_journey_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an Amazon Pinpoint configuration for a recommender model.
#
# DELETE /v1/recommenders/{recommender-id}
# operationId: DeleteRecommenderConfiguration
export def "recommenders delete-configuration" [
  recommender_id: string
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
]: nothing -> record<RecommenderConfigurationResponse: record<Attributes: record, CreationDate: record, Description: record, Id: record, LastModifiedDate: record, Name: record, RecommendationProviderIdType: record, RecommendationProviderRoleArn: record, RecommendationProviderUri: record, RecommendationTransformerUri: record, RecommendationsDisplayName: record, RecommendationsPerMessage: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($recommender_id | is-empty) { error make --unspanned { msg: "path parameter 'recommender-id' must be non-empty" } }
  let full_url = (build-url $base ({recommender_id: (encode-path-segment $recommender_id)} | format pattern "/v1/recommenders/{recommender_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about an Amazon Pinpoint configuration for a recommender model.
#
# GET /v1/recommenders/{recommender-id}
# operationId: GetRecommenderConfiguration
export def "recommenders get-configuration" [
  recommender_id: string
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
]: nothing -> record<RecommenderConfigurationResponse: record<Attributes: record, CreationDate: record, Description: record, Id: record, LastModifiedDate: record, Name: record, RecommendationProviderIdType: record, RecommendationProviderRoleArn: record, RecommendationProviderUri: record, RecommendationTransformerUri: record, RecommendationsDisplayName: record, RecommendationsPerMessage: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($recommender_id | is-empty) { error make --unspanned { msg: "path parameter 'recommender-id' must be non-empty" } }
  let full_url = (build-url $base ({recommender_id: (encode-path-segment $recommender_id)} | format pattern "/v1/recommenders/{recommender_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an Amazon Pinpoint configuration for a recommender model.
#
# PUT /v1/recommenders/{recommender-id}
# operationId: UpdateRecommenderConfiguration
# --UpdateRecommenderConfiguration shape: {Attributes?: any, Description?: any, Name?: any, RecommendationProviderIdType?: any, RecommendationProviderRoleArn?: any, RecommendationProviderUri?: any, RecommendationTransformerUri?: any, RecommendationsDisplayName?: any, RecommendationsPerMessage?: any}
export def "recommenders update-configuration" [
  recommender_id: string
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
  update_recommender_configuration: record # Specifies Amazon Pinpoint configuration settings for retrieving and processing recommendation data from a recommender model. — shape: {Attributes?: any, Description?: any, Name?: any, RecommendationProviderIdType?: any, RecommendationProviderRoleArn?: any, RecommendationProviderUri?: any, RecommendationTransformerUri?: any, RecommendationsDisplayName?: any, RecommendationsPerMessage?: any}
]: any -> record<RecommenderConfigurationResponse: record<Attributes: record, CreationDate: record, Description: record, Id: record, LastModifiedDate: record, Name: record, RecommendationProviderIdType: record, RecommendationProviderRoleArn: record, RecommendationProviderUri: record, RecommendationTransformerUri: record, RecommendationsDisplayName: record, RecommendationsPerMessage: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($recommender_id | is-empty) { error make --unspanned { msg: "path parameter 'recommender-id' must be non-empty" } }
  let full_url = (build-url $base ({recommender_id: (encode-path-segment $recommender_id)} | format pattern "/v1/recommenders/{recommender_id}"))
  let req_body = {"UpdateRecommenderConfiguration": $update_recommender_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a segment from an application.
#
# DELETE /v1/apps/{application-id}/segments/{segment-id}
# operationId: DeleteSegment
export def "apps-segments delete" [
  application_id: string
  segment_id: string
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
]: nothing -> record<SegmentResponse: record<ApplicationId: record, Arn: record, CreationDate: record, Dimensions: record<Attributes: record, Behavior: record, Demographic: record, Location: record, Metrics: record, UserAttributes: record>, Id: record, ImportDefinition: record<ChannelCounts: record, ExternalId: record, Format: record, RoleArn: record, S3Url: record, Size: record>, LastModifiedDate: record, Name: record, SegmentGroups: record<Groups: record, Include: record>, SegmentType: record, tags: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($segment_id | is-empty) { error make --unspanned { msg: "path parameter 'segment-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), segment_id: (encode-path-segment $segment_id)} | format pattern "/v1/apps/{application_id}/segments/{segment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
#
# GET /v1/apps/{application-id}/segments/{segment-id}
# operationId: GetSegment
export def "apps-segments get" [
  application_id: string
  segment_id: string
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
]: nothing -> record<SegmentResponse: record<ApplicationId: record, Arn: record, CreationDate: record, Dimensions: record<Attributes: record, Behavior: record, Demographic: record, Location: record, Metrics: record, UserAttributes: record>, Id: record, ImportDefinition: record<ChannelCounts: record, ExternalId: record, Format: record, RoleArn: record, S3Url: record, Size: record>, LastModifiedDate: record, Name: record, SegmentGroups: record<Groups: record, Include: record>, SegmentType: record, tags: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($segment_id | is-empty) { error make --unspanned { msg: "path parameter 'segment-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), segment_id: (encode-path-segment $segment_id)} | format pattern "/v1/apps/{application_id}/segments/{segment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
#
# PUT /v1/apps/{application-id}/segments/{segment-id}
# operationId: UpdateSegment
# --WriteSegmentRequest shape: {Dimensions?: any, Name?: any, SegmentGroups?: any, tags?: any}
export def "apps-segments update" [
  application_id: string
  segment_id: string
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
  write_segment_request: record # Specifies the configuration, dimension, and other settings for a segment. A WriteSegmentRequest object can include a Dimensions object or a SegmentGroups object, but not both. — shape: {Dimensions?: any, Name?: any, SegmentGroups?: any, tags?: any}
]: any -> record<SegmentResponse: record<ApplicationId: record, Arn: record, CreationDate: record, Dimensions: record<Attributes: record, Behavior: record, Demographic: record, Location: record, Metrics: record, UserAttributes: record>, Id: record, ImportDefinition: record<ChannelCounts: record, ExternalId: record, Format: record, RoleArn: record, S3Url: record, Size: record>, LastModifiedDate: record, Name: record, SegmentGroups: record<Groups: record, Include: record>, SegmentType: record, tags: record, Version: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($segment_id | is-empty) { error make --unspanned { msg: "path parameter 'segment-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), segment_id: (encode-path-segment $segment_id)} | format pattern "/v1/apps/{application_id}/segments/{segment_id}"))
  let req_body = {"WriteSegmentRequest": $write_segment_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Disables the SMS channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/sms
# operationId: DeleteSmsChannel
export def "apps-channels-sms delete" [
  application_id: string
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
]: nothing -> record<SMSChannelResponse: record<ApplicationId: record, CreationDate: record, Enabled: record, HasCredential: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, PromotionalMessagesPerSecond: record, SenderId: record, ShortCode: record, TransactionalMessagesPerSecond: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/sms"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the status and settings of the SMS channel for an application.
#
# GET /v1/apps/{application-id}/channels/sms
# operationId: GetSmsChannel
export def "apps-channels-sms get" [
  application_id: string
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
]: nothing -> record<SMSChannelResponse: record<ApplicationId: record, CreationDate: record, Enabled: record, HasCredential: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, PromotionalMessagesPerSecond: record, SenderId: record, ShortCode: record, TransactionalMessagesPerSecond: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/sms"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
#
# PUT /v1/apps/{application-id}/channels/sms
# operationId: UpdateSmsChannel
# --SMSChannelRequest shape: {Enabled?: any, SenderId?: any, ShortCode?: any}
export def "apps-channels-sms update" [
  application_id: string
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
  sms_channel_request: record # Specifies the status and settings of the SMS channel for an application. — shape: {Enabled?: any, SenderId?: any, ShortCode?: any}
]: any -> record<SMSChannelResponse: record<ApplicationId: record, CreationDate: record, Enabled: record, HasCredential: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, PromotionalMessagesPerSecond: record, SenderId: record, ShortCode: record, TransactionalMessagesPerSecond: record, Version: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/sms"))
  let req_body = {"SMSChannelRequest": $sms_channel_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes all the endpoints that are associated with a specific user ID.
#
# DELETE /v1/apps/{application-id}/users/{user-id}
# operationId: DeleteUserEndpoints
export def "apps-users delete-endpoints" [
  application_id: string
  user_id: string
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
]: nothing -> record<EndpointsResponse: record<Item: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), user_id: (encode-path-segment $user_id)} | format pattern "/v1/apps/{application_id}/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about all the endpoints that are associated with a specific user ID.
#
# GET /v1/apps/{application-id}/users/{user-id}
# operationId: GetUserEndpoints
export def "apps-users get-endpoints" [
  application_id: string
  user_id: string
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
]: nothing -> record<EndpointsResponse: record<Item: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), user_id: (encode-path-segment $user_id)} | format pattern "/v1/apps/{application_id}/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Disables the voice channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/voice
# operationId: DeleteVoiceChannel
export def "apps-channels-voice delete" [
  application_id: string
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
]: nothing -> record<VoiceChannelResponse: record<ApplicationId: record, CreationDate: record, Enabled: record, HasCredential: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/voice"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the status and settings of the voice channel for an application.
#
# GET /v1/apps/{application-id}/channels/voice
# operationId: GetVoiceChannel
export def "apps-channels-voice get" [
  application_id: string
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
]: nothing -> record<VoiceChannelResponse: record<ApplicationId: record, CreationDate: record, Enabled: record, HasCredential: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/voice"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
#
# PUT /v1/apps/{application-id}/channels/voice
# operationId: UpdateVoiceChannel
# --VoiceChannelRequest shape: {Enabled?: any}
export def "apps-channels-voice update" [
  application_id: string
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
  voice_channel_request: record # Specifies the status and settings of the voice channel for an application. — shape: {Enabled?: any}
]: any -> record<VoiceChannelResponse: record<ApplicationId: record, CreationDate: record, Enabled: record, HasCredential: record, Id: record, IsArchived: record, LastModifiedBy: record, LastModifiedDate: record, Platform: record, Version: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels/voice"))
  let req_body = {"VoiceChannelRequest": $voice_channel_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
#
# GET /v1/apps/{application-id}/kpis/daterange/{kpi-name}
# operationId: GetApplicationDateRangeKpi
export def "apps-kpis-daterange get-date-range" [
  application_id: string
  kpi_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-time: string # The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-26T20:00:00Z for 8:00 PM UTC July 26, 2019. (format: date-time)
  --next-token: string # The string that specifies which page of results to return in a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --start-time: string # The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-19T20:00:00Z for 8:00 PM UTC July 19, 2019. This value should also be fewer than 90 days from the current day. (format: date-time)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ApplicationDateRangeKpiResponse: record<ApplicationId: record, EndTime: record, KpiName: record, KpiResult: record<Rows: record>, NextToken: record, StartTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($kpi_name | is-empty) { error make --unspanned { msg: "path parameter 'kpi-name' must be non-empty" } }
  let qp = [(serialize-qp "end-time" $end_time "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "start-time" $start_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), kpi_name: (encode-path-segment $kpi_name)} | format pattern "/v1/apps/{application_id}/kpis/daterange/{kpi_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"end-time": $end_time, "next-token": $next_token, "page-size": $page_size, "start-time": $start_time} | compact), body: null}
}

# Retrieves information about the settings for an application.
#
# GET /v1/apps/{application-id}/settings
# operationId: GetApplicationSettings
export def "apps-settings get" [
  application_id: string
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
]: nothing -> record<ApplicationSettingsResource: record<ApplicationId: record, CampaignHook: record<LambdaFunctionName: record, Mode: record, WebUrl: record>, LastModifiedDate: record, Limits: record<Daily: record, MaximumDuration: record, MessagesPerSecond: record, Total: record, Session: record>, QuietTime: record<End: record, Start: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the settings for an application.
#
# PUT /v1/apps/{application-id}/settings
# operationId: UpdateApplicationSettings
# --WriteApplicationSettingsRequest shape: {CampaignHook?: any, CloudWatchMetricsEnabled?: any, EventTaggingEnabled?: bool, Limits?: any, QuietTime?: any}
export def "apps-settings update" [
  application_id: string
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
  write_application_settings_request: record # Specifies the default settings for an application. — shape: {CampaignHook?: any, CloudWatchMetricsEnabled?: any, EventTaggingEnabled?: bool, Limits?: any, QuietTime?: any}
]: any -> record<ApplicationSettingsResource: record<ApplicationId: record, CampaignHook: record<LambdaFunctionName: record, Mode: record, WebUrl: record>, LastModifiedDate: record, Limits: record<Daily: record, MaximumDuration: record, MessagesPerSecond: record, Total: record, Session: record>, QuietTime: record<End: record, Start: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/settings"))
  let req_body = {"WriteApplicationSettingsRequest": $write_application_settings_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves information about all the activities for a campaign.
#
# GET /v1/apps/{application-id}/campaigns/{campaign-id}/activities
# operationId: GetCampaignActivities
export def "apps-campaigns-activities get" [
  application_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ActivitiesResponse: record<Item: record, NextToken: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign-id' must be non-empty" } }
  let qp = [(serialize-qp "page-size" $page_size "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), campaign_id: (encode-path-segment $campaign_id)} | format pattern "/v1/apps/{application_id}/campaigns/{campaign_id}/activities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page-size": $page_size, "token": $qp_token} | compact), body: null}
}

# Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
#
# GET /v1/apps/{application-id}/campaigns/{campaign-id}/kpis/daterange/{kpi-name}
# operationId: GetCampaignDateRangeKpi
export def "apps-campaigns-kpis-daterange get-date-range" [
  application_id: string
  campaign_id: string
  kpi_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-time: string # The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-26T20:00:00Z for 8:00 PM UTC July 26, 2019. (format: date-time)
  --next-token: string # The string that specifies which page of results to return in a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --start-time: string # The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-19T20:00:00Z for 8:00 PM UTC July 19, 2019. This value should also be fewer than 90 days from the current day. (format: date-time)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<CampaignDateRangeKpiResponse: record<ApplicationId: record, CampaignId: record, EndTime: record, KpiName: record, KpiResult: record<Rows: record>, NextToken: record, StartTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign-id' must be non-empty" } }
  if ($kpi_name | is-empty) { error make --unspanned { msg: "path parameter 'kpi-name' must be non-empty" } }
  let qp = [(serialize-qp "end-time" $end_time "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "start-time" $start_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), campaign_id: (encode-path-segment $campaign_id), kpi_name: (encode-path-segment $kpi_name)} | format pattern "/v1/apps/{application_id}/campaigns/{campaign_id}/kpis/daterange/{kpi_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"end-time": $end_time, "next-token": $next_token, "page-size": $page_size, "start-time": $start_time} | compact), body: null}
}

# Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
#
# GET /v1/apps/{application-id}/campaigns/{campaign-id}/versions/{version}
# operationId: GetCampaignVersion
export def "apps-campaigns-versions get" [
  application_id: string
  campaign_id: string
  version: string
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
]: nothing -> record<CampaignResponse: record<AdditionalTreatments: record, ApplicationId: record, Arn: record, CreationDate: record, CustomDeliveryConfiguration: record<DeliveryUri: record, EndpointTypes: record>, DefaultState: record<CampaignStatus: record>, Description: record, HoldoutPercent: record, Hook: record<LambdaFunctionName: record, Mode: record, WebUrl: record>, Id: record, IsPaused: record, LastModifiedDate: record, Limits: record<Daily: record, MaximumDuration: record, MessagesPerSecond: record, Total: record, Session: record>, MessageConfiguration: record<ADMMessage: record, APNSMessage: record, BaiduMessage: record, CustomMessage: record, DefaultMessage: record, EmailMessage: record, GCMMessage: record, SMSMessage: record, InAppMessage: record>, Name: record, Schedule: record<EndTime: record, EventFilter: record, Frequency: record, IsLocalTime: record, QuietTime: record, StartTime: record, Timezone: record>, SegmentId: record, SegmentVersion: record, State: record<CampaignStatus: record>, tags: record, TemplateConfiguration: record<EmailTemplate: record, PushTemplate: record, SMSTemplate: record, VoiceTemplate: record>, TreatmentDescription: record, TreatmentName: record, Version: record, Priority: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign-id' must be non-empty" } }
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), campaign_id: (encode-path-segment $campaign_id), version: (encode-path-segment $version)} | format pattern "/v1/apps/{application_id}/campaigns/{campaign_id}/versions/{version}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the status, configuration, and other settings for all versions of a campaign.
#
# GET /v1/apps/{application-id}/campaigns/{campaign-id}/versions
# operationId: GetCampaignVersions
export def "apps-campaigns-versions list" [
  application_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<CampaignsResponse: record<Item: record, NextToken: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign-id' must be non-empty" } }
  let qp = [(serialize-qp "page-size" $page_size "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), campaign_id: (encode-path-segment $campaign_id)} | format pattern "/v1/apps/{application_id}/campaigns/{campaign_id}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page-size": $page_size, "token": $qp_token} | compact), body: null}
}

# Retrieves information about the history and status of each channel for an application.
#
# GET /v1/apps/{application-id}/channels
# operationId: GetChannels
export def "apps-channels get" [
  application_id: string
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
]: nothing -> record<ChannelsResponse: record<Channels: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/channels"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the status and settings of a specific export job for an application.
#
# GET /v1/apps/{application-id}/jobs/export/{job-id}
# operationId: GetExportJob
export def "apps-jobs-export get" [
  application_id: string
  job_id: string
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
]: nothing -> record<ExportJobResponse: record<ApplicationId: record, CompletedPieces: record, CompletionDate: record, CreationDate: record, Definition: record<RoleArn: record, S3UrlPrefix: record, SegmentId: record, SegmentVersion: record>, FailedPieces: record, Failures: record, Id: record, JobStatus: record, TotalFailures: record, TotalPieces: record, TotalProcessed: record, Type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'job-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), job_id: (encode-path-segment $job_id)} | format pattern "/v1/apps/{application_id}/jobs/export/{job_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the status and settings of a specific import job for an application.
#
# GET /v1/apps/{application-id}/jobs/import/{job-id}
# operationId: GetImportJob
export def "apps-jobs-import get" [
  application_id: string
  job_id: string
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
]: nothing -> record<ImportJobResponse: record<ApplicationId: record, CompletedPieces: record, CompletionDate: record, CreationDate: record, Definition: record<DefineSegment: record, ExternalId: record, Format: record, RegisterEndpoints: record, RoleArn: record, S3Url: record, SegmentId: record, SegmentName: record>, FailedPieces: record, Failures: record, Id: record, JobStatus: record, TotalFailures: record, TotalPieces: record, TotalProcessed: record, Type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'job-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), job_id: (encode-path-segment $job_id)} | format pattern "/v1/apps/{application_id}/jobs/import/{job_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves the in-app messages targeted for the provided endpoint ID.
#
# GET /v1/apps/{application-id}/endpoints/{endpoint-id}/inappmessages
# operationId: GetInAppMessages
export def "apps-endpoints-inappmessages get-in-messages" [
  application_id: string
  endpoint_id: string
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
]: nothing -> record<InAppMessagesResponse: record<InAppMessageCampaigns: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($endpoint_id | is-empty) { error make --unspanned { msg: "path parameter 'endpoint-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), endpoint_id: (encode-path-segment $endpoint_id)} | format pattern "/v1/apps/{application_id}/endpoints/{endpoint_id}/inappmessages"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves (queries) pre-aggregated data for a standard engagement metric that applies to a journey.
#
# GET /v1/apps/{application-id}/journeys/{journey-id}/kpis/daterange/{kpi-name}
# operationId: GetJourneyDateRangeKpi
export def "apps-journeys-kpis-daterange get-date-range" [
  application_id: string
  journey_id: string
  kpi_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-time: string # The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-26T20:00:00Z for 8:00 PM UTC July 26, 2019. (format: date-time)
  --next-token: string # The string that specifies which page of results to return in a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --start-time: string # The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-19T20:00:00Z for 8:00 PM UTC July 19, 2019. This value should also be fewer than 90 days from the current day. (format: date-time)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<JourneyDateRangeKpiResponse: record<ApplicationId: record, EndTime: record, JourneyId: record, KpiName: record, KpiResult: record<Rows: record>, NextToken: record, StartTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($journey_id | is-empty) { error make --unspanned { msg: "path parameter 'journey-id' must be non-empty" } }
  if ($kpi_name | is-empty) { error make --unspanned { msg: "path parameter 'kpi-name' must be non-empty" } }
  let qp = [(serialize-qp "end-time" $end_time "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "start-time" $start_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), journey_id: (encode-path-segment $journey_id), kpi_name: (encode-path-segment $kpi_name)} | format pattern "/v1/apps/{application_id}/journeys/{journey_id}/kpis/daterange/{kpi_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"end-time": $end_time, "next-token": $next_token, "page-size": $page_size, "start-time": $start_time} | compact), body: null}
}

# Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey activity.
#
# GET /v1/apps/{application-id}/journeys/{journey-id}/activities/{journey-activity-id}/execution-metrics
# operationId: GetJourneyExecutionActivityMetrics
export def "apps-journeys-activities-execution-metrics get" [
  application_id: string
  journey_id: string
  journey_activity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The string that specifies which page of results to return in a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<JourneyExecutionActivityMetricsResponse: record<ActivityType: record, ApplicationId: record, JourneyActivityId: record, JourneyId: record, LastEvaluatedTime: record, Metrics: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($journey_id | is-empty) { error make --unspanned { msg: "path parameter 'journey-id' must be non-empty" } }
  if ($journey_activity_id | is-empty) { error make --unspanned { msg: "path parameter 'journey-activity-id' must be non-empty" } }
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "page-size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), journey_id: (encode-path-segment $journey_id), journey_activity_id: (encode-path-segment $journey_activity_id)} | format pattern "/v1/apps/{application_id}/journeys/{journey_id}/activities/{journey_activity_id}/execution-metrics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"next-token": $next_token, "page-size": $page_size} | compact), body: null}
}

# Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey.
#
# GET /v1/apps/{application-id}/journeys/{journey-id}/execution-metrics
# operationId: GetJourneyExecutionMetrics
export def "apps-journeys-execution-metrics get" [
  application_id: string
  journey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The string that specifies which page of results to return in a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<JourneyExecutionMetricsResponse: record<ApplicationId: record, JourneyId: record, LastEvaluatedTime: record, Metrics: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($journey_id | is-empty) { error make --unspanned { msg: "path parameter 'journey-id' must be non-empty" } }
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "page-size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), journey_id: (encode-path-segment $journey_id)} | format pattern "/v1/apps/{application_id}/journeys/{journey_id}/execution-metrics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"next-token": $next_token, "page-size": $page_size} | compact), body: null}
}

# Retrieves information about the status and settings of the export jobs for a segment.
#
# GET /v1/apps/{application-id}/segments/{segment-id}/jobs/export
# operationId: GetSegmentExportJobs
export def "apps-segments-jobs-export get" [
  application_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ExportJobsResponse: record<Item: record, NextToken: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($segment_id | is-empty) { error make --unspanned { msg: "path parameter 'segment-id' must be non-empty" } }
  let qp = [(serialize-qp "page-size" $page_size "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), segment_id: (encode-path-segment $segment_id)} | format pattern "/v1/apps/{application_id}/segments/{segment_id}/jobs/export") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page-size": $page_size, "token": $qp_token} | compact), body: null}
}

# Retrieves information about the status and settings of the import jobs for a segment.
#
# GET /v1/apps/{application-id}/segments/{segment-id}/jobs/import
# operationId: GetSegmentImportJobs
export def "apps-segments-jobs-import get" [
  application_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ImportJobsResponse: record<Item: record, NextToken: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($segment_id | is-empty) { error make --unspanned { msg: "path parameter 'segment-id' must be non-empty" } }
  let qp = [(serialize-qp "page-size" $page_size "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), segment_id: (encode-path-segment $segment_id)} | format pattern "/v1/apps/{application_id}/segments/{segment_id}/jobs/import") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page-size": $page_size, "token": $qp_token} | compact), body: null}
}

# Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
#
# GET /v1/apps/{application-id}/segments/{segment-id}/versions/{version}
# operationId: GetSegmentVersion
export def "apps-segments-versions get" [
  application_id: string
  segment_id: string
  version: string
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
]: nothing -> record<SegmentResponse: record<ApplicationId: record, Arn: record, CreationDate: record, Dimensions: record<Attributes: record, Behavior: record, Demographic: record, Location: record, Metrics: record, UserAttributes: record>, Id: record, ImportDefinition: record<ChannelCounts: record, ExternalId: record, Format: record, RoleArn: record, S3Url: record, Size: record>, LastModifiedDate: record, Name: record, SegmentGroups: record<Groups: record, Include: record>, SegmentType: record, tags: record, Version: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($segment_id | is-empty) { error make --unspanned { msg: "path parameter 'segment-id' must be non-empty" } }
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), segment_id: (encode-path-segment $segment_id), version: (encode-path-segment $version)} | format pattern "/v1/apps/{application_id}/segments/{segment_id}/versions/{version}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves information about the configuration, dimension, and other settings for all the versions of a specific segment that's associated with an application.
#
# GET /v1/apps/{application-id}/segments/{segment-id}/versions
# operationId: GetSegmentVersions
export def "apps-segments-versions list" [
  application_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<SegmentsResponse: record<Item: record, NextToken: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($segment_id | is-empty) { error make --unspanned { msg: "path parameter 'segment-id' must be non-empty" } }
  let qp = [(serialize-qp "page-size" $page_size "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), segment_id: (encode-path-segment $segment_id)} | format pattern "/v1/apps/{application_id}/segments/{segment_id}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page-size": $page_size, "token": $qp_token} | compact), body: null}
}

# Retrieves all the tags (keys and values) that are associated with an application, campaign, message template, or segment.
#
# GET /v1/tags/{resource-arn}
# operationId: ListTagsForResource
export def "tags list" [
  resource_arn: string
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
]: nothing -> record<TagsModel: record<tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource-arn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v1/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds one or more tags (keys and values) to an application, campaign, message template, or segment.
#
# POST /v1/tags/{resource-arn}
# operationId: TagResource
# --TagsModel shape: {tags?: any}
export def "tags tag" [
  resource_arn: string
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
  tags_model: record # Specifies the tags (keys and values) for an application, campaign, message template, or segment. — shape: {tags?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource-arn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v1/tags/{resource_arn}"))
  let req_body = {"TagsModel": $tags_model} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves information about all the versions of a specific message template.
#
# GET /v1/templates/{template-name}/{template-type}/versions
# operationId: ListTemplateVersions
export def "templates-versions list" [
  template_name: string
  template_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The string that specifies which page of results to return in a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<TemplateVersionsResponse: record<Item: record, Message: record, NextToken: record, RequestID: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  if ($template_type | is-empty) { error make --unspanned { msg: "path parameter 'template-type' must be non-empty" } }
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "page-size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name), template_type: (encode-path-segment $template_type)} | format pattern "/v1/templates/{template_name}/{template_type}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"next-token": $next_token, "page-size": $page_size} | compact), body: null}
}

# Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
#
# GET /v1/templates
# operationId: ListTemplates
export def "templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The string that specifies which page of results to return in a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --prefix: string # The substring to match in the names of the message templates to include in the results. If you specify this value, Amazon Pinpoint returns only those templates whose names begin with the value that you specify.
  --template-type: string # The type of message template to include in the results. Valid values are: EMAIL, PUSH, SMS, and VOICE. To include all types of templates in the results, don't include this parameter in your request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<TemplatesResponse: record<Item: record, NextToken: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "template-type" $template_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"next-token": $next_token, "page-size": $page_size, "prefix": $prefix, "template-type": $template_type} | compact), body: null}
}

# Retrieves information about a phone number.
#
# POST /v1/phone/number/validate
# operationId: PhoneNumberValidate
# --NumberValidateRequest shape: {IsoCountryCode?: any, PhoneNumber?: any}
export def "phone-number-validate validate" [
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
  number_validate_request: record # Specifies a phone number to validate and retrieve information about. — shape: {IsoCountryCode?: any, PhoneNumber?: any}
]: any -> record<NumberValidateResponse: record<Carrier: record, City: record, CleansedPhoneNumberE164: record, CleansedPhoneNumberNational: record, Country: record, CountryCodeIso2: record, CountryCodeNumeric: record, County: record, OriginalCountryCodeIso2: record, OriginalPhoneNumber: record, PhoneType: record, PhoneTypeCode: record, Timezone: record, ZipCode: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/phone/number/validate")
  let req_body = {"NumberValidateRequest": $number_validate_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
#
# POST /v1/apps/{application-id}/events
# operationId: PutEvents
# --EventsRequest shape: {BatchItem?: any}
export def "apps-events update" [
  application_id: string
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
  events_request: record # Specifies a batch of events to process. — shape: {BatchItem?: any}
]: any -> record<EventsResponse: record<Results: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/events"))
  let req_body = {"EventsRequest": $events_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
#
# PUT /v1/apps/{application-id}/attributes/{attribute-type}
# operationId: RemoveAttributes
# --UpdateAttributesRequest shape: {Blacklist?: any}
export def "apps-attributes delete" [
  application_id: string
  attribute_type: string
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
  update_attributes_request: record # Specifies one or more attributes to remove from all the endpoints that are associated with an application. — shape: {Blacklist?: any}
]: any -> record<AttributesResource: record<ApplicationId: record, AttributeType: record, Attributes: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($attribute_type | is-empty) { error make --unspanned { msg: "path parameter 'attribute-type' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), attribute_type: (encode-path-segment $attribute_type)} | format pattern "/v1/apps/{application_id}/attributes/{attribute_type}"))
  let req_body = {"UpdateAttributesRequest": $update_attributes_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates and sends a direct message.
#
# POST /v1/apps/{application-id}/messages
# operationId: SendMessages
# --MessageRequest shape: {Addresses?: any, Context?: any, Endpoints?: any, MessageConfiguration?: any, TemplateConfiguration?: any, TraceId?: any}
export def "apps-messages send" [
  application_id: string
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
  message_request: record # Specifies the configuration and other settings for a message. — shape: {Addresses?: any, Context?: any, Endpoints?: any, MessageConfiguration?: any, TemplateConfiguration?: any, TraceId?: any}
]: any -> record<MessageResponse: record<ApplicationId: record, EndpointResult: record, RequestId: record, Result: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/messages"))
  let req_body = {"MessageRequest": $message_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Send an OTP message
#
# POST /v1/apps/{application-id}/otp
# operationId: SendOTPMessage
# --SendOTPMessageRequestParameters shape: {AllowedAttempts?: any, BrandName?: any, Channel?: any, CodeLength?: any, DestinationIdentity?: any, EntityId?: any, Language?: any, OriginationIdentity?: any, ReferenceId?: any, TemplateId?: any, ValidityPeriod?: any}
export def "apps-otp send-message" [
  application_id: string
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
  send_otp_message_request_parameters: record # Send OTP message request parameters. — shape: {AllowedAttempts?: any, BrandName?: any, Channel?: any, CodeLength?: any, DestinationIdentity?: any, EntityId?: any, Language?: any, OriginationIdentity?: any, ReferenceId?: any, TemplateId?: any, ValidityPeriod?: any}
]: any -> record<MessageResponse: record<ApplicationId: record, EndpointResult: record, RequestId: record, Result: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/otp"))
  let req_body = {"SendOTPMessageRequestParameters": $send_otp_message_request_parameters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates and sends a message to a list of users.
#
# POST /v1/apps/{application-id}/users-messages
# operationId: SendUsersMessages
# --SendUsersMessageRequest shape: {Context?: any, MessageConfiguration?: any, TemplateConfiguration?: any, TraceId?: any, Users?: any}
export def "apps-users-messages send" [
  application_id: string
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
  send_users_message_request: record # Specifies the configuration and other settings for a message to send to all the endpoints that are associated with a list of users. — shape: {Context?: any, MessageConfiguration?: any, TemplateConfiguration?: any, TraceId?: any, Users?: any}
]: any -> record<SendUsersMessageResponse: record<ApplicationId: record, RequestId: record, Result: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/users-messages"))
  let req_body = {"SendUsersMessageRequest": $send_users_message_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes one or more tags (keys and values) from an application, campaign, message template, or segment.
#
# DELETE /v1/tags/{resource-arn}
# operationId: UntagResource
export def "tags untag" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list # The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource-arn' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v1/tags/{resource_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagKeys": $tag_keys} | compact), body: null}
}

# Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes for a batch of endpoints. If an update includes one or more values for a custom attribute, Amazon Pinpoint replaces (overwrites) any existing values with the new values.
#
# PUT /v1/apps/{application-id}/endpoints
# operationId: UpdateEndpointsBatch
# --EndpointBatchRequest shape: {Item?: any}
export def "apps-endpoints update-batch" [
  application_id: string
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
  endpoint_batch_request: record # Specifies a batch of endpoints to create or update and the settings and attributes to set or change for each endpoint. — shape: {Item?: any}
]: any -> record<MessageBody: record<Message: record, RequestID: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/endpoints"))
  let req_body = {"EndpointBatchRequest": $endpoint_batch_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Cancels (stops) an active journey.
#
# PUT /v1/apps/{application-id}/journeys/{journey-id}/state
# operationId: UpdateJourneyState
# --JourneyStateRequest shape: {State?: any}
export def "apps-journeys-state update" [
  application_id: string
  journey_id: string
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
  journey_state_request: record # Changes the status of a journey. — shape: {State?: any}
]: any -> record<JourneyResponse: record<Activities: record, ApplicationId: record, CreationDate: record, Id: record, LastModifiedDate: record, Limits: record<DailyCap: record, EndpointReentryCap: record, MessagesPerSecond: record, EndpointReentryInterval: record>, LocalTime: record, Name: record, QuietTime: record<End: record, Start: record>, RefreshFrequency: record, Schedule: record<EndTime: record, StartTime: record, Timezone: record>, StartActivity: record, StartCondition: record<Description: record, EventStartCondition: record, SegmentStartCondition: record>, State: record, tags: record, WaitForQuietTime: record, RefreshOnSegmentUpdate: record, JourneyChannelSettings: record<ConnectCampaignArn: record, ConnectCampaignExecutionRoleArn: record>, SendingSchedule: record, OpenHours: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>, ClosedDays: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  if ($journey_id | is-empty) { error make --unspanned { msg: "path parameter 'journey-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), journey_id: (encode-path-segment $journey_id)} | format pattern "/v1/apps/{application_id}/journeys/{journey_id}/state"))
  let req_body = {"JourneyStateRequest": $journey_state_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Changes the status of a specific version of a message template to active.
#
# PUT /v1/templates/{template-name}/{template-type}/active-version
# operationId: UpdateTemplateActiveVersion
# --TemplateActiveVersionRequest shape: {Version?: any}
export def "templates-active-version update" [
  template_name: string
  template_type: string
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
  template_active_version_request: record # Specifies which version of a message template to use as the active version of the template. — shape: {Version?: any}
]: any -> record<MessageBody: record<Message: record, RequestID: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'template-name' must be non-empty" } }
  if ($template_type | is-empty) { error make --unspanned { msg: "path parameter 'template-type' must be non-empty" } }
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name), template_type: (encode-path-segment $template_type)} | format pattern "/v1/templates/{template_name}/{template_type}/active-version"))
  let req_body = {"TemplateActiveVersionRequest": $template_active_version_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Verify an OTP
#
# POST /v1/apps/{application-id}/verify-otp
# operationId: VerifyOTPMessage
# --VerifyOTPMessageRequestParameters shape: {DestinationIdentity?: any, Otp?: any, ReferenceId?: any}
export def "apps-verify-otp verify-message" [
  application_id: string
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
  verify_otp_message_request_parameters: record # Verify OTP message request. — shape: {DestinationIdentity?: any, Otp?: any, ReferenceId?: any}
]: any -> record<VerificationResponse: record<Valid: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application-id' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/v1/apps/{application_id}/verify-otp"))
  let req_body = {"VerifyOTPMessageRequestParameters": $verify_otp_message_request_parameters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
