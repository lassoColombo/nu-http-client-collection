# Auto-generated client for Ship24 Tracking API v1.0.0
# Source: https://raw.githubusercontent.com/api-evangelist/ship24/main/openapi/ship24-tracking-api-openapi.yml
# Auth: --token flag or $env.SHIP24_TRACKING_API_TOKEN

const BASE_URL = "https://api.ship24.com"
const DEFAULT_AUTH = "bearer your_api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SHIP24_TRACKING_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer your_api_key" => { {headers: {Bearer your_api_key: $token_val}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = ($name | url encode)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[($in.k | into string | url encode)]=($in.v | into string | url encode)" }) }
  if not $is_list { return [$"($n)=($value | into string | url encode)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
    "csv" => { let joined = ($value | each { $in | into string | url encode } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string | url encode } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string | url encode } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string | url encode } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=($v | into string | url encode)" } }
    _ => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
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
def base-url-completer [] { ["https://api.ship24.com"] }
def auth-scheme-completer [] { ["bearer your_api_key"] }

# Completers for enum parameters
def sort-completer [] { ["-1" "1"] }
def accept-completer [] { ["application/json" "application/xml" "multipart/form-data"] }
def searchBy-completer [] { ["clientTrackerId" "trackerId"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "public-trackers create-tracker" } } | get name | first)
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

# Create a tracker
#
# POST /public/v1/trackers
# operationId: create-tracker
# --recipient shape: {email?: string, name?: string}
# --settings shape: {restrictTrackingToCourierCode?: bool}
export def "public-trackers create-tracker" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # application/json; charset=utf-8 (e.g. application/json; charset=utf-8)
  --Authorization: string # Your `api_key` prefixed with `Bearer`. (e.g. Bearer your_api_key)
  trackingNumber: string # Tracking number of the shipment. (e.g. 9400115901047177598206)
  --shipmentReference: string # Your reference for this shipment. Will be provided in our webhooks or API responses for this tracker. (e.g. c6e4fef4-a816-b68f-4024-3b7e4c5a9f81)
  --clientTrackerId: string # Your unique identifier for this shipment. Will be provided in our webhooks or API responses for this tracker. (e.g. 3fa99515-3ca0-4901-85bb-056ee016799b)
  --originCountryCode: string # Sender country code. (format: ISO 3166-1 alpha-2/alpha-3, e.g. CN)
  --destinationCountryCode: string # Recipient country code - 📌 Recommended to improve tracking accuracy (format: ISO 3166-1 alpha-2/alpha-3, e.g. US)
  --destinationPostCode: string # Recipient Post code (or ZIP code)  - 📌 Recommended to improve tracking accuracy (e.g. 94901)
  --shippingDate: string # Date at which the shipment has been shipped  - 📌 Recommended to improve tracking accuracy: providing the shipping date helps us accurately identify the shipment and improves our ability to retrieve the correct data. However, an inaccurate shipping date could cause our system to exclude the right shipment. Therefore, please ensure the provided shipping date aligns closely with the actual shipment date, give or take a few days. [Format](http://docs.ship24.com/data-format#logistics-date-and-time) (format: date-time)
  --courierCode: list # Code of the courier(s) handling the shipment (Up to 3 max) (see Couriers list section)  - 📌 Recommended to improve tracking accuracy (e.g. [us-post])
  --courierName: string # Courier name and/or service. (e.g. USPS Standard)
  --trackingUrl: string # Tracking URL of the courier. (e.g. https://tools.usps.com/go/TrackConfirmAction?tLabels=9400115901047177598206)
  --orderNumber: string # Order number in case of an eCommerce order. (e.g. DF14R2022)
  --title: string # Title for this shipment, visible on the Tracking Dashboard. (e.g. Nike shoes for Marc)
  --recipient: record # shape: {email?: string, name?: string}
  --settings: record # shape: {restrictTrackingToCourierCode?: bool}
]: any -> record<data: record<tracker: record<trackerId: string, trackingNumber: string, shipmentReference: string, courierCode: list, clientTrackerId: string, isSubscribed: bool, isTracked: bool, createdAt: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer your_api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/trackers")
  let body = {trackingNumber: $trackingNumber, shipmentReference: $shipmentReference, clientTrackerId: $clientTrackerId, originCountryCode: $originCountryCode, destinationCountryCode: $destinationCountryCode, destinationPostCode: $destinationPostCode, shippingDate: $shippingDate, courierCode: $courierCode, courierName: $courierName, trackingUrl: $trackingUrl, orderNumber: $orderNumber, title: $title, recipient: $recipient, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List existing Trackers
#
# GET /public/v1/trackers
# operationId: list-trackers
export def "public-trackers list-trackers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --page: int # The page index, starting from 1. (e.g. 1)
  --limit: int # The maximum number of trackers returned per page. (e.g. 100)
  --qp-sort: int@sort-completer # Defines the sorting order of trackers. Use `1` for ascending (`createdAt` oldest first) and `-1` for descending (`createdAt` newest first). The default is ascending (`1`) to ensure stable pagination. (e.g. 1)
  --Authorization: string # Your `api_key` prefixed with `Bearer`. (e.g. Bearer your_api_key)
]: nothing -> record<data: record<trackers: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer your_api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/trackers" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk create trackers
#
# POST /public/v1/trackers/bulk
# operationId: bulk-create-trackers
export def "public-trackers-bulk bulk-create-trackers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # application/json; charset=utf-8 (e.g. application/json; charset=utf-8)
  --Authorization: string # Your `api_key` prefixed with `Bearer`. (e.g. Bearer your_api_key)
  --body: record
]: any -> record<status: string, summary: record<totalInputs: int, totalCreated: int, totalExisting: int, totalErrors: int>, data: table<itemStatus: string, inputData: record, tracker: record, errors: list>, error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer your_api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/trackers/bulk")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a tracker and get tracking results
#
# POST /public/v1/trackers/track
# operationId: create-tracker-and-get-tracking-results
# --recipient shape: {email?: string, name?: string}
# --settings shape: {restrictTrackingToCourierCode?: bool}
export def "public-trackers-track create-tracker-and-get-tracking-results" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # application/json; charset=utf-8 (e.g. application/json; charset=utf-8)
  --Authorization: string # Your `api_key` prefixed with `Bearer`. (e.g. Bearer your_api_key)
  trackingNumber: string # Tracking number of the shipment. (e.g. 9400115901047177598206)
  --shipmentReference: string # Your reference for this shipment. Will be provided in our webhooks or API responses for this tracker. (e.g. c6e4fef4-a816-b68f-4024-3b7e4c5a9f81)
  --clientTrackerId: string # Your unique identifier for this shipment. Will be provided in our webhooks or API responses for this tracker. (e.g. 3fa99515-3ca0-4901-85bb-056ee016799b)
  --originCountryCode: string # Sender country code. (format: ISO 3166-1 alpha-2/alpha-3, e.g. CN)
  --destinationCountryCode: string # Recipient country code - 📌 Recommended to improve tracking accuracy (format: ISO 3166-1 alpha-2/alpha-3, e.g. US)
  --destinationPostCode: string # Recipient Post code (or ZIP code)  - 📌 Recommended to improve tracking accuracy (e.g. 94901)
  --shippingDate: string # Date at which the shipment has been shipped  - 📌 Recommended to improve tracking accuracy: providing the shipping date helps us accurately identify the shipment and improves our ability to retrieve the correct data. However, an inaccurate shipping date could cause our system to exclude the right shipment. Therefore, please ensure the provided shipping date aligns closely with the actual shipment date, give or take a few days. [Format](http://docs.ship24.com/data-format#logistics-date-and-time) (format: date-time)
  --courierCode: list # Code of the courier(s) handling the shipment (Up to 3 max) (see Couriers list section)  - 📌 Recommended to improve tracking accuracy (e.g. [us-post])
  --courierName: string # Courier name and/or service. (e.g. USPS Standard)
  --trackingUrl: string # Tracking URL of the courier. (e.g. https://tools.usps.com/go/TrackConfirmAction?tLabels=9400115901047177598206)
  --orderNumber: string # Order number in case of an eCommerce order. (e.g. DF14R2022)
  --title: string # Title for this shipment, visible on the Tracking Dashboard. (e.g. Nike shoes for Marc)
  --recipient: record # shape: {email?: string, name?: string}
  --settings: record # shape: {restrictTrackingToCourierCode?: bool}
]: any -> record<data: record<trackings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer your_api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/trackers/track")
  let body = {trackingNumber: $trackingNumber, shipmentReference: $shipmentReference, clientTrackerId: $clientTrackerId, originCountryCode: $originCountryCode, destinationCountryCode: $destinationCountryCode, destinationPostCode: $destinationPostCode, shippingDate: $shippingDate, courierCode: $courierCode, courierName: $courierName, trackingUrl: $trackingUrl, orderNumber: $orderNumber, title: $title, recipient: $recipient, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an existing tracker
#
# GET /public/v1/trackers/{trackerId}
# operationId: get-tracker-by-trackerId
export def "public-trackers get-tracker-by-trackerId" [
  trackerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --searchBy: string@searchBy-completer # Parameter allowing to search either by `trackerId`or `clientTrackerId`. Default behavior is by `trackerId`. (e.g. trackerId)
  --Authorization: string # Your `api_key` prefixed with `Bearer`. (e.g. Bearer your_api_key)
]: nothing -> record<trackerId: string, trackingNumber: string, shipmentReference: string, courierCode: list<string>, clientTrackerId: string, isSubscribed: bool, isTracked: bool, createdAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer your_api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchBy" $searchBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/v1/trackers/($trackerId)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing tracker
#
# PATCH /public/v1/trackers/{trackerId}
# operationId: update-tracker-by-trackerId
export def "public-trackers update-tracker-by-trackerId" [
  trackerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --searchBy: string@searchBy-completer # Parameter allowing to search either by `trackerId`or `clientTrackerId`. Default behavior is by `trackerId`. (e.g. trackerId)
  --Content-Type: string # application/json; charset=utf-8 (e.g. application/json; charset=utf-8)
  --Authorization: string # Your `api_key` prefixed with `Bearer`. (e.g. Bearer your_api_key)
  --isSubscribed: string@bool-completer # Setting at `false` will unsubscribe you from the `Tracker`. Once unsubscribed, you will still be able to fetch the existing tracking results but Ship24 won't search for new data or send webhook notifications. `Trackers` are automatically disabled after the parcel delivery or after a long period without any new events. Manually unsubscribing your tracker is not useful, except if you wish to stop receiving webhooks on it or if you need to reuse the `clientTrackerId` value in a new `Tracker`. (e.g. false)
  --courierCode: list # Code of the courier(s) handling the shipment (Up to 3 max) (see Couriers list section)  - 📌 Recommended to improve tracking accuracy (e.g. [us-post])
  --originCountryCode: string # Sender country code. (format: ISO 3166-1 alpha-2/alpha-3, e.g. CN)
  --destinationCountryCode: string # Recipient country code - 📌 Recommended to improve tracking accuracy (format: ISO 3166-1 alpha-2/alpha-3, e.g. US)
  --destinationPostCode: string # Recipient Post code (or ZIP code)  - 📌 Recommended to improve tracking accuracy (e.g. 94901)
  --shippingDate: string # Date at which the shipment has been shipped  - 📌 Recommended to improve tracking accuracy: providing the shipping date helps us accurately identify the shipment and improves our ability to retrieve the correct data. However, an inaccurate shipping date could cause our system to exclude the right shipment. Therefore, please ensure the provided shipping date aligns closely with the actual shipment date, give or take a few days. [Format](http://docs.ship24.com/data-format#logistics-date-and-time) (format: date-time)
]: any -> record<trackerId: string, trackingNumber: string, shipmentReference: string, courierCode: list<string>, clientTrackerId: string, isSubscribed: bool, isTracked: bool, createdAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer your_api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchBy" $searchBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/v1/trackers/($trackerId)" $qp)
  let body = {isSubscribed: $isSubscribed, courierCode: $courierCode, originCountryCode: $originCountryCode, destinationCountryCode: $destinationCountryCode, destinationPostCode: $destinationPostCode, shippingDate: $shippingDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get tracking results for existing trackers by tracking number
#
# GET /public/v1/trackers/search/{trackingNumber}/results
# operationId: get-tracking-results-of-trackers-by-tracking-number
export def "public-trackers-search-results get-tracking-results-of-trackers-by-tracking-number" [
  trackingNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Your `api_key` prefixed with `Bearer`. (e.g. Bearer your_api_key)
]: nothing -> record<data: record<trackings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer your_api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/trackers/search/($trackingNumber)/results")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get tracking results for an existing tracker
#
# GET /public/v1/trackers/{trackerId}/results
# operationId: get-tracking-results-of-tracker-by-trackerId
export def "public-trackers-results get-tracking-results-of-tracker-by-trackerId" [
  trackerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --searchBy: string@searchBy-completer # Parameter allowing to search either by `trackerId`or `clientTrackerId`. Default behavior is by `trackerId`. (e.g. trackerId)
  --Authorization: string # Your `api_key` prefixed with `Bearer`. (e.g. Bearer your_api_key)
]: nothing -> record<data: record<trackings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer your_api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchBy" $searchBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/v1/trackers/($trackerId)/results" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all couriers
#
# GET /public/v1/couriers
# operationId: get-couriers
export def "public-couriers get-couriers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Your `api_key` prefixed with `Bearer`. (e.g. Bearer your_api_key)
]: nothing -> record<data: record<couriers: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer your_api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/couriers")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get tracking results by tracking number
#
# POST /public/v1/tracking/search
# operationId: get-tracking
export def "public-tracking-search get-tracking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # e.g. application/json; charset=utf-8
  --Authorization: string # Your `api_key` prefixed with `Bearer`. (e.g. Bearer your_api_key)
  --trackingNumber: string # Tracking number of the shipment. (e.g. 9400115901047177598206)
  --originCountryCode: string # Sender country code - 📌 Recommended to improve tracking accuracy (format: ISO 3166-1 alpha-2/alpha-3, e.g. CN)
  --destinationCountryCode: string # Recipient country code - 📌 Recommended to improve tracking accuracy (format: ISO 3166-1 alpha-2/alpha-3, e.g. US)
  --destinationPostCode: string # Recipient Post code (or ZIP code) - 📌 Recommended to improve tracking accuracy (e.g. 94901)
  --shippingDate: string # Date at which the shipment has been shipped  - 📌 Recommended to improve tracking accuracy: providing the shipping date helps us accurately identify the shipment and improves our ability to retrieve the correct data. However, an inaccurate shipping date could cause our system to exclude the right shipment. Therefore, please ensure the provided shipping date aligns closely with the actual shipment date, give or take a few days. [Format](http://docs.ship24.com/data-format#logistics-date-and-time) (format: date-time)
  --courierCode: list # Code of the courier(s) handling the shipment (Up to 3 max) (see Couriers list section)  - 📌 Recommended to improve tracking accuracy
]: any -> record<data: record<trackings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer your_api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/tracking/search")
  let body = {trackingNumber: $trackingNumber, originCountryCode: $originCountryCode, destinationCountryCode: $destinationCountryCode, destinationPostCode: $destinationPostCode, shippingDate: $shippingDate, courierCode: $courierCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resend webhooks of an existing tracker
#
# POST /public/v1/trackers/{trackerId}/webhook-events/resend
# operationId: resend-webhooks
export def "public-trackers-webhook-events-resend resend-webhooks" [
  trackerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --searchBy: string@searchBy-completer # Parameter allowing to search either by `trackerId`or `clientTrackerId`. Default behavior is by `trackerId`. (e.g. trackerId)
  --Authorization: string # Your `api_key` prefixed with `Bearer`. (e.g. Bearer your_api_key)
]: nothing -> record<data: record<summary: record<totalResent: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer your_api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchBy" $searchBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/v1/trackers/($trackerId)/webhook-events/resend" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
