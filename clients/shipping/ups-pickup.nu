# Auto-generated client for Pickup v
# Source: https://raw.githubusercontent.com/UPS-API/api-documentation/main/Pickup.yaml
# Auth: --token flag or $env.PICKUP_TOKEN

const BASE_URL = "https://wwwcie.ups.com/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PICKUP_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://wwwcie.ups.com/api" "https://onlinetools.ups.com/api"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "shipments-pickup Pickup-Rate" } } | get name | first)
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

# Pickup Rate
#
# POST /shipments/{version}/pickup/{pickuptype}
# operationId: Pickup Rate
# --PickupRateRequest shape: {Request: record, ShipperAccount?: record, PickupAddress: record, AlternateAddressIndicator: string, ServiceDateOption: string, PickupDateInfo?: record, RateChartType?: string, TaxInformationIndicator?: string, UserLevelDiscountIndicator?: string}
export def "shipments-pickup Pickup-Rate" [
  version: string
  pickuptype: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transId: string # An identifier unique to the request. Length 32
  --transactionSrc: string # An identifier of the client/source application that is making the request.Length 512
  PickupRateRequest: record # This request is used to rate an on-callpickup. — shape: {Request: record, ShipperAccount?: record, PickupAddress: record, AlternateAddressIndicator: string, ServiceDateOption: string, PickupDateInfo?: record, RateChartType?: string, TaxInformationIndicator?: string, UserLevelDiscountIndicator?: string}
]: any -> record<PickupRateResponse: record<Response: record<ResponseStatus: record, Alert: list, TransactionReference: record>, RateResult: record<Disclaimer: record, RateType: string, CurrencyCode: string, ChargeDetail: list, TaxCharges: list, TotalTax: string, GrandTotalOfAllCharge: string, GrandTotalOfAllIncentedCharge: string, PreTaxTotalCharge: string, PreTaxTotalIncentedCharge: string>, WeekendServiceTerritoryIndicator: string, WeekendServiceTerritory: record<SatWST: string, SunWST: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shipments/($version)/pickup/($pickuptype)")
  let body = {PickupRateRequest: $PickupRateRequest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"transId": $transId, "transactionSrc": $transactionSrc} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Pickup Pending Status
#
# GET /shipments/{version}/pickup/{pickuptype}
# operationId: Pickup Pending Status
export def "shipments-pickup Pickup-Pending-Status" [
  version: string
  pickuptype: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transId: string # An identifier unique to the request. Length 32
  --transactionSrc: string # An identifier of the client/source application that is making the request.Length 512
  --AccountNumber: string # The specific account number that belongs to the  shipper.Length 6 or 10
]: nothing -> record<PickupPendingStatusResponse: record<Response: record<ResponseStatus: record, Alert: list, TransactionReference: record>, PendingStatus: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shipments/($version)/pickup/($pickuptype)")
  let extra_headers = {"transId": $transId, "transactionSrc": $transactionSrc, "AccountNumber": $AccountNumber} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pickup Cancel
#
# DELETE /shipments/{version}/pickup/{CancelBy}
# operationId: Pickup Cancel
export def "shipments-pickup Pickup-Cancel" [
  CancelBy: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transId: string # An identifier unique to the request. Length 32
  --transactionSrc: string # An identifier of the client/source application that is making the request.Length 512
  --Prn: string # The pickup equest number (PRN) generated by  UPS pickup system. Required if CancelBy = prn.Length 26
]: nothing -> record<PickupCancelResponse: record<Response: record<ResponseStatus: record, Alert: list, TransactionReference: record>, PickupType: string, GWNStatus: record<Code: string, Description: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shipments/($version)/pickup/($CancelBy)")
  let extra_headers = {"transId": $transId, "transactionSrc": $transactionSrc, "Prn": $Prn} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pickup Creation
#
# POST /pickupcreation/{version}/pickup
# operationId: Pickup Creation
# --PickupCreationRequest shape: {Request: record, RatePickupIndicator: string, RateChartType?: string, TaxInformationIndicator?: string, UserLevelDiscountIndicator?: string, Shipper?: record, PickupDateInfo: record, PickupAddress: record, AlternateAddressIndicator: string, PickupPiece: list, TotalWeight?: record, OverweightIndicator?: string, TrackingData?: list, TrackingDataWithReferenceNumber?: record, PaymentMethod: string, SpecialInstruction?: string, ReferenceNumber?: string, FreightOptions?: record, ServiceCategory?: string, CashType?: string, ShippingLabelsAvailable?: string, Notification?: record}
# --PickupTriggerGWNRequest shape: {Request: record, AccountNumber: string, ServiceDateOption: string}
export def "pickupcreation-pickup Pickup-Creation" [
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transId: string # An identifier unique to the request. Length 32
  --transactionSrc: string # An identifier of the client/source application that is making the request.Length 512
  --PickupCreationRequest: record # This request is for scheduling an on-call pickup — shape: {Request: record, RatePickupIndicator: string, RateChartType?: string, TaxInformationIndicator?: string, UserLevelDiscountIndicator?: string, Shipper?: record, PickupDateInfo: record, PickupAddress: record, AlternateAddressIndicator: string, PickupPiece: list, TotalWeight?: record, OverweightIndicator?: string, TrackingData?: list, TrackingDataWithReferenceNumber?: record, PaymentMethod: string, SpecialInstruction?: string, ReferenceNumber?: string, FreightOptions?: record, ServiceCategory?: string, CashType?: string, ShippingLabelsAvailable?: string, Notification?: record}
  --PickupTriggerGWNRequest: record # Request to trigger a Smart Pickup (GWN - Green When Needed). This flow applies to accounts enabled for Smart Pickup and supports same-day or future-day pickup requests. Unlike regular Pickup Creation, Smart Pickup does not require a separate Shipper object - it uses the pickup address pre-configured on the UPS account. — shape: {Request: record, AccountNumber: string, ServiceDateOption: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pickupcreation/($version)/pickup")
  let body = {PickupCreationRequest: $PickupCreationRequest, PickupTriggerGWNRequest: $PickupTriggerGWNRequest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"transId": $transId, "transactionSrc": $transactionSrc} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Pickup Get Political Division1 List
#
# GET /pickup/{version}/countries/{countrycode}
# operationId: Pickup Get Political Division1 List
export def "pickup-countries Pickup-Get-Political-Division1-List" [
  version: string
  countrycode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transId: string # An identifier unique to the request. Length 32
  --transactionSrc: string # An identifier of the client/source application that is making the request.Length 512
]: nothing -> record<PickupGetPoliticalDivision1ListResponse: record<Response: record<ResponseStatus: record, Alert: list, TransactionReference: record>, PoliticalDivision1: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pickup/($version)/countries/($countrycode)")
  let extra_headers = {"transId": $transId, "transactionSrc": $transactionSrc} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pickup Get Service Center Facilities
#
# POST /pickup/{version}/servicecenterlocations
# operationId: Pickup Get Service Center Facilities
# --PickupGetServiceCenterFacilitiesRequest shape: {Request: record, PickupPiece: any, OriginAddress?: record, DestinationAddress?: record, Locale: string, ProximitySearchIndicator?: string}
export def "pickup-servicecenterlocations Pickup-Get-Service-Center-Facilities" [
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transId: string # An identifier unique to the request. Length 32
  --transactionSrc: string # An identifier of the client/source application that is making the request.Length 512
  PickupGetServiceCenterFacilitiesRequest: record # This request is to retrieve UPS Facility location information including location address, phone number, SLIC, and hours of operation for pick-up and drop-off requests — shape: {Request: record, PickupPiece: any, OriginAddress?: record, DestinationAddress?: record, Locale: string, ProximitySearchIndicator?: string}
]: any -> record<PickupGetServiceCenterFacilitiesResponse: record<Response: record<ResponseStatus: record, Alert: list, TransactionReference: record>, ServiceCenterLocation: record<DropOffFacilities: list, PickupFacilities: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pickup/($version)/servicecenterlocations")
  let body = {PickupGetServiceCenterFacilitiesRequest: $PickupGetServiceCenterFacilitiesRequest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"transId": $transId, "transactionSrc": $transactionSrc} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Pickup Cancel
#
# DELETE /shipments/{deprecatedVersion}/pickup/{CancelBy}
# DEPRECATED
# operationId: Deprecated Pickup Cancel
@deprecated
export def "shipments-pickup Deprecated-Pickup-Cancel" [
  CancelBy: string
  deprecatedVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transId: string # An identifier unique to the request. Length 32
  --transactionSrc: string # An identifier of the client/source application that is making the request.Length 512
  --Prn: string # The pickup equest number (PRN) generated by  UPS pickup system. Required if CancelBy = prn.Length 26
]: nothing -> record<PickupCancelResponse: record<Response: record<ResponseStatus: record, Alert: list, TransactionReference: record>, PickupType: string, GWNStatus: record<Code: string, Description: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shipments/($deprecatedVersion)/pickup/($CancelBy)")
  let extra_headers = {"transId": $transId, "transactionSrc": $transactionSrc, "Prn": $Prn} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pickup Creation
#
# POST /pickupcreation/{deprecatedVersion}/pickup
# DEPRECATED
# operationId: Deprecated Pickup Creation
# --PickupCreationRequest shape: {Request: record, RatePickupIndicator: string, RateChartType?: string, TaxInformationIndicator?: string, UserLevelDiscountIndicator?: string, Shipper?: record, PickupDateInfo: record, PickupAddress: record, AlternateAddressIndicator: string, PickupPiece: list, TotalWeight?: record, OverweightIndicator?: string, TrackingData?: list, TrackingDataWithReferenceNumber?: record, PaymentMethod: string, SpecialInstruction?: string, ReferenceNumber?: string, FreightOptions?: record, ServiceCategory?: string, CashType?: string, ShippingLabelsAvailable?: string, Notification?: record}
@deprecated
export def "pickupcreation-pickup Deprecated-Pickup-Creation" [
  deprecatedVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transId: string # An identifier unique to the request. Length 32
  --transactionSrc: string # An identifier of the client/source application that is making the request.Length 512
  PickupCreationRequest: record # This request is for scheduling an on-call pickup — shape: {Request: record, RatePickupIndicator: string, RateChartType?: string, TaxInformationIndicator?: string, UserLevelDiscountIndicator?: string, Shipper?: record, PickupDateInfo: record, PickupAddress: record, AlternateAddressIndicator: string, PickupPiece: list, TotalWeight?: record, OverweightIndicator?: string, TrackingData?: list, TrackingDataWithReferenceNumber?: record, PaymentMethod: string, SpecialInstruction?: string, ReferenceNumber?: string, FreightOptions?: record, ServiceCategory?: string, CashType?: string, ShippingLabelsAvailable?: string, Notification?: record}
]: any -> record<PickupCreationResponse: record<Response: record<ResponseStatus: record, Alert: list, TransactionReference: record>, PRN: string, WeekendServiceTerritory: record<SatWST: string, SunWST: string>, WeekendServiceTerritoryIndicator: string, RateStatus: record<Code: string, Description: string>, RateResult: record<Disclaimer: record, RateType: string, CurrencyCode: string, ChargeDetail: list, TaxCharges: list, TotalTax: string, GrandTotalOfAllCharge: string, GrandTotalOfAllIncentedCharge: string, PreTaxTotalCharge: string, PreTaxTotalIncentedCharge: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pickupcreation/($deprecatedVersion)/pickup")
  let body = {PickupCreationRequest: $PickupCreationRequest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"transId": $transId, "transactionSrc": $transactionSrc} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
