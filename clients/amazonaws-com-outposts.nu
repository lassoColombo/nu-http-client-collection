# Auto-generated client for AWS Outposts v2019-12-03
# Source: https://api.apis.guru/v2/specs/amazonaws.com/outposts/2019-12-03/openapi.json
# Auth: --token flag or $env.AWS_OUTPOSTS_TOKEN

const BASE_URL = "http://outposts.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_OUTPOSTS_TOKEN | default "" }
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["http://outposts.us-east-1.amazonaws.com" "http://outposts.us-east-2.amazonaws.com" "http://outposts.us-west-1.amazonaws.com" "http://outposts.us-west-2.amazonaws.com" "http://outposts.us-gov-west-1.amazonaws.com" "http://outposts.us-gov-east-1.amazonaws.com" "http://outposts.ca-central-1.amazonaws.com" "http://outposts.eu-north-1.amazonaws.com" "http://outposts.eu-west-1.amazonaws.com" "http://outposts.eu-west-2.amazonaws.com" "http://outposts.eu-west-3.amazonaws.com" "http://outposts.eu-central-1.amazonaws.com" "http://outposts.eu-south-1.amazonaws.com" "http://outposts.af-south-1.amazonaws.com" "http://outposts.ap-northeast-1.amazonaws.com" "http://outposts.ap-northeast-2.amazonaws.com" "http://outposts.ap-northeast-3.amazonaws.com" "http://outposts.ap-southeast-1.amazonaws.com" "http://outposts.ap-southeast-2.amazonaws.com" "http://outposts.ap-east-1.amazonaws.com" "http://outposts.ap-south-1.amazonaws.com" "http://outposts.sa-east-1.amazonaws.com" "http://outposts.me-south-1.amazonaws.com" "https://outposts.us-east-1.amazonaws.com" "https://outposts.us-east-2.amazonaws.com" "https://outposts.us-west-1.amazonaws.com" "https://outposts.us-west-2.amazonaws.com" "https://outposts.us-gov-west-1.amazonaws.com" "https://outposts.us-gov-east-1.amazonaws.com" "https://outposts.ca-central-1.amazonaws.com" "https://outposts.eu-north-1.amazonaws.com" "https://outposts.eu-west-1.amazonaws.com" "https://outposts.eu-west-2.amazonaws.com" "https://outposts.eu-west-3.amazonaws.com" "https://outposts.eu-central-1.amazonaws.com" "https://outposts.eu-south-1.amazonaws.com" "https://outposts.af-south-1.amazonaws.com" "https://outposts.ap-northeast-1.amazonaws.com" "https://outposts.ap-northeast-2.amazonaws.com" "https://outposts.ap-northeast-3.amazonaws.com" "https://outposts.ap-southeast-1.amazonaws.com" "https://outposts.ap-southeast-2.amazonaws.com" "https://outposts.ap-east-1.amazonaws.com" "https://outposts.ap-south-1.amazonaws.com" "https://outposts.sa-east-1.amazonaws.com" "https://outposts.me-south-1.amazonaws.com" "http://outposts.cn-north-1.amazonaws.com.cn" "http://outposts.cn-northwest-1.amazonaws.com.cn" "https://outposts.cn-north-1.amazonaws.com.cn" "https://outposts.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def payment-option-completer [] { ["ALL_UPFRONT" "NO_UPFRONT" "PARTIAL_UPFRONT"] }
def payment-term-completer [] { ["ONE_YEAR" "THREE_YEARS"] }
def supported-hardware-type-completer [] { ["RACK" "SERVER"] }
def address-type-completer [] { ["OPERATING_ADDRESS" "SHIPPING_ADDRESS"] }
def power-draw-kva-completer [] { ["POWER_10_KVA" "POWER_15_KVA" "POWER_30_KVA" "POWER_5_KVA"] }
def power-phase-completer [] { ["SINGLE_PHASE" "THREE_PHASE"] }
def power-connector-completer [] { ["AH530P7W" "AH532P6W" "IEC309" "L6_30P"] }
def power-feed-drop-completer [] { ["ABOVE_RACK" "BELOW_RACK"] }
def uplink-gbps-completer [] { ["UPLINK_100G" "UPLINK_10G" "UPLINK_1G" "UPLINK_40G"] }
def uplink-count-completer [] { ["UPLINK_COUNT_1" "UPLINK_COUNT_12" "UPLINK_COUNT_16" "UPLINK_COUNT_2" "UPLINK_COUNT_3" "UPLINK_COUNT_4" "UPLINK_COUNT_5" "UPLINK_COUNT_6" "UPLINK_COUNT_7" "UPLINK_COUNT_8"] }
def fiber-optic-cable-type-completer [] { ["MULTI_MODE" "SINGLE_MODE"] }
def optical-standard-completer [] { ["OPTIC_1000BASE_LX" "OPTIC_1000BASE_SX" "OPTIC_100GBASE_CWDM4" "OPTIC_100GBASE_LR4" "OPTIC_100GBASE_SR4" "OPTIC_100G_PSM4_MSA" "OPTIC_10GBASE_IR" "OPTIC_10GBASE_LR" "OPTIC_10GBASE_SR" "OPTIC_40GBASE_ESR" "OPTIC_40GBASE_IR4_LR4L" "OPTIC_40GBASE_LR4" "OPTIC_40GBASE_SR"] }
def maximum-supported-weight-lbs-completer [] { ["MAX_1400_LBS" "MAX_1600_LBS" "MAX_1800_LBS" "MAX_2000_LBS" "NO_LIMIT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "orders-cancel cancel" } } | get name | first)
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

# Cancels the specified order for an Outpost.
#
# POST /orders/{OrderId}/cancel
# operationId: CancelOrder
export def "orders-cancel cancel" [
  order_id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'OrderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates an order for an Outpost.
#
# POST /orders
# operationId: CreateOrder
# --LineItems item shape: {CatalogItemId?: any, Quantity?: any}
export def "orders create" [
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
  outpost_identifier: string # The ID or the Amazon Resource Name (ARN) of the Outpost.
  line_items: list # The line items that make up the order. — item shape: {CatalogItemId?: any, Quantity?: any}
  payment_option: string@payment-option-completer # The payment option.
  --payment-term: string@payment-term-completer # The payment terms.
]: any -> record<Order: record<OutpostId: record, OrderId: record, Status: record, LineItems: record, PaymentOption: record, OrderSubmissionDate: record, OrderFulfilledDate: record, PaymentTerm: record, OrderType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders")
  let req_body = {"OutpostIdentifier": $outpost_identifier, "LineItems": $line_items, "PaymentOption": $payment_option, "PaymentTerm": $payment_term} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates an Outpost. You can specify either an Availability one or an AZ ID.
#
# POST /outposts
# operationId: CreateOutpost
export def "outposts create" [
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
  name: string # The name of the Outpost.
  --description: string # The description of the Outpost.
  site_id: string # The ID of the site.
  --availability-zone: string # The Availability Zone.
  --availability-zone-id: string # The ID of the Availability Zone.
  --tags: record # The tags to apply to the Outpost.
  --supported-hardware-type: string@supported-hardware-type-completer # The type of hardware for this Outpost.
]: any -> record<Outpost: record<OutpostId: record, OwnerId: string, OutpostArn: string, SiteId: string, Name: string, Description: string, LifeCycleStatus: string, AvailabilityZone: string, AvailabilityZoneId: string, Tags: record, SiteArn: string, SupportedHardwareType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/outposts")
  let req_body = {"Name": $name, "Description": $description, "SiteId": $site_id, "AvailabilityZone": $availability_zone, "AvailabilityZoneId": $availability_zone_id, "Tags": $tags, "SupportedHardwareType": $supported_hardware_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists the Outposts for your Amazon Web Services account. Use filters to return specific results. If you specify multiple filters, the results include only the resources that match all of the specified filters. For a filter where you can specify multiple values, the results include items that match any of the values that you specify for the filter.
#
# GET /outposts
# operationId: ListOutposts
export def "outposts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: int
  --life-cycle-status-filter: list # Filters the results by the lifecycle status.
  --availability-zone-filter: list # Filters the results by Availability Zone (for example, us-east-1a).
  --availability-zone-id-filter: list # Filters the results by AZ ID (for example, use1-az1).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Outposts: table<OutpostId: record, OwnerId: string, OutpostArn: string, SiteId: string, Name: string, Description: string, LifeCycleStatus: string, AvailabilityZone: string, AvailabilityZoneId: string, Tags: record, SiteArn: string, SupportedHardwareType: record>, NextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "LifeCycleStatusFilter" $life_cycle_status_filter "multi") (serialize-qp "AvailabilityZoneFilter" $availability_zone_filter "multi") (serialize-qp "AvailabilityZoneIdFilter" $availability_zone_id_filter "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/outposts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"NextToken": $next_token, "MaxResults": $max_results, "LifeCycleStatusFilter": $life_cycle_status_filter, "AvailabilityZoneFilter": $availability_zone_filter, "AvailabilityZoneIdFilter": $availability_zone_id_filter} | compact), body: null}
}

# Creates a site for an Outpost.
#
# POST /sites
# operationId: CreateSite
# --OperatingAddress shape: {ContactName?: any, ContactPhoneNumber?: any, AddressLine1?: any, AddressLine2?: any, AddressLine3?: any, City?: any, StateOrRegion?: any, DistrictOrCounty?: any, PostalCode?: any, CountryCode?: any, Municipality?: any}
# --ShippingAddress shape: {ContactName?: any, ContactPhoneNumber?: any, AddressLine1?: any, AddressLine2?: any, AddressLine3?: any, City?: any, StateOrRegion?: any, DistrictOrCounty?: any, PostalCode?: any, CountryCode?: any, Municipality?: any}
# --RackPhysicalProperties shape: {PowerDrawKva?: any, PowerPhase?: any, PowerConnector?: any, PowerFeedDrop?: any, UplinkGbps?: any, UplinkCount?: any, FiberOpticCableType?: any, OpticalStandard?: any, MaximumSupportedWeightLbs?: any}
export def "sites create" [
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
  name: string # The name of the site.
  --description: string # The description of the site.
  --notes: string # Additional information that you provide about site access requirements, electrician scheduling, personal protective equipment, or regulation of equipment materials that could affect your installation process.
  --tags: record # The tags to apply to a site.
  --operating-address: record # Information about an address. — shape: {ContactName?: any, ContactPhoneNumber?: any, AddressLine1?: any, AddressLine2?: any, AddressLine3?: any, City?: any, StateOrRegion?: any, DistrictOrCounty?: any, PostalCode?: any, CountryCode?: any, Municipality?: any}
  --shipping-address: record # Information about an address. — shape: {ContactName?: any, ContactPhoneNumber?: any, AddressLine1?: any, AddressLine2?: any, AddressLine3?: any, City?: any, StateOrRegion?: any, DistrictOrCounty?: any, PostalCode?: any, CountryCode?: any, Municipality?: any}
  --rack-physical-properties: record # Information about the physical and logistical details for racks at sites. For more information about hardware requirements for racks, see Network readiness checklist (https://docs.aws.amazon.com/outposts/latest/userguide/outposts-requirements.html#checklist) in the Amazon Web Services Outposts User Guide. — shape: {PowerDrawKva?: any, PowerPhase?: any, PowerConnector?: any, PowerFeedDrop?: any, UplinkGbps?: any, UplinkCount?: any, FiberOpticCableType?: any, OpticalStandard?: any, MaximumSupportedWeightLbs?: any}
]: any -> record<Site: record<SiteId: string, AccountId: string, Name: string, Description: string, Tags: record, SiteArn: string, Notes: record, OperatingAddressCountryCode: record, OperatingAddressStateOrRegion: record, OperatingAddressCity: record, RackPhysicalProperties: record<PowerDrawKva: record, PowerPhase: record, PowerConnector: record, PowerFeedDrop: record, UplinkGbps: record, UplinkCount: record, FiberOpticCableType: record, OpticalStandard: record, MaximumSupportedWeightLbs: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sites")
  let req_body = {"Name": $name, "Description": $description, "Notes": $notes, "Tags": $tags, "OperatingAddress": $operating_address, "ShippingAddress": $shipping_address, "RackPhysicalProperties": $rack_physical_properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists the Outpost sites for your Amazon Web Services account. Use filters to return specific results. Use filters to return specific results. If you specify multiple filters, the results include only the resources that match all of the specified filters. For a filter where you can specify multiple values, the results include items that match any of the values that you specify for the filter.
#
# GET /sites
# operationId: ListSites
export def "sites list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: int
  --operating-address-country-code-filter: list # Filters the results by country code.
  --operating-address-state-or-region-filter: list # Filters the results by state or region.
  --operating-address-city-filter: list # Filters the results by city.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Sites: table<SiteId: string, AccountId: string, Name: string, Description: string, Tags: record, SiteArn: string, Notes: record, OperatingAddressCountryCode: record, OperatingAddressStateOrRegion: record, OperatingAddressCity: record, RackPhysicalProperties: record>, NextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "OperatingAddressCountryCodeFilter" $operating_address_country_code_filter "multi") (serialize-qp "OperatingAddressStateOrRegionFilter" $operating_address_state_or_region_filter "multi") (serialize-qp "OperatingAddressCityFilter" $operating_address_city_filter "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/sites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"NextToken": $next_token, "MaxResults": $max_results, "OperatingAddressCountryCodeFilter": $operating_address_country_code_filter, "OperatingAddressStateOrRegionFilter": $operating_address_state_or_region_filter, "OperatingAddressCityFilter": $operating_address_city_filter} | compact), body: null}
}

# Deletes the specified Outpost.
#
# DELETE /outposts/{OutpostId}
# operationId: DeleteOutpost
export def "outposts delete" [
  outpost_id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($outpost_id | is-empty) { error make --unspanned { msg: "path parameter 'OutpostId' must be non-empty" } }
  let full_url = (build-url $base ({outpost_id: (encode-path-segment $outpost_id)} | format pattern "/outposts/{outpost_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about the specified Outpost.
#
# GET /outposts/{OutpostId}
# operationId: GetOutpost
export def "outposts get" [
  outpost_id: string
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
]: nothing -> record<Outpost: record<OutpostId: record, OwnerId: string, OutpostArn: string, SiteId: string, Name: string, Description: string, LifeCycleStatus: string, AvailabilityZone: string, AvailabilityZoneId: string, Tags: record, SiteArn: string, SupportedHardwareType: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($outpost_id | is-empty) { error make --unspanned { msg: "path parameter 'OutpostId' must be non-empty" } }
  let full_url = (build-url $base ({outpost_id: (encode-path-segment $outpost_id)} | format pattern "/outposts/{outpost_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an Outpost.
#
# PATCH /outposts/{OutpostId}
# operationId: UpdateOutpost
export def "outposts update" [
  outpost_id: string
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
  --name: string # The name of the Outpost.
  --description: string # The description of the Outpost.
  --supported-hardware-type: string@supported-hardware-type-completer # The type of hardware for this Outpost.
]: any -> record<Outpost: record<OutpostId: record, OwnerId: string, OutpostArn: string, SiteId: string, Name: string, Description: string, LifeCycleStatus: string, AvailabilityZone: string, AvailabilityZoneId: string, Tags: record, SiteArn: string, SupportedHardwareType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($outpost_id | is-empty) { error make --unspanned { msg: "path parameter 'OutpostId' must be non-empty" } }
  let full_url = (build-url $base ({outpost_id: (encode-path-segment $outpost_id)} | format pattern "/outposts/{outpost_id}"))
  let req_body = {"Name": $name, "Description": $description, "SupportedHardwareType": $supported_hardware_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the specified site.
#
# DELETE /sites/{SiteId}
# operationId: DeleteSite
export def "sites delete" [
  site_id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'SiteId' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about the specified Outpost site.
#
# GET /sites/{SiteId}
# operationId: GetSite
export def "sites get" [
  site_id: string
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
]: nothing -> record<Site: record<SiteId: string, AccountId: string, Name: string, Description: string, Tags: record, SiteArn: string, Notes: record, OperatingAddressCountryCode: record, OperatingAddressStateOrRegion: record, OperatingAddressCity: record, RackPhysicalProperties: record<PowerDrawKva: record, PowerPhase: record, PowerConnector: record, PowerFeedDrop: record, UplinkGbps: record, UplinkCount: record, FiberOpticCableType: record, OpticalStandard: record, MaximumSupportedWeightLbs: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'SiteId' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the specified site.
#
# PATCH /sites/{SiteId}
# operationId: UpdateSite
export def "sites update" [
  site_id: string
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
  --name: string # The name of the site.
  --description: string # The description of the site.
  --notes: string # Notes about a site.
]: any -> record<Site: record<SiteId: string, AccountId: string, Name: string, Description: string, Tags: record, SiteArn: string, Notes: record, OperatingAddressCountryCode: record, OperatingAddressStateOrRegion: record, OperatingAddressCity: record, RackPhysicalProperties: record<PowerDrawKva: record, PowerPhase: record, PowerConnector: record, PowerFeedDrop: record, UplinkGbps: record, UplinkCount: record, FiberOpticCableType: record, OpticalStandard: record, MaximumSupportedWeightLbs: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'SiteId' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}"))
  let req_body = {"Name": $name, "Description": $description, "Notes": $notes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets information about the specified catalog item.
#
# GET /catalog/item/{CatalogItemId}
# operationId: GetCatalogItem
export def "catalog-item get" [
  catalog_item_id: string
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
]: nothing -> record<CatalogItem: record<CatalogItemId: record, ItemStatus: record, EC2Capacities: record, PowerKva: record, WeightLbs: record, SupportedUplinkGbps: record, SupportedStorage: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($catalog_item_id | is-empty) { error make --unspanned { msg: "path parameter 'CatalogItemId' must be non-empty" } }
  let full_url = (build-url $base ({catalog_item_id: (encode-path-segment $catalog_item_id)} | format pattern "/catalog/item/{catalog_item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Amazon Web Services uses this action to install Outpost servers. Gets information about the specified connection. Use CloudTrail to monitor this action or Amazon Web Services managed policy for Amazon Web Services Outposts to secure it. For more information, see Amazon Web Services managed policies for Amazon Web Services Outposts (https://docs.aws.amazon.com/outposts/latest/userguide/security-iam-awsmanpol.html) and Logging Amazon Web Services Outposts API calls with Amazon Web Services CloudTrail (https://docs.aws.amazon.com/outposts/latest/userguide/logging-using-cloudtrail.html) in the Amazon Web Services Outposts User Guide.
#
# GET /connections/{ConnectionId}
# operationId: GetConnection
export def "connections get" [
  connection_id: string
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
]: nothing -> record<ConnectionId: record, ConnectionDetails: record<ClientPublicKey: record, ServerPublicKey: record, ServerEndpoint: record, ClientTunnelAddress: record, ServerTunnelAddress: record, AllowedIps: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'ConnectionId' must be non-empty" } }
  let full_url = (build-url $base ({connection_id: (encode-path-segment $connection_id)} | format pattern "/connections/{connection_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about the specified order.
#
# GET /orders/{OrderId}
# operationId: GetOrder
export def "orders get" [
  order_id: string
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
]: nothing -> record<Order: record<OutpostId: record, OrderId: record, Status: record, LineItems: record, PaymentOption: record, OrderSubmissionDate: record, OrderFulfilledDate: record, PaymentTerm: record, OrderType: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'OrderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the instance types for the specified Outpost.
#
# GET /outposts/{OutpostId}/instanceTypes
# operationId: GetOutpostInstanceTypes
export def "outposts-instance-types get" [
  outpost_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: int
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<InstanceTypes: table<InstanceType: string>, NextToken: string, OutpostId: record, OutpostArn: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($outpost_id | is-empty) { error make --unspanned { msg: "path parameter 'OutpostId' must be non-empty" } }
  let qp = [(serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({outpost_id: (encode-path-segment $outpost_id)} | format pattern "/outposts/{outpost_id}/instanceTypes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"NextToken": $next_token, "MaxResults": $max_results} | compact), body: null}
}

# Gets the site address of the specified site.
#
# GET /sites/{SiteId}/address
# operationId: GetSiteAddress
export def "sites-address get" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-type: string@address-type-completer # The type of the address you request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<SiteId: string, AddressType: record, Address: record<ContactName: record, ContactPhoneNumber: record, AddressLine1: record, AddressLine2: record, AddressLine3: record, City: record, StateOrRegion: record, DistrictOrCounty: record, PostalCode: record, CountryCode: record, Municipality: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'SiteId' must be non-empty" } }
  let qp = [(serialize-qp "AddressType" $address_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/address") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AddressType": $address_type} | compact), body: null}
}

# Lists the hardware assets for the specified Outpost. Use filters to return specific results. If you specify multiple filters, the results include only the resources that match all of the specified filters. For a filter where you can specify multiple values, the results include items that match any of the values that you specify for the filter.
#
# GET /outposts/{OutpostId}/assets
# operationId: ListAssets
export def "outposts-assets list" [
  outpost_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id-filter: list # Filters the results by the host ID of a Dedicated Host.
  --max-results: int
  --next-token: string
  --status-filter: list # Filters the results by state.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Assets: record, NextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($outpost_id | is-empty) { error make --unspanned { msg: "path parameter 'OutpostId' must be non-empty" } }
  let qp = [(serialize-qp "HostIdFilter" $host_id_filter "multi") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "StatusFilter" $status_filter "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({outpost_id: (encode-path-segment $outpost_id)} | format pattern "/outposts/{outpost_id}/assets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"HostIdFilter": $host_id_filter, "MaxResults": $max_results, "NextToken": $next_token, "StatusFilter": $status_filter} | compact), body: null}
}

# Lists the items in the catalog. Use filters to return specific results. If you specify multiple filters, the results include only the resources that match all of the specified filters. For a filter where you can specify multiple values, the results include items that match any of the values that you specify for the filter.
#
# GET /catalog/items
# operationId: ListCatalogItems
export def "catalog-items list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: int
  --item-class-filter: list # Filters the results by item class.
  --supported-storage-filter: list # Filters the results by storage option.
  --ec2-family-filter: list # Filters the results by EC2 family (for example, M5).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<CatalogItems: record, NextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "ItemClassFilter" $item_class_filter "multi") (serialize-qp "SupportedStorageFilter" $supported_storage_filter "multi") (serialize-qp "EC2FamilyFilter" $ec2_family_filter "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/catalog/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"NextToken": $next_token, "MaxResults": $max_results, "ItemClassFilter": $item_class_filter, "SupportedStorageFilter": $supported_storage_filter, "EC2FamilyFilter": $ec2_family_filter} | compact), body: null}
}

# Lists the Outpost orders for your Amazon Web Services account.
#
# GET /list-orders
# operationId: ListOrders
export def "list-orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --outpost-identifier-filter: string # The ID or the Amazon Resource Name (ARN) of the Outpost.
  --next-token: string
  --max-results: int
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Orders: record, NextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "OutpostIdentifierFilter" $outpost_identifier_filter "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/list-orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"OutpostIdentifierFilter": $outpost_identifier_filter, "NextToken": $next_token, "MaxResults": $max_results} | compact), body: null}
}

# Lists the tags for the specified resource.
#
# GET /tags/{ResourceArn}
# operationId: ListTagsForResource
export def "tags list-for-resource" [
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
]: nothing -> record<Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'ResourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds tags to the specified resource.
#
# POST /tags/{ResourceArn}
# operationId: TagResource
export def "tags tag-resource" [
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
  tags: record # The tags to add to the resource.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'ResourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let req_body = {"Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Amazon Web Services uses this action to install Outpost servers. Starts the connection required for Outpost server installation. Use CloudTrail to monitor this action or Amazon Web Services managed policy for Amazon Web Services Outposts to secure it. For more information, see Amazon Web Services managed policies for Amazon Web Services Outposts (https://docs.aws.amazon.com/outposts/latest/userguide/security-iam-awsmanpol.html) and Logging Amazon Web Services Outposts API calls with Amazon Web Services CloudTrail (https://docs.aws.amazon.com/outposts/latest/userguide/logging-using-cloudtrail.html) in the Amazon Web Services Outposts User Guide.
#
# POST /connections
# operationId: StartConnection
export def "connections start" [
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
  device_serial_number: string # The serial number of the dongle.
  asset_id: string # The ID of the Outpost server.
  client_public_key: string # The public key of the client.
  network_interface_device_index: int # The device index of the network interface on the Outpost server.
]: any -> record<ConnectionId: record, UnderlayIpAddress: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/connections")
  let req_body = {"DeviceSerialNumber": $device_serial_number, "AssetId": $asset_id, "ClientPublicKey": $client_public_key, "NetworkInterfaceDeviceIndex": $network_interface_device_index} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes tags from the specified resource.
#
# DELETE /tags/{ResourceArn}
# operationId: UntagResource
export def "tags untag-resource" [
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
  --tag-keys: list # The tag keys.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'ResourceArn' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagKeys": $tag_keys} | compact), body: null}
}

# Updates the address of the specified site. You can't update a site address if there is an order in progress. You must wait for the order to complete or cancel the order. You can update the operating address before you place an order at the site, or after all Outposts that belong to the site have been deactivated.
#
# PUT /sites/{SiteId}/address
# operationId: UpdateSiteAddress
# --Address shape: {ContactName?: any, ContactPhoneNumber?: any, AddressLine1?: any, AddressLine2?: any, AddressLine3?: any, City?: any, StateOrRegion?: any, DistrictOrCounty?: any, PostalCode?: any, CountryCode?: any, Municipality?: any}
export def "sites-address update" [
  site_id: string
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
  address_type: string@address-type-completer # The type of the address.
  address: record # Information about an address. — shape: {ContactName?: any, ContactPhoneNumber?: any, AddressLine1?: any, AddressLine2?: any, AddressLine3?: any, City?: any, StateOrRegion?: any, DistrictOrCounty?: any, PostalCode?: any, CountryCode?: any, Municipality?: any}
]: any -> record<AddressType: record, Address: record<ContactName: record, ContactPhoneNumber: record, AddressLine1: record, AddressLine2: record, AddressLine3: record, City: record, StateOrRegion: record, DistrictOrCounty: record, PostalCode: record, CountryCode: record, Municipality: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'SiteId' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/address"))
  let req_body = {"AddressType": $address_type, "Address": $address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update the physical and logistical details for a rack at a site. For more information about hardware requirements for racks, see Network readiness checklist (https://docs.aws.amazon.com/outposts/latest/userguide/outposts-requirements.html#checklist) in the Amazon Web Services Outposts User Guide. To update a rack at a site with an order of IN_PROGRESS, you must wait for the order to complete or cancel the order.
#
# PATCH /sites/{SiteId}/rackPhysicalProperties
# operationId: UpdateSiteRackPhysicalProperties
export def "sites-rack-physical-properties update" [
  site_id: string
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
  --power-draw-kva: string@power-draw-kva-completer # The power draw, in kVA, available at the hardware placement position for the rack.
  --power-phase: string@power-phase-completer # The power option that you can provide for hardware. Single-phase AC feed: 200 V to 277 V, 50 Hz or 60 Hz Three-phase AC feed: 346 V to 480 V, 50 Hz or 60 Hz
  --power-connector: string@power-connector-completer # The power connector that Amazon Web Services should plan to provide for connections to the hardware. Note the correlation between PowerPhase and PowerConnector. Single-phase AC feed L6-30P – (common in US); 30A; single phase IEC309 (blue) – P+N+E, 6hr; 32 A; single phase Three-phase AC feed AH530P7W (red) – 3P+N+E, 7hr; 30A; three phase AH532P6W (red) – 3P+N+E, 6hr; 32A; three phase
  --power-feed-drop: string@power-feed-drop-completer # Indicates whether the power feed comes above or below the rack.
  --uplink-gbps: string@uplink-gbps-completer # The uplink speed the rack should support for the connection to the Region.
  --uplink-count: string@uplink-count-completer # Racks come with two Outpost network devices. Depending on the supported uplink speed at the site, the Outpost network devices provide a variable number of uplinks. Specify the number of uplinks for each Outpost network device that you intend to use to connect the rack to your network. Note the correlation between UplinkGbps and UplinkCount. 1Gbps - Uplinks available: 1, 2, 4, 6, 8 10Gbps - Uplinks available: 1, 2, 4, 8, 12, 16 40 and 100 Gbps- Uplinks available: 1, 2, 4
  --fiber-optic-cable-type: string@fiber-optic-cable-type-completer # The type of fiber that you will use to attach the Outpost to your network.
  --optical-standard: string@optical-standard-completer # The type of optical standard that you will use to attach the Outpost to your network. This field is dependent on uplink speed, fiber type, and distance to the upstream device. For more information about networking requirements for racks, see Network (https://docs.aws.amazon.com/outposts/latest/userguide/outposts-requirements.html#facility-networking) in the Amazon Web Services Outposts User Guide. OPTIC_10GBASE_SR: 10GBASE-SR OPTIC_10GBASE_IR: 10GBASE-IR OPTIC_10GBASE_LR: 10GBASE-LR OPTIC_40GBASE_SR: 40GBASE-SR OPTIC_40GBASE_ESR: 40GBASE-ESR OPTIC_40GBASE_IR4_LR4L: 40GBASE-IR (LR4L) OPTIC_40GBASE_LR4: 40GBASE-LR4 OPTIC_100GBASE_SR4: 100GBASE-SR4 OPTIC_100GBASE_CWDM4: 100GBASE-CWDM4 OPTIC_100GBASE_LR4: 100GBASE-LR4 OPTIC_100G_PSM4_MSA: 100G PSM4 MSA OPTIC_1000BASE_LX: 1000Base-LX OPTIC_1000BASE_SX : 1000Base-SX
  --maximum-supported-weight-lbs: string@maximum-supported-weight-lbs-completer # The maximum rack weight that this site can support. NO_LIMIT is over 2000lbs.
]: any -> record<Site: record<SiteId: string, AccountId: string, Name: string, Description: string, Tags: record, SiteArn: string, Notes: record, OperatingAddressCountryCode: record, OperatingAddressStateOrRegion: record, OperatingAddressCity: record, RackPhysicalProperties: record<PowerDrawKva: record, PowerPhase: record, PowerConnector: record, PowerFeedDrop: record, UplinkGbps: record, UplinkCount: record, FiberOpticCableType: record, OpticalStandard: record, MaximumSupportedWeightLbs: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'SiteId' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/rackPhysicalProperties"))
  let req_body = {"PowerDrawKva": $power_draw_kva, "PowerPhase": $power_phase, "PowerConnector": $power_connector, "PowerFeedDrop": $power_feed_drop, "UplinkGbps": $uplink_gbps, "UplinkCount": $uplink_count, "FiberOpticCableType": $fiber_optic_cable_type, "OpticalStandard": $optical_standard, "MaximumSupportedWeightLbs": $maximum_supported_weight_lbs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
