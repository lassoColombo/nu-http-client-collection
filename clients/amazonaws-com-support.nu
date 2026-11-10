# Auto-generated client for AWS Support v2013-04-15
# Source: https://api.apis.guru/v2/specs/amazonaws.com/support/2013-04-15/openapi.json
# Auth: --token flag or $env.AWS_SUPPORT_TOKEN

const BASE_URL = "https://support.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_SUPPORT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://support.us-east-1.amazonaws.com" "http://support.cn-north-1.amazonaws.com.cn" "http://support.cn-northwest-1.amazonaws.com.cn" "https://support.cn-north-1.amazonaws.com.cn" "https://support.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSSupport_20130415.AddAttachmentsToSet"] }
def x-amz-target-completer-1 [] { ["AWSSupport_20130415.AddCommunicationToCase"] }
def x-amz-target-completer-2 [] { ["AWSSupport_20130415.CreateCase"] }
def x-amz-target-completer-3 [] { ["AWSSupport_20130415.DescribeAttachment"] }
def x-amz-target-completer-4 [] { ["AWSSupport_20130415.DescribeCases"] }
def x-amz-target-completer-5 [] { ["AWSSupport_20130415.DescribeCommunications"] }
def x-amz-target-completer-6 [] { ["AWSSupport_20130415.DescribeServices"] }
def x-amz-target-completer-7 [] { ["AWSSupport_20130415.DescribeSeverityLevels"] }
def x-amz-target-completer-8 [] { ["AWSSupport_20130415.DescribeTrustedAdvisorCheckRefreshStatuses"] }
def x-amz-target-completer-9 [] { ["AWSSupport_20130415.DescribeTrustedAdvisorCheckResult"] }
def x-amz-target-completer-10 [] { ["AWSSupport_20130415.DescribeTrustedAdvisorCheckSummaries"] }
def x-amz-target-completer-11 [] { ["AWSSupport_20130415.DescribeTrustedAdvisorChecks"] }
def x-amz-target-completer-12 [] { ["AWSSupport_20130415.RefreshTrustedAdvisorCheck"] }
def x-amz-target-completer-13 [] { ["AWSSupport_20130415.ResolveCase"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["add-attachments-to-set" "add-communication-to-case" "create-case" "describe-attachment" "describe-cases" "describe-communications" "describe-services" "describe-severity-levels" "describe-trusted-advisor-check-refresh-statuses" "describe-trusted-advisor-check-result" "describe-trusted-advisor-check-summaries" "describe-trusted-advisor-checks" "refresh-trusted-advisor-check" "resolve-case" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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

# Adds one or more attachments to an attachment set. An attachment set is a temporary container for attachments that you add to a case or case communication. The set is available for 1 hour after it's created. The expiryTime returned in the response is when the set expires. You must have a Business, Enterprise On-Ramp, or Enterprise Support plan to use the Amazon Web Services Support API. If you call the Amazon Web Services Support API from an account that doesn't have a Business, Enterprise On-Ramp, or Enterprise Support plan, the SubscriptionRequiredException error message appears. For information about changing your support plan, see Amazon Web Services Support (http://aws.amazon.com/premiumsupport/).
#
# POST /
# operationId: AddAttachmentsToSet
export def "add-attachments-to-set" [
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
  --attachment-set-id: string # The ID of the attachment set. If an attachmentSetId is not specified, a new attachment set is created, and the ID of the set is returned in the response. If an attachmentSetId is specified, the attachments are added to the specified set, if it exists.
  attachments: list # One or more attachments to add to the set. You can add up to three attachments per set. The size limit is 5 MB per attachment. In the Attachment object, use the data parameter to specify the contents of the attachment file. In the previous request syntax, the value for data appear as blob, which is represented as a base64-encoded string. The value for fileName is the name of the attachment, such as troubleshoot-screenshot.png. — item shape: {fileName?: string, data?: string}
]: any -> oneof<record<attachmentSetId: string, expiryTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSupport_20130415.AddAttachmentsToSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"attachmentSetId": $attachment_set_id, "attachments": $attachments} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Adds additional customer communication to an Amazon Web Services Support case. Use the caseId parameter to identify the case to which to add communication. You can list a set of email addresses to copy on the communication by using the ccEmailAddresses parameter. The communicationBody value contains the text of the communication. You must have a Business, Enterprise On-Ramp, or Enterprise Support plan to use the Amazon Web Services Support API. If you call the Amazon Web Services Support API from an account that doesn't have a Business, Enterprise On-Ramp, or Enterprise Support plan, the SubscriptionRequiredException error message appears. For information about changing your support plan, see Amazon Web Services Support (http://aws.amazon.com/premiumsupport/).
#
# POST /
# operationId: AddCommunicationToCase
export def "add-communication-to-case" [
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
  --case-id: string # The support case ID requested or returned in the call. The case ID is an alphanumeric string formatted as shown in this example: case-12345678910-2013-c4c1d2bf33c5cf47
  communication_body: string # The body of an email communication to add to the support case.
  --cc-email-addresses: list<string> # The email addresses in the CC line of an email to be added to the support case.
  --attachment-set-id: string # The ID of a set of one or more attachments for the communication to add to the case. Create the set by calling AddAttachmentsToSet
]: any -> oneof<record<result: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSupport_20130415.AddCommunicationToCase")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"caseId": $case_id, "communicationBody": $communication_body, "ccEmailAddresses": $cc_email_addresses, "attachmentSetId": $attachment_set_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Creates a case in the Amazon Web Services Support Center. This operation is similar to how you create a case in the Amazon Web Services Support Center Create Case (https://console.aws.amazon.com/support/home#/case/create) page. The Amazon Web Services Support API doesn't support requesting service limit increases. You can submit a service limit increase in the following ways: Submit a request from the Amazon Web Services Support Center Create Case (https://console.aws.amazon.com/support/home#/case/create) page. Use the Service Quotas RequestServiceQuotaIncrease (https://docs.aws.amazon.com/servicequotas/2019-06-24/apireference/API_RequestServiceQuotaIncrease.html) operation. A successful CreateCase request returns an Amazon Web Services Support case number. You can use the DescribeCases operation and specify the case number to get existing Amazon Web Services Support cases. After you create a case, use the AddCommunicationToCase operation to add additional communication or attachments to an existing case. The caseId is separate from the displayId that appears in the Amazon Web Services Support Center (https://console.aws.amazon.com/support). Use the DescribeCases operation to get the displayId. You must have a Business, Enterprise On-Ramp, or Enterprise Support plan to use the Amazon Web Services Support API. If you call the Amazon Web Services Support API from an account that doesn't have a Business, Enterprise On-Ramp, or Enterprise Support plan, the SubscriptionRequiredException error message appears. For information about changing your support plan, see Amazon Web Services Support (http://aws.amazon.com/premiumsupport/).
#
# POST /
# operationId: CreateCase
export def "create-case" [
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
  subject: string # The title of the support case. The title appears in the Subject field on the Amazon Web Services Support Center Create Case (https://console.aws.amazon.com/support/home#/case/create) page.
  --service-code: string # The code for the Amazon Web Services service. You can use the DescribeServices operation to get the possible serviceCode values.
  --severity-code: string # A value that indicates the urgency of the case. This value determines the response time according to your service level agreement with Amazon Web Services Support. You can use the DescribeSeverityLevels operation to get the possible values for severityCode. For more information, see SeverityLevel and Choosing a Severity (https://docs.aws.amazon.com/awssupport/latest/user/getting-started.html#choosing-severity) in the Amazon Web Services Support User Guide. The availability of severity levels depends on the support plan for the Amazon Web Services account.
  --category-code: string # The category of problem for the support case. You also use the DescribeServices operation to get the category code for a service. Each Amazon Web Services service defines its own set of category codes.
  communication_body: string # The communication body text that describes the issue. This text appears in the Description field on the Amazon Web Services Support Center Create Case (https://console.aws.amazon.com/support/home#/case/create) page.
  --cc-email-addresses: list<string> # A list of email addresses that Amazon Web Services Support copies on case correspondence. Amazon Web Services Support identifies the account that creates the case when you specify your Amazon Web Services credentials in an HTTP POST method or use the Amazon Web Services SDKs (http://aws.amazon.com/tools/).
  --language: string # The language in which Amazon Web Services Support handles the case. Amazon Web Services Support currently supports English ("en") and Japanese ("ja"). You must specify the ISO 639-1 code for the language parameter if you want support in that language.
  --issue-type: string # The type of issue for the case. You can specify customer-service or technical. If you don't specify a value, the default is technical.
  --attachment-set-id: string # The ID of a set of one or more attachments for the case. Create the set by using the AddAttachmentsToSet operation.
]: any -> oneof<record<caseId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSupport_20130415.CreateCase")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"subject": $subject, "serviceCode": $service_code, "severityCode": $severity_code, "categoryCode": $category_code, "communicationBody": $communication_body, "ccEmailAddresses": $cc_email_addresses, "language": $language, "issueType": $issue_type, "attachmentSetId": $attachment_set_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Returns the attachment that has the specified ID. Attachments can include screenshots, error logs, or other files that describe your issue. Attachment IDs are generated by the case management system when you add an attachment to a case or case communication. Attachment IDs are returned in the AttachmentDetails objects that are returned by the DescribeCommunications operation. You must have a Business, Enterprise On-Ramp, or Enterprise Support plan to use the Amazon Web Services Support API. If you call the Amazon Web Services Support API from an account that doesn't have a Business, Enterprise On-Ramp, or Enterprise Support plan, the SubscriptionRequiredException error message appears. For information about changing your support plan, see Amazon Web Services Support (http://aws.amazon.com/premiumsupport/).
#
# POST /
# operationId: DescribeAttachment
export def "describe-attachment" [
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
  attachment_id: string # The ID of the attachment to return. Attachment IDs are returned by the DescribeCommunications operation.
]: any -> oneof<record<attachment: record<fileName: string, data: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSupport_20130415.DescribeAttachment")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"attachmentId": $attachment_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Returns a list of cases that you specify by passing one or more case IDs. You can use the afterTime and beforeTime parameters to filter the cases by date. You can set values for the includeResolvedCases and includeCommunications parameters to specify how much information to return. The response returns the following in JSON format: One or more CaseDetails (https://docs.aws.amazon.com/awssupport/latest/APIReference/API_CaseDetails.html) data types. One or more nextToken values, which specify where to paginate the returned records represented by the CaseDetails objects. Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request might return an error. You must have a Business, Enterprise On-Ramp, or Enterprise Support plan to use the Amazon Web Services Support API. If you call the Amazon Web Services Support API from an account that doesn't have a Business, Enterprise On-Ramp, or Enterprise Support plan, the SubscriptionRequiredException error message appears. For information about changing your support plan, see Amazon Web Services Support (http://aws.amazon.com/premiumsupport/).
#
# POST /
# operationId: DescribeCases
export def "describe-cases" [
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
  --x-amz-target: string@x-amz-target-completer-4 # required
  --case-id-list: list<string> # A list of ID numbers of the support cases you want returned. The maximum number of cases is 100.
  --display-id: string # The ID displayed for a case in the Amazon Web Services Support Center user interface.
  --after-time: string # The start date for a filtered date search on support case communications. Case communications are available for 12 months after creation.
  --before-time: string # The end date for a filtered date search on support case communications. Case communications are available for 12 months after creation.
  --include-resolved-cases: oneof<nothing, bool> # Specifies whether to include resolved support cases in the DescribeCases response. By default, resolved cases aren't included.
  --body-next-token: string # A resumption point for pagination. (spec name: nextToken)
  --body-max-results: int # The maximum number of results to return before paginating. (spec name: maxResults)
  --language: string # The language in which Amazon Web Services Support handles the case. Amazon Web Services Support currently supports English ("en") and Japanese ("ja"). You must specify the ISO 639-1 code for the language parameter if you want support in that language.
  --include-communications: oneof<nothing, bool> # Specifies whether to include communications in the DescribeCases response. By default, communications are included.
]: any -> oneof<record<cases: table<caseId: string, displayId: string, subject: string, status: string, serviceCode: string, categoryCode: string, severityCode: string, submittedBy: string, timeCreated: string, recentCommunications: record, ccEmailAddresses: list, language: string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSupport_20130415.DescribeCases")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"caseIdList": $case_id_list, "displayId": $display_id, "afterTime": $after_time, "beforeTime": $before_time, "includeResolvedCases": $include_resolved_cases, "nextToken": $body_next_token, "maxResults": $body_max_results, "language": $language, "includeCommunications": $include_communications} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns communications and attachments for one or more support cases. Use the afterTime and beforeTime parameters to filter by date. You can use the caseId parameter to restrict the results to a specific case. Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error. You can use the maxResults and nextToken parameters to control the pagination of the results. Set maxResults to the number of cases that you want to display on each page, and use nextToken to specify the resumption of pagination. You must have a Business, Enterprise On-Ramp, or Enterprise Support plan to use the Amazon Web Services Support API. If you call the Amazon Web Services Support API from an account that doesn't have a Business, Enterprise On-Ramp, or Enterprise Support plan, the SubscriptionRequiredException error message appears. For information about changing your support plan, see Amazon Web Services Support (http://aws.amazon.com/premiumsupport/).
#
# POST /
# operationId: DescribeCommunications
export def "describe-communications" [
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
  --x-amz-target: string@x-amz-target-completer-5 # required
  case_id: string # The support case ID requested or returned in the call. The case ID is an alphanumeric string formatted as shown in this example: case-12345678910-2013-c4c1d2bf33c5cf47
  --before-time: string # The end date for a filtered date search on support case communications. Case communications are available for 12 months after creation.
  --after-time: string # The start date for a filtered date search on support case communications. Case communications are available for 12 months after creation.
  --body-next-token: string # A resumption point for pagination. (spec name: nextToken)
  --body-max-results: int # The maximum number of results to return before paginating. (spec name: maxResults)
]: any -> oneof<record<communications: table<caseId: string, body: string, submittedBy: string, timeCreated: string, attachmentSet: list>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSupport_20130415.DescribeCommunications")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"caseId": $case_id, "beforeTime": $before_time, "afterTime": $after_time, "nextToken": $body_next_token, "maxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the current list of Amazon Web Services services and a list of service categories for each service. You then use service names and categories in your CreateCase requests. Each Amazon Web Services service has its own set of categories. The service codes and category codes correspond to the values that appear in the Service and Category lists on the Amazon Web Services Support Center Create Case (https://console.aws.amazon.com/support/home#/case/create) page. The values in those fields don't necessarily match the service codes and categories returned by the DescribeServices operation. Always use the service codes and categories that the DescribeServices operation returns, so that you have the most recent set of service and category codes. You must have a Business, Enterprise On-Ramp, or Enterprise Support plan to use the Amazon Web Services Support API. If you call the Amazon Web Services Support API from an account that doesn't have a Business, Enterprise On-Ramp, or Enterprise Support plan, the SubscriptionRequiredException error message appears. For information about changing your support plan, see Amazon Web Services Support (http://aws.amazon.com/premiumsupport/).
#
# POST /
# operationId: DescribeServices
export def "describe-services" [
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
  --service-code-list: list<string> # A JSON-formatted list of service codes available for Amazon Web Services services.
  --language: string # The language in which Amazon Web Services Support handles the case. Amazon Web Services Support currently supports English ("en") and Japanese ("ja"). You must specify the ISO 639-1 code for the language parameter if you want support in that language.
]: any -> oneof<record<services: table<code: string, name: string, categories: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSupport_20130415.DescribeServices")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"serviceCodeList": $service_code_list, "language": $language} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Returns the list of severity levels that you can assign to a support case. The severity level for a case is also a field in the CaseDetails data type that you include for a CreateCase request. You must have a Business, Enterprise On-Ramp, or Enterprise Support plan to use the Amazon Web Services Support API. If you call the Amazon Web Services Support API from an account that doesn't have a Business, Enterprise On-Ramp, or Enterprise Support plan, the SubscriptionRequiredException error message appears. For information about changing your support plan, see Amazon Web Services Support (http://aws.amazon.com/premiumsupport/).
#
# POST /
# operationId: DescribeSeverityLevels
export def "describe-severity-levels" [
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
  --language: string # The language in which Amazon Web Services Support handles the case. Amazon Web Services Support currently supports English ("en") and Japanese ("ja"). You must specify the ISO 639-1 code for the language parameter if you want support in that language.
]: any -> oneof<record<severityLevels: table<code: string, name: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSupport_20130415.DescribeSeverityLevels")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"language": $language} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Returns the refresh status of the Trusted Advisor checks that have the specified check IDs. You can get the check IDs by calling the DescribeTrustedAdvisorChecks operation. Some checks are refreshed automatically, and you can't return their refresh statuses by using the DescribeTrustedAdvisorCheckRefreshStatuses operation. If you call this operation for these checks, you might see an InvalidParameterValue error. You must have a Business, Enterprise On-Ramp, or Enterprise Support plan to use the Amazon Web Services Support API. If you call the Amazon Web Services Support API from an account that doesn't have a Business, Enterprise On-Ramp, or Enterprise Support plan, the SubscriptionRequiredException error message appears. For information about changing your support plan, see Amazon Web Services Support (http://aws.amazon.com/premiumsupport/). To call the Trusted Advisor operations in the Amazon Web Services Support API, you must use the US East (N. Virginia) endpoint. Currently, the US West (Oregon) and Europe (Ireland) endpoints don't support the Trusted Advisor operations. For more information, see About the Amazon Web Services Support API (https://docs.aws.amazon.com/awssupport/latest/user/about-support-api.html#endpoint) in the Amazon Web Services Support User Guide.
#
# POST /
# operationId: DescribeTrustedAdvisorCheckRefreshStatuses
export def "describe-trusted-advisor-check-refresh-statuses" [
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
  check_ids: list<string> # The IDs of the Trusted Advisor checks to get the status. If you specify the check ID of a check that is automatically refreshed, you might see an InvalidParameterValue error.
]: any -> oneof<record<statuses: table<checkId: string, status: string, millisUntilNextRefreshable: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSupport_20130415.DescribeTrustedAdvisorCheckRefreshStatuses")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"checkIds": $check_ids} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Returns the results of the Trusted Advisor check that has the specified check ID. You can get the check IDs by calling the DescribeTrustedAdvisorChecks operation. The response contains a TrustedAdvisorCheckResult object, which contains these three objects: TrustedAdvisorCategorySpecificSummary TrustedAdvisorResourceDetail TrustedAdvisorResourcesSummary In addition, the response contains these fields: status - The alert status of the check can be ok (green), warning (yellow), error (red), or not_available. timestamp - The time of the last refresh of the check. checkId - The unique identifier for the check. You must have a Business, Enterprise On-Ramp, or Enterprise Support plan to use the Amazon Web Services Support API. If you call the Amazon Web Services Support API from an account that doesn't have a Business, Enterprise On-Ramp, or Enterprise Support plan, the SubscriptionRequiredException error message appears. For information about changing your support plan, see Amazon Web Services Support (http://aws.amazon.com/premiumsupport/). To call the Trusted Advisor operations in the Amazon Web Services Support API, you must use the US East (N. Virginia) endpoint. Currently, the US West (Oregon) and Europe (Ireland) endpoints don't support the Trusted Advisor operations. For more information, see About the Amazon Web Services Support API (https://docs.aws.amazon.com/awssupport/latest/user/about-support-api.html#endpoint) in the Amazon Web Services Support User Guide.
#
# POST /
# operationId: DescribeTrustedAdvisorCheckResult
export def "describe-trusted-advisor-check-result" [
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
  check_id: string # The unique identifier for the Trusted Advisor check.
  --language: string # The ISO 639-1 code for the language that you want your check results to appear in. The Amazon Web Services Support API currently supports the following languages for Trusted Advisor: Chinese, Simplified - zh Chinese, Traditional - zh_TW English - en French - fr German - de Indonesian - id Italian - it Japanese - ja Korean - ko Portuguese, Brazilian - pt_BR Spanish - es
]: any -> oneof<record<result: record<checkId: string, timestamp: string, status: string, resourcesSummary: record<resourcesProcessed: int, resourcesFlagged: int, resourcesIgnored: int, resourcesSuppressed: int>, categorySpecificSummary: record<costOptimizing: record>, flaggedResources: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSupport_20130415.DescribeTrustedAdvisorCheckResult")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"checkId": $check_id, "language": $language} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Returns the results for the Trusted Advisor check summaries for the check IDs that you specified. You can get the check IDs by calling the DescribeTrustedAdvisorChecks operation. The response contains an array of TrustedAdvisorCheckSummary objects. You must have a Business, Enterprise On-Ramp, or Enterprise Support plan to use the Amazon Web Services Support API. If you call the Amazon Web Services Support API from an account that doesn't have a Business, Enterprise On-Ramp, or Enterprise Support plan, the SubscriptionRequiredException error message appears. For information about changing your support plan, see Amazon Web Services Support (http://aws.amazon.com/premiumsupport/). To call the Trusted Advisor operations in the Amazon Web Services Support API, you must use the US East (N. Virginia) endpoint. Currently, the US West (Oregon) and Europe (Ireland) endpoints don't support the Trusted Advisor operations. For more information, see About the Amazon Web Services Support API (https://docs.aws.amazon.com/awssupport/latest/user/about-support-api.html#endpoint) in the Amazon Web Services Support User Guide.
#
# POST /
# operationId: DescribeTrustedAdvisorCheckSummaries
export def "describe-trusted-advisor-check-summaries" [
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
  --x-amz-target: string@x-amz-target-completer-10 # required
  check_ids: list<string> # The IDs of the Trusted Advisor checks.
]: any -> oneof<record<summaries: table<checkId: string, timestamp: string, status: string, hasFlaggedResources: bool, resourcesSummary: record, categorySpecificSummary: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSupport_20130415.DescribeTrustedAdvisorCheckSummaries")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"checkIds": $check_ids} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Returns information about all available Trusted Advisor checks, including the name, ID, category, description, and metadata. You must specify a language code. The response contains a TrustedAdvisorCheckDescription object for each check. You must set the Amazon Web Services Region to us-east-1. You must have a Business, Enterprise On-Ramp, or Enterprise Support plan to use the Amazon Web Services Support API. If you call the Amazon Web Services Support API from an account that doesn't have a Business, Enterprise On-Ramp, or Enterprise Support plan, the SubscriptionRequiredException error message appears. For information about changing your support plan, see Amazon Web Services Support (http://aws.amazon.com/premiumsupport/). The names and descriptions for Trusted Advisor checks are subject to change. We recommend that you specify the check ID in your code to uniquely identify a check. To call the Trusted Advisor operations in the Amazon Web Services Support API, you must use the US East (N. Virginia) endpoint. Currently, the US West (Oregon) and Europe (Ireland) endpoints don't support the Trusted Advisor operations. For more information, see About the Amazon Web Services Support API (https://docs.aws.amazon.com/awssupport/latest/user/about-support-api.html#endpoint) in the Amazon Web Services Support User Guide.
#
# POST /
# operationId: DescribeTrustedAdvisorChecks
export def "describe-trusted-advisor-checks" [
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
  --x-amz-target: string@x-amz-target-completer-11 # required
  language: string # The ISO 639-1 code for the language that you want your checks to appear in. The Amazon Web Services Support API currently supports the following languages for Trusted Advisor: Chinese, Simplified - zh Chinese, Traditional - zh_TW English - en French - fr German - de Indonesian - id Italian - it Japanese - ja Korean - ko Portuguese, Brazilian - pt_BR Spanish - es
]: any -> oneof<record<checks: table<id: string, name: string, description: string, category: string, metadata: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSupport_20130415.DescribeTrustedAdvisorChecks")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"language": $language} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Refreshes the Trusted Advisor check that you specify using the check ID. You can get the check IDs by calling the DescribeTrustedAdvisorChecks operation. Some checks are refreshed automatically. If you call the RefreshTrustedAdvisorCheck operation to refresh them, you might see the InvalidParameterValue error. The response contains a TrustedAdvisorCheckRefreshStatus object. You must have a Business, Enterprise On-Ramp, or Enterprise Support plan to use the Amazon Web Services Support API. If you call the Amazon Web Services Support API from an account that doesn't have a Business, Enterprise On-Ramp, or Enterprise Support plan, the SubscriptionRequiredException error message appears. For information about changing your support plan, see Amazon Web Services Support (http://aws.amazon.com/premiumsupport/). To call the Trusted Advisor operations in the Amazon Web Services Support API, you must use the US East (N. Virginia) endpoint. Currently, the US West (Oregon) and Europe (Ireland) endpoints don't support the Trusted Advisor operations. For more information, see About the Amazon Web Services Support API (https://docs.aws.amazon.com/awssupport/latest/user/about-support-api.html#endpoint) in the Amazon Web Services Support User Guide.
#
# POST /
# operationId: RefreshTrustedAdvisorCheck
export def "refresh-trusted-advisor-check" [
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
  --x-amz-target: string@x-amz-target-completer-12 # required
  check_id: string # The unique identifier for the Trusted Advisor check to refresh. Specifying the check ID of a check that is automatically refreshed causes an InvalidParameterValue error.
]: any -> oneof<record<status: record<checkId: string, status: string, millisUntilNextRefreshable: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSupport_20130415.RefreshTrustedAdvisorCheck")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"checkId": $check_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Resolves a support case. This operation takes a caseId and returns the initial and final state of the case. You must have a Business, Enterprise On-Ramp, or Enterprise Support plan to use the Amazon Web Services Support API. If you call the Amazon Web Services Support API from an account that doesn't have a Business, Enterprise On-Ramp, or Enterprise Support plan, the SubscriptionRequiredException error message appears. For information about changing your support plan, see Amazon Web Services Support (http://aws.amazon.com/premiumsupport/).
#
# POST /
# operationId: ResolveCase
export def "resolve-case" [
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
  --x-amz-target: string@x-amz-target-completer-13 # required
  --case-id: string # The support case ID requested or returned in the call. The case ID is an alphanumeric string formatted as shown in this example: case-12345678910-2013-c4c1d2bf33c5cf47
]: any -> oneof<record<initialCaseStatus: string, finalCaseStatus: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSupport_20130415.ResolveCase")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"caseId": $case_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
