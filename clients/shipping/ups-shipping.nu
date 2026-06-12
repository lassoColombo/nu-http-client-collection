# Auto-generated client for Ship v
# Source: https://raw.githubusercontent.com/UPS-API/api-documentation/main/Shipping.yaml
# Auth: --token flag or $env.SHIP_TOKEN

const BASE_URL = "https://wwwcie.ups.com/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SHIP_TOKEN | default "" }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "shipments-ship Shipment" } } | get name | first)
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

# Shipment
#
# POST /shipments/{version}/ship
# operationId: Shipment
# --ShipmentRequest shape: {Request: record, Shipment: record, LabelSpecification?: record, ReceiptSpecification?: record}
export def "shipments-ship Shipment" [
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additionaladdressvalidation: string # Valid Values:  city = validation will include city.Length 15
  --transId: string # An identifier unique to the request. Length 32
  --transactionSrc: string # An identifier of the client/source application that is making the request.Length 512
  ShipmentRequest: record # Shipment Request. — shape: {Request: record, Shipment: record, LabelSpecification?: record, ReceiptSpecification?: record}
]: any -> record<ShipmentResponse: record<Response: record<ResponseStatus: record, Alert: list, TransactionReference: record>, ShipmentResults: record<Disclaimer: list, ShipmentCharges: record, NegotiatedRateCharges: record, FRSShipmentData: record, RatingMethod: string, BillableWeightCalculationMethod: string, BillingWeight: record, ShipmentIdentificationNumber: string, MIDualReturnShipmentKey: string, BarCodeImage: string, PackageResults: list, ControlLogReceipt: list, Form: record, CODTurnInPage: record, HighValueReport: record, LabelURL: string, LocalLanguageLabelURL: string, ReceiptURL: string, LocalLanguageReceiptURL: string, DGPaperImage: list, MasterCartonID: string, RoarRatedIndicator: string, GCCN: string, USI: string, Message: string, SubProNumber: string, PalletLabel: record, BillOfLading: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additionaladdressvalidation" $additionaladdressvalidation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/shipments/($version)/ship" $qp)
  let body = {ShipmentRequest: $ShipmentRequest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"transId": $transId, "transactionSrc": $transactionSrc} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Void Shipment
#
# DELETE /shipments/{version}/void/cancel/{shipmentidentificationnumber}
# operationId: VoidShipment
export def "shipments-void-cancel VoidShipment" [
  version: string
  shipmentidentificationnumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --trackingnumber: string # The package's tracking number. You may have  up to 20 different tracking numbers listed. If more than one tracking number, pass this  value as: trackingnumber=  ["1ZISUS010330563105","1ZISUS01033056310 8"] with a coma separating each number. Alpha-numeric. Must pass 1Z rules. Must be  upper case. Length 18
  --transId: string # An identifier unique to the request. Length 32
  --transactionSrc: string # An identifier of the client/source application that is making the request.Length 512
]: nothing -> record<VoidShipmentResponse: record<Response: record<ResponseStatus: record, Alert: record, TransactionReference: record>, SummaryResult: record<Status: record>, PackageLevelResults: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "trackingnumber" $trackingnumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/shipments/($version)/void/cancel/($shipmentidentificationnumber)" $qp)
  let extra_headers = {"transId": $transId, "transactionSrc": $transactionSrc} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Label Recovery
#
# POST /labels/{version}/recovery
# operationId: LabelRecovery
# --LabelRecoveryRequest shape: {Request: record, LabelSpecification?: record, Translate?: record, LabelDelivery?: record, TrackingNumber?: string, TrackingNumbers: list, MailInnovationsTrackingNumber?: string, ReferenceValues: record, Locale?: string, UPSPremiumCareForm?: record}
export def "labels-recovery LabelRecovery" [
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
  LabelRecoveryRequest: record # Request for obtaining the Label for the return shipment. — shape: {Request: record, LabelSpecification?: record, Translate?: record, LabelDelivery?: record, TrackingNumber?: string, TrackingNumbers: list, MailInnovationsTrackingNumber?: string, ReferenceValues: record, Locale?: string, UPSPremiumCareForm?: record}
]: any -> record<LabelRecoveryResponse: record<Response: record<ResponseStatus: record, Alert: list, TransactionReference: record>, ShipmentIdentificationNumber: string, LabelResults: list<record>, CODTurnInPage: record<Image: record>, Form: record<Image: record>, HighValueReport: record<Image: record>, TrackingCandidate: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/labels/($version)/recovery")
  let body = {LabelRecoveryRequest: $LabelRecoveryRequest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"transId": $transId, "transactionSrc": $transactionSrc} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Shipment
#
# POST /shipments/{deprecatedVersion}/ship
# DEPRECATED
# operationId: Deprecated Shipment
# --ShipmentRequest shape: {Request: record, Shipment: record, LabelSpecification?: record, ReceiptSpecification?: record}
@deprecated
export def "shipments-ship Deprecated-Shipment" [
  deprecatedVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additionaladdressvalidation: string # Valid Values:  city = validation will include city.Length 15
  --transId: string # An identifier unique to the request. Length 32
  --transactionSrc: string # An identifier of the client/source application that is making the request.Length 512
  ShipmentRequest: record # Shipment Request. — shape: {Request: record, Shipment: record, LabelSpecification?: record, ReceiptSpecification?: record}
]: any -> record<ShipmentResponse: record<Response: record<ResponseStatus: record, Alert: list, TransactionReference: record>, ShipmentResults: record<Disclaimer: list, ShipmentCharges: record, NegotiatedRateCharges: record, FRSShipmentData: record, RatingMethod: string, BillableWeightCalculationMethod: string, BillingWeight: record, ShipmentIdentificationNumber: string, MIDualReturnShipmentKey: string, BarCodeImage: string, PackageResults: list, ControlLogReceipt: list, Form: record, CODTurnInPage: record, HighValueReport: record, LabelURL: string, LocalLanguageLabelURL: string, ReceiptURL: string, LocalLanguageReceiptURL: string, DGPaperImage: list, MasterCartonID: string, RoarRatedIndicator: string, GCCN: string, USI: string, Message: string, SubProNumber: string, PalletLabel: record, BillOfLading: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additionaladdressvalidation" $additionaladdressvalidation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/shipments/($deprecatedVersion)/ship" $qp)
  let body = {ShipmentRequest: $ShipmentRequest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"transId": $transId, "transactionSrc": $transactionSrc} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Void Shipment
#
# DELETE /shipments/{deprecatedVersion}/void/cancel/{shipmentidentificationnumber}
# DEPRECATED
# operationId: Deprecated VoidShipment
@deprecated
export def "shipments-void-cancel Deprecated-VoidShipment" [
  deprecatedVersion: string
  shipmentidentificationnumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --trackingnumber: string # The package's tracking number. You may have  up to 20 different tracking numbers listed. If more than one tracking number, pass this  value as: trackingnumber=  ["1ZISUS010330563105","1ZISUS01033056310 8"] with a coma separating each number. Alpha-numeric. Must pass 1Z rules. Must be  upper case. Length 18
  --transId: string # An identifier unique to the request. Length 32
  --transactionSrc: string # An identifier of the client/source application that is making the request.Length 512
]: nothing -> record<VoidShipmentResponse: record<Response: record<ResponseStatus: record, Alert: record, TransactionReference: record>, SummaryResult: record<Status: record>, PackageLevelResults: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "trackingnumber" $trackingnumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/shipments/($deprecatedVersion)/void/cancel/($shipmentidentificationnumber)" $qp)
  let extra_headers = {"transId": $transId, "transactionSrc": $transactionSrc} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
