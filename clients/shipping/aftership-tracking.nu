# Auto-generated client for API Overview v1.0
# Source: https://stoplight.io/api/v1/projects/automizely/docs-api-aftership-com/nodes/reference/api.json?branch=production/2026-01&deref=optimizedBundle
# Auth: --token flag or $env.API_OVERVIEW_TOKEN

const BASE_URL = "https://api.aftership.com/tracking/2026-01"
const DEFAULT_AUTH = "as-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_OVERVIEW_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "as-api-key" => { {headers: {as-api-key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.aftership.com/tracking/2026-01"] }
def auth-scheme-completer [] { ["as-api-key"] }

# Completers for enum parameters
def tag-completer [] { ["AttemptFail" "AvailableForPickup" "Delivered" "Exception" "Expired" "InTransit" "InfoReceived" "OutForDelivery" "Pending"] }
def Content-Type-completer [] { ["application/json"] }
def delivery-type-completer [] { ["door_to_door" "pickup_at_courier" "pickup_at_store"] }
def reason-completer [] { ["DELIVERED" "LOST" "RETURNED_TO_SENDER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "trackings get-trackings" } } | get name | first)
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

# Get trackings
#
# GET /trackings
# operationId: get-trackings
export def "trackings get-trackings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A string representing the cursor value for the current page of results. (e.g. WzE3MTk5OTIwMzIzNTMsImE0NWQ5NDg5ODU4NzQzMjA5YjBjYjRlZjE3ZTBjNGVhIl0=)
  --limit: int # Number of trackings each page contain. (Default: 100, Max: 200) (default: 100, e.g. 100)
  --keyword: string # Search the content of the tracking record fields: `tracking_number`, `title`, `order_id`, `customers[x].name`, `custom_fields`, `customers[x].email`, `customers[x].phone_number` (e.g. RA123456789US)
  --tracking-numbers: string # Tracking number of shipments. Use comma to separate multiple values (Example: RA123456789US,LE123456789US). Supports up to 50 tracking numbers. (e.g. RA123456789US,LE123456789US)
  --slug: string # Unique courier code Use comma for multiple values. (Example: dhl,ups,usps) (e.g. usps)
  --transit-time: int # Total delivery time in days.  - When the shipment is delivered: Transit time = Delivered date - Picked up date - When the shipment is not delivered: Transit time = Current date - Picked up date  Value as `null` for the shipment without pickup date. (e.g. 1)
  --origin: string # Origin country/region of trackings. Use ISO Alpha-3 (three letters). Use comma for multiple values. (Example: USA,HKG) (e.g. USA)
  --destination: string # Destination country/region of trackings. Use ISO Alpha-3 (three letters). Use comma for multiple values. (Example: USA,HKG) (e.g. USA)
  --tag: string@tag-completer # Current status of tracking. Values include `Pending`, `InfoReceived`, `InTransit`, `OutForDelivery`, `AttemptFail`, `Delivered`, `AvailableForPickup`, `Exception`, `Expired` (See tag definition) (e.g. InTransit)
  --created-at-min: string # Start date and time of trackings created. AfterShip only stores data of 120 days. Please make sure the value of the parameter is properly escaped in [URL encoding](https://en.wikipedia.org/wiki/Percent-encoding).(Defaults: 120 days ago, Example: The escaped value of 2013-03-15T16:41:56+08:00 is 2013-03-15T16:41:56%2B08:00) (e.g. 2013-03-15T16:41:56%2B08:00)
  --created-at-max: string # End date and time of trackings created. Please make sure the value of the parameter is properly escaped in [URL encoding](https://en.wikipedia.org/wiki/Percent-encoding).(Defaults: now, Example: The escaped value of 2013-04-15T16:41:56+08:00 is 2013-04-15T16:41:56%2B08:00) (e.g. 2013-03-15T16:41:56%2B08:00)
  --updated-at-min: string # Start date and time of trackings updated. Please make sure the value of the parameter is properly escaped in [URL encoding](https://en.wikipedia.org/wiki/Percent-encoding).(Example: The escaped value of 2013-03-15T16:41:56+08:00 is 2013-03-15T16:41:56%2B08:00) (e.g. 2013-03-15T16:41:56%2B08:00)
  --updated-at-max: string # End date and time of trackings updated. Please make sure the value of the parameter is properly escaped in [URL encoding](https://en.wikipedia.org/wiki/Percent-encoding).(Example: The escaped value of 2013-04-15T16:41:56+08:00 is 2013-04-15T16:41:56%2B08:00) (e.g. 2013-03-15T16:41:56%2B08:00)
  --qp-fields: string # List of fields to include in the response. Use comma for multiple values. Available options: `title`, `order_id`, `tag`, `checkpoints`. Example: `title,order_id` (e.g. title)
  --return-to-sender: string # Select return to sender, the value should be `true` or `false`, with optional comma separated. (e.g. true)
  --courier-destination-country-region: string # Destination country/region of trackings returned by courier. Use ISO Alpha-3 (three letters). Use comma for multiple values. (Example: USA,HKG) (e.g. USA)
  --shipment-tags: string # Tags you added to your shipments to help categorize and filter them easily. Use a comma to separate multiple values (Example: a,b)
  --order-id: string # A globally-unique identifier for the order. Use comma for multiple values.(Example: 6845a095a27a4caeb27487806f058add,4845a095a27a4caeb27487806f058abc) (e.g. 6845a095a27a4caeb27487806f058add)
  --Content-Type: string@Content-Type-completer # Content-Type  (e.g. application/json)
]: nothing -> record<meta: record<code: int, message: string, type: string>, data: record<pagination: record<total: int, next_cursor: string, has_next_page: bool>, trackings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "as-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "tracking_numbers" $tracking_numbers "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "transit_time" $transit_time "scalar") (serialize-qp "origin" $origin "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "created_at_min" $created_at_min "scalar") (serialize-qp "created_at_max" $created_at_max "scalar") (serialize-qp "updated_at_min" $updated_at_min "scalar") (serialize-qp "updated_at_max" $updated_at_max "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "return_to_sender" $return_to_sender "scalar") (serialize-qp "courier_destination_country_region" $courier_destination_country_region "scalar") (serialize-qp "shipment_tags" $shipment_tags "scalar") (serialize-qp "order_id" $order_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/trackings" $qp)
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a tracking
#
# POST /trackings
# operationId: create-tracking
# --order_promised_delivery_date shape: {promised_delivery_date?: string, promised_delivery_date_min?: string, promised_delivery_date_max?: string}
# --last_mile shape: {tracking_number: string, slug: string}
# --customers item shape: {role?: string, name?: string, phone_number?: string, email?: string, language?: string}
export def "trackings create-tracking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Content-Type
  --id: string # Tracking ID that is system-generated by default and can be customized by the user when creating a tracking. (e.g. bff5a3bac79b472991a204172473a635)
  tracking_number: string # Tracking number of a shipment.  Duplicated tracking numbers, tracking numbers with invalid tracking number format will not be accepted.  We only accept tracking numbers with length from 4 to 100  We currently support the following characters in a tracking number:  - A - Z - 0 - 9 - `-` (Hyphen) - . (Period) - _ (Underscore) - / (Slash)
  --slug: string # Unique courier code. Get courier codes [here](https://www.aftership.com/docs/tracking/others/supported-couriers).
  --title: string # By default this field shows the `tracking_number`, but you can customize it as you wish with any info (e.g. the order number).
  --order-id: string # A globally-unique identifier for the order.
  --custom-fields: record # Custom fields that accept an object with string field. In order to protect the privacy of your customers, do not include any [personal data](https://www.aftership.com/legal/dpa#:~:text=Personal%20Data%20means,that%20natural%20person) in custom fields.  - Maximum charater limit for a key name: 30 - Maximum count for a key-value pair in a custom field object: 25 - Maximum value length: 512 charaters - Supported value type: String only (object and array are prohibted)
  --order-id-path: string # The URL for the order in your system or store.
  --language: string # The recipient’s language. If you set up AfterShip notifications in different languages, we use this to send the recipient tracking updates in their preferred language. Use an [ISO 639-1 Language Code](https://help.aftership.com/hc/en-us/articles/360001623287-Supported-Language-Parameters) to specify the language.
  --order-promised-delivery-date: record # The promised delivery date of the order in shipment recipient’s timezone. — shape: {promised_delivery_date?: string, promised_delivery_date_min?: string, promised_delivery_date_max?: string}
  --pickup-location: string # Shipment pickup location for receiver
  --delivery-type: string@delivery-type-completer # Shipment delivery type  - pickup_at_store - pickup_at_courier - door_to_door
  --pickup-note: string # Shipment pickup note for receiver
  --tracking-account-number: string # Additional field required by some carriers to retrieve the tracking info. The shipper’s carrier account number. Refer to our article on [additional tracking fields](../../docs/enum/additional_tracking_fields.md) for more details.
  --tracking-key: string # Additional field required by some carriers to retrieve the tracking info. A type of tracking credential required by some carriers. Refer to our article on [additional tracking fields](../../docs/enum/additional_tracking_fields.md) for more details.
  --tracking-ship-date: string # The date and time when the shipment is shipped by the merchant and ready for pickup by the carrier. The field supports the following formats: - YYYY-MM-DD - YYYY-MM-DDTHH:mm:ss - YYYY-MM-DDTHH:mm:ssZ The field serves two key purposes: - Calculate processing time metrics in the Order-to-delivery Analytics dashboard. To ensure accurate analytics, it's recommended to include timezone information when configuring this value - Required by certain carriers to retrieve tracking information as an additional tracking field.
  --origin-country-region: string # The [ISO Alpha-3](https://support.aftership.com/en/article/iso3-country-code-rlpi07/) code (3 letters) for the origin country/region. E.g. USA for the United States. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. Also the additional field required by some carriers to retrieve the tracking info. The origin country/region of the shipment. Refer to our article on [additional tracking fields](../../docs/enum/additional_tracking_fields.md) for more details. (e.g. CHN)
  --origin-state: string # The state of the sender’s address. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. (e.g. Beijing)
  --origin-city: string # The city of the sender’s address. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. (e.g. Beijing)
  --origin-postal-code: string # The postal of the sender’s address. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. (e.g. 065001)
  --origin-raw-location: string # The sender address that the shipment is shipping from. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. (e.g. Lihong Gardon 4A 2301, Chaoyang District, Beijing, BJ, 065001, CHN, China)
  --destination-country-region: string # The [ISO Alpha-3](https://support.aftership.com/en/article/iso3-country-code-rlpi07/) code (3 letters) for the destination country/region. E.g. USA for the United States. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. Also the additional field required by some carriers to retrieve the tracking info. The destination country/region of the shipment. Refer to our article on [additional tracking fields](../../docs/enum/additional_tracking_fields.md) for more details. (e.g. USA)
  --destination-state: string # The state of the recipient’s address. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. Also the additional field required by some carriers to retrieve the tracking info. The state/province of the recipient’s address. Refer to our article on [additional tracking fields](../../docs/enum/additional_tracking_fields.md) for more details. (e.g. New York)
  --destination-city: string # The city of the recipient’s address. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. (e.g. New York City)
  --destination-postal-code: string # The postal of the recipient’s address. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. Also the additional field required by some carriers to retrieve the tracking info. The postal code of the recipient’s address. Refer to our article on [additional tracking fields](../../docs/enum/additional_tracking_fields.md) for more details. (e.g. 10001)
  --destination-raw-location: string # The shipping address that the shipment is shipping to. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. (e.g. 13th Street, New York, NY, 10011, USA, United States)
  --note: string # Text field for the note
  --slug-group: string # Slug group is a group of slugs which belong to same courier. For example, when you inpit "fedex-group" as slug_group, AfterShip will detect the tracking with "fedex-uk", "fedex-fims", and other slugs which belong to "fedex". It cannot be used with slug at the same time. ([See slug_groups definition](../../docs/enum/slug_groups.md)) (e.g. fedex-group)
  --order-date: string # Order date in YYYY-MM-DDTHH:mm:ssZ format. e.g. 2021-07-26T11:23:51-05:00
  --order-number: string # A unique, human-readable identifier for the order.
  --shipment-type: string # The carrier service type for the shipment. If you provide info for this field, AfterShip will not update it with info from the carrier.
  --shipment-tags: list # Used to add tags to your shipments to help categorize and filter them easily.
  --courier-connection-id: string # If you’ve connected multiple accounts for a single carrier on AfterShip, you can now use the courier_connection_id field to tell AfterShip which carrier account you’ve used to handle a shipment so we can track it. ([Get your courier connection id](https://admin.aftership.com/carrier-connection))
  --location-id: string # The location_id refers to the place where you fulfilled the items.   - If you provide a location_id, the system will automatically use it as the tracking's origin address. However, passing both location_id and any origin address information simultaneously is not allowed. - Please make sure you add your locations [here](https://admin.aftership.com/settings/locations-and-rules) before passing the location_id and verify that the location's status is active. Learn more about adding locations [here](https://support.aftership.com/en/article/manage-ship-from-locations-via-aftership-tracking-okbhj4/?bust=1702871142396).
  --shipping-method: string # The shipping_method string refers to the chosen method for delivering the package. Merchants typically offer various shipping methods to consumers during the checkout process, such as, Local Delivery, Free Express Worldwide Shipping, etc
  --last-mile: record # This field contains information about the last leg of the shipment, starting from the carrier who hands it over to the last-mile carrier, all the way to delivery. Once AfterShip detects that the shipment involves multiple legs and identifies the last-mile carrier, we will populate the last-mile carrier information in this object. Alternatively, the user can provide this information in this field to specify the last-mile carrier, which is helpful if AfterShip is unable to detect it automatically. — shape: {tracking_number: string, slug: string}
  --customers: list # The field contains the customer information associated with the tracking. A maximum of three customer objects are allowed. — item shape: {role?: string, name?: string, phone_number?: string, email?: string, language?: string}
]: any -> record<meta: record<code: int, message: string, type: string>, data: record<id: string, legacy_id: string, created_at: string, updated_at: string, tracking_number: string, slug: string, active: bool, custom_fields: record, transit_time: int, origin_country_region: string, origin_state: string, origin_city: string, origin_postal_code: string, origin_raw_location: string, destination_country_region: string, destination_state: string, destination_city: string, destination_postal_code: string, destination_raw_location: string, courier_destination_country_region: string, courier_estimated_delivery_date: record<estimated_delivery_date: string, estimated_delivery_date_min: string, estimated_delivery_date_max: string>, note: string, order_id: string, order_id_path: string, order_date: string, shipment_package_count: float, shipment_pickup_date: string, shipment_delivery_date: string, shipment_type: string, shipment_weight: record<unit: string, value: float>, signed_by: string, source: string, tag: string, subtag: string, subtag_message: string, title: string, tracked_count: float, language: string, unique_token: string, checkpoints: list<record>, subscribed_smses: list<string>, subscribed_emails: list<string>, return_to_sender: bool, order_promised_delivery_date: record<promised_delivery_date: string, promised_delivery_date_min: string, promised_delivery_date_max: string>, delivery_type: string, pickup_location: string, pickup_note: string, courier_tracking_link: string, first_attempted_at: string, courier_redirect_link: string, tracking_account_number: string, tracking_key: string, tracking_ship_date: string, on_time_status: string, on_time_difference: float, order_tags: list<string>, aftership_estimated_delivery_date: record<estimated_delivery_date: string, confidence_code: float, estimated_delivery_date_min: string, estimated_delivery_date_max: string>, custom_estimated_delivery_date: record<type: string, datetime: string, datetime_min: string, datetime_max: string>, order_number: string, first_estimated_delivery: record<type: string, source: string, datetime: string, datetime_min: string, datetime_max: string>, latest_estimated_delivery: record<type: string, source: string, datetime: string, datetime_min: string, datetime_max: string, revise_reason: string>, shipment_tags: list<string>, courier_connection_id: string, carbon_emissions: record<unit: string, value: float>, location_id: string, shipping_method: string, failed_delivery_attempts: int, signature_requirement: string, delivery_location_type: string, aftership_tracking_url: string, aftership_tracking_order_url: string, first_mile: record<tracking_number: string, slug: string, transit_time: int, courier_redirect_link: string, courier_tracking_link: string>, last_mile: record<tracking_number: string, slug: string, transit_time: int, courier_tracking_link: string, courier_redirect_link: string, source: any>, customers: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "as-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/trackings")
  let body = {id: $id, tracking_number: $tracking_number, slug: $slug, title: $title, order_id: $order_id, custom_fields: $custom_fields, order_id_path: $order_id_path, language: $language, order_promised_delivery_date: $order_promised_delivery_date, pickup_location: $pickup_location, delivery_type: $delivery_type, pickup_note: $pickup_note, tracking_account_number: $tracking_account_number, tracking_key: $tracking_key, tracking_ship_date: $tracking_ship_date, origin_country_region: $origin_country_region, origin_state: $origin_state, origin_city: $origin_city, origin_postal_code: $origin_postal_code, origin_raw_location: $origin_raw_location, destination_country_region: $destination_country_region, destination_state: $destination_state, destination_city: $destination_city, destination_postal_code: $destination_postal_code, destination_raw_location: $destination_raw_location, note: $note, slug_group: $slug_group, order_date: $order_date, order_number: $order_number, shipment_type: $shipment_type, shipment_tags: $shipment_tags, courier_connection_id: $courier_connection_id, location_id: $location_id, shipping_method: $shipping_method, last_mile: $last_mile, customers: $customers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a tracking by ID
#
# GET /trackings/{id}
# operationId: get-tracking-by-id
export def "trackings get-tracking-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # List of fields to include in the response. Use comma for multiple values. Fields to include: `destination_postal_code`, `tracking_ship_date`, `tracking_account_number`, `tracking_key`, `origin_country_region`, `destination_country_region`, `destination_state`, `title`, `order_id`, `tag`, `checkpoints` (e.g. title,order_id)
  --lang: string # Translate checkpoint messages from the carrier’s provided language to the target language. Supported target languages include:</br>&nbsp;&nbsp;&nbsp;&nbsp;- English (en)</br>&nbsp;&nbsp;&nbsp;&nbsp;- French (fr)</br>&nbsp;&nbsp;&nbsp;&nbsp;- French Canadian (fr-CA)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Arabic (ar)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Bulgarian (bg)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Catalan (ca)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Croatian (hr)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Czech (cs)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Danish (da)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Dutch (nl)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Estonian (et)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Filipino (tl)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Finnish (fi)</br>&nbsp;&nbsp;&nbsp;&nbsp;- German (de)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Greek (el)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Hebrew (he)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Hindi (hi)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Hungarian (hu)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Indonesian (id)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Italian (it)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Japanese (ja)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Korean (ko)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Latvian (lv)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Lithuanian (lt)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Malay (ms)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Polish (pl)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Portuguese (pt)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Romanian (ro)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Russian (ru)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Serbian (sr)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Slovak (sk)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Slovenian (sl)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Spanish (es)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Swedish (sv)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Thai (th)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Turkish (tr)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Ukrainian (uk)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Vietnamese (vi)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Simplified Chinese (zh-Hans)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Traditional Chinese (zh-Hant)</br>&nbsp;&nbsp;&nbsp;&nbsp;- Norwegian (nb)</br> (e.g. en)
  --Content-Type: string@Content-Type-completer # Content-Type
]: nothing -> record<meta: record<code: int, message: string, type: string>, data: record<id: string, legacy_id: string, created_at: string, updated_at: string, tracking_number: string, slug: string, active: bool, custom_fields: record, transit_time: int, origin_country_region: string, origin_state: string, origin_city: string, origin_postal_code: string, origin_raw_location: string, destination_country_region: string, destination_state: string, destination_city: string, destination_postal_code: string, destination_raw_location: string, courier_destination_country_region: string, courier_estimated_delivery_date: record<estimated_delivery_date: string, estimated_delivery_date_min: string, estimated_delivery_date_max: string>, note: string, order_id: string, order_id_path: string, order_date: string, shipment_package_count: float, shipment_pickup_date: string, shipment_delivery_date: string, shipment_type: string, shipment_weight: record<unit: string, value: float>, signed_by: string, source: string, tag: string, subtag: string, subtag_message: string, title: string, tracked_count: float, language: string, unique_token: string, checkpoints: list<record>, subscribed_smses: list<string>, subscribed_emails: list<string>, return_to_sender: bool, order_promised_delivery_date: record<promised_delivery_date: string, promised_delivery_date_min: string, promised_delivery_date_max: string>, delivery_type: string, pickup_location: string, pickup_note: string, courier_tracking_link: string, first_attempted_at: string, courier_redirect_link: string, tracking_account_number: string, tracking_key: string, tracking_ship_date: string, on_time_status: string, on_time_difference: float, order_tags: list<string>, aftership_estimated_delivery_date: record<estimated_delivery_date: string, confidence_code: float, estimated_delivery_date_min: string, estimated_delivery_date_max: string>, custom_estimated_delivery_date: record<type: string, datetime: string, datetime_min: string, datetime_max: string>, order_number: string, first_estimated_delivery: record<type: string, source: string, datetime: string, datetime_min: string, datetime_max: string>, latest_estimated_delivery: record<type: string, source: string, datetime: string, datetime_min: string, datetime_max: string, revise_reason: string>, shipment_tags: list<string>, courier_connection_id: string, carbon_emissions: record<unit: string, value: float>, location_id: string, shipping_method: string, failed_delivery_attempts: int, signature_requirement: string, delivery_location_type: string, aftership_tracking_url: string, aftership_tracking_order_url: string, first_mile: record<tracking_number: string, slug: string, transit_time: int, courier_redirect_link: string, courier_tracking_link: string>, last_mile: record<tracking_number: string, slug: string, transit_time: int, courier_tracking_link: string, courier_redirect_link: string, source: any>, customers: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "as-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/trackings/($id)" $qp)
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a tracking by ID
#
# PUT /trackings/{id}
# operationId: update-tracking-by-id
# --order_promised_delivery_date shape: {promised_delivery_date?: string, promised_delivery_date_min?: string, promised_delivery_date_max?: string}
# --customers item shape: {role?: string, name?: string, phone_number?: string, email?: string, language?: string}
export def "trackings update-tracking-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Content-Type
  --title: string # By default this field shows the `tracking_number`, but you can customize it as you wish with any info (e.g. the order number).
  --order-id: string # A globally-unique identifier for the order.
  --order-id-path: string # The URL for the order in your system or store.
  --custom-fields: record # Custom fields that accept an object with string field. In order to protect the privacy of your customers, do not include any [personal data](https://www.aftership.com/legal/dpa#:~:text=Personal%20Data%20means,that%20natural%20person) in custom fields.  - Maximum charater limit for a key name: 30 - Maximum count for a key-value pair in a custom field object: 25 - Maximum value length: 512 charaters - Supported value type: String only (object and array are prohibted)
  --note: string # Text field for the note. Input `""` to clear the value of this field.
  --language: string # The recipient’s language. If you set up AfterShip notifications in different languages, we use this to send the recipient tracking updates in their preferred language. Use an [ISO 639-1 Language Code](https://help.aftership.com/hc/en-us/articles/360001623287-Supported-Language-Parameters) to specify the language.
  --order-promised-delivery-date: record # The promised delivery date of the order in shipment recipient’s timezone. — shape: {promised_delivery_date?: string, promised_delivery_date_min?: string, promised_delivery_date_max?: string}
  --delivery-type: string@delivery-type-completer # Shipment delivery type  - `pickup_at_store` - `pickup_at_courier` - `door_to_door`
  --pickup-location: string # Shipment pickup location for receiver
  --pickup-note: string # Shipment pickup note for receiver
  --slug: string # Unique code of each courier. Provide a single courier.(https://admin.aftership.com/settings/couriers). Get a list of courier slug using [GET /couriers](./api.json/paths/~1couriers/get)
  --tracking-account-number: string # Additional field required by some carriers to retrieve the tracking info. The shipper’s carrier account number. Refer to our article on [additional tracking fields](../../docs/enum/additional_tracking_fields.md) for more details.
  --tracking-key: string # Additional field required by some carriers to retrieve the tracking info. A type of tracking credential required by some carriers. Refer to our article on [additional tracking fields](../../docs/enum/additional_tracking_fields.md) for more details.
  --tracking-ship-date: string # The date and time when the shipment is shipped by the merchant and ready for pickup by the carrier. The field supports the following formats: - YYYY-MM-DD - YYYY-MM-DDTHH:mm:ss - YYYY-MM-DDTHH:mm:ssZ The field serves two key purposes: - Calculate processing time metrics in the Order-to-delivery Analytics dashboard. To ensure accurate analytics, it's recommended to include timezone information when configuring this value - Required by certain carriers to retrieve tracking information as an additional tracking field.
  --order-number: string # A unique, human-readable identifier for the order.
  --order-date: string # Order date in YYYY-MM-DDTHH:mm:ssZ format. e.g. 2021-07-26T11:23:51-05:00
  --shipment-type: string # The carrier service type for the shipment. If you provide info for this field, AfterShip will not update it with info from the carrier.
  --origin-country-region: string # The [ISO Alpha-3](https://support.aftership.com/en/article/iso3-country-code-rlpi07/) code (3 letters) for the origin country/region. E.g. USA for the United States. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. Also the additional field required by some carriers to retrieve the tracking info. The origin country/region of the shipment. Refer to our article on [additional tracking fields](../../docs/enum/additional_tracking_fields.md) for more details. (e.g. CHN)
  --origin-state: string # The state of the sender’s address. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. (e.g. Beijing)
  --origin-city: string # The city of the sender’s address. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. (e.g. Beijing)
  --origin-postal-code: string # The postal of the sender’s address. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. (e.g. 065001)
  --origin-raw-location: string # The sender address that the shipment is shipping from. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. (e.g. Lihong Gardon 4A 2301, Chaoyang District, Beijing, BJ, 065001, CHN, China)
  --destination-country-region: string # The [ISO Alpha-3](https://support.aftership.com/en/article/iso3-country-code-rlpi07/) code (3 letters) for the destination country/region. E.g. USA for the United States. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. Also the additional field required by some carriers to retrieve the tracking info. The destination country/region of the shipment. Refer to our article on [additional tracking fields](../../docs/enum/additional_tracking_fields.md) for more details. (e.g. USA)
  --destination-state: string # The state of the recipient’s address. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. Also the additional field required by some carriers to retrieve the tracking info. The state/province of the recipient’s address. Refer to our article on [additional tracking fields](../../docs/enum/additional_tracking_fields.md) for more details. (e.g. New York)
  --destination-city: string # The city of the recipient’s address. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. (e.g. New York City)
  --destination-postal-code: string # The postal of the recipient’s address. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. Also the additional field required by some carriers to retrieve the tracking info. The postal code of the recipient’s address. Refer to our article on [additional tracking fields](../../docs/enum/additional_tracking_fields.md) for more details. (e.g. 10001)
  --destination-raw-location: string # The shipping address that the shipment is shipping to. This can help AfterShip with various functions like tracking, carrier auto-detection and auto-correction, calculating an EDD, etc. (e.g. 13th Street, New York, NY, 10011, USA, United States)
  --location-id: string # The location_id refers to the place where you fulfilled the items.   - If you provide a location_id, the system will automatically use it as the tracking's origin address. However, passing both location_id and any origin address information simultaneously is not allowed. - Please make sure you add your locations [here](https://admin.aftership.com/settings/locations-and-rules) before passing the location_id and verify that the location's status is active. Learn more about adding locations [here](https://support.aftership.com/en/article/manage-ship-from-locations-via-aftership-tracking-okbhj4/?bust=1702871142396).
  --shipping-method: string # The shipping_method string refers to the chosen method for delivering the package. Merchants typically offer various shipping methods to consumers during the checkout process, such as, Local Delivery, Free Express Worldwide Shipping, etc.
  --customers: list # The field contains the customer information associated with the tracking. A maximum of three customer objects are allowed. — item shape: {role?: string, name?: string, phone_number?: string, email?: string, language?: string}
]: any -> record<meta: record<code: int, message: string, type: string>, data: record<id: string, legacy_id: string, created_at: string, updated_at: string, tracking_number: string, slug: string, active: bool, custom_fields: record, transit_time: int, origin_country_region: string, origin_state: string, origin_city: string, origin_postal_code: string, origin_raw_location: string, destination_country_region: string, destination_state: string, destination_city: string, destination_postal_code: string, destination_raw_location: string, courier_destination_country_region: string, courier_estimated_delivery_date: record<estimated_delivery_date: string, estimated_delivery_date_min: string, estimated_delivery_date_max: string>, note: string, order_id: string, order_id_path: string, order_date: string, shipment_package_count: float, shipment_pickup_date: string, shipment_delivery_date: string, shipment_type: string, shipment_weight: record<unit: string, value: float>, signed_by: string, source: string, tag: string, subtag: string, subtag_message: string, title: string, tracked_count: float, language: string, unique_token: string, checkpoints: list<record>, subscribed_smses: list<string>, subscribed_emails: list<string>, return_to_sender: bool, order_promised_delivery_date: record<promised_delivery_date: string, promised_delivery_date_min: string, promised_delivery_date_max: string>, delivery_type: string, pickup_location: string, pickup_note: string, courier_tracking_link: string, first_attempted_at: string, courier_redirect_link: string, tracking_account_number: string, tracking_key: string, tracking_ship_date: string, on_time_status: string, on_time_difference: float, order_tags: list<string>, aftership_estimated_delivery_date: record<estimated_delivery_date: string, confidence_code: float, estimated_delivery_date_min: string, estimated_delivery_date_max: string>, custom_estimated_delivery_date: record<type: string, datetime: string, datetime_min: string, datetime_max: string>, order_number: string, first_estimated_delivery: record<type: string, source: string, datetime: string, datetime_min: string, datetime_max: string>, latest_estimated_delivery: record<type: string, source: string, datetime: string, datetime_min: string, datetime_max: string, revise_reason: string>, shipment_tags: list<string>, courier_connection_id: string, carbon_emissions: record<unit: string, value: float>, location_id: string, shipping_method: string, failed_delivery_attempts: int, signature_requirement: string, delivery_location_type: string, aftership_tracking_url: string, aftership_tracking_order_url: string, first_mile: record<tracking_number: string, slug: string, transit_time: int, courier_redirect_link: string, courier_tracking_link: string>, last_mile: record<tracking_number: string, slug: string, transit_time: int, courier_tracking_link: string, courier_redirect_link: string, source: any>, customers: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "as-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/trackings/($id)")
  let body = {title: $title, order_id: $order_id, order_id_path: $order_id_path, custom_fields: $custom_fields, note: $note, language: $language, order_promised_delivery_date: $order_promised_delivery_date, delivery_type: $delivery_type, pickup_location: $pickup_location, pickup_note: $pickup_note, slug: $slug, tracking_account_number: $tracking_account_number, tracking_key: $tracking_key, tracking_ship_date: $tracking_ship_date, order_number: $order_number, order_date: $order_date, shipment_type: $shipment_type, origin_country_region: $origin_country_region, origin_state: $origin_state, origin_city: $origin_city, origin_postal_code: $origin_postal_code, origin_raw_location: $origin_raw_location, destination_country_region: $destination_country_region, destination_state: $destination_state, destination_city: $destination_city, destination_postal_code: $destination_postal_code, destination_raw_location: $destination_raw_location, location_id: $location_id, shipping_method: $shipping_method, customers: $customers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a tracking by ID
#
# DELETE /trackings/{id}
# operationId: delete-tracking-by-id
export def "trackings delete-tracking-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Content-Type
]: nothing -> record<meta: record<code: int, message: string, type: string>, data: record<id: string, legacy_id: string, created_at: string, updated_at: string, tracking_number: string, slug: string, active: bool, custom_fields: record, transit_time: int, origin_country_region: string, origin_state: string, origin_city: string, origin_postal_code: string, origin_raw_location: string, destination_country_region: string, destination_state: string, destination_city: string, destination_postal_code: string, destination_raw_location: string, courier_destination_country_region: string, courier_estimated_delivery_date: record<estimated_delivery_date: string, estimated_delivery_date_min: string, estimated_delivery_date_max: string>, note: string, order_id: string, order_id_path: string, order_date: string, shipment_package_count: float, shipment_pickup_date: string, shipment_delivery_date: string, shipment_type: string, shipment_weight: record<unit: string, value: float>, signed_by: string, source: string, tag: string, subtag: string, subtag_message: string, title: string, tracked_count: float, language: string, unique_token: string, checkpoints: list<record>, subscribed_smses: list<string>, subscribed_emails: list<string>, return_to_sender: bool, order_promised_delivery_date: record<promised_delivery_date: string, promised_delivery_date_min: string, promised_delivery_date_max: string>, delivery_type: string, pickup_location: string, pickup_note: string, courier_tracking_link: string, first_attempted_at: string, courier_redirect_link: string, tracking_account_number: string, tracking_key: string, tracking_ship_date: string, on_time_status: string, on_time_difference: float, order_tags: list<string>, aftership_estimated_delivery_date: record<estimated_delivery_date: string, confidence_code: float, estimated_delivery_date_min: string, estimated_delivery_date_max: string>, custom_estimated_delivery_date: record<type: string, datetime: string, datetime_min: string, datetime_max: string>, order_number: string, first_estimated_delivery: record<type: string, source: string, datetime: string, datetime_min: string, datetime_max: string>, latest_estimated_delivery: record<type: string, source: string, datetime: string, datetime_min: string, datetime_max: string, revise_reason: string>, shipment_tags: list<string>, courier_connection_id: string, carbon_emissions: record<unit: string, value: float>, location_id: string, shipping_method: string, failed_delivery_attempts: int, signature_requirement: string, delivery_location_type: string, aftership_tracking_url: string, aftership_tracking_order_url: string, first_mile: record<tracking_number: string, slug: string, transit_time: int, courier_redirect_link: string, courier_tracking_link: string>, last_mile: record<tracking_number: string, slug: string, transit_time: int, courier_tracking_link: string, courier_redirect_link: string, source: any>, customers: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "as-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/trackings/($id)")
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrack an expired tracking by ID
#
# POST /trackings/{id}/retrack
# operationId: retrack-tracking-by-id
export def "trackings-retrack retrack-tracking-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Content-Type
]: nothing -> record<meta: record<code: int, message: string, type: string>, data: record<id: string, legacy_id: string, created_at: string, updated_at: string, tracking_number: string, slug: string, active: bool, custom_fields: record, transit_time: int, origin_country_region: string, origin_state: string, origin_city: string, origin_postal_code: string, origin_raw_location: string, destination_country_region: string, destination_state: string, destination_city: string, destination_postal_code: string, destination_raw_location: string, courier_destination_country_region: string, courier_estimated_delivery_date: record<estimated_delivery_date: string, estimated_delivery_date_min: string, estimated_delivery_date_max: string>, note: string, order_id: string, order_id_path: string, order_date: string, shipment_package_count: float, shipment_pickup_date: string, shipment_delivery_date: string, shipment_type: string, shipment_weight: record<unit: string, value: float>, signed_by: string, source: string, tag: string, subtag: string, subtag_message: string, title: string, tracked_count: float, language: string, unique_token: string, checkpoints: list<record>, subscribed_smses: list<string>, subscribed_emails: list<string>, return_to_sender: bool, order_promised_delivery_date: record<promised_delivery_date: string, promised_delivery_date_min: string, promised_delivery_date_max: string>, delivery_type: string, pickup_location: string, pickup_note: string, courier_tracking_link: string, first_attempted_at: string, courier_redirect_link: string, tracking_account_number: string, tracking_key: string, tracking_ship_date: string, on_time_status: string, on_time_difference: float, order_tags: list<string>, aftership_estimated_delivery_date: record<estimated_delivery_date: string, confidence_code: float, estimated_delivery_date_min: string, estimated_delivery_date_max: string>, custom_estimated_delivery_date: record<type: string, datetime: string, datetime_min: string, datetime_max: string>, order_number: string, first_estimated_delivery: record<type: string, source: string, datetime: string, datetime_min: string, datetime_max: string>, latest_estimated_delivery: record<type: string, source: string, datetime: string, datetime_min: string, datetime_max: string, revise_reason: string>, shipment_tags: list<string>, courier_connection_id: string, carbon_emissions: record<unit: string, value: float>, location_id: string, shipping_method: string, failed_delivery_attempts: int, signature_requirement: string, delivery_location_type: string, aftership_tracking_url: string, aftership_tracking_order_url: string, first_mile: record<tracking_number: string, slug: string, transit_time: int, courier_redirect_link: string, courier_tracking_link: string>, last_mile: record<tracking_number: string, slug: string, transit_time: int, courier_tracking_link: string, courier_redirect_link: string, source: any>, customers: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "as-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/trackings/($id)/retrack")
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark tracking as completed by ID
#
# POST /trackings/{id}/mark-as-completed
# operationId: mark-tracking-completed-by-id
export def "trackings-mark-as-completed mark-tracking-completed-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Content-Type
  reason: string@reason-completer # One of `DELIVERED`, `LOST` or `RETURNED_TO_SENDER`.  - Mark the tracking as completed with `DELIVERED`. The tag of the tracking will be updated to `Delivered` and the subtag will be updated to `Delivered_001`. - Mark the tracking as completed with `LOST`. The tag of the tracking will be updated to `Exception` and the subtag will be updated to `Exception_013`. - Mark the tracking as completed with `RETURNED_TO_SENDER`. The tag of the tracking will be updated to `Exception` and the subtag will be updated to `Exception_011`.
  --event-datetime: string # The actual occurrence time of the marked tracking status. The field supports the following formats:  - YYYY-MM-DD - YYYY-MM-DDTHH:mm:ss - YYYY-MM-DDTHH:mm:ssZ
]: any -> record<meta: record<code: int, message: string, type: string>, data: record<id: string, legacy_id: string, created_at: string, updated_at: string, tracking_number: string, slug: string, active: bool, custom_fields: record, transit_time: int, origin_country_region: string, origin_state: string, origin_city: string, origin_postal_code: string, origin_raw_location: string, destination_country_region: string, destination_state: string, destination_city: string, destination_postal_code: string, destination_raw_location: string, courier_destination_country_region: string, courier_estimated_delivery_date: record<estimated_delivery_date: string, estimated_delivery_date_min: string, estimated_delivery_date_max: string>, note: string, order_id: string, order_id_path: string, order_date: string, shipment_package_count: float, shipment_pickup_date: string, shipment_delivery_date: string, shipment_type: string, shipment_weight: record<unit: string, value: float>, signed_by: string, source: string, tag: string, subtag: string, subtag_message: string, title: string, tracked_count: float, language: string, unique_token: string, checkpoints: list<record>, subscribed_smses: list<string>, subscribed_emails: list<string>, return_to_sender: bool, order_promised_delivery_date: record<promised_delivery_date: string, promised_delivery_date_min: string, promised_delivery_date_max: string>, delivery_type: string, pickup_location: string, pickup_note: string, courier_tracking_link: string, first_attempted_at: string, courier_redirect_link: string, tracking_account_number: string, tracking_key: string, tracking_ship_date: string, on_time_status: string, on_time_difference: float, order_tags: list<string>, aftership_estimated_delivery_date: record<estimated_delivery_date: string, confidence_code: float, estimated_delivery_date_min: string, estimated_delivery_date_max: string>, custom_estimated_delivery_date: record<type: string, datetime: string, datetime_min: string, datetime_max: string>, order_number: string, first_estimated_delivery: record<type: string, source: string, datetime: string, datetime_min: string, datetime_max: string>, latest_estimated_delivery: record<type: string, source: string, datetime: string, datetime_min: string, datetime_max: string, revise_reason: string>, shipment_tags: list<string>, courier_connection_id: string, carbon_emissions: record<unit: string, value: float>, location_id: string, shipping_method: string, failed_delivery_attempts: int, signature_requirement: string, delivery_location_type: string, aftership_tracking_url: string, aftership_tracking_order_url: string, first_mile: record<tracking_number: string, slug: string, transit_time: int, courier_redirect_link: string, courier_tracking_link: string>, last_mile: record<tracking_number: string, slug: string, transit_time: int, courier_tracking_link: string, courier_redirect_link: string, source: any>, customers: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "as-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/trackings/($id)/mark-as-completed")
  let body = {reason: $reason, event_datetime: $event_datetime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get couriers
#
# GET /couriers
# operationId: get-couriers
export def "couriers get-couriers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool> # get user activated couriers
  --slug: string # Unique courier code Use comma for multiple values. (Example: dhl,ups,usps) (e.g. usps)
  --Content-Type: string@Content-Type-completer # Content-Type (e.g. application/json)
]: nothing -> record<meta: record<code: int, message: string, type: string>, data: record<total: int, couriers: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "as-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/couriers" $qp)
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Detect courier
#
# POST /couriers/detect
# operationId: detect-courier
export def "couriers-detect detect-courier" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Content-Type (e.g. application/json)
  tracking_number: string # Tracking number of a shipment. (e.g. RA123456879US)
  --slug: list # If not specified, Aftership will automatically detect the courier based on the tracking number format and your [selected couriers](https://admin.aftership.com/settings/couriers). Use array to input a list of couriers for auto detect. Cannot be used with slug_group at the same time.
  --destination-postal-code: string # The postal code of receiver's address. Required by some couriers. Refer to [this page](../../docs/enum/additional_tracking_fields.md) for more details
  --tracking-ship-date: string # Shipping date in `YYYYMMDD` format. Required by some couriers. Refer to [this page](../../docs/enum/additional_tracking_fields.md) for more details
  --tracking-account-number: string # Account number of the shipper for a specific courier. Required by some couriers. Refer to [this page](../../docs/enum/additional_tracking_fields.md) for more details
  --tracking-key: string # Key of the shipment for a specific courier. Required by some couriers. Refer to [this page](../../docs/enum/additional_tracking_fields.md) for more details
  --destination-state: string # State of the destination shipping address of the  shipment. Required by some couriers.
  --slug-group: string # Slug group is a group of slugs which belong to same courier. For example, when you inpit "fedex-group" as slug_group, AfterShip will detect the tracking with "fedex-uk", "fedex-fims", and other slugs which belong to "fedex". It cannot be used with slug at the same time. ([See slug_groups definition](../../docs/enum/slug_groups.md)) (e.g. fedex-group)
  --origin-country-region: string # Enter [ISO Alpha-3](https://support.aftership.com/en/article/iso3-country-code-rlpi07/) (three letters) to specify the origin of the shipment (e.g. USA for United States).
  --destination-country-region: string # Enter [ISO Alpha-3](https://support.aftership.com/en/article/iso3-country-code-rlpi07/) (three letters) to specify the destination of the shipment (e.g. USA for United States).
]: any -> record<meta: record<code: int, message: string, type: string>, data: record<total: int, couriers: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "as-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/couriers/detect")
  let body = {tracking_number: $tracking_number, slug: $slug, destination_postal_code: $destination_postal_code, tracking_ship_date: $tracking_ship_date, tracking_account_number: $tracking_account_number, tracking_key: $tracking_key, destination_state: $destination_state, slug_group: $slug_group, origin_country_region: $origin_country_region, destination_country_region: $destination_country_region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get courier connections
#
# GET /courier-connections
# operationId: get-courier-connections
export def "courier-connections get-courier-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --courier-slug: string # Unique courier code.(Example: dhl-api)
  --cursor: string # A string representing the cursor value for the current page of results.
  --limit: string # Number of courier connections each page contain. (Default: 100, Max: 200)
  --Content-Type: string # Content-Type
]: nothing -> record<meta: record<code: int, message: string, type: string>, data: record<pagination: record<total: int, next_cursor: string, has_next_page: bool>, courier_connections: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "as-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "courier_slug" $courier_slug "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/courier-connections" $qp)
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create courier connections
#
# POST /courier-connections
# operationId: post-courier-connections
export def "courier-connections post-courier-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  courier_slug: string # Unique code of courier. Get the slugs from [here](https://www.aftership.com/docs/tracking/others/supported-couriers). (e.g. ups)
  credentials: record # It refers to the authentication details required for each specific carrier details required for each specific carrier (such as API keys, username, password, etc.) that the user must provide to establish a carrier connection. The content varies by carrier.
]: any -> record<meta: record<code: int, message: string, type: string>, data: record<id: string, courier_slug: string, credentials: record, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "as-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/courier-connections")
  let body = {courier_slug: $courier_slug, credentials: $credentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get courier connection by id
#
# GET /courier-connections/{id}
# operationId: get-courier-connections-by-id
export def "courier-connections get-courier-connections-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<meta: record<code: int, message: string, type: string>, data: record<id: string, courier_slug: string, credentials: record, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "as-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/courier-connections/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update courier connection by id
#
# PATCH /courier-connections/{id}
# operationId: put-courier-connections-by-id
export def "courier-connections put-courier-connections-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  credentials: record # It refers to the authentication details required for each specific carrier details required for each specific carrier (such as API keys, username, password, etc.) that the user must provide to establish a carrier connection. The content varies by carrier.
]: any -> record<meta: record<code: int, message: string, type: string>, data: record<id: string, courier_slug: string, credentials: record, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "as-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/courier-connections/($id)")
  let body = {credentials: $credentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete courier connection by id
#
# DELETE /courier-connections/{id}
# operationId: delete-courier-connections-by-id
export def "courier-connections delete-courier-connections-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<meta: record<code: int, message: string, type: string>, data: record<id: string, courier_slug: string, credentials: record, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "as-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/courier-connections/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Prediction for the Estimated Delivery Date
#
# POST /estimated-delivery-date/predict
# operationId: predict
# --origin_address shape: {country_region: string, state?: string, city?: string, postal_code?: string, raw_location?: string}
# --destination_address shape: {country_region: string, state?: string, city?: string, postal_code?: string, raw_location?: string}
# --weight shape: {unit: string, value: float}
# --estimated_pickup shape: {order_time: string, order_cutoff_time?: string, business_days?: list, order_processing_time?: record}
export def "estimated-delivery-date-predict predict" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  slug: string # AfterShip's unique code of courier. Please refer to https://track.aftership.com/couriers/download. (e.g. fedex)
  --service-type-name: string # AfterShip’s unique code represents carrier’s shipping and delivery options. Refer to [Download Link](https://assets.aftership.com/downloads/service_type_list.csv). (nullable, e.g. FEDEX HOME DELIVERY)
  origin_address: record # The location from where the package is picked up by the carrier to be delivered to the final destination. — shape: {country_region: string, state?: string, city?: string, postal_code?: string, raw_location?: string}
  destination_address: record # The final destination of the customer where the delivery will be made. — shape: {country_region: string, state?: string, city?: string, postal_code?: string, raw_location?: string}
  --weight: record # AfterShip uses this object to calculate the total weight of the order. (nullable) — shape: {unit: string, value: float}
  --package-count: int # The number of packages. (nullable, e.g. 1)
  --pickup-time: string # The local pickup time in the origin address time zone of the package. </br><span style=color:#ff6b2b;padding:2px>**Either `pickup_time` or `estimated_pickup` is required.**</span> (nullable, e.g. 2021-07-01 06:42:30)
  --estimated-pickup: record # The local pickup time of the package. </br><span style=color:#ff6b2b;padding:2px>**Either `pickup_time` or `estimated_pickup` is required.**</span> (nullable) — shape: {order_time: string, order_cutoff_time?: string, business_days?: list, order_processing_time?: record}
]: any -> record<meta: record<code: int, message: string, type: string>, data: record<id: string, slug: string, service_type_name: string, origin_address: record<country_region: string, state: string, city: string, postal_code: string, raw_location: string>, destination_address: record<country_region: string, state: string, city: string, postal_code: string, raw_location: string>, weight: record<unit: string, value: float>, package_count: int, pickup_time: string, estimated_pickup: record<order_time: string, order_cutoff_time: string, business_days: list, order_processing_time: record, pickup_time: string>, estimated_delivery_date: string, confidence_code: float, estimated_delivery_date_min: string, estimated_delivery_date_max: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "as-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/estimated-delivery-date/predict")
  let body = {slug: $slug, service_type_name: $service_type_name, origin_address: $origin_address, destination_address: $destination_address, weight: $weight, package_count: $package_count, pickup_time: $pickup_time, estimated_pickup: $estimated_pickup} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Batch prediction for the Estimated Delivery Date
#
# POST /estimated-delivery-date/predict-batch
# operationId: predict-batch
# --estimated_delivery_dates item shape: {slug: string, service_type_name?: string, origin_address: record, destination_address: record, weight?: record, package_count?: int, pickup_time?: string, estimated_pickup?: record}
export def "estimated-delivery-date-predict-batch predict-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  estimated_delivery_dates: list # item shape: {slug: string, service_type_name?: string, origin_address: record, destination_address: record, weight?: record, package_count?: int, pickup_time?: string, estimated_pickup?: record}
]: any -> record<meta: record<code: int, message: string, type: string>, data: record<estimated_delivery_dates: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "as-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/estimated-delivery-date/predict-batch")
  let body = {estimated_delivery_dates: $estimated_delivery_dates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
