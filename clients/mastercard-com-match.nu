# Auto-generated client for MATCH API v1.0.0
# Source: https://api.apis.guru/v2/specs/mastercard.com/MATCH/1.0.0/swagger.json
# Auth: --token flag or $env.MATCH_API_TOKEN

const BASE_URL = "https://api.mastercard.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o MATCH_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.mastercard.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "fraud-merchant-add-merchant create" } } | get name | first)
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

# Used by Acquirers to add a terminated a merchant in the MATCH system. Merchant information, and up to five principal owners per merchant, can be provided by an acquiring bank as part of the listing.
#
# POST /fraud/merchant/v3/add-merchant
# --AddMerchantRequest shape: {AcquirerId: string, Merchant?: any}
export def "fraud-merchant-add-merchant create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-merchant-request: any # shape: {AcquirerId: string, Merchant?: any}
]: any -> record<AddMerchantResponse: record<MerchantReferenceNumber: string, Name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fraud/merchant/v3/add-merchant" $auth.query)
  let req_body = {"AddMerchantRequest": $add_merchant_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns the contact information for the acquirer id requested. When MATCH returns a possible merchant match, this resource assists users by retrieving the contact information associated with the Acquirer ID/ICA that added the merchant to MATCH.
#
# POST /fraud/merchant/v3/common/contact-details
# --ContactRequest shape: {AcquirerId: string}
export def "fraud-merchant-common-contact-details create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-request: any # shape: {AcquirerId: string}
]: any -> record<ContactResponse: record<Contact: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fraud/merchant/v3/common/contact-details" $auth.query)
  let req_body = {"ContactRequest": $contact_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns detailed information about Merchants, URLs and up to five principal owners, that have been terminated by an acquiring bank after the inquiry was made. This MATCH resource assists acquirer's ability to consider the merchants terminated after the inquiry was made. If an initial inquiry does not result in a possible match, it is still possible that the merchant listing could appear sometime in the next 360 days. This may occur when another acquirer enters the merchant into the MATCH database. The system will automatically continue to search the MATCH system for 360 days. To view these notifications, acquirers must use the Retroactive Inquiry Summary service. This resource can be used to obtain detailed information, such as, if a Merchant or individual has been terminated by another acquirer after an inquiry was made, the reason for termination, and the history of fraudulent or risky business practices that led to that termination.
#
# POST /fraud/merchant/v3/retro/retro-inquiry-details
# --RetroInquiryRequest shape: {InquiryReferenceNumber?: string}
export def "fraud-merchant-retro-retro-inquiry-details create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --acquirer-id: string # The Member ICA number which is used to validate that the application has permission to hit the MATCH database. This number must be obtained from a participating MATCH acquiring bank or entity before a developer can access the MATCH resource.
  --retro-inquiry-request: any # shape: {InquiryReferenceNumber?: string}
]: any -> record<RetroInquiryResponse: record<PossibleMerchantMatches: record<TerminatedMerchant: list, TotalLength: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AcquirerId" $acquirer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fraud/merchant/v3/retro/retro-inquiry-details" $qp $auth.query)
  let req_body = {"RetroInquiryRequest": $retro_inquiry_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"AcquirerId": $acquirer_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the summary of Retro matches for the given Acquirer Id. This resource will return the summary of Retroactive Inquiry matches for the given Acquirer ID/ICA. If an initial inquiry does not result in a possible match, it is still possible that the merchant listing could appear sometime in the next 360 days. This may occur when another acquirer enters the merchant into the MATCH database. The system will automatically continue to search the MATCH system for 360 days. To view these notifications, acquirers must use the Retroactive Inquiry service.
#
# POST /fraud/merchant/v3/retro/retro-list
# --RetroRequest shape: {AcquirerId?: string}
export def "fraud-merchant-retro-retro-list create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --retro-request: any # shape: {AcquirerId?: string}
]: any -> record<RetroResponse: record<BusinessName: string, City: string, Country: string, Date: string, RefNum: string, State: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fraud/merchant/v3/retro/retro-list" $auth.query)
  let req_body = {"RetroRequest": $retro_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns information on merchants that have been terminated and merchants that have inquired upon. Provides the acquiring bank with information, such as, if a Merchant or individual has been terminated by another acquirer already, the reason for termination, the history of fraudulent or risky business practices that led to that termination and the inquiry that was made already on the Merchant or individual by own or another acquiring bank (if opted).
#
# POST /fraud/merchant/v3/termination-inquiry
# --TerminationInquiryRequest shape: {AcquirerId: string, Merchant?: any, TransactionReferenceNumber?: string}
export def "fraud-merchant-termination-inquiry create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-offset: float # The zero-based offset to start at. The actual start position is this value +1. An offset of 10 starts at item 11. Combined with the PageLength option this allows pagination to be supported through the service requests. (e.g. 0)
  --page-length: float # The maximum number of items to retrieve within the current "page" of results. (e.g. 10)
  --termination-inquiry-request: any # shape: {AcquirerId: string, Merchant?: any, TransactionReferenceNumber?: string}
]: any -> record<TerminationInquiry: record<PageOffset: string, PossibleInquiryMatches: record<InquiredMerchant: list, TotalLength: string>, PossibleMerchantMatches: list<record>, TransactionReferenceNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageOffset" $page_offset "scalar") (serialize-qp "PageLength" $page_length "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fraud/merchant/v3/termination-inquiry" $qp $auth.query)
  let req_body = {"TerminationInquiryRequest": $termination_inquiry_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageOffset": $page_offset, "PageLength": $page_length} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns information about Merchants, URLs and up to five principal owners, that have been terminated by an acquiring bank from a previous inquiry. The Inquiry History Results resource displays the inquiry with the option to view either; Possible Merchant Matches or Possible Inquiry Matches.
#
# GET /fraud/merchant/v3/termination-inquiry/{IRN}
export def "fraud-merchant-termination-inquiry get" [
  irn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-offset: float # The zero-based offset to start at. The actual start position is this value +1. An offset of 10 starts at item 11. Combined with the PageLength option this allows pagination to be supported through the service requests. (e.g. 0)
  --page-length: float # The maximum number of items to retrieve within the current "page" of results. (e.g. 10)
  --acquirer-id: string # The Member ICA number which is used to validate that the application has permission to hit the MATCH database. This number must be obtained from a participating MATCH acquiring bank or entity before a developer can access the MATCH resource. (e.g. 1996)
]: nothing -> record<TerminationInquiry: record<PageOffset: string, PossibleInquiryMatches: record<InquiredMerchant: list, TotalLength: string>, PossibleMerchantMatches: list<record>, TransactionReferenceNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($irn | is-empty) { error make --unspanned { msg: "path parameter 'IRN' must be non-empty" } }
  let qp = [(serialize-qp "PageOffset" $page_offset "scalar") (serialize-qp "PageLength" $page_length "scalar") (serialize-qp "AcquirerId" $acquirer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({irn: (encode-path-segment $irn)} | format pattern "/fraud/merchant/v3/termination-inquiry/{irn}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageOffset": $page_offset, "PageLength": $page_length, "AcquirerId": $acquirer_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
