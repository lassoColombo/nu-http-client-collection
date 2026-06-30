# Auto-generated client for Postmark API v1.0.0
# Source: https://api.apis.guru/v2/specs/postmarkapp.com/server/1.0.0/swagger.json
# Auth: --token flag or $env.POSTMARK_API_TOKEN

const BASE_URL = "https://api.postmarkapp.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o POSTMARK_API_TOKEN | default "" }
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

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.postmarkapp.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["AddressChange" "AutoResponder" "BadEmailAddress" "Blocked" "DMARCPolicy" "DnsError" "HardBounce" "InboundError" "MailFrontier Matador." "ManuallyDeactivated" "OpenRelayTest" "SMTPApiError" "SoftBounce" "SpamComplaint" "SpamNotification" "Subscribe" "TemplateRenderingFailed" "Transient" "Unconfirmed" "Unknown" "Unsubscribe" "VirusNotification"] }
def track-links-completer [] { ["HtmlAndText" "HtmlOnly" "None" "TextOnly"] }
def status-completer [] { ["blocked" "failed" "processed" "queued" "scheduled"] }
def status-completer-1 [] { ["queued" "sent"] }
def color-completer [] { ["blue" "green" "grey" "purple" "red" "turqoise" "yellow"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bounces get" } } | get name | first)
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

# Get bounces
#
# GET /bounces
# operationId: getBounces
export def "bounces get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of bounces to return per request. Max 500.
  --offset: int # Number of bounces to skip.
  --type: string@type-completer # Filter by type of bounce
  --inactive: oneof<nothing, bool> # Filter by emails that were deactivated by Postmark due to the bounce. Set to true or false. If this isn't specified it will return both active and inactive.
  --email-filter: string # Filter by email address (format: email)
  --message-id: string # Filter by messageID
  --tag: string # Filter by tag
  --todate: string # Filter messages up to the date specified. e.g. `2014-02-01` (format: date)
  --fromdate: string # Filter messages starting from the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Bounces: table<BouncedAt: string, CanActivate: bool, Content: string, Description: string, Details: string, DumpAvailable: bool, Email: string, ID: string, Inactive: bool, MessageID: string, Name: string, Subject: string, Tag: string, Type: string, TypeCode: int>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "inactive" $inactive "scalar") (serialize-qp "emailFilter" $email_filter "scalar") (serialize-qp "messageID" $message_id "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "fromdate" $fromdate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bounces" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count, "offset": $offset, "type": $type, "inactive": $inactive, "emailFilter": $email_filter, "messageID": $message_id, "tag": $tag, "todate": $todate, "fromdate": $fromdate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a single bounce
#
# GET /bounces/{bounceid}
# operationId: getSingleBounce
export def "bounces get-single" [
  bounceid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<BouncedAt: string, CanActivate: bool, Content: string, Description: string, Details: string, DumpAvailable: bool, Email: string, ID: string, Inactive: bool, MessageID: string, Name: string, Subject: string, Tag: string, Type: string, TypeCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bounceid | is-empty) { error make --unspanned { msg: "path parameter 'bounceid' must be non-empty" } }
  let full_url = (build-url $base ({bounceid: (encode-path-segment $bounceid)} | format pattern "/bounces/{bounceid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Activate a bounce
#
# PUT /bounces/{bounceid}/activate
# operationId: activateBounce
export def "bounces-activate update" [
  bounceid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Bounce: record<BouncedAt: string, CanActivate: bool, Content: string, Description: string, Details: string, DumpAvailable: bool, Email: string, ID: string, Inactive: bool, MessageID: string, Name: string, Subject: string, Tag: string, Type: string, TypeCode: int>, Message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bounceid | is-empty) { error make --unspanned { msg: "path parameter 'bounceid' must be non-empty" } }
  let full_url = (build-url $base ({bounceid: (encode-path-segment $bounceid)} | format pattern "/bounces/{bounceid}/activate") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get bounce dump
#
# GET /bounces/{bounceid}/dump
export def "bounces-dump get" [
  bounceid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Body: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bounceid | is-empty) { error make --unspanned { msg: "path parameter 'bounceid' must be non-empty" } }
  let full_url = (build-url $base ({bounceid: (encode-path-segment $bounceid)} | format pattern "/bounces/{bounceid}/dump") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get delivery stats
#
# GET /deliverystats
# operationId: getDeliveryStats
export def "deliverystats get-delivery-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Bounces: table<Count: int, Name: string, Type: string>, InactiveMails: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deliverystats" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Send a single email
#
# POST /email
# operationId: sendEmail
# --Attachments item shape: {Content?: string, ContentID?: string, ContentType?: string, Name?: string}
# --Headers item shape: {Name?: string, Value?: string}
export def "email send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
  --attachments: list # item shape: {Content?: string, ContentID?: string, ContentType?: string, Name?: string}
  --bcc: string # Bcc recipient email address. Multiple addresses are comma seperated. Max 50.
  --cc: string # Recipient email address. Multiple addresses are comma seperated. Max 50.
  --body-from: string # The sender email address. Must have a registered and confirmed Sender Signature.
  --headers: list # item shape: {Name?: string, Value?: string}
  --html-body: string # If no TextBody specified HTML email message
  --reply-to: string # Reply To override email address. Defaults to the Reply To set in the sender signature.
  --subject: string # Email Subject
  --tag: string # Email tag that allows you to categorize outgoing emails and get detailed statistics.
  --text-body: string # If no HtmlBody specified Plain text email message
  --body-to: string # Recipient email address. Multiple addresses are comma seperated. Max 50.
  --track-links: string@track-links-completer # Replace links in content to enable "click tracking" stats. Default is 'null', which uses the server's LinkTracking setting'.
  --track-opens: oneof<nothing, bool> # Activate open tracking for this email.
]: any -> record<ErrorCode: int, Message: string, MessageID: string, SubmittedAt: string, To: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/email" $auth.query)
  let req_body = {"Attachments": $attachments, "Bcc": $bcc, "Cc": $cc, "From": $body_from, "Headers": $headers, "HtmlBody": $html_body, "ReplyTo": $reply_to, "Subject": $subject, "Tag": $tag, "TextBody": $text_body, "To": $body_to, "TrackLinks": $track_links, "TrackOpens": $track_opens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
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

# Send a batch of emails
#
# POST /email/batch
# operationId: sendEmailBatch
export def "email-batch send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
  --body: list
]: any -> table<ErrorCode: int, Message: string, MessageID: string, SubmittedAt: string, To: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/email/batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
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

# Send a batch of email using templates.
#
# POST /email/batchWithTemplates
# operationId: sendEmailBatchWithTemplates
# --Messages item shape: {Attachments?: list, Bcc?: string, Cc?: string, From: string, Headers?: list, InlineCss?: bool, ReplyTo?: string, Tag?: string, TemplateAlias: string, TemplateId: int, TemplateModel: record, To: string, TrackLinks?: "None"|"HtmlAndText"|"HtmlOnly"|"TextOnly", TrackOpens?: bool}
export def "email-batch-with-templates send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
  --messages: list # item shape: {Attachments?: list, Bcc?: string, Cc?: string, From: string, Headers?: list, InlineCss?: bool, ReplyTo?: string, Tag?: string, TemplateAlias: string, TemplateId: int, TemplateModel: record, To: string, TrackLinks?: "None"|"HtmlAndText"|"HtmlOnly"|"TextOnly", TrackOpens?: bool}
]: any -> table<ErrorCode: int, Message: string, MessageID: string, SubmittedAt: string, To: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/email/batchWithTemplates" $auth.query)
  let req_body = {"Messages": $messages} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
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

# Send an email using a Template
#
# POST /email/withTemplate
# operationId: sendEmailWithTemplate
# --Attachments item shape: {Content?: string, ContentID?: string, ContentType?: string, Name?: string}
# --Headers item shape: {Name?: string, Value?: string}
export def "email-with-template send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
  --attachments: list # item shape: {Content?: string, ContentID?: string, ContentType?: string, Name?: string}
  --bcc: string # format: email
  --cc: string # format: email
  --body-from: string # format: email
  --headers: list # item shape: {Name?: string, Value?: string}
  --inline-css: oneof<nothing, bool> # default: true
  --reply-to: string
  --tag: string
  template_alias: string # Required if 'TemplateId' is not specified.
  template_id: int # Required if 'TemplateAlias' is not specified.
  template_model: record
  --body-to: string # format: email
  --track-links: string@track-links-completer # Replace links in content to enable "click tracking" stats. Default is 'null', which uses the server's LinkTracking setting'.
  --track-opens: oneof<nothing, bool> # Activate open tracking for this email.
]: any -> record<ErrorCode: int, Message: string, MessageID: string, SubmittedAt: string, To: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/email/withTemplate" $auth.query)
  let req_body = {"Attachments": $attachments, "Bcc": $bcc, "Cc": $cc, "From": $body_from, "Headers": $headers, "InlineCss": $inline_css, "ReplyTo": $reply_to, "Tag": $tag, "TemplateAlias": $template_alias, "TemplateId": $template_id, "TemplateModel": $template_model, "To": $body_to, "TrackLinks": $track_links, "TrackOpens": $track_opens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
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

# Inbound message search
#
# GET /messages/inbound
# operationId: searchInboundMessages
export def "messages-inbound list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of messages to return per request. Max 500.
  --offset: int # Number of messages to skip
  --recipient: string # Filter by the user who was receiving the email (format: email)
  --fromemail: string # Filter by the sender email address (format: email)
  --subject: string # Filter by email subject
  --mailboxhash: string # Filter by mailboxhash
  --tag: string # Filter by tag
  --status: string@status-completer # Filter by status (`blocked`, `processed`, `queued`, `failed`, `scheduled`)
  --todate: string # Filter messages up to the date specified. e.g. `2014-02-01` (format: date)
  --fromdate: string # Filter messages starting from the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<InboundMessages: table<Attachments: list, Cc: string, CcFull: list, Date: string, From: string, FromFull: record, FromName: string, MailboxHash: string, MessageID: string, OriginalRecipient: string, ReplyTo: string, Status: string, Subject: string, Tag: string, To: string, ToFull: list>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "recipient" $recipient "scalar") (serialize-qp "fromemail" $fromemail "scalar") (serialize-qp "subject" $subject "scalar") (serialize-qp "mailboxhash" $mailboxhash "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "fromdate" $fromdate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages/inbound" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count, "offset": $offset, "recipient": $recipient, "fromemail": $fromemail, "subject": $subject, "mailboxhash": $mailboxhash, "tag": $tag, "status": $status, "todate": $todate, "fromdate": $fromdate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Bypass rules for a blocked inbound message
#
# PUT /messages/inbound/{messageid}/bypass
# operationId: bypassRulesForInboundMessage
export def "messages-inbound-bypass update-rules" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<ErrorCode: int, Message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($messageid | is-empty) { error make --unspanned { msg: "path parameter 'messageid' must be non-empty" } }
  let full_url = (build-url $base ({messageid: (encode-path-segment $messageid)} | format pattern "/messages/inbound/{messageid}/bypass") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Inbound message details
#
# GET /messages/inbound/{messageid}/details
# operationId: getInboundMessageDetails
export def "messages-inbound-details get" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Attachments: table<Content: string, ContentID: string, ContentType: string, Name: string>, BlockedReason: string, Cc: string, CcFull: table<Email: string, Name: string>, Date: string, From: string, FromFull: record<Email: string, Name: string>, FromName: string, Headers: table<Name: string, Value: string>, HtmlBody: string, MailboxHash: string, MessageID: string, OriginalRecipient: string, ReplyTo: string, Status: string, Subject: string, Tag: string, TextBody: string, To: string, ToFull: table<Email: string, Name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($messageid | is-empty) { error make --unspanned { msg: "path parameter 'messageid' must be non-empty" } }
  let full_url = (build-url $base ({messageid: (encode-path-segment $messageid)} | format pattern "/messages/inbound/{messageid}/details") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retry a failed inbound message for processing
#
# PUT /messages/inbound/{messageid}/retry
# operationId: retryInboundMessageProcessing
export def "messages-inbound-retry update-processing" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<ErrorCode: int, Message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($messageid | is-empty) { error make --unspanned { msg: "path parameter 'messageid' must be non-empty" } }
  let full_url = (build-url $base ({messageid: (encode-path-segment $messageid)} | format pattern "/messages/inbound/{messageid}/retry") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Outbound message search
#
# GET /messages/outbound
# operationId: searchOutboundMessages
export def "messages-outbound list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of messages to return per request. Max 500.
  --offset: int # Number of messages to skip
  --recipient: string # Filter by the user who was receiving the email (format: email)
  --fromemail: string # Filter by the sender email address (format: email)
  --tag: string # Filter by tag
  --status: string@status-completer-1 # Filter by status (`queued` or `sent`)
  --todate: string # Filter messages up to the date specified. e.g. `2014-02-01` (format: date)
  --fromdate: string # Filter messages starting from the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Messages: table<Attachments: list, Bcc: list, Cc: list, From: string, MessageID: string, ReceivedAt: string, Recipients: list, Status: string, Subject: string, Tag: string, To: list, TrackLinks: string, TrackOpens: bool>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "recipient" $recipient "scalar") (serialize-qp "fromemail" $fromemail "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "fromdate" $fromdate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages/outbound" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count, "offset": $offset, "recipient": $recipient, "fromemail": $fromemail, "tag": $tag, "status": $status, "todate": $todate, "fromdate": $fromdate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Clicks for a all messages
#
# GET /messages/outbound/clicks
# operationId: searchClicksForOutboundMessages
export def "messages-outbound-clicks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of message clicks to return per request. Max 500.
  --offset: int # Number of messages to skip
  --recipient: string # Filter by To, Cc, Bcc
  --tag: string # Filter by tag
  --client-name: string # Filter by client name, i.e. Outlook, Gmail
  --client-company: string # Filter by company, i.e. Microsoft, Apple, Google
  --client-family: string # Filter by client family, i.e. OS X, Chrome
  --os-name: string # Filter by full OS name and specific version, i.e. OS X 10.9 Mavericks, Windows 7
  --os-family: string # Filter by kind of OS used without specific version, i.e. OS X, Windows
  --os-company: string # Filter by company which produced the OS, i.e. Apple Computer, Inc., Microsoft Corporation
  --platform: string # Filter by platform, i.e. webmail, desktop, mobile
  --country: string # Filter by country messages were opened in, i.e. Denmark, Russia
  --region: string # Filter by full name of region messages were opened in, i.e. Moscow, New York
  --city: string # Filter by full name of region messages were opened in, i.e. Moscow, New York
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Clicks: table<ClickLocation: string, Client: record, Geo: record, MessageID: string, OS: record, OriginalLink: string, Platform: string, ReceivedAt: string, Recipient: string, Tag: string, UserAgent: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "recipient" $recipient "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "client_name" $client_name "scalar") (serialize-qp "client_company" $client_company "scalar") (serialize-qp "client_family" $client_family "scalar") (serialize-qp "os_name" $os_name "scalar") (serialize-qp "os_family" $os_family "scalar") (serialize-qp "os_company" $os_company "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "city" $city "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages/outbound/clicks" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count, "offset": $offset, "recipient": $recipient, "tag": $tag, "client_name": $client_name, "client_company": $client_company, "client_family": $client_family, "os_name": $os_name, "os_family": $os_family, "os_company": $os_company, "platform": $platform, "country": $country, "region": $region, "city": $city} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve Message Clicks
#
# GET /messages/outbound/clicks/{messageid}
# operationId: getClicksForSingleOutboundMessage
export def "messages-outbound-clicks get-for-single" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of message clicks to return per request. Max 500. (default: 1)
  --offset: int # Number of messages to skip. (default: 0)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Clicks: table<ClickLocation: string, Client: record, Geo: record, MessageID: string, OS: record, OriginalLink: string, Platform: string, ReceivedAt: string, Recipient: string, Tag: string, UserAgent: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($messageid | is-empty) { error make --unspanned { msg: "path parameter 'messageid' must be non-empty" } }
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({messageid: (encode-path-segment $messageid)} | format pattern "/messages/outbound/clicks/{messageid}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Opens for all messages
#
# GET /messages/outbound/opens
# operationId: searchOpensForOutboundMessages
export def "messages-outbound-opens list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of message opens to return per request. Max 500.
  --offset: int # Number of messages to skip
  --recipient: string # Filter by To, Cc, Bcc
  --tag: string # Filter by tag
  --client-name: string # Filter by client name, i.e. Outlook, Gmail
  --client-company: string # Filter by company, i.e. Microsoft, Apple, Google
  --client-family: string # Filter by client family, i.e. OS X, Chrome
  --os-name: string # Filter by full OS name and specific version, i.e. OS X 10.9 Mavericks, Windows 7
  --os-family: string # Filter by kind of OS used without specific version, i.e. OS X, Windows
  --os-company: string # Filter by company which produced the OS, i.e. Apple Computer, Inc., Microsoft Corporation
  --platform: string # Filter by platform, i.e. webmail, desktop, mobile
  --country: string # Filter by country messages were opened in, i.e. Denmark, Russia
  --region: string # Filter by full name of region messages were opened in, i.e. Moscow, New York
  --city: string # Filter by full name of region messages were opened in, i.e. Moscow, New York
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Opens: table<Client: record, FirstOpen: bool, Geo: record, MessageID: string, OS: record, Platform: string, ReceivedAt: string, Recipient: string, Tag: string, UserAgent: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "recipient" $recipient "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "client_name" $client_name "scalar") (serialize-qp "client_company" $client_company "scalar") (serialize-qp "client_family" $client_family "scalar") (serialize-qp "os_name" $os_name "scalar") (serialize-qp "os_family" $os_family "scalar") (serialize-qp "os_company" $os_company "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "city" $city "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages/outbound/opens" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count, "offset": $offset, "recipient": $recipient, "tag": $tag, "client_name": $client_name, "client_company": $client_company, "client_family": $client_family, "os_name": $os_name, "os_family": $os_family, "os_company": $os_company, "platform": $platform, "country": $country, "region": $region, "city": $city} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve Message Opens
#
# GET /messages/outbound/opens/{messageid}
# operationId: getOpensForSingleOutboundMessage
export def "messages-outbound-opens get-for-single" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of message opens to return per request. Max 500. (default: 1)
  --offset: int # Number of messages to skip. (default: 0)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Opens: table<Client: record, FirstOpen: bool, Geo: record, MessageID: string, OS: record, Platform: string, ReceivedAt: string, Recipient: string, Tag: string, UserAgent: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($messageid | is-empty) { error make --unspanned { msg: "path parameter 'messageid' must be non-empty" } }
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({messageid: (encode-path-segment $messageid)} | format pattern "/messages/outbound/opens/{messageid}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Outbound message details
#
# GET /messages/outbound/{messageid}/details
# operationId: getOutboundMessageDetails
export def "messages-outbound-details get" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Attachments: table<Content: string, ContentID: string, ContentType: string, Name: string>, Bcc: table<Email: string, Name: string>, Body: string, Cc: table<Email: string, Name: string>, From: string, HtmlBody: string, MessageEvents: table<Details: record, ReceivedAt: string, Recipient: string, Type: string>, MessageID: string, ReceivedAt: string, Recipients: list<string>, Status: string, Subject: string, Tag: string, TextBody: string, To: table<Email: string, Name: string>, TrackLinks: string, TrackOpens: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($messageid | is-empty) { error make --unspanned { msg: "path parameter 'messageid' must be non-empty" } }
  let full_url = (build-url $base ({messageid: (encode-path-segment $messageid)} | format pattern "/messages/outbound/{messageid}/details") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Outbound message dump
#
# GET /messages/outbound/{messageid}/dump
# operationId: getOutboundMessageDump
export def "messages-outbound-dump get" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Body: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($messageid | is-empty) { error make --unspanned { msg: "path parameter 'messageid' must be non-empty" } }
  let full_url = (build-url $base ({messageid: (encode-path-segment $messageid)} | format pattern "/messages/outbound/{messageid}/dump") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Server Configuration
#
# GET /server
# operationId: getCurrentServerConfiguration
export def "server get-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<ApiTokens: list<string>, BounceHookUrl: string, ClickHookUrl: string, Color: string, DeliveryHookUrl: string, ID: int, InboundAddress: string, InboundDomain: string, InboundHash: string, InboundHookUrl: string, InboundSpamThreshold: int, Name: string, OpenHookUrl: string, PostFirstOpenOnly: bool, RawEmailEnabled: bool, ServerLink: string, SmtpApiActivated: bool, TrackLinks: string, TrackOpens: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/server" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Edit Server Configuration
#
# PUT /server
# operationId: editCurrentServerConfiguration
export def "server get-edit-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
  --bounce-hook-url: string
  --click-hook-url: string # Webhook url allowing real-time notification when tracked links are clicked.
  --color: string@color-completer
  --delivery-hook-url: string
  --inbound-domain: string
  --inbound-hook-url: string
  --inbound-spam-threshold: int
  --name: string
  --open-hook-url: string
  --post-first-open-only: oneof<nothing, bool>
  --raw-email-enabled: oneof<nothing, bool>
  --smtp-api-activated: oneof<nothing, bool>
  --track-links: string@track-links-completer
  --track-opens: oneof<nothing, bool>
]: any -> record<ApiTokens: list<string>, BounceHookUrl: string, ClickHookUrl: string, Color: string, DeliveryHookUrl: string, ID: int, InboundAddress: string, InboundDomain: string, InboundHash: string, InboundHookUrl: string, InboundSpamThreshold: int, Name: string, OpenHookUrl: string, PostFirstOpenOnly: bool, RawEmailEnabled: bool, ServerLink: string, SmtpApiActivated: bool, TrackLinks: string, TrackOpens: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/server" $auth.query)
  let req_body = {"BounceHookUrl": $bounce_hook_url, "ClickHookUrl": $click_hook_url, "Color": $color, "DeliveryHookUrl": $delivery_hook_url, "InboundDomain": $inbound_domain, "InboundHookUrl": $inbound_hook_url, "InboundSpamThreshold": $inbound_spam_threshold, "Name": $name, "OpenHookUrl": $open_hook_url, "PostFirstOpenOnly": $post_first_open_only, "RawEmailEnabled": $raw_email_enabled, "SmtpApiActivated": $smtp_api_activated, "TrackLinks": $track_links, "TrackOpens": $track_opens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get outbound overview
#
# GET /stats/outbound
# operationId: getOutboundOverviewStatistics
export def "stats-outbound get-overview-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<BounceRate: int, Bounced: int, Opens: int, SMTPAPIErrors: int, Sent: int, SpamComplaints: int, SpamComplaintsRate: int, TotalClicks: int, TotalTrackedLinksSent: int, Tracked: int, UniqueLinksClicked: int, UniqueOpens: int, WithClientRecorded: int, WithLinkTracking: int, WithOpenTracking: int, WithPlatformRecorded: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"tag": $tag, "fromdate": $fromdate, "todate": $todate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get bounce counts
#
# GET /stats/outbound/bounces
# operationId: getBounceCounts
export def "stats-outbound-bounces get-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Days: table<Date: string, HardBounce: int, SMTPApiError: int, SoftBounce: int, Transient: int>, HardBounce: int, SMTPApiError: int, SoftBounce: int, Transient: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/bounces" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"tag": $tag, "fromdate": $fromdate, "todate": $todate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get click counts
#
# GET /stats/outbound/clicks
# operationId: getOutboundClickCounts
export def "stats-outbound-clicks get-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/clicks" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"tag": $tag, "fromdate": $fromdate, "todate": $todate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get browser usage by family
#
# GET /stats/outbound/clicks/browserfamilies
# operationId: getOutboundClickCountsByBrowserFamily
export def "stats-outbound-clicks-browserfamilies get-counts-by-browser-family" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/clicks/browserfamilies" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"tag": $tag, "fromdate": $fromdate, "todate": $todate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get clicks by body location
#
# GET /stats/outbound/clicks/location
# operationId: getOutboundClickCountsByLocation
export def "stats-outbound-clicks-location get-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/clicks/location" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"tag": $tag, "fromdate": $fromdate, "todate": $todate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get browser plaform usage
#
# GET /stats/outbound/clicks/platforms
# operationId: getOutboundClickCountsByPlatform
export def "stats-outbound-clicks-platforms get-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/clicks/platforms" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"tag": $tag, "fromdate": $fromdate, "todate": $todate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get email open counts
#
# GET /stats/outbound/opens
# operationId: getOutboundOpenCounts
export def "stats-outbound-opens get-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Days: table<Date: string, Opens: int, Unique: int>, Opens: int, Unique: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/opens" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"tag": $tag, "fromdate": $fromdate, "todate": $todate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get email client usage
#
# GET /stats/outbound/opens/emailclients
# operationId: getOutboundOpenCountsByEmailClient
export def "stats-outbound-opens-emailclients get-counts-by-email-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Days: list<any>, Desktop: int, Mobile: int, Unknown: int, WebMail: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/opens/emailclients" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"tag": $tag, "fromdate": $fromdate, "todate": $todate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get email platform usage
#
# GET /stats/outbound/opens/platforms
# operationId: getOutboundOpenCountsByPlatform
export def "stats-outbound-opens-platforms get-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Days: table<Date: string, Desktop: int, Mobile: int, Unknown: int, WebMail: int>, Desktop: int, Mobile: int, Unknown: int, WebMail: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/opens/platforms" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"tag": $tag, "fromdate": $fromdate, "todate": $todate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get sent counts
#
# GET /stats/outbound/sends
# operationId: getSentCounts
export def "stats-outbound-sends get-sent-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Days: table<Date: string, Sent: int>, Sent: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/sends" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"tag": $tag, "fromdate": $fromdate, "todate": $todate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get spam complaints
#
# GET /stats/outbound/spam
# operationId: getSpamComplaints
export def "stats-outbound-spam get-complaints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Days: table<Date: string, SpamComplaint: int>, SpamComplaint: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/spam" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"tag": $tag, "fromdate": $fromdate, "todate": $todate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get tracked email counts
#
# GET /stats/outbound/tracked
# operationId: getTrackedEmailCounts
export def "stats-outbound-tracked get-email-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Days: table<Date: string, Tracked: int>, Tracked: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/tracked" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"tag": $tag, "fromdate": $fromdate, "todate": $todate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the Templates associated with this Server
#
# GET /templates
# operationId: listTemplates
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
  --count: float # The number of Templates to return (format: int)
  --offset: float # The number of Templates to "skip" before returning results. (format: int)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Templates_API: table<Active: bool, Alias: string, Name: string, TemplateId: float>, TotalCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Count" $count "scalar") (serialize-qp "Offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/templates" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Count": $count, "Offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a Template
#
# POST /templates
export def "templates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
  --alias: string # The optional string identifier for referring to this Template (numbers, letters, and '.', '-', '_' characters, starts with a letter).
  --html-body: string # The HTML template definition for this Template.
  name: string # The friendly display name for the template.
  subject: string # The Subject template definition for this Template.
  --text-body: string # The Text template definition for this Template.
]: any -> record<Active: bool, Alias: string, Name: string, TemplateId: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates" $auth.query)
  let req_body = {"Alias": $alias, "HtmlBody": $html_body, "Name": $name, "Subject": $subject, "TextBody": $text_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
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

# Test Template Content
#
# POST /templates/validate
# operationId: testTemplateContent
export def "templates-validate test-content" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
  --html-body: string # The html body content to validate. Must be specified if Subject or TextBody are not. See our template language documentation for more information on the syntax for this field.
  --inline-css-for-html-test-render: oneof<nothing, bool> # When HtmlBody is specified, the test render will have style blocks inlined as style attributes on matching html elements. You may disable the css inlining behavior by passing false for this parameter. (default: true)
  --subject: string # The subject content to validate. Must be specified if HtmlBody or TextBody are not. See our template language documentation for more information on the syntax for this field.
  --test-render-model: record # The model to be used when rendering test content.
  --text-body: string # The text body content to validate. Must be specified if HtmlBody or Subject are not. See our template language documentation for more information on the syntax for this field.
]: any -> record<AllContentIsValid: bool, HtmlBody: record<ContentIsValid: bool, RenderedContent: string, ValidationErrors: list<record>>, Subject: record<ContentIsValid: bool, RenderedContent: string, ValidationErrors: list<record>>, SuggestedTemplateModel: record, TextBody: record<ContentIsValid: bool, RenderedContent: string, ValidationErrors: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/validate" $auth.query)
  let req_body = {"HtmlBody": $html_body, "InlineCssForHtmlTestRender": $inline_css_for_html_test_render, "Subject": $subject, "TestRenderModel": $test_render_model, "TextBody": $text_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
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

# Delete a Template
#
# DELETE /templates/{templateIdOrAlias}
# operationId: deleteTemplate
export def "templates delete" [
  template_id_or_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Active: bool, Alias: string, AssociatedServerId: int, HtmlBody: string, Name: string, Subject: string, TemplateID: int, TextBody: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_id_or_alias | is-empty) { error make --unspanned { msg: "path parameter 'templateIdOrAlias' must be non-empty" } }
  let full_url = (build-url $base ({template_id_or_alias: (encode-path-segment $template_id_or_alias)} | format pattern "/templates/{template_id_or_alias}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get a Template
#
# GET /templates/{templateIdOrAlias}
# operationId: getSingleTemplate
export def "templates get-single" [
  template_id_or_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Active: bool, Alias: string, AssociatedServerId: int, HtmlBody: string, Name: string, Subject: string, TemplateID: int, TextBody: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_id_or_alias | is-empty) { error make --unspanned { msg: "path parameter 'templateIdOrAlias' must be non-empty" } }
  let full_url = (build-url $base ({template_id_or_alias: (encode-path-segment $template_id_or_alias)} | format pattern "/templates/{template_id_or_alias}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a Template
#
# PUT /templates/{templateIdOrAlias}
# operationId: updateTemplate
export def "templates update" [
  template_id_or_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
  --alias: string # The optional string identifier for referring to this Template (numbers, letters, and '.', '-', '_' characters, starts with a letter).
  --html-body: string # The HTML template definition for this Template.
  --name: string # The friendly display name for the template.
  --subject: string # The Subject template definition for this Template.
  --text-body: string # The Text template definition for this Template.
]: any -> record<Active: bool, Alias: string, Name: string, TemplateId: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_id_or_alias | is-empty) { error make --unspanned { msg: "path parameter 'templateIdOrAlias' must be non-empty" } }
  let full_url = (build-url $base ({template_id_or_alias: (encode-path-segment $template_id_or_alias)} | format pattern "/templates/{template_id_or_alias}") $auth.query)
  let req_body = {"Alias": $alias, "HtmlBody": $html_body, "Name": $name, "Subject": $subject, "TextBody": $text_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List inbound rule triggers
#
# GET /triggers/inboundrules
# operationId: listInboundRules
export def "triggers-inboundrules list-inbound-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of records to return per request.
  --offset: int # Number of records to skip.
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<InboundRules: table<ID: int, Rule: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/triggers/inboundrules" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an inbound rule trigger
#
# POST /triggers/inboundrules
# operationId: createInboundRule
export def "triggers-inboundrules create-inbound-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
  --rule: string # format: email
]: any -> record<ID: int, Rule: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/triggers/inboundrules" $auth.query)
  let req_body = {"Rule": $rule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
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

# Delete a single trigger
#
# DELETE /triggers/inboundrules/{triggerid}
# operationId: deleteInboundRule
export def "triggers-inboundrules delete-inbound-rule" [
  triggerid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<ErrorCode: int, Message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($triggerid | is-empty) { error make --unspanned { msg: "path parameter 'triggerid' must be non-empty" } }
  let full_url = (build-url $base ({triggerid: (encode-path-segment $triggerid)} | format pattern "/triggers/inboundrules/{triggerid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Server-Token": $x_postmark_server_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}
