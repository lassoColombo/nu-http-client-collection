# Auto-generated client for Mailgun API v3.0.0
# Source: https://documentation.mailgun.com/_spec/docs/mailgun/api-reference/send/mailgun.yaml?download
# Auth: --token flag or $env.MAILGUN_API_TOKEN

const BASE_URL = "https://api.mailgun.net"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MAILGUN_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://api.mailgun.net" "https://api.eu.mailgun.net"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def t:text-completer [] { ["yes"] }
def o:dkim-completer [] { ["false" "no" "true" "yes"] }
def o:testmode-completer [] { ["yes"] }
def o:tracking-completer [] { ["false" "htmlonly" "no" "true" "yes"] }
def o:tracking-clicks-completer [] { ["false" "htmlonly" "no" "true" "yes"] }
def o:tracking-opens-completer [] { ["false" "no" "true" "yes"] }
def o:require-tls-completer [] { ["false" "no" "true" "yes"] }
def o:skip-verification-completer [] { ["false" "no" "true" "yes"] }
def o:tracking-pixel-location-top-completer [] { ["false" "htmlonly" "no" "true" "yes"] }
def id-completer [] { ["accepted" "clicked" "complained" "delivered" "opened" "permanent_fail" "temporary_fail" "unsubscribed"] }
def event-types-completer [] { ["accepted" "clicked" "complained" "delivered" "opened" "permanent_fail" "temporary_fail" "unsubscribed"] }
def sort-by-completer [] { ["bounce_rate" "complaint_rate" "name"] }
def sort-order-completer [] { ["ascending" "descending"] }
def ascending-completer [] { ["no" "yes"] }
def page-completer [] { ["first" "last" "next" "previous"] }
def sort-completer [] { ["asc" "desc"] }
def kind-completer [] { ["domain" "user" "web"] }
def role-completer [] { ["admin" "basic" "developer" "sending"] }
def role-completer-1 [] { ["admin" "basic" "billing" "developer" "support"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "messages POST-v3--domain-name--messages" } } | get name | first)
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

# Send an email
#
# POST /v3/{domain_name}/messages
# operationId: POST-v3--domain-name--messages
export def "messages POST-v3--domain-name--messages" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-from: string # Email address of the `From` header. Can include a friendly name using the format `"Friendly Name <email@domain.com>"`. Note: not required if sending with a template that has a pre-set From header, but will override the template's From header if provided.
  --body-to: list # Email address of the recipient(s). Supports friendly name format. Example: `"Bob <bob@host.com>"`. Use commas to separate multiple recipients. Duplicate addresses are automatically ignored.
  --cc: list # Same as `to` but for carbon copy recipients. Supports friendly name format.
  --bcc: list # Same as `to` but for blind carbon copy recipients. Supports friendly name format.
  subject: string # Message subject. Note: not required if sending with a template that has a pre-set Subject header, but it will override it if provided.
  --text: string # Body of the message (text version)
  --html: string # Body of the message (HTML version)
  --amp-html: string # AMP part of the message.  Please follow Google guidelines to compose and send AMP emails
  --attachment: list # File attachment.  You can post multiple `attachment` values.  **Important:** You must use `multipart/form-data` encoding for sending attachments
  --inline: list # Attachment with `inline` disposition.  Can be used to send inline images (see example). You can post multiple `inline` values (format: binary)
  --template: string # Name of a template stored via the Templates API to use to render the email body. See [Templates](https://documentation.mailgun.com/docs/mailgun/user-manual/sending-messages/send-templates) for more information
  --t:version: string # Render a specific version of the given template instead of the latest version. `template` option must also be provided.
  --t:text: string@t:text-completer # Generates a plain text version of the template alongside the HTML version when sending templated emails. When set to 'yes', instructs Mailgun to create a text/plain MIME part based on the template content, ensuring compatibility with email clients that don't support HTML or have HTML rendering disabled. This improves email deliverability and accessibility by providing a fallback text version in multipart emails.
  --t:variables: string # A valid JSON-encoded dictionary used as the input for template variable expansion.  See [Templates](https://documentation.mailgun.com/docs/mailgun/user-manual/sending-messages/send-templates) for more information
  --o:tag: list # Tag string.  See [Tagging](https://documentation.mailgun.com/docs/mailgun/user-manual/tracking-messages/track-tagging) for more information
  --o:dkim: string@o:dkim-completer # Enables or disables DKIM signatures on a per-message basis. Overrides the domain-level DKIM setting for this specific message.
  --o:secondary-dkim: string # Specify a second domain key to sign the email with. The value is formatted as `signing_domain/selector`, e.g. `example.com/s1`. This tells Mailgun to sign the message with the signing domain `example.com` using the selector `s1`. Note: the domain key specified must have been previously created and activated.
  --o:secondary-dkim-public: string # Specify an alias of the domain key specified in `o:secondary-dkim`. Also formatted as `public_signing_domain/selector`. `o:secondary-dkim` option must also be provided. Mailgun will sign the message with the provided key of the secondary DKIM, but use the public secondary DKIM name and selector. Note: We will perform a DNS check prior to signing the message to ensure the public keys matches the secondary DKIM.
  --o:deliverytime: string # Specifies the scheduled delivery time in [RFC-2822 format](https://documentation.mailgun.com/docs/mailgun/api-reference/api-overview#date-format). Depending on your plan, you can schedule messages up to 3 or 7 days in advance. If your domain has a custom message_ttl (time-to-live) setting, this value determines the maximum scheduling duration. Example: 'Fri, 14 Oct 2011 12:00:00 +0000'
  --o:deliver-within: string # Specifies the maximum time window for delivering the message. Accepts values in format `[0-9]+h[0-9]+m` (e.g., `1h30m`, `30m`, `24h`), with a minimum of `5m` and maximum of `24h`. For scheduled messages, the delivery window starts from the scheduled time. The standard retry schedule applies within this window, so shorter timeframes may result in fewer delivery attempts.
  --o:deliverytime-optimize-period: string # Toggles Send Time Optimization (STO) on a per-message basis.  String should be set to the number of hours in `[0-9]+h` format, with the minimum being `24h` and the maximum being `72h`.  This value defines the time window in which Mailgun will run the optimization algorithm based on prior engagement data of a given recipient. See [Sending a Message with STO](https://documentation.mailgun.com/docs/mailgun/user-manual/sending-messages/send-sto) for details. *Please note that STO is only available on certain plans. See www.mailgun.com/pricing for more info*
  --o:time-zone-localize: string # Toggles Timezone Optimization (TZO) on a per message basis. String should be set to preferred delivery time in `HH:mm` or `hh:mmaa` format, where `HH:mm` is used for 24 hour format without AM/PM and hh:mmaa is used for 12 hour format with AM/PM. See [Sending a Message with TZO](https://documentation.mailgun.com/docs/mailgun/user-manual/sending-messages/send-tzo) for details. *Please note that TZO is only available on certain plans. See www.mailgun.com/pricing for more info*
  --o:testmode: string@o:testmode-completer # Enables sending in test mode. Messages are processed normally but not actually delivered to recipients. Useful for testing without sending real emails. See [Sending in Test Mode](https://documentation.mailgun.com/docs/mailgun/user-manual/sending-messages/test-mode)
  --o:tracking: string@o:tracking-completer # Toggles both click and open tracking on a per-message basis
  --o:tracking-clicks: string@o:tracking-clicks-completer # Toggles click tracking on a per-message basis, see [Tracking Clicks](https://documentation.mailgun.com/docs/mailgun/user-manual/tracking-messages/tracking-clicks).  This overrides the domain-level click tracking setting.
  --o:tracking-opens: string@o:tracking-opens-completer # Toggles opens tracking on a per-message basis, see [Tracking Opens](https://documentation.mailgun.com/docs/mailgun/user-manual/tracking-messages/tracking-opens).  Has higher priority than domain-level setting.
  --o:require-tls: string@o:require-tls-completer # When set to 'yes', requires the message to be sent only over a TLS connection to the Email Service Provider. If TLS cannot be established, the message will not be delivered. When set to 'no' (default), Mailgun attempts TLS but falls back to plaintext SMTP if needed.
  --o:skip-verification: string@o:skip-verification-completer # If `true`, the certificate and hostname of the resolved MX Host will not be verified when trying to establish a TLS connection. If `false`, Mailgun will verify the certificate and hostname. If either one can not be verified, a TLS connection will not be established. The default is `false`
  --o:sending-ip: string # Used to specify an IP Address to send an email that is owned by your account
  --o:sending-ip-pool: string # If an IP Pool ID is provided, the email will be delivered with an IP that belongs in that pool
  --o:tracking-pixel-location-top: string@o:tracking-pixel-location-top-completer # Places the tracking pixel at the top of emails instead of the bottom. Useful for long emails that may be truncated or have rendering issues, ensuring open tracking works accurately.
  --o:archive-to: string # Sends a copy of successfully delivered messages to the specified URL via HTTP POST. The request uses Content-Type: application/mime and contains the exact message the recipient's SMTP server received. NOTE: These are accounted for and billed as delivered messages
  --o:suppress-headers: string # Removes specified X-Mailgun headers from the delivered message. Provide header names separated by commas (e.g., 'X-Mailgun-Variables,X-Mailgun-Tag') or use 'all' to remove all X-Mailgun headers.Note: X-Mailgun-Sid header is currently used to process complains received via feedback loops.
  --h:X-My-Header: string # Adds custom headers to the email. Use 'h:' prefix followed by header name and value. Example: 'h:X-Custom-Header=my-value'
  --v:my-var: string # Attaches custom data to the message using the 'v:' prefix followed by a variable name. When sending with templates, provides values for template variable substitution (overridden by 't:variables' if both are provided). When not using templates, treated as metadata and included in events/webhooks. Variables are visible in the delivered email's X-Mailgun-Variables header. Example: 'v:user-id=123'. NOTE: Anything over 4KB will be truncated in the event/webhooks.
  --recipient-variables: string # A JSON-encoded dictionary for batch sending with personalized variables per recipient. Each key is a recipient email address, each value is a dictionary of variables for that recipient. Variables can be referenced in the message using %recipient.variablename%. Example: '{"alice@example.com": {"name":"Alice", "id":1}, "bob@example.com": {"name":"Bob", "id":2}}'. Maximum 1,000 recipients per batch. See [Batch Sending](https://documentation.mailgun.com/docs/mailgun/user-manual/sending-messages/batch-sending) for more information
]: any -> record<id: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/messages")
  let body = {from: $body_from, to: $body_to, cc: $cc, bcc: $bcc, subject: $subject, text: $text, html: $html, amp-html: $amp_html, attachment: $attachment, inline: $inline, template: $template, t:version: $t:version, t:text: $t:text, t:variables: $t:variables, o:tag: $o:tag, o:dkim: $o:dkim, o:secondary-dkim: $o:secondary_dkim, o:secondary-dkim-public: $o:secondary_dkim_public, o:deliverytime: $o:deliverytime, o:deliver-within: $o:deliver_within, o:deliverytime-optimize-period: $o:deliverytime_optimize_period, o:time-zone-localize: $o:time_zone_localize, o:testmode: $o:testmode, o:tracking: $o:tracking, o:tracking-clicks: $o:tracking_clicks, o:tracking-opens: $o:tracking_opens, o:require-tls: $o:require_tls, o:skip-verification: $o:skip_verification, o:sending-ip: $o:sending_ip, o:sending-ip-pool: $o:sending_ip_pool, o:tracking-pixel-location-top: $o:tracking_pixel_location_top, o:archive-to: $o:archive_to, o:suppress-headers: $o:suppress_headers, h:X-My-Header: $h:X_My_Header, v:my-var: $v:my_var, recipient-variables: $recipient_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Send an email in MIME format
#
# POST /v3/{domain_name}/messages.mime
# operationId: POST-v3--domain-name--messages-mime
export def "messagesmime POST-v3--domain-name--messages-mime" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-to: list # Email address of the recipient(s). Supports friendly name format. Example: `"Bob <bob@host.com>"`. Use commas to separate multiple recipients. Duplicate addresses are automatically ignored.
  message: string # MIME string of the message.  Make sure to use `multipart/form-data` content type to send this as a file upload (format: binary)
  --template: string # Name of a template stored via template API to use to render the email body. See [Templates](https://documentation.mailgun.com/docs/mailgun/user-manual/sending-messages/send-templates) for more information
  --t:version: string # Render a specific version of the given template instead of the latest version. `template` option must also be provided.
  --t:text: string@t:text-completer # Generates a plain text version of the template alongside the HTML version when sending templated emails. When set to 'yes', instructs Mailgun to create a text/plain MIME part based on the template content, ensuring compatibility with email clients that don't support HTML or have HTML rendering disabled. This improves email deliverability and accessibility by providing a fallback text version in multipart emails.
  --t:variables: string # A valid JSON-encoded dictionary used as the input for template variable expansion. See [Templates](https://documentation.mailgun.com/docs/mailgun/user-manual/sending-messages/send-templates) for more information
  --o:tag: list # Tag string.  See [Tags](https://documentation.mailgun.com/docs/mailgun/user-manual/tracking-messages/track-tagging) for more information
  --o:dkim: string@o:dkim-completer # Enables or disables DKIM signatures on a per-message basis. Overrides the domain-level DKIM setting for this specific message.
  --o:secondary-dkim: string # Specify a second domain key to sign the email with. The value is formatted as `signing_domain/selector`, e.g. `example.com/s1`. This tells Mailgun to sign the message with the signing domain `example.com` using the selector `s1`. Note: the domain key specified must have been previously created and activated.
  --o:secondary-dkim-public: string # Specify an alias of the domain key specified in `o:secondary-dkim`. Also formatted as `public_signing_domain/selector`. `o:secondary-dkim` option must also be provided. Mailgun will sign the message with the provided key of the secondary DKIM, but use the public secondary DKIM name and selector. Note: We will perform a DNS check prior to signing the message to ensure the public keys matches the secondary DKIM.
  --o:deliverytime: string # Specifies the scheduled delivery time in [RFC-2822 format](https://documentation.mailgun.com/docs/mailgun/api-reference/api-overview#date-format). Depending on your plan, you can schedule messages up to 3 or 7 days in advance. If your domain has a custom message_ttl (time-to-live) setting, this value determines the maximum scheduling duration. Example: 'Fri, 14 Oct 2011 12:00:00 +0000'
  --o:deliver-within: string # Specifies the maximum time window for delivering the message. Accepts values in format `[0-9]+h[0-9]+m` (e.g., `1h30m`, `30m`, `24h`), with a minimum of `5m` and maximum of `24h`. For scheduled messages, the delivery window starts from the scheduled time. The standard retry schedule applies within this window, so shorter timeframes may result in fewer delivery attempts.
  --o:deliverytime-optimize-period: string # Toggles Send Time Optimization (STO) on a per-message basis.  String should be set to the number of hours in `[0-9]+h` format, with the minimum being `24h` and the maximum being `72h`.  This value defines the time window in which Mailgun will run the optimization algorithm based on prior engagement data of a given recipient.  See [Sending a Message with STO](https://documentation.mailgun.com/docs/mailgun/user-manual/sending-messages/send-sto) for details. *Please note that STO is only available on certain plans. See www.mailgun.com/pricing for more info*
  --o:time-zone-localize: string # Toggles Timezone Optimization (TZO) on a per message basis. String should be set to preferred delivery time in `HH:mm` or `hh:mmaa` format, where `HH:mm` is used for 24 hour format without AM/PM and hh:mmaa is used for 12 hour format with AM/PM. See [Sending a Message with TZO](https://documentation.mailgun.com/docs/mailgun/user-manual/sending-messages/send-tzo) for details.  *Please note that TZO is only available on certain plans. See www.mailgun.com/pricing for more info*
  --o:testmode: string@o:testmode-completer # Enables sending in test mode. Messages are processed normally but not actually delivered to recipients. Useful for testing without sending real emails. See [Sending in Test Mode](https://documentation.mailgun.com/docs/mailgun/user-manual/sending-messages/test-mode)
  --o:tracking: string@o:tracking-completer # Toggles both click and open tracking on a per-message basis, see [Tracking Messages](https://documentation.mailgun.com/docs/mailgun/user-manual/tracking-messages) for details.
  --o:tracking-clicks: string@o:tracking-clicks-completer # Toggles click tracking on a per-message basis, see [Tracking Clicks](https://documentation.mailgun.com/docs/mailgun/user-manual/tracking-messages/tracking-clicks).  This overrides the domain-level click tracking setting
  --o:tracking-opens: string@o:tracking-opens-completer # Toggles opens tracking on a per-message basis, see [Tracking Opens](https://documentation.mailgun.com/docs/mailgun/user-manual/tracking-messages/tracking-opens). Has higher priority than domain-level setting.
  --o:require-tls: string@o:require-tls-completer # When set to 'yes', requires the message to be sent only over a TLS connection. If TLS cannot be established, the message will not be delivered. When set to 'no' (default), Mailgun attempts TLS but falls back to plaintext SMTP if needed.
  --o:skip-verification: string@o:skip-verification-completer # When set to 'true', skips certificate and hostname verification for TLS connections. When 'false' (default), Mailgun verifies certificates and hostnames - if verification fails, TLS connection is not established.
  --o:sending-ip: string # Used to specify an IP Address to send an email that is owned by your account
  --o:sending-ip-pool: string # If an IP Pool ID is provided, the email will be delivered with an IP that belongs in that pool
  --o:tracking-pixel-location-top: string@o:tracking-pixel-location-top-completer # Places the tracking pixel at the top of emails instead of the bottom. Useful for long emails that may be truncated or have rendering issues, ensuring open tracking works accurately.
  --o:archive-to: string # Sends a copy of successfully delivered messages to the specified URL via HTTP POST. The request uses Content-Type: application/mime and contains the exact message the recipient's SMTP server received. NOTE: These are accounted for and billed as delivered messages
  --o:suppress-headers: string # Removes specified X-Mailgun headers from the delivered message. Provide header names separated by commas (e.g., 'X-Mailgun-Variables,X-Mailgun-Tag') or use 'all' to remove all X-Mailgun headers.Note: X-Mailgun-Sid header is currently used to process complains received via feedback loops.
  --h:X-My-Header: string # Adds custom headers to the email. Use 'h:' prefix followed by header name and value. Example: 'h:X-Custom-Header=my-value'
  --v:my-var: string # Attaches custom data to the message using the 'v:' prefix followed by a variable name. When sending with templates, provides values for template variable substitution (overridden by 't:variables' if both are provided). When not using templates, treated as metadata and included in events/webhooks. Variables are visible in the delivered email's X-Mailgun-Variables header. Example: 'v:user-id=123'.NOTE: Anything over 4KB will be truncated in the event/webhooks
  --recipient-variables: string # A JSON-encoded dictionary for batch sending with personalized variables per recipient. Each key is a recipient email address, each value is a dictionary of variables for that recipient. Variables can be referenced in the message using %recipient.variablename%. Example: '{"alice@example.com": {"name":"Alice", "id":1}, "bob@example.com": {"name":"Bob", "id":2}}'. Maximum 1,000 recipients per batch. See [Batch Sending](https://documentation.mailgun.com/docs/mailgun/user-manual/sending-messages/batch-sending) for more information.
]: any -> record<id: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/messages.mime")
  let body = {to: $body_to, message: $message, template: $template, t:version: $t:version, t:text: $t:text, t:variables: $t:variables, o:tag: $o:tag, o:dkim: $o:dkim, o:secondary-dkim: $o:secondary_dkim, o:secondary-dkim-public: $o:secondary_dkim_public, o:deliverytime: $o:deliverytime, o:deliver-within: $o:deliver_within, o:deliverytime-optimize-period: $o:deliverytime_optimize_period, o:time-zone-localize: $o:time_zone_localize, o:testmode: $o:testmode, o:tracking: $o:tracking, o:tracking-clicks: $o:tracking_clicks, o:tracking-opens: $o:tracking_opens, o:require-tls: $o:require_tls, o:skip-verification: $o:skip_verification, o:sending-ip: $o:sending_ip, o:sending-ip-pool: $o:sending_ip_pool, o:tracking-pixel-location-top: $o:tracking_pixel_location_top, o:archive-to: $o:archive_to, o:suppress-headers: $o:suppress_headers, h:X-My-Header: $h:X_My_Header, v:my-var: $v:my_var, recipient-variables: $recipient_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve a stored email
#
# GET /v3/domains/{domain_name}/messages/{storage_key}
# operationId: GET-v3-domains--domain-name--messages--storage-key-
export def "domains-messages GET-v3-domains--domain-name--messages--storage-key-" [
  domain_name: string
  storage_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Content_Transfer_Encoding: string, Content_Type: string, From: string, Message_Id: string, Mime_Version: string, Subject: string, To: string, X_Mailgun_Tag: string, sender: string, recipients: string, body_html: string, body_plain: string, stripped_html: string, stripped_text: string, stripped_signature: string, message_headers: list<list<string>>, X_Mailgun_Template_Name: string, X_Mailgun_Template_Variables: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($domain_name)/messages/($storage_key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resend an email
#
# POST /v3/domains/{domain_name}/messages/{storage_key}
# operationId: POST-v3-domains--domain-name--messages--storage-key-
export def "domains-messages POST-v3-domains--domain-name--messages--storage-key-" [
  domain_name: string
  storage_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-to: string # Email address of the recipient(s). Supports friendly name format. Example: `"Bob <bob@host.com>"`. Use commas to separate multiple recipients. Duplicate addresses are automatically ignored.
]: any -> record<id: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($domain_name)/messages/($storage_key)")
  let body = {to: $body_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get domains
#
# GET /v4/domains
# operationId: GET-v4-domains
export def "domains GET-v4-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Max count of items. Max: 1000. Default: 100
  --skip: int # Get the list of items starting at the nth element. Default: 0
  --state: string # Get only domains with a specific state. Can be either active, unverified or disabled.
  --qp-sort: string # Valid sort options are `name` which defaults to asc order, `name:asc`, or `name:desc`. If sorting is not specified domains are returned in reverse creation date order.
  --authority: string # Get only domains with a specific authority. If state is specified then only state filtering will be proceed
  --search: string # Search domains by the given partial or complete name. Does not support wildcards
  --include-subaccounts: string@bool-completer # Search on every domain that belongs to any subaccounts under this account. Default to false.
]: nothing -> record<total_count: int, items: table<archive_to: string, created_at: string, id: string, is_disabled: bool, name: string, require_tls: bool, skip_verification: bool, smtp_login: string, smtp_password: string, spam_action: string, subaccount_id: string, state: string, type: string, tracking_host: string, use_automatic_sender_security: bool, webhooks_redact_pii: bool, web_prefix: string, web_scheme: string, wildcard: bool, disabled: any, encrypt_incoming_message: bool, message_ttl: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "authority" $authority "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "include_subaccounts" $include_subaccounts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a domain
#
# POST /v4/domains
# operationId: POST-v4-domains
export def "domains POST-v4-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archive-to: string # If set to a URL, then each successfully delivered message will be submitted in an HTTP POST request to the URL. The Content-Type of the POST requests is application/mime and the request body is exactly what the recipient SMTP server received.
  --dkim-host-name: string # Set the DKIM host name for the domain that is being created. Note, the value must be a valid domain name, and can be the domain name being created or the root domain. This parameter cannot be used in conjunction with force_dkim_authority or force_root_dkim_host.
  --dkim-key-size: string # The size of the new domain's DKIM key. Shall be either 1024 or 2048.
  --dkim-selector: string # Explicitly set the value of the DKIM selector for the domain being created. If the domain key does not already exist, one will be created.  The selector must be a valid atom per RFC2822. e.g valid value `foobar`, invalid value `foo.bar`  https://datatracker.ietf.org/doc/html/rfc2822#section-3.2.4
  --encrypt-incoming-message: string@bool-completer # Enable encrypting incoming messages for the given domain. This cannot be altered via API after being set for security purposes. Reach out to Support to disable if necessary. Default to false
  --force-dkim-authority: string@bool-completer # If set to true, the domain will be the DKIM authority for itself even if the root domain is registered on the same mailgun account. If set to false, the domain will have the same DKIM authority as the root domain registered on the same mailgun account. Default to false.
  --force-root-dkim-host: string@bool-completer # If set to true, the root domain will be the DKIM Host for the domain being created even if the root domain itself is not registered with Mailgun. The domain being created will still need to pass domain verification with valid spf records for the domain and valid DKIM record for the root domain.  This does not effect the smtp mail-from host for the domain being created. The mail-from host will remain the domain name being created, not the root domain.
  --wildcard: string@bool-completer # Allows domain to accept inbound messages received on subdomains that have MX records pointed to Mailgun. Default is false.
  name: string # The name of the new domain
  --pool-id: string # Requested IP Pool to be assigned to the domain at creation.
  --ips: string # An optional, comma-separated list of IP addresses to be assigned to this domain. If not specified, all dedicated IP addresses on the account will be assigned. If the request cannot be fulfilled (e.g. a requested IP is not assigned to the account, etc), a 400 will be returned.
  --require-tls: string@bool-completer # If set to true, this requires messages for the domain only be sent over a TLS connection. If a TLS connection cannot be established, Mailgun will not deliver the message.  If set to false, Mailgun will still try and upgrade the connection, but if Mailgun cannot, the message will be delivered over a plaintext SMTP connection.  The default value is false.
  --skip-verification: string@bool-completer # If set to true, the certificate and hostname will not be verified when trying to establish a TLS connection and Mailgun will accept any certificate during delivery of a message.  If set to false, Mailgun will verify the certificate and hostname. If either one can not be verified, a TLS connection will not be established.  The default value is false.
  --spam-action: string # Disabled, block or tag. Default to disabled. If disabled, no spam filtering will occur for inbound messages.  If block, inbound spam messages will not be delivered.  If tag, inbound messages will be tagged with a spam header. See Spam Filter.
  --smtp-password: string # Password for SMTP authentication
  --use-automatic-sender-security: string@bool-completer # Enable Automatic Sender Security. This requires setting DNS CNAME entries for DKIM keys instead of a TXT record. Defaults to false.
  --webhooks-redact-pii: string@bool-completer # If set to true, Personally Identifiable Information (PII) will be redacted from the payload of any webhook posted for this domain
  --web-prefix: string # Sets your open, click and unsubscribe URLs domain name prefix. Links rewritten or added by Mailgun in your emails will look like <web_scheme>://<web_prefix>.<domain_name>/... Default to email
  --web-scheme: string # Sets your open, click and unsubscribe URLs to use http or https. Value either `http` or `https`. Defaults to http. In order for https to work, you must have a valid cert created for your domain. See Domain Tracking for TLS cert generation.
  --message-ttl: int # Specifies the time-to-live (TTL) in seconds for retrieving both incoming and outgoing messages. The maximum TTL value is determined by your subscription plan.
]: any -> record<message: string, domain: any, receiving_dns_records: list<any>, sending_dns_records: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/domains")
  let body = {archive_to: $archive_to, dkim_host_name: $dkim_host_name, dkim_key_size: $dkim_key_size, dkim_selector: $dkim_selector, encrypt_incoming_message: $encrypt_incoming_message, force_dkim_authority: $force_dkim_authority, force_root_dkim_host: $force_root_dkim_host, wildcard: $wildcard, name: $name, pool_id: $pool_id, ips: $ips, require_tls: $require_tls, skip_verification: $skip_verification, spam_action: $spam_action, smtp_password: $smtp_password, use_automatic_sender_security: $use_automatic_sender_security, webhooks_redact_pii: $webhooks_redact_pii, web_prefix: $web_prefix, web_scheme: $web_scheme, message_ttl: $message_ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get domain details
#
# GET /v4/domains/{name}
# operationId: GET-v4-domains--name-
export def "domains GET-v4-domains--name-" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<domain: any, receiving_dns_records: list<any>, sending_dns_records: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/domains/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update domain
#
# PUT /v4/domains/{name}
# operationId: PUT-v4-domains--name-
export def "domains PUT-v4-domains--name-" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archive-to: string # If set to a URL, then each successfully delivered message will be submitted in an HTTP POST request to the URL. The Content-Type of the POST requests is application/mime and the request body is exactly what the recipient SMTP server received.
  --mailfrom-host: string # The hostname to update to. Must be in lower case
  --message-ttl: int # Specifies the time-to-live (TTL) in seconds for retrieving both incoming and outgoing messages. The maximum TTL value is determined by your subscription plan.
  --require-tls: string@bool-completer # If set to true, this requires messages for the domain only be sent over a TLS connection. If a TLS connection cannot be established, Mailgun will not deliver the message.  If set to false, Mailgun will still try and upgrade the connection, but if Mailgun cannot, the message will be delivered over a plaintext SMTP connection.  The default value is false.
  --skip-verification: string@bool-completer # If set to true, the certificate and hostname will not be verified when trying to establish a TLS connection and Mailgun will accept any certificate during delivery of a message.  If set to false, Mailgun will verify the certificate and hostname. If either one can not be verified, a TLS connection will not be established.  The default value is false.
  --smtp-password: string # Updates the domain's SMTP credentials with the given string
  --spam-action: string # Updates the domain's spam action. Valid values are 'disabled', 'tag', and 'block'
  --use-automatic-sender-security: string@bool-completer # Enable or disable Automatic Sender Security. If enabled, requires setting DNS CNAME entries for DKIM keys instead of a TXT record. Domain must be reverified after changing this field. Defaults to false
  --webhooks-redact-pii: string@bool-completer # If set to true, Personally Identifiable Information (PII) will be redacted from the payload of any webhook posted for this domain
  --web-scheme: string # Updates your open, click and unsubscribe URLs to use http or https. Value either `http` or `https`. Defaults to http. In order for https to work, you must have a valid cert created for your domain. See Domain Tracking for TLS cert generation.
  --web-prefix: string # This updates the web prefix used for a domain's tracking features.  Must be a valid atom. Nothing will be updated if omitted. This impacts click, open, and unsubscribe tracking features.    Note: Updating the web prefix for a domain will require also updating the domain's DNS to include the CNAME record to match. For example, if you set the web prefix to `zed` for the domain `my-domain.com`, the corresponding CNAME `zed.my-domain.com` will need to be created in your domain's dns zone.
  --wildcard: string@bool-completer # Updates the domain's wildcard status with the given boolean
]: any -> record<message: string, domain: any, receiving_dns_records: list<any>, sending_dns_records: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/domains/($name)")
  let body = {archive_to: $archive_to, mailfrom_host: $mailfrom_host, message_ttl: $message_ttl, require_tls: $require_tls, skip_verification: $skip_verification, smtp_password: $smtp_password, spam_action: $spam_action, use_automatic_sender_security: $use_automatic_sender_security, webhooks_redact_pii: $webhooks_redact_pii, web_scheme: $web_scheme, web_prefix: $web_prefix, wildcard: $wildcard} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Verify Domain
#
# PUT /v4/domains/{name}/verify
# operationId: PUT-v4-domains--name--verify
export def "domains-verify PUT-v4-domains--name--verify" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, domain: any, sending_dns_records: list<any>, receiving_dns_records: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/domains/($name)/verify")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a domain
#
# DELETE /v3/domains/{name}
# operationId: DELETE-v3-domains--name-
export def "domains DELETE-v3-domains--name-" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get domain webhooks
#
# GET /v3/domains/{domain}/webhooks
# operationId: GET-v3-domains--domain--webhooks
export def "domains-webhooks GET-v3-domains--domain--webhooks" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<webhooks: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($domain)/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a domain webhook
#
# POST /v3/domains/{domain}/webhooks
# operationId: POST-v3-domains--domain--webhooks
export def "domains-webhooks POST-v3-domains--domain--webhooks" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string@id-completer # Webhook type to create.
  --body-url: string # url(s) for webhooks to be sent to. Use multiple times to associate more than one url. Maximum of 3 urls for a given webhook type.
]: any -> record<message: string, webhook: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($domain)/webhooks")
  let body = {id: $id, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get domain webhooks by type
#
# GET /v3/domains/{domain_name}/webhooks/{webhook_name}
# operationId: GET-v3-domains--domain-name--webhooks--webhook-name-
export def "domains-webhooks GET-v3-domains--domain-name--webhooks--webhook-name-" [
  domain_name: string
  webhook_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<webhook: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($domain_name)/webhooks/($webhook_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update domain webhook
#
# PUT /v3/domains/{domain_name}/webhooks/{webhook_name}
# operationId: PUT-v3-domains--domain-name--webhooks--webhook-name-
export def "domains-webhooks PUT-v3-domains--domain-name--webhooks--webhook-name-" [
  domain_name: string
  webhook_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # New url(s) to associate to webhook. Use multiple times to associate more than one url. Maximum of 3 urls for a given type.
]: any -> record<message: string, webhook: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($domain_name)/webhooks/($webhook_name)")
  let body = {url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete domain webhooks by type
#
# DELETE /v3/domains/{domain_name}/webhooks/{webhook_name}
# operationId: DELETE-v3-domains--domain-name--webhooks--webhook-name-
export def "domains-webhooks DELETE-v3-domains--domain-name--webhooks--webhook-name-" [
  domain_name: string
  webhook_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, webhook: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($domain_name)/webhooks/($webhook_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update domain webhooks (v4)
#
# PUT /v4/domains/{domain}/webhooks
# operationId: PUT-v4-domains--domain--webhooks
export def "domains-webhooks PUT-v4-domains--domain--webhooks" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # The webhook URL to update
  event_types: string@event-types-completer # Event types to associate with this URL. Use multiple times to specify multiple event types. This replaces the existing associations. 
]: any -> record<webhooks: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/domains/($domain)/webhooks")
  let body = {url: $body_url, event_types: $event_types} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create domain webhooks (v4)
#
# POST /v4/domains/{domain}/webhooks
# operationId: POST-v4-domains--domain--webhooks
export def "domains-webhooks POST-v4-domains--domain--webhooks" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # The webhook URL that will receive POST requests
  event_types: string@event-types-completer # Event types. Use multiple times to specify multiple event types. 
]: any -> record<webhooks: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/domains/($domain)/webhooks")
  let body = {url: $body_url, event_types: $event_types} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete domain webhooks (v4)
#
# DELETE /v4/domains/{domain}/webhooks
# operationId: DELETE-v4-domains--domain--webhooks
export def "domains-webhooks DELETE-v4-domains--domain--webhooks" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-url: list # The webhook URL to delete. The URL is removed from all event types it's associated with. To delete multiple URLs in one request, repeat the parameter (e.g., `?url=https://a.example&url=https://b.example`).
]: nothing -> record<webhooks: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/domains/($domain)/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get tracking settings
#
# GET /v3/domains/{name}/tracking
# operationId: GET-v3-domains--name--tracking
export def "domains-tracking GET-v3-domains--name--tracking" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tracking: record<open: record, click: record, unsubscribe: record, web_scheme: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($name)/tracking")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update click tracking settings
#
# PUT /v3/domains/{name}/tracking/click
# operationId: PUT-v3-domains--name--tracking-click
export def "domains-tracking-click PUT-v3-domains--name--tracking-click" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string # Set param to `htmlonly`, `true`, or `false`.  Omit this param to make no change to the active status. Click tracking is consider as active if it's in the 'htmlonly' or 'true' state
]: any -> record<message: string, click: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($name)/tracking/click")
  let body = {active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Update open tracking settings
#
# PUT /v3/domains/{name}/tracking/open
# operationId: PUT-v3-domains--name--tracking-open
export def "domains-tracking-open PUT-v3-domains--name--tracking-open" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # Set this param to true or false to toggle open tracking active status. Omit this param to keep current settings.
  --place-at-the-top: string@bool-completer # Setting this param to true will place the open tracking pixel at the top of the HTML body when inserted into the email mime. Omit this param to keep current setting.
]: any -> record<message: string, open: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($name)/tracking/open")
  let body = {active: $active, place_at_the_top: $place_at_the_top} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Update unsubscribe tracking settings
#
# PUT /v3/domains/{name}/tracking/unsubscribe
# operationId: PUT-v3-domains--name--tracking-unsubscribe
export def "domains-tracking-unsubscribe PUT-v3-domains--name--tracking-unsubscribe" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # This param will toggle the active status of unsubscribe tracking on the domain.
  --html-footer: string # Updates the html footer for the unsubscribe link inserted into the email html part of the mime.
  --text-footer: string # Updates the text footer for the unsubscribe link inserted into the email plain part of the mime.
]: any -> record<message: string, unsubscribe: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($name)/tracking/unsubscribe")
  let body = {active: $active, html_footer: $html_footer, text_footer: $text_footer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List keys for all domains
#
# GET /v1/dkim/keys
# operationId: GET-v1-dkim-keys
export def "dkim-keys GET-v1-dkim-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  page: string # Encoded paging information, provided via 'next', 'previous' links
  limit: int # Limits the number of items returned in a request
  --signing-domain: string # Filter by signing domain
  --selector: string # Filter by selector
]: any -> record<items: list<any>, paging: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dkim/keys")
  let body = {page: $page, limit: $limit, signing_domain: $signing_domain, selector: $selector} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create a domain key
#
# POST /v1/dkim/keys
# operationId: POST-v1-dkim-keys
export def "dkim-keys POST-v1-dkim-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  signing_domain: string # Signing domain to be used for the new domain key
  selector: string # Selector to be used for the new domain key
  --bits: int # Key size, can be 1024 or 2048
  --pem: string # Private key PEM file
]: any -> record<signing_domain: string, selector: string, dns_record: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dkim/keys")
  let body = {signing_domain: $signing_domain, selector: $selector, bits: $bits, pem: $pem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete a domain key
#
# DELETE /v1/dkim/keys
# operationId: DELETE-v1-dkim-keys
export def "dkim-keys DELETE-v1-dkim-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --signing-domain: string # Signing Domain
  --selector: string # Selector
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "signing_domain" $signing_domain "scalar") (serialize-qp "selector" $selector "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/dkim/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Activate a domain key
#
# PUT /v4/domains/{authority_name}/keys/{selector}/activate
# operationId: PUT-v4-domains--authority-name--keys--selector--activate
export def "domains-keys-activate PUT-v4-domains--authority-name--keys--selector--activate" [
  authority_name: string
  selector: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, authority: string, selector: string, active: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/domains/($authority_name)/keys/($selector)/activate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List domain keys
#
# GET /v4/domains/{authority_name}/keys
# operationId: GET-v4-domains--authority-name--keys
export def "domains-keys GET-v4-domains--authority-name--keys" [
  authority_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/domains/($authority_name)/keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deactivate a domain key
#
# PUT /v4/domains/{authority_name}/keys/{selector}/deactivate
# operationId: PUT-v4-domains--authority-name--keys--selector--deactivate
export def "domains-keys-deactivate PUT-v4-domains--authority-name--keys--selector--deactivate" [
  authority_name: string
  selector: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, authority: string, selector: string, active: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/domains/($authority_name)/keys/($selector)/deactivate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update DKIM authority
#
# PUT /v3/domains/{name}/dkim_authority
# operationId: PUT-v3-domains--name--dkim-authority
export def "domains-dkim-authority PUT-v3-domains--name--dkim-authority" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --self: string@bool-completer # Change the DKIM authority for a domain. If set to true, the domain will be the DKIM authority for itself even if the root domain is registered on the same mailgun account  If set to false, the domain will have the same DKIM authority as the root domain registered on the same mailgun account.
]: any -> record<message: string, sending_dns_records: list<any>, changed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($name)/dkim_authority")
  let body = {self: $self} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Update a DKIM selector
#
# PUT /v3/domains/{name}/dkim_selector
# operationId: PUT-v3-domains--name--dkim-selector
export def "domains-dkim-selector PUT-v3-domains--name--dkim-selector" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dkim-selector: string # Update the DKIM selector for a domain. If omitted no change is committed.
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($name)/dkim_selector")
  let body = {dkim_selector: $dkim_selector} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List account-level webhooks
#
# GET /v1/webhooks
# operationId: GET-v1-webhooks
export def "webhooks GET-v1-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook-ids: string # Comma-separated list of webhook IDs to filter results. If specified, only webhooks with matching IDs will be returned.
]: nothing -> record<webhooks: table<webhook_id: string, description: string, url: string, event_types: list, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "webhook_ids" $webhook_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an account-level webhook
#
# POST /v1/webhooks
# operationId: POST-v1-webhooks
export def "webhooks POST-v1-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description for the webhook
  event_types: string@event-types-completer # Event types to subscribe to. Use multiple times to specify multiple event types. Maximum of 3 unique URLs per event type.
  --body-url: string # URL for webhook to be sent to
]: any -> record<webhook_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/webhooks")
  let body = {description: $description, event_types: $event_types, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete account-level webhooks
#
# DELETE /v1/webhooks
# operationId: DELETE-v1-webhooks
export def "webhooks DELETE-v1-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook-ids: string # Comma-separated list of webhook IDs to delete. If provided, only these specific webhooks will be deleted.
  --all: string@bool-completer # Set to 'true' to delete all account-level webhooks. This acts as a safety mechanism to prevent accidental deletion of all webhooks.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "webhook_ids" $webhook_ids "scalar") (serialize-qp "all" $all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get account-level webhook by ID
#
# GET /v1/webhooks/{webhook_id}
# operationId: GET-v1-webhooks--webhook-id-
export def "webhooks GET-v1-webhooks--webhook-id-" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<webhook_id: string, description: string, url: string, event_types: list<string>, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an account-level webhook
#
# PUT /v1/webhooks/{webhook_id}
# operationId: PUT-v1-webhooks--webhook-id-
export def "webhooks PUT-v1-webhooks--webhook-id-" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description for the webhook
  event_types: string@event-types-completer # Event types to subscribe to. Use multiple times to specify multiple event types. Maximum of 3 unique URLs per event type.
  --body-url: string # URL for webhook to be sent to
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/webhooks/($webhook_id)")
  let body = {description: $description, event_types: $event_types, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete account-level webhook by ID
#
# DELETE /v1/webhooks/{webhook_id}
# operationId: DELETE-v1-webhooks--webhook-id-
export def "webhooks DELETE-v1-webhooks--webhook-id-" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get messages queue status
#
# GET /v3/domains/{name}/sending_queues
# operationId: GET-v3-domains--name--sending-queues
export def "domains-sending-queues GET-v3-domains--name--sending-queues" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<regular: record, scheduled: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($name)/sending_queues")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Automatic Sender Security DKIM key rotation for a domain
#
# PUT /v1/dkim_management/domains/{name}/rotation
# operationId: PUT-v1-dkim-management-domains--name--rotation
export def "dkim-management-domains-rotation PUT-v1-dkim-management-domains--name--rotation" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rotation-enabled: string@bool-completer # If true, enables DKIM Auto-Rotation. If false, disables it
  --rotation-interval: string # The interval at which to rotate keys. Example, '5d' for five days
]: any -> record<domain: record<id: string, account_id: string, sid: string, name: string, state: string, active_selector: string, rotation_enabled: string, rotation_interval: string, records: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dkim_management/domains/($name)/rotation")
  let body = {rotation_enabled: $rotation_enabled, rotation_interval: $rotation_interval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Rotate Automatic Sender Security DKIM key for a domain
#
# POST /v1/dkim_management/domains/{name}/rotate
# operationId: POST-v1-dkim-management-domains--name--rotate
export def "dkim-management-domains-rotate POST-v1-dkim-management-domains--name--rotate" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dkim_management/domains/($name)/rotate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List DIPPs delegated to subaccounts
#
# GET /v5/accounts/subaccounts/ip_pools/all
# operationId: GET-v5-accounts-subaccounts-ip-pools-all
export def "accounts-subaccounts-ip-pools-all GET-v5-accounts-subaccounts-ip-pools-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<pool_id: string, subaccount_id: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v5/accounts/subaccounts/ip_pools/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delegate a DIPP to a subaccount
#
# PUT /v5/accounts/subaccounts/{subaccountId}/ip_pool
# DEPRECATED
# operationId: PUT-v5-accounts-subaccounts--subaccountId--ip-pool
@deprecated
export def "accounts-subaccounts-ip-pool PUT-v5-accounts-subaccounts--subaccountId--ip-pool" [
  subaccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, reference_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v5/accounts/subaccounts/($subaccountId)/ip_pool")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke a DIPP delegated to a subaccount
#
# DELETE /v5/accounts/subaccounts/{subaccountId}/ip_pool
# DEPRECATED
# operationId: DELETE-v5-accounts-subaccounts--subaccountId--ip-pool
@deprecated
export def "accounts-subaccounts-ip-pool DELETE-v5-accounts-subaccounts--subaccountId--ip-pool" [
  subaccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pool-id: string # Id of the DIPP to revoke
]: nothing -> record<message: string, reference_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pool_id" $pool_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v5/accounts/subaccounts/($subaccountId)/ip_pool" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the dedicated IP pool used for spillover for a domain
#
# GET /v3/ips/domain/{name}
# operationId: GET-v3-ips-domain--name-
export def "ips-domain GET-v3-ips-domain--name-" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<extra_dedicated_ips: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/ips/domain/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set or modify the dediciated IP pool used for spillover for a domain
#
# PATCH /v3/ips/domain/{name}
# operationId: PATCH-v3-ips-domain--name-
# --extra_dedicated_ips shape: {pool_id: string}
export def "ips-domain PATCH-v3-ips-domain--name-" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  extra_dedicated_ips: record # the DIPP spillover settings for the account — shape: {pool_id: string}
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/ips/domain/($name)")
  let body = {extra_dedicated_ips: $extra_dedicated_ips} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an IP from the domain pool, unlink a DIPP or remove the domain pool
#
# DELETE /v3/domains/{name}/ips/{ip}
# operationId: DELETE-v3-domains--name--ips--ip-
export def "domains-ips DELETE-v3-domains--name--ips--ip-" [
  ip: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ip: string # Replacement IP or special value `shared`.
  --pool-id: string # Replacement DIPP id.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ip" $ip "scalar") (serialize-qp "pool_id" $pool_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/domains/($name)/ips/($ip)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove an IP from the domain pool, unlink a DIPP or remove the domain pool
#
# DELETE /v3/domains/{name}/pool/{ip}
# operationId: DELETE-v3-domains--name--pool--ip-
export def "domains-pool DELETE-v3-domains--name--pool--ip-" [
  ip: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ip: string # Replacement IP or special value `shared`.
  --pool-id: string # Replacement DIPP id.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ip" $ip "scalar") (serialize-qp "pool_id" $pool_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/domains/($name)/pool/($ip)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enroll domain
#
# POST /v3/domains/{name}/dynamic_pools
# operationId: POST-v3-domains--name--dynamic-pools
export def "domains-dynamic-pools POST-v3-domains--name--dynamic-pools" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --replacement-ip: string # A valid IP address or 'shared'
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "replacement_ip" $replacement_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/domains/($name)/dynamic_pools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove domain from dynamic IP pools
#
# DELETE /v3/domains/{name}/dynamic_pools
# operationId: DELETE-v3-domains--name--dynamic-pools
export def "domains-dynamic-pools DELETE-v3-domains--name--dynamic-pools" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --replacement-ip: string # A valid IP address or 'shared'. This field can be specified multiple times if all provided IPs are dedicated. Cannot be provided if providing 'replacement_pool_id' param
  --replacement-pool-id: string # A valid dedicated IP pool ID to assign to the domain. Cannot be provided if providing 'replacement_ip' param
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "replacement_ip" $replacement_ip "scalar") (serialize-qp "replacement_pool_id" $replacement_pool_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/domains/($name)/dynamic_pools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List assignable domains
#
# GET /v3/domains/dynamic_pools/assignable
# operationId: GET-v3-domains-dynamic-pools-assignable
export def "domains-dynamic-pools-assignable GET-v3-domains-dynamic-pools-assignable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subaccount-id: string # If provided, queries domains belonging to the subaccount. Must be a valid account ID
  --domain: string # Regex search term to query a domain by name
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subaccount_id" $subaccount_id "scalar") (serialize-qp "domain" $domain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/domains/dynamic_pools/assignable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enroll all account domains
#
# POST /v3/domains/all/dynamic_pools/enroll
# operationId: POST-v3-domains-all-dynamic-pools-enroll
export def "domains-all-dynamic-pools-enroll POST-v3-domains-all-dynamic-pools-enroll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-subaccounts: string@bool-completer # If true, domains belonging to subaccounts will also be enrolled in Dynamic IP Pools (default: false)
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_subaccounts" $include_subaccounts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/domains/all/dynamic_pools/enroll" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get DIPP spillover settings for an account
#
# GET /v3/ips/account/settings
# operationId: GET-v3-ips-account-settings
export def "ips-account-settings GET-v3-ips-account-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<extra_dedicated_ips: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/ips/account/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set or Modify the dedicated IP pool used for IP spillover
#
# PATCH /v3/ips/account/settings
# operationId: PATCH-v3-ips-account-settings
# --extra_dedicated_ips shape: {pool_id: string}
export def "ips-account-settings PATCH-v3-ips-account-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  extra_dedicated_ips: record # the DIPP spillover settings for the account.  This value will apply to all domains under the account — shape: {pool_id: string}
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/ips/account/settings")
  let body = {extra_dedicated_ips: $extra_dedicated_ips} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List account IPs
#
# GET /v3/ips
# operationId: GET-v3-ips
export def "ips GET-v3-ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dedicated: string@bool-completer # Return only dedicated IPs
  --enabled: string@bool-completer # Return only enabled IPs
]: nothing -> record<assignable_to_pools: list<string>, details: table<ip: string, is_on_warmup: bool, dedicated: bool, enabled: bool>, items: list<string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dedicated" $dedicated "scalar") (serialize-qp "enabled" $enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/ips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details about account IP
#
# GET /v3/ips/{ip}
# operationId: GET-v3-ips--ip-
export def "ips GET-v3-ips--ip-" [
  ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dedicated: bool, ip: string, rdns: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/ips/($ip)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all domains of an account where a specific IP is assigned
#
# GET /v3/ips/{ip}/domains
# operationId: GET-v3-ips--ip--domains
export def "ips-domains GET-v3-ips--ip--domains" [
  ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The limit to apply to the returned domains
  --search: string # The search query that the returned domains' names must match
  --skip: int # The number of matching domains to skip in the response
]: nothing -> record<items: table<ips: list, domain: string, linked_at: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/ips/($ip)/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign an IP to all account domains
#
# POST /v3/ips/{ip}/domains
# operationId: POST-v3-ips--ip--domains
export def "ips-domains POST-v3-ips--ip--domains" [
  ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, reference_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/ips/($ip)/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove an IP from all account domains
#
# DELETE /v3/ips/{ip}/domains
# operationId: DELETE-v3-ips--ip--domains
export def "ips-domains DELETE-v3-ips--ip--domains" [
  ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alternative: string # An IP that will replace the removed IP on all domains
]: nothing -> record<message: string, reference_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alternative" $alternative "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/ips/($ip)/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Place account IP into a dedicated IP band
#
# POST /v3/ips/{addr}/ip_band
# operationId: POST-v3-ips--addr--ip-band
export def "ips-ip-band POST-v3-ips--addr--ip-band" [
  addr: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ip_band: string # Dedicated IP band to place the IP address into
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/ips/($addr)/ip_band")
  let body = {ip_band: $ip_band} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Return the number of IPs available to the account per its billing plan
#
# GET /v3/ips/request/new
# operationId: GET-v3-ips-request-new
export def "ips-request-new GET-v3-ips-request-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/ips/request/new")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new dedicated IP to the account
#
# POST /v3/ips/request/new
# operationId: POST-v3-ips-request-new
export def "ips-request-new POST-v3-ips-request-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/ips/request/new")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List account IPs - detailed view
#
# GET /v3/ips/details/all
# operationId: GET-v3-ips-details-all
export def "ips-details-all GET-v3-ips-details-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum records to return (default: 10)
  --skip: int # The amount of returned records to skip (default: 0)
  --pool-id: string # Filter IPs linked to a pool. Value can be a specific pool ID, 'any' or 'none'
  --domain-id: string # Filter IPs linked to a domain. Value can be a specific domain ID, 'any' or 'none'
  --subaccount-id: string # Filter IPs linked to a subaccount. Value can be a specific subaccount ID, 'any' or 'none'
  --ip: string # Search for IPs containing this text (supports partial matching)
  --sort-by: string # Name of the field to sort results by
  --sort-order: string # Sort results 'descending' or 'ascending' (default: ascending)
]: nothing -> record<items: table<address: string, parent_account_id: string, account_id: string, pool_ids: list, dedicated: bool, created_at: string, pool_last_modified_at: string, domains_last_modified_at: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "pool_id" $pool_id "scalar") (serialize-qp "domain_id" $domain_id "scalar") (serialize-qp "subaccount_id" $subaccount_id "scalar") (serialize-qp "ip" $ip "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/ips/details/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all Dynamic IP pools
#
# GET /v3/dynamic_pools
# operationId: GET-v3-dynamic-pools
export def "dynamic-pools GET-v3-dynamic-pools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/dynamic_pools")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initialize/set IPs for all pools
#
# POST /v3/dynamic_pools/all
# operationId: POST-v3-dynamic-pools-all
export def "dynamic-pools-all POST-v3-dynamic-pools-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  good_reputation: string # IP(s) to include in the good_reputation pool
  poor_reputation: string # IP(s) to include in the poor_reputation pool
  new_senders: string # IP(s) to include in the new_senders pool
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/dynamic_pools/all")
  let body = {good_reputation: $good_reputation, poor_reputation: $poor_reputation, new_senders: $new_senders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Remove all dynamic IP pools
#
# DELETE /v3/dynamic_pools/all
# operationId: DELETE-v3-dynamic-pools-all
export def "dynamic-pools-all DELETE-v3-dynamic-pools-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/dynamic_pools/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add IP to Dynamic IP Pool
#
# POST /v3/dynamic_pools/{pool_name}/{ip}
# operationId: POST-v3-dynamic-pools--pool-name---ip-
export def "dynamic-pools POST-v3-dynamic-pools--pool-name---ip-" [
  pool_name: string
  ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/dynamic_pools/($pool_name)/($ip)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update pool IPs
#
# PATCH /v3/dynamic_pools/{pool_name}
# operationId: PATCH-v3-dynamic-pools--pool-name-
export def "dynamic-pools PATCH-v3-dynamic-pools--pool-name-" [
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  add_ip: string # IP(s) to add to the pool
  remove_ip: string # IP(s) to remove from the pool
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/dynamic_pools/($pool_name)")
  let body = {add_ip: $add_ip, remove_ip: $remove_ip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List dedicated IP pools of the account
#
# GET /v3/ip_pools
# operationId: GET-v3-ip-pools
export def "ip-pools GET-v3-ip-pools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ip_pools: table<description: string, ips: list, metadata: record, is_inherited: bool, is_linked: bool, name: string, pool_id: string>, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/ip_pools")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new DIPP to the account
#
# POST /v3/ip_pools
# operationId: POST-v3-ip-pools
export def "ip-pools POST-v3-ip-pools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # Description of the DIPP
  --ip: string # IP address to add to the DIPP (may be specified multiple times)
  name: string # Short name of the DIPP
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/ip_pools")
  let body = {description: $description, ip: $ip, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get DIPP details
#
# GET /v3/ip_pools/{pool_id}
# operationId: GET-v3-ip-pools--pool-id-
export def "ip-pools GET-v3-ip-pools--pool-id-" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/ip_pools/($pool_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the DIPP
#
# DELETE /v3/ip_pools/{pool_id}
# operationId: DELETE-v3-ip-pools--pool-id-
export def "ip-pools DELETE-v3-ip-pools--pool-id-" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ip: string # Replacement IP or a special value `shared`
  --pool-id: string # Id of the replacement DIPP
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ip" $ip "scalar") (serialize-qp "pool_id" $pool_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/ip_pools/($pool_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit DIPP
#
# PATCH /v3/ip_pools/{pool_id}
# operationId: PATCH-v3-ip-pools--pool-id-
export def "ip-pools PATCH-v3-ip-pools--pool-id-" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --add-ip: string # The IP to add to the DIPP (may be specified multiple times)
  --description: string # The new description for the DIPP
  --link-domain: string # The ID of the domain link to the DIPP (may be specified multiple times)
  --name: string # The new short for the DIPP
  --remove-ip: string # The IP to remove from the DIPP (may be specified multiple times)
  --unlink-domain: string # The ID of the domain to unlink from the DIPP (may be specified multiple times)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/ip_pools/($pool_id)")
  let body = {add_ip: $add_ip, description: $description, link_domain: $link_domain, name: $name, remove_ip: $remove_ip, unlink_domain: $unlink_domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get domains linked to DIPP
#
# GET /v3/ip_pools/{pool_id}/domains
# operationId: GET-v3-ip-pools--pool-id--domains
export def "ip-pools-domains GET-v3-ip-pools--pool-id--domains" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of records to return (default: 10)
  --page: string # Encoded page identifier retrieved from previous call
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/ip_pools/($pool_id)/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an IP to a DIPP
#
# PUT /v3/ip_pools/{pool_id}/ips/{ip}
# operationId: PUT-v3-ip-pools--pool-id--ips--ip-
export def "ip-pools-ips PUT-v3-ip-pools--pool-id--ips--ip-" [
  ip: string
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/ip_pools/($pool_id)/ips/($ip)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove an IP from a DIPP
#
# DELETE /v3/ip_pools/{pool_id}/ips/{ip}
# operationId: DELETE-v3-ip-pools--pool-id--ips--ip-
export def "ip-pools-ips DELETE-v3-ip-pools--pool-id--ips--ip-" [
  ip: string
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/ip_pools/($pool_id)/ips/($ip)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add multiple IPs to the DIPP
#
# POST /v3/ip_pools/{pool_id}/ips.json
# operationId: POST-v3-ip-pools--pool-id--ips-json
export def "ip-pools-ipsjson POST-v3-ip-pools--pool-id--ips-json" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ips: list # IPs to add to the DIPP
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/ip_pools/($pool_id)/ips.json")
  let body = {ips: $ips} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delegate DIPP to Subaccount
#
# PUT /v3/ip_pools/{pool_id}/delegate
# operationId: PUT-v3-ip-pools--pool-id--delegate
export def "ip-pools-delegate PUT-v3-ip-pools--pool-id--delegate" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subaccount_id: string # The ID of the subaccount to delegate the pool to
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/ip_pools/($pool_id)/delegate")
  let body = {subaccount_id: $subaccount_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Revoke DIPP from Subaccount
#
# DELETE /v3/ip_pools/{pool_id}/delegate
# operationId: DELETE-v3-ip-pools--pool-id--delegate
export def "ip-pools-delegate DELETE-v3-ip-pools--pool-id--delegate" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subaccount_id: string # The ID of the subaccount to revoke the pool from
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/ip_pools/($pool_id)/delegate")
  let body = {subaccount_id: $subaccount_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Update subaccount IP assignments
#
# PATCH /v3/ips/subaccounts
# operationId: PATCH-v3-ips-subaccounts
export def "ips-subaccounts PATCH-v3-ips-subaccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/ips/subaccounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of in-flight IP address warmup statuses.
#
# GET /v3/ip_warmups
# operationId: GET-v3-ip-warmups
export def "ip-warmups GET-v3-ip-warmups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # The page to retrieve. If not specified, the first page is returned.
  --limit: string # The number of results to return per page. Defaults to 10 if not specified.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/ip_warmups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the status of an in-flight IP warmup
#
# GET /v3/ip_warmups/{addr}
# operationId: GET-v3-ip-warmups--addr-
export def "ip-warmups GET-v3-ip-warmups--addr-" [
  addr: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/ip_warmups/($addr)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a warmup plan for an IP Address
#
# POST /v3/ip_warmups/{addr}
# operationId: POST-v3-ip-warmups--addr-
export def "ip-warmups POST-v3-ip-warmups--addr-" [
  addr: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/ip_warmups/($addr)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancels the warmup plan for an IP address
#
# DELETE /v3/ip_warmups/{addr}
# operationId: DELETE-v3-ip-warmups--addr-
export def "ip-warmups DELETE-v3-ip-warmups--addr-" [
  addr: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/ip_warmups/($addr)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all domains assigned to dynamic IP pools
#
# GET /v1/dynamic_pools/domains
# operationId: GET-v1-dynamic-pools-domains
export def "dynamic-pools-domains GET-v1-dynamic-pools-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of domains to return
  --account: string # Filter domains by account ID. Can be specified multiple times.
  --pool: string # Filter domains to a specific Dynamic IP Pool. Can be specified multiple times.
  --sort-by: string@sort-by-completer # Specify which field to use to sort domains (default: name)
  --sort-order: string@sort-order-completer # Specify which field to use to sort domains (default: ascending)
]: nothing -> record<items: table<id: string, account_id: string, account_name: string, name: string, registered_at: string, pool: string, override: bool, bounce_rate: float, complaint_rate: float, processed_count: int>, total_items: int, paging: record<Next: string, Previous: string, First: string, Last: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "account" $account "scalar") (serialize-qp "pool" $pool "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/dynamic_pools/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Preview domain assignment
#
# GET /v1/dynamic_pools/domains/{name}/preview
# operationId: GET-v1-dynamic-pools-domains--name--preview
export def "dynamic-pools-domains-preview GET-v1-dynamic-pools-domains--name--preview" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dynamic_pools/domains/($name)/preview")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List domain history
#
# GET /v1/dynamic_pools/domains/{name}/history
# operationId: GET-v1-dynamic-pools-domains--name--history
export def "dynamic-pools-domains-history GET-v1-dynamic-pools-domains--name--history" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, owning_account_id: string, account_id: string, account_name: string, domain_id: string, domain_name: string, new_band: string, prev_band: string, reason: string, bounce_rate: float, complaint_rate: float, processed_count: int, initiated_by: string, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dynamic_pools/domains/($name)/history")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Override domain assignment
#
# PUT /v1/dynamic_pools/domains/{name}/override
# operationId: PUT-v1-dynamic-pools-domains--name--override
export def "dynamic-pools-domains-override PUT-v1-dynamic-pools-domains--name--override" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  pool: string # The name of the Dynamic IP pool to override the domain with. Must be a valid pool name (ex: dynamic_good, dynamic_new, etc.)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dynamic_pools/domains/($name)/override")
  let body = {pool: $pool} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Remove override
#
# DELETE /v1/dynamic_pools/domains/{name}/override
# operationId: DELETE-v1-dynamic-pools-domains--name--override
export def "dynamic-pools-domains-override DELETE-v1-dynamic-pools-domains--name--override" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dynamic_pools/domains/($name)/override")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List account history
#
# GET /v1/dynamic_pools/history
# operationId: GET-v1-dynamic-pools-history
export def "dynamic-pools-history GET-v1-dynamic-pools-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Limit: int # The maximum number of events to return
  --include-subaccounts: string@bool-completer # If true, includes events from all subaccounts in addition to events from the parent account
  --domain: string # Filter events by domain name
  --before: string # Filter events emitted before a given timestamp (Format: Mon, 02 Jan 2006 15:04:05 MST)
  --after: string # Filter events emitted after a given timestamp (Format: Mon, 02 Jan 2006 15:04:05 MST)
  --moved-to: string # Filter events by which Dynamic Pool a domain was moved to (ex. dynamic_good, dynamic_poor, etc.)
  --moved-from: string # Filter events by which Dynamic Pool a domain was moved from (ex. dynamic_good, dynamic_poor, etc.)
]: nothing -> record<items: table<id: string, owning_account_id: string, account_id: string, account_name: string, domain_id: string, domain_name: string, new_band: string, prev_band: string, reason: string, bounce_rate: float, complaint_rate: float, processed_count: int, initiated_by: string, timestamp: string>, total_items: int, paging: record<Next: string, Previous: string, First: string, Last: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $Limit "scalar") (serialize-qp "include_subaccounts" $include_subaccounts "scalar") (serialize-qp "domain" $domain "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "moved_to" $moved_to "scalar") (serialize-qp "moved_from" $moved_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/dynamic_pools/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete scheduled and undelivered mail
#
# DELETE /v3/{domain_name}/envelopes
# operationId: DELETE-v3--domain-name--envelopes
export def "envelopes DELETE-v3--domain-name--envelopes" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/envelopes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tracking Certificate: Get certificate and status
#
# GET /v2/x509/{domain}/status
# operationId: GET-v2-x509--domain--status
export def "x509-status GET-v2-x509--domain--status" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: record, error: string, certificate: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/x509/($domain)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tracking Certificate: Regenerate expired certificate
#
# PUT /v2/x509/{domain}
# operationId: PUT-v2-x509--domain-
export def "x509 PUT-v2-x509--domain-" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, location: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/x509/($domain)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tracking Certificate: Generate
#
# POST /v2/x509/{domain}
# operationId: POST-v2-x509--domain-
export def "x509 POST-v2-x509--domain-" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, location: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/x509/($domain)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a paginated list of events
#
# GET /v3/{domain_name}/events
# operationId: get-v3-domain_name-events
export def "events name-events" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --begin: string # The beginning of the search time range in epoch seconds
  --end: string # The end of the search time range in epoch seconds
  --ascending: string@ascending-completer # Sort direction by time. Must be provided if the range end time is not specified. Can be either yes or no
  --limit: int # The number of entries to return (300 max)
  --event: string # Filter by event type
  --list: string # Filter by mailing list email address that message was originally sent to
  --attachment: string # Filter by the name of an attached file
  --qp-from: string # Filter by email address mentioned in the From MIME header
  --message-id: string # Filter by Mailgun message id returned by the messages API
  --subject: string # Filter by subject line
  --qp-to: string # Filter by email address mentioned in the To MIME header
  --size: string # Filter by message size. Mostly intended to be used with range filtering expressions
  --recipient: string # Filter by email address of a recipient. While messages are addressable to one or more recipients, each event (with one exception) tracks one recipient. See stored events for use of recipients
  --recipients: string # Specific to stored events, this field tracks all of the potential message recipients.
  --tags: string # Filter by user defined tags
  --severity: string # Filter by event severity, if exists. Currently for failed events only. See [Tracking Failures](https://documentation.mailgun.com/docs/mailgun/user-manual/tracking-messages/#tracking-failures)
]: nothing -> record<items: table<method: string, id: string, event: string, timestamp: float, log_level: string, flags: record, reject: record, message: record, tags: list, user_variables: record, storage: record, geolocation: record, client_info: record, ip: string, delivery_status: record, batch: record, severity: string, recipient_domain: string, recipient_provider: string, template: record, envelope: record>, paging: record<next: string, previous: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "begin" $begin "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "ascending" $ascending "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "event" $event "scalar") (serialize-qp "list" $list "scalar") (serialize-qp "attachment" $attachment "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "message-id" $message_id "scalar") (serialize-qp "subject" $subject "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recipient" $recipient "scalar") (serialize-qp "recipients" $recipients "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "severity" $severity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($domain_name)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all tags
#
# GET /v3/{domain}/tags
# DEPRECATED
# operationId: GET-v3--domain--tags
@deprecated
export def "tags GET-v3--domain--tags" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # The page direction based on the tag parameter; valid choices are (first, last, next, prev)
  --limit: int # Limits the number of items returned in a request
  --tag: string # The tag that marks the end of the current page and the start of the next
  --prefix: string # List only tags that begin with this prefix
]: nothing -> record<items: table<tag: string, description: string, first_seen: string, last_seen: string>, paging: record<previous: string, first: string, next: string, last: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "prefix" $prefix "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($domain)/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a tag
#
# GET /v3/{domain}/tag
# DEPRECATED
# operationId: GET-v3--domain--tag
@deprecated
export def "tag GET-v3--domain--tag" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # The name of the tag
]: nothing -> record<tag: string, description: string, first_seen: string, last_seen: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($domain)/tag" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update tag 
#
# PUT /v3/{domain}/tag
# DEPRECATED
# operationId: PUT-v3--domain--tag
@deprecated
export def "tag PUT-v3--domain--tag" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # The name of the tag
  --description: string # The description of the tag
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "description" $description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($domain)/tag" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete tag
#
# DELETE /v3/{domain}/tag
# DEPRECATED
# operationId: DELETE-v3--domain--tag
@deprecated
export def "tag DELETE-v3--domain--tag" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # The name of the tag
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($domain)/tag" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get aggregate stat types by tag
#
# GET /v3/{domain}/tag/stats/aggregates
# DEPRECATED
# operationId: GET-v3--domain--tag-stats-aggregates
@deprecated
export def "tag-stats-aggregates GET-v3--domain--tag-stats-aggregates" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # The name of the tag
  --type: string # The type of aggregate (country, device, provider)
]: nothing -> record<tag: string, provider: record, country: record, device: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($domain)/tag/stats/aggregates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get stats by tag
#
# GET /v3/{domain}/tag/stats
# DEPRECATED
# operationId: GET-v3--domain--tag-stats
@deprecated
export def "tag-stats GET-v3--domain--tag-stats" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # The start date in RFC 2822 format or unix epoch (default: 7 days ago)
  --end: string # The end date in RFC 2822 format or unix epoch (default: current time) 
  --resolution: string # The gregorian resolution the query is for 'day, month, hour` (default: day)
  --duration: string # If duration is provided than it's calculated from the 'end' date and overwrites the 'start' date
  --provider: string # The provider value; see `GET /v3/domains/1/tag/providers` for possible values
  --device: string # The device value; see `GET /v3/domains/1/tag/devices` for possible values
  --country: string # The country value; see `GET /v3/domains/1/tag/providers` for possible values
  --event: string # Name of the event(s) to receive the stats for (Multiple events are allowed). Supported events are: accepted, delivered, failed, opened, clicked, unsubscribed, complained, stored
  --tag: string # The name of the tag
]: nothing -> record<tag: string, description: string, start: string, end: string, type: record<type: string, key: string>, resolution: string, stats: table<time: string, accepted: record, delivered: record, failed: record, stored: record, opened: record, clicked: record, unsubscribed: record, complained: record, campaign: record, email_validation: record, seed_test: record, ip_blocklist_monitoring: record, domain_blocklist_monitoring: record, email_preview: record, email_preview_failed: record, link_validation: record, link_validation_failed: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "event" $event "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($domain)/tag/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of supported devices
#
# GET /v3/domains/{domain}/tag/devices
# DEPRECATED
# operationId: GET-v3-domains--domain--tag-devices
@deprecated
export def "domains-tag-devices GET-v3-domains--domain--tag-devices" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($domain)/tag/devices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of supported providers
#
# GET /v3/domains/{domain}/tag/providers
# DEPRECATED
# operationId: GET-v3-domains--domain--tag-providers
@deprecated
export def "domains-tag-providers GET-v3-domains--domain--tag-providers" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($domain)/tag/providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of supported country codes
#
# GET /v3/domains/{domain}/tag/countries
# DEPRECATED
# operationId: GET-v3-domains--domain--tag-countries
@deprecated
export def "domains-tag-countries GET-v3-domains--domain--tag-countries" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($domain)/tag/countries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Totals for entire account
#
# GET /v3/stats/total
# DEPRECATED
# operationId: GET-v3-stats-total
@deprecated
export def "stats-total GET-v3-stats-total" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # The start date in RFC 2822 format or unix epoch (default: 7 days ago)
  --end: string # The end date in RFC 2822 format or unix epoch (default: current time) 
  --resolution: string # The gregorian resolution the query is for 'day, month, hour` (default: day)
  --duration: string # If duration is provided than it's calculated from the 'end' date and overwrites the 'start' date
  --event: string # Name of the event(s) to receive the stats for (Multiple events are allowed). Supported events are: accepted, delivered, failed, opened, clicked, unsubscribed, complained, stored
]: nothing -> record<tag: string, description: string, start: string, end: string, type: record<type: string, key: string>, resolution: string, stats: table<time: string, accepted: record, delivered: record, failed: record, stored: record, opened: record, clicked: record, unsubscribed: record, complained: record, campaign: record, email_validation: record, seed_test: record, ip_blocklist_monitoring: record, domain_blocklist_monitoring: record, email_preview: record, email_preview_failed: record, link_validation: record, link_validation_failed: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "event" $event "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/stats/total" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Totals for entire domain
#
# GET /v3/{domain}/stats/total
# DEPRECATED
# operationId: GET-v3--domain--stats-total
@deprecated
export def "stats-total GET-v3--domain--stats-total" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # The start date in RFC 2822 format or unix epoch (default: 7 days ago)
  --end: string # The end date in RFC 2822 format or unix epoch (default: current time) 
  --resolution: string # The gregorian resolution the query is for 'day, month, hour` (default: day)
  --duration: string # If duration is provided than it's calculated from the 'end' date and overwrites the 'start' date
  --event: string # Name of the event(s) to receive the stats for (Multiple events are allowed). Supported events are: accepted, delivered, failed, opened, clicked, unsubscribed, complained, stored
]: nothing -> record<tag: string, description: string, start: string, end: string, type: record<type: string, key: string>, resolution: string, stats: table<time: string, accepted: record, delivered: record, failed: record, stored: record, opened: record, clicked: record, unsubscribed: record, complained: record, campaign: record, email_validation: record, seed_test: record, ip_blocklist_monitoring: record, domain_blocklist_monitoring: record, email_preview: record, email_preview_failed: record, link_validation: record, link_validation_failed: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "event" $event "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($domain)/stats/total" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Totals for account domains for a single time resolution
#
# GET /v3/stats/total/domains
# DEPRECATED
# operationId: GET-v3-stats-total-domains
@deprecated
export def "stats-total-domains GET-v3-stats-total-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --event: string # Name of the event(s) to receive the stats for (Multiple events are allowed). Supported events are: accepted, delivered, failed, opened, clicked, unsubscribed, complained, stored
  --limit: string # Skip x number of domains; used to page through large numbers of domains
  --resolution: string # The gregorian resolution the query is for 'day, month, hour` (default: day)
  --timestamp: string # The date/time of the 'resolution' we are retrieving
]: nothing -> record<tag: string, description: string, start: string, end: string, type: record<type: string, key: string>, resolution: string, stats: table<time: string, accepted: record, delivered: record, failed: record, stored: record, opened: record, clicked: record, unsubscribed: record, complained: record, campaign: record, email_validation: record, seed_test: record, ip_blocklist_monitoring: record, domain_blocklist_monitoring: record, email_preview: record, email_preview_failed: record, link_validation: record, link_validation_failed: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event" $event "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/stats/total/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Filtered/grouped totals for entire account
#
# GET /v3/stats/filter
# DEPRECATED
# operationId: GET-v3-stats-filter
@deprecated
export def "stats-filter GET-v3-stats-filter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # The start date in RFC 2822 format or unix epoch (default: 7 days ago)
  --end: string # The end date in RFC 2822 format or unix epoch (default: current time) 
  --resolution: string # The gregorian resolution the query is for 'day, month, hour` (default: day)
  --duration: string # If duration is provided than it's calculated from the 'end' date and overwrites the 'start' date
  --event: string # Name of the event(s) to receive the stats for (Multiple events are allowed). Supported events are: accepted, delivered, failed, opened, clicked, unsubscribed, complained, stored
  --filter: string # A filter for account level metrics such as filter=domain:my.example.com
  --group: string # The key to group metrics by.  Must be one of total, time, day, month, domain, ip, provider, tag, country
]: nothing -> record<tag: string, description: string, start: string, end: string, type: record<type: string, key: string>, resolution: string, stats: table<time: string, accepted: record, delivered: record, failed: record, stored: record, opened: record, clicked: record, unsubscribed: record, complained: record, campaign: record, email_validation: record, seed_test: record, ip_blocklist_monitoring: record, domain_blocklist_monitoring: record, email_preview: record, email_preview_failed: record, link_validation: record, link_validation_failed: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "event" $event "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "group" $group "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/stats/filter" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get tag limits
#
# GET /v3/domains/{domain}/limits/tag
# DEPRECATED
# operationId: GET-v3-domains--domain--limits-tag
@deprecated
export def "domains-limits-tag GET-v3-domains--domain--limits-tag" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, limit: int, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($domain)/limits/tag")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Aggregate counts by ESP
#
# GET /v3/{domain}/aggregates/providers
# DEPRECATED
# operationId: GET-v3--domain--aggregates-providers
@deprecated
export def "aggregates-providers GET-v3--domain--aggregates-providers" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<providers: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain)/aggregates/providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Aggregate counts by devices triggering events 
#
# GET /v3/{domain}/aggregates/devices
# DEPRECATED
# operationId: GET-v3--domain--aggregates-devices
@deprecated
export def "aggregates-devices GET-v3--domain--aggregates-devices" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<devices: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain)/aggregates/devices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Aggregate counts by country
#
# GET /v3/{domain}/aggregates/countries
# DEPRECATED
# operationId: GET-v3--domain--aggregates-countries
@deprecated
export def "aggregates-countries GET-v3--domain--aggregates-countries" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<countries: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain)/aggregates/countries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query account metrics
#
# POST /v1/analytics/metrics
# operationId: POST-v1-analytics-metrics
# --filter shape: {AND: list}
export def "analytics-metrics POST-v1-analytics-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # A start date (default: 7 days before current time). Must be in RFC 2822 format: https://datatracker.ietf.org/doc/html/rfc2822.html#page-14
  --end: string # An end date (default: current time). Must be in RFC 2822 format: https://datatracker.ietf.org/doc/html/rfc2822.html#page-14
  --resolution: string # A resolution in the format of 'day' 'hour' 'month'. Default is day.
  --duration: string # A duration in the format of '1d' '2h' '2m'. If duration is provided then it is calculated from the end date and overwrites the start date.
  --dimensions: list # Attributes of the metric data such as 'subaccount'.  See [dimensions](https://documentation.mailgun.com/docs/mailgun/user-manual/reporting/dimensions)
  --metrics: list # Name of the metrics to receive the stats for such as 'processed_count'. See [metrics](https://documentation.mailgun.com/docs/mailgun/user-manual/reporting/metric-definitions)
  --filter: record # Filters to apply to the query. — shape: {AND: list}
  --include-subaccounts: string@bool-completer # Include stats from all subaccounts.
  --include-aggregates: string@bool-completer # Include top-level aggregate metrics.
]: any -> record<start: string, end: string, resolution: string, duration: string, dimensions: list<string>, pagination: record<sort: string, skip: int, limit: int, total: int>, items: table<dimensions: list, metrics: record>, aggregates: record<metrics: record<accepted_incoming_count: int, accepted_outgoing_count: int, accepted_count: int, delivered_smtp_count: int, delivered_http_count: int, delivered_optimized_count: int, delivered_count: int, stored_count: int, processed_count: int, sent_count: int, opened_count: int, clicked_count: int, unique_opened_count: int, unique_clicked_count: int, unsubscribed_count: int, complained_count: int, failed_count: int, temporary_failed_count: int, permanent_failed_count: int, temporary_failed_esp_block_count: int, permanent_failed_esp_block_count: int, rate_limit_count: int, webhook_count: int, permanent_failed_optimized_count: int, permanent_failed_old_count: int, bounced_count: int, hard_bounces_count: int, soft_bounces_count: int, delayed_bounce_count: int, suppressed_bounces_count: int, suppressed_unsubscribed_count: int, suppressed_complaints_count: int, delivered_first_attempt_count: int, delayed_first_attempt_count: int, delivered_subsequent_count: int, delivered_two_plus_attempts_count: int, delivered_rate: string, opened_rate: string, clicked_rate: string, unique_opened_rate: string, unique_clicked_rate: string, unsubscribed_rate: string, complained_rate: string, bounce_rate: string, fail_rate: string, permanent_fail_rate: string, temporary_fail_rate: string, delayed_rate: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/analytics/metrics")
  let body = {start: $start, end: $end, resolution: $resolution, duration: $duration, dimensions: $dimensions, metrics: $metrics, filter: $filter, include_subaccounts: $include_subaccounts, include_aggregates: $include_aggregates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Query account usage metrics
#
# POST /v1/analytics/usage/metrics
# operationId: POST-v1-analytics-usage-metrics
# --filter shape: {AND: list}
export def "analytics-usage-metrics POST-v1-analytics-usage-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # A start date (default: 7 days before current time). Must be in RFC 2822 format: https://datatracker.ietf.org/doc/html/rfc2822.html#page-14
  --end: string # An end date (default: current time). Must be in RFC 2822 format: https://datatracker.ietf.org/doc/html/rfc2822.html#page-14
  --resolution: string # A resolution in the format of 'day' 'hour' 'month'. Default is day.
  --duration: string # A duration in the format of '1d' '2h' '2m'. If duration is provided then it is calculated from the end date and overwrites the start date.
  --dimensions: list # Attributes of the metric data such as 'subaccount'.  See [dimensions](https://documentation.mailgun.com/docs/mailgun/user-manual/reporting/dimensions)
  --metrics: list # Name of the metrics to receive the stats for such as 'processed_count'.
  --filter: record # Filters to apply to the query. — shape: {AND: list}
  --include-subaccounts: string@bool-completer # Include stats from all subaccounts.
  --include-aggregates: string@bool-completer # Include top-level aggregate metrics.
]: any -> record<start: string, end: string, resolution: string, duration: string, dimensions: list<string>, pagination: record<sort: string, skip: int, limit: int, total: int>, items: table<dimensions: list, metrics: record>, aggregates: record<metrics: record<processed_count: int, email_validation_count: int, email_validation_public_count: int, email_validation_valid_count: int, email_validation_single_count: int, email_validation_bulk_count: int, email_validation_list_count: int, email_validation_mailgun_count: int, email_validation_mailjet_count: int, email_preview_count: int, email_preview_failed_count: int, link_validation_count: int, link_validation_failed_count: int, seed_test_count: int, ip_blocklist_monitoring_count: int, domain_blocklist_monitoring_count: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/analytics/usage/metrics")
  let body = {start: $start, end: $end, resolution: $resolution, duration: $duration, dimensions: $dimensions, metrics: $metrics, filter: $filter, include_subaccounts: $include_subaccounts, include_aggregates: $include_aggregates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List logs
#
# POST /v1/analytics/logs
# operationId: POST-v1-analytics-logs
# --filter shape: {AND: list}
# --pagination shape: {sort?: string, token?: string, limit?: int}
export def "analytics-logs POST-v1-analytics-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # The start date (default: 1 day before current time). Must be in RFC 2822 format: https://datatracker.ietf.org/doc/html/rfc2822.html#page-14
  --end: string # The end date (default: current time). Must be in RFC 2822 format: https://datatracker.ietf.org/doc/html/rfc2822.html#page-14
  duration: string # A duration in the format of '1d' '2h'. If duration is provided then it is calculated from the end date and overwrites the start date.
  --events: list # The set of events to include.
  --metric-events: list # Optional set of analytics metric events. Will be converted into corresponding events.
  --filter: record # Filters to apply to the query. — shape: {AND: list}
  --include-subaccounts: string@bool-completer # Include logs from all subaccounts.
  --include-totals: string@bool-completer # Include total number of log entries.
  --pagination: record # shape: {sort?: string, token?: string, limit?: int}
]: any -> record<start: string, end: string, items: table<id: string, event: string, _timestamp: string, account: any, campaigns: list, tags: list, method: string, originating_ip: string, api_key_id: string, delivered_at: string, delivery_status: any, i_delivery_optimizer: string, domain: any, recipient: string, recipient_domain: string, recipient_provider: string, envelope: any, storage: any, template: any, log_level: string, user_variables: string, message: any, flags: any, primary_dkim: string, ip: string, geolocation: any, client_info: any, severity: string, reason: string, routes: any, mailing_list: any, url: string>, pagination: record<previous: string, next: string, first: string, last: string, total: int>, aggregates: record<all: int, metrics: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/analytics/logs")
  let body = {start: $start, end: $end, duration: $duration, events: $events, metric_events: $metric_events, filter: $filter, include_subaccounts: $include_subaccounts, include_totals: $include_totals, pagination: $pagination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update account tag
#
# PUT /v1/analytics/tags
# operationId: PUT-v1-analytics-tags
export def "analytics-tags PUT-v1-analytics-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # The tag to update.
  --description: string # The updated tag description.
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/analytics/tags")
  let body = {tag: $tag, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Post query to list account tags or search for single tag
#
# POST /v1/analytics/tags
# operationId: POST-v1-analytics-tags
# --pagination shape: {sort?: string, skip?: int, limit?: int, total?: int, include_total?: bool}
export def "analytics-tags POST-v1-analytics-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pagination: record # shape: {sort?: string, skip?: int, limit?: int, total?: int, include_total?: bool}
  --include-subaccounts: string@bool-completer # Boolean indicating whether or not to include data from all subaccounts. Default false.
  --include-metrics: string@bool-completer # Boolean indicating whether or not to include metrics for tags. Default false.  When true max limit is 20.
  --tag: string # The tag or tag prefix.
]: any -> record<items: table<account_id: string, parent_account_id: string, tag: string, description: string, first_seen: record, last_seen: record, metrics: record, account_name: string>, pagination: record<sort: string, skip: int, limit: int, total: int, include_total: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/analytics/tags")
  let body = {pagination: $pagination, include_subaccounts: $include_subaccounts, include_metrics: $include_metrics, tag: $tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete account tag
#
# DELETE /v1/analytics/tags
# operationId: DELETE-v1-analytics-tags
export def "analytics-tags DELETE-v1-analytics-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # The tag to delete.
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/analytics/tags")
  let body = {tag: $tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get account tag limit information
#
# GET /v1/analytics/tags/limits
# operationId: GET-v1-analytics-tags-limits
export def "analytics-tags-limits GET-v1-analytics-tags-limits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<limit: int, count: int, limit_reached: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/analytics/tags/limits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List send alerts
#
# GET /v1/thresholds/alerts/send
# operationId: GET-v1-thresholds-alerts-send
export def "thresholds-alerts-send GET-v1-thresholds-alerts-send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<id: string, parent_account_id: string, subaccount_id: string, account_group: string, name: string, created_at: string, updated_at: string, last_checked: string, description: string, alert_channels: list, filters: list, metric: string, comparator: string, limit: string, dimension: string, period: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/thresholds/alerts/send")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a send alert for an account
#
# POST /v1/thresholds/alerts/send
# operationId: POST-v1-thresholds-alerts-send
# --filters item shape: {dimension: string, comparator: string, values: list}
export def "thresholds-alerts-send POST-v1-thresholds-alerts-send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # A user-friendly name for the alert.
  metric: string # The metric being monitored.
  comparator: string # The comparison operator.
  limit: string # The threshold limit for the alert.
  dimension: string # The dimension to apply to the metric.
  --alert-channels: list # A list of alert channels to notify.
  --filters: list # A list of filters to apply to the alert. — item shape: {dimension: string, comparator: string, values: list}
  --period: string # The time period for the metric aggregation in the format of '1h' '1d'.
  --description: string # A description of what the alert does.
]: any -> record<id: string, parent_account_id: string, subaccount_id: string, account_group: string, name: string, created_at: string, updated_at: string, last_checked: string, description: string, alert_channels: list<string>, filters: table<dimension: string, comparator: string, values: list>, metric: string, comparator: string, limit: string, dimension: string, period: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/thresholds/alerts/send")
  let body = {name: $name, metric: $metric, comparator: $comparator, limit: $limit, dimension: $dimension, alert_channels: $alert_channels, filters: $filters, period: $period, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a send alert
#
# GET /v1/thresholds/alerts/send/{name}
# operationId: GET-v1-thresholds-alerts-send--name-
export def "thresholds-alerts-send GET-v1-thresholds-alerts-send--name-" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, parent_account_id: string, subaccount_id: string, account_group: string, name: string, created_at: string, updated_at: string, last_checked: string, description: string, alert_channels: list<string>, filters: table<dimension: string, comparator: string, values: list>, metric: string, comparator: string, limit: string, dimension: string, period: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/thresholds/alerts/send/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a send alert
#
# PUT /v1/thresholds/alerts/send/{name}
# operationId: PUT-v1-thresholds-alerts-send--name-
# --filters item shape: {dimension: string, comparator: string, values: list}
export def "thresholds-alerts-send PUT-v1-thresholds-alerts-send--name-" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-name: string # A user-friendly name for the alert.
  metric: string # The metric being monitored.
  comparator: string # The comparison operator.
  limit: string # The threshold limit for the alert.
  dimension: string # The dimension to apply to the metric.
  --alert-channels: list # A list of alert channels to notify.
  --filters: list # A list of filters to apply to the alert. — item shape: {dimension: string, comparator: string, values: list}
  --period: string # The time period for the metric aggregation in the format of '1h' '1d'.
  --description: string # A description of what the alert does.
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/thresholds/alerts/send/($name)")
  let body = {name: $body_name, metric: $metric, comparator: $comparator, limit: $limit, dimension: $dimension, alert_channels: $alert_channels, filters: $filters, period: $period, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a send alert
#
# DELETE /v1/thresholds/alerts/send/{name}
# operationId: DELETE-v1-thresholds-alerts-send--name-
export def "thresholds-alerts-send DELETE-v1-thresholds-alerts-send--name-" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/thresholds/alerts/send/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List limit thresholds for an account
#
# GET /v1/thresholds/limits
# operationId: GET-v1-thresholds-limits
export def "thresholds-limits GET-v1-thresholds-limits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<id: string, parent_account_id: string, subaccount_id: string, account_group: string, name: string, created_at: string, updated_at: string, last_checked: string, description: string, filters: list, metric: string, comparator: string, limit: string, dimension: string, period: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/thresholds/limits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a limit threshold for an account
#
# POST /v1/thresholds/limits
# operationId: POST-v1-thresholds-limits
# --filters item shape: {dimension: string, comparator: string, values: list}
export def "thresholds-limits POST-v1-thresholds-limits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # A user-friendly name for the limit.
  metric: string # The metric being monitored.
  comparator: string # The comparison operator.
  limit: string # The threshold limit.
  dimension: string # The dimension to apply to the metric.
  --filters: list # A list of filters to apply to the limit. — item shape: {dimension: string, comparator: string, values: list}
  --period: string # The time period for the metric aggregation in the format of '1h' '1d'.
  --description: string # A description of what the limit does.
]: any -> record<id: string, parent_account_id: string, subaccount_id: string, account_group: string, name: string, created_at: string, updated_at: string, last_checked: string, description: string, filters: table<dimension: string, comparator: string, values: list>, metric: string, comparator: string, limit: string, dimension: string, period: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/thresholds/limits")
  let body = {name: $name, metric: $metric, comparator: $comparator, limit: $limit, dimension: $dimension, filters: $filters, period: $period, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a limit threshold for an account
#
# GET /v1/thresholds/limits/{name}
# operationId: GET-v1-thresholds-limits--name-
export def "thresholds-limits GET-v1-thresholds-limits--name-" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, parent_account_id: string, subaccount_id: string, account_group: string, name: string, created_at: string, updated_at: string, last_checked: string, description: string, filters: table<dimension: string, comparator: string, values: list>, metric: string, comparator: string, limit: string, dimension: string, period: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/thresholds/limits/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a limit threshold for an account
#
# PUT /v1/thresholds/limits/{name}
# operationId: PUT-v1-thresholds-limits--name-
# --filters item shape: {dimension: string, comparator: string, values: list}
export def "thresholds-limits PUT-v1-thresholds-limits--name-" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-name: string # A user-friendly name for the limit.
  metric: string # The metric being monitored.
  comparator: string # The comparison operator.
  limit: string # The threshold limit.
  dimension: string # The dimension to apply to the metric.
  --filters: list # A list of filters to apply to the limit. — item shape: {dimension: string, comparator: string, values: list}
  --period: string # The time period for the metric aggregation in the format of '1h' '1d'.
  --description: string # A description of what the limit does.
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/thresholds/limits/($name)")
  let body = {name: $body_name, metric: $metric, comparator: $comparator, limit: $limit, dimension: $dimension, filters: $filters, period: $period, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a limit threshold for an account
#
# DELETE /v1/thresholds/limits/{name}
# operationId: DELETE-v1-thresholds-limits--name-
export def "thresholds-limits DELETE-v1-thresholds-limits--name-" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/thresholds/limits/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List account hits
#
# GET /v1/thresholds/hits
# operationId: GET-v1-thresholds-hits
export def "thresholds-hits GET-v1-thresholds-hits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<id: string, name: string, created_at: string, updated_at: string, triggered: bool, expires_at: string, latest_value: string, metric: string, comparator: string, limit: string, parent_account_id: string, subaccount_id: string, dimension: string, dimension_value: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/thresholds/hits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List events
#
# GET /v1/alerts/events
# operationId: GET-v1-alerts-events
export def "alerts-events GET-v1-alerts-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<events: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/alerts/events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Alert
#
# POST /v1/alerts/settings/events
# operationId: POST-v1-alerts-settings-events
# --settings shape: {url?: string, emails?: list, channel_ids?: list, disabled_channel_ids?: record}
export def "alerts-settings-events POST-v1-alerts-settings-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  event_type: string # The type of event for which you would like to receive alerts.
  channel: string # The delivery method for the alert.
  settings: record # The details pertaining to the specified channel. Please note that the contents of this object differ per channel type. — shape: {url?: string, emails?: list, channel_ids?: list, disabled_channel_ids?: record}
]: any -> record<id: string, event_type: string, channel: string, settings: record, disabled_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/alerts/settings/events")
  let body = {event_type: $event_type, channel: $channel, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Alert
#
# PUT /v1/alerts/settings/events/{id}
# operationId: PUT-v1-alerts-settings-events--id-
# --settings shape: {url?: string, emails?: list, channel_ids?: list, disabled_channel_ids?: record}
export def "alerts-settings-events PUT-v1-alerts-settings-events--id-" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  event_type: string # The type of event for which you would like to receive alerts.
  channel: string # The delivery method for the alert.
  settings: record # The details pertaining to the specified channel. Please note that the contents of this object differ per channel type. — shape: {url?: string, emails?: list, channel_ids?: list, disabled_channel_ids?: record}
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/alerts/settings/events/($id)")
  let body = {event_type: $event_type, channel: $channel, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Alert
#
# DELETE /v1/alerts/settings/events/{id}
# operationId: DELETE-v1-alerts-settings-events--id-
export def "alerts-settings-events DELETE-v1-alerts-settings-events--id-" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/alerts/settings/events/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Alerts
#
# GET /v1/alerts/settings
# operationId: GET-v1-alerts-settings
export def "alerts-settings GET-v1-alerts-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<events: table<id: string, event_type: string, channel: string, settings: record, disabled_at: string>, webhooks: record<signing_key: string>, slack: record<token: string, team_id: string, team_name: string, scope: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/alerts/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Slack settings
#
# PUT /v1/alerts/settings/slack
# operationId: PUT-v1-alerts-settings-slack
export def "alerts-settings-slack PUT-v1-alerts-settings-slack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string
  --team-id: string # nullable
  --team-name: string # nullable
  --scope: string # nullable
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/alerts/settings/slack")
  let body = {token: $body_token, team_id: $team_id, team_name: $team_name, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Slack settings
#
# DELETE /v1/alerts/settings/slack
# operationId: DELETE-v1-alerts-settings-slack
export def "alerts-settings-slack DELETE-v1-alerts-settings-slack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/alerts/settings/slack")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset Webhook Signing Key
#
# PUT /v1/alerts/settings/webhooks/signing_key
# operationId: PUT-v1-alerts-settings-webhooks-signing-key
export def "alerts-settings-webhooks-signing-key PUT-v1-alerts-settings-webhooks-signing-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<signing_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/alerts/settings/webhooks/signing_key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test webhook
#
# POST /v1/alerts/webhooks/test
# operationId: POST-v1-alerts-webhooks-test
export def "alerts-webhooks-test POST-v1-alerts-webhooks-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  event_type: string
  --body-url: string
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/alerts/webhooks/test")
  let body = {event_type: $event_type, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test message
#
# POST /v1/alerts/email/test
# operationId: POST-v1-alerts-email-test
export def "alerts-email-test POST-v1-alerts-email-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  event_type: string
  emails: list
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/alerts/email/test")
  let body = {event_type: $event_type, emails: $emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test message
#
# POST /v1/alerts/slack/test
# operationId: POST-v1-alerts-slack-test
export def "alerts-slack-test POST-v1-alerts-slack-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  event_type: string
  --channel-ids: list # If omitted would be taken from the event settings
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/alerts/slack/test")
  let body = {event_type: $event_type, channel_ids: $channel_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke Slack access token
#
# DELETE /v1/alerts/slack/oauth
# operationId: DELETE-v1-alerts-slack-oauth
export def "alerts-slack-oauth DELETE-v1-alerts-slack-oauth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/alerts/slack/oauth")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Slack channel
#
# GET /v1/alerts/slack/channels/{id}
# operationId: GET-v1-alerts-slack-channels--id-
export def "alerts-slack-channels GET-v1-alerts-slack-channels--id-" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, is_archived: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/alerts/slack/channels/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Slack channels
#
# GET /v1/alerts/slack/channels
# operationId: GET-v1-alerts-slack-channels
export def "alerts-slack-channels GET-v1-alerts-slack-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Encoded paging information, provided via 'next', 'first' links
  --limit: int # Limits the number of items returned in a request
]: nothing -> record<items: table<id: string, name: string, is_archived: bool>, paging: record<previous: string, first: string, next: string, last: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/alerts/slack/channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import unsubscribe list
#
# POST /v3/{domain_name}/unsubscribes/import
# operationId: POST-v3--domainID--unsubscribes-import
export def "unsubscribes-import POST-v3--domainID--unsubscribes-import" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Content-Type must be `multipart/form-data`
  file: string # CSV file
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/unsubscribes/import")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Import list of bounces
#
# POST /v3/{domain_name}/bounces/import
# operationId: POST-v3--domainID--bounces-import
export def "bounces-import POST-v3--domainID--bounces-import" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Content-Type must be `multipart/form-data`
  file: string # CSV file
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/bounces/import")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Import complaint list
#
# POST /v3/{domain_name}/complaints/import
# operationId: POST-v3--domainID--complaints-import
export def "complaints-import POST-v3--domainID--complaints-import" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Content-Type must be `multipart/form-data`
  file: string # CSV file
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/complaints/import")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Import allowlist
#
# POST /v3/{domain_name}/whitelists/import
# operationId: POST-v3--domainID--whitelists-import
export def "whitelists-import POST-v3--domainID--whitelists-import" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Content-Type must be `multipart/form-data`
  file: string # CSV file
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/whitelists/import")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Lookup bounce record
#
# GET /v3/{domain_name}/bounces/{address}
# operationId: GET-v3--domainID--bounces--address-
export def "bounces GET-v3--domainID--bounces--address-" [
  domain_name: string
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, code: string, error: string, created_at: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/bounces/($address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove bounce
#
# DELETE /v3/{domain_name}/bounces/{address}
# operationId: DELETE-v3--domainID--bounces--address-
export def "bounces DELETE-v3--domainID--bounces--address-" [
  domain_name: string
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, address: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/bounces/($address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all bounces
#
# GET /v3/{domain_name}/bounces
# operationId: GET-v3--domainID--bounces
export def "bounces GET-v3--domainID--bounces" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of records to return (optional, default: 100, max: 1000)
  --page: string # Page direction relative to the above address, can be `next`, `previous` or `last`, if empty, returns the first page
  --term: string # Filter records based on addresses that start with the specified substring.
]: nothing -> record<items: table<address: string, code: string, error: string, created_at: record>, paging: record<previous: string, first: string, next: string, last: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "term" $term "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($domain_name)/bounces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add bounces
#
# POST /v3/{domain_name}/bounces
# operationId: POST-v3--domainID--bounces
export def "bounces POST-v3--domainID--bounces" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Content-Type must be `application/json` if inserting using JSON, no header necessary for form-data insertion
  --body: record
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/bounces")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clear all bounces
#
# DELETE /v3/{domain_name}/bounces
# operationId: DELETE-v3--domainID--bounces
export def "bounces DELETE-v3--domainID--bounces" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/bounces")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lookup unsubscribe record
#
# GET /v3/{domain_name}/unsubscribes/{address}
# operationId: GET-v3--domainID--unsubscribes--address-
export def "unsubscribes GET-v3--domainID--unsubscribes--address-" [
  domain_name: string
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, tags: list<string>, created_at: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/unsubscribes/($address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove unsubscribe
#
# DELETE /v3/{domain_name}/unsubscribes/{address}
# operationId: DELETE-v3--domainID--unsubscribes--address-
export def "unsubscribes DELETE-v3--domainID--unsubscribes--address-" [
  domain_name: string
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, address: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/unsubscribes/($address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all unsubscribes
#
# GET /v3/{domain_name}/unsubscribes
# operationId: GET-v3--domainID--unsubscribes
export def "unsubscribes GET-v3--domainID--unsubscribes" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of records to return (optional, default: 100, max: 1000)
  --page: string # Page direction relative to the above address, can be `next`, `previous` or `last`, if empty, returns the first page
  --address: string # address serving as a "divider" between pages
  --term: string # Filter records based on addresses that start with the specified substring.
]: nothing -> record<items: table<address: string, tags: list, created_at: record>, paging: record<previous: string, first: string, next: string, last: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "address" $address "scalar") (serialize-qp "term" $term "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($domain_name)/unsubscribes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add unsubscribes
#
# POST /v3/{domain_name}/unsubscribes
# operationId: POST-v3--domainID--unsubscribes
export def "unsubscribes POST-v3--domainID--unsubscribes" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Content-Type must be `application/json` if inserting using JSON, no header necessary for form-data insertion
  --body: record
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/unsubscribes")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clear all unsubscribes
#
# DELETE /v3/{domain_name}/unsubscribes
# operationId: DELETE-v3--domainID--unsubscribes
export def "unsubscribes DELETE-v3--domainID--unsubscribes" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/unsubscribes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lookup complaint record
#
# GET /v3/{domain_name}/complaints/{address}
# operationId: GET-v3--domainID--complaints--address-
export def "complaints GET-v3--domainID--complaints--address-" [
  domain_name: string
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, created_at: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/complaints/($address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove complaint
#
# DELETE /v3/{domain_name}/complaints/{address}
# operationId: DELETE-v3--domainID--complaints--address-
export def "complaints DELETE-v3--domainID--complaints--address-" [
  domain_name: string
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, address: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/complaints/($address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all complaints
#
# GET /v3/{domain_name}/complaints
# operationId: GET-v3--domainID--complaints
export def "complaints GET-v3--domainID--complaints" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of records to return (optional, default: 100, max: 1000)
  --page: string # Page direction relative to the above address, can be `next`, `previous` or `last`, if empty, returns the first page
  --address: string # address serving as a "divider" between pages
  --term: string # Filter records based on addresses that start with the specified substring.
]: nothing -> record<items: table<address: string, created_at: record>, paging: record<previous: string, first: string, next: string, last: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "address" $address "scalar") (serialize-qp "term" $term "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($domain_name)/complaints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add complaints
#
# POST /v3/{domain_name}/complaints
# operationId: POST-v3--domainID--complaints
export def "complaints POST-v3--domainID--complaints" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Content-Type must be `application/json` if inserting using JSON, no header necessary for form-data insertion
  --body: record
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/complaints")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clear all complaints
#
# DELETE /v3/{domain_name}/complaints
# operationId: DELETE-v3--domainID--complaints
export def "complaints DELETE-v3--domainID--complaints" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/complaints")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lookup allowlist record
#
# GET /v3/{domain_name}/whitelists/{value}
# operationId: GET-v3--domainID--whitelists--value-
export def "whitelists GET-v3--domainID--whitelists--value-" [
  domain_name: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, value: string, createdAt: record, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/whitelists/($value)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove entry from allowlist
#
# DELETE /v3/{domain_name}/whitelists/{value}
# operationId: DELETE-v3--domainID--whitelists--value-
export def "whitelists DELETE-v3--domainID--whitelists--value-" [
  domain_name: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/whitelists/($value)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List allowlist records for domain
#
# GET /v3/{domain_name}/whitelists
# operationId: GET-v3--domainID--whitelists
export def "whitelists GET-v3--domainID--whitelists" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of records to return (optional, default: 100, max: 1000)
  --page: string # Page direction relative to the above address, can be `next`, `previous` or `last`, if empty, returns the first page
  --address: string # address serving as a "divider" between pages
  --term: string # Filter records based on addresses that start with the specified substring.
]: nothing -> record<items: table<type: string, value: string, createdAt: record, reason: string>, paging: record<previous: string, first: string, next: string, last: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "address" $address "scalar") (serialize-qp "term" $term "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($domain_name)/whitelists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add allowlist record
#
# POST /v3/{domain_name}/whitelists
# operationId: POST-v3--domainID--whitelists
export def "whitelists POST-v3--domainID--whitelists" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<message: string, type: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/whitelists")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/form-data" $body
}

# Clear allowlist
#
# DELETE /v3/{domain_name}/whitelists
# operationId: DELETE-v3--domainID--whitelists
export def "whitelists DELETE-v3--domainID--whitelists" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/whitelists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a route
#
# POST /v3/routes
# operationId: post-v3-routes
export def "routes post-v3-routes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --priority: int # Smaller number indicates higher priority. Higher priority routes are handled first. Defaults to 0.
  --description: string # An arbitrary string.
  expression: string # The filtering rule.
  --action: list # This action is executed when the expression evaluates to True. You can pass multiple parameters.
]: any -> record<message: string, route: record<id: string, priority: int, description: string, expression: string, actions: list<string>, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/routes")
  let body = {priority: $priority, description: $description, expression: $expression, action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get all routes
#
# GET /v3/routes
# operationId: get-v3-routes
export def "routes get-v3-routes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --skip: string # Number of records to skip. Defaults to 0.
  --limit: string # Maximum number of records to return. Defaults to 100.
]: nothing -> record<total_count: int, items: table<id: string, priority: int, description: string, expression: string, actions: list, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/routes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a route
#
# GET /v3/routes/{id}
# operationId: get-v3-routes-id
export def "routes get-v3-routes-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<route: record<id: string, priority: int, description: string, expression: string, actions: list<string>, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/routes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a route
#
# PUT /v3/routes/{id}
# operationId: put-v3-routes-id
export def "routes put-v3-routes-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: string # Unique identifier of the route
  --priority: int # Smaller number indicates higher priority. Higher priority routes are handled first.
  --description: string # An arbitrary string.
  --expression: string # The filtering rule.
  --action: list # This action is executed when the expression evaluates to True. You can pass multiple parameters.
]: any -> record<message: string, route: record<id: string, priority: int, description: string, expression: string, actions: list<string>, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/routes/($id)")
  let body = {id: $body_id, priority: $priority, description: $description, expression: $expression, action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a route
#
# DELETE /v3/routes/{id}
# operationId: delete-v3-routes-id
export def "routes delete-v3-routes-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/routes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Match address to route
#
# GET /v3/routes/match
# operationId: get-v3-routes-match
export def "routes-match get-v3-routes-match" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: string # address to match routes on
]: nothing -> record<route: record<id: string, priority: int, description: string, expression: string, actions: list<string>, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/routes/match" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a mailing list
#
# POST /v3/lists
# operationId: post-v3-lists
export def "lists post-v3-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  address: string # A valid email address for the mailing list, e.g. developers@mailgun.net, or Developers <devs@mg.net>
  --name: string # Mailing list name, e.g. Developers
  --description: string # A description
  --access-level: string # List access level, one of: readonly, members, everyone. Defaults to readonly
  --reply-preference: string # Set where replies should go: list or sender. Defaults to list
]: any -> record<list: record<address: string, name: string, description: string, access_level: string, reply_preference: string, created_at: string, members_count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/lists")
  let body = {address: $address, name: $name, description: $description, access_level: $access_level, reply_preference: $reply_preference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get mailing lists
#
# GET /v3/lists
# operationId: get-v3-lists
export def "lists get-v3-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # Set limit for the list length returned. Defaults to 100.
  --skip: string # Skip the first n values in the list. Defaults to 0.
  --address: string # Filter mailing lists matching a specific address
]: nothing -> record<total_count: int, items: table<address: string, name: string, description: string, access_level: string, reply_preference: string, created_at: string, members_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "address" $address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get mailing lists members
#
# GET /v3/lists/{list_address}/members
# operationId: get-lists-string:list_address-members
export def "lists-members address-members-by-list_address" [
  list_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: string # A valid email address specification.
  --subscribed: string@bool-completer # Filtering list on whether the member is subscribed or not.
  --limit: int # Maximum number of records to return. Max is 100. Defaults to 100.
  --skip: int
]: nothing -> record<total_count: int, items: table<address: string, name: string, vars: record, subscribed: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar") (serialize-qp "subscribed" $subscribed "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/lists/($list_address)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a mailing list member
#
# POST /v3/lists/{list_address}/members
# operationId: post-lists-string:list_address-members
export def "lists-members address-members-by-list_address-1" [
  list_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: string # Valid email address specification.
  --name: string # An optional member name.
  --vars: record # JSON-encoded dictionary string with arbitrary parameters.
  --subscribed: string@bool-completer # Set the member as subscribed or not. Defaults to true.
  --upsert: string@bool-completer # Set to True to update member if present, False to raise error in case of a duplicate member. Defaults to false.
]: any -> record<member: record<address: string, name: string, vars: record, subscribed: bool>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/lists/($list_address)/members")
  let body = {address: $address, name: $name, vars: $vars, subscribed: $subscribed, upsert: $upsert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Bulk upload members to a mailing list (JSON)
#
# POST /v3/lists/{list_address}/members.json
# operationId: post-lists-list_address-members.json
export def "lists-membersjson address-membersjson" [
  list_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --members: string # Mailing list recipients in JSON array format. Can be, either, an array of string addresses or an array of ListMemberRequest JSON objects.
  --upsert: string@bool-completer # If true, an existing member will be updated. Defaults to false.
]: nothing -> record<list: record<address: string, name: string, description: string, access_level: string, reply_preference: string, created_at: string, members_count: int>, task_id: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "members" $members "scalar") (serialize-qp "upsert" $upsert "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/lists/($list_address)/members.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk upload members to a mailing list (CSV)
#
# POST /v3/lists/{list_address}/members.csv
# operationId: post-lists-list_address-members.csv
export def "lists-memberscsv address-memberscsv" [
  list_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscribed: string@bool-completer
  --upsert: string@bool-completer
  --members: string # Absolute path to the CSV file
]: any -> record<list: record<address: string, name: string, description: string, access_level: string, reply_preference: string, created_at: string, members_count: int>, task_id: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/lists/($list_address)/members.csv")
  let body = {subscribed: $subscribed, upsert: $upsert, members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get a member
#
# GET /v3/lists/{list_address}/members/{member_address}
# operationId: get-lists-list_address-members-member_address
export def "lists-members address-by-list_address-member_address" [
  list_address: string
  member_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, name: string, vars: record, subscribed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/lists/($list_address)/members/($member_address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a mailing list member
#
# PUT /v3/lists/{list_address}/members/{member_address}
# operationId: put-lists-list_address-members-member_address
export def "lists-members address-by-list_address-member_address-1" [
  list_address: string
  member_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: string # A valid email address specification.
  --name: string # An optional member name.
  --vars: record # JSON-encoded dictionary string with arbitrary parameters.
  --subscribed: string@bool-completer # Set the member to subscribed or not. Defaults to True.
]: any -> record<member: record<address: string, name: string, vars: record, subscribed: bool>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/lists/($list_address)/members/($member_address)")
  let body = {address: $address, name: $name, vars: $vars, subscribed: $subscribed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete a member
#
# DELETE /v3/lists/{list_address}/members/{member_address}
# operationId: delete-lists-list_address-members-member_address
export def "lists-members address-by-list_address-member_address-2" [
  list_address: string
  member_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<member: record<address: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/lists/($list_address)/members/($member_address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a mailing list
#
# PUT /v3/lists/{list_address}
# operationId: put-v3-lists-address
export def "lists put-v3-lists-address" [
  list_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: string # The new mailing list address.
  --description: string
  --name: string
  --access-level: string # One of: readonly, members, everyone. Defaults to readonly.
  --reply-reference: string # Set where replies should go. Can be list or sender. Defaults to list.
  --list-id: string
]: any -> record<message: string, list: record<address: string, name: string, description: string, access_level: string, reply_preference: string, created_at: string, members_count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/lists/($list_address)")
  let body = {address: $address, description: $description, name: $name, access_level: $access_level, reply_reference: $reply_reference, list-id: $list_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete a mailing list
#
# DELETE /v3/lists/{list_address}
# operationId: delete-v3-lists-address
export def "lists delete-v3-lists-address" [
  list_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/lists/($list_address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a mailing list by address
#
# GET /v3/lists/{list_address}
# operationId: get-v3-lists-address
export def "lists get-v3-lists-address" [
  list_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<list: record<address: string, name: string, description: string, access_level: string, reply_preference: string, created_at: string, members_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/lists/($list_address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get mailing lists by page
#
# GET /v3/lists/pages
# operationId: get-v3-lists-pages
export def "lists-pages get-v3-lists-pages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Set limit for the list length returned. Defaults to 100.
]: nothing -> record<paging: record<first: string, next: string, previous: string, last: string>, items: table<address: string, name: string, description: string, access_level: string, reply_preference: string, created_at: string, members_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/lists/pages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get members by page
#
# GET /v3/lists/{list_address}/members/pages
# operationId: get-lists-list_address-members-pages
export def "lists-members-pages address-members-pages" [
  list_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscribed: string@bool-completer # Filtering list on whether the member is subscribed or not.
  --limit: int # Set limit for the list length returned. Defaults to 100.
  --address: string # Use as pivot for pagination.
  --page: string # Could be either: first, last, next or prev
]: nothing -> record<paging: record<first: string, next: string, last: string, previous: string>, items: table<address: string, name: string, vars: record, subscribed: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscribed" $subscribed "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "address" $address "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/lists/($list_address)/members/pages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get templates
#
# GET /v3/{domain_name}/templates
# operationId: GET-v3--domain-name--templates
export def "templates GET-v3--domain-name--templates" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string@page-completer # Name of the page to retrieve. Value can be `first`, `last`, `next`, or `previous`. Defaults to `first`.
  --limit: int # Number of templates to retrieve. Default and max limit is 100.
  --p: string # Pivot used to retrieve the next page of templates.
]: nothing -> record<items: table<name: string, description: string, createdAt: string, createdBy: string, id: string, domain: string, version: any, versions: list>, paging: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "p" $p "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($domain_name)/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a template
#
# POST /v3/{domain_name}/templates
# operationId: POST-v3--domain-name--templates
export def "templates POST-v3--domain-name--templates" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the template being stored. Supports utf-8 characters and name will be down cased.
  --description: string # Description of the template being stored
  --createdBy: string # Optional metadata field api user can indicate who created the template.
  --template: string # Content of the template.
  --tag: string # Initial tag of the created version. If the template parameter is provided and the tag is missing, the default value `initial` is used.
  --comment: string # Version comment. This is valid only if a new version is being created. (template parameter is provided.)
  --headers: string # Key value JSON object of headers to be stored with the template. Where key is the header name and value is the header value. The header names `From`, `Subject`, and `Reply-To` are the only ones currently supported.  These headers will be inserted into the MIME at the time we attempt delivery.   Headers set at the message level will override headers set on the template. e.g. Setting the From header at the time of sending will override the From header saved on the template. Additionally, headers generated by templates are not reflected on the accepted event as they are not prepended to the message until the message is prepped for delivery. if a From header is not provided either in the message or template, we will default to `postmaster@your-sending-domain.tld`
]: any -> record<message: string, template: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/templates")
  let body = {name: $name, description: $description, createdBy: $createdBy, template: $template, tag: $tag, comment: $comment, headers: $headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete all templates
#
# DELETE /v3/{domain_name}/templates
# operationId: DELETE-v3--domain-name--templates
export def "templates DELETE-v3--domain-name--templates" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all template versions
#
# GET /v3/{domain_name}/templates/{template_name}/versions
# operationId: GET-v3--domain-name--templates--template-name--versions
export def "templates-versions GET-v3--domain-name--templates--template-name--versions" [
  domain_name: string
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string@page-completer # Name of the page to retrieve. Value can be `first`, `last`, `next`, or `previous`. Defaults to `first`.
  --limit: int # Number of templates to retrieve. Default and max limit is 100.
  --p: string # Pivot used to retrieve the next page of templates.
]: nothing -> record<template: any, paging: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "p" $p "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($domain_name)/templates/($template_name)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a template version
#
# POST /v3/{domain_name}/templates/{template_name}/versions
# operationId: POST-v3--domain-name--templates--template-name--versions
export def "templates-versions POST-v3--domain-name--templates--template-name--versions" [
  domain_name: string
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template: string # Content of the template.
  tag: string # Tag of the version that is being created. Must be unique to the template.
  --comment: string # Comment related to the version that is being created.
  --active: string # If this flag is set to yes, this version becomes active
  --headers: string # Key value JSON object of headers to be stored with the template. Where key is the header name and value is the header value. The header names `From`, `Subject`, and `Reply-To` are the only ones currently supported.  These headers will be inserted into the MIME at the time we attempt delivery.   Headers set at the message level will override headers set on the template. e.g. Setting the From header at the time of sending will override the From header saved on the template. Additionally, headers generated by templates are not reflected on the accepted event as they are not prepended to the message until the message is prepped for delivery. if a From header is not provided either in the message or template, we will default to `postmaster@your-sending-domain.tld`
]: any -> record<message: string, template: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/templates/($template_name)/versions")
  let body = {template: $template, tag: $tag, comment: $comment, active: $active, headers: $headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get template
#
# GET /v3/{domain_name}/templates/{template_name}
# operationId: GET-v3--domain-name--templates--template-name-
export def "templates GET-v3--domain-name--templates--template-name-" [
  domain_name: string
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string # If this flag is set to yes the active version of the template is included in the response.
]: nothing -> record<template: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($domain_name)/templates/($template_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update template
#
# PUT /v3/{domain_name}/templates/{template_name}
# operationId: PUT-v3--domain-name--templates--template-name-
export def "templates PUT-v3--domain-name--templates--template-name-" [
  domain_name: string
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # Update description of the template being updated.
]: any -> record<message: string, template: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/templates/($template_name)")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete a template
#
# DELETE /v3/{domain_name}/templates/{template_name}
# operationId: DELETE-v3--domain-name--templates--template-name-
export def "templates DELETE-v3--domain-name--templates--template-name-" [
  domain_name: string
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, template: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/templates/($template_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a version
#
# GET /v3/{domain_name}/templates/{template_name}/versions/{version_name}
# operationId: GET-v3--domain-name--templates--template-name--versions--version-name-
export def "templates-versions GET-v3--domain-name--templates--template-name--versions--version-name-" [
  domain_name: string
  template_name: string
  version_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<template: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/templates/($template_name)/versions/($version_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a version
#
# PUT /v3/{domain_name}/templates/{template_name}/versions/{version_name}
# operationId: PUT-v3--domain-name--templates--template-name--versions--version-name-
export def "templates-versions PUT-v3--domain-name--templates--template-name--versions--version-name-" [
  domain_name: string
  template_name: string
  version_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --template: string # Content of the template.
  --comment: string # Comment related to the version that is being created.
  --active: string # If this flag is set to yes, this version becomes active
  --headers: string # Key value JSON object of headers to be stored with the template. Where key is the header name and value is the header value. The header names `From`, `Subject`, and `Reply-To` are the only ones currently supported.  These headers will be inserted into the MIME at the time we attempt delivery.
]: any -> record<message: string, template: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/templates/($template_name)/versions/($version_name)")
  let body = {template: $template, comment: $comment, active: $active, headers: $headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete a version
#
# DELETE /v3/{domain_name}/templates/{template_name}/versions/{version_name}
# operationId: DELETE-v3--domain-name--templates--template-name--versions--version-name-
export def "templates-versions DELETE-v3--domain-name--templates--template-name--versions--version-name-" [
  domain_name: string
  template_name: string
  version_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, template: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/templates/($template_name)/versions/($version_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy a template
#
# PUT /v3/{domain_name}/templates/{template_name}/copy
# operationId: PUT-v3--domain-name--templates--template-name--copy
# --requests item shape: {account_id: string, name: string, domain?: string}
export def "templates-copy PUT-v3--domain-name--templates--template-name--copy" [
  domain_name: string
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  requests: list # List of copy requests — item shape: {account_id: string, name: string, domain?: string}
  --source-versions: list # Versions to copy or all versions if empty.
]: any -> record<message: string, failed_copies: table<account_id: string, name: string, domain: string>, error: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/templates/($template_name)/copy")
  let body = {requests: $requests, source_versions: $source_versions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Copy a version
#
# PUT /v3/{domain_name}/templates/{template_name}/versions/{version_name}/copy/{new_version_name}
# operationId: PUT-v3--domain-name--templates--template-name--versions--version-name--copy--new-version-name-
export def "templates-versions-copy PUT-v3--domain-name--templates--template-name--versions--version-name--copy--new-version-name-" [
  domain_name: string
  template_name: string
  version_name: string
  new_version_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --comment: string # Comment to be used for the new version.
]: nothing -> record<message: string, version: any, template: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "comment" $comment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($domain_name)/templates/($template_name)/versions/($version_name)/copy/($new_version_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rename a template
#
# PUT /v3/{domain_name}/templates/{template_name}/rename/{new_template_name}
# operationId: PUT-v3--domain-name--templates--template-name--rename--new-template-name-
export def "templates-rename PUT-v3--domain-name--templates--template-name--rename--new-template-name-" [
  domain_name: string
  template_name: string
  new_template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, template: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($domain_name)/templates/($template_name)/rename/($new_template_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get account-level templates
#
# GET /v4/templates
# operationId: GET-v4-templates
export def "templates GET-v4-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string@page-completer # Name of the page to retrieve. Value can be `first`, `last`, `next`, or `previous`. Defaults to `first`.
  --limit: int # Number of templates to retrieve. Default and max limit is 100.
  --p: string # Pivot used to retrieve the next page of templates.
]: nothing -> record<items: table<name: string, description: string, createdAt: string, createdBy: string, id: string, domain: string, version: any, versions: list>, paging: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "p" $p "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an account-level template
#
# POST /v4/templates
# operationId: POST-v4-templates
export def "templates POST-v4-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the template being stored. Supports utf-8 characters and name will be down cased.
  --description: string # Description of the template being stored
  --createdBy: string # Optional metadata field api user can indicate who created the template.
  --template: string # Content of the template.
  --tag: string # Initial tag of the created version. If the template parameter is provided and the tag is missing, the default value `initial` is used.
  --comment: string # Version comment. This is valid only if a new version is being created. (template parameter is provided.)
  --headers: string # Key value JSON object of headers to be stored with the template. Where key is the header name and value is the header value. The header names `From`, `Subject`, and `Reply-To` are the only ones currently supported.
]: any -> record<message: string, template: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/templates")
  let body = {name: $name, description: $description, createdBy: $createdBy, template: $template, tag: $tag, comment: $comment, headers: $headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete all account-level templates
#
# DELETE /v4/templates
# operationId: DELETE-v4-templates
export def "templates DELETE-v4-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all account-level template versions
#
# GET /v4/templates/{template_name}/versions
# operationId: GET-v4-templates--template-name--versions
export def "templates-versions GET-v4-templates--template-name--versions" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string@page-completer # Name of the page to retrieve. Value can be `first`, `last`, `next`, or `previous`. Defaults to `first`.
  --limit: int # Number of versions to retrieve. Default and max limit is 100.
  --p: string # Pivot used to retrieve the next page of versions.
]: nothing -> record<template: any, paging: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "p" $p "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/templates/($template_name)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an account-level template version
#
# POST /v4/templates/{template_name}/versions
# operationId: POST-v4-templates--template-name--versions
export def "templates-versions POST-v4-templates--template-name--versions" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template: string # Content of the template.
  tag: string # Tag of the version that is being created. Must be unique to the template.
  --comment: string # Comment related to the version that is being created.
  --active: string # If this flag is set to yes, this version becomes active
  --headers: string # Key value JSON object of headers to be stored with the template.
]: any -> record<message: string, template: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/templates/($template_name)/versions")
  let body = {template: $template, tag: $tag, comment: $comment, active: $active, headers: $headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get an account-level template
#
# GET /v4/templates/{template_name}
# operationId: GET-v4-templates--template-name-
export def "templates GET-v4-templates--template-name-" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string # If this flag is set to yes the active version of the template is included in the response.
]: nothing -> record<template: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/templates/($template_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an account-level template
#
# PUT /v4/templates/{template_name}
# operationId: PUT-v4-templates--template-name-
export def "templates PUT-v4-templates--template-name-" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # Update description of the template being updated.
]: any -> record<message: string, template: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/templates/($template_name)")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete an account-level template
#
# DELETE /v4/templates/{template_name}
# operationId: DELETE-v4-templates--template-name-
export def "templates DELETE-v4-templates--template-name-" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, template: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/templates/($template_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an account-level template version
#
# GET /v4/templates/{template_name}/versions/{version_name}
# operationId: GET-v4-templates--template-name--versions--version-name-
export def "templates-versions GET-v4-templates--template-name--versions--version-name-" [
  template_name: string
  version_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<template: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/templates/($template_name)/versions/($version_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an account-level template version
#
# PUT /v4/templates/{template_name}/versions/{version_name}
# operationId: PUT-v4-templates--template-name--versions--version-name-
export def "templates-versions PUT-v4-templates--template-name--versions--version-name-" [
  template_name: string
  version_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --template: string # Content of the template.
  --comment: string # Comment related to the version.
  --active: string # If this flag is set to yes, this version becomes active
  --headers: string # Key value JSON object of headers to be stored with the template.
]: any -> record<message: string, template: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/templates/($template_name)/versions/($version_name)")
  let body = {template: $template, comment: $comment, active: $active, headers: $headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete an account-level template version
#
# DELETE /v4/templates/{template_name}/versions/{version_name}
# operationId: DELETE-v4-templates--template-name--versions--version-name-
export def "templates-versions DELETE-v4-templates--template-name--versions--version-name-" [
  template_name: string
  version_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, template: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/templates/($template_name)/versions/($version_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy a template
#
# PUT /v4/templates/{template_name}/copy
# operationId: PUT-v4-templates--template-name--copy
# --requests item shape: {account_id: string, name: string, domain?: string}
export def "templates-copy PUT-v4-templates--template-name--copy" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  requests: list # List of copy requests — item shape: {account_id: string, name: string, domain?: string}
  --source-versions: list # Versions to copy or all versions if empty.
]: any -> record<message: string, failed_copies: table<account_id: string, name: string, domain: string>, error: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/templates/($template_name)/copy")
  let body = {requests: $requests, source_versions: $source_versions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Copy an account-level template version
#
# PUT /v4/templates/{template_name}/versions/{version_name}/copy/{new_version_name}
# operationId: PUT-v4-templates--template-name--versions--version-name--copy--new-version-name-
export def "templates-versions-copy PUT-v4-templates--template-name--versions--version-name--copy--new-version-name-" [
  template_name: string
  version_name: string
  new_version_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --comment: string # Comment to be used for the new version.
]: nothing -> record<message: string, version: any, template: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "comment" $comment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/templates/($template_name)/versions/($version_name)/copy/($new_version_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rename a template
#
# PUT /v4/templates/{template_name}/rename/{new_template_name}
# operationId: PUT-v4-templates--template-name--rename--new-template-name-
export def "templates-rename PUT-v4-templates--template-name--rename--new-template-name-" [
  template_name: string
  new_template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, template: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/templates/($template_name)/rename/($new_template_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update variable account settings
#
# PUT /v5/accounts
# operationId: put-v5-accounts
export def "accounts put-v5-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The new account organization name
  --inactive-session-timeout: int # The login session timeout period for inactivity
  --absolute-session-timeout: int # The login session timeout period limit
  --logout-redirect-url: string # The url to redirect to upon logout
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "inactive_session_timeout" $inactive_session_timeout "scalar") (serialize-qp "absolute_session_timeout" $absolute_session_timeout "scalar") (serialize-qp "logout_redirect_url" $logout_redirect_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v5/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get webhook signing key saved on the account
#
# GET /v5/accounts/http_signing_key
# operationId: get-v5-accounts-http_signing_key
export def "accounts-http-signing-key key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, http_signing_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v5/accounts/http_signing_key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or regenerate webhook signing key on an account
#
# POST /v5/accounts/http_signing_key
# operationId: post-v5-accounts-http_signing_key
export def "accounts-http-signing-key key-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, http_signing_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v5/accounts/http_signing_key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get authorized email recipients for a sandbox domain
#
# GET /v5/sandbox/auth_recipients
# operationId: get-v5-sandbox-auth_recipients
export def "sandbox-auth-recipients recipients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<recipients: table<email: string, activated: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v5/sandbox/auth_recipients")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add authorized email recipient for a sandbox domain
#
# POST /v5/sandbox/auth_recipients
# operationId: post-v5-sandbox-auth_recipients
export def "sandbox-auth-recipients recipients-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # The email address of the new recipient
]: nothing -> record<recipient: record<email: string, activated: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v5/sandbox/auth_recipients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove an authorized sandbox domain email recipient
#
# DELETE /v5/sandbox/auth_recipients/{email}
# operationId: delete-v5-sandbox-auth_recipients-email
export def "sandbox-auth-recipients recipients-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v5/sandbox/auth_recipients/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resend account activation email to the account owner
#
# POST /v5/accounts/resend_activation_email
# operationId: post-v5-accounts-resend_activation_email
export def "accounts-resend-activation-email email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v5/accounts/resend_activation_email")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update account feature
#
# PUT /v5/accounts/features
# operationId: put-v5-accounts-features
export def "accounts-features put-v5-accounts-features" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhooks-redact-pii: string # JSON object encoded as a string (format: json, e.g. {"enabled": false})
  --ai-insights: string # JSON object encoded as a string (format: json, e.g. {"enabled": false})
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v5/accounts/features")
  let body = {webhooks_redact_pii: $webhooks_redact_pii, ai_insights: $ai_insights} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a single subaccount
#
# GET /v5/accounts/subaccounts/{subaccount_id}
# operationId: get-v5-accounts-subaccounts-subaccount_id
export def "accounts-subaccounts id-by-subaccount_id" [
  subaccount_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<subaccount: record<id: string, name: string, created_at: string, updated_at: string, status: string, features: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v5/accounts/subaccounts/($subaccount_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all subaccounts
#
# GET /v5/accounts/subaccounts
# operationId: get-v5-accounts-subaccounts
export def "accounts-subaccounts get-v5-accounts-subaccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Sort order
  --filter: string # Name of account to filter by
  --limit: int # Number of subaccounts to return (default: 10)
  --skip: int # Number of subaccounts to skip (default: 0)
  --enabled: string@bool-completer # Indicate to include enabled subaccounts (true) or disabled accounts (false). Leave unspecified to allow for either, depending on other parameters provided.
  --closed: string@bool-completer # Indicate to include closed subaccounts (true) or exclude closed accounts (false). Leave unspecified to allow for either, depending on other parameters provided.
]: nothing -> record<subaccounts: table<id: string, name: string, created_at: string, updated_at: string, status: string, features: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "enabled" $enabled "scalar") (serialize-qp "closed" $closed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v5/accounts/subaccounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a subaccount
#
# POST /v5/accounts/subaccounts
# operationId: post-v5-accounts-subaccounts
export def "accounts-subaccounts post-v5-accounts-subaccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the subaccount
]: nothing -> record<subaccount: record<id: string, name: string, created_at: string, updated_at: string, status: string, features: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v5/accounts/subaccounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a subaccount
#
# DELETE /v5/accounts/subaccounts
# operationId: delete-v5-accounts-subaccounts-subaccount_id
export def "accounts-subaccounts id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Mailgun-On-Behalf-Of: string # The ID of the subaccount
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v5/accounts/subaccounts")
  let extra_headers = {"X-Mailgun-On-Behalf-Of": $X_Mailgun_On_Behalf_Of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable a subaccount
#
# POST /v5/accounts/subaccounts/{subaccount_id}/disable
# operationId: post-v5-accounts-subaccounts-subaccount_id-disable
export def "accounts-subaccounts-disable id-disable" [
  subaccount_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reason: string # The reason for disabling the subaccount
  --note: string # A note for the subaccount
]: nothing -> record<subaccount: record<id: string, name: string, created_at: string, updated_at: string, status: string, features: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar") (serialize-qp "note" $note "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v5/accounts/subaccounts/($subaccount_id)/disable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable a subaccount
#
# POST /v5/accounts/subaccounts/{subaccount_id}/enable
# operationId: post-v5-accounts-subaccounts-subaccount_id-enable
export def "accounts-subaccounts-enable id-enable" [
  subaccount_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<subaccount: record<id: string, name: string, created_at: string, updated_at: string, status: string, features: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v5/accounts/subaccounts/($subaccount_id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current custom sending limit
#
# GET /v5/accounts/subaccounts/{subaccount_id}/limit/custom/monthly
# operationId: get-v5-accounts-subaccounts-subaccount_id-limit-custom-monthly
export def "accounts-subaccounts-limit-custom-monthly id-limit-custom-monthly-by-subaccount_id" [
  subaccount_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<limit: float, current: float, period: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v5/accounts/subaccounts/($subaccount_id)/limit/custom/monthly")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set a custom sending limit
#
# PUT /v5/accounts/subaccounts/{subaccount_id}/limit/custom/monthly
# operationId: put-v5-accounts-subaccounts-subaccount_id-limit-custom-monthly
export def "accounts-subaccounts-limit-custom-monthly id-limit-custom-monthly-by-subaccount_id-1" [
  subaccount_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # The limit to set
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v5/accounts/subaccounts/($subaccount_id)/limit/custom/monthly" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a custom sending limit
#
# DELETE /v5/accounts/subaccounts/{subaccount_id}/limit/custom/monthly
# operationId: delete-v5-accounts-subaccounts-subaccount_id-limit-custom-monthly
export def "accounts-subaccounts-limit-custom-monthly id-limit-custom-monthly-by-subaccount_id-2" [
  subaccount_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v5/accounts/subaccounts/($subaccount_id)/limit/custom/monthly")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current custom sending limit
#
# GET /v5/accounts/limit/custom/monthly
# operationId: get-v5-accounts-limit-custom-monthly
export def "accounts-limit-custom-monthly get-v5-accounts-limit-custom-monthly" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<limit: float, current: float, period: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v5/accounts/limit/custom/monthly")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set a custom sending limit
#
# PUT /v5/accounts/limit/custom/monthly
# operationId: put-v5-accounts-limit-custom-monthly
export def "accounts-limit-custom-monthly put-v5-accounts-limit-custom-monthly" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # The limit to set
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v5/accounts/limit/custom/monthly" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a custom sending limit
#
# DELETE /v5/accounts/limit/custom/monthly
# operationId: delete-v5-accounts-limit-custom-monthly
export def "accounts-limit-custom-monthly delete-v5-accounts-limit-custom-monthly" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v5/accounts/limit/custom/monthly")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Re-enable account disabled for hitting send limit
#
# PUT /v5/accounts/limit/custom/enable
# operationId: put-v5-accounts-limit-custom-enable
export def "accounts-limit-custom-enable put-v5-accounts-limit-custom-enable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v5/accounts/limit/custom/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update subaccount feature
#
# PUT /v5/accounts/subaccounts/{subaccount_id}/features
# operationId: put-v5-accounts-subaccounts-subaccount_id-features
export def "accounts-subaccounts-features id-features" [
  subaccount_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email-preview: string # JSON object encoded as a string (format: json, e.g. {"enabled": false})
  --inbox-placement: string # JSON object encoded as a string (format: json, e.g. {"enabled": false})
  --sending: string # JSON object encoded as a string (format: json, e.g. {"enabled": false})
  --validations: string # JSON object encoded as a string (format: json, e.g. {"enabled": false})
  --validations-bulk: string # JSON object encoded as a string (format: json, e.g. {"enabled": false})
]: any -> record<features: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v5/accounts/subaccounts/($subaccount_id)/features")
  let body = {email_preview: $email_preview, inbox_placement: $inbox_placement, sending: $sending, validations: $validations, validations_bulk: $validations_bulk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List Mailgun API keys
#
# GET /v1/keys
# operationId: GET-v1-keys
export def "keys GET-v1-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain-name: string # Domain name filter for domain keys
  --kind: string@kind-completer # Key kind filter
]: nothing -> record<total_count: int, items: table<id: string, description: string, kind: string, role: string, created_at: string, updated_at: string, expires_at: string, disabled_reason: string, is_disabled: bool, domain_name: any, requestor: any, user_name: any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "kind" $kind "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Mailgun API key
#
# POST /v1/keys
# operationId: POST-v1-keys
export def "keys POST-v1-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain-name: string # Web domain to associate with the key, for keys of 'domain' kind
  --kind: string@kind-completer # Type of API key ('domain', 'user', or 'web'). Defaults to 'user' if not provided. Note: web keys are not subject to IP allowlisting and have a default/maximum validity period of 1 day.
  --description: string # Key description
  --expiration: int # Key lifetime in seconds, must be greater than 0 if set
  role: string@role-completer # Key role ('admin', 'basic' [use in place of analyst], 'sending' [use with keys of domain kind], or 'developer')
  --user-id: string # API Key user's string user ID; should be provided for all keys of 'web' kind
  --user-name: string # API Key user's name
  --email: string # API Key user's email address; should be provided for all keys of 'web' kind
]: any -> record<message: string, key: record<id: string, description: string, kind: string, role: string, created_at: string, updated_at: string, expires_at: string, disabled_reason: string, is_disabled: bool, domain_name: any, requestor: any, user_name: any, secret: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/keys")
  let body = {domain_name: $domain_name, kind: $kind, description: $description, expiration: $expiration, role: $role, user_id: $user_id, user_name: $user_name, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete Mailgun API key
#
# DELETE /v1/keys/{key_id}
# operationId: DELETE-v1-keys--key-id-
export def "keys DELETE-v1-keys--key-id-" [
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Regenerate Mailgun Public API key
#
# POST /v1/keys/public
# operationId: POST-v1-keys-public
export def "keys-public POST-v1-keys-public" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/keys/public")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Mailgun SMTP credential metadata for a given domain
#
# GET /v3/domains/{domain_name}/credentials
# operationId: GET-v3-domains--domain-name--credentials
export def "domains-credentials GET-v3-domains--domain-name--credentials" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --skip: int # Number of results to skip, to help with pagination (default: 0)
  --limit: int # Limit results to this many (default: 100)
]: nothing -> record<items: table<mailbox: string, login: string, created_at: string, size_bytes: any>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/domains/($domain_name)/credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Mailgun SMTP credentials for a given domain
#
# POST /v3/domains/{domain_name}/credentials
# operationId: POST-v3-domains--domain-name--credentials
export def "domains-credentials POST-v3-domains--domain-name--credentials" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  login: string # Email address of SMTP credential user; accepts multiple values
  --mailbox: string # Email address of SMTP credential user, may be used in place of 'login'; accepts multiple values
  --system: string@bool-completer # Identify if these are system account credentials, defaults to false
  --password: string # Supply desired password(s) for the new credentials if preferred over generated ones; accepts multiple values
]: any -> record<message: string, note: string, credentials: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($domain_name)/credentials")
  let body = {login: $login, mailbox: $mailbox, system: $system, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete all Mailgun SMTP credentials for a domain
#
# DELETE /v3/domains/{domain_name}/credentials
# operationId: DELETE-v3-domains--domain-name--credentials
export def "domains-credentials DELETE-v3-domains--domain-name--credentials" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($domain_name)/credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Mailgun SMTP credentials
#
# PUT /v3/domains/{domain_name}/credentials/{spec}
# operationId: PUT-v3-domains--domain-name--credentials--spec-
export def "domains-credentials PUT-v3-domains--domain-name--credentials--spec-" [
  domain_name: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --password: string # Supply desired password for the credentials to update if preferred over a generated one
]: any -> record<message: string, note: string, credentials: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($domain_name)/credentials/($spec)")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete Mailgun SMTP credentials
#
# DELETE /v3/domains/{domain_name}/credentials/{spec}
# operationId: DELETE-v3-domains--domain-name--credentials--spec-
export def "domains-credentials DELETE-v3-domains--domain-name--credentials--spec-" [
  domain_name: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, spec: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($domain_name)/credentials/($spec)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Mailgun account IP allowlist entries
#
# GET /v2/ip_whitelist
# operationId: GET-v2-ip-whitelist
export def "ip-whitelist GET-v2-ip-whitelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<addresses: table<ip_address: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/ip_whitelist")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update individual Mailgun account IP allowlist entry's description
#
# PUT /v2/ip_whitelist
# operationId: PUT-v2-ip-whitelist
export def "ip-whitelist PUT-v2-ip-whitelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  address: string # Address to be updated in the allowlist
  --description: string # Description of the address to be updated in the allowlist, defaults to empty string
]: any -> record<addresses: table<ip_address: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/ip_whitelist")
  let body = {address: $address, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Add Mailgun account IP allowlist entry
#
# POST /v2/ip_whitelist
# operationId: POST-v2-ip-whitelist
export def "ip-whitelist POST-v2-ip-whitelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  address: string # Address to be added to the allowlist
  --description: string # Description of the address to be added to the allowlist, defaults to empty string
]: any -> record<addresses: table<ip_address: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/ip_whitelist")
  let body = {address: $address, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete Mailgun account IP allowlist entry
#
# DELETE /v2/ip_whitelist
# operationId: DELETE-v2-ip-whitelist
export def "ip-whitelist DELETE-v2-ip-whitelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: string # Address to be deleted from allowlist
]: nothing -> record<addresses: table<ip_address: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/ip_whitelist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List statistics, ordered by total bounces
#
# GET /v1/bounce-classification/stats
# DEPRECATED
# operationId: GET-v1-bounce-classification-stats
@deprecated
export def "bounce-classification-stats GET-v1-bounce-classification-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --group: string # Group response by fields: subaccount.id, domain.name, entity-id, rule-id
  --limit: int # Limits the number of items returned in a response
  --include-subaccounts: string@bool-completer # Include subaccounts (default: false)
]: nothing -> record<items: list<any>, _duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group" $group "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "include_subaccounts" $include_subaccounts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/bounce-classification/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List domains statistic per account
#
# GET /v1/bounce-classification/domains
# DEPRECATED
# operationId: GET-v1-bounce-classification-domains
@deprecated
export def "bounce-classification-domains GET-v1-bounce-classification-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limits the number of items returned in a response
  --skip: int # Skips N items in a response
  --qp-query: string # Query filter, e.g.: 'domain.name:example.com'
  --include-subaccounts: string@bool-completer # Include subaccounts (default: false)
]: nothing -> record<items: list<any>, total: int, req: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "include_subaccounts" $include_subaccounts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/bounce-classification/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List statistic per domain
#
# GET /v1/bounce-classification/domains/{domain}/entities
# DEPRECATED
# operationId: GET-v1-bounce-classification-domains--domain--entities
@deprecated
export def "bounce-classification-domains-entities GET-v1-bounce-classification-domains--domain--entities" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-subaccounts: string@bool-completer # Include subaccounts (default: false)
]: nothing -> record<items: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_subaccounts" $include_subaccounts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/bounce-classification/domains/($domain)/entities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List statistic per entity
#
# GET /v1/bounce-classification/domains/{domain}/entities/{entity-id}/rules
# DEPRECATED
# operationId: GET-v1-bounce-classification-domains--domain--entities--entity-id--rules
@deprecated
export def "bounce-classification-domains-entities-rules GET-v1-bounce-classification-domains--domain--entities--entity-id--rules" [
  domain: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-subaccounts: string@bool-completer # Include subaccounts (default: false)
]: nothing -> record<items: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_subaccounts" $include_subaccounts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/bounce-classification/domains/($domain)/entities/($entity_id)/rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Bounce Logs
#
# GET /v1/bounce-classification/domains/{domain}/events
# DEPRECATED
# operationId: GET-v1-bounce-classification-domains--domain--events
@deprecated
export def "bounce-classification-domains-events GET-v1-bounce-classification-domains--domain--events" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rule-id: string # Optional if 'page' is passed
  --entity-id: string # The entity ID(Email Service Entity or Spam Filter / BL)
  --qp-sort: string # Sort field and order. Default is '@timestamp:asc'
  --page: string # Encoded paging information, provided via 'next', 'previous' links
  --limit: int # Limits the number of items returned in a response
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rule-id" $rule_id "scalar") (serialize-qp "entity-id" $entity_id "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/bounce-classification/domains/($domain)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List entities
#
# GET /v1/bounce-classification/config/entities
# DEPRECATED
# operationId: GET-v1-bounce-classification-config-entities
@deprecated
export def "bounce-classification-config-entities GET-v1-bounce-classification-config-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/bounce-classification/config/entities")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List rules
#
# GET /v1/bounce-classification/config/rules
# DEPRECATED
# operationId: GET-v1-bounce-classification-config-rules
@deprecated
export def "bounce-classification-config-rules GET-v1-bounce-classification-config-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/bounce-classification/config/rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List statistic v2
#
# POST /v2/bounce-classification/metrics
# operationId: POST-v2-bounce-classification-metrics
# --filter shape: {AND: list}
# --pagination shape: {sort?: string, skip?: int, limit?: int}
export def "bounce-classification-metrics POST-v2-bounce-classification-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: record # A start timestamp (default: 7 days before current time). Must be in RFC 2822 format: https://documentation.mailgun.com/docs/mailgun/api-reference/api-overview#date-format
  --end: record # An end timestamp (default: current time). Must be in RFC 2822 format: https://documentation.mailgun.com/docs/mailgun/api-reference/api-overview#date-format
  --resolution: record
  --duration: string # A duration in the format of '48h' '60m' '30s'. If duration is provided then it is calculated from the end date and overwrites the start date.
  --dimensions: list # Dimensions.
  --metrics: list # Metrics to return. See example.
  --filter: record # Filters to apply to the query. — shape: {AND: list}
  --include-subaccounts: string@bool-completer # Include stats from all subaccounts.
  --pagination: record # Attributes used for pagination and sorting. — shape: {sort?: string, skip?: int, limit?: int}
]: any -> record<start: string, end: string, resolution: record, duration: string, dimensions: list<string>, pagination: record<sort: string, skip: int, limit: int, total: int>, items: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bounce-classification/metrics")
  let body = {start: $start, end: $end, resolution: $resolution, duration: $duration, dimensions: $dimensions, metrics: $metrics, filter: $filter, include_subaccounts: $include_subaccounts, pagination: $pagination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single forward rule by ID
#
# GET /v3/forwards/{id}
# operationId: GET-v3-forwards--id-
export def "forwards GET-v3-forwards--id-" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, account_id: string, domain_name: string, domain_id: string, match: string, forward: record<urls: list<string>, recipients: list<string>, store: string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/forwards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a single forward rule by ID
#
# PUT /v3/forwards/{id}
# operationId: PUT-v3-forwards--id-
export def "forwards PUT-v3-forwards--id-" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-match: string # A wildcard expression which matches the recipient address to forward. This is a insensitive match address
  --forwardurl: string # A URL to forward when the rule matches the recipient. May be repeated up to 3 times. Must be a valid URL that resolves
  --forwardrecipient: string # A email address to forward to when the rule matches the recipient. May be repeated up to 5 times
  --forwardstore: string # A URL which will be used to notify you when the email arrives along with a URL you can use to retrieve the message. Must be a valid URL that resolves
]: nothing -> record<id: string, account_id: string, domain_name: string, domain_id: string, match: string, forward: record<urls: list<string>, recipients: list<string>, store: string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "match" $qp_match "scalar") (serialize-qp "forward.url" $forwardurl "scalar") (serialize-qp "forward.recipient" $forwardrecipient "scalar") (serialize-qp "forward.store" $forwardstore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/forwards/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a single forward rule by ID
#
# DELETE /v3/forwards/{id}
# operationId: DELETE-v3-forwards--id-
export def "forwards DELETE-v3-forwards--id-" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domainname: string # The name of the domain the rule is scoped to
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain.name" $domainname "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/forwards/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List forward rules
#
# GET /v3/forwards
# operationId: GET-v3-forwards
export def "forwards GET-v3-forwards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Encoded paging information, provided via 'next', 'previous' links
  --limit: int # Limits the number of items returned in a request
  --domainname: string # The name of the domain the rule is scoped to
]: nothing -> record<items: table<id: string, account_id: string, domain_name: string, domain_id: string, match: string, forward: record, created_at: string, updated_at: string>, paging: record<previous: string, first: string, next: string, last: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "domain.name" $domainname "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/forwards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a forward rule
#
# POST /v3/forwards
# operationId: POST-v3-forwards
export def "forwards POST-v3-forwards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-match: string # A wildcard expression which matches the recipient address to forward. This is a insensitive match address
  --forwardurl: string # A URL to forward when the rule matches the recipient. May be repeated up to 3 times. Must be a valid URL that resolves
  --forwardrecipient: string # A email address to forward to when the rule matches the recipient. May be repeated up to 5 times
  --forwardstore: string # A URL which will be used to notify you when the email arrives along with a URL you can use to retrieve the message. Must be a valid URL that resolves
]: nothing -> record<id: string, account_id: string, domain_name: string, domain_id: string, match: string, forward: record<urls: list<string>, recipients: list<string>, store: string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "match" $qp_match "scalar") (serialize-qp "forward.url" $forwardurl "scalar") (serialize-qp "forward.recipient" $forwardrecipient "scalar") (serialize-qp "forward.store" $forwardstore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/forwards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get users on an account
#
# GET /v5/users
# operationId: get-v5-users
export def "users get-v5-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string@role-completer-1 # The user role by which to filter results (basic == analyst)
  --limit: int # The number of users to return
  --skip: int # The number of users to skip
]: nothing -> record<users: table<id: string, activated: bool, name: string, is_disabled: bool, email: string, email_details: record, role: string, account_id: string, opened_ip: string, is_master: bool, metadata: record, tfa_enabled: bool, tfa_active: bool, tfa_created_at: any, password_updated_at: any, preferences: record, auth: record, github_user_id: any, salesforce_user_id: any, migration_status: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v5/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user's details
#
# GET /v5/users/{user_id}
# operationId: get-v5-users-user_id
export def "users id" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, activated: bool, name: string, is_disabled: bool, email: string, email_details: record<address: string, is_valid: bool, reason: string, parts: record<domain: string, local_part: string, display_name: string>>, role: string, account_id: string, opened_ip: string, is_master: bool, metadata: record, tfa_enabled: bool, tfa_active: bool, tfa_created_at: any, password_updated_at: any, preferences: record<time_zone: string, time_format: string, programming_language: string>, auth: record<method: string, prior_method: string, prior_details: record>, github_user_id: any, salesforce_user_id: any, migration_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v5/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one's own user details
#
# GET /v5/users/me
# operationId: get-v5-users-me
export def "users-me get-v5-users-me" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, activated: bool, name: string, is_disabled: bool, email: string, email_details: record<address: string, is_valid: bool, reason: string, parts: record<domain: string, local_part: string, display_name: string>>, role: string, account_id: string, opened_ip: string, is_master: bool, metadata: record, tfa_enabled: bool, tfa_active: bool, tfa_created_at: any, password_updated_at: any, preferences: record<time_zone: string, time_format: string, programming_language: string>, auth: record<method: string, prior_method: string, prior_details: record>, github_user_id: any, salesforce_user_id: any, migration_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v5/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
