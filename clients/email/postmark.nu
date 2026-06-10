# Auto-generated client for Postmark API v1.0.0
# Source: https://api.apis.guru/v2/specs/postmarkapp.com/server/1.0.0/swagger.json
# Auth: --token flag or $env.POSTMARK_API_TOKEN

const BASE_URL = "https://api.postmarkapp.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o POSTMARK_API_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.postmarkapp.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["AddressChange" "AutoResponder" "BadEmailAddress" "Blocked" "DMARCPolicy" "DnsError" "HardBounce" "InboundError" "MailFrontier Matador." "ManuallyDeactivated" "OpenRelayTest" "SMTPApiError" "SoftBounce" "SpamComplaint" "SpamNotification" "Subscribe" "TemplateRenderingFailed" "Transient" "Unconfirmed" "Unknown" "Unsubscribe" "VirusNotification"] }
def TrackLinks-completer [] { ["HtmlAndText" "HtmlOnly" "None" "TextOnly"] }
def status-completer [] { ["blocked" "failed" "processed" "queued" "scheduled"] }
def status-completer-1 [] { ["queued" "sent"] }
def Color-completer [] { ["blue" "green" "grey" "purple" "red" "turqoise" "yellow"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bounces list" } } | get name | first)
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
export def "bounces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Number of bounces to return per request. Max 500.
  --offset: int # Number of bounces to skip.
  --type: string@type-completer # Filter by type of bounce
  --inactive: string@bool-completer # Filter by emails that were deactivated by Postmark due to the bounce. Set to true or false. If this isn't specified it will return both active and inactive.
  --emailFilter: string # Filter by email address (format: email)
  --messageID: string # Filter by messageID
  --tag: string # Filter by tag
  --todate: string # Filter messages up to the date specified. e.g. `2014-02-01` (format: date)
  --fromdate: string # Filter messages starting from the date specified. e.g. `2014-02-01` (format: date)
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Bounces: table<BouncedAt: string, CanActivate: bool, Content: string, Description: string, Details: string, DumpAvailable: bool, Email: string, ID: string, Inactive: bool, MessageID: string, Name: string, Subject: string, Tag: string, Type: string, TypeCode: int>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "inactive" $inactive "scalar") (serialize-qp "emailFilter" $emailFilter "scalar") (serialize-qp "messageID" $messageID "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "fromdate" $fromdate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bounces" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single bounce
#
# GET /bounces/{bounceid}
# operationId: getSingleBounce
export def "bounces get" [
  bounceid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<BouncedAt: string, CanActivate: bool, Content: string, Description: string, Details: string, DumpAvailable: bool, Email: string, ID: string, Inactive: bool, MessageID: string, Name: string, Subject: string, Tag: string, Type: string, TypeCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bounces/($bounceid)")
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Activate a bounce
#
# PUT /bounces/{bounceid}/activate
# operationId: activateBounce
export def "bounces-activate activateBounce" [
  bounceid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Bounce: record<BouncedAt: string, CanActivate: bool, Content: string, Description: string, Details: string, DumpAvailable: bool, Email: string, ID: string, Inactive: bool, MessageID: string, Name: string, Subject: string, Tag: string, Type: string, TypeCode: int>, Message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bounces/($bounceid)/activate")
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Body: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bounces/($bounceid)/dump")
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get delivery stats
#
# GET /deliverystats
# operationId: getDeliveryStats
export def "deliverystats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Bounces: table<Count: int, Name: string, Type: string>, InactiveMails: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deliverystats")
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send a single email
#
# POST /email
# operationId: sendEmail
# --Attachments item shape: {Content?: string, ContentID?: string, ContentType?: string, Name?: string}
# --Headers item shape: {Name?: string, Value?: string}
export def "email sendEmail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
  --Attachments: list # item shape: {Content?: string, ContentID?: string, ContentType?: string, Name?: string}
  --Bcc: string # Bcc recipient email address. Multiple addresses are comma seperated. Max 50.
  --Cc: string # Recipient email address. Multiple addresses are comma seperated. Max 50.
  --From: string # The sender email address. Must have a registered and confirmed Sender Signature.
  --Headers: list # item shape: {Name?: string, Value?: string}
  --HtmlBody: string # If no TextBody specified HTML email message
  --ReplyTo: string # Reply To override email address. Defaults to the Reply To set in the sender signature.
  --Subject: string # Email Subject
  --Tag: string # Email tag that allows you to categorize outgoing emails and get detailed statistics.
  --TextBody: string # If no HtmlBody specified Plain text email message
  --To: string # Recipient email address. Multiple addresses are comma seperated. Max 50.
  --TrackLinks: string@TrackLinks-completer # Replace links in content to enable "click tracking" stats. Default is 'null', which uses the server's LinkTracking setting'.
  --TrackOpens: string@bool-completer # Activate open tracking for this email.
]: any -> record<ErrorCode: int, Message: string, MessageID: string, SubmittedAt: string, To: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/email")
  let body = {Attachments: $Attachments, Bcc: $Bcc, Cc: $Cc, From: $From, Headers: $Headers, HtmlBody: $HtmlBody, ReplyTo: $ReplyTo, Subject: $Subject, Tag: $Tag, TextBody: $TextBody, To: $To, TrackLinks: $TrackLinks, TrackOpens: $TrackOpens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send a batch of emails
#
# POST /email/batch
# operationId: sendEmailBatch
export def "email-batch sendEmailBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
  --body: record
]: any -> table<ErrorCode: int, Message: string, MessageID: string, SubmittedAt: string, To: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/email/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send a batch of email using templates.
#
# POST /email/batchWithTemplates
# operationId: sendEmailBatchWithTemplates
# --Messages item shape: {Attachments?: list, Bcc?: string, Cc?: string, From: string, Headers?: list, InlineCss?: bool, ReplyTo?: string, Tag?: string, TemplateAlias: string, TemplateId: int, TemplateModel: record, To: string, TrackLinks?: "None"|"HtmlAndText"|"HtmlOnly"|"TextOnly", TrackOpens?: bool}
export def "email-batch-with-templates sendEmailBatchWithTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
  --Messages: list # item shape: {Attachments?: list, Bcc?: string, Cc?: string, From: string, Headers?: list, InlineCss?: bool, ReplyTo?: string, Tag?: string, TemplateAlias: string, TemplateId: int, TemplateModel: record, To: string, TrackLinks?: "None"|"HtmlAndText"|"HtmlOnly"|"TextOnly", TrackOpens?: bool}
]: any -> table<ErrorCode: int, Message: string, MessageID: string, SubmittedAt: string, To: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/email/batchWithTemplates")
  let body = {Messages: $Messages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send an email using a Template
#
# POST /email/withTemplate
# operationId: sendEmailWithTemplate
# --Attachments item shape: {Content?: string, ContentID?: string, ContentType?: string, Name?: string}
# --Headers item shape: {Name?: string, Value?: string}
export def "email-with-template sendEmailWithTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
  --Attachments: list # item shape: {Content?: string, ContentID?: string, ContentType?: string, Name?: string}
  --Bcc: string # format: email
  --Cc: string # format: email
  From: string # format: email
  --Headers: list # item shape: {Name?: string, Value?: string}
  --InlineCss: string@bool-completer # default: true
  --ReplyTo: string
  --Tag: string
  TemplateAlias: string # Required if 'TemplateId' is not specified.
  TemplateId: int # Required if 'TemplateAlias' is not specified.
  TemplateModel: record
  To: string # format: email
  --TrackLinks: string@TrackLinks-completer # Replace links in content to enable "click tracking" stats. Default is 'null', which uses the server's LinkTracking setting'.
  --TrackOpens: string@bool-completer # Activate open tracking for this email.
]: any -> record<ErrorCode: int, Message: string, MessageID: string, SubmittedAt: string, To: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/email/withTemplate")
  let body = {Attachments: $Attachments, Bcc: $Bcc, Cc: $Cc, From: $From, Headers: $Headers, InlineCss: $InlineCss, ReplyTo: $ReplyTo, Tag: $Tag, TemplateAlias: $TemplateAlias, TemplateId: $TemplateId, TemplateModel: $TemplateModel, To: $To, TrackLinks: $TrackLinks, TrackOpens: $TrackOpens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Inbound message search
#
# GET /messages/inbound
# operationId: searchInboundMessages
export def "messages-inbound searchInboundMessages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<InboundMessages: table<Attachments: list, Cc: string, CcFull: list, Date: string, From: string, FromFull: record, FromName: string, MailboxHash: string, MessageID: string, OriginalRecipient: string, ReplyTo: string, Status: string, Subject: string, Tag: string, To: string, ToFull: list>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "recipient" $recipient "scalar") (serialize-qp "fromemail" $fromemail "scalar") (serialize-qp "subject" $subject "scalar") (serialize-qp "mailboxhash" $mailboxhash "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "fromdate" $fromdate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages/inbound" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bypass rules for a blocked inbound message
#
# PUT /messages/inbound/{messageid}/bypass
# operationId: bypassRulesForInboundMessage
export def "messages-inbound-bypass bypassRulesForInboundMessage" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<ErrorCode: int, Message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/inbound/($messageid)/bypass")
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Attachments: table<Content: string, ContentID: string, ContentType: string, Name: string>, BlockedReason: string, Cc: string, CcFull: table<Email: string, Name: string>, Date: string, From: string, FromFull: record<Email: string, Name: string>, FromName: string, Headers: table<Name: string, Value: string>, HtmlBody: string, MailboxHash: string, MessageID: string, OriginalRecipient: string, ReplyTo: string, Status: string, Subject: string, Tag: string, TextBody: string, To: string, ToFull: table<Email: string, Name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/inbound/($messageid)/details")
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retry a failed inbound message for processing
#
# PUT /messages/inbound/{messageid}/retry
# operationId: retryInboundMessageProcessing
export def "messages-inbound-retry retryInboundMessageProcessing" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<ErrorCode: int, Message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/inbound/($messageid)/retry")
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Outbound message search
#
# GET /messages/outbound
# operationId: searchOutboundMessages
export def "messages-outbound searchOutboundMessages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Number of messages to return per request. Max 500.
  --offset: int # Number of messages to skip
  --recipient: string # Filter by the user who was receiving the email (format: email)
  --fromemail: string # Filter by the sender email address (format: email)
  --tag: string # Filter by tag
  --status: string@status-completer-1 # Filter by status (`queued` or `sent`)
  --todate: string # Filter messages up to the date specified. e.g. `2014-02-01` (format: date)
  --fromdate: string # Filter messages starting from the date specified. e.g. `2014-02-01` (format: date)
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Messages: table<Attachments: list, Bcc: list, Cc: list, From: string, MessageID: string, ReceivedAt: string, Recipients: list, Status: string, Subject: string, Tag: string, To: list, TrackLinks: string, TrackOpens: bool>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "recipient" $recipient "scalar") (serialize-qp "fromemail" $fromemail "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "fromdate" $fromdate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages/outbound" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Clicks for a all messages
#
# GET /messages/outbound/clicks
# operationId: searchClicksForOutboundMessages
export def "messages-outbound-clicks searchClicksForOutboundMessages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Clicks: table<ClickLocation: string, Client: record, Geo: record, MessageID: string, OS: record, OriginalLink: string, Platform: string, ReceivedAt: string, Recipient: string, Tag: string, UserAgent: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "recipient" $recipient "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "client_name" $client_name "scalar") (serialize-qp "client_company" $client_company "scalar") (serialize-qp "client_family" $client_family "scalar") (serialize-qp "os_name" $os_name "scalar") (serialize-qp "os_family" $os_family "scalar") (serialize-qp "os_company" $os_company "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "city" $city "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages/outbound/clicks" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Message Clicks
#
# GET /messages/outbound/clicks/{messageid}
# operationId: getClicksForSingleOutboundMessage
export def "messages-outbound-clicks get" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Number of message clicks to return per request. Max 500. (default: 1)
  --offset: int # Number of messages to skip. (default: 0)
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Clicks: table<ClickLocation: string, Client: record, Geo: record, MessageID: string, OS: record, OriginalLink: string, Platform: string, ReceivedAt: string, Recipient: string, Tag: string, UserAgent: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/messages/outbound/clicks/($messageid)" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Opens for all messages
#
# GET /messages/outbound/opens
# operationId: searchOpensForOutboundMessages
export def "messages-outbound-opens searchOpensForOutboundMessages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Opens: table<Client: record, FirstOpen: bool, Geo: record, MessageID: string, OS: record, Platform: string, ReceivedAt: string, Recipient: string, Tag: string, UserAgent: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "recipient" $recipient "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "client_name" $client_name "scalar") (serialize-qp "client_company" $client_company "scalar") (serialize-qp "client_family" $client_family "scalar") (serialize-qp "os_name" $os_name "scalar") (serialize-qp "os_family" $os_family "scalar") (serialize-qp "os_company" $os_company "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "city" $city "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages/outbound/opens" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Message Opens
#
# GET /messages/outbound/opens/{messageid}
# operationId: getOpensForSingleOutboundMessage
export def "messages-outbound-opens get" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Number of message opens to return per request. Max 500. (default: 1)
  --offset: int # Number of messages to skip. (default: 0)
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Opens: table<Client: record, FirstOpen: bool, Geo: record, MessageID: string, OS: record, Platform: string, ReceivedAt: string, Recipient: string, Tag: string, UserAgent: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/messages/outbound/opens/($messageid)" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Attachments: table<Content: string, ContentID: string, ContentType: string, Name: string>, Bcc: table<Email: string, Name: string>, Body: string, Cc: table<Email: string, Name: string>, From: string, HtmlBody: string, MessageEvents: table<Details: record, ReceivedAt: string, Recipient: string, Type: string>, MessageID: string, ReceivedAt: string, Recipients: list<string>, Status: string, Subject: string, Tag: string, TextBody: string, To: table<Email: string, Name: string>, TrackLinks: string, TrackOpens: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/outbound/($messageid)/details")
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Body: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/outbound/($messageid)/dump")
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Server Configuration
#
# GET /server
# operationId: getCurrentServerConfiguration
export def "server get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<ApiTokens: list<string>, BounceHookUrl: string, ClickHookUrl: string, Color: string, DeliveryHookUrl: string, ID: int, InboundAddress: string, InboundDomain: string, InboundHash: string, InboundHookUrl: string, InboundSpamThreshold: int, Name: string, OpenHookUrl: string, PostFirstOpenOnly: bool, RawEmailEnabled: bool, ServerLink: string, SmtpApiActivated: bool, TrackLinks: string, TrackOpens: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/server")
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit Server Configuration
#
# PUT /server
# operationId: editCurrentServerConfiguration
export def "server editCurrentServerConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
  --BounceHookUrl: string
  --ClickHookUrl: string # Webhook url allowing real-time notification when tracked links are clicked.
  --Color: string@Color-completer
  --DeliveryHookUrl: string
  --InboundDomain: string
  --InboundHookUrl: string
  --InboundSpamThreshold: int
  --Name: string
  --OpenHookUrl: string
  --PostFirstOpenOnly: string@bool-completer
  --RawEmailEnabled: string@bool-completer
  --SmtpApiActivated: string@bool-completer
  --TrackLinks: string@TrackLinks-completer
  --TrackOpens: string@bool-completer
]: any -> record<ApiTokens: list<string>, BounceHookUrl: string, ClickHookUrl: string, Color: string, DeliveryHookUrl: string, ID: int, InboundAddress: string, InboundDomain: string, InboundHash: string, InboundHookUrl: string, InboundSpamThreshold: int, Name: string, OpenHookUrl: string, PostFirstOpenOnly: bool, RawEmailEnabled: bool, ServerLink: string, SmtpApiActivated: bool, TrackLinks: string, TrackOpens: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/server")
  let body = {BounceHookUrl: $BounceHookUrl, ClickHookUrl: $ClickHookUrl, Color: $Color, DeliveryHookUrl: $DeliveryHookUrl, InboundDomain: $InboundDomain, InboundHookUrl: $InboundHookUrl, InboundSpamThreshold: $InboundSpamThreshold, Name: $Name, OpenHookUrl: $OpenHookUrl, PostFirstOpenOnly: $PostFirstOpenOnly, RawEmailEnabled: $RawEmailEnabled, SmtpApiActivated: $SmtpApiActivated, TrackLinks: $TrackLinks, TrackOpens: $TrackOpens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get outbound overview
#
# GET /stats/outbound
# operationId: getOutboundOverviewStatistics
export def "stats-outbound get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<BounceRate: int, Bounced: int, Opens: int, SMTPAPIErrors: int, Sent: int, SpamComplaints: int, SpamComplaintsRate: int, TotalClicks: int, TotalTrackedLinksSent: int, Tracked: int, UniqueLinksClicked: int, UniqueOpens: int, WithClientRecorded: int, WithLinkTracking: int, WithOpenTracking: int, WithPlatformRecorded: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get bounce counts
#
# GET /stats/outbound/bounces
# operationId: getBounceCounts
export def "stats-outbound-bounces get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Days: table<Date: string, HardBounce: int, SMTPApiError: int, SoftBounce: int, Transient: int>, HardBounce: int, SMTPApiError: int, SoftBounce: int, Transient: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/bounces" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get click counts
#
# GET /stats/outbound/clicks
# operationId: getOutboundClickCounts
export def "stats-outbound-clicks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/clicks" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get browser usage by family
#
# GET /stats/outbound/clicks/browserfamilies
# operationId: getOutboundClickCountsByBrowserFamily
export def "stats-outbound-clicks-browserfamilies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/clicks/browserfamilies" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get clicks by body location
#
# GET /stats/outbound/clicks/location
# operationId: getOutboundClickCountsByLocation
export def "stats-outbound-clicks-location get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/clicks/location" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get browser plaform usage
#
# GET /stats/outbound/clicks/platforms
# operationId: getOutboundClickCountsByPlatform
export def "stats-outbound-clicks-platforms get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/clicks/platforms" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get email open counts
#
# GET /stats/outbound/opens
# operationId: getOutboundOpenCounts
export def "stats-outbound-opens get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Days: table<Date: string, Opens: int, Unique: int>, Opens: int, Unique: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/opens" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get email client usage
#
# GET /stats/outbound/opens/emailclients
# operationId: getOutboundOpenCountsByEmailClient
export def "stats-outbound-opens-emailclients get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Days: list<any>, Desktop: int, Mobile: int, Unknown: int, WebMail: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/opens/emailclients" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get email platform usage
#
# GET /stats/outbound/opens/platforms
# operationId: getOutboundOpenCountsByPlatform
export def "stats-outbound-opens-platforms get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Days: table<Date: string, Desktop: int, Mobile: int, Unknown: int, WebMail: int>, Desktop: int, Mobile: int, Unknown: int, WebMail: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/opens/platforms" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get sent counts
#
# GET /stats/outbound/sends
# operationId: getSentCounts
export def "stats-outbound-sends get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Days: table<Date: string, Sent: int>, Sent: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/sends" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get spam complaints
#
# GET /stats/outbound/spam
# operationId: getSpamComplaints
export def "stats-outbound-spam get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Days: table<Date: string, SpamComplaint: int>, SpamComplaint: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/spam" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get tracked email counts
#
# GET /stats/outbound/tracked
# operationId: getTrackedEmailCounts
export def "stats-outbound-tracked get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Days: table<Date: string, Tracked: int>, Tracked: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/outbound/tracked" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the Templates associated with this Server
#
# GET /templates
# operationId: listTemplates
export def "templates listTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Count: float # The number of Templates to return (format: int)
  --Offset: float # The number of Templates to "skip" before returning results. (format: int)
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Templates_API: table<Active: bool, Alias: string, Name: string, TemplateId: float>, TotalCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Count" $Count "scalar") (serialize-qp "Offset" $Offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/templates" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Template
#
# POST /templates
export def "templates post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
  --Alias: string # The optional string identifier for referring to this Template (numbers, letters, and '.', '-', '_' characters, starts with a letter).
  --HtmlBody: string # The HTML template definition for this Template.
  Name: string # The friendly display name for the template.
  Subject: string # The Subject template definition for this Template.
  --TextBody: string # The Text template definition for this Template.
]: any -> record<Active: bool, Alias: string, Name: string, TemplateId: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates")
  let body = {Alias: $Alias, HtmlBody: $HtmlBody, Name: $Name, Subject: $Subject, TextBody: $TextBody} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test Template Content
#
# POST /templates/validate
# operationId: testTemplateContent
export def "templates-validate testTemplateContent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
  --HtmlBody: string # The html body content to validate. Must be specified if Subject or TextBody are not. See our template language documentation for more information on the syntax for this field.
  --InlineCssForHtmlTestRender: string@bool-completer # When HtmlBody is specified, the test render will have style blocks inlined as style attributes on matching html elements. You may disable the css inlining behavior by passing false for this parameter.  (default: true)
  --Subject: string # The subject content to validate. Must be specified if HtmlBody or TextBody are not. See our template language documentation for more information on the syntax for this field.
  --TestRenderModel: record # The model to be used when rendering test content.
  --TextBody: string # The text body content to validate. Must be specified if HtmlBody or Subject are not. See our template language documentation for more information on the syntax for this field.
]: any -> record<AllContentIsValid: bool, HtmlBody: record<ContentIsValid: bool, RenderedContent: string, ValidationErrors: list<record>>, Subject: record<ContentIsValid: bool, RenderedContent: string, ValidationErrors: list<record>>, SuggestedTemplateModel: record, TextBody: record<ContentIsValid: bool, RenderedContent: string, ValidationErrors: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/validate")
  let body = {HtmlBody: $HtmlBody, InlineCssForHtmlTestRender: $InlineCssForHtmlTestRender, Subject: $Subject, TestRenderModel: $TestRenderModel, TextBody: $TextBody} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Template
#
# DELETE /templates/{templateIdOrAlias}
# operationId: deleteTemplate
export def "templates delete" [
  templateIdOrAlias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Active: bool, Alias: string, AssociatedServerId: int, HtmlBody: string, Name: string, Subject: string, TemplateID: int, TextBody: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($templateIdOrAlias)")
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Template
#
# GET /templates/{templateIdOrAlias}
# operationId: getSingleTemplate
export def "templates get" [
  templateIdOrAlias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<Active: bool, Alias: string, AssociatedServerId: int, HtmlBody: string, Name: string, Subject: string, TemplateID: int, TextBody: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($templateIdOrAlias)")
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Template
#
# PUT /templates/{templateIdOrAlias}
# operationId: updateTemplate
export def "templates updateTemplate" [
  templateIdOrAlias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
  --Alias: string # The optional string identifier for referring to this Template (numbers, letters, and '.', '-', '_' characters, starts with a letter).
  --HtmlBody: string # The HTML template definition for this Template.
  --Name: string # The friendly display name for the template.
  --Subject: string # The Subject template definition for this Template.
  --TextBody: string # The Text template definition for this Template.
]: any -> record<Active: bool, Alias: string, Name: string, TemplateId: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($templateIdOrAlias)")
  let body = {Alias: $Alias, HtmlBody: $HtmlBody, Name: $Name, Subject: $Subject, TextBody: $TextBody} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List inbound rule triggers
#
# GET /triggers/inboundrules
# operationId: listInboundRules
export def "triggers-inboundrules listInboundRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Number of records to return per request.
  --offset: int # Number of records to skip.
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<InboundRules: table<ID: int, Rule: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/triggers/inboundrules" $qp)
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an inbound rule trigger
#
# POST /triggers/inboundrules
# operationId: createInboundRule
export def "triggers-inboundrules createInboundRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
  --Rule: string # format: email
]: any -> record<ID: int, Rule: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/triggers/inboundrules")
  let body = {Rule: $Rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a single trigger
#
# DELETE /triggers/inboundrules/{triggerid}
# operationId: deleteInboundRule
export def "triggers-inboundrules delete" [
  triggerid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Server-Token: string # The token associated with the Server on which this request will operate.
]: nothing -> record<ErrorCode: int, Message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/triggers/inboundrules/($triggerid)")
  let extra_headers = {"X-Postmark-Server-Token": $X_Postmark_Server_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
