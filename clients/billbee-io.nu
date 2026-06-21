# Auto-generated client for Billbee API vv1
# Source: https://api.apis.guru/v2/specs/billbee.io/v1/openapi.json
# Auth: --token flag or $env.BILLBEE_API_TOKEN

const BASE_URL = "https://app.billbee.io"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BILLBEE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-billbee-api-key" => { {scheme: $scheme, headers: {X-Billbee-Api-Key: $token_val}, query: "", location: "header"} }
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://app.billbee.io"] }
def auth-scheme-completer [] { ["x-billbee-api-key" "basic" "basic-credentials"] }

# Completers for enum parameters
def default-vat-mode-completer [] { ["0" "1" "2" "3" "4" "5"] }
def accept-completer [] { ["application/json" "text/json"] }
def accept-completer-1 [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def address-type-completer [] { ["1" "2"] }
def article-title-source-completer [] { ["0" "1" "2" "3"] }
def payment-method-completer [] { ["1" "100" "101" "102" "103" "104" "105" "106" "107" "108" "109" "110" "111" "112" "113" "114" "115" "116" "117" "118" "119" "120" "121" "122" "123" "124" "125" "126" "127" "128" "129" "130" "131" "132" "133" "134" "135" "136" "19" "2" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "3" "30" "31" "32" "33" "34" "35" "36" "37" "38" "39" "4" "40" "41" "42" "43" "44" "45" "46" "47" "48" "49" "50" "51" "52" "53" "54" "55" "56" "57" "58" "59" "6" "60" "61" "62" "63" "64" "65" "66" "67" "68" "69" "70" "71" "72" "73" "74" "75" "76" "77" "78" "79" "80" "81" "82" "83" "84" "85" "86" "87" "88" "89" "90" "91" "92" "93" "94" "95" "96" "97" "98" "99"] }
def state-completer [] { ["1" "10" "11" "12" "13" "14" "15" "16" "2" "3" "4" "5" "6" "7" "8" "9"] }
def vat-mode-completer [] { ["0" "1" "2" "3" "4" "5"] }
def new-state-id-completer [] { ["1" "10" "11" "12" "13" "14" "15" "16" "2" "3" "4" "5" "6" "7" "8" "9"] }
def send-mode-completer [] { ["0" "1" "2" "3" "4"] }
def search-mode-completer [] { ["0" "1" "2" "3" "4"] }
def shipping-carrier-completer [] { ["0" "1" "10" "11" "12" "13" "14" "15" "16" "17" "18" "2" "3" "4" "5" "6" "7" "8" "9"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "automaticprovision-create-account create-automatic-provisioning" } } | get name | first)
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

# Creates a new Billbee user account with the data passed
#
# POST /api/v1/automaticprovision/createaccount
# operationId: AutomaticProvisioning_CreateAccount
# --Address shape: {Address1?: string, Address2?: string, City?: string, Company?: string, Country?: string, Name?: string, VatId?: string, Zip?: string}
export def "automaticprovision-create-account create-automatic-provisioning" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --accept-terms: oneof<nothing, bool> # Set to true, if the user has accepted the Billbee terms & conditions
  --address: record # Represents the invoice address of a Billbee user — shape: {Address1?: string, Address2?: string, City?: string, Company?: string, Country?: string, Name?: string, VatId?: string, Zip?: string}
  --affiliate-coupon-code: string # Specifies an billbee affiliate code to attach to the user
  --default-currrency: string # Optionally specify the default currency of the user
  --default-vat-index: int # Optionally specify the default vat index of the user (format: int32)
  --default-vat-mode: int@default-vat-mode-completer # Optionally specify the default vat mode of the user (format: int32)
  e_mail: string # The Email address of the user to create
  --password: string
  --vat1-rate: float # Optionally specify the vat1 (normal) rate of the user (format: double)
  --vat2-rate: float # Optionally specify the vat2 (reduced) rate of the user (format: double)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/automaticprovision/createaccount")
  let req_body = {"AcceptTerms": $accept_terms, "Address": $address, "AffiliateCouponCode": $affiliate_coupon_code, "DefaultCurrrency": $default_currrency, "DefaultVatIndex": $default_vat_index, "DefaultVatMode": $default_vat_mode, "EMail": $e_mail, "Password": $password, "Vat1Rate": $vat1_rate, "Vat2Rate": $vat2_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns infos about Billbee terms and conditions
#
# GET /api/v1/automaticprovision/termsinfo
# operationId: AutomaticProvisioning_TermsInfo
export def "automaticprovision-termsinfo get-automatic-provisioning-terms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/automaticprovision/termsinfo")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a list of all connected cloud storage devices
#
# GET /api/v1/cloudstorages
# operationId: CloudStorageApi_GetList
export def "cloudstorages get-cloud-storage-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: table<Id: int, Name: string, Type: string, UsedAsPrinter: bool>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/cloudstorages")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of all customer addresses
#
# GET /api/v1/customer-addresses
# operationId: CustomerAddresses_GetAll
export def "customer-addresses get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --page: int # The current page to request starting with 1 (default is 1) (format: int32)
  --page-size: int # The page size for the result list. Values between 1 and 250 are allowed. (default is 50) (format: int32)
]: nothing -> record<Data: table<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/customer-addresses" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "pageSize": $page_size} | compact), body: null}
}

# Creates a new customer address
#
# POST /api/v1/customer-addresses
# operationId: CustomerAddresses_Create
export def "customer-addresses create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --address-addition: string
  --address-type: int@address-type-completer # The type of the address (format: int32)
  --archived-at: string # If set, the customeraddress was already archived at the given date. Further modification is disabled. (format: date-time)
  --city: string
  --company: string # The name of the company
  --country-code: string # The ISO2 code of the country
  --customer-id: int # The internal Billbee id of the customer the address belongs to (format: int64)
  --email: string
  --fax: string
  --first-name: string
  --housenumber: string
  --id: int # The internal Billbee ID of the address record. Can be null if a new address is created (format: int64)
  --last-name: string
  --name2: string # Optionally an additional name field
  --restored-at: string # If set, the customeraddress was restored from the archive at the given date. (format: date-time)
  --state: string
  --street: string
  --tel1: string
  --tel2: string
  --zip: string
]: any -> record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/customer-addresses")
  let req_body = {"AddressAddition": $address_addition, "AddressType": $address_type, "ArchivedAt": $archived_at, "City": $city, "Company": $company, "CountryCode": $country_code, "CustomerId": $customer_id, "Email": $email, "Fax": $fax, "FirstName": $first_name, "Housenumber": $housenumber, "Id": $id, "LastName": $last_name, "Name2": $name2, "RestoredAt": $restored_at, "State": $state, "Street": $street, "Tel1": $tel1, "Tel2": $tel2, "Zip": $zip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Queries a single customer address by id
#
# GET /api/v1/customer-addresses/{id}
# operationId: CustomerAddresses_GetOne
export def "customer-addresses get-one" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/customer-addresses/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a customer address by id
#
# PUT /api/v1/customer-addresses/{id}
# operationId: CustomerAddresses_Update
export def "customer-addresses update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --address-addition: string
  --address-type: int@address-type-completer # The type of the address (format: int32)
  --archived-at: string # If set, the customeraddress was already archived at the given date. Further modification is disabled. (format: date-time)
  --city: string
  --company: string # The name of the company
  --country-code: string # The ISO2 code of the country
  --customer-id: int # The internal Billbee id of the customer the address belongs to (format: int64)
  --email: string
  --fax: string
  --first-name: string
  --housenumber: string
  --body-id: int # The internal Billbee ID of the address record. Can be null if a new address is created (format: int64)
  --last-name: string
  --name2: string # Optionally an additional name field
  --restored-at: string # If set, the customeraddress was restored from the archive at the given date. (format: date-time)
  --state: string
  --street: string
  --tel1: string
  --tel2: string
  --zip: string
]: any -> record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/customer-addresses/{id}"))
  let req_body = {"AddressAddition": $address_addition, "AddressType": $address_type, "ArchivedAt": $archived_at, "City": $city, "Company": $company, "CountryCode": $country_code, "CustomerId": $customer_id, "Email": $email, "Fax": $fax, "FirstName": $first_name, "Housenumber": $housenumber, "Id": $body_id, "LastName": $last_name, "Name2": $name2, "RestoredAt": $restored_at, "State": $state, "Street": $street, "Tel1": $tel1, "Tel2": $tel2, "Zip": $zip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a list of all customers
#
# GET /api/v1/customers
# operationId: Customer_GetAll
export def "customers get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --page: int # The current page to request starting with 1 (format: int32)
  --page-size: int # The pagesize for the result list. Values between 1 and 250 are allowed (format: int32)
]: nothing -> record<Data: table<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/customers" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "pageSize": $page_size} | compact), body: null}
}

# Creates a new customer
#
# POST /api/v1/customers
# operationId: Customer_Create
# --Address shape: {AddressAddition?: string, AddressType?: "1"|"2", ArchivedAt?: string, City?: string, Company?: string, CountryCode?: string, CustomerId?: int, Email?: string, Fax?: string, FirstName?: string, Housenumber?: string, Id?: int, LastName?: string, Name2?: string, RestoredAt?: string, State?: string, Street?: string, Tel1?: string, Tel2?: string, Zip?: string}
# --DefaultCommercialMailAddress shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
# --DefaultFax shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
# --DefaultMailAddress shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
# --DefaultPhone1 shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
# --DefaultPhone2 shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
# --DefaultStatusUpdatesMailAddress shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
# --MetaData item shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
export def "customers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --address: record # Container for passing address data — shape: {AddressAddition?: string, AddressType?: "1"|"2", ArchivedAt?: string, City?: string, Company?: string, CountryCode?: string, CustomerId?: int, Email?: string, Fax?: string, FirstName?: string, Housenumber?: string, Id?: int, LastName?: string, Name2?: string, RestoredAt?: string, State?: string, Street?: string, Tel1?: string, Tel2?: string, Zip?: string}
  --archived-at: string # If set, the customer was already archived at the given date. Further modification is disabled. (format: date-time)
  --default-commercial-mail-address: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-fax: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-mail-address: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-phone1: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-phone2: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-status-updates-mail-address: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --email: string
  --id: int # The Billbee Id of the customer (format: int64)
  --language-id: int # format: int32
  --meta-data: list # item shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --name: string
  --number: int # format: int32
  --price-group-id: int # format: int64
  --restored-at: string # If set, the customer was restored from the archive at the given date. (format: date-time)
  --tel1: string
  --tel2: string
  --type: int # Customer Type (format: int32)
  --vat-id: string # The vat-id, that should be saved at the customer. Only used if CustomerVatId is not set on the order.
]: any -> record<Data: record<ArchivedAt: string, DefaultCommercialMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultFax: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone1: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone2: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultStatusUpdatesMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, Email: string, Id: int, LanguageId: int, MetaData: list<record>, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/customers")
  let req_body = {"Address": $address, "ArchivedAt": $archived_at, "DefaultCommercialMailAddress": $default_commercial_mail_address, "DefaultFax": $default_fax, "DefaultMailAddress": $default_mail_address, "DefaultPhone1": $default_phone1, "DefaultPhone2": $default_phone2, "DefaultStatusUpdatesMailAddress": $default_status_updates_mail_address, "Email": $email, "Id": $id, "LanguageId": $language_id, "MetaData": $meta_data, "Name": $name, "Number": $number, "PriceGroupId": $price_group_id, "RestoredAt": $restored_at, "Tel1": $tel1, "Tel2": $tel2, "Type": $type, "VatId": $vat_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Queries a single address from a customer
#
# GET /api/v1/customers/addresses/{id}
# operationId: Customer_GetCustomerAddress
export def "customers-addresses get-address" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/customers/addresses/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates one or more fields of an address
#
# PATCH /api/v1/customers/addresses/{id}
# operationId: Customer_PatchAddress
export def "customers-addresses update-address-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --body: record
]: any -> record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/customers/addresses/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates all fields of an address
#
# PUT /api/v1/customers/addresses/{id}
# operationId: Customer_UpdateAddress
export def "customers-addresses update-address-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --address-addition: string
  --address-type: int@address-type-completer # The type of the address (format: int32)
  --archived-at: string # If set, the customeraddress was already archived at the given date. Further modification is disabled. (format: date-time)
  --city: string
  --company: string # The name of the company
  --country-code: string # The ISO2 code of the country
  --customer-id: int # The internal Billbee id of the customer the address belongs to (format: int64)
  --email: string
  --fax: string
  --first-name: string
  --housenumber: string
  --body-id: int # The internal Billbee ID of the address record. Can be null if a new address is created (format: int64)
  --last-name: string
  --name2: string # Optionally an additional name field
  --restored-at: string # If set, the customeraddress was restored from the archive at the given date. (format: date-time)
  --state: string
  --street: string
  --tel1: string
  --tel2: string
  --zip: string
]: any -> record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/customers/addresses/{id}"))
  let req_body = {"AddressAddition": $address_addition, "AddressType": $address_type, "ArchivedAt": $archived_at, "City": $city, "Company": $company, "CountryCode": $country_code, "CustomerId": $customer_id, "Email": $email, "Fax": $fax, "FirstName": $first_name, "Housenumber": $housenumber, "Id": $body_id, "LastName": $last_name, "Name2": $name2, "RestoredAt": $restored_at, "State": $state, "Street": $street, "Tel1": $tel1, "Tel2": $tel2, "Zip": $zip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Queries a single customer by id
#
# GET /api/v1/customers/{id}
# operationId: Customer_GetOne
export def "customers get-one" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: record<ArchivedAt: string, DefaultCommercialMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultFax: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone1: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone2: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultStatusUpdatesMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, Email: string, Id: int, LanguageId: int, MetaData: list<record>, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/customers/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a customer by id
#
# PUT /api/v1/customers/{id}
# operationId: Customer_Update
# --DefaultCommercialMailAddress shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
# --DefaultFax shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
# --DefaultMailAddress shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
# --DefaultPhone1 shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
# --DefaultPhone2 shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
# --DefaultStatusUpdatesMailAddress shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
# --MetaData item shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
export def "customers update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --archived-at: string # If set, the customer was already archived at the given date. Further modification is disabled. (format: date-time)
  --default-commercial-mail-address: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-fax: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-mail-address: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-phone1: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-phone2: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-status-updates-mail-address: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --email: string
  --body-id: int # The Billbee Id of the customer (format: int64)
  --language-id: int # format: int32
  --meta-data: list # item shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --name: string
  --number: int # format: int32
  --price-group-id: int # format: int64
  --restored-at: string # If set, the customer was restored from the archive at the given date. (format: date-time)
  --tel1: string
  --tel2: string
  --type: int # Customer Type (format: int32)
  --vat-id: string # The vat-id, that should be saved at the customer. Only used if CustomerVatId is not set on the order.
]: any -> record<Data: record<ArchivedAt: string, DefaultCommercialMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultFax: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone1: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone2: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultStatusUpdatesMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, Email: string, Id: int, LanguageId: int, MetaData: list<record>, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/customers/{id}"))
  let req_body = {"ArchivedAt": $archived_at, "DefaultCommercialMailAddress": $default_commercial_mail_address, "DefaultFax": $default_fax, "DefaultMailAddress": $default_mail_address, "DefaultPhone1": $default_phone1, "DefaultPhone2": $default_phone2, "DefaultStatusUpdatesMailAddress": $default_status_updates_mail_address, "Email": $email, "Id": $body_id, "LanguageId": $language_id, "MetaData": $meta_data, "Name": $name, "Number": $number, "PriceGroupId": $price_group_id, "RestoredAt": $restored_at, "Tel1": $tel1, "Tel2": $tel2, "Type": $type, "VatId": $vat_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Queries a list of addresses from a customer
#
# GET /api/v1/customers/{id}/addresses
# operationId: Customer_GetCustomerAddresses
export def "customers-addresses get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --page: int # The current page to request starting with 1 (format: int32)
  --page-size: int # The pagesize for the result list. Values between 1 and 250 are allowed (format: int32)
]: nothing -> record<Data: table<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/customers/{id}/addresses") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "pageSize": $page_size} | compact), body: null}
}

# Adds a new address to a customer
#
# POST /api/v1/customers/{id}/addresses
# operationId: Customer_AddCustomerAddress
export def "customers-addresses create-address" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --address-addition: string
  --address-type: int@address-type-completer # The type of the address (format: int32)
  --archived-at: string # If set, the customeraddress was already archived at the given date. Further modification is disabled. (format: date-time)
  --city: string
  --company: string # The name of the company
  --country-code: string # The ISO2 code of the country
  --customer-id: int # The internal Billbee id of the customer the address belongs to (format: int64)
  --email: string
  --fax: string
  --first-name: string
  --housenumber: string
  --body-id: int # The internal Billbee ID of the address record. Can be null if a new address is created (format: int64)
  --last-name: string
  --name2: string # Optionally an additional name field
  --restored-at: string # If set, the customeraddress was restored from the archive at the given date. (format: date-time)
  --state: string
  --street: string
  --tel1: string
  --tel2: string
  --zip: string
]: any -> record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/customers/{id}/addresses"))
  let req_body = {"AddressAddition": $address_addition, "AddressType": $address_type, "ArchivedAt": $archived_at, "City": $city, "Company": $company, "CountryCode": $country_code, "CustomerId": $customer_id, "Email": $email, "Fax": $fax, "FirstName": $first_name, "Housenumber": $housenumber, "Id": $body_id, "LastName": $last_name, "Name2": $name2, "RestoredAt": $restored_at, "State": $state, "Street": $street, "Tel1": $tel1, "Tel2": $tel2, "Zip": $zip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Queries a list of orders from a customer
#
# GET /api/v1/customers/{id}/orders
# operationId: Customer_GetCustomerOrders
export def "customers-orders get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --page: int # The current page to request starting with 1 (format: int32)
  --page-size: int # The pagesize for the result list. Values between 1 and 250 are allowed (format: int32)
]: nothing -> record<Data: table<CanCreateAutoInvoice: bool, CreatedAt: string, ExternalId: string, HasInvoice: bool, Id: int, InvoiceCreatedAt: string, InvoiceDate: string, InvoiceNumber: string, OrderStateId: int, OrderStateText: string, PaidAt: string, ShippedAt: string, ShopName: string, TotalGross: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/customers/{id}/orders") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "pageSize": $page_size} | compact), body: null}
}

# Returns a list with all defined orderstates
#
# GET /api/v1/enums/orderstates
# operationId: EnumApi_GetOrderStates
export def "enums-orderstates get-order-states" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/enums/orderstates")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list with all defined paymenttypes
#
# GET /api/v1/enums/paymenttypes
# operationId: EnumApi_GetPaymentTypes
export def "enums-paymenttypes get-payment-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/enums/paymenttypes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list with all defined shipmenttypes
#
# GET /api/v1/enums/shipmenttypes
# operationId: EnumApi_GetShipmentTypes
export def "enums-shipmenttypes get-shipment-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/enums/shipmenttypes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list with all defined shippingcarriers
#
# GET /api/v1/enums/shippingcarriers
# operationId: EnumApi_GetShippingCarriers
export def "enums-shippingcarriers get-shipping-carriers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/enums/shippingcarriers")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of all events optionally filtered by date. This request is extra throttled to 2 calls per page per hour.
#
# GET /api/v1/events
# operationId: EventApi_GetList
export def "events get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --min-date: string # Specifies the oldest date to include in the response (format: date-time)
  --max-date: string # Specifies the newest date to include in the response (format: date-time)
  --page: int # Specifies the page to request (format: int32)
  --page-size: int # Specifies the pagesize. Defaults to 50, max value is 250 (format: int32)
  --type-id: list<int> # Filter for specific event types
  --order-id: int # Filter for specific order id (format: int64)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "minDate" $min_date "scalar") (serialize-qp "maxDate" $max_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "typeId" $type_id "multi") (serialize-qp "orderId" $order_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/events" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"minDate": $min_date, "maxDate": $max_date, "page": $page, "pageSize": $page_size, "typeId": $type_id, "orderId": $order_id} | compact), body: null}
}

# GET /api/v1/layouts
#
# operationId: LayoutApi_GetList
export def "layouts get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: table<Id: int, Name: string, Type: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/layouts")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of all orders optionally filtered by date
#
# GET /api/v1/orders
# operationId: OrderApi_GetList
export def "orders get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --min-order-date: string # Specifies the oldest order date to include in the response (format: date-time)
  --max-order-date: string # Specifies the newest order date to include in the response (format: date-time)
  --page: int # Specifies the page to request (format: int32)
  --page-size: int # Specifies the pagesize. Defaults to 50, max value is 250 (format: int32)
  --shop-id: list<int> # Specifies a list of shop ids for which invoices should be included
  --order-state-id: list<int> # Specifies a list of state ids to include in the response
  --tag: list<string> # Specifies a list of tags the order must have attached to be included in the response
  --minimum-bill-bee-order-id: int # If given, all delivered orders have an Id greater than or equal to the given minimumOrderId (format: int64)
  --modified-at-min: string # If given, the last modification has to be newer than the given date (format: date-time)
  --modified-at-max: string # If given, the last modification has to be older or equal than the given date. (format: date-time)
  --article-title-source: int@article-title-source-completer # The source field for the article title. 0 = Order Position (default), 1 = Article Title, 2 = Article Invoice Text (format: int32)
  --exclude-tags: oneof<nothing, bool> # If true the list of tags passed to the call are used to filter orders to not include these tags
]: nothing -> record<Data: table<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record, Comments: list, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list, Id: string, InvoiceAddress: record, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list, RebateDifference: float, RestoredAt: string, Seller: record, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record, ShippingCost: float, ShippingIds: list, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list, State: int, Tags: list, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "minOrderDate" $min_order_date "scalar") (serialize-qp "maxOrderDate" $max_order_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "shopId" $shop_id "multi") (serialize-qp "orderStateId" $order_state_id "multi") (serialize-qp "tag" $tag "multi") (serialize-qp "minimumBillBeeOrderId" $minimum_bill_bee_order_id "scalar") (serialize-qp "modifiedAtMin" $modified_at_min "scalar") (serialize-qp "modifiedAtMax" $modified_at_max "scalar") (serialize-qp "articleTitleSource" $article_title_source "scalar") (serialize-qp "excludeTags" $exclude_tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/orders" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"minOrderDate": $min_order_date, "maxOrderDate": $max_order_date, "page": $page, "pageSize": $page_size, "shopId": $shop_id, "orderStateId": $order_state_id, "tag": $tag, "minimumBillBeeOrderId": $minimum_bill_bee_order_id, "modifiedAtMin": $modified_at_min, "modifiedAtMax": $modified_at_max, "articleTitleSource": $article_title_source, "excludeTags": $exclude_tags} | compact), body: null}
}

# Creates a new order in the Billbee account
#
# POST /api/v1/orders
# operationId: OrderApi_PostNewOrder
# --Buyer shape: {BillbeeShopId?: int, BillbeeShopName?: string, Email?: string, FirstName?: string, Id?: string, LastName?: string, Nick?: string, Platform?: string}
# --Comments item shape: {Created?: string, FromCustomer?: bool, Id?: int, Name?: string, Text?: string}
# --Customer shape: {ArchivedAt?: string, DefaultCommercialMailAddress?: record, DefaultFax?: record, DefaultMailAddress?: record, DefaultPhone1?: record, DefaultPhone2?: record, DefaultStatusUpdatesMailAddress?: record, Email?: string, Id?: int, LanguageId?: int, MetaData?: list, Name?: string, Number?: int, PriceGroupId?: int, RestoredAt?: string, Tel1?: string, Tel2?: string, Type?: int, VatId?: string}
# --History item shape: {Created?: string, EmployeeName?: string, EventTypeName?: string, Text?: string, TypeId?: int}
# --InvoiceAddress shape: {BillbeeId?: int, City?: string, Company?: string, Country?: string, CountryISO2?: string, Email?: string, FirstName?: string, HouseNumber?: string, LastName?: string, Line2?: string, NameAddition?: string, Phone?: string, State?: string, Street?: string, Zip?: string}
# --OrderItems item shape: {Attributes?: list, BillbeeId?: int, Discount?: float, DontAdjustStock?: bool, GetPriceFromArticleIfAny?: bool, InvoiceSKU?: string, IsCoupon?: bool, Product?: record, Quantity?: float, SerialNumber?: string, ShippingProfileId?: string, TaxAmount?: float, TaxIndex?: int, TotalPrice?: float, TransactionId?: string, UnrebatedTotalPrice?: float}
# --Payments item shape: {BillbeeId?: int, Name?: string, PayDate?: string, PayValue?: float, PaymentType?: int, Purpose?: string, SourceTechnology?: string, SourceText?: string, TransactionId?: string}
# --Seller shape: {BillbeeShopId?: int, BillbeeShopName?: string, Email?: string, FirstName?: string, Id?: string, LastName?: string, Nick?: string, Platform?: string}
# --ShippingAddress shape: {BillbeeId?: int, City?: string, Company?: string, Country?: string, CountryISO2?: string, Email?: string, FirstName?: string, HouseNumber?: string, LastName?: string, Line2?: string, NameAddition?: string, Phone?: string, State?: string, Street?: string, Zip?: string}
# --ShippingIds item shape: {BillbeeId?: int, Created?: string, ShipmentType?: int, Shipper?: string, ShippingCarrier?: int, ShippingId?: string, ShippingProviderId?: int, ShippingProviderProductId?: int, TrackingUrl?: string}
export def "orders create-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --shop-id: int # Deprecated, if orderData.ApiAccountId is set, it will be used instead of 'shopId' (format: int64)
  --accept-loss-of-return-right: oneof<nothing, bool> # Customer accepts loss due to withdrawal
  --adjustment-cost: float # format: double
  --adjustment-reason: string
  --api-account-id: int # Id of the account, this order belongs to (format: int64)
  --api-account-name: string # The name of the account, this order belongs to. Will be ignored on order creation.
  --archived-at: string # If set, the order was already archived at the given date. Further modification is disabled. (format: date-time)
  --bill-bee-order-id: int # The Order.Id from the Billbee database (format: int64)
  --bill-bee-parent-order-id: int # The Id of the parent order in the Billbee database (format: int64)
  --buyer: record # shape: {BillbeeShopId?: int, BillbeeShopName?: string, Email?: string, FirstName?: string, Id?: string, LastName?: string, Nick?: string, Platform?: string}
  --comments: list # All messages / comments of the order — item shape: {Created?: string, FromCustomer?: bool, Id?: int, Name?: string, Text?: string}
  --confirmed-at: string # The date on which the order was confirmed (format: date-time)
  --created-at: string # The date on which the order was created (format: date-time)
  --currency: string # The three letter currency code.
  --custom-invoice-note: string # An optional multiline text which is printed on the invoice
  --customer: record # shape: {ArchivedAt?: string, DefaultCommercialMailAddress?: record, DefaultFax?: record, DefaultMailAddress?: record, DefaultPhone1?: record, DefaultPhone2?: record, DefaultStatusUpdatesMailAddress?: record, Email?: string, Id?: int, LanguageId?: int, MetaData?: list, Name?: string, Number?: int, PriceGroupId?: int, RestoredAt?: string, Tel1?: string, Tel2?: string, Type?: int, VatId?: string}
  --customer-number: string # The customer number (not to be confused with the id of the customer)
  --customer-vat-id: string # The vat-id, that was given by the customer to fulfill this order
  --delivery-source-country-code: string # An optional Country ISO2 Code of the country where order is shipped from (FBA)
  --distribution-center: string # An optional code for the distribution center delivering this order
  --history: list # item shape: {Created?: string, EmployeeName?: string, EventTypeName?: string, Text?: string, TypeId?: int}
  --id: string # Id of the order in the external system (marketplace)
  --invoice-address: record # shape: {BillbeeId?: int, City?: string, Company?: string, Country?: string, CountryISO2?: string, Email?: string, FirstName?: string, HouseNumber?: string, LastName?: string, Line2?: string, NameAddition?: string, Phone?: string, State?: string, Street?: string, Zip?: string}
  --invoice-date: string # The date on which the invoice was created (format: date-time)
  --invoice-number: int # The invoice number (format: int32)
  --invoice-number-postfix: string # The postfix of the invoice number
  --invoice-number-prefix: string # The prefix of the invoice number
  --is-cancelation-for: string # An optional Order Id (externalid) for an order if this is a cancel order (shopify only at the moment)
  --is-from-billbee-api: oneof<nothing, bool> # Indicates whether the order was created through the Billbee-Api or not.
  --language-code: string # The two-letter language code of the customer
  --last-modified-at: string # Date of the last update, the order got (format: date-time)
  --merchant-vat-id: string # The vat-id, that should be displayed on the invoice and other order documents
  --order-items: list # The list of items purchased like shirt, pant, toys etc — item shape: {Attributes?: list, BillbeeId?: int, Discount?: float, DontAdjustStock?: bool, GetPriceFromArticleIfAny?: bool, InvoiceSKU?: string, IsCoupon?: bool, Product?: record, Quantity?: float, SerialNumber?: string, ShippingProfileId?: string, TaxAmount?: float, TaxIndex?: int, TotalPrice?: float, TransactionId?: string, UnrebatedTotalPrice?: float}
  --order-number: string # Order number of the order in the external system (marketplace)
  --paid-amount: float # format: double
  --payed-at: string # The date on which the order was paid (format: date-time)
  --payment-instruction: string # A textfield optionaly filled with a payment instruction text for printout on the invoice (z.B. Ebay Kauf auf Rechnung)
  --payment-method: int@payment-method-completer # The payment method (format: int32)
  --payment-reference: string # A payment reference. Should not be used any more. Please use 'Payments' instead.
  --payment-transaction-id: string # The id of the payment transaction. For example the transaction id of PayPal payment. Should not be used any more. Please use 'Payments' instead.
  --payments: list # item shape: {BillbeeId?: int, Name?: string, PayDate?: string, PayValue?: float, PaymentType?: int, Purpose?: string, SourceTechnology?: string, SourceText?: string, TransactionId?: string}
  --restored-at: string # If set, the order was restored from the archive at the given date. (format: date-time)
  --seller: record # shape: {BillbeeShopId?: int, BillbeeShopName?: string, Email?: string, FirstName?: string, Id?: string, LastName?: string, Nick?: string, Platform?: string}
  --seller-comment: string # An internal seller comment
  --ship-weight-kg: float # The total weight of the shipment(s) (format: double)
  --shipped-at: string # The date on which the order was shipped (format: date-time)
  --shipping-address: record # shape: {BillbeeId?: int, City?: string, Company?: string, Country?: string, CountryISO2?: string, Email?: string, FirstName?: string, HouseNumber?: string, LastName?: string, Line2?: string, NameAddition?: string, Phone?: string, State?: string, Street?: string, Zip?: string}
  --shipping-cost: float # The shipping cost (format: double)
  --shipping-ids: list # The shipments of the order — item shape: {BillbeeId?: int, Created?: string, ShipmentType?: int, Shipper?: string, ShippingCarrier?: int, ShippingId?: string, ShippingProviderId?: int, ShippingProviderProductId?: int, TrackingUrl?: string}
  --shipping-profile-id: string # Internal Id for the shipping profile for that order
  --shipping-profile-name: string # Display Name of Shipping profile, if available
  --shipping-provider-id: int # Internal Id for the used shipping provider (format: int64)
  --shipping-provider-name: string # The Name for of used shipping provider
  --shipping-provider-product-id: int # Internal Id for the used shipping product (format: int64)
  --shipping-provider-product-name: string # The Name of the used shipping product
  --shipping-services: list # Additional services for the shipment
  --state: int@state-completer # The current state of the order (format: int32)
  --tags: list<string> # The Tags of the order
  --tax-rate1: float # The regular tax rate (format: double)
  --tax-rate2: float # The reduced tax rate (format: double)
  --total-cost: float # The total cost excluding shipping cost (format: double)
  --updated-at: string # The date on which the order was last updated (format: date-time)
  --vat-id: string # The customers vat id
  --vat-mode: int@vat-mode-completer # The vat mode of the order (format: int32)
]: any -> record<Data: record<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, Comments: list<record>, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list<record>, Id: string, InvoiceAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list<record>, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list<record>, RebateDifference: float, RestoredAt: string, Seller: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, ShippingCost: float, ShippingIds: list<record>, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list<record>, State: int, Tags: list<string>, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shopId" $shop_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/orders" $qp)
  let req_body = {"AcceptLossOfReturnRight": $accept_loss_of_return_right, "AdjustmentCost": $adjustment_cost, "AdjustmentReason": $adjustment_reason, "ApiAccountId": $api_account_id, "ApiAccountName": $api_account_name, "ArchivedAt": $archived_at, "BillBeeOrderId": $bill_bee_order_id, "BillBeeParentOrderId": $bill_bee_parent_order_id, "Buyer": $buyer, "Comments": $comments, "ConfirmedAt": $confirmed_at, "CreatedAt": $created_at, "Currency": $currency, "CustomInvoiceNote": $custom_invoice_note, "Customer": $customer, "CustomerNumber": $customer_number, "CustomerVatId": $customer_vat_id, "DeliverySourceCountryCode": $delivery_source_country_code, "DistributionCenter": $distribution_center, "History": $history, "Id": $id, "InvoiceAddress": $invoice_address, "InvoiceDate": $invoice_date, "InvoiceNumber": $invoice_number, "InvoiceNumberPostfix": $invoice_number_postfix, "InvoiceNumberPrefix": $invoice_number_prefix, "IsCancelationFor": $is_cancelation_for, "IsFromBillbeeApi": $is_from_billbee_api, "LanguageCode": $language_code, "LastModifiedAt": $last_modified_at, "MerchantVatId": $merchant_vat_id, "OrderItems": $order_items, "OrderNumber": $order_number, "PaidAmount": $paid_amount, "PayedAt": $payed_at, "PaymentInstruction": $payment_instruction, "PaymentMethod": $payment_method, "PaymentReference": $payment_reference, "PaymentTransactionId": $payment_transaction_id, "Payments": $payments, "RestoredAt": $restored_at, "Seller": $seller, "SellerComment": $seller_comment, "ShipWeightKg": $ship_weight_kg, "ShippedAt": $shipped_at, "ShippingAddress": $shipping_address, "ShippingCost": $shipping_cost, "ShippingIds": $shipping_ids, "ShippingProfileId": $shipping_profile_id, "ShippingProfileName": $shipping_profile_name, "ShippingProviderId": $shipping_provider_id, "ShippingProviderName": $shipping_provider_name, "ShippingProviderProductId": $shipping_provider_product_id, "ShippingProviderProductName": $shipping_provider_product_name, "ShippingServices": $shipping_services, "State": $state, "Tags": $tags, "TaxRate1": $tax_rate1, "TaxRate2": $tax_rate2, "TotalCost": $total_cost, "UpdatedAt": $updated_at, "VatId": $vat_id, "VatMode": $vat_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"shopId": $shop_id} | compact), body: $req_body}
}

# Create an delivery note for an existing order. This request is extra throttled by order and api key to a maximum of 1 per 5 minutes.
#
# POST /api/v1/orders/CreateDeliveryNote/{id}
# operationId: OrderApi_CreateDeliveryNote
export def "orders-create-delivery-note create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include-pdf: oneof<nothing, bool> # If true, the PDF is included in the response as base64 encoded string
  --send-to-cloud-id: int # Optionally specify the id of a billbee connected cloud device to send the pdf to (format: int64)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "includePdf" $include_pdf "scalar") (serialize-qp "sendToCloudId" $send_to_cloud_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/orders/CreateDeliveryNote/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"includePdf": $include_pdf, "sendToCloudId": $send_to_cloud_id} | compact), body: null}
}

# Create an invoice for an existing order. This request is extra throttled by order and api key to a maximum of 1 per 5 minutes.
#
# POST /api/v1/orders/CreateInvoice/{id}
# operationId: OrderApi_CreateInvoice
export def "orders-create-invoice create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include-invoice-pdf: oneof<nothing, bool> # If true, the PDF is included in the response as base64 encoded string
  --template-id: int # You can pass the id of an invoice template to overwrite the assigned template for invoice creation (format: int64)
  --send-to-cloud-id: int # You can pass the id of a connected cloud printer/storage to send the invoice to it (format: int64)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "includeInvoicePdf" $include_invoice_pdf "scalar") (serialize-qp "templateId" $template_id "scalar") (serialize-qp "sendToCloudId" $send_to_cloud_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/orders/CreateInvoice/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"includeInvoicePdf": $include_invoice_pdf, "templateId": $template_id, "sendToCloudId": $send_to_cloud_id} | compact), body: null}
}

# Returns a list of fields which can be updated with the orders/{id} patch call
#
# GET /api/v1/orders/PatchableFields
# operationId: OrderApi_GetPatchableFields
export def "orders-patchable-fields get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/orders/PatchableFields")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find a single order by its external id (order number)
#
# GET /api/v1/orders/find/{id}/{partner}
# DEPRECATED
# operationId: OrderApi_Find
@deprecated
export def "orders-find find" [
  id: string
  partner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($partner | is-empty) { error make --unspanned { msg: "path parameter 'partner' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), partner: (encode-path-segment $partner)} | format pattern "/api/v1/orders/find/{id}/{partner}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a single order by its external order number
#
# GET /api/v1/orders/findbyextref/{extRef}
# operationId: OrderApi_GetByExtRef
export def "orders-findbyextref get-by-ext-ref" [
  ext_ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: record<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, Comments: list<record>, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list<record>, Id: string, InvoiceAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list<record>, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list<record>, RebateDifference: float, RestoredAt: string, Seller: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, ShippingCost: float, ShippingIds: list<record>, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list<record>, State: int, Tags: list<string>, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($ext_ref | is-empty) { error make --unspanned { msg: "path parameter 'extRef' must be non-empty" } }
  let full_url = (build-url $base ({ext_ref: (encode-path-segment $ext_ref)} | format pattern "/api/v1/orders/findbyextref/{ext_ref}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of all invoices optionally filtered by date. This request ist throttled to 1 per 1 minute for same page and minInvoiceDate
#
# GET /api/v1/orders/invoices
# operationId: OrderApi_GetInvoiceList
export def "orders-invoices get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --min-invoice-date: string # Specifies the oldest invoice date to include (format: date-time)
  --max-invoice-date: string # Specifies the newest invoice date to include (format: date-time)
  --page: int # Specifies the page to request (format: int32)
  --page-size: int # Specifies the pagesize. Defaults to 50, max value is 250 (format: int32)
  --shop-id: list<int> # Specifies a list of shop ids for which invoices should be included
  --order-state-id: list<int> # Specifies a list of state ids to include in the response
  --tag: list<string>
  --min-pay-date: string # format: date-time
  --max-pay-date: string # format: date-time
  --include-positions: oneof<nothing, bool>
  --exclude-tags: oneof<nothing, bool> # If true the list of tags passed to the call are used to filter orders to not include these tags
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "minInvoiceDate" $min_invoice_date "scalar") (serialize-qp "maxInvoiceDate" $max_invoice_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "shopId" $shop_id "multi") (serialize-qp "orderStateId" $order_state_id "multi") (serialize-qp "tag" $tag "multi") (serialize-qp "minPayDate" $min_pay_date "scalar") (serialize-qp "maxPayDate" $max_pay_date "scalar") (serialize-qp "includePositions" $include_positions "scalar") (serialize-qp "excludeTags" $exclude_tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/orders/invoices" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"minInvoiceDate": $min_invoice_date, "maxInvoiceDate": $max_invoice_date, "page": $page, "pageSize": $page_size, "shopId": $shop_id, "orderStateId": $order_state_id, "tag": $tag, "minPayDate": $min_pay_date, "maxPayDate": $max_pay_date, "includePositions": $include_positions, "excludeTags": $exclude_tags} | compact), body: null}
}

# Get a single order by its internal billbee id. This request is throttled to 6 calls per order in one minute
#
# GET /api/v1/orders/{id}
# operationId: OrderApi_Get
export def "orders get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --article-title-source: int@article-title-source-completer # The source field for the article title. 0 = Order Position (default), 1 = Article Title, 2 = Article Invoice Text (format: int32)
]: nothing -> record<Data: record<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, Comments: list<record>, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list<record>, Id: string, InvoiceAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list<record>, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list<record>, RebateDifference: float, RestoredAt: string, Seller: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, ShippingCost: float, ShippingIds: list<record>, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list<record>, State: int, Tags: list<string>, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "articleTitleSource" $article_title_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/orders/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"articleTitleSource": $article_title_source} | compact), body: null}
}

# Updates one or more fields of an order
#
# PATCH /api/v1/orders/{id}
# operationId: OrderApi_PatchOrder
export def "orders update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --body: record
]: any -> record<Data: record<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, Comments: list<record>, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list<record>, Id: string, InvoiceAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list<record>, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list<record>, RebateDifference: float, RestoredAt: string, Seller: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, ShippingCost: float, ShippingIds: list<record>, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list<record>, State: int, Tags: list<string>, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/orders/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Changes the main state of a single order
#
# PUT /api/v1/orders/{id}/orderstate
# operationId: OrderApi_UpdateState
export def "orders-orderstate update-state" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --new-state-id: int@new-state-id-completer # The new state to set (format: int32)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/orders/{id}/orderstate"))
  let req_body = {"NewStateId": $new_state_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Parses a text and replaces all placeholders
#
# POST /api/v1/orders/{id}/parse-placeholders
# operationId: OrderApi_ParsePlaceholders
export def "orders-parse-placeholders create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --is-html: oneof<nothing, bool> # If true, the string will be handled as html.
  --language: string # The ISO 639-1 code of the target language. Using default if not set.
  --text-to-parse: string # The text to parse and replace the placeholders in.
  --trim: oneof<nothing, bool> # If true, then the placeholder values are trimmed after usage.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/orders/{id}/parse-placeholders"))
  let req_body = {"IsHtml": $is_html, "Language": $language, "TextToParse": $text_to_parse, "Trim": $trim} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Sends a message to the buyer
#
# POST /api/v1/orders/{id}/send-message
# operationId: OrderApi_SendMessage
# --Body item shape: {LanguageCode?: string, Text?: string}
# --Subject item shape: {LanguageCode?: string, Text?: string}
export def "orders-send-message send" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --alternative-mail: string
  --body: list # item shape: {LanguageCode?: string, Text?: string}
  --send-mode: int@send-mode-completer # format: int32
  --subject: list # item shape: {LanguageCode?: string, Text?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/orders/{id}/send-message"))
  let req_body = {"AlternativeMail": $alternative_mail, "Body": $body, "SendMode": $send_mode, "Subject": $subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Add a shipment to a given order
#
# POST /api/v1/orders/{id}/shipment
# operationId: OrderApi_AddShipment
export def "orders-shipment create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --carrier-id: int # Optional the id of a shipping carrier that should be assigend to the shipment Will override the carrier from the shipment product. Please use the integer value from this Enumeration: {Billbee.Interfaces.Shipping.Enums.ShippingCarrier} (format: int32)
  --comment: string # Optional a text stored with the shipment
  --order-id: string # Optional a differing order number of the shipment if available
  --shipment-type: int # 0 if Shipment, 1 if Retoure {Billbee.Interfaces.Shipping.Enums.ShipmentTypeEnum} (format: int32)
  --shipping-id: string # The id of the shipment (Sendungsnummer/trackingid)
  --shipping-provider-id: int # Optional the id of a shipping provider existing in the billbee account that should be assigned to the shipment (format: int64)
  --shipping-provider-product-id: int # Optional the id of a shipping provider product that should be assigend to the shipment (format: int64)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/orders/{id}/shipment"))
  let req_body = {"CarrierId": $carrier_id, "Comment": $comment, "OrderId": $order_id, "ShipmentType": $shipment_type, "ShippingId": $shipping_id, "ShippingProviderId": $shipping_provider_id, "ShippingProviderProductId": $shipping_provider_product_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Attach one or more tags to an order
#
# POST /api/v1/orders/{id}/tags
# operationId: OrderApi_TagsCreate
export def "orders-tags create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --tags: list<string>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/orders/{id}/tags"))
  let req_body = {"Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Sets the tags attached to an order
#
# PUT /api/v1/orders/{id}/tags
# operationId: OrderApi_TagsUpdate
export def "orders-tags update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --tags: list<string>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/orders/{id}/tags"))
  let req_body = {"Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Triggers a rule event
#
# POST /api/v1/orders/{id}/trigger-event
# operationId: OrderApi_TriggerEvent
export def "orders-trigger-event trigger" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --delay-in-minutes: int # The delay in minutes until the rule is executed (format: int32)
  --name: string # Name of the event
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/orders/{id}/trigger-event"))
  let req_body = {"DelayInMinutes": $delay_in_minutes, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a list of all products
#
# GET /api/v1/products
# operationId: Article_GetList
export def "products get-article-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The current page to request starting with 1 (format: int32)
  --page-size: int # The pagesize for the result list. Values between 1 and 250 are allowed (format: int32)
  --min-created-at: string # Optional the oldest create date of the articles to be returned (format: date-time)
  --minimum-bill-bee-article-id: int # format: int64
  --maximum-bill-bee-article-id: int # format: int64
]: nothing -> record<Data: table<BasicAttributes: list, BillOfMaterial: list, Category1: record, Category2: record, Category3: record, Condition: int, CostPrice: float, CountryOfOrigin: string, CustomFields: list, DeliveryTime: int, Description: list, EAN: string, ExportDescription: string, ExportDescriptionMultiLanguage: list, HeightCm: float, Id: int, Images: list, InvoiceText: list, IsCustomizable: bool, IsDeactivated: bool, IsDigital: bool, LengthCm: float, LowStock: bool, Manufacturer: string, Materials: list, Occasion: int, Price: float, Recipient: int, SKU: string, ShippingProductId: int, ShortDescription: list, SoldAmount: float, SoldAmountLast30Days: float, SoldSumGross: float, SoldSumGrossLast30Days: float, SoldSumNet: float, SoldSumNetLast30Days: float, Sources: list, StockCode: string, StockCurrent: float, StockDesired: float, StockReduceItemsPerSale: float, StockWarning: float, Stocks: list, Tags: list, TaricNumber: string, Title: list, Type: int, Unit: int, UnitsPerItem: float, Vat1Rate: float, Vat2Rate: float, VatIndex: int, Weight: int, WeightNet: int, WidthCm: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "minCreatedAt" $min_created_at "scalar") (serialize-qp "minimumBillBeeArticleId" $minimum_bill_bee_article_id "scalar") (serialize-qp "maximumBillBeeArticleId" $maximum_bill_bee_article_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/products" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "pageSize": $page_size, "minCreatedAt": $min_created_at, "minimumBillBeeArticleId": $minimum_bill_bee_article_id, "maximumBillBeeArticleId": $maximum_bill_bee_article_id} | compact), body: null}
}

# Creates a new product
#
# POST /api/v1/products
# operationId: Article_CreateArticle
# --BasicAttributes item shape: {LanguageCode?: string, Text?: string}
# --BillOfMaterial item shape: {Amount?: float, ArticleId?: int, SKU?: string}
# --Category1 shape: {Id?: int, Name?: string}
# --Category2 shape: {Id?: int, Name?: string}
# --Category3 shape: {Id?: int, Name?: string}
# --CustomFields item shape: {ArticleId?: int, Definition?: record, DefinitionId?: int, Id?: int, Value?: record}
# --Description item shape: {LanguageCode?: string, Text?: string}
# --ExportDescriptionMultiLanguage item shape: {LanguageCode?: string, Text?: string}
# --Images item shape: {ArticleId?: int, Id?: int, IsDefault?: bool, Position?: int, ThumbPathExt?: string, ThumbUrl?: string, Url?: string}
# --InvoiceText item shape: {LanguageCode?: string, Text?: string}
# --Materials item shape: {LanguageCode?: string, Text?: string}
# --ShortDescription item shape: {LanguageCode?: string, Text?: string}
# --Sources item shape: {ApiAccountId?: int, ApiAccountName?: string, Custom?: record, ExportFactor?: float, Id?: int, Source: string, SourceId: string, StockSyncInactive?: bool, StockSyncMax?: float, StockSyncMin?: float, UnitsPerItem?: float}
# --Stocks item shape: {Name?: string, StockCode?: string, StockCurrent?: float, StockDesired?: float, StockId?: int, StockWarning?: float, UnfulfilledAmount?: float}
# --Tags item shape: {LanguageCode?: string, Text?: string}
# --Title item shape: {LanguageCode?: string, Text?: string}
export def "products create-article-article" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --basic-attributes: list # item shape: {LanguageCode?: string, Text?: string}
  --bill-of-material: list # item shape: {Amount?: float, ArticleId?: int, SKU?: string}
  --category1: record # shape: {Id?: int, Name?: string}
  --category2: record # shape: {Id?: int, Name?: string}
  --category3: record # shape: {Id?: int, Name?: string}
  --condition: int # format: int32
  --cost-price: float # format: double
  --country-of-origin: string
  --custom-fields: list # item shape: {ArticleId?: int, Definition?: record, DefinitionId?: int, Id?: int, Value?: record}
  --delivery-time: int # format: int32
  --description: list # item shape: {LanguageCode?: string, Text?: string}
  --ean: string
  --export-description: string
  --export-description-multi-language: list # item shape: {LanguageCode?: string, Text?: string}
  --height-cm: float # format: double
  --id: int # format: int64
  --images: list # item shape: {ArticleId?: int, Id?: int, IsDefault?: bool, Position?: int, ThumbPathExt?: string, ThumbUrl?: string, Url?: string}
  --invoice-text: list # item shape: {LanguageCode?: string, Text?: string}
  --is-customizable: oneof<nothing, bool>
  --is-deactivated: oneof<nothing, bool>
  --is-digital: oneof<nothing, bool>
  --length-cm: float # format: double
  --manufacturer: string
  --materials: list # item shape: {LanguageCode?: string, Text?: string}
  --occasion: int # format: int32
  price: float # format: double
  --recipient: int # format: int32
  --sku: string
  --shipping-product-id: int # format: int64
  --short-description: list # item shape: {LanguageCode?: string, Text?: string}
  --sold-amount: float # format: double
  --sold-amount-last30-days: float # format: double
  --sold-sum-gross: float # format: double
  --sold-sum-gross-last30-days: float # format: double
  --sold-sum-net: float # format: double
  --sold-sum-net-last30-days: float # format: double
  --sources: list # item shape: {ApiAccountId?: int, ApiAccountName?: string, Custom?: record, ExportFactor?: float, Id?: int, Source: string, SourceId: string, StockSyncInactive?: bool, StockSyncMax?: float, StockSyncMin?: float, UnitsPerItem?: float}
  --stock-code: string
  --stock-current: float # format: double
  --stock-desired: float # format: double
  --stock-reduce-items-per-sale: float # format: double
  --stock-warning: float # format: double
  --stocks: list # item shape: {Name?: string, StockCode?: string, StockCurrent?: float, StockDesired?: float, StockId?: int, StockWarning?: float, UnfulfilledAmount?: float}
  --tags: list # item shape: {LanguageCode?: string, Text?: string}
  --taric-number: string
  --title: list # item shape: {LanguageCode?: string, Text?: string}
  type: int # format: int32
  --unit: int # format: int32
  --units-per-item: float # format: double
  vat1_rate: float # format: double
  vat2_rate: float # format: double
  vat_index: int # format: int32
  --weight: int # format: int32
  --weight-net: int # format: int32
  --width-cm: float # format: double
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/products")
  let req_body = {"BasicAttributes": $basic_attributes, "BillOfMaterial": $bill_of_material, "Category1": $category1, "Category2": $category2, "Category3": $category3, "Condition": $condition, "CostPrice": $cost_price, "CountryOfOrigin": $country_of_origin, "CustomFields": $custom_fields, "DeliveryTime": $delivery_time, "Description": $description, "EAN": $ean, "ExportDescription": $export_description, "ExportDescriptionMultiLanguage": $export_description_multi_language, "HeightCm": $height_cm, "Id": $id, "Images": $images, "InvoiceText": $invoice_text, "IsCustomizable": $is_customizable, "IsDeactivated": $is_deactivated, "IsDigital": $is_digital, "LengthCm": $length_cm, "Manufacturer": $manufacturer, "Materials": $materials, "Occasion": $occasion, "Price": $price, "Recipient": $recipient, "SKU": $sku, "ShippingProductId": $shipping_product_id, "ShortDescription": $short_description, "SoldAmount": $sold_amount, "SoldAmountLast30Days": $sold_amount_last30_days, "SoldSumGross": $sold_sum_gross, "SoldSumGrossLast30Days": $sold_sum_gross_last30_days, "SoldSumNet": $sold_sum_net, "SoldSumNetLast30Days": $sold_sum_net_last30_days, "Sources": $sources, "StockCode": $stock_code, "StockCurrent": $stock_current, "StockDesired": $stock_desired, "StockReduceItemsPerSale": $stock_reduce_items_per_sale, "StockWarning": $stock_warning, "Stocks": $stocks, "Tags": $tags, "TaricNumber": $taric_number, "Title": $title, "Type": $type, "Unit": $unit, "UnitsPerItem": $units_per_item, "Vat1Rate": $vat1_rate, "Vat2Rate": $vat2_rate, "VatIndex": $vat_index, "Weight": $weight, "WeightNet": $weight_net, "WidthCm": $width_cm} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of fields which can be updated with the patch call
#
# GET /api/v1/products/PatchableFields
# operationId: Article_GetPatchableFields
export def "products-patchable-fields get-article" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/products/PatchableFields")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GEts a list of all defined categories
#
# GET /api/v1/products/category
# operationId: Article_GetCategory
export def "products-category get-article" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/products/category")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Queries a list of all custom fields
#
# GET /api/v1/products/custom-fields
# operationId: Article_GetCustomFields
export def "products-custom-fields list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --page: int # format: int32
  --page-size: int # format: int32
]: nothing -> record<Data: table<Configuration: record, Id: int, IsNullable: bool, Name: string, Type: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/products/custom-fields" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "pageSize": $page_size} | compact), body: null}
}

# Queries a single custom field
#
# GET /api/v1/products/custom-fields/{id}
# operationId: Article_GetCustomField
export def "products-custom-fields get-article" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: record<Configuration: record, Id: int, IsNullable: bool, Name: string, Type: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/products/custom-fields/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete multiple images by id
#
# POST /api/v1/products/images/delete
# operationId: Article_DeleteImages
export def "products-images-delete delete-article" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --body: list
]: any -> record<Data: record<Deleted: list<int>, NotFound: list<int>>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/products/images/delete")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a single image by id
#
# DELETE /api/v1/products/images/{imageId}
# operationId: Article_DeleteImage
export def "products-images delete-article-by-image-id" [
  image_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/api/v1/products/images/{image_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a single image by id
#
# GET /api/v1/products/images/{imageId}
# operationId: Article_GetImage
export def "products-images get-article-by-image-id" [
  image_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: record<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/api/v1/products/images/{image_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Queries the reserved amount for a single article by id or by sku
#
# GET /api/v1/products/reservedamount
# operationId: Article_GetReservedAmount
export def "products-reservedamount get-article-reserved-amount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --id: string # The id or the sku of the article to query
  --lookup-by: string # Either the value id or the value sku to specify the meaning of the id parameter
  --stock-id: int # Optional the stock id if the multi stock feature is enabled (format: int64)
]: nothing -> record<Data: record<ReservedAmount: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "lookupBy" $lookup_by "scalar") (serialize-qp "stockId" $stock_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/products/reservedamount" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "lookupBy": $lookup_by, "stockId": $stock_id} | compact), body: null}
}

# Query all defined stock locations
#
# GET /api/v1/products/stocks
# operationId: Article_GetStocks
export def "products-stocks get-article" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: table<Description: string, Id: int, IsDefault: bool, Name: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/products/stocks")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the stock qty of an article
#
# POST /api/v1/products/updatestock
# operationId: Article_UpdateStock
export def "products-update-stock update-article" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --autosubtract-reserved-amount: oneof<nothing, bool> # Automatically reduce the NewQuantity by the currently not fulfilled amount
  --billbee-id: int # Optional the ID of the Billbee product to update (format: int64)
  --delta-quantity: float # This parameter is currently ignored (format: double)
  --force-send-stock-to-shops: oneof<nothing, bool> # If true, every sent stockchange is stored and transmitted to the connected shop, even if the value has not changed
  --new-quantity: float # The new absolute stock quantity for the product you want to set (format: double)
  --old-quantity: float # This parameter is currently ignored (format: double)
  --reason: string # Optional a reason text for the stock update
  --sku: string # The SKU of the product to update
  --stock-id: int # Optional the stock id if the feature multi stock is activated (format: int64)
]: any -> record<Data: record<CurrentStock: float, Message: string, OldStock: float, SKU: string, UnfulfilledAmount: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/products/updatestock")
  let req_body = {"AutosubtractReservedAmount": $autosubtract_reserved_amount, "BillbeeId": $billbee_id, "DeltaQuantity": $delta_quantity, "ForceSendStockToShops": $force_send_stock_to_shops, "NewQuantity": $new_quantity, "OldQuantity": $old_quantity, "Reason": $reason, "Sku": $sku, "StockId": $stock_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update the stock code of an article
#
# POST /api/v1/products/updatestockcode
# operationId: Article_UpdateStockCode
export def "products-update-stockcode update-article-stock-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --billbee-id: int # format: int64
  --sku: string
  --stock-code: string
  --stock-id: int # format: int64
]: any -> record<Data: record, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/products/updatestockcode")
  let req_body = {"BillbeeId": $billbee_id, "Sku": $sku, "StockCode": $stock_code, "StockId": $stock_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update the stock qty for multiple articles at once
#
# POST /api/v1/products/updatestockmultiple
# operationId: Article_UpdateStockMultiple
export def "products-update-stockmultiple update-article-stock-multiple" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --body: list
]: any -> table<Data: record<CurrentStock: float, Message: string, OldStock: float, SKU: string, UnfulfilledAmount: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/products/updatestockmultiple")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a product
#
# DELETE /api/v1/products/{id}
# operationId: Article_DeleteArticle
export def "products delete-article-article" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/products/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Queries a single article by id or by sku
#
# GET /api/v1/products/{id}
# operationId: Article_GetArticle
export def "products get-article-article" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --lookup-by: string # Either the value id, ean or the value sku to specify the meaning of the id parameter.
]: nothing -> record<Data: record<BasicAttributes: list<record>, BillOfMaterial: list<record>, Category1: record<Id: int, Name: string>, Category2: record<Id: int, Name: string>, Category3: record<Id: int, Name: string>, Condition: int, CostPrice: float, CountryOfOrigin: string, CustomFields: list<record>, DeliveryTime: int, Description: list<record>, EAN: string, ExportDescription: string, ExportDescriptionMultiLanguage: list<record>, HeightCm: float, Id: int, Images: list<record>, InvoiceText: list<record>, IsCustomizable: bool, IsDeactivated: bool, IsDigital: bool, LengthCm: float, LowStock: bool, Manufacturer: string, Materials: list<record>, Occasion: int, Price: float, Recipient: int, SKU: string, ShippingProductId: int, ShortDescription: list<record>, SoldAmount: float, SoldAmountLast30Days: float, SoldSumGross: float, SoldSumGrossLast30Days: float, SoldSumNet: float, SoldSumNetLast30Days: float, Sources: list<record>, StockCode: string, StockCurrent: float, StockDesired: float, StockReduceItemsPerSale: float, StockWarning: float, Stocks: list<record>, Tags: list<record>, TaricNumber: string, Title: list<record>, Type: int, Unit: int, UnitsPerItem: float, Vat1Rate: float, Vat2Rate: float, VatIndex: int, Weight: int, WeightNet: int, WidthCm: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "lookupBy" $lookup_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/products/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lookupBy": $lookup_by} | compact), body: null}
}

# Updates one or more fields of a product
#
# PATCH /api/v1/products/{id}
# operationId: Article_PatchArticle
export def "products update-article-article" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/products/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of all images of the product
#
# GET /api/v1/products/{productId}/images
# operationId: Article_GetImages
export def "products-images get-article-by-product-id" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: table<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/v1/products/{product_id}/images"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add multiple images to a product or replace the product images by the given images
#
# PUT /api/v1/products/{productId}/images
# operationId: Article_PutImages
export def "products-images update-article-by-product-id" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --replace: oneof<nothing, bool> # If you pass true, the images will be replaced by the passed images. Otherwise the passed images will be appended to the product.
  --body: list
]: any -> record<Data: record<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let qp = [(serialize-qp "replace" $replace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/v1/products/{product_id}/images") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"replace": $replace} | compact), body: $req_body}
}

# Deletes a single image from a product
#
# DELETE /api/v1/products/{productId}/images/{imageId}
# operationId: Article_DeleteImageFromProduct
export def "products-images delete-article-by-product-id-image-id" [
  product_id: int
  image_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), image_id: (encode-path-segment $image_id)} | format pattern "/api/v1/products/{product_id}/images/{image_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a single image by id
#
# GET /api/v1/products/{productId}/images/{imageId}
# operationId: Article_GetImageFromProduct
export def "products-images get-article-by-product-id-image-id" [
  product_id: int
  image_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: record<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), image_id: (encode-path-segment $image_id)} | format pattern "/api/v1/products/{product_id}/images/{image_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add or update an existing image of a product
#
# PUT /api/v1/products/{productId}/images/{imageId}
# operationId: Article_PutImage
export def "products-images update-article-by-product-id-image-id" [
  product_id: int
  image_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --article-id: int # format: int64
  --id: int # format: int64
  --is-default: oneof<nothing, bool>
  --position: int # format: int32
  --thumb-path-ext: string
  --thumb-url: string
  --url: string
]: any -> record<Data: record<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), image_id: (encode-path-segment $image_id)} | format pattern "/api/v1/products/{product_id}/images/{image_id}"))
  let req_body = {"ArticleId": $article_id, "Id": $id, "IsDefault": $is_default, "Position": $position, "ThumbPathExt": $thumb_path_ext, "ThumbUrl": $thumb_url, "Url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search for products, customers and orders. Type can be "order", "product" and / or "customer" Term can contains lucene query syntax
#
# POST /api/v1/search
# operationId: Search_Search
export def "search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --search-mode: int@search-mode-completer # format: int32
  --term: string
  --type: list<string>
]: any -> record<Data: record<Customers: list<record>, Orders: list<record>, Products: list<record>>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/search")
  let req_body = {"SearchMode": $search_mode, "Term": $term, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/v1/shipment/ping
#
# operationId: Shipment_GetPing
export def "shipment-ping get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/shipment/ping")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new shipment with the selected Shippingprovider
#
# POST /api/v1/shipment/shipment
# operationId: Shipment_PostShipment
# --Dimension shape: {height?: float, length?: float, width?: float}
# --ReceiverAddress shape: {AddressAddition?: string, City?: string, Company?: string, CountryCode?: string, CountryCodeISO3?: string, Email?: string, FirstName?: string, Housenumber?: string, IsExportCountry?: bool, LastName?: string, Name2?: string, State?: string, Street?: string, Telephone?: string, Zip?: string}
export def "shipment-shipment create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --client-reference: string # Optional specify a text to be included on the label. Not possible with all carriers
  --content: string # Optional specify a text describing the content of the shipment. Used for export shipments
  --customer-number: string # Not used anymore
  --dimension: record # shape: {height?: float, length?: float, width?: float}
  --order-currency-code: string # The Currency if the ordersum
  --order-sum: float # The value of the shipments content (format: double)
  --printer-id-for-export-docs: int # The id of a connected Cloudprinter to sent the export docs to (format: int64)
  --printer-name: string # The name of a connected Cloudprinter to sent the label to
  --product-code: string # The productcode to be used when creating the shipment. Values depends on the carrier used
  --provider-name: string # The name of the provider as specified in the billbee account
  --receiver-address: record # shape: {AddressAddition?: string, City?: string, Company?: string, CountryCode?: string, CountryCodeISO3?: string, Email?: string, FirstName?: string, Housenumber?: string, IsExportCountry?: bool, LastName?: string, Name2?: string, State?: string, Street?: string, Telephone?: string, Zip?: string}
  --services: list # A list of services to be used when creating the shipment
  --ship-date: string # Optional overwrite the shipdate to be transferred to the carrier (format: date-time)
  --total-net: float # The value of the shipments content (net) (format: double)
  --weight-in-gram: float # Optional specify the weight in gram of the shipment (format: double)
  --shipping-carrier: int@shipping-carrier-completer # format: int32
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/shipment/shipment")
  let req_body = {"ClientReference": $client_reference, "Content": $content, "CustomerNumber": $customer_number, "Dimension": $dimension, "OrderCurrencyCode": $order_currency_code, "OrderSum": $order_sum, "PrinterIdForExportDocs": $printer_id_for_export_docs, "PrinterName": $printer_name, "ProductCode": $product_code, "ProviderName": $provider_name, "ReceiverAddress": $receiver_address, "Services": $services, "ShipDate": $ship_date, "TotalNet": $total_net, "WeightInGram": $weight_in_gram, "shippingCarrier": $shipping_carrier} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a list of all shipments optionally filtered by date. All parameters are optional.
#
# GET /api/v1/shipment/shipments
# operationId: Shipment_GetList
export def "shipment-shipments get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --page: int # Specifies the page to request. (format: int32)
  --page-size: int # Specifies the pagesize. Defaults to 50, max value is 250 (format: int32)
  --created-at-min: string # Specifies the oldest shipment date to include in the response (format: date-time)
  --created-at-max: string # Specifies the newest shipment date to include in the response (format: date-time)
  --order-id: int # Get shipments for this order only. (format: int64)
  --minimum-shipment-id: int # Get Shipments with a shipment greater or equal than this id. New shipments have a greater id than older shipments. (format: int64)
  --shipping-provider-id: int # Get Shippings for the specified shipping provider only. (format: int64)
]: nothing -> record<Data: table<BillbeeId: int, Created: string, ShipmentType: int, Shipper: string, ShippingCarrier: int, ShippingId: string, ShippingProviderId: int, ShippingProviderProductId: int, TrackingUrl: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "createdAtMin" $created_at_min "scalar") (serialize-qp "createdAtMax" $created_at_max "scalar") (serialize-qp "orderId" $order_id "scalar") (serialize-qp "minimumShipmentId" $minimum_shipment_id "scalar") (serialize-qp "shippingProviderId" $shipping_provider_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/shipment/shipments" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "pageSize": $page_size, "createdAtMin": $created_at_min, "createdAtMax": $created_at_max, "orderId": $order_id, "minimumShipmentId": $minimum_shipment_id, "shippingProviderId": $shipping_provider_id} | compact), body: null}
}

# Queries the currently available shipping carriers.
#
# GET /api/v1/shipment/shippingcarriers
# operationId: Shipment_GetShippingCarrier
export def "shipment-shippingcarriers get-shipping-carrier" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/shipment/shippingcarriers")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Query all defined shipping providers
#
# GET /api/v1/shipment/shippingproviders
# operationId: Shipment_GetShippingproviders
export def "shipment-shippingproviders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/shipment/shippingproviders")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a shipment for an order in billbee
#
# POST /api/v1/shipment/shipwithlabel
# operationId: Shipment_ShipWithLabel
# --Dimension shape: {height?: float, length?: float, width?: float}
export def "shipment-shipwithlabel create-ship-with-label" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --change-state-to-send: oneof<nothing, bool> # Optional parameter to automatically change the orderstate to sent after creating the shipment
  --client-reference: string # Optional specify a reference text to be included on the label. Works not with all carriers
  --dimension: record # shape: {height?: float, length?: float, width?: float}
  --order-id: int # The Billbee internal id of the order to ship (format: int64)
  --printer-name: string # Optional the name of a connected cloudprinter to send the label to
  --product-id: int # the id of the shipping provider product to be used (format: int64)
  --provider-id: int # The id of the provider. You can query all providers with the shippingproviders endpoint (format: int64)
  --ship-date: string # Optional specify the shipdate to be transmitted to the carrier (format: date-time)
  --weight-in-gram: int # Optional the shipments weight in gram to override the calculated weight (format: int32)
]: any -> record<Data: record<Carrier: string, ExportDocsPdf: string, LabelDataPdf: string, OrderId: int, OrderReference: string, ShippingDate: string, ShippingId: string, TrackingUrl: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/shipment/shipwithlabel")
  let req_body = {"ChangeStateToSend": $change_state_to_send, "ClientReference": $client_reference, "Dimension": $dimension, "OrderId": $order_id, "PrinterName": $printer_name, "ProductId": $product_id, "ProviderId": $provider_id, "ShipDate": $ship_date, "WeightInGram": $weight_in_gram} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes all existing WebHook registrations.
#
# DELETE /api/v1/webhooks
# operationId: WebHookManagement_DeleteAll
export def "webhooks delete-web-hook-management-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/webhooks")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets all registered WebHooks for a given user.
#
# GET /api/v1/webhooks
# operationId: WebHookManagement_Get
export def "webhooks get-web-hook-management" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Description: string, Filters: list<string>, Headers: record, Id: string, IsPaused: bool, Properties: record, Secret: string, WebHookUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/webhooks")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Registers a new WebHook for a given user.
#
# POST /api/v1/webhooks
# operationId: WebHookManagement_Post
export def "webhooks create-web-hook-management" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string
  --filters: list<string>
  --headers: record
  --id: string
  --is-paused: oneof<nothing, bool>
  --properties: record
  secret: string
  web_hook_uri: string
]: any -> record<Description: string, Filters: list<string>, Headers: record, Id: string, IsPaused: bool, Properties: record, Secret: string, WebHookUri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/webhooks")
  let req_body = {"Description": $description, "Filters": $filters, "Headers": $headers, "Id": $id, "IsPaused": $is_paused, "Properties": $properties, "Secret": $secret, "WebHookUri": $web_hook_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of all known filters you can use to register webhooks
#
# GET /api/v1/webhooks/filters
# operationId: WebHookManagement_GetFilters
export def "webhooks-filters get-web-hook-management" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/webhooks/filters")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes an existing WebHook registration.
#
# DELETE /api/v1/webhooks/{id}
# operationId: WebHookManagement_Delete
export def "webhooks delete-web-hook-management" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/webhooks/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Looks up a registered WebHook with the given {id} for a given user.
#
# GET /api/v1/webhooks/{id}
# operationId: WebHookManagement_Lookup
export def "webhooks get-web-hook-management-lookup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Description: string, Filters: list<string>, Headers: record, Id: string, IsPaused: bool, Properties: record, Secret: string, WebHookUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/webhooks/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an existing WebHook registration.
#
# PUT /api/v1/webhooks/{id}
# operationId: WebHookManagement_Put
export def "webhooks update-web-hook-management" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string
  --filters: list<string>
  --headers: record
  --body-id: string
  --is-paused: oneof<nothing, bool>
  --properties: record
  secret: string
  web_hook_uri: string
]: any -> record<Description: string, Filters: list<string>, Headers: record, Id: string, IsPaused: bool, Properties: record, Secret: string, WebHookUri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/webhooks/{id}"))
  let req_body = {"Description": $description, "Filters": $filters, "Headers": $headers, "Id": $body_id, "IsPaused": $is_paused, "Properties": $properties, "Secret": $secret, "WebHookUri": $web_hook_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
