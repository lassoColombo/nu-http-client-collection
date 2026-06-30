# Auto-generated client for Viator API Documentation &amp; Specification – Merchant Partners v1.0.0
# Source: https://api.apis.guru/v2/specs/viator.com/1.0.0/openapi.json
# Auth: --token flag or $env.VIATOR_API_DOCUMENTATION_AMP_SPECIFICATION_MERCHANT_PARTNERS_TOKEN

const BASE_URL = "https://viatorapi.viator.com/service"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o VIATOR_API_DOCUMENTATION_AMP_SPECIFICATION_MERCHANT_PARTNERS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "exp-api-key" => { {scheme: $scheme, headers: {exp-api-key: $token_val}, query: "", location: "header"} }
    "query-apiKey" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "apiKey")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://viatorapi.viator.com/service" "https://viatorapi.sandbox.viator.com/service" "https://api.sandbox.viator.com/partner"] }
def auth-scheme-completer [] { ["exp-api-key" "query-apiKey"] }

# Completers for enum parameters
def sort-order-completer [] { ["REVIEW_RATING_A" "REVIEW_RATING_D" "REVIEW_RATING_SUBMISSION_DATE_D"] }
def voucher-option-completer [] { ["VOUCHER_E" "VOUCHER_PAPER_ONLY"] }
def sort-order-completer-1 [] { ["PRICE_FROM_A" "PRICE_FROM_D" "REVIEW_AVG_RATING_A" "REVIEW_AVG_RATING_D" "TOP_SELLERS"] }
def sort-order-completer-2 [] { ["SEO_ALPHABETICAL" "SEO_PUBLISHED_DATE_A" "SEO_PUBLISHED_DATE_D" "SEO_REVIEW_AVG_RATING_A" "SEO_REVIEW_AVG_RATING_D"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "available-products create" } } | get name | first)
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

# /available/products
#
# POST /available/products
# operationId: availableProducts
export def "available-products create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
  --currency-code: string # **currency** in which to display product pricing - default: `'USD'`
  --end-date: string # **end date** of the date range to search within (must be in the future)
  --num-adults: int # **number of adult travelers** who wish to participate - default: `1`
  --product-codes: list<string> # **array of unique alphanumeric product identifiers** specifying which products to find the availability of - maximum: `50` (e.g. [5010SYDNEY, 2280SUN, 9169P50])
  --start-date: string # **start date** of the date range to search within (must be in the future)
]: any -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<admission: string, available: bool, bookingEngineId: string, catIds: list, code: string, currencyCode: string, duration: string, essential: string, merchantCancellable: bool, merchantNetPriceFrom: float, merchantNetPriceFromFormatted: string, onRequestPeriod: int, onSale: bool, panoramaCount: int, pas: record, photoCount: int, price: float, priceFormatted: string, primaryDestinationId: int, primaryDestinationName: string, primaryDestinationUrlName: string, primaryGroupId: string, productUrlName: string, rating: float, reviewCount: int, rrp: int, rrpFormatted: string, savingAmount: string, savingAmountFormated: string, shortDescription: string, shortTitle: string, sortOrder: int, specialOfferAvailable: bool, specialReservation: bool, specialReservationDetails: string, sslSupported: bool, subCatIds: list, supplierCode: string, supplierName: string, thumbnailHiResURL: string, thumbnailURL: string, title: string, translationLevel: int, uniqueShortDescription: string, videoCount: int, webURL: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/available/products" $auth.query)
  let req_body = {"currencyCode": $currency_code, "endDate": $end_date, "numAdults": $num_adults, "productCodes": $product_codes, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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

# /booking/availability
#
# POST /booking/availability
# operationId: bookingAvailability
# --ageBands item shape: {bandId?: int, count?: int}
export def "booking-availability create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
  --age-bands: list # **array of objects** specifying the age bands by which to to filter search results — item shape: {bandId?: int, count?: int}
  --currency-code: string # **currency code** for the currency in which to display tour grade pricing information
  --month: string # **month component** (text format) of the start of the date range for which to retrieve tour grade availability information (must be in the future)
  --product-code: string # **unique alphanumeric identifier** of the product for which you wish to retrieve tour grade availability information
  --year: string # **year component** (text format) of the start of the date range for which to retrieve tour grade availability information (must be in the future)
]: any -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<availability: list<record>, firstAvailableDate: string, lastAvailableDate: string, productCode: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/booking/availability" $auth.query)
  let req_body = {"ageBands": $age_bands, "currencyCode": $currency_code, "month": $month, "productCode": $product_code, "year": $year} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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

# /booking/availability/dates
#
# GET /booking/availability/dates
# operationId: bookingAvailabilityDates
export def "booking-availability-dates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-code: string # **unique alphanumeric identifier** of the product (e.g. 2280AAHT)
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
]: nothing -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "productCode" $product_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/booking/availability/dates" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"productCode": $product_code} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# /booking/availability/tourgrades
#
# POST /booking/availability/tourgrades
# operationId: bookingAvailabilityTourgrades
# --ageBands item shape: {bandId?: int, count?: int}
export def "booking-availability-tourgrades create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
  --age-bands: list # **array** of ageBand objects — item shape: {bandId?: int, count?: int}
  --booking-date: string # **date** to enquire about available tour grades for *this* product (must be in the future)
  --currency-code: string # **currency code** for the currency in which to display pricing information
  --product-code: string
]: any -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<ageBands: list, ageBandsRequired: list, available: bool, bookingDate: string, currencyCode: string, defaultLanguageCode: string, gradeCode: string, gradeDepartureTime: string, gradeDescription: string, gradeTitle: string, langServices: record, merchantNetPrice: float, merchantNetPriceFormatted: string, retailPrice: float, retailPriceFormatted: string, sortOrder: int, unavailableReason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/booking/availability/tourgrades" $auth.query)
  let req_body = {"ageBands": $age_bands, "bookingDate": $booking_date, "currencyCode": $currency_code, "productCode": $product_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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

# /booking/availability/tourgrades/pricingmatrix
#
# POST /booking/availability/tourgrades/pricingmatrix
# operationId: bookingAvailabilityTourgradesPricingmatrix
export def "booking-availability-tourgrades-pricingmatrix create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
  --currency-code: string # **currency code** for the currency in which to display pricing details
  --month: string # **month of year** (as text) by which to filter results (must be in the future)
  --product-code: string # **alphanumeric identifier** of product about which to retrieve tour grade and pricing information
  --year: string # **year** (as text) by which to filter results (must be in the future)
]: any -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<bookingMonth: string, dates: list<record>, pricingUnit: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/booking/availability/tourgrades/pricingmatrix" $auth.query)
  let req_body = {"currencyCode": $currency_code, "month": $month, "productCode": $product_code, "year": $year} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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

# /booking/book
#
# POST /booking/book
# operationId: bookingBook
# --booker shape: {cellPhone?: string, cellPhoneCountryCode?: string, email?: string, firstname: string, homePhone?: string, surname: string, title?: string}
# --items item shape: {bookingQuestionAnswers?: list, hotelId?: string, languageOptionCode?: string, partnerItemDetail?: record, pickupPoint?: string, productCode?: string, specialRequirements?: string, tourGradeCode?: string, travelDate?: string, travellers?: list}
# --partnerDetail shape: {distributorRef?: string}
export def "booking-book create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
  --booker: record # **object** containing details about the primary contact (**note**: this contact needn't be a traveller) — shape: {cellPhone?: string, cellPhoneCountryCode?: string, email?: string, firstname: string, homePhone?: string, surname: string, title?: string}
  --currency-code: string # **currency code** for the currency the booking will be submitted in (you will be billed in this currency)
  --demo: oneof<nothing, bool> # **specifier**: `true` if this is a *demo* booking only (demos do not send any notifications, are automatically confirmed and OnRequest products become freesale products. Default value is true. Production must have `demo` set to `false`.
  --items: list # **array** of items to be booked — item shape: {bookingQuestionAnswers?: list, hotelId?: string, languageOptionCode?: string, partnerItemDetail?: record, pickupPoint?: string, productCode?: string, specialRequirements?: string, tourGradeCode?: string, travelDate?: string, travellers?: list}
  --partner-detail: record # Applicable only for extra partner detail for either partner or merchant partner for sending partner specific information — shape: {distributorRef?: string}
]: any -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<bookerEmail: string, bookingDate: string, bookingStatus: record<amended: bool, cancelled: bool, confirmed: bool, failed: bool, level: string, pending: bool, status: int, text: string, type: string>, currencyCode: string, distributorRef: string, exchangeRate: int, hasVoucher: bool, itemSummaries: list<record>, itineraryId: int, omniPreRuleList: string, paypalRedirectURL: string, rulesApplied: string, securityToken: string, sortOrder: int, totalPrice: float, totalPriceFormatted: string, totalPriceUSD: float, userId: string, voucherKey: string, voucherURL: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/booking/book" $auth.query)
  let req_body = {"booker": $booker, "currencyCode": $currency_code, "demo": $demo, "items": $items, "partnerDetail": $partner_detail} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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

# /booking/calculateprice
#
# POST /booking/calculateprice
# operationId: bookingCalculateprice
# --items item shape: {productCode?: string, tourGradeCode?: string, travelDate?: string, travellers?: list}
export def "booking-calculateprice create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
  --currency-code: string # **currency code** for the currency in which to display pricing details
  --items: list # **array** of travel detail objects — item shape: {productCode?: string, tourGradeCode?: string, travelDate?: string, travellers?: list}
]: any -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<currencyCode: string, hasPromoCode: bool, itinerary: record<bookerEmail: string, bookingDate: string, bookingStatus: record, currencyCode: string, distributorRef: string, exchangeRate: int, hasVoucher: bool, itemSummaries: list, itineraryId: int, omniPreRuleList: int, paypalRedirectURL: string, rulesApplied: list, securityToken: string, sortOrder: int, totalPrice: float, totalPriceFormatted: string, totalPriceUSD: float, userId: int, voucherKey: string, voucherURL: string>, itineraryFromPrice: float, itineraryFromPriceFormatted: string, itineraryNewPrice: float, itineraryNewPriceFormatted: string, itinerarySaving: int, itinerarySavingFormatted: string, paymentGatewayInfo: string, promoCode: string, promoCodeExpired: bool, promoCodeValid: bool, rulesApplied: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/booking/calculateprice" $auth.query)
  let req_body = {"currencyCode": $currency_code, "items": $items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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

# /booking/hotels
#
# GET /booking/hotels
# operationId: bookingHotels
export def "booking-hotels get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-code: string # **unique alphanumeric identifier** of the product (e.g. 2280AAHT)
  --dest-id: int # **unique numeric identifier** of the destination (e.g. 123)
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
]: nothing -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<address: string, brand: string, city: string, destinationId: int, hotelString: string, id: string, latitude: float, longitude: float, name: string, notes: string, phone: string, postcode: string, productCodes: list, sortOrder: int>> {
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "productCode" $product_code "scalar") (serialize-qp "destId" $dest_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/booking/hotels" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"productCode": $product_code, "destId": $dest_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# /booking/mybookings
#
# GET /booking/mybookings
# operationId: bookingMybookings
export def "booking-mybookings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --voucher-key: string # **voucher key** for the booking (e.g. 3299307:93c7f36a56b18ba1068787ba7fb7988da5c8ad08db77604110141ff21498603e:600033670)
  --email: string # **email address** of the booker for the booking (e.g. apitest@viator.com)
  --itinerary-or-item-id: string # The booking reference number of the item - **Note**: For more information, see [Booking references](#section/Key-concepts/Booking-references) (e.g. 700179574)
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
]: nothing -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<bookerEmail: string, bookingDate: string, bookingStatus: record<amended: bool, cancelled: bool, confirmed: bool, failed: bool, level: string, pending: bool, status: int, text: string, type: string>, currencyCode: string, distributorRef: string, exchangeRate: int, hasVoucher: bool, itemSummaries: list<record>, itineraryId: int, rulesApplied: string, sortOrder: int, totalPrice: float, totalPriceFormatted: string, totalPriceUSD: float, userId: string, voucherKey: string, voucherURL: string>> {
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "voucherKey" $voucher_key "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "itineraryOrItemId" $itinerary_or_item_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/booking/mybookings" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"voucherKey": $voucher_key, "email": $email, "itineraryOrItemId": $itinerary_or_item_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# /booking/pastbooking
#
# GET /booking/pastbooking
# operationId: bookingPastbooking
export def "booking-pastbooking get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --voucher-key: string # **specifier** of past booking type (use *one* of: `itemId` (booking reference) *and* `'voucherKey'` *or* `'email'`) (e.g. 1005851866:4af44c13ecf3f1a7d3f9ef2fc00c2257e08fa42ae20f877f3039ff9b52aba24e:580669678)
  --email: string # **email address** by which to search for past bookings (e.g. apitest@viator.com)
  --item-id: string # Search for a booking with this **unique booking-reference number**. See [Booking references](#section/Key-concepts/Booking-references) for more information. (e.g. 580669678)
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
]: nothing -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<bookerEmail: string, bookingDate: string, bookingStatus: record<amended: bool, cancelled: bool, confirmed: bool, failed: bool, level: string, pending: bool, status: int, text: string, type: string>, currencyCode: string, distributorRef: string, exchangeRate: int, hasVoucher: bool, itemSummaries: list<record>, itineraryId: int, rulesApplied: string, sortOrder: int, totalPrice: float, totalPriceFormatted: string, totalPriceUSD: float, userId: string, voucherKey: string, voucherURL: string>> {
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "voucherKey" $voucher_key "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "itemId" $item_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/booking/pastbooking" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"voucherKey": $voucher_key, "email": $email, "itemId": $item_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# /booking/pricingmatrix
#
# POST /booking/pricingmatrix
# operationId: bookingPricingmatrix
export def "booking-pricingmatrix create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
  --booking-date: string # **date** for which to retrieve pricing data (must be in the future) (**note**: this is an optional parameter for normal products; if the date is *not* provided then the nearest available date is determined)
  --currency-code: string # **currency code** of the currency in which to display pricing information
  --product-code: string # **unique alphanumeric identifier** of the product for which to retrieve the pricing matrix
  --tour-grade-code: string # **alphanumeric identifier** of the product tour grade for which to retrieve the pricing matrix
]: any -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<ageBandPrices: list, bookingDate: string, pricingUnit: string, sortOrder: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/booking/pricingmatrix" $auth.query)
  let req_body = {"bookingDate": $booking_date, "currencyCode": $currency_code, "productCode": $product_code, "tourGradeCode": $tour_grade_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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

# /booking/status
#
# POST /booking/status
# operationId: bookingStatus
export def "booking-status create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
  --booking-date-from: string # **earliest date** for *this* booking (must be in the future)
  --booking-date-to: string # **latest date** for *this* booking (must be in the future)
  --distributor-item-refs: list<string> # **array** of partner-defined distributor item reference identifiers e.g. `['refItem1','refItem2','refItem3']`
  --distributor-refs: list<string> # **array** of partner-defined distributor reference identifiers
  --item-ids: list<int> # **array** of item identifiers to check
  --lead-first-name: string # **first name** of the lead traveler
  --lead-surname: string # **surname** of the lead traveler
  --test: oneof<nothing, bool> # **specifier**: - `true`: bypass the poll limit in the prelive environment only (recommended for testing) - `false`: (default)
]: any -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<bookingDate: string, bookingStatus: record<amended: bool, cancelled: bool, confirmed: bool, failed: bool, level: string, pending: bool, status: int, text: string, type: string>, distributorRef: string, itemSummaries: list<record>, itineraryId: int, sortOrder: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/booking/status" $auth.query)
  let req_body = {"bookingDateFrom": $booking_date_from, "bookingDateTo": $booking_date_to, "distributorItemRefs": $distributor_item_refs, "distributorRefs": $distributor_refs, "itemIds": $item_ids, "leadFirstName": $lead_first_name, "leadSurname": $lead_surname, "test": $test} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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

# /booking/status/items
#
# POST /booking/status/items
# operationId: bookingStatusItems
export def "booking-status-items create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
  --booking-date-from: string # **earliest date** for when the booking(s) in question were made (must be in the future)
  --booking-date-to: string # **latest date** for when the booking(s) in question were made (must be in the future)
  --distributor-item-refs: list<string> # **array** of partner-defined distributor item reference identifiers e.g. `['refItem1','refItem2','refItem3']`
  --distributor-refs: list<string> # **array** of partner-defined distributor reference identifiers
  --item-ids: list<int> # **array** of booking-reference numbers to check `itemId` (booking-reference provided by Viator). For more information, see [Booking references](#section/Key-concepts/Booking-references)
  --lead-first-name: string # **first name** of the lead traveler
  --lead-surname: string # **surname** of the lead traveler
  --test: oneof<nothing, bool> # **specifier**: - `true`: bypass the poll limit in the prelive environment only - `false`: (default) make a *real* booking, not a test
]: any -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<bookingStatus: record, distributorItemRef: string, itemId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/booking/status/items" $auth.query)
  let req_body = {"bookingDateFrom": $booking_date_from, "bookingDateTo": $booking_date_to, "distributorItemRefs": $distributor_item_refs, "distributorRefs": $distributor_refs, "itemIds": $item_ids, "leadFirstName": $lead_first_name, "leadSurname": $lead_surname, "test": $test} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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

# /booking/voucher
#
# GET /booking/voucher
# operationId: bookingVoucher
export def "booking-voucher get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lead-last-name: string # **surname** of *this* lead traveler (e.g. Simpson)
  --item-id: int # Booking-reference number generated by Viator - **Note**: For more information, see: [Booking references](#section/Key-concepts/Booking-references) (e.g. 600033670)
  --embedded-resources: oneof<nothing, bool> # ignore (Viator only) (e.g. false)
  --voucher-key: string # **identifier** for the voucher - **note**: use <u>either</u> `voucherKey` <u>or</u> the three separate parameters - if `voucherKey` is provided as well as the other parameters, then `voucherKey` overrides the other paramaters - `voucherKey` is obtained from [/booking/mybookings](#operation/bookingMybookings) or in the response from [/booking/book](#operation/bookingBook) when you make a booking (e.g. 3299307:93c7f36a56b18ba1068787ba7fb7988da5c8ad08db77604110141ff21498603e:600033670)
  --full-html: oneof<nothing, bool> # **specifier**: - set to `true` if you wish to retrieve the full HTML-formatted voucher - set to `false` if you want the div fragment (optional) (e.g. true)
  --mobile-voucher: oneof<nothing, bool> # **specifier**: - if set to `true`, the service returns the mobile (cut down) HTML-formatted voucher - if `false` the full voucher HTML is returned (ignoring `fullHTML`) - default: `true` - this field should only be enabled for products that have a `voucherOption` of `'VOUCHER_E'` - do not enable `mobileVouchers` for paper vouchers (`voucherOption` of `'VOUCHER_PAPER_ONLY'`) as no barcode is returned - the voucher information is available in the response from [/product](#operation/product), [/booking/book](#operation/bookingBook), [/booking/pastbooking](#operation/bookingPastbooking), [/booking/mybookings](#operation/bookingMybookings) (it is also displayed under the 'Redemption Info' heading in this service) (e.g. true)
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
]: nothing -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: string> {
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "leadLastName" $lead_last_name "scalar") (serialize-qp "itemId" $item_id "scalar") (serialize-qp "embeddedResources" $embedded_resources "scalar") (serialize-qp "voucherKey" $voucher_key "scalar") (serialize-qp "fullHTML" $full_html "scalar") (serialize-qp "mobileVoucher" $mobile_voucher "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/booking/voucher" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"leadLastName": $lead_last_name, "itemId": $item_id, "embeddedResources": $embedded_resources, "voucherKey": $voucher_key, "fullHTML": $full_html, "mobileVoucher": $mobile_voucher} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# /bookings/cancel-reasons
#
# GET /bookings/cancel-reasons
# operationId: cancellationReasons
export def "bookings-cancel-reasons get-cancellation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
]: nothing -> table<reasons: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default "https://api.sandbox.viator.com/partner")
  let full_url = (build-url $base "/bookings/cancel-reasons" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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

# /bookings/{booking-reference}/cancel
#
# POST /bookings/{booking-reference}/cancel
# operationId: cancelBooking
export def "bookings-cancel cancel" [
  booking_reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
  --reason-code: string # Machine-interpretable identification code for this cancellation reason, retrieved from [cancellationReasons](#operation/cancellationReasons) (e.g. Customer_Service.I_canceled_my_entire_trip)
]: any -> record<bookingId: string, reason: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default "https://api.sandbox.viator.com/partner")
  if ($booking_reference | is-empty) { error make --unspanned { msg: "path parameter 'booking-reference' must be non-empty" } }
  let full_url = (build-url $base ({booking_reference: (encode-path-segment $booking_reference)} | format pattern "/bookings/{booking_reference}/cancel") $auth.query)
  let req_body = {"reasonCode": $reason_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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

# /bookings/{booking-reference}/cancel-quote
#
# GET /bookings/{booking-reference}/cancel-quote
# operationId: cancelBookingQuote
export def "bookings-cancel-quote cancel" [
  booking_reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bookingId: string, refundDetails: record<currencyCode: string, itemPrice: float, refundAmount: float, refundPercentage: float>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default "https://api.sandbox.viator.com/partner")
  if ($booking_reference | is-empty) { error make --unspanned { msg: "path parameter 'booking-reference' must be non-empty" } }
  let full_url = (build-url $base ({booking_reference: (encode-path-segment $booking_reference)} | format pattern "/bookings/{booking_reference}/cancel-quote") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# /health/check
#
# GET /health/check
# operationId: healthCheck
export def "health-check check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
]: nothing -> record<allGood: bool, capiOk: bool, dbOk: bool, memcachedOk: bool, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/check" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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

# /merchant/cancellation
#
# POST /merchant/cancellation
# DEPRECATED
# operationId: merchantCancellation
# --cancelItems item shape: {cancelCode?: string, cancelDescription?: string, distributorItemRef?: string, itemId?: int}
@deprecated
export def "merchant-cancellation create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
  --cancel-items: list # **array** of objects detailing itinerary items to cancel — item shape: {cancelCode?: string, cancelDescription?: string, distributorItemRef?: string, itemId?: int}
  --distributor-ref: string # **itinerary reference identifier** (partner defined) for the booking to cancel (e.g. Jdp122)
  --itinerary-id: int # **numeric identifier** for the itinerary (e.g. 1234655)
]: any -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<cancelItems: list<record>, distributorRef: string, itineraryId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/merchant/cancellation" $auth.query)
  let req_body = {"cancelItems": $cancel_items, "distributorRef": $distributor_ref, "itineraryId": $itinerary_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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

# /product
#
# GET /product
# operationId: product
export def "product get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency-code: string # **currency code** for the currency in which pricing is displayed - default=`'USD'`
  --sort-order: string@sort-order-completer # **specifier** of the order in which to return reviews Sort order options: - `"REVIEW_RATING_A"`: Traveler Rating (low→high) Average - `"REVIEW_RATING_D"`: Traveler Rating (high→low) Average - `"REVIEW_RATING_SUBMISSION_DATE_D"`: Most recent review
  --voucher-option: string@voucher-option-completer # - `"VOUCHER_PAPER_ONLY"`: Paper Vouchers only accepted - `"VOUCHER_E"`: EVouchers + Paper Vouchers accepted
  --code: string # **unique alphanumeric identifier** of the product (e.g. 5010SYDNEY)
  --show-unavailable: oneof<nothing, bool> # **specifier** as to whether or not to show 'unavailable' products: - `true`: return *both* available and unavailable products - `false`: return *only* available products (default) (e.g. false)
  --exclude-tour-grade-availability: oneof<nothing, bool> # **specifier:** - `true`: return **all** tour grades, including those that are not available - `false`: only display tour grades that *are* available
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
]: nothing -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<additionalInfo: list<string>, admission: string, ageBands: list<record>, allTravellerNamesRequired: bool, applePassSupported: bool, available: bool, bookingEngineId: string, bookingQuestions: list<record>, catIds: list<int>, city: string, code: string, country: string, currencyCode: string, departurePoint: string, departureTime: string, departureTimeComments: string, description: string, destinationId: int, duration: string, essential: string, exclusions: list<string>, highlights: int, hotelPickup: bool, inclusions: list<string>, itinerary: string, location: string, mapURL: string, maxTravellerCount: int, merchantCancellable: bool, merchantNetPriceFrom: float, merchantNetPriceFromFormatted: string, merchantTermsAndConditions: record<amountRefundable: int, cancellationFromTourDate: list, merchantTermsAndConditionsType: int, termsAndConditions: string>, onRequestPeriod: int, onSale: bool, operates: string, panoramaCount: int, pas: record, passengerAttributes: list<record>, photoCount: int, price: float, priceFormatted: string, primaryDestinationId: int, primaryDestinationName: string, primaryDestinationUrlName: string, primaryGroupId: string, productPhotos: list<record>, productUrlName: string, rating: float, ratingCounts: record<1: float, 2: float, 3: float, 4: float, 5: float>, region: string, returnDetails: string, reviewCount: int, reviews: list<record>, rrp: int, rrpFormatted: string, salesPoints: list<string>, savingAmount: string, savingAmountFormated: string, shortDescription: string, shortTitle: string, specialOffer: string, specialOfferAvailable: bool, specialReservation: bool, specialReservationDetails: string, sslSupported: bool, subCatIds: list<int>, supplierCode: string, supplierName: string, thumbnailHiResURL: string, thumbnailURL: string, title: string, tourGrades: list<record>, tourGradesAvailable: bool, translationLevel: int, userPhotos: list<record>, videoCount: int, videos: string, voucherOption: string, voucherRequirements: any, webURL: string>> {
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currencyCode" $currency_code "scalar") (serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "voucherOption" $voucher_option "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "showUnavailable" $show_unavailable "scalar") (serialize-qp "excludeTourGradeAvailability" $exclude_tour_grade_availability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"currencyCode": $currency_code, "sortOrder": $sort_order, "voucherOption": $voucher_option, "code": $code, "showUnavailable": $show_unavailable, "excludeTourGradeAvailability": $exclude_tour_grade_availability} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# /product/photos
#
# GET /product/photos
# operationId: productPhotos
export def "product-photos get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top-x: string # **start and end rows** to return in the format {start}-{end} - e.g. `'1-10'`, `'11-20'` **Note**: - the maximum number of rows per request is 100; therefore, `'100-400'` will return the same as `'100-200'` - if `topX` is not specified, the default is `'1-100'` (e.g. 1-3)
  --code: string # **unique alphanumeric identifier** of the product (e.g. 5010SYDNEY)
  --show-unavailable: oneof<nothing, bool> # **specifier** as to whether or not to show 'unavailable' products: - `true`: return *both* available and unavailable products - `false`: return *only* available products (default) (e.g. false)
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
]: nothing -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<caption: string, editorsPick: bool, ownerAvatarURL: string, ownerCountry: string, ownerId: int, ownerName: string, photoHiResURL: string, photoId: int, photoMediumResURL: string, photoURL: string, productCode: string, productTitle: string, productUrlName: string, sortOrder: int, sslSupported: bool, thumbnailURL: string, timeUploaded: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "topX" $top_x "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "showUnavailable" $show_unavailable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product/photos" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"topX": $top_x, "code": $code, "showUnavailable": $show_unavailable} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# /product/reviews
#
# GET /product/reviews
# operationId: productReviews
export def "product-reviews get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-order: string@sort-order-completer # **specifier** of the order in which to return reviews Sort order options: - `"REVIEW_RATING_A"`: Traveler Rating (low→high) Average - `"REVIEW_RATING_D"`: Traveler Rating (high→low) Average - `"REVIEW_RATING_SUBMISSION_DATE_D"`: Most recent review
  --top-x: string # **start and end rows** to return in the format {start}-{end} - e.g. `'1-10'`, `'11-20'` **Note**: - the maximum number of rows per request is 100; therefore, `'100-400'` will return the same as `'100-200'` - if `topX` is not specified, the default is `'1-100'` (e.g. 1-3)
  --code: string # **unique alphanumeric identifier** of the product (e.g. 5010SYDNEY)
  --show-unavailable: oneof<nothing, bool> # **specifier** as to whether or not to show 'unavailable' products: - `true`: return *both* available and unavailable products - `false`: return *only* available products (default) (e.g. false)
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
]: nothing -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<ownerAvatarURL: string, ownerCountry: string, ownerId: int, ownerName: string, productCode: string, productTitle: string, productUrlName: string, publishedDate: string, rating: int, review: string, reviewId: int, sortOrder: int, sslSupported: bool, submissionDate: string, viatorFeedback: string, viatorNotes: string>> {
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "topX" $top_x "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "showUnavailable" $show_unavailable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product/reviews" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sortOrder": $sort_order, "topX": $top_x, "code": $code, "showUnavailable": $show_unavailable} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# /search/freetext
#
# POST /search/freetext
# operationId: searchFreetext
export def "search-freetext list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
  --currency-code: string # **currency code** for the currency in which to display product pricing information
  --dest-id: int # **unique numeric identifier** of the destination to search within - `destinationId` can be retrieved from the [/taxonomy/destinations](#operation/taxonomyDestinations) service
  --search-types: list<string> # **array** of search domain specifiers where each item is *one of*: - `"PRODUCT"`: a tour / activity - `"DESTINATION"`: continent, country, city, region - `"ATTRACTION"`: an attraction within a destination (only available to partners with SEO access) - `"RECOMMENDATION"`: an attraction within a destination (only available to partners with SEO access)
  --sort-order: string@sort-order-completer-1 # **sort order** in which to return the results that is *one of*: - `'TOP_SELLERS'`: the top sellers - `'REVIEW_AVG_RATING_A'`: ascending by average traveler rating (low -> high) - `'REVIEW_AVG_RATING_D'`: descending by average traveler rating (high -> low) - `'PRICE_FROM_A'`: ascending by price (low -> high) - `'PRICE_FROM_D'`: descending by price (high -> low)
  --text: string # **text** to search for
  --top-x: string # **start and end rows** to return in the format {start}-{end} - e.g. `'1-10'`, `'11-20'` **Note**: - the maximum number of rows per request is 100; therefore, `'100-400'` will return the same as `'100-200'` - if `topX` is not specified, the default is `'1-100'`
]: any -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<searchType: string, sortOrder: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search/freetext" $auth.query)
  let req_body = {"currencyCode": $currency_code, "destId": $dest_id, "searchTypes": $search_types, "sortOrder": $sort_order, "text": $text, "topX": $top_x} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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

# /search/products
#
# POST /search/products
# operationId: searchProducts
export def "search-products list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
  --cat-id: int # **unique numeric identifier** of *this* product category to search within - `categoryId` can be retrieved from the [/taxonomy/categories](#operation/taxonomyCategories) service - at present, it is not possible to use `catId` in conjunction with `seoId`
  --currency-code: string # **currency** in which to display product prices
  --dest-id: int # **unique numeric identifier** of the destination in which to search for products - `destinationId` is available from the [/taxonomy/destinations](#operation/taxonomyDestinations) service - use **EITHER** `destId` **OR** `seoId`, but not both
  --end-date: string # **end date delimiter** for the search (must be in the future) - e.g., `'2019-10-21'`
  --seo-id: string # **search restriction specifier** for products associated with an attraction uniquely identified by `seoId` - use **EITHER** `destId` **OR** `seoId`, but not both
  --sort-order: string@sort-order-completer-1 # **sort order** in which to return the results that is *one of*: - `"TOP_SELLERS"`: the top sellers - `"REVIEW_AVG_RATING_A"`: ascending by average traveler rating (low -> high) - `"REVIEW_AVG_RATING_D"`: descending by average traveler rating (high -> low) - `"PRICE_FROM_A"`: ascending by price (low -> high) - `"PRICE_FROM_D"`: descending by price (high -> low)
  --start-date: string # **start date delimiter** for the search (must be in the future) - e.g., `'2018-10-21'`
  --sub-cat-id: int # **unique numeric identifier** of *this* product subcategory to search within - `subcategoryId` can be retrieved from the [/taxonomy/categories](#operation/taxonomyCategories) service - at present, it is not possible to use `subCatId` in conjunction with `seoId`
  --top-x: string # **start and end rows** to return in the format {start}-{end} - e.g. `'1-10'`, `'11-20'` **Note**: - the maximum number of rows per request is 100; therefore, `'100-400'` will return the same as `'100-200'` - if `topX` is not specified, the default is `'1-100'`
]: any -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<admission: string, available: bool, bookingEngineId: string, catIds: list, code: string, currencyCode: string, duration: string, essential: string, merchantCancellable: bool, merchantNetPriceFrom: float, merchantNetPriceFromFormatted: string, onRequestPeriod: int, onSale: bool, panoramaCount: int, pas: record, photoCount: int, price: float, priceFormatted: string, primaryDestinationId: int, primaryDestinationName: string, primaryDestinationUrlName: string, primaryGroupId: int, productUrlName: string, rating: float, reviewCount: int, rrp: int, rrpformatted: string, savingAmount: string, savingAmountFormated: string, shortDescription: string, shortTitle: string, sortOrder: int, specialOfferAvailable: bool, specialReservation: bool, specialReservationDetails: string, sslSupported: any, subCatIds: list, supplierCode: string, supplierName: string, thumbnailHiResURL: string, thumbnailURL: string, title: string, translationLevel: int, uniqueShortDescription: string, videoCount: int, webURL: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search/products" $auth.query)
  let req_body = {"catId": $cat_id, "currencyCode": $currency_code, "destId": $dest_id, "endDate": $end_date, "seoId": $seo_id, "sortOrder": $sort_order, "startDate": $start_date, "subCatId": $sub_cat_id, "topX": $top_x} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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

# /search/products/codes
#
# POST /search/products/codes
# operationId: searchProductsCodes
export def "search-products-codes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
  --currency-code: string # **currency code** for the currency in which to display product pricing
  --product-codes: list<string> # **array** of product codes to search for
]: any -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<admission: string, bookingEngineId: string, catIds: list, code: string, currencyCode: string, duration: string, essential: string, merchantCancellable: bool, merchantNetPriceFrom: float, merchantNetPriceFromFormatted: string, onRequestPeriod: int, onSale: bool, panoramaCount: int, pas: record, photoCount: int, price: float, priceFormatted: string, primaryDestinationId: int, primaryDestinationName: string, primaryGroupId: string, rating: float, reviewCount: int, rrp: int, rrpformatted: string, savingAmount: string, savingAmountFormated: string, shortDescription: string, shortTitle: string, sortOrder: int, specialOfferAvailable: bool, specialReservation: bool, specialReservationDetails: string, subCatIds: list, supplierCode: string, supplierName: string, thumbnailHiResURL: string, thumbnailURL: string, title: string, translationLevel: int, uniqueShortDescription: string, videoCount: int, webURL: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search/products/codes" $auth.query)
  let req_body = {"currencyCode": $currency_code, "productCodes": $product_codes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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

# /taxonomy/attractions
#
# POST /taxonomy/attractions
# operationId: taxonomyAttractions
export def "taxonomy-attractions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
  --dest-id: int # **unique numeric identifier** of the destination in which to search for attractions
  --sort-order: string@sort-order-completer-2 # **sort order** in which to return the results that is *one of*: * `"SEO_PUBLISHED_DATE_D"`: publish date (descending) * `"SEO_PUBLISHED_DATE_A"`: publish date (ascending) * `"SEO_REVIEW_AVG_RATING_D"`: traveler rating (high→low) * `"SEO_REVIEW_AVG_RATING_A"`: traveler rating (low→high) * `"SEO_ALPHABETICAL"`: alphabetical (A→Z)
  --top-x: string # **start and end rows** to return in the format {start}-{end} - e.g. `'1-10'`, `'11-20'` **Note**: - the maximum number of rows per request is 100; therefore, `'100-400'` will return the same as `'100-200'` - if `topX` is not specified, the default is `'1-100'`
]: any -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<attractionCity: string, attractionLatitude: float, attractionLongitude: float, attractionState: string, attractionStreetAddress: string, destinationId: int, pageUrlName: string, photoCount: int, primaryDestinationId: int, primaryDestinationName: string, primaryDestinationUrlName: string, productCount: int, publishedDate: string, rating: float, seoId: int, sortOrder: int, thumbnailHiResURL: string, thumbnailURL: string, title: string, webURL: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/taxonomy/attractions" $auth.query)
  let req_body = {"destId": $dest_id, "sortOrder": $sort_order, "topX": $top_x} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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

# /taxonomy/categories
#
# GET /taxonomy/categories
# operationId: taxonomyCategories
export def "taxonomy-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dest-id: int # **unique numeric identifier** of the destination to enquire about (optional) - `destinationId` is returned by [/taxonomy/destinations](#operation/taxonomyDestinations) (e.g. 684)
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
]: nothing -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<groupName: string, groupUrlName: string, id: int, productCount: int, subcategories: list, thumbnailURL: string>> {
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "destId" $dest_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/taxonomy/categories" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"destId": $dest_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# /taxonomy/destinations
#
# GET /taxonomy/destinations
# operationId: taxonomyDestinations
export def "taxonomy-destinations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (e.g. en-US)
]: nothing -> record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<defaultCurrencyCode: string, destinationId: int, destinationName: string, destinationType: string, destinationUrlName: string, iataCode: string, latitude: float, longitude: float, lookupId: string, parentId: int, selectable: bool, sortOrder: int, timeZone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "exp-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/taxonomy/destinations" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
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
