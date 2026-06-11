# Auto-generated client for Postmark Account-level API v0.9.0
# Source: https://api.apis.guru/v2/specs/postmarkapp.com/account/0.9.0/swagger.json
# Auth: --token flag or $env.POSTMARK_ACCOUNT_LEVEL_API_TOKEN

const BASE_URL = "https://api.postmarkapp.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o POSTMARK_ACCOUNT_LEVEL_API_TOKEN | default "" }
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
def TrackLinks-completer [] { ["HtmlAndTextTracking" "HtmlOnlyTracking" "None" "TextOnlyTracking"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "domains listDomains" } } | get name | first)
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
export def "domains listDomains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Number of records to return per request. Max 500.
  --offset: int # Number of records to skip
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<Domains: table<DKIMVerified: bool, ID: int, Name: string, ReturnPathDomainVerified: bool, SPFVerified: bool, WeakDKIM: bool>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/domains" $qp)
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Domain
#
# POST /domains
# operationId: createDomain
export def "domains createDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
  --Name: string
  --ReturnPathDomain: string
]: any -> record<DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, ID: int, Name: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domains")
  let body = {Name: $Name, ReturnPathDomain: $ReturnPathDomain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<ErrorCode: int, Message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($domainid)")
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, ID: int, Name: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($domainid)")
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Domain
#
# PUT /domains/{domainid}
# operationId: editDomain
export def "domains editDomain" [
  domainid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
  --ReturnPathDomain: string
]: any -> record<DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, ID: int, Name: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($domainid)")
  let body = {ReturnPathDomain: $ReturnPathDomain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rotate DKIM Key
#
# POST /domains/{domainid}/rotatedkim
# operationId: rotateDKIMKeyForDomain
export def "domains-rotatedkim rotateDKIMKeyForDomain" [
  domainid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, ID: int, Name: string, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($domainid)/rotatedkim")
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request DNS Verification for DKIM
#
# PUT /domains/{domainid}/verifydkim
# operationId: requestDkimVerificationForDomain
export def "domains-verifydkim requestDkimVerificationForDomain" [
  domainid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, ID: int, Name: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($domainid)/verifydkim")
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request DNS Verification for Return-Path
#
# PUT /domains/{domainid}/verifyreturnpath
# operationId: requestReturnPathVerificationForDomain
export def "domains-verifyreturnpath requestReturnPathVerificationForDomain" [
  domainid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, ID: int, Name: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($domainid)/verifyreturnpath")
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request DNS Verification for SPF
#
# POST /domains/{domainid}/verifyspf
# operationId: requestSPFVerificationForDomain
export def "domains-verifyspf requestSPFVerificationForDomain" [
  domainid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<SPFHost: string, SPFTextValue: string, SPFVerified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($domainid)/verifyspf")
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Sender Signatures
#
# GET /senders
# operationId: listSenderSignatures
export def "senders listSenderSignatures" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Number of records to return per request. Max 500.
  --offset: int # Number of records to skip
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<SenderSignatures: table<Confirmed: bool, Domain: string, EmailAddress: string, ID: int, Name: string, ReplyToEmailAddress: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/senders" $qp)
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Sender Signature
#
# POST /senders
# operationId: createSenderSignature
export def "senders createSenderSignature" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
  --FromEmail: string # format: email
  --Name: string
  --ReplyToEmail: string # format: email
  --ReturnPathDomain: string
]: any -> record<Confirmed: bool, DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, Domain: string, EmailAddress: string, ID: int, Name: string, ReplyToEmailAddress: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/senders")
  let body = {FromEmail: $FromEmail, Name: $Name, ReplyToEmail: $ReplyToEmail, ReturnPathDomain: $ReturnPathDomain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Sender Signature
#
# DELETE /senders/{signatureid}
# operationId: deleteSenderSignature
export def "senders delete" [
  signatureid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<ErrorCode: int, Message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/senders/($signatureid)")
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Sender Signature
#
# GET /senders/{signatureid}
# operationId: getSenderSignature
export def "senders get" [
  signatureid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<Confirmed: bool, DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, Domain: string, EmailAddress: string, ID: int, Name: string, ReplyToEmailAddress: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/senders/($signatureid)")
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Sender Signature
#
# PUT /senders/{signatureid}
# operationId: editSenderSignature
export def "senders editSenderSignature" [
  signatureid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
  --Name: string
  --ReplyToEmail: string # format: email
  --ReturnPathDomain: string
]: any -> record<Confirmed: bool, DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, Domain: string, EmailAddress: string, ID: int, Name: string, ReplyToEmailAddress: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/senders/($signatureid)")
  let body = {Name: $Name, ReplyToEmail: $ReplyToEmail, ReturnPathDomain: $ReturnPathDomain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Request a new DKIM Key
#
# POST /senders/{signatureid}/requestnewdkim
# operationId: requestNewDKIMKeyForSenderSignature
export def "senders-requestnewdkim requestNewDKIMKeyForSenderSignature" [
  signatureid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<ErrorCode: int, Message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/senders/($signatureid)/requestnewdkim")
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resend Signature Confirmation Email
#
# POST /senders/{signatureid}/resend
# operationId: resendSenderSignatureConfirmationEmail
export def "senders-resend resendSenderSignatureConfirmationEmail" [
  signatureid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<ErrorCode: int, Message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/senders/($signatureid)/resend")
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request DNS Verification for SPF
#
# POST /senders/{signatureid}/verifyspf
# operationId: requestSPFVerificationForSenderSignature
export def "senders-verifyspf requestSPFVerificationForSenderSignature" [
  signatureid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<Confirmed: bool, DKIMHost: string, DKIMPendingHost: string, DKIMPendingTextValue: string, DKIMRevokedHost: string, DKIMRevokedTextValue: string, DKIMTestValue: string, DKIMUpdateStatus: string, DKIMVerified: bool, Domain: string, EmailAddress: string, ID: int, Name: string, ReplyToEmailAddress: string, ReturnPathDomain: string, ReturnPathDomainCNAMEValue: string, ReturnPathDomainVerified: bool, SPFHost: string, SPFTextValue: string, SPFVerified: bool, SafeToRemoveRevokedKeyFromDNS: bool, WeakDKIM: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/senders/($signatureid)/verifyspf")
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List servers
#
# GET /servers
# operationId: listServers
export def "servers listServers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Number of servers to return per request.
  --offset: int # Number of servers to skip.
  --name: string # Filter by a specific server name
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<Servers: table<ApiTokens: list, BounceHookUrl: string, ClickHookUrl: string, Color: string, DeliveryHookUrl: string, ID: int, InboundAddress: string, InboundDomain: string, InboundHash: string, InboundHookUrl: string, InboundSpamThreshold: int, Name: string, OpenHookUrl: string, PostFirstOpenOnly: bool, RawEmailEnabled: bool, ServerLink: string, SmtpApiActivated: bool, TrackLinks: string, TrackOpens: bool>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/servers" $qp)
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Server
#
# POST /servers
# operationId: createServer
export def "servers createServer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
  --BounceHookUrl: string
  --ClickHookUrl: string
  --Color: string
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
  let full_url = (build-url $base "/servers")
  let body = {BounceHookUrl: $BounceHookUrl, ClickHookUrl: $ClickHookUrl, Color: $Color, DeliveryHookUrl: $DeliveryHookUrl, InboundDomain: $InboundDomain, InboundHookUrl: $InboundHookUrl, InboundSpamThreshold: $InboundSpamThreshold, Name: $Name, OpenHookUrl: $OpenHookUrl, PostFirstOpenOnly: $PostFirstOpenOnly, RawEmailEnabled: $RawEmailEnabled, SmtpApiActivated: $SmtpApiActivated, TrackLinks: $TrackLinks, TrackOpens: $TrackOpens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($serverid)")
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Server
#
# GET /servers/{serverid}
# operationId: getServerInformation
export def "servers get" [
  serverid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
]: nothing -> record<ApiTokens: list<string>, BounceHookUrl: string, ClickHookUrl: string, Color: string, DeliveryHookUrl: string, ID: int, InboundAddress: string, InboundDomain: string, InboundHash: string, InboundHookUrl: string, InboundSpamThreshold: int, Name: string, OpenHookUrl: string, PostFirstOpenOnly: bool, RawEmailEnabled: bool, ServerLink: string, SmtpApiActivated: bool, TrackLinks: string, TrackOpens: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($serverid)")
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a Server
#
# PUT /servers/{serverid}
# operationId: editServerInformation
export def "servers editServerInformation" [
  serverid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
  --BounceHookUrl: string
  --ClickHookUrl: string
  --Color: string
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
  let full_url = (build-url $base $"/servers/($serverid)")
  let body = {BounceHookUrl: $BounceHookUrl, ClickHookUrl: $ClickHookUrl, Color: $Color, DeliveryHookUrl: $DeliveryHookUrl, InboundDomain: $InboundDomain, InboundHookUrl: $InboundHookUrl, InboundSpamThreshold: $InboundSpamThreshold, Name: $Name, OpenHookUrl: $OpenHookUrl, PostFirstOpenOnly: $PostFirstOpenOnly, RawEmailEnabled: $RawEmailEnabled, SmtpApiActivated: $SmtpApiActivated, TrackLinks: $TrackLinks, TrackOpens: $TrackOpens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Push templates from one server to another
#
# PUT /templates/push
# operationId: pushTemplates
export def "templates-push pushTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Postmark-Account-Token: string # The token associated with the Account on which this request will operate.
  --DestinationServerId: int
  --PerformChanges: string@bool-completer
  --SourceServerId: int
]: any -> record<Templates: table<Action: string, Alias: string, Name: string, TemplateId: int>, TotalCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/push")
  let body = {DestinationServerId: $DestinationServerId, PerformChanges: $PerformChanges, SourceServerId: $SourceServerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Postmark-Account-Token": $X_Postmark_Account_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
