# Auto-generated client for Postmark Account-level API v0.9.0
# Source: https://api.apis.guru/v2/specs/postmarkapp.com/account/0.9.0/swagger.json
# Auth: --token flag or $env.POSTMARK_ACCOUNT_LEVEL_API_TOKEN

const BASE_URL = "https://api.postmarkapp.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o POSTMARK_ACCOUNT_LEVEL_API_TOKEN | default "" }
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
def track-links-completer [] { ["HtmlAndTextTracking" "HtmlOnlyTracking" "None" "TextOnlyTracking"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "domains list" } } | get name | first)
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

# List Domains
#
# GET /domains
# operationId: listDomains
export def "domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of records to return per request. Max 500.
  --offset: int # Number of records to skip
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<Domains: table<DKIMVerified: bool, ID: int, Name: string, ReturnPathDomainVerified: bool, SPFVerified: bool, WeakDKIM: bool>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/domains" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
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

# Create a Domain
#
# POST /domains
# operationId: createDomain
export def "domains create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
  --name: string
  --return-path-domain: string
]: any -> record<DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, ID: int, Name: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domains" $auth.query)
  let req_body = {"Name": $name, "ReturnPathDomain": $return_path_domain} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
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

# Delete a Domain
#
# DELETE /domains/{domainid}
# operationId: deleteDomain
export def "domains delete" [
  domainid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<ErrorCode: int, Message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domainid | is-empty) { error make --unspanned { msg: "path parameter 'domainid' must be non-empty" } }
  let full_url = (build-url $base ({domainid: (encode-path-segment $domainid)} | format pattern "/domains/{domainid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
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

# Get a Domain
#
# GET /domains/{domainid}
# operationId: getDomain
export def "domains get" [
  domainid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, ID: int, Name: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domainid | is-empty) { error make --unspanned { msg: "path parameter 'domainid' must be non-empty" } }
  let full_url = (build-url $base ({domainid: (encode-path-segment $domainid)} | format pattern "/domains/{domainid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
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

# Update a Domain
#
# PUT /domains/{domainid}
# operationId: editDomain
export def "domains update-edit" [
  domainid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
  --return-path-domain: string
]: any -> record<DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, ID: int, Name: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domainid | is-empty) { error make --unspanned { msg: "path parameter 'domainid' must be non-empty" } }
  let full_url = (build-url $base ({domainid: (encode-path-segment $domainid)} | format pattern "/domains/{domainid}") $auth.query)
  let req_body = {"ReturnPathDomain": $return_path_domain} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
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

# Rotate DKIM Key
#
# POST /domains/{domainid}/rotatedkim
# operationId: rotateDKIMKeyForDomain
export def "domains-rotatedkim create-rotate-dkim-key" [
  domainid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, ID: int, Name: string, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domainid | is-empty) { error make --unspanned { msg: "path parameter 'domainid' must be non-empty" } }
  let full_url = (build-url $base ({domainid: (encode-path-segment $domainid)} | format pattern "/domains/{domainid}/rotatedkim") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Request DNS Verification for DKIM
#
# PUT /domains/{domainid}/verifydkim
# operationId: requestDkimVerificationForDomain
export def "domains-verifydkim request-dkim-verification" [
  domainid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, ID: int, Name: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domainid | is-empty) { error make --unspanned { msg: "path parameter 'domainid' must be non-empty" } }
  let full_url = (build-url $base ({domainid: (encode-path-segment $domainid)} | format pattern "/domains/{domainid}/verifydkim") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
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

# Request DNS Verification for Return-Path
#
# PUT /domains/{domainid}/verifyreturnpath
# operationId: requestReturnPathVerificationForDomain
export def "domains-verifyreturnpath request-return-path-verification" [
  domainid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, ID: int, Name: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domainid | is-empty) { error make --unspanned { msg: "path parameter 'domainid' must be non-empty" } }
  let full_url = (build-url $base ({domainid: (encode-path-segment $domainid)} | format pattern "/domains/{domainid}/verifyreturnpath") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
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

# Request DNS Verification for SPF
#
# POST /domains/{domainid}/verifyspf
# operationId: requestSPFVerificationForDomain
export def "domains-verifyspf request-spf-verification" [
  domainid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<SPFHost: string, SPFTextValue: string, SPFVerified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domainid | is-empty) { error make --unspanned { msg: "path parameter 'domainid' must be non-empty" } }
  let full_url = (build-url $base ({domainid: (encode-path-segment $domainid)} | format pattern "/domains/{domainid}/verifyspf") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# List Sender Signatures
#
# GET /senders
# operationId: listSenderSignatures
export def "senders list-signatures" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of records to return per request. Max 500.
  --offset: int # Number of records to skip
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<SenderSignatures: table<Confirmed: bool, Domain: string, EmailAddress: string, ID: int, Name: string, ReplyToEmailAddress: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/senders" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
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

# Create a Sender Signature
#
# POST /senders
# operationId: createSenderSignature
export def "senders create-signature" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
  --from-email: string # format: email
  --name: string
  --reply-to-email: string # format: email
  --return-path-domain: string
]: any -> record<Confirmed: bool, DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, Domain: string, EmailAddress: string, ID: int, Name: string, ReplyToEmailAddress: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/senders" $auth.query)
  let req_body = {"FromEmail": $from_email, "Name": $name, "ReplyToEmail": $reply_to_email, "ReturnPathDomain": $return_path_domain} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
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

# Delete a Sender Signature
#
# DELETE /senders/{signatureid}
# operationId: deleteSenderSignature
export def "senders delete-signature" [
  signatureid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<ErrorCode: int, Message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($signatureid | is-empty) { error make --unspanned { msg: "path parameter 'signatureid' must be non-empty" } }
  let full_url = (build-url $base ({signatureid: (encode-path-segment $signatureid)} | format pattern "/senders/{signatureid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
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

# Get a Sender Signature
#
# GET /senders/{signatureid}
# operationId: getSenderSignature
export def "senders get-signature" [
  signatureid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<Confirmed: bool, DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, Domain: string, EmailAddress: string, ID: int, Name: string, ReplyToEmailAddress: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($signatureid | is-empty) { error make --unspanned { msg: "path parameter 'signatureid' must be non-empty" } }
  let full_url = (build-url $base ({signatureid: (encode-path-segment $signatureid)} | format pattern "/senders/{signatureid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
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

# Update a Sender Signature
#
# PUT /senders/{signatureid}
# operationId: editSenderSignature
export def "senders update-edit-signature" [
  signatureid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
  --name: string
  --reply-to-email: string # format: email
  --return-path-domain: string
]: any -> record<Confirmed: bool, DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, Domain: string, EmailAddress: string, ID: int, Name: string, ReplyToEmailAddress: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($signatureid | is-empty) { error make --unspanned { msg: "path parameter 'signatureid' must be non-empty" } }
  let full_url = (build-url $base ({signatureid: (encode-path-segment $signatureid)} | format pattern "/senders/{signatureid}") $auth.query)
  let req_body = {"Name": $name, "ReplyToEmail": $reply_to_email, "ReturnPathDomain": $return_path_domain} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
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

# Request a new DKIM Key
#
# POST /senders/{signatureid}/requestnewdkim
# operationId: requestNewDKIMKeyForSenderSignature
export def "senders-requestnewdkim request-new-dkim-key-for-signature" [
  signatureid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<ErrorCode: int, Message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($signatureid | is-empty) { error make --unspanned { msg: "path parameter 'signatureid' must be non-empty" } }
  let full_url = (build-url $base ({signatureid: (encode-path-segment $signatureid)} | format pattern "/senders/{signatureid}/requestnewdkim") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Resend Signature Confirmation Email
#
# POST /senders/{signatureid}/resend
# operationId: resendSenderSignatureConfirmationEmail
export def "senders-resend resend-signature-confirmation-email" [
  signatureid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<ErrorCode: int, Message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($signatureid | is-empty) { error make --unspanned { msg: "path parameter 'signatureid' must be non-empty" } }
  let full_url = (build-url $base ({signatureid: (encode-path-segment $signatureid)} | format pattern "/senders/{signatureid}/resend") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Request DNS Verification for SPF
#
# POST /senders/{signatureid}/verifyspf
# operationId: requestSPFVerificationForSenderSignature
export def "senders-verifyspf request-spf-verification-for-signature" [
  signatureid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<Confirmed: bool, DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, Domain: string, EmailAddress: string, ID: int, Name: string, ReplyToEmailAddress: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($signatureid | is-empty) { error make --unspanned { msg: "path parameter 'signatureid' must be non-empty" } }
  let full_url = (build-url $base ({signatureid: (encode-path-segment $signatureid)} | format pattern "/senders/{signatureid}/verifyspf") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# List servers
#
# GET /servers
# operationId: listServers
export def "servers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of servers to return per request.
  --offset: int # Number of servers to skip.
  --name: string # Filter by a specific server name
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<Servers: table<ApiTokens: list, BounceHookUrl: string, ClickHookUrl: string, Color: string, DeliveryHookUrl: string, ID: int, InboundAddress: string, InboundDomain: string, InboundHash: string, InboundHookUrl: string, InboundSpamThreshold: int, Name: string, OpenHookUrl: string, PostFirstOpenOnly: bool, RawEmailEnabled: bool, ServerLink: string, SmtpApiActivated: bool, TrackLinks: string, TrackOpens: bool>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/servers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count, "offset": $offset, "name": $name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a Server
#
# POST /servers
# operationId: createServer
export def "servers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
  --bounce-hook-url: string
  --click-hook-url: string
  --color: string
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
  let full_url = (build-url $base "/servers" $auth.query)
  let req_body = {"BounceHookUrl": $bounce_hook_url, "ClickHookUrl": $click_hook_url, "Color": $color, "DeliveryHookUrl": $delivery_hook_url, "InboundDomain": $inbound_domain, "InboundHookUrl": $inbound_hook_url, "InboundSpamThreshold": $inbound_spam_threshold, "Name": $name, "OpenHookUrl": $open_hook_url, "PostFirstOpenOnly": $post_first_open_only, "RawEmailEnabled": $raw_email_enabled, "SmtpApiActivated": $smtp_api_activated, "TrackLinks": $track_links, "TrackOpens": $track_opens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
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

# Delete a Server
#
# DELETE /servers/{serverid}
# operationId: deleteServer
export def "servers delete" [
  serverid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
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

# Get a Server
#
# GET /servers/{serverid}
# operationId: getServerInformation
export def "servers get-information" [
  serverid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<ApiTokens: list<string>, BounceHookUrl: string, ClickHookUrl: string, Color: string, DeliveryHookUrl: string, ID: int, InboundAddress: string, InboundDomain: string, InboundHash: string, InboundHookUrl: string, InboundSpamThreshold: int, Name: string, OpenHookUrl: string, PostFirstOpenOnly: bool, RawEmailEnabled: bool, ServerLink: string, SmtpApiActivated: bool, TrackLinks: string, TrackOpens: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
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

# Edit a Server
#
# PUT /servers/{serverid}
# operationId: editServerInformation
export def "servers update-edit-information" [
  serverid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
  --bounce-hook-url: string
  --click-hook-url: string
  --color: string
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
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}") $auth.query)
  let req_body = {"BounceHookUrl": $bounce_hook_url, "ClickHookUrl": $click_hook_url, "Color": $color, "DeliveryHookUrl": $delivery_hook_url, "InboundDomain": $inbound_domain, "InboundHookUrl": $inbound_hook_url, "InboundSpamThreshold": $inbound_spam_threshold, "Name": $name, "OpenHookUrl": $open_hook_url, "PostFirstOpenOnly": $post_first_open_only, "RawEmailEnabled": $raw_email_enabled, "SmtpApiActivated": $smtp_api_activated, "TrackLinks": $track_links, "TrackOpens": $track_opens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
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

# Push templates from one server to another
#
# PUT /templates/push
# operationId: pushTemplates
export def "templates-push push" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-account-token: string # The token associated with the Account on which this request will operate.
  --destination-server-id: int
  --perform-changes: oneof<nothing, bool>
  --source-server-id: int
]: any -> record<Templates: table<Action: string, Alias: string, Name: string, TemplateId: int>, TotalCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/push" $auth.query)
  let req_body = {"DestinationServerId": $destination_server_id, "PerformChanges": $perform_changes, "SourceServerId": $source_server_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Postmark-Account-Token": $x_postmark_account_token} | compact
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
