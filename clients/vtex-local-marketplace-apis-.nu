# Auto-generated client for Suggestions v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Marketplace-APIs-/1.0/openapi.json
# Auth: --token flag or $env.SUGGESTIONS_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SUGGESTIONS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-vtex-api-appkey" => { {scheme: $scheme, headers: {X-VTEX-API-AppKey: $token_val}, query: "", location: "header"} }
    "x-vtex-api-apptoken" => { {scheme: $scheme, headers: {X-VTEX-API-AppToken: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://vtex.local" "https://api.vtex.com/{accountName}"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "suggestions get-getsuggestions" } } | get name | first)
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

# Get all SKU suggestions
#
# GET /suggestions
# operationId: Getsuggestions
export def "suggestions get-getsuggestions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account. Used as part of the URL (default: apiexamples)
  --q: string # This field allows you to customize your search. You can fill in this query param if you want to narrow down your search using the available filters on Received SKU modules. (e.g. )
  --type: string # This field allows users to filter SKU suggestions, by searching only the new suggestions that were just sent, and suggestions that have already been sent, but were updated. Possible values for this field include `new` and `update`. (e.g. new)
  --seller: string # A string that identifies the seller in the marketplace. This ID must be created by the marketplace and informed to the seller so it can call this endpoint. (e.g. )
  --status: string # Narrow down you search, filtering by status. Values allowed on this field include: `accepted`, `pending` and `denied.` (e.g. accepted)
  --hasmapping: string # This field allows you to filter SKUs that have mapping or not. Insert `true` to filter SKUs that have mapping, or `false` to retrieve SKUs that aren't mapped. (e.g. true)
  --matcherid: string # Identifies the matching entity. It can be either VTEX's matcher, or an external matcher developed by partners, for example. The `matcherId`'s value can be obtained through the [Get SKU Suggestion by ID](https://developers.vtex.com/vtex-rest-api/reference/getsuggestion) endpoint. (default: vtex-matcher)
  --qp-from: int # Define your pagination range, by adding the pagination starting value. Values should be bigger than 0, with a maximum of 50 records per page. (format: int32, default: 1)
  --qp-to: int # Define your pagination range, by adding the pagination ending value. Values should be bigger than 0, with a maximum of 50 records per page. (format: int32, default: 50)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "seller" $seller "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "hasmapping" $hasmapping "scalar") (serialize-qp "matcherid" $matcherid "scalar") (serialize-qp "_from" $qp_from "scalar") (serialize-qp "_to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/suggestions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountName": $account_name, "q": $q, "type": $type, "seller": $seller, "status": $status, "hasmapping": $hasmapping, "matcherid": $matcherid, "_from": $qp_from, "_to": $qp_to} | compact), body: null}
}

# Get Account's Approval Settings
#
# GET /suggestions/configuration
# operationId: Getaccountconfig
export def "suggestions-configuration get-getaccountconfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (default: apiexamples)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
]: nothing -> record<MatchFlux: string, Matchers: list<any>, Rules: record, Score: record, SpecificationsMapping: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/suggestions/configuration" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountName": $account_name} | compact), body: null}
}

# Save Account's Approval Settings
#
# PUT /suggestions/configuration
# operationId: Saveaccountconfig
# --Matchers item shape: {Description?: string, IsActive: bool, MatcherId: string, UpdatesNotificationEndpoint: string, hook-base-address: string}
# --Score shape: {Approve: int, Reject: int}
export def "suggestions-configuration update-saveaccountconfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (default: apiexamples)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
  match_flux: string # This field determines the type of approval configuration applied to SKUs received from a seller. The possible values include: - `default` where the Matcher reviews the SKU, and approves it based on its score - `manual` for manual approvals through the Received SKU UI or Match API - `autoApprove` for every SKU received from a given seller to be approved automatically, regardless of the Matcher Score. (default: autoApprove)
  matchers: list # Matchers for approving and rejecting SKUs received from sellers. — item shape: {Description?: string, IsActive: bool, MatcherId: string, UpdatesNotificationEndpoint: string, hook-base-address: string}
  score: record # Matcher rates received SKUs by comparing the data sent by sellers to existing fields in the marketplace. The calculation of these scores determines whether the product has been: `Approved` or `Denied`. — shape: {Approve: int, Reject: int}
  specifications_mapping: list<string> # This attribute maps product and SKU specifications.
]: any -> record<MatchFlux: string, Matchers: list<any>, Rules: record<Item: list<int>, Product: list<string>>, Score: record<Approve: int, Reject: int>, SpecificationsMapping: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/suggestions/configuration" $qp)
  let req_body = {"MatchFlux": $match_flux, "Matchers": $matchers, "Score": $score, "SpecificationsMapping": $specifications_mapping} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: ({"accountName": $account_name} | compact), body: $req_body}
}

# Get autoApprove Status in Account Settings
#
# GET /suggestions/configuration/autoapproval/toggle
# operationId: GetautoApprovevaluefromconfig
export def "suggestions-configuration-autoapproval-toggle get-getauto-approvevaluefromconfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --seller-id: string # A string that identifies the seller in the marketplace. This ID must be created by the marketplace. (default: seller123)
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (default: apiexamples)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
]: nothing -> record<Enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sellerId" $seller_id "scalar") (serialize-qp "accountName" $account_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/suggestions/configuration/autoapproval/toggle" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sellerId": $seller_id, "accountName": $account_name} | compact), body: null}
}

# Activate autoApprove in Marketplace's Account
#
# PUT /suggestions/configuration/autoapproval/toggle
# operationId: Saveautoapproveforaccount
export def "suggestions-configuration-autoapproval-toggle update-saveautoapproveforaccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (default: apiexamples)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
  --enabled: oneof<nothing, bool> # Insert `true` if you wish to activate the autoapprove rule for an entire marketplace account. Insert `false` if you wish to deactivate it. Be aware that once enabling the setting through this request, all received SKUs will be automatically approved on your store, regardless of the seller, or the Matcher Score. (default: true)
]: any -> record<Enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/suggestions/configuration/autoapproval/toggle" $qp)
  let req_body = {"Enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: ({"accountName": $account_name} | compact), body: $req_body}
}

# Activate autoApprove Setting for a Seller
#
# PUT /suggestions/configuration/autoapproval/toggle/seller/{sellerId}
# operationId: Saveautoapproveforaccountseller
export def "suggestions-configuration-autoapproval-toggle-seller update-saveautoapproveforaccountseller" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (default: apiexamples)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
  --enabled: oneof<nothing, bool> # Insert `true` if you wish to activate the autoapprove rule for that specific seller account. Insert `false` if you wish to deactivate it. Be aware that once enabling the setting through this request, all SKUs received from this seller will be automatically approved on your store regardless of the Matcher Score. (default: true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($seller_id | is-empty) { error make --unspanned { msg: "path parameter 'sellerId' must be non-empty" } }
  let qp = [(serialize-qp "accountName" $account_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id)} | format pattern "/suggestions/configuration/autoapproval/toggle/seller/{seller_id}") $qp)
  let req_body = {"Enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: ({"accountName": $account_name} | compact), body: $req_body}
}

# Get Seller's Approval Settings
#
# GET /suggestions/configuration/seller/{sellerId}
# operationId: Getselleraccountconfig
export def "suggestions-configuration-seller get-getselleraccountconfig" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (default: apiexamples)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($seller_id | is-empty) { error make --unspanned { msg: "path parameter 'sellerId' must be non-empty" } }
  let qp = [(serialize-qp "accountName" $account_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id)} | format pattern "/suggestions/configuration/seller/{seller_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountName": $account_name} | compact), body: null}
}

# Save Seller's Approval Settings
#
# PUT /suggestions/configuration/seller/{sellerId}
# operationId: Putselleraccountconfig
export def "suggestions-configuration-seller update-putselleraccountconfig" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (default: apiexamples)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
  --mapping: record # Mapping of SKU and product Specifications. This object should be sent in the following format for all fields you wish to map: {specificationName}:{specificationValue}, Example: Choose voltage: Voltage, Choose size: Size (nullable, default: {Choose size: Size, Choose type: Type, Choose voltage: Voltage, Choose volume: Volume})
  match_flux: string # This field determines the type of approval configuration applied to SKUs received from a seller. The possible values include: - `default` where the Matcher reviews the SKU, and approves it based on its score - `manual` for manual approvals through the Received SKU UI or Match API - `autoApprove` for every SKU received from a given seller to be approved automatically, regardless of the Matcher Score. (default: autoApprove)
  --body-seller-id: string # A string that identifies the seller in the marketplace. This ID must be created by the marketplace. (default: seller123)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($seller_id | is-empty) { error make --unspanned { msg: "path parameter 'sellerId' must be non-empty" } }
  let qp = [(serialize-qp "accountName" $account_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id)} | format pattern "/suggestions/configuration/seller/{seller_id}") $qp)
  let req_body = {"mapping": $mapping, "matchFlux": $match_flux, "sellerId": $body_seller_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: ({"accountName": $account_name} | compact), body: $req_body}
}

# Match Multiple Received SKUs
#
# PUT /suggestions/matches/action/{actionName}
# operationId: MatchMultiple
export def "suggestions-matches-action update-match-multiple" [
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account. Used as part of the URL (default: apiexamples)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($action_name | is-empty) { error make --unspanned { msg: "path parameter 'actionName' must be non-empty" } }
  let qp = [(serialize-qp "accountName" $account_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({action_name: (encode-path-segment $action_name)} | format pattern "/suggestions/matches/action/{action_name}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: ({"accountName": $account_name} | compact), body: $req_body}
}

# Delete SKU Suggestion
#
# DELETE /suggestions/{sellerId}/{sellerSkuId}
# operationId: DeleteSuggestion
export def "suggestions delete" [
  seller_id: string
  seller_sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account. Used as part of the URL. (default: apiexamples)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($seller_id | is-empty) { error make --unspanned { msg: "path parameter 'sellerId' must be non-empty" } }
  if ($seller_sku_id | is-empty) { error make --unspanned { msg: "path parameter 'sellerSkuId' must be non-empty" } }
  let qp = [(serialize-qp "accountName" $account_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id), seller_sku_id: (encode-path-segment $seller_sku_id)} | format pattern "/suggestions/{seller_id}/{seller_sku_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountName": $account_name} | compact), body: null}
}

# Get SKU Suggestion by ID
#
# GET /suggestions/{sellerId}/{sellerSkuId}
# operationId: GetSuggestion
export def "suggestions get" [
  seller_id: string
  seller_sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account. Used as part of the URL (default: apiexamples)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($seller_id | is-empty) { error make --unspanned { msg: "path parameter 'sellerId' must be non-empty" } }
  if ($seller_sku_id | is-empty) { error make --unspanned { msg: "path parameter 'sellerSkuId' must be non-empty" } }
  let qp = [(serialize-qp "accountName" $account_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id), seller_sku_id: (encode-path-segment $seller_sku_id)} | format pattern "/suggestions/{seller_id}/{seller_sku_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountName": $account_name} | compact), body: null}
}

# Send SKU Suggestion
#
# PUT /suggestions/{sellerId}/{sellerSkuId}
# operationId: SaveSuggestion
# --Images item shape: {imageName: string, imageUrl: string}
# --Pricing shape: {Currency?: string, CurrencySymbol?: string, SalePrice?: int}
# --ProductSpecifications item shape: {fieldName?: string, fieldValues?: list<string>}
# --SkuSpecifications item shape: {fieldName?: string, fieldValues?: list<string>}
export def "suggestions update-save" [
  seller_id: string
  seller_sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account to which the seller wants to suggest a new SKU. It is used as part of the request URL. (default: apiexamples)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/vnd.vtex.suggestion.v0+json)
  --content-type: string # Describes the type of the content being sent.
  available_quantity: int # format: int32
  brand_name: string # Name of the brand to which this SKU belongs. It must match the brand created in the marketplace.
  category_full_path: string # Full path to the SKU's category. It should be written as {department}/{category}. For example: if the department is **Appliances** and the category is **Oven**, the full path should be 'Appliances/Oven'.
  ean: string # SKU reference code. Mandatory if the RefId is not informed. (default: EAN10)
  height: int # Height of the SKU. (format: decimal, default: 10)
  images: list # Array containing the URLs and names the SKU images. — item shape: {imageName: string, imageUrl: string}
  length: int # Length of the SKU. (format: decimal, default: 10)
  --measurement-unit: string # Measurement unit that should be used for this SKU. If this information doesn't apply, you should use the default value `un`.
  pricing: record # shape: {Currency?: string, CurrencySymbol?: string, SalePrice?: int}
  product_description: string # Product Description containing the main information about the product (not the SKU).
  product_id: string # Product ID in seller's account. (default: 1234)
  product_name: string # Name of the suggested product. This field has a limit of 150 characters. (default: )
  --product-specifications: list # Array containing the names and values of the product specifications. — item shape: {fieldName?: string, fieldValues?: list<string>}
  ref_id: string # SKU reference code. Mandotory if the EAN is not informed. (default: REF10)
  --body-seller-id: string # ID of the seller in the marketplace. This ID must be created by the marketplace and informed to the seller before the integration is built. (default: 1)
  --seller-stock-keeping-unit-id: int # ID of the SKU registered in the seller. (format: int32)
  sku_name: string # Name of the suggested SKU.
  --sku-specifications: list # Array containing the names and values of the SKU specifications. — item shape: {fieldName?: string, fieldValues?: list<string>}
  --unit-multiplier: int # Unit multiplier for this SKU. If this information doesn't apply, you should use the default value `1`. (format: int32)
  weight: int # Weight of the SKU in grams. (format: decimal, default: 100)
  width: int # Width of the SKU. (format: decimal, default: 10)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($seller_id | is-empty) { error make --unspanned { msg: "path parameter 'sellerId' must be non-empty" } }
  if ($seller_sku_id | is-empty) { error make --unspanned { msg: "path parameter 'sellerSkuId' must be non-empty" } }
  let qp = [(serialize-qp "accountName" $account_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id), seller_sku_id: (encode-path-segment $seller_sku_id)} | format pattern "/suggestions/{seller_id}/{seller_sku_id}") $qp)
  let req_body = {"AvailableQuantity": $available_quantity, "BrandName": $brand_name, "CategoryFullPath": $category_full_path, "EAN": $ean, "Height": $height, "Images": $images, "Length": $length, "MeasurementUnit": $measurement_unit, "Pricing": $pricing, "ProductDescription": $product_description, "ProductId": $product_id, "ProductName": $product_name, "ProductSpecifications": $product_specifications, "RefId": $ref_id, "SellerId": $body_seller_id, "SellerStockKeepingUnitId": $seller_stock_keeping_unit_id, "SkuName": $sku_name, "SkuSpecifications": $sku_specifications, "UnitMultiplier": $unit_multiplier, "Weight": $weight, "Width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: ({"accountName": $account_name} | compact), body: $req_body}
}

# Get all Versions
#
# GET /suggestions/{sellerId}/{sellerskuid}/versions
# operationId: GetVersions
export def "suggestions-versions get" [
  seller_id: string
  sellerskuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account. Used as part of the URL (default: apiexamples)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --content-type: string # Describes the type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($seller_id | is-empty) { error make --unspanned { msg: "path parameter 'sellerId' must be non-empty" } }
  if ($sellerskuid | is-empty) { error make --unspanned { msg: "path parameter 'sellerskuid' must be non-empty" } }
  let qp = [(serialize-qp "accountName" $account_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id), sellerskuid: (encode-path-segment $sellerskuid)} | format pattern "/suggestions/{seller_id}/{sellerskuid}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountName": $account_name} | compact), body: null}
}

# Get Version by ID
#
# GET /suggestions/{sellerId}/{sellerskuid}/versions/{version}
# operationId: GetSuggestionbyversion
export def "suggestions-versions get-suggestionbyversion" [
  seller_id: string
  sellerskuid: string
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
  --account-name: string # Name of the VTEX account. Used as part of the URL (default: apiexamples)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --content-type: string # Describes the type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($seller_id | is-empty) { error make --unspanned { msg: "path parameter 'sellerId' must be non-empty" } }
  if ($sellerskuid | is-empty) { error make --unspanned { msg: "path parameter 'sellerskuid' must be non-empty" } }
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let qp = [(serialize-qp "accountName" $account_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id), sellerskuid: (encode-path-segment $sellerskuid), version: (encode-path-segment $version)} | format pattern "/suggestions/{seller_id}/{sellerskuid}/versions/{version}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountName": $account_name} | compact), body: null}
}

# Match Received SKUs individually
#
# PUT /suggestions/{sellerId}/{sellerskuid}/versions/{version}/matches/{matchid}
# operationId: Match
# --product shape: {brandId: int, categoryId: int, description: string, name: string, specifications: string}
# --sku shape: {eans: list<string>, height: int, images: list, length: int, measurementUnit: string, name: string, refId: string, specifications: record, unitMultiplier: int, weight: int, width: int}
export def "suggestions-versions-matches update-match" [
  seller_id: string
  sellerskuid: string
  version: string
  matchid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account. Used as part of the URL (default: apiexamples)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --content-type: string # Describes the type of the content being sent.
  match_type: string # Define the action you want to apply to each SKU. Values include: 1. `newproduct`: match the SKU as a new product. 2. `itemMatch`: associate the received SKU to an existing SKU. 3. `productMatch`: associate the received SKU to an existing product. 4. `deny`: deny the received SKU. 5. `pending`: the received SKU requires attention. 6. `incomplete`: the received SKU is lacking information to be matched. 7. `insufficientScore`: the score given by the Matcher to this received SKU doesn't qualify it to be matched. Note that if the autoApprove setting is enabled, the SKUs will be approved, regardless of the Score. (default: itemMatch)
  matcher_id: string # Identifies the matching entity. It can be either VTEX's matcher, or an external matcher developed by partners, for example. The `matcherId`'s value can be obtained through the [Get SKU Suggestion by ID](https://developers.vtex.com/vtex-rest-api/reference/getsuggestion) endpoint. (default: vtex-matcher)
  --product: record # shape: {brandId: int, categoryId: int, description: string, name: string, specifications: string}
  --product-ref: string # In `productMatch` actions, fill in this field on your request to match the item to an existing product in the marketplace. (nullable, default: )
  score: string # Matcher rates received SKUs by correlating the data sent by sellers, to existing fields in the marketplace. The calculation of these scores determines whether the product has been: `Approved`: score equal to or greater than 80 points. `Pending`: from 31 to 79 points. `Denied`: from 0 to 30 points. Note that if the autoApprove setting is enabled, the SKUs will be approved, regardless of the Score. (default: 80)
  --sku: record # e.g. {eans: [12345678901213], height: 1, images: [{imagem1.jpg: imageurl.example}], length: 1, measurementUnit: un, name: Sku exemplo, refId: , specifications: {Embalagem: 3 kg}, unitMultiplier: 1, weight: 1, width: 1} — shape: {eans: list<string>, height: int, images: list, length: int, measurementUnit: string, name: string, refId: string, specifications: record, unitMultiplier: int, weight: int, width: int}
  --sku-ref: string # In `itemMatch` actions, fill in this field on your request to match the item to an existing SKU in the marketplace. (nullable, default: )
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($seller_id | is-empty) { error make --unspanned { msg: "path parameter 'sellerId' must be non-empty" } }
  if ($sellerskuid | is-empty) { error make --unspanned { msg: "path parameter 'sellerskuid' must be non-empty" } }
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  if ($matchid | is-empty) { error make --unspanned { msg: "path parameter 'matchid' must be non-empty" } }
  let qp = [(serialize-qp "accountName" $account_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id), sellerskuid: (encode-path-segment $sellerskuid), version: (encode-path-segment $version), matchid: (encode-path-segment $matchid)} | format pattern "/suggestions/{seller_id}/{sellerskuid}/versions/{version}/matches/{matchid}") $qp)
  let req_body = {"matchType": $match_type, "matcherId": $matcher_id, "product": $product, "productRef": $product_ref, "score": $score, "sku": $sku, "skuRef": $sku_ref} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: ({"accountName": $account_name} | compact), body: $req_body}
}
