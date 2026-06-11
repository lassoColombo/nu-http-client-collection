# Auto-generated client for Billbee API vv1
# Source: https://api.apis.guru/v2/specs/billbee.io/v1/openapi.json
# Auth: --token flag or $env.BILLBEE_API_TOKEN

const BASE_URL = "https://app.billbee.io"
const DEFAULT_AUTH = "x-billbee-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BILLBEE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-billbee-api-key" => { {headers: {X-Billbee-Api-Key: $token_val}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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
def base-url-completer [] { ["https://app.billbee.io"] }
def auth-scheme-completer [] { ["x-billbee-api-key" "basic"] }

# Completers for enum parameters
def DefaultVatMode-completer [] { ["0" "1" "2" "3" "4" "5"] }
def accept-completer [] { ["application/json" "text/json"] }
def accept-completer-1 [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def AddressType-completer [] { ["1" "2"] }
def articleTitleSource-completer [] { ["0" "1" "2" "3"] }
def PaymentMethod-completer [] { ["1" "100" "101" "102" "103" "104" "105" "106" "107" "108" "109" "110" "111" "112" "113" "114" "115" "116" "117" "118" "119" "120" "121" "122" "123" "124" "125" "126" "127" "128" "129" "130" "131" "132" "133" "134" "135" "136" "19" "2" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "3" "30" "31" "32" "33" "34" "35" "36" "37" "38" "39" "4" "40" "41" "42" "43" "44" "45" "46" "47" "48" "49" "50" "51" "52" "53" "54" "55" "56" "57" "58" "59" "6" "60" "61" "62" "63" "64" "65" "66" "67" "68" "69" "70" "71" "72" "73" "74" "75" "76" "77" "78" "79" "80" "81" "82" "83" "84" "85" "86" "87" "88" "89" "90" "91" "92" "93" "94" "95" "96" "97" "98" "99"] }
def State-completer [] { ["1" "10" "11" "12" "13" "14" "15" "16" "2" "3" "4" "5" "6" "7" "8" "9"] }
def VatMode-completer [] { ["0" "1" "2" "3" "4" "5"] }
def NewStateId-completer [] { ["1" "10" "11" "12" "13" "14" "15" "16" "2" "3" "4" "5" "6" "7" "8" "9"] }
def SendMode-completer [] { ["0" "1" "2" "3" "4"] }
def SearchMode-completer [] { ["0" "1" "2" "3" "4"] }
def shippingCarrier-completer [] { ["0" "1" "10" "11" "12" "13" "14" "15" "16" "17" "18" "2" "3" "4" "5" "6" "7" "8" "9"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "automaticprovision-createaccount CreateAccount" } } | get name | first)
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
export def "automaticprovision-createaccount CreateAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --AcceptTerms: string@bool-completer # Set to true, if the user has accepted the Billbee terms &amp; conditions
  --Address: record # Represents the invoice address of a Billbee user — shape: {Address1?: string, Address2?: string, City?: string, Company?: string, Country?: string, Name?: string, VatId?: string, Zip?: string}
  --AffiliateCouponCode: string # Specifies an billbee affiliate code to attach to the user
  --DefaultCurrrency: string # Optionally specify the default currency of the user
  --DefaultVatIndex: int # Optionally specify the default vat index of the user (format: int32)
  --DefaultVatMode: int@DefaultVatMode-completer # Optionally specify the default vat mode of the user (format: int32)
  EMail: string # The Email address of the user to create
  --Password: string
  --Vat1Rate: float # Optionally specify the vat1 (normal) rate of the user (format: double)
  --Vat2Rate: float # Optionally specify the vat2 (reduced) rate of the user (format: double)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/automaticprovision/createaccount")
  let body = {AcceptTerms: $AcceptTerms, Address: $Address, AffiliateCouponCode: $AffiliateCouponCode, DefaultCurrrency: $DefaultCurrrency, DefaultVatIndex: $DefaultVatIndex, DefaultVatMode: $DefaultVatMode, EMail: $EMail, Password: $Password, Vat1Rate: $Vat1Rate, Vat2Rate: $Vat2Rate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns infos about Billbee terms and conditions
#
# GET /api/v1/automaticprovision/termsinfo
# operationId: AutomaticProvisioning_TermsInfo
export def "automaticprovision-termsinfo TermsInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/automaticprovision/termsinfo")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a list of all connected cloud storage devices
#
# GET /api/v1/cloudstorages
# operationId: CloudStorageApi_GetList
export def "cloudstorages GetList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: table<Id: int, Name: string, Type: string, UsedAsPrinter: bool>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/cloudstorages")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all customer addresses
#
# GET /api/v1/customer-addresses
# operationId: CustomerAddresses_GetAll
export def "customer-addresses GetAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --page: int # The current page to request starting with 1 (default is 1) (format: int32)
  --pageSize: int # The page size for the result list. Values between 1 and 250 are allowed. (default is 50) (format: int32)
]: nothing -> record<Data: table<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/customer-addresses" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new customer address
#
# POST /api/v1/customer-addresses
# operationId: CustomerAddresses_Create
export def "customer-addresses Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --AddressAddition: string
  --AddressType: int@AddressType-completer # The type of the address (format: int32)
  --ArchivedAt: string # If set, the customeraddress was already archived at the given date. Further modification is disabled. (format: date-time)
  --City: string
  --Company: string # The name of the company
  --CountryCode: string # The ISO2 code of the country
  --CustomerId: int # The internal Billbee id of the customer the address belongs to (format: int64)
  --Email: string
  --Fax: string
  --FirstName: string
  --Housenumber: string
  --Id: int # The internal Billbee ID of the address record. Can be null if a new address is created (format: int64)
  --LastName: string
  --Name2: string # Optionally an additional name field
  --RestoredAt: string # If set, the customeraddress was restored from the archive at the given date. (format: date-time)
  --State: string
  --Street: string
  --Tel1: string
  --Tel2: string
  --Zip: string
]: any -> record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/customer-addresses")
  let body = {AddressAddition: $AddressAddition, AddressType: $AddressType, ArchivedAt: $ArchivedAt, City: $City, Company: $Company, CountryCode: $CountryCode, CustomerId: $CustomerId, Email: $Email, Fax: $Fax, FirstName: $FirstName, Housenumber: $Housenumber, Id: $Id, LastName: $LastName, Name2: $Name2, RestoredAt: $RestoredAt, State: $State, Street: $Street, Tel1: $Tel1, Tel2: $Tel2, Zip: $Zip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Queries a single customer address by id
#
# GET /api/v1/customer-addresses/{id}
# operationId: CustomerAddresses_GetOne
export def "customer-addresses GetOne" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/customer-addresses/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a customer address by id
#
# PUT /api/v1/customer-addresses/{id}
# operationId: CustomerAddresses_Update
export def "customer-addresses Update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --AddressAddition: string
  --AddressType: int@AddressType-completer # The type of the address (format: int32)
  --ArchivedAt: string # If set, the customeraddress was already archived at the given date. Further modification is disabled. (format: date-time)
  --City: string
  --Company: string # The name of the company
  --CountryCode: string # The ISO2 code of the country
  --CustomerId: int # The internal Billbee id of the customer the address belongs to (format: int64)
  --Email: string
  --Fax: string
  --FirstName: string
  --Housenumber: string
  --Id: int # The internal Billbee ID of the address record. Can be null if a new address is created (format: int64)
  --LastName: string
  --Name2: string # Optionally an additional name field
  --RestoredAt: string # If set, the customeraddress was restored from the archive at the given date. (format: date-time)
  --State: string
  --Street: string
  --Tel1: string
  --Tel2: string
  --Zip: string
]: any -> record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/customer-addresses/($id)")
  let body = {AddressAddition: $AddressAddition, AddressType: $AddressType, ArchivedAt: $ArchivedAt, City: $City, Company: $Company, CountryCode: $CountryCode, CustomerId: $CustomerId, Email: $Email, Fax: $Fax, FirstName: $FirstName, Housenumber: $Housenumber, Id: $Id, LastName: $LastName, Name2: $Name2, RestoredAt: $RestoredAt, State: $State, Street: $Street, Tel1: $Tel1, Tel2: $Tel2, Zip: $Zip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of all customers
#
# GET /api/v1/customers
# operationId: Customer_GetAll
export def "customers GetAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --page: int # The current page to request starting with 1 (format: int32)
  --pageSize: int # The pagesize for the result list. Values between 1 and 250 are allowed (format: int32)
]: nothing -> record<Data: table<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/customers" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
export def "customers Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --Address: record # Container for passing address data — shape: {AddressAddition?: string, AddressType?: "1"|"2", ArchivedAt?: string, City?: string, Company?: string, CountryCode?: string, CustomerId?: int, Email?: string, Fax?: string, FirstName?: string, Housenumber?: string, Id?: int, LastName?: string, Name2?: string, RestoredAt?: string, State?: string, Street?: string, Tel1?: string, Tel2?: string, Zip?: string}
  --ArchivedAt: string # If set, the customer was already archived at the given date. Further modification is disabled. (format: date-time)
  --DefaultCommercialMailAddress: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --DefaultFax: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --DefaultMailAddress: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --DefaultPhone1: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --DefaultPhone2: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --DefaultStatusUpdatesMailAddress: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --Email: string
  --Id: int # The Billbee Id of the customer (format: int64)
  --LanguageId: int # format: int32
  --MetaData: list # item shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --Name: string
  --Number: int # format: int32
  --PriceGroupId: int # format: int64
  --RestoredAt: string # If set, the customer was restored from the archive at the given date. (format: date-time)
  --Tel1: string
  --Tel2: string
  --Type: int # Customer Type (format: int32)
  --VatId: string # The vat-id, that should be saved at the customer. Only used if CustomerVatId is not set on the order.
]: any -> record<Data: record<ArchivedAt: string, DefaultCommercialMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultFax: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone1: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone2: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultStatusUpdatesMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, Email: string, Id: int, LanguageId: int, MetaData: list<record>, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/customers")
  let body = {Address: $Address, ArchivedAt: $ArchivedAt, DefaultCommercialMailAddress: $DefaultCommercialMailAddress, DefaultFax: $DefaultFax, DefaultMailAddress: $DefaultMailAddress, DefaultPhone1: $DefaultPhone1, DefaultPhone2: $DefaultPhone2, DefaultStatusUpdatesMailAddress: $DefaultStatusUpdatesMailAddress, Email: $Email, Id: $Id, LanguageId: $LanguageId, MetaData: $MetaData, Name: $Name, Number: $Number, PriceGroupId: $PriceGroupId, RestoredAt: $RestoredAt, Tel1: $Tel1, Tel2: $Tel2, Type: $Type, VatId: $VatId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Queries a single address from a customer
#
# GET /api/v1/customers/addresses/{id}
# operationId: Customer_GetCustomerAddress
export def "customers-addresses GetCustomerAddress" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/customers/addresses/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates one or more fields of an address
#
# PATCH /api/v1/customers/addresses/{id}
# operationId: Customer_PatchAddress
export def "customers-addresses PatchAddress" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --body: record
]: any -> record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/customers/addresses/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates all fields of an address
#
# PUT /api/v1/customers/addresses/{id}
# operationId: Customer_UpdateAddress
export def "customers-addresses UpdateAddress" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --AddressAddition: string
  --AddressType: int@AddressType-completer # The type of the address (format: int32)
  --ArchivedAt: string # If set, the customeraddress was already archived at the given date. Further modification is disabled. (format: date-time)
  --City: string
  --Company: string # The name of the company
  --CountryCode: string # The ISO2 code of the country
  --CustomerId: int # The internal Billbee id of the customer the address belongs to (format: int64)
  --Email: string
  --Fax: string
  --FirstName: string
  --Housenumber: string
  --Id: int # The internal Billbee ID of the address record. Can be null if a new address is created (format: int64)
  --LastName: string
  --Name2: string # Optionally an additional name field
  --RestoredAt: string # If set, the customeraddress was restored from the archive at the given date. (format: date-time)
  --State: string
  --Street: string
  --Tel1: string
  --Tel2: string
  --Zip: string
]: any -> record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/customers/addresses/($id)")
  let body = {AddressAddition: $AddressAddition, AddressType: $AddressType, ArchivedAt: $ArchivedAt, City: $City, Company: $Company, CountryCode: $CountryCode, CustomerId: $CustomerId, Email: $Email, Fax: $Fax, FirstName: $FirstName, Housenumber: $Housenumber, Id: $Id, LastName: $LastName, Name2: $Name2, RestoredAt: $RestoredAt, State: $State, Street: $Street, Tel1: $Tel1, Tel2: $Tel2, Zip: $Zip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Queries a single customer by id
#
# GET /api/v1/customers/{id}
# operationId: Customer_GetOne
export def "customers GetOne" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: record<ArchivedAt: string, DefaultCommercialMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultFax: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone1: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone2: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultStatusUpdatesMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, Email: string, Id: int, LanguageId: int, MetaData: list<record>, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/customers/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
export def "customers Update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --ArchivedAt: string # If set, the customer was already archived at the given date. Further modification is disabled. (format: date-time)
  --DefaultCommercialMailAddress: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --DefaultFax: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --DefaultMailAddress: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --DefaultPhone1: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --DefaultPhone2: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --DefaultStatusUpdatesMailAddress: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --Email: string
  --Id: int # The Billbee Id of the customer (format: int64)
  --LanguageId: int # format: int32
  --MetaData: list # item shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --Name: string
  --Number: int # format: int32
  --PriceGroupId: int # format: int64
  --RestoredAt: string # If set, the customer was restored from the archive at the given date. (format: date-time)
  --Tel1: string
  --Tel2: string
  --Type: int # Customer Type (format: int32)
  --VatId: string # The vat-id, that should be saved at the customer. Only used if CustomerVatId is not set on the order.
]: any -> record<Data: record<ArchivedAt: string, DefaultCommercialMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultFax: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone1: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone2: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultStatusUpdatesMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, Email: string, Id: int, LanguageId: int, MetaData: list<record>, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/customers/($id)")
  let body = {ArchivedAt: $ArchivedAt, DefaultCommercialMailAddress: $DefaultCommercialMailAddress, DefaultFax: $DefaultFax, DefaultMailAddress: $DefaultMailAddress, DefaultPhone1: $DefaultPhone1, DefaultPhone2: $DefaultPhone2, DefaultStatusUpdatesMailAddress: $DefaultStatusUpdatesMailAddress, Email: $Email, Id: $Id, LanguageId: $LanguageId, MetaData: $MetaData, Name: $Name, Number: $Number, PriceGroupId: $PriceGroupId, RestoredAt: $RestoredAt, Tel1: $Tel1, Tel2: $Tel2, Type: $Type, VatId: $VatId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Queries a list of addresses from a customer
#
# GET /api/v1/customers/{id}/addresses
# operationId: Customer_GetCustomerAddresses
export def "customers-addresses GetCustomerAddresses" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --page: int # The current page to request starting with 1 (format: int32)
  --pageSize: int # The pagesize for the result list. Values between 1 and 250 are allowed (format: int32)
]: nothing -> record<Data: table<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/customers/($id)/addresses" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a new address to a customer
#
# POST /api/v1/customers/{id}/addresses
# operationId: Customer_AddCustomerAddress
export def "customers-addresses AddCustomerAddress" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --AddressAddition: string
  --AddressType: int@AddressType-completer # The type of the address (format: int32)
  --ArchivedAt: string # If set, the customeraddress was already archived at the given date. Further modification is disabled. (format: date-time)
  --City: string
  --Company: string # The name of the company
  --CountryCode: string # The ISO2 code of the country
  --CustomerId: int # The internal Billbee id of the customer the address belongs to (format: int64)
  --Email: string
  --Fax: string
  --FirstName: string
  --Housenumber: string
  --Id: int # The internal Billbee ID of the address record. Can be null if a new address is created (format: int64)
  --LastName: string
  --Name2: string # Optionally an additional name field
  --RestoredAt: string # If set, the customeraddress was restored from the archive at the given date. (format: date-time)
  --State: string
  --Street: string
  --Tel1: string
  --Tel2: string
  --Zip: string
]: any -> record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/customers/($id)/addresses")
  let body = {AddressAddition: $AddressAddition, AddressType: $AddressType, ArchivedAt: $ArchivedAt, City: $City, Company: $Company, CountryCode: $CountryCode, CustomerId: $CustomerId, Email: $Email, Fax: $Fax, FirstName: $FirstName, Housenumber: $Housenumber, Id: $Id, LastName: $LastName, Name2: $Name2, RestoredAt: $RestoredAt, State: $State, Street: $Street, Tel1: $Tel1, Tel2: $Tel2, Zip: $Zip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Queries a list of orders from a customer
#
# GET /api/v1/customers/{id}/orders
# operationId: Customer_GetCustomerOrders
export def "customers-orders GetCustomerOrders" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --page: int # The current page to request starting with 1 (format: int32)
  --pageSize: int # The pagesize for the result list. Values between 1 and 250 are allowed (format: int32)
]: nothing -> record<Data: table<CanCreateAutoInvoice: bool, CreatedAt: string, ExternalId: string, HasInvoice: bool, Id: int, InvoiceCreatedAt: string, InvoiceDate: string, InvoiceNumber: string, OrderStateId: int, OrderStateText: string, PaidAt: string, ShippedAt: string, ShopName: string, TotalGross: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/customers/($id)/orders" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list with all defined orderstates
#
# GET /api/v1/enums/orderstates
# operationId: EnumApi_GetOrderStates
export def "enums-orderstates GetOrderStates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/enums/orderstates")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list with all defined paymenttypes
#
# GET /api/v1/enums/paymenttypes
# operationId: EnumApi_GetPaymentTypes
export def "enums-paymenttypes GetPaymentTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/enums/paymenttypes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list with all defined shipmenttypes
#
# GET /api/v1/enums/shipmenttypes
# operationId: EnumApi_GetShipmentTypes
export def "enums-shipmenttypes GetShipmentTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/enums/shipmenttypes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list with all defined shippingcarriers
#
# GET /api/v1/enums/shippingcarriers
# operationId: EnumApi_GetShippingCarriers
export def "enums-shippingcarriers GetShippingCarriers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/enums/shippingcarriers")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all events optionally filtered by date. This request is extra throttled to 2 calls per page per hour.
#
# GET /api/v1/events
# operationId: EventApi_GetList
export def "events GetList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --minDate: string # Specifies the oldest date to include in the response (format: date-time)
  --maxDate: string # Specifies the newest date to include in the response (format: date-time)
  --page: int # Specifies the page to request (format: int32)
  --pageSize: int # Specifies the pagesize. Defaults to 50, max value is 250 (format: int32)
  --typeId: list # Filter for specific event types
  --orderId: int # Filter for specific order id (format: int64)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "minDate" $minDate "scalar") (serialize-qp "maxDate" $maxDate "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "typeId" $typeId "multi") (serialize-qp "orderId" $orderId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/events" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/layouts
#
# operationId: LayoutApi_GetList
export def "layouts GetList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: table<Id: int, Name: string, Type: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/layouts")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all orders optionally filtered by date
#
# GET /api/v1/orders
# operationId: OrderApi_GetList
export def "orders GetList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --minOrderDate: string # Specifies the oldest order date to include in the response (format: date-time)
  --maxOrderDate: string # Specifies the newest order date to include in the response (format: date-time)
  --page: int # Specifies the page to request (format: int32)
  --pageSize: int # Specifies the pagesize. Defaults to 50, max value is 250 (format: int32)
  --shopId: list # Specifies a list of shop ids for which invoices should be included
  --orderStateId: list # Specifies a list of state ids to include in the response
  --tag: list # Specifies a list of tags the order must have attached to be included in the response
  --minimumBillBeeOrderId: int # If given, all delivered orders have an Id greater than or equal to the given minimumOrderId (format: int64)
  --modifiedAtMin: string # If given, the last modification has to be newer than the given date (format: date-time)
  --modifiedAtMax: string # If given, the last modification has to be older or equal than the given date. (format: date-time)
  --articleTitleSource: int@articleTitleSource-completer # The source field for the article title. 0 = Order Position (default), 1 = Article Title, 2 = Article Invoice Text (format: int32)
  --excludeTags: string@bool-completer # If true the list of tags passed to the call are used to filter orders to not include these tags
]: nothing -> record<Data: table<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record, Comments: list, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list, Id: string, InvoiceAddress: record, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list, RebateDifference: float, RestoredAt: string, Seller: record, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record, ShippingCost: float, ShippingIds: list, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list, State: int, Tags: list, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "minOrderDate" $minOrderDate "scalar") (serialize-qp "maxOrderDate" $maxOrderDate "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "shopId" $shopId "multi") (serialize-qp "orderStateId" $orderStateId "multi") (serialize-qp "tag" $tag "multi") (serialize-qp "minimumBillBeeOrderId" $minimumBillBeeOrderId "scalar") (serialize-qp "modifiedAtMin" $modifiedAtMin "scalar") (serialize-qp "modifiedAtMax" $modifiedAtMax "scalar") (serialize-qp "articleTitleSource" $articleTitleSource "scalar") (serialize-qp "excludeTags" $excludeTags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/orders" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
export def "orders PostNewOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --shopId: int # Deprecated, if orderData.ApiAccountId is set, it will be used instead of 'shopId' (format: int64)
  --AcceptLossOfReturnRight: string@bool-completer # Customer accepts loss due to withdrawal
  --AdjustmentCost: float # format: double
  --AdjustmentReason: string
  --ApiAccountId: int # Id of the account, this order belongs to (format: int64)
  --ApiAccountName: string # The name of the account, this order belongs to. Will be ignored on order creation.
  --ArchivedAt: string # If set, the order was already archived at the given date. Further modification is disabled. (format: date-time)
  --BillBeeOrderId: int # The Order.Id from the Billbee database (format: int64)
  --BillBeeParentOrderId: int # The Id of the parent order in the Billbee database (format: int64)
  --Buyer: record # shape: {BillbeeShopId?: int, BillbeeShopName?: string, Email?: string, FirstName?: string, Id?: string, LastName?: string, Nick?: string, Platform?: string}
  --Comments: list # All messages / comments of the order — item shape: {Created?: string, FromCustomer?: bool, Id?: int, Name?: string, Text?: string}
  --ConfirmedAt: string # The date on which the order was confirmed (format: date-time)
  --CreatedAt: string # The date on which the order was created (format: date-time)
  --Currency: string # The three letter currency code.
  --CustomInvoiceNote: string # An optional multiline text which is printed on the invoice
  --Customer: record # shape: {ArchivedAt?: string, DefaultCommercialMailAddress?: record, DefaultFax?: record, DefaultMailAddress?: record, DefaultPhone1?: record, DefaultPhone2?: record, DefaultStatusUpdatesMailAddress?: record, Email?: string, Id?: int, LanguageId?: int, MetaData?: list, Name?: string, Number?: int, PriceGroupId?: int, RestoredAt?: string, Tel1?: string, Tel2?: string, Type?: int, VatId?: string}
  --CustomerNumber: string # The customer number (not to be confused with the id of the customer)
  --CustomerVatId: string # The vat-id, that was given by the customer to fulfill this order
  --DeliverySourceCountryCode: string # An optional Country ISO2 Code of the country where order is shipped from (FBA)
  --DistributionCenter: string # An optional code for the distribution center delivering this order
  --History: list # item shape: {Created?: string, EmployeeName?: string, EventTypeName?: string, Text?: string, TypeId?: int}
  --Id: string # Id of the order in the external system (marketplace)
  --InvoiceAddress: record # shape: {BillbeeId?: int, City?: string, Company?: string, Country?: string, CountryISO2?: string, Email?: string, FirstName?: string, HouseNumber?: string, LastName?: string, Line2?: string, NameAddition?: string, Phone?: string, State?: string, Street?: string, Zip?: string}
  --InvoiceDate: string # The date on which the invoice was created (format: date-time)
  --InvoiceNumber: int # The invoice number (format: int32)
  --InvoiceNumberPostfix: string # The postfix of the invoice number
  --InvoiceNumberPrefix: string # The prefix of the invoice number
  --IsCancelationFor: string # An optional Order Id (externalid) for an order if this is a cancel order (shopify only at the moment)
  --IsFromBillbeeApi: string@bool-completer # Indicates whether the order was created through the Billbee-Api or not.
  --LanguageCode: string # The two-letter language code of the customer
  --LastModifiedAt: string # Date of the last update, the order got (format: date-time)
  --MerchantVatId: string # The vat-id, that should be displayed on the invoice and other order documents
  --OrderItems: list # The list of items purchased like shirt, pant, toys etc — item shape: {Attributes?: list, BillbeeId?: int, Discount?: float, DontAdjustStock?: bool, GetPriceFromArticleIfAny?: bool, InvoiceSKU?: string, IsCoupon?: bool, Product?: record, Quantity?: float, SerialNumber?: string, ShippingProfileId?: string, TaxAmount?: float, TaxIndex?: int, TotalPrice?: float, TransactionId?: string, UnrebatedTotalPrice?: float}
  --OrderNumber: string # Order number of the order in the external system (marketplace)
  --PaidAmount: float # format: double
  --PayedAt: string # The date on which the order was paid (format: date-time)
  --PaymentInstruction: string # A textfield optionaly filled with a payment instruction text for printout on the invoice (z.B. Ebay Kauf auf Rechnung)
  --PaymentMethod: int@PaymentMethod-completer # The payment method (format: int32)
  --PaymentReference: string # A payment reference. Should not be used any more. Please use 'Payments' instead.
  --PaymentTransactionId: string # The id of the payment transaction. For example the transaction id of PayPal payment. Should not be used any more. Please use 'Payments' instead.
  --Payments: list # item shape: {BillbeeId?: int, Name?: string, PayDate?: string, PayValue?: float, PaymentType?: int, Purpose?: string, SourceTechnology?: string, SourceText?: string, TransactionId?: string}
  --RestoredAt: string # If set, the order was restored from the archive at the given date. (format: date-time)
  --Seller: record # shape: {BillbeeShopId?: int, BillbeeShopName?: string, Email?: string, FirstName?: string, Id?: string, LastName?: string, Nick?: string, Platform?: string}
  --SellerComment: string # An internal seller comment
  --ShipWeightKg: float # The total weight of the shipment(s) (format: double)
  --ShippedAt: string # The date on which the order was shipped (format: date-time)
  --ShippingAddress: record # shape: {BillbeeId?: int, City?: string, Company?: string, Country?: string, CountryISO2?: string, Email?: string, FirstName?: string, HouseNumber?: string, LastName?: string, Line2?: string, NameAddition?: string, Phone?: string, State?: string, Street?: string, Zip?: string}
  --ShippingCost: float # The shipping cost (format: double)
  --ShippingIds: list # The shipments of the order — item shape: {BillbeeId?: int, Created?: string, ShipmentType?: int, Shipper?: string, ShippingCarrier?: int, ShippingId?: string, ShippingProviderId?: int, ShippingProviderProductId?: int, TrackingUrl?: string}
  --ShippingProfileId: string # Internal Id for the shipping profile for that order
  --ShippingProfileName: string # Display Name of Shipping profile, if available
  --ShippingProviderId: int # Internal Id for the used shipping provider (format: int64)
  --ShippingProviderName: string # The Name for of used shipping provider
  --ShippingProviderProductId: int # Internal Id for the used shipping product (format: int64)
  --ShippingProviderProductName: string # The Name of the used shipping product
  --ShippingServices: list # Additional services for the shipment
  --State: int@State-completer # The current state of the order (format: int32)
  --Tags: list # The Tags of the order
  --TaxRate1: float # The regular tax rate (format: double)
  --TaxRate2: float # The reduced tax rate (format: double)
  --TotalCost: float # The total cost excluding shipping cost (format: double)
  --UpdatedAt: string # The date on which the order was last updated (format: date-time)
  --VatId: string # The customers vat id
  --VatMode: int@VatMode-completer # The vat mode of the order (format: int32)
]: any -> record<Data: record<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, Comments: list<record>, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list<record>, Id: string, InvoiceAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list<record>, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list<record>, RebateDifference: float, RestoredAt: string, Seller: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, ShippingCost: float, ShippingIds: list<record>, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list<record>, State: int, Tags: list<string>, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shopId" $shopId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/orders" $qp)
  let body = {AcceptLossOfReturnRight: $AcceptLossOfReturnRight, AdjustmentCost: $AdjustmentCost, AdjustmentReason: $AdjustmentReason, ApiAccountId: $ApiAccountId, ApiAccountName: $ApiAccountName, ArchivedAt: $ArchivedAt, BillBeeOrderId: $BillBeeOrderId, BillBeeParentOrderId: $BillBeeParentOrderId, Buyer: $Buyer, Comments: $Comments, ConfirmedAt: $ConfirmedAt, CreatedAt: $CreatedAt, Currency: $Currency, CustomInvoiceNote: $CustomInvoiceNote, Customer: $Customer, CustomerNumber: $CustomerNumber, CustomerVatId: $CustomerVatId, DeliverySourceCountryCode: $DeliverySourceCountryCode, DistributionCenter: $DistributionCenter, History: $History, Id: $Id, InvoiceAddress: $InvoiceAddress, InvoiceDate: $InvoiceDate, InvoiceNumber: $InvoiceNumber, InvoiceNumberPostfix: $InvoiceNumberPostfix, InvoiceNumberPrefix: $InvoiceNumberPrefix, IsCancelationFor: $IsCancelationFor, IsFromBillbeeApi: $IsFromBillbeeApi, LanguageCode: $LanguageCode, LastModifiedAt: $LastModifiedAt, MerchantVatId: $MerchantVatId, OrderItems: $OrderItems, OrderNumber: $OrderNumber, PaidAmount: $PaidAmount, PayedAt: $PayedAt, PaymentInstruction: $PaymentInstruction, PaymentMethod: $PaymentMethod, PaymentReference: $PaymentReference, PaymentTransactionId: $PaymentTransactionId, Payments: $Payments, RestoredAt: $RestoredAt, Seller: $Seller, SellerComment: $SellerComment, ShipWeightKg: $ShipWeightKg, ShippedAt: $ShippedAt, ShippingAddress: $ShippingAddress, ShippingCost: $ShippingCost, ShippingIds: $ShippingIds, ShippingProfileId: $ShippingProfileId, ShippingProfileName: $ShippingProfileName, ShippingProviderId: $ShippingProviderId, ShippingProviderName: $ShippingProviderName, ShippingProviderProductId: $ShippingProviderProductId, ShippingProviderProductName: $ShippingProviderProductName, ShippingServices: $ShippingServices, State: $State, Tags: $Tags, TaxRate1: $TaxRate1, TaxRate2: $TaxRate2, TotalCost: $TotalCost, UpdatedAt: $UpdatedAt, VatId: $VatId, VatMode: $VatMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an delivery note for an existing order. This request is extra throttled by order and api key to a maximum of 1 per 5 minutes.
#
# POST /api/v1/orders/CreateDeliveryNote/{id}
# operationId: OrderApi_CreateDeliveryNote
export def "orders-create-delivery-note CreateDeliveryNote" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --includePdf: string@bool-completer # If true, the PDF is included in the response as base64 encoded string
  --sendToCloudId: int # Optionally specify the id of a billbee connected cloud device to send the pdf to (format: int64)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includePdf" $includePdf "scalar") (serialize-qp "sendToCloudId" $sendToCloudId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/orders/CreateDeliveryNote/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an invoice for an existing order. This request is extra throttled by order and api key to a maximum of 1 per 5 minutes.
#
# POST /api/v1/orders/CreateInvoice/{id}
# operationId: OrderApi_CreateInvoice
export def "orders-create-invoice CreateInvoice" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --includeInvoicePdf: string@bool-completer # If true, the PDF is included in the response as base64 encoded string
  --templateId: int # You can pass the id of an invoice template to overwrite the assigned template for invoice creation (format: int64)
  --sendToCloudId: int # You can pass the id of a connected cloud printer/storage to send the invoice to it (format: int64)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeInvoicePdf" $includeInvoicePdf "scalar") (serialize-qp "templateId" $templateId "scalar") (serialize-qp "sendToCloudId" $sendToCloudId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/orders/CreateInvoice/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of fields which can be updated with the orders/{id} patch call
#
# GET /api/v1/orders/PatchableFields
# operationId: OrderApi_GetPatchableFields
export def "orders-patchable-fields GetPatchableFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/orders/PatchableFields")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find a single order by its external id (order number)
#
# GET /api/v1/orders/find/{id}/{partner}
# DEPRECATED
# operationId: OrderApi_Find
@deprecated
export def "orders-find Find" [
  id: string
  partner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/orders/find/($id)/($partner)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single order by its external order number
#
# GET /api/v1/orders/findbyextref/{extRef}
# operationId: OrderApi_GetByExtRef
export def "orders-findbyextref GetByExtRef" [
  extRef: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: record<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, Comments: list<record>, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list<record>, Id: string, InvoiceAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list<record>, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list<record>, RebateDifference: float, RestoredAt: string, Seller: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, ShippingCost: float, ShippingIds: list<record>, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list<record>, State: int, Tags: list<string>, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/orders/findbyextref/($extRef)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all invoices optionally filtered by date. This request ist throttled to 1 per 1 minute for same page and minInvoiceDate
#
# GET /api/v1/orders/invoices
# operationId: OrderApi_GetInvoiceList
export def "orders-invoices GetInvoiceList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --minInvoiceDate: string # Specifies the oldest invoice date to include (format: date-time)
  --maxInvoiceDate: string # Specifies the newest invoice date to include (format: date-time)
  --page: int # Specifies the page to request (format: int32)
  --pageSize: int # Specifies the pagesize. Defaults to 50, max value is 250 (format: int32)
  --shopId: list # Specifies a list of shop ids for which invoices should be included
  --orderStateId: list # Specifies a list of state ids to include in the response
  --tag: list
  --minPayDate: string # format: date-time
  --maxPayDate: string # format: date-time
  --includePositions: string@bool-completer
  --excludeTags: string@bool-completer # If true the list of tags passed to the call are used to filter orders to not include these tags
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "minInvoiceDate" $minInvoiceDate "scalar") (serialize-qp "maxInvoiceDate" $maxInvoiceDate "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "shopId" $shopId "multi") (serialize-qp "orderStateId" $orderStateId "multi") (serialize-qp "tag" $tag "multi") (serialize-qp "minPayDate" $minPayDate "scalar") (serialize-qp "maxPayDate" $maxPayDate "scalar") (serialize-qp "includePositions" $includePositions "scalar") (serialize-qp "excludeTags" $excludeTags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/orders/invoices" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single order by its internal billbee id. This request is throttled to 6 calls per order in one minute
#
# GET /api/v1/orders/{id}
# operationId: OrderApi_Get
export def "orders Get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --articleTitleSource: int@articleTitleSource-completer # The source field for the article title. 0 = Order Position (default), 1 = Article Title, 2 = Article Invoice Text (format: int32)
]: nothing -> record<Data: record<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, Comments: list<record>, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list<record>, Id: string, InvoiceAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list<record>, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list<record>, RebateDifference: float, RestoredAt: string, Seller: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, ShippingCost: float, ShippingIds: list<record>, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list<record>, State: int, Tags: list<string>, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "articleTitleSource" $articleTitleSource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/orders/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates one or more fields of an order
#
# PATCH /api/v1/orders/{id}
# operationId: OrderApi_PatchOrder
export def "orders PatchOrder" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --body: record
]: any -> record<Data: record<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, Comments: list<record>, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list<record>, Id: string, InvoiceAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list<record>, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list<record>, RebateDifference: float, RestoredAt: string, Seller: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, ShippingCost: float, ShippingIds: list<record>, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list<record>, State: int, Tags: list<string>, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/orders/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Changes the main state of a single order
#
# PUT /api/v1/orders/{id}/orderstate
# operationId: OrderApi_UpdateState
export def "orders-orderstate UpdateState" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --NewStateId: int@NewStateId-completer # The new state to set (format: int32)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/orders/($id)/orderstate")
  let body = {NewStateId: $NewStateId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Parses a text and replaces all placeholders
#
# POST /api/v1/orders/{id}/parse-placeholders
# operationId: OrderApi_ParsePlaceholders
export def "orders-parse-placeholders ParsePlaceholders" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --IsHtml: string@bool-completer # If true, the string will be handled as html.
  --Language: string # The ISO 639-1 code of the target language. Using default if not set.
  --TextToParse: string # The text to parse and replace the placeholders in.
  --Trim: string@bool-completer # If true, then the placeholder values are trimmed after usage.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/orders/($id)/parse-placeholders")
  let body = {IsHtml: $IsHtml, Language: $Language, TextToParse: $TextToParse, Trim: $Trim} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sends a message to the buyer
#
# POST /api/v1/orders/{id}/send-message
# operationId: OrderApi_SendMessage
# --Body item shape: {LanguageCode?: string, Text?: string}
# --Subject item shape: {LanguageCode?: string, Text?: string}
export def "orders-send-message SendMessage" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --AlternativeMail: string
  --Body: list # item shape: {LanguageCode?: string, Text?: string}
  --SendMode: int@SendMode-completer # format: int32
  --Subject: list # item shape: {LanguageCode?: string, Text?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/orders/($id)/send-message")
  let body = {AlternativeMail: $AlternativeMail, Body: $Body, SendMode: $SendMode, Subject: $Subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a shipment to a given order
#
# POST /api/v1/orders/{id}/shipment
# operationId: OrderApi_AddShipment
export def "orders-shipment AddShipment" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --CarrierId: int # Optional the id of a shipping carrier that should be assigend to the shipment Will override the carrier from the shipment product. Please use the integer value from this Enumeration: {Billbee.Interfaces.Shipping.Enums.ShippingCarrier} (format: int32)
  --Comment: string # Optional a text stored with the shipment
  --OrderId: string # Optional a differing order number of the shipment if available
  --ShipmentType: int # 0 if Shipment, 1 if Retoure {Billbee.Interfaces.Shipping.Enums.ShipmentTypeEnum} (format: int32)
  --ShippingId: string # The id of the shipment (Sendungsnummer/trackingid)
  --ShippingProviderId: int # Optional the id of a shipping provider existing in the billbee account that should be assigned to the shipment (format: int64)
  --ShippingProviderProductId: int # Optional the id of a shipping provider product that should be assigend to the shipment (format: int64)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/orders/($id)/shipment")
  let body = {CarrierId: $CarrierId, Comment: $Comment, OrderId: $OrderId, ShipmentType: $ShipmentType, ShippingId: $ShippingId, ShippingProviderId: $ShippingProviderId, ShippingProviderProductId: $ShippingProviderProductId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Attach one or more tags to an order
#
# POST /api/v1/orders/{id}/tags
# operationId: OrderApi_TagsCreate
export def "orders-tags TagsCreate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Tags: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/orders/($id)/tags")
  let body = {Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sets the tags attached to an order
#
# PUT /api/v1/orders/{id}/tags
# operationId: OrderApi_TagsUpdate
export def "orders-tags TagsUpdate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Tags: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/orders/($id)/tags")
  let body = {Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Triggers a rule event
#
# POST /api/v1/orders/{id}/trigger-event
# operationId: OrderApi_TriggerEvent
export def "orders-trigger-event TriggerEvent" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --DelayInMinutes: int # The delay in minutes until the rule is executed (format: int32)
  --Name: string # Name of the event
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/orders/($id)/trigger-event")
  let body = {DelayInMinutes: $DelayInMinutes, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of all products
#
# GET /api/v1/products
# operationId: Article_GetList
export def "products GetList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --page: int # The current page to request starting with 1 (format: int32)
  --pageSize: int # The pagesize for the result list. Values between 1 and 250 are allowed (format: int32)
  --minCreatedAt: string # Optional the oldest create date of the articles to be returned (format: date-time)
  --minimumBillBeeArticleId: int # format: int64
  --maximumBillBeeArticleId: int # format: int64
]: nothing -> record<Data: table<BasicAttributes: list, BillOfMaterial: list, Category1: record, Category2: record, Category3: record, Condition: int, CostPrice: float, CountryOfOrigin: string, CustomFields: list, DeliveryTime: int, Description: list, EAN: string, ExportDescription: string, ExportDescriptionMultiLanguage: list, HeightCm: float, Id: int, Images: list, InvoiceText: list, IsCustomizable: bool, IsDeactivated: bool, IsDigital: bool, LengthCm: float, LowStock: bool, Manufacturer: string, Materials: list, Occasion: int, Price: float, Recipient: int, SKU: string, ShippingProductId: int, ShortDescription: list, SoldAmount: float, SoldAmountLast30Days: float, SoldSumGross: float, SoldSumGrossLast30Days: float, SoldSumNet: float, SoldSumNetLast30Days: float, Sources: list, StockCode: string, StockCurrent: float, StockDesired: float, StockReduceItemsPerSale: float, StockWarning: float, Stocks: list, Tags: list, TaricNumber: string, Title: list, Type: int, Unit: int, UnitsPerItem: float, Vat1Rate: float, Vat2Rate: float, VatIndex: int, Weight: int, WeightNet: int, WidthCm: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "minCreatedAt" $minCreatedAt "scalar") (serialize-qp "minimumBillBeeArticleId" $minimumBillBeeArticleId "scalar") (serialize-qp "maximumBillBeeArticleId" $maximumBillBeeArticleId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/products" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
export def "products CreateArticle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --BasicAttributes: list # item shape: {LanguageCode?: string, Text?: string}
  --BillOfMaterial: list # item shape: {Amount?: float, ArticleId?: int, SKU?: string}
  --Category1: record # shape: {Id?: int, Name?: string}
  --Category2: record # shape: {Id?: int, Name?: string}
  --Category3: record # shape: {Id?: int, Name?: string}
  --Condition: int # format: int32
  --CostPrice: float # format: double
  --CountryOfOrigin: string
  --CustomFields: list # item shape: {ArticleId?: int, Definition?: record, DefinitionId?: int, Id?: int, Value?: record}
  --DeliveryTime: int # format: int32
  --Description: list # item shape: {LanguageCode?: string, Text?: string}
  --EAN: string
  --ExportDescription: string
  --ExportDescriptionMultiLanguage: list # item shape: {LanguageCode?: string, Text?: string}
  --HeightCm: float # format: double
  --Id: int # format: int64
  --Images: list # item shape: {ArticleId?: int, Id?: int, IsDefault?: bool, Position?: int, ThumbPathExt?: string, ThumbUrl?: string, Url?: string}
  --InvoiceText: list # item shape: {LanguageCode?: string, Text?: string}
  --IsCustomizable: string@bool-completer
  --IsDeactivated: string@bool-completer
  --IsDigital: string@bool-completer
  --LengthCm: float # format: double
  --Manufacturer: string
  --Materials: list # item shape: {LanguageCode?: string, Text?: string}
  --Occasion: int # format: int32
  Price: float # format: double
  --Recipient: int # format: int32
  --SKU: string
  --ShippingProductId: int # format: int64
  --ShortDescription: list # item shape: {LanguageCode?: string, Text?: string}
  --SoldAmount: float # format: double
  --SoldAmountLast30Days: float # format: double
  --SoldSumGross: float # format: double
  --SoldSumGrossLast30Days: float # format: double
  --SoldSumNet: float # format: double
  --SoldSumNetLast30Days: float # format: double
  --Sources: list # item shape: {ApiAccountId?: int, ApiAccountName?: string, Custom?: record, ExportFactor?: float, Id?: int, Source: string, SourceId: string, StockSyncInactive?: bool, StockSyncMax?: float, StockSyncMin?: float, UnitsPerItem?: float}
  --StockCode: string
  --StockCurrent: float # format: double
  --StockDesired: float # format: double
  --StockReduceItemsPerSale: float # format: double
  --StockWarning: float # format: double
  --Stocks: list # item shape: {Name?: string, StockCode?: string, StockCurrent?: float, StockDesired?: float, StockId?: int, StockWarning?: float, UnfulfilledAmount?: float}
  --Tags: list # item shape: {LanguageCode?: string, Text?: string}
  --TaricNumber: string
  --Title: list # item shape: {LanguageCode?: string, Text?: string}
  Type: int # format: int32
  --Unit: int # format: int32
  --UnitsPerItem: float # format: double
  Vat1Rate: float # format: double
  Vat2Rate: float # format: double
  VatIndex: int # format: int32
  --Weight: int # format: int32
  --WeightNet: int # format: int32
  --WidthCm: float # format: double
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/products")
  let body = {BasicAttributes: $BasicAttributes, BillOfMaterial: $BillOfMaterial, Category1: $Category1, Category2: $Category2, Category3: $Category3, Condition: $Condition, CostPrice: $CostPrice, CountryOfOrigin: $CountryOfOrigin, CustomFields: $CustomFields, DeliveryTime: $DeliveryTime, Description: $Description, EAN: $EAN, ExportDescription: $ExportDescription, ExportDescriptionMultiLanguage: $ExportDescriptionMultiLanguage, HeightCm: $HeightCm, Id: $Id, Images: $Images, InvoiceText: $InvoiceText, IsCustomizable: $IsCustomizable, IsDeactivated: $IsDeactivated, IsDigital: $IsDigital, LengthCm: $LengthCm, Manufacturer: $Manufacturer, Materials: $Materials, Occasion: $Occasion, Price: $Price, Recipient: $Recipient, SKU: $SKU, ShippingProductId: $ShippingProductId, ShortDescription: $ShortDescription, SoldAmount: $SoldAmount, SoldAmountLast30Days: $SoldAmountLast30Days, SoldSumGross: $SoldSumGross, SoldSumGrossLast30Days: $SoldSumGrossLast30Days, SoldSumNet: $SoldSumNet, SoldSumNetLast30Days: $SoldSumNetLast30Days, Sources: $Sources, StockCode: $StockCode, StockCurrent: $StockCurrent, StockDesired: $StockDesired, StockReduceItemsPerSale: $StockReduceItemsPerSale, StockWarning: $StockWarning, Stocks: $Stocks, Tags: $Tags, TaricNumber: $TaricNumber, Title: $Title, Type: $Type, Unit: $Unit, UnitsPerItem: $UnitsPerItem, Vat1Rate: $Vat1Rate, Vat2Rate: $Vat2Rate, VatIndex: $VatIndex, Weight: $Weight, WeightNet: $WeightNet, WidthCm: $WidthCm} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of fields which can be updated with the patch call
#
# GET /api/v1/products/PatchableFields
# operationId: Article_GetPatchableFields
export def "products-patchable-fields GetPatchableFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/products/PatchableFields")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GEts a list of all defined categories
#
# GET /api/v1/products/category
# operationId: Article_GetCategory
export def "products-category GetCategory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/products/category")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Queries a list of all custom fields
#
# GET /api/v1/products/custom-fields
# operationId: Article_GetCustomFields
export def "products-custom-fields GetCustomFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --page: int # format: int32
  --pageSize: int # format: int32
]: nothing -> record<Data: table<Configuration: record, Id: int, IsNullable: bool, Name: string, Type: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/products/custom-fields" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Queries a single custom field
#
# GET /api/v1/products/custom-fields/{id}
# operationId: Article_GetCustomField
export def "products-custom-fields GetCustomField" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: record<Configuration: record, Id: int, IsNullable: bool, Name: string, Type: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/products/custom-fields/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete multiple images by id
#
# POST /api/v1/products/images/delete
# operationId: Article_DeleteImages
export def "products-images-delete DeleteImages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --body: record
]: any -> record<Data: record<Deleted: list<int>, NotFound: list<int>>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/products/images/delete")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a single image by id
#
# DELETE /api/v1/products/images/{imageId}
# operationId: Article_DeleteImage
export def "products-images DeleteImage" [
  imageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/products/images/($imageId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a single image by id
#
# GET /api/v1/products/images/{imageId}
# operationId: Article_GetImage
export def "products-images GetImage" [
  imageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: record<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/products/images/($imageId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Queries the reserved amount for a single article by id or by sku
#
# GET /api/v1/products/reservedamount
# operationId: Article_GetReservedAmount
export def "products-reservedamount GetReservedAmount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --id: string # The id or the sku of the article to query
  --lookupBy: string # Either the value id or the value sku to specify the meaning of the id parameter
  --stockId: int # Optional the stock id if the multi stock feature is enabled (format: int64)
]: nothing -> record<Data: record<ReservedAmount: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "lookupBy" $lookupBy "scalar") (serialize-qp "stockId" $stockId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/products/reservedamount" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query all defined stock locations
#
# GET /api/v1/products/stocks
# operationId: Article_GetStocks
export def "products-stocks GetStocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: table<Description: string, Id: int, IsDefault: bool, Name: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/products/stocks")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the stock qty of an article
#
# POST /api/v1/products/updatestock
# operationId: Article_UpdateStock
export def "products-updatestock UpdateStock" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --AutosubtractReservedAmount: string@bool-completer # Automatically reduce the NewQuantity by the currently not fulfilled amount
  --BillbeeId: int # Optional the ID of the Billbee product to update (format: int64)
  --DeltaQuantity: float # This parameter is currently ignored (format: double)
  --ForceSendStockToShops: string@bool-completer # If true, every sent stockchange is stored and transmitted to the connected shop, even if the value has not changed
  --NewQuantity: float # The new absolute stock quantity for the product you want to set (format: double)
  --OldQuantity: float # This parameter is currently ignored (format: double)
  --Reason: string # Optional a reason text for the stock update
  --Sku: string # The SKU of the product to update
  --StockId: int # Optional the stock id if the feature multi stock is activated (format: int64)
]: any -> record<Data: record<CurrentStock: float, Message: string, OldStock: float, SKU: string, UnfulfilledAmount: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/products/updatestock")
  let body = {AutosubtractReservedAmount: $AutosubtractReservedAmount, BillbeeId: $BillbeeId, DeltaQuantity: $DeltaQuantity, ForceSendStockToShops: $ForceSendStockToShops, NewQuantity: $NewQuantity, OldQuantity: $OldQuantity, Reason: $Reason, Sku: $Sku, StockId: $StockId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the stock code of an article
#
# POST /api/v1/products/updatestockcode
# operationId: Article_UpdateStockCode
export def "products-updatestockcode UpdateStockCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --BillbeeId: int # format: int64
  --Sku: string
  --StockCode: string
  --StockId: int # format: int64
]: any -> record<Data: record, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/products/updatestockcode")
  let body = {BillbeeId: $BillbeeId, Sku: $Sku, StockCode: $StockCode, StockId: $StockId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the stock qty for multiple articles at once
#
# POST /api/v1/products/updatestockmultiple
# operationId: Article_UpdateStockMultiple
export def "products-updatestockmultiple UpdateStockMultiple" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --body: record
]: any -> table<Data: record<CurrentStock: float, Message: string, OldStock: float, SKU: string, UnfulfilledAmount: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/products/updatestockmultiple")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a product
#
# DELETE /api/v1/products/{id}
# operationId: Article_DeleteArticle
export def "products DeleteArticle" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/products/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Queries a single article by id or by sku
#
# GET /api/v1/products/{id}
# operationId: Article_GetArticle
export def "products GetArticle" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --lookupBy: string # Either the value id, ean or the value sku to specify the meaning of the id parameter.
]: nothing -> record<Data: record<BasicAttributes: list<record>, BillOfMaterial: list<record>, Category1: record<Id: int, Name: string>, Category2: record<Id: int, Name: string>, Category3: record<Id: int, Name: string>, Condition: int, CostPrice: float, CountryOfOrigin: string, CustomFields: list<record>, DeliveryTime: int, Description: list<record>, EAN: string, ExportDescription: string, ExportDescriptionMultiLanguage: list<record>, HeightCm: float, Id: int, Images: list<record>, InvoiceText: list<record>, IsCustomizable: bool, IsDeactivated: bool, IsDigital: bool, LengthCm: float, LowStock: bool, Manufacturer: string, Materials: list<record>, Occasion: int, Price: float, Recipient: int, SKU: string, ShippingProductId: int, ShortDescription: list<record>, SoldAmount: float, SoldAmountLast30Days: float, SoldSumGross: float, SoldSumGrossLast30Days: float, SoldSumNet: float, SoldSumNetLast30Days: float, Sources: list<record>, StockCode: string, StockCurrent: float, StockDesired: float, StockReduceItemsPerSale: float, StockWarning: float, Stocks: list<record>, Tags: list<record>, TaricNumber: string, Title: list<record>, Type: int, Unit: int, UnitsPerItem: float, Vat1Rate: float, Vat2Rate: float, VatIndex: int, Weight: int, WeightNet: int, WidthCm: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lookupBy" $lookupBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/products/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates one or more fields of a product
#
# PATCH /api/v1/products/{id}
# operationId: Article_PatchArticle
export def "products PatchArticle" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/products/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of all images of the product
#
# GET /api/v1/products/{productId}/images
# operationId: Article_GetImages
export def "products-images GetImages" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: table<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/products/($productId)/images")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add multiple images to a product or replace the product images by the given images
#
# PUT /api/v1/products/{productId}/images
# operationId: Article_PutImages
export def "products-images PutImages" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --replace: string@bool-completer # If you pass true, the images will be replaced by the passed images. Otherwise the passed images will be appended to the product.
  --body: record
]: any -> record<Data: record<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "replace" $replace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/products/($productId)/images" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a single image from a product
#
# DELETE /api/v1/products/{productId}/images/{imageId}
# operationId: Article_DeleteImageFromProduct
export def "products-images DeleteImageFromProduct" [
  productId: int
  imageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/products/($productId)/images/($imageId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a single image by id
#
# GET /api/v1/products/{productId}/images/{imageId}
# operationId: Article_GetImageFromProduct
export def "products-images GetImageFromProduct" [
  productId: int
  imageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Data: record<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/products/($productId)/images/($imageId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or update an existing image of a product
#
# PUT /api/v1/products/{productId}/images/{imageId}
# operationId: Article_PutImage
export def "products-images PutImage" [
  productId: int
  imageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --ArticleId: int # format: int64
  --Id: int # format: int64
  --IsDefault: string@bool-completer
  --Position: int # format: int32
  --ThumbPathExt: string
  --ThumbUrl: string
  --Url: string
]: any -> record<Data: record<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/products/($productId)/images/($imageId)")
  let body = {ArticleId: $ArticleId, Id: $Id, IsDefault: $IsDefault, Position: $Position, ThumbPathExt: $ThumbPathExt, ThumbUrl: $ThumbUrl, Url: $Url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search for products, customers and orders. Type can be "order", "product" and / or "customer" Term can contains lucene query syntax
#
# POST /api/v1/search
# operationId: Search_Search
export def "search Search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --SearchMode: int@SearchMode-completer # format: int32
  --Term: string
  --Type: list
]: any -> record<Data: record<Customers: list<record>, Orders: list<record>, Products: list<record>>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/search")
  let body = {SearchMode: $SearchMode, Term: $Term, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/shipment/ping
#
# operationId: Shipment_GetPing
export def "shipment-ping GetPing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/shipment/ping")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new shipment with the selected Shippingprovider
#
# POST /api/v1/shipment/shipment
# operationId: Shipment_PostShipment
# --Dimension shape: {height?: float, length?: float, width?: float}
# --ReceiverAddress shape: {AddressAddition?: string, City?: string, Company?: string, CountryCode?: string, CountryCodeISO3?: string, Email?: string, FirstName?: string, Housenumber?: string, IsExportCountry?: bool, LastName?: string, Name2?: string, State?: string, Street?: string, Telephone?: string, Zip?: string}
export def "shipment-shipment PostShipment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --ClientReference: string # Optional specify a text to be included on the label. Not possible with all carriers
  --Content: string # Optional specify a text describing the content of the shipment. Used for export shipments
  --CustomerNumber: string # Not used anymore
  --Dimension: record # shape: {height?: float, length?: float, width?: float}
  --OrderCurrencyCode: string # The Currency if the ordersum
  --OrderSum: float # The value of the shipments content (format: double)
  --PrinterIdForExportDocs: int # The id of a connected Cloudprinter to sent the export docs to (format: int64)
  --PrinterName: string # The name of a connected Cloudprinter to sent the label to
  --ProductCode: string # The productcode to be used when creating the shipment. Values depends on the carrier used
  --ProviderName: string # The name of the provider as specified in the billbee account
  --ReceiverAddress: record # shape: {AddressAddition?: string, City?: string, Company?: string, CountryCode?: string, CountryCodeISO3?: string, Email?: string, FirstName?: string, Housenumber?: string, IsExportCountry?: bool, LastName?: string, Name2?: string, State?: string, Street?: string, Telephone?: string, Zip?: string}
  --Services: list # A list of services to be used when creating the shipment
  --ShipDate: string # Optional overwrite the shipdate to be transferred to the carrier (format: date-time)
  --TotalNet: float # The value of the shipments content (net) (format: double)
  --WeightInGram: float # Optional specify the weight in gram of the shipment (format: double)
  --shippingCarrier: int@shippingCarrier-completer # format: int32
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/shipment/shipment")
  let body = {ClientReference: $ClientReference, Content: $Content, CustomerNumber: $CustomerNumber, Dimension: $Dimension, OrderCurrencyCode: $OrderCurrencyCode, OrderSum: $OrderSum, PrinterIdForExportDocs: $PrinterIdForExportDocs, PrinterName: $PrinterName, ProductCode: $ProductCode, ProviderName: $ProviderName, ReceiverAddress: $ReceiverAddress, Services: $Services, ShipDate: $ShipDate, TotalNet: $TotalNet, WeightInGram: $WeightInGram, shippingCarrier: $shippingCarrier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of all shipments optionally filtered by date. All parameters are optional.
#
# GET /api/v1/shipment/shipments
# operationId: Shipment_GetList
export def "shipment-shipments GetList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --page: int # Specifies the page to request. (format: int32)
  --pageSize: int # Specifies the pagesize. Defaults to 50, max value is 250 (format: int32)
  --createdAtMin: string # Specifies the oldest shipment date to include in the response (format: date-time)
  --createdAtMax: string # Specifies the newest shipment date to include in the response (format: date-time)
  --orderId: int # Get shipments for this order only. (format: int64)
  --minimumShipmentId: int # Get Shipments with a shipment greater or equal than this id. New shipments have a greater id than older shipments. (format: int64)
  --shippingProviderId: int # Get Shippings for the specified shipping provider only. <seealso cref="M:Rechnungsdruck.WebApp.Controllers.Api.ShipmentController.GetShippingproviders" /> (format: int64)
]: nothing -> record<Data: table<BillbeeId: int, Created: string, ShipmentType: int, Shipper: string, ShippingCarrier: int, ShippingId: string, ShippingProviderId: int, ShippingProviderProductId: int, TrackingUrl: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "createdAtMin" $createdAtMin "scalar") (serialize-qp "createdAtMax" $createdAtMax "scalar") (serialize-qp "orderId" $orderId "scalar") (serialize-qp "minimumShipmentId" $minimumShipmentId "scalar") (serialize-qp "shippingProviderId" $shippingProviderId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/shipment/shipments" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Queries the currently available shipping carriers.
#
# GET /api/v1/shipment/shippingcarriers
# operationId: Shipment_GetShippingCarrier
export def "shipment-shippingcarriers GetShippingCarrier" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/shipment/shippingcarriers")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query all defined shipping providers
#
# GET /api/v1/shipment/shippingproviders
# operationId: Shipment_GetShippingproviders
export def "shipment-shippingproviders GetShippingproviders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/shipment/shippingproviders")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a shipment for an order in billbee
#
# POST /api/v1/shipment/shipwithlabel
# operationId: Shipment_ShipWithLabel
# --Dimension shape: {height?: float, length?: float, width?: float}
export def "shipment-shipwithlabel ShipWithLabel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --ChangeStateToSend: string@bool-completer # Optional parameter to automatically change the orderstate to sent after creating the shipment
  --ClientReference: string # Optional specify a reference text to be included on the label. Works not with all carriers
  --Dimension: record # shape: {height?: float, length?: float, width?: float}
  --OrderId: int # The Billbee internal id of the order to ship (format: int64)
  --PrinterName: string # Optional the name of a connected cloudprinter to send the label to
  --ProductId: int # the id of the shipping provider product to be used (format: int64)
  --ProviderId: int # The id of the provider. You can query all providers with the shippingproviders endpoint (format: int64)
  --ShipDate: string # Optional specify the shipdate to be transmitted to the carrier (format: date-time)
  --WeightInGram: int # Optional the shipments weight in gram to override the calculated weight (format: int32)
]: any -> record<Data: record<Carrier: string, ExportDocsPdf: string, LabelDataPdf: string, OrderId: int, OrderReference: string, ShippingDate: string, ShippingId: string, TrackingUrl: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/shipment/shipwithlabel")
  let body = {ChangeStateToSend: $ChangeStateToSend, ClientReference: $ClientReference, Dimension: $Dimension, OrderId: $OrderId, PrinterName: $PrinterName, ProductId: $ProductId, ProviderId: $ProviderId, ShipDate: $ShipDate, WeightInGram: $WeightInGram} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes all existing WebHook registrations.
#
# DELETE /api/v1/webhooks
# operationId: WebHookManagement_DeleteAll
export def "webhooks DeleteAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/webhooks")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all registered WebHooks for a given user.
#
# GET /api/v1/webhooks
# operationId: WebHookManagement_Get
export def "webhooks Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<Description: string, Filters: list<string>, Headers: record, Id: string, IsPaused: bool, Properties: record, Secret: string, WebHookUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/webhooks")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Registers a new WebHook for a given user.
#
# POST /api/v1/webhooks
# operationId: WebHookManagement_Post
export def "webhooks Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Description: string
  --Filters: list
  --Headers: record
  --Id: string
  --IsPaused: string@bool-completer
  --Properties: record
  Secret: string
  WebHookUri: string
]: any -> record<Description: string, Filters: list<string>, Headers: record, Id: string, IsPaused: bool, Properties: record, Secret: string, WebHookUri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/webhooks")
  let body = {Description: $Description, Filters: $Filters, Headers: $Headers, Id: $Id, IsPaused: $IsPaused, Properties: $Properties, Secret: $Secret, WebHookUri: $WebHookUri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of all known filters you can use to register webhooks
#
# GET /api/v1/webhooks/filters
# operationId: WebHookManagement_GetFilters
export def "webhooks-filters GetFilters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/webhooks/filters")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes an existing WebHook registration.
#
# DELETE /api/v1/webhooks/{id}
# operationId: WebHookManagement_Delete
export def "webhooks Delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/webhooks/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Looks up a registered WebHook with the given {id} for a given user.
#
# GET /api/v1/webhooks/{id}
# operationId: WebHookManagement_Lookup
export def "webhooks Lookup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<Description: string, Filters: list<string>, Headers: record, Id: string, IsPaused: bool, Properties: record, Secret: string, WebHookUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/webhooks/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an existing WebHook registration.
#
# PUT /api/v1/webhooks/{id}
# operationId: WebHookManagement_Put
export def "webhooks Put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Description: string
  --Filters: list
  --Headers: record
  --Id: string
  --IsPaused: string@bool-completer
  --Properties: record
  Secret: string
  WebHookUri: string
]: any -> record<Description: string, Filters: list<string>, Headers: record, Id: string, IsPaused: bool, Properties: record, Secret: string, WebHookUri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-billbee-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/webhooks/($id)")
  let body = {Description: $Description, Filters: $Filters, Headers: $Headers, Id: $Id, IsPaused: $IsPaused, Properties: $Properties, Secret: $Secret, WebHookUri: $WebHookUri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
