# Auto-generated client for Twilio - Api v1.0.0
# Source: https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_api_v2010.json
# Auth: --token flag or $env.TWILIO_API_TOKEN

const BASE_URL = "https://api.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://api.twilio.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def Status-completer [] { ["active" "closed" "suspended"] }
def VoiceMethod-completer [] { ["GET" "POST"] }
def VoiceFallbackMethod-completer [] { ["GET" "POST"] }
def StatusCallbackMethod-completer [] { ["GET" "POST"] }
def SmsMethod-completer [] { ["GET" "POST"] }
def SmsFallbackMethod-completer [] { ["GET" "POST"] }
def Method-completer [] { ["GET" "POST"] }
def FallbackMethod-completer [] { ["GET" "POST"] }
def RecordingStatusCallbackMethod-completer [] { ["GET" "POST"] }
def AsyncAmdStatusCallbackMethod-completer [] { ["GET" "POST"] }
def Status-completer-1 [] { ["busy" "canceled" "completed" "failed" "in-progress" "no-answer" "queued" "ringing"] }
def Status-completer-2 [] { ["canceled" "completed"] }
def Status-completer-3 [] { ["absent" "completed" "in-progress" "paused" "processing" "stopped"] }
def Status-completer-4 [] { ["completed"] }
def AnnounceMethod-completer [] { ["GET" "POST"] }
def Status-completer-5 [] { ["completed" "in-progress" "init"] }
def DeauthorizeCallbackMethod-completer [] { ["GET" "POST"] }
def EmergencyStatus-completer [] { ["Active" "Inactive"] }
def VoiceReceiveMode-completer [] { ["fax" "voice"] }
def ContentRetention-completer [] { ["discard" "retain"] }
def AddressRetention-completer [] { ["obfuscate" "retain"] }
def TrafficType-completer [] { ["free"] }
def ScheduleType-completer [] { ["fixed"] }
def RiskCheck-completer [] { ["disable" "enable"] }
def Status-completer-6 [] { ["canceled"] }
def Outcome-completer [] { ["confirmed" "unconfirmed"] }
def HoldMethod-completer [] { ["GET" "POST"] }
def WaitMethod-completer [] { ["GET" "POST"] }
def ConferenceStatusCallbackMethod-completer [] { ["GET" "POST"] }
def ConferenceRecordingStatusCallbackMethod-completer [] { ["GET" "POST"] }
def AmdStatusCallbackMethod-completer [] { ["GET" "POST"] }
def BankAccountType-completer [] { ["commercial-checking" "consumer-checking" "consumer-savings"] }
def PaymentMethod-completer [] { ["ach-debit" "credit-card"] }
def TokenType-completer [] { ["one-time" "payment-method" "reusable"] }
def Confirmation-completer [] { ["false" "true"] }
def Capture-completer [] { ["bank-account-number" "bank-routing-number" "expiration-date" "expiration-date-matcher" "payment-card-number" "payment-card-number-matcher" "postal-code" "postal-code-matcher" "security-code" "security-code-matcher"] }
def Status-completer-7 [] { ["cancel" "complete"] }
def Track-completer [] { ["both_tracks" "inbound_track" "outbound_track"] }
def Status-completer-8 [] { ["stopped"] }
def VoiceStatusCallbackMethod-completer [] { ["GET" "POST"] }
def CallbackMethod-completer [] { ["GET" "POST"] }
def Recurring-completer [] { ["alltime" "daily" "monthly" "yearly"] }
def TriggerBy-completer [] { ["count" "price" "usage"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "2010-04-01-accountsjson CreateAccount" } } | get name | first)
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

# Create a new Twilio Subaccount from the account making the request
#
# POST /2010-04-01/Accounts.json
# operationId: CreateAccount
export def "2010-04-01-accountsjson CreateAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A human readable description of the account to create, defaults to `SubAccount Created at {YYYY-MM-DD HH:MM meridian}`
]: any -> record<auth_token: string, date_created: string, date_updated: string, friendly_name: string, owner_account_sid: string, sid: string, status: string, subresource_uris: record, type: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base "/2010-04-01/Accounts.json")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieves a collection of Accounts belonging to the account used to make the request
#
# GET /2010-04-01/Accounts.json
# operationId: ListAccount
export def "2010-04-01-accountsjson ListAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # Only return the Account resources with friendly names that exactly match this name.
  --Status: string@Status-completer # Only return Account resources with the given status. Can be `closed`, `suspended` or `active`.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, accounts: table<auth_token: string, date_created: string, date_updated: string, friendly_name: string, owner_account_sid: string, sid: string, status: string, subresource_uris: record, type: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "Status" $Status "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2010-04-01/Accounts.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch the account specified by the provided Account Sid
#
# GET /2010-04-01/Accounts/{Sid}.json
# operationId: FetchAccount
export def "2010-04-01-accounts FetchAccount" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_token: string, date_created: string, date_updated: string, friendly_name: string, owner_account_sid: string, sid: string, status: string, subresource_uris: record, type: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify the properties of a given Account
#
# POST /2010-04-01/Accounts/{Sid}.json
# operationId: UpdateAccount
export def "2010-04-01-accounts UpdateAccount" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # Update the human-readable description of this Account
  --Status: string@Status-completer # The status of this account. Usually `active`, but can be `suspended` or `closed`.
]: any -> record<auth_token: string, date_created: string, date_updated: string, friendly_name: string, owner_account_sid: string, sid: string, status: string, subresource_uris: record, type: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($Sid).json")
  let body = {FriendlyName: $FriendlyName, Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# POST /2010-04-01/Accounts/{AccountSid}/Addresses.json
#
# operationId: CreateAddress
export def "2010-04-01-accounts-addressesjson CreateAddress" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  CustomerName: string # The name to associate with the new address.
  Street: string # The number and street address of the new address.
  City: string # The city of the new address.
  Region: string # The state or region of the new address.
  PostalCode: string # The postal code of the new address.
  IsoCountry: string # The ISO country code of the new address. (format: iso-country-code)
  --FriendlyName: string # A descriptive string that you create to describe the new address. It can be up to 64 characters long for Regulatory Compliance addresses and 32 characters long for Emergency addresses.
  --EmergencyEnabled: oneof<nothing, bool> # Whether to enable emergency calling on the new address. Can be: `true` or `false`.
  --AutoCorrectAddress: oneof<nothing, bool> # Whether we should automatically correct the address. Can be: `true` or `false` and the default is `true`. If empty or `true`, we will correct the address you provide if necessary. If `false`, we won't alter the address you provide.
  --StreetSecondary: string # The additional number and street address of the address.
]: any -> record<account_sid: string, city: string, customer_name: string, date_created: string, date_updated: string, friendly_name: string, iso_country: string, postal_code: string, region: string, sid: string, street: string, uri: string, emergency_enabled: bool, validated: bool, verified: bool, street_secondary: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Addresses.json")
  let body = {CustomerName: $CustomerName, Street: $Street, City: $City, Region: $Region, PostalCode: $PostalCode, IsoCountry: $IsoCountry, FriendlyName: $FriendlyName, EmergencyEnabled: $EmergencyEnabled, AutoCorrectAddress: $AutoCorrectAddress, StreetSecondary: $StreetSecondary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /2010-04-01/Accounts/{AccountSid}/Addresses.json
#
# operationId: ListAddress
export def "2010-04-01-accounts-addressesjson ListAddress" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --CustomerName: string # The `customer_name` of the Address resources to read.
  --FriendlyName: string # The string that identifies the Address resources to read.
  --EmergencyEnabled: oneof<nothing, bool> # Whether the address can be associated to a number for emergency calling.
  --IsoCountry: string # The ISO country code of the Address resources to read. (format: iso-country-code)
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, addresses: table<account_sid: string, city: string, customer_name: string, date_created: string, date_updated: string, friendly_name: string, iso_country: string, postal_code: string, region: string, sid: string, street: string, uri: string, emergency_enabled: bool, validated: bool, verified: bool, street_secondary: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "CustomerName" $CustomerName "scalar") (serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "EmergencyEnabled" $EmergencyEnabled "scalar") (serialize-qp "IsoCountry" $IsoCountry "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Addresses.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /2010-04-01/Accounts/{AccountSid}/Addresses/{Sid}.json
#
# operationId: DeleteAddress
export def "2010-04-01-accounts-addresses DeleteAddress" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Addresses/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Addresses/{Sid}.json
#
# operationId: FetchAddress
export def "2010-04-01-accounts-addresses FetchAddress" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, city: string, customer_name: string, date_created: string, date_updated: string, friendly_name: string, iso_country: string, postal_code: string, region: string, sid: string, street: string, uri: string, emergency_enabled: bool, validated: bool, verified: bool, street_secondary: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Addresses/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/Addresses/{Sid}.json
#
# operationId: UpdateAddress
export def "2010-04-01-accounts-addresses UpdateAddress" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A descriptive string that you create to describe the new address. It can be up to 64 characters long for Regulatory Compliance addresses and 32 characters long for Emergency addresses.
  --CustomerName: string # The name to associate with the address.
  --Street: string # The number and street address of the address.
  --City: string # The city of the address.
  --Region: string # The state or region of the address.
  --PostalCode: string # The postal code of the address.
  --EmergencyEnabled: oneof<nothing, bool> # Whether to enable emergency calling on the address. Can be: `true` or `false`.
  --AutoCorrectAddress: oneof<nothing, bool> # Whether we should automatically correct the address. Can be: `true` or `false` and the default is `true`. If empty or `true`, we will correct the address you provide if necessary. If `false`, we won't alter the address you provide.
  --StreetSecondary: string # The additional number and street address of the address.
]: any -> record<account_sid: string, city: string, customer_name: string, date_created: string, date_updated: string, friendly_name: string, iso_country: string, postal_code: string, region: string, sid: string, street: string, uri: string, emergency_enabled: bool, validated: bool, verified: bool, street_secondary: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Addresses/($Sid).json")
  let body = {FriendlyName: $FriendlyName, CustomerName: $CustomerName, Street: $Street, City: $City, Region: $Region, PostalCode: $PostalCode, EmergencyEnabled: $EmergencyEnabled, AutoCorrectAddress: $AutoCorrectAddress, StreetSecondary: $StreetSecondary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a new application within your account
#
# POST /2010-04-01/Accounts/{AccountSid}/Applications.json
# operationId: CreateApplication
export def "2010-04-01-accounts-applicationsjson CreateApplication" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ApiVersion: string # The API version to use to start a new TwiML session. Can be: `2010-04-01` or `2008-08-01`. The default value is the account's default API version.
  --VoiceUrl: string # The URL we should call when the phone number assigned to this application receives a call. (format: uri)
  --VoiceMethod: string@VoiceMethod-completer # The HTTP method we should use to call `voice_url`. Can be: `GET` or `POST`. (format: http-method)
  --VoiceFallbackUrl: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --VoiceFallbackMethod: string@VoiceFallbackMethod-completer # The HTTP method we should use to call `voice_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --StatusCallback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST`. (format: http-method)
  --VoiceCallerIdLookup: oneof<nothing, bool> # Whether we should look up the caller's caller-ID name from the CNAM database (additional charges apply). Can be: `true` or `false`.
  --SmsUrl: string # The URL we should call when the phone number receives an incoming SMS message. (format: uri)
  --SmsMethod: string@SmsMethod-completer # The HTTP method we should use to call `sms_url`. Can be: `GET` or `POST`. (format: http-method)
  --SmsFallbackUrl: string # The URL that we should call when an error occurs while retrieving or executing the TwiML from `sms_url`. (format: uri)
  --SmsFallbackMethod: string@SmsFallbackMethod-completer # The HTTP method we should use to call `sms_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --SmsStatusCallback: string # The URL we should call using a POST method to send status information about SMS messages sent by the application. (format: uri)
  --MessageStatusCallback: string # The URL we should call using a POST method to send message status information to your application. (format: uri)
  --FriendlyName: string # A descriptive string that you create to describe the new application. It can be up to 64 characters long.
  --PublicApplicationConnectEnabled: oneof<nothing, bool> # Whether to allow other Twilio accounts to dial this applicaton using Dial verb. Can be: `true` or `false`.
]: any -> record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, message_status_callback: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_status_callback: string, sms_url: string, status_callback: string, status_callback_method: string, uri: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string, public_application_connect_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Applications.json")
  let body = {ApiVersion: $ApiVersion, VoiceUrl: $VoiceUrl, VoiceMethod: $VoiceMethod, VoiceFallbackUrl: $VoiceFallbackUrl, VoiceFallbackMethod: $VoiceFallbackMethod, StatusCallback: $StatusCallback, StatusCallbackMethod: $StatusCallbackMethod, VoiceCallerIdLookup: $VoiceCallerIdLookup, SmsUrl: $SmsUrl, SmsMethod: $SmsMethod, SmsFallbackUrl: $SmsFallbackUrl, SmsFallbackMethod: $SmsFallbackMethod, SmsStatusCallback: $SmsStatusCallback, MessageStatusCallback: $MessageStatusCallback, FriendlyName: $FriendlyName, PublicApplicationConnectEnabled: $PublicApplicationConnectEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of applications representing an application within the requesting account
#
# GET /2010-04-01/Accounts/{AccountSid}/Applications.json
# operationId: ListApplication
export def "2010-04-01-accounts-applicationsjson ListApplication" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # The string that identifies the Application resources to read.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, applications: table<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, message_status_callback: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_status_callback: string, sms_url: string, status_callback: string, status_callback_method: string, uri: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string, public_application_connect_enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Applications.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the application by the specified application sid
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Applications/{Sid}.json
# operationId: DeleteApplication
export def "2010-04-01-accounts-applications DeleteApplication" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Applications/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch the application specified by the provided sid
#
# GET /2010-04-01/Accounts/{AccountSid}/Applications/{Sid}.json
# operationId: FetchApplication
export def "2010-04-01-accounts-applications FetchApplication" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, message_status_callback: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_status_callback: string, sms_url: string, status_callback: string, status_callback_method: string, uri: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string, public_application_connect_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Applications/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the application's properties
#
# POST /2010-04-01/Accounts/{AccountSid}/Applications/{Sid}.json
# operationId: UpdateApplication
export def "2010-04-01-accounts-applications UpdateApplication" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --ApiVersion: string # The API version to use to start a new TwiML session. Can be: `2010-04-01` or `2008-08-01`. The default value is your account's default API version.
  --VoiceUrl: string # The URL we should call when the phone number assigned to this application receives a call. (format: uri)
  --VoiceMethod: string@VoiceMethod-completer # The HTTP method we should use to call `voice_url`. Can be: `GET` or `POST`. (format: http-method)
  --VoiceFallbackUrl: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --VoiceFallbackMethod: string@VoiceFallbackMethod-completer # The HTTP method we should use to call `voice_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --StatusCallback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST`. (format: http-method)
  --VoiceCallerIdLookup: oneof<nothing, bool> # Whether we should look up the caller's caller-ID name from the CNAM database (additional charges apply). Can be: `true` or `false`.
  --SmsUrl: string # The URL we should call when the phone number receives an incoming SMS message. (format: uri)
  --SmsMethod: string@SmsMethod-completer # The HTTP method we should use to call `sms_url`. Can be: `GET` or `POST`. (format: http-method)
  --SmsFallbackUrl: string # The URL that we should call when an error occurs while retrieving or executing the TwiML from `sms_url`. (format: uri)
  --SmsFallbackMethod: string@SmsFallbackMethod-completer # The HTTP method we should use to call `sms_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --SmsStatusCallback: string # Same as message_status_callback: The URL we should call using a POST method to send status information about SMS messages sent by the application. Deprecated, included for backwards compatibility. (format: uri)
  --MessageStatusCallback: string # The URL we should call using a POST method to send message status information to your application. (format: uri)
  --PublicApplicationConnectEnabled: oneof<nothing, bool> # Whether to allow other Twilio accounts to dial this applicaton using Dial verb. Can be: `true` or `false`.
]: any -> record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, message_status_callback: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_status_callback: string, sms_url: string, status_callback: string, status_callback_method: string, uri: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string, public_application_connect_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Applications/($Sid).json")
  let body = {FriendlyName: $FriendlyName, ApiVersion: $ApiVersion, VoiceUrl: $VoiceUrl, VoiceMethod: $VoiceMethod, VoiceFallbackUrl: $VoiceFallbackUrl, VoiceFallbackMethod: $VoiceFallbackMethod, StatusCallback: $StatusCallback, StatusCallbackMethod: $StatusCallbackMethod, VoiceCallerIdLookup: $VoiceCallerIdLookup, SmsUrl: $SmsUrl, SmsMethod: $SmsMethod, SmsFallbackUrl: $SmsFallbackUrl, SmsFallbackMethod: $SmsFallbackMethod, SmsStatusCallback: $SmsStatusCallback, MessageStatusCallback: $MessageStatusCallback, PublicApplicationConnectEnabled: $PublicApplicationConnectEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch an instance of an authorized-connect-app
#
# GET /2010-04-01/Accounts/{AccountSid}/AuthorizedConnectApps/{ConnectAppSid}.json
# operationId: FetchAuthorizedConnectApp
export def "2010-04-01-accounts-authorized-connect-apps FetchAuthorizedConnectApp" [
  AccountSid: string
  ConnectAppSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, connect_app_company_name: string, connect_app_description: string, connect_app_friendly_name: string, connect_app_homepage_url: string, connect_app_sid: string, permissions: list<string>, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/AuthorizedConnectApps/($ConnectAppSid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of authorized-connect-apps belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/AuthorizedConnectApps.json
# operationId: ListAuthorizedConnectApp
export def "2010-04-01-accounts-authorized-connect-appsjson ListAuthorizedConnectApp" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, authorized_connect_apps: table<account_sid: string, connect_app_company_name: string, connect_app_description: string, connect_app_friendly_name: string, connect_app_homepage_url: string, connect_app_sid: string, permissions: list, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/AuthorizedConnectApps.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers.json
#
# operationId: ListAvailablePhoneNumberCountry
export def "2010-04-01-accounts-available-phone-numbersjson ListAvailablePhoneNumberCountry" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<countries: table<country_code: string, country: string, uri: string, beta: bool, subresource_uris: record>, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/AvailablePhoneNumbers.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}.json
#
# operationId: FetchAvailablePhoneNumberCountry
export def "2010-04-01-accounts-available-phone-numbers FetchAvailablePhoneNumberCountry" [
  AccountSid: string
  CountryCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<country_code: string, country: string, uri: string, beta: bool, subresource_uris: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/AvailablePhoneNumbers/($CountryCode).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/Local.json
#
# operationId: ListAvailablePhoneNumberLocal
export def "2010-04-01-accounts-available-phone-numbers-localjson ListAvailablePhoneNumberLocal" [
  AccountSid: string
  CountryCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --AreaCode: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --Contains: string # Matching pattern to identify phone numbers. This pattern can be between 2 and 16 characters long and allows all digits (0-9) and all non-diacritic latin alphabet letters (a-z, A-Z). It accepts four meta-characters: `*`, `%`, `+`, `$`. The `*` and `%` meta-characters can appear multiple times in the pattern. To match wildcards at the beginning or end of the pattern, use `*` to match any single character or `%` to match a sequence of characters. If you use the wildcard patterns, it must include at least two non-meta-characters, and wildcards cannot be used between non-meta-characters. To match the beginning of a pattern, start the pattern with `+`. To match the end of the pattern, append the pattern with `$`. These meta-characters can't be adjacent to each other.
  --SmsEnabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --MmsEnabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --VoiceEnabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --ExcludeAllAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --ExcludeLocalAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --ExcludeForeignAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --Beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --NearNumber: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --NearLatLong: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --Distance: int # The search radius, in miles, for a `near_` query.  Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --InPostalCode: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --InRegion: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --InRateCenter: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --InLata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --InLocality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --FaxEnabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, available_phone_numbers: table<friendly_name: string, phone_number: string, lata: string, locality: string, rate_center: string, latitude: float, longitude: float, region: string, postal_code: string, iso_country: string, address_requirements: string, beta: bool, capabilities: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "AreaCode" $AreaCode "scalar") (serialize-qp "Contains" $Contains "scalar") (serialize-qp "SmsEnabled" $SmsEnabled "scalar") (serialize-qp "MmsEnabled" $MmsEnabled "scalar") (serialize-qp "VoiceEnabled" $VoiceEnabled "scalar") (serialize-qp "ExcludeAllAddressRequired" $ExcludeAllAddressRequired "scalar") (serialize-qp "ExcludeLocalAddressRequired" $ExcludeLocalAddressRequired "scalar") (serialize-qp "ExcludeForeignAddressRequired" $ExcludeForeignAddressRequired "scalar") (serialize-qp "Beta" $Beta "scalar") (serialize-qp "NearNumber" $NearNumber "scalar") (serialize-qp "NearLatLong" $NearLatLong "scalar") (serialize-qp "Distance" $Distance "scalar") (serialize-qp "InPostalCode" $InPostalCode "scalar") (serialize-qp "InRegion" $InRegion "scalar") (serialize-qp "InRateCenter" $InRateCenter "scalar") (serialize-qp "InLata" $InLata "scalar") (serialize-qp "InLocality" $InLocality "scalar") (serialize-qp "FaxEnabled" $FaxEnabled "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/AvailablePhoneNumbers/($CountryCode)/Local.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/MachineToMachine.json
#
# operationId: ListAvailablePhoneNumberMachineToMachine
export def "2010-04-01-accounts-available-phone-numbers-machine-to-machinejson ListAvailablePhoneNumberMachineToMachine" [
  AccountSid: string
  CountryCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --AreaCode: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --Contains: string # Matching pattern to identify phone numbers. This pattern can be between 2 and 16 characters long and allows all digits (0-9) and all non-diacritic latin alphabet letters (a-z, A-Z). It accepts four meta-characters: `*`, `%`, `+`, `$`. The `*` and `%` meta-characters can appear multiple times in the pattern. To match wildcards at the beginning or end of the pattern, use `*` to match any single character or `%` to match a sequence of characters. If you use the wildcard patterns, it must include at least two non-meta-characters, and wildcards cannot be used between non-meta-characters. To match the beginning of a pattern, start the pattern with `+`. To match the end of the pattern, append the pattern with `$`. These meta-characters can't be adjacent to each other.
  --SmsEnabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --MmsEnabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --VoiceEnabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --ExcludeAllAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --ExcludeLocalAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --ExcludeForeignAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --Beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --NearNumber: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --NearLatLong: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --Distance: int # The search radius, in miles, for a `near_` query.  Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --InPostalCode: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --InRegion: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --InRateCenter: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --InLata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --InLocality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --FaxEnabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, available_phone_numbers: table<friendly_name: string, phone_number: string, lata: string, locality: string, rate_center: string, latitude: float, longitude: float, region: string, postal_code: string, iso_country: string, address_requirements: string, beta: bool, capabilities: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "AreaCode" $AreaCode "scalar") (serialize-qp "Contains" $Contains "scalar") (serialize-qp "SmsEnabled" $SmsEnabled "scalar") (serialize-qp "MmsEnabled" $MmsEnabled "scalar") (serialize-qp "VoiceEnabled" $VoiceEnabled "scalar") (serialize-qp "ExcludeAllAddressRequired" $ExcludeAllAddressRequired "scalar") (serialize-qp "ExcludeLocalAddressRequired" $ExcludeLocalAddressRequired "scalar") (serialize-qp "ExcludeForeignAddressRequired" $ExcludeForeignAddressRequired "scalar") (serialize-qp "Beta" $Beta "scalar") (serialize-qp "NearNumber" $NearNumber "scalar") (serialize-qp "NearLatLong" $NearLatLong "scalar") (serialize-qp "Distance" $Distance "scalar") (serialize-qp "InPostalCode" $InPostalCode "scalar") (serialize-qp "InRegion" $InRegion "scalar") (serialize-qp "InRateCenter" $InRateCenter "scalar") (serialize-qp "InLata" $InLata "scalar") (serialize-qp "InLocality" $InLocality "scalar") (serialize-qp "FaxEnabled" $FaxEnabled "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/AvailablePhoneNumbers/($CountryCode)/MachineToMachine.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/Mobile.json
#
# operationId: ListAvailablePhoneNumberMobile
export def "2010-04-01-accounts-available-phone-numbers-mobilejson ListAvailablePhoneNumberMobile" [
  AccountSid: string
  CountryCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --AreaCode: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --Contains: string # Matching pattern to identify phone numbers. This pattern can be between 2 and 16 characters long and allows all digits (0-9) and all non-diacritic latin alphabet letters (a-z, A-Z). It accepts four meta-characters: `*`, `%`, `+`, `$`. The `*` and `%` meta-characters can appear multiple times in the pattern. To match wildcards at the beginning or end of the pattern, use `*` to match any single character or `%` to match a sequence of characters. If you use the wildcard patterns, it must include at least two non-meta-characters, and wildcards cannot be used between non-meta-characters. To match the beginning of a pattern, start the pattern with `+`. To match the end of the pattern, append the pattern with `$`. These meta-characters can't be adjacent to each other.
  --SmsEnabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --MmsEnabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --VoiceEnabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --ExcludeAllAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --ExcludeLocalAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --ExcludeForeignAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --Beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --NearNumber: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --NearLatLong: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --Distance: int # The search radius, in miles, for a `near_` query.  Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --InPostalCode: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --InRegion: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --InRateCenter: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --InLata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --InLocality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --FaxEnabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, available_phone_numbers: table<friendly_name: string, phone_number: string, lata: string, locality: string, rate_center: string, latitude: float, longitude: float, region: string, postal_code: string, iso_country: string, address_requirements: string, beta: bool, capabilities: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "AreaCode" $AreaCode "scalar") (serialize-qp "Contains" $Contains "scalar") (serialize-qp "SmsEnabled" $SmsEnabled "scalar") (serialize-qp "MmsEnabled" $MmsEnabled "scalar") (serialize-qp "VoiceEnabled" $VoiceEnabled "scalar") (serialize-qp "ExcludeAllAddressRequired" $ExcludeAllAddressRequired "scalar") (serialize-qp "ExcludeLocalAddressRequired" $ExcludeLocalAddressRequired "scalar") (serialize-qp "ExcludeForeignAddressRequired" $ExcludeForeignAddressRequired "scalar") (serialize-qp "Beta" $Beta "scalar") (serialize-qp "NearNumber" $NearNumber "scalar") (serialize-qp "NearLatLong" $NearLatLong "scalar") (serialize-qp "Distance" $Distance "scalar") (serialize-qp "InPostalCode" $InPostalCode "scalar") (serialize-qp "InRegion" $InRegion "scalar") (serialize-qp "InRateCenter" $InRateCenter "scalar") (serialize-qp "InLata" $InLata "scalar") (serialize-qp "InLocality" $InLocality "scalar") (serialize-qp "FaxEnabled" $FaxEnabled "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/AvailablePhoneNumbers/($CountryCode)/Mobile.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/National.json
#
# operationId: ListAvailablePhoneNumberNational
export def "2010-04-01-accounts-available-phone-numbers-nationaljson ListAvailablePhoneNumberNational" [
  AccountSid: string
  CountryCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --AreaCode: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --Contains: string # Matching pattern to identify phone numbers. This pattern can be between 2 and 16 characters long and allows all digits (0-9) and all non-diacritic latin alphabet letters (a-z, A-Z). It accepts four meta-characters: `*`, `%`, `+`, `$`. The `*` and `%` meta-characters can appear multiple times in the pattern. To match wildcards at the beginning or end of the pattern, use `*` to match any single character or `%` to match a sequence of characters. If you use the wildcard patterns, it must include at least two non-meta-characters, and wildcards cannot be used between non-meta-characters. To match the beginning of a pattern, start the pattern with `+`. To match the end of the pattern, append the pattern with `$`. These meta-characters can't be adjacent to each other.
  --SmsEnabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --MmsEnabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --VoiceEnabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --ExcludeAllAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --ExcludeLocalAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --ExcludeForeignAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --Beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --NearNumber: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --NearLatLong: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --Distance: int # The search radius, in miles, for a `near_` query.  Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --InPostalCode: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --InRegion: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --InRateCenter: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --InLata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --InLocality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --FaxEnabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, available_phone_numbers: table<friendly_name: string, phone_number: string, lata: string, locality: string, rate_center: string, latitude: float, longitude: float, region: string, postal_code: string, iso_country: string, address_requirements: string, beta: bool, capabilities: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "AreaCode" $AreaCode "scalar") (serialize-qp "Contains" $Contains "scalar") (serialize-qp "SmsEnabled" $SmsEnabled "scalar") (serialize-qp "MmsEnabled" $MmsEnabled "scalar") (serialize-qp "VoiceEnabled" $VoiceEnabled "scalar") (serialize-qp "ExcludeAllAddressRequired" $ExcludeAllAddressRequired "scalar") (serialize-qp "ExcludeLocalAddressRequired" $ExcludeLocalAddressRequired "scalar") (serialize-qp "ExcludeForeignAddressRequired" $ExcludeForeignAddressRequired "scalar") (serialize-qp "Beta" $Beta "scalar") (serialize-qp "NearNumber" $NearNumber "scalar") (serialize-qp "NearLatLong" $NearLatLong "scalar") (serialize-qp "Distance" $Distance "scalar") (serialize-qp "InPostalCode" $InPostalCode "scalar") (serialize-qp "InRegion" $InRegion "scalar") (serialize-qp "InRateCenter" $InRateCenter "scalar") (serialize-qp "InLata" $InLata "scalar") (serialize-qp "InLocality" $InLocality "scalar") (serialize-qp "FaxEnabled" $FaxEnabled "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/AvailablePhoneNumbers/($CountryCode)/National.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/SharedCost.json
#
# operationId: ListAvailablePhoneNumberSharedCost
export def "2010-04-01-accounts-available-phone-numbers-shared-costjson ListAvailablePhoneNumberSharedCost" [
  AccountSid: string
  CountryCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --AreaCode: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --Contains: string # Matching pattern to identify phone numbers. This pattern can be between 2 and 16 characters long and allows all digits (0-9) and all non-diacritic latin alphabet letters (a-z, A-Z). It accepts four meta-characters: `*`, `%`, `+`, `$`. The `*` and `%` meta-characters can appear multiple times in the pattern. To match wildcards at the beginning or end of the pattern, use `*` to match any single character or `%` to match a sequence of characters. If you use the wildcard patterns, it must include at least two non-meta-characters, and wildcards cannot be used between non-meta-characters. To match the beginning of a pattern, start the pattern with `+`. To match the end of the pattern, append the pattern with `$`. These meta-characters can't be adjacent to each other.
  --SmsEnabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --MmsEnabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --VoiceEnabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --ExcludeAllAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --ExcludeLocalAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --ExcludeForeignAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --Beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --NearNumber: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --NearLatLong: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --Distance: int # The search radius, in miles, for a `near_` query.  Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --InPostalCode: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --InRegion: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --InRateCenter: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --InLata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --InLocality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --FaxEnabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, available_phone_numbers: table<friendly_name: string, phone_number: string, lata: string, locality: string, rate_center: string, latitude: float, longitude: float, region: string, postal_code: string, iso_country: string, address_requirements: string, beta: bool, capabilities: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "AreaCode" $AreaCode "scalar") (serialize-qp "Contains" $Contains "scalar") (serialize-qp "SmsEnabled" $SmsEnabled "scalar") (serialize-qp "MmsEnabled" $MmsEnabled "scalar") (serialize-qp "VoiceEnabled" $VoiceEnabled "scalar") (serialize-qp "ExcludeAllAddressRequired" $ExcludeAllAddressRequired "scalar") (serialize-qp "ExcludeLocalAddressRequired" $ExcludeLocalAddressRequired "scalar") (serialize-qp "ExcludeForeignAddressRequired" $ExcludeForeignAddressRequired "scalar") (serialize-qp "Beta" $Beta "scalar") (serialize-qp "NearNumber" $NearNumber "scalar") (serialize-qp "NearLatLong" $NearLatLong "scalar") (serialize-qp "Distance" $Distance "scalar") (serialize-qp "InPostalCode" $InPostalCode "scalar") (serialize-qp "InRegion" $InRegion "scalar") (serialize-qp "InRateCenter" $InRateCenter "scalar") (serialize-qp "InLata" $InLata "scalar") (serialize-qp "InLocality" $InLocality "scalar") (serialize-qp "FaxEnabled" $FaxEnabled "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/AvailablePhoneNumbers/($CountryCode)/SharedCost.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/TollFree.json
#
# operationId: ListAvailablePhoneNumberTollFree
export def "2010-04-01-accounts-available-phone-numbers-toll-freejson ListAvailablePhoneNumberTollFree" [
  AccountSid: string
  CountryCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --AreaCode: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --Contains: string # Matching pattern to identify phone numbers. This pattern can be between 2 and 16 characters long and allows all digits (0-9) and all non-diacritic latin alphabet letters (a-z, A-Z). It accepts four meta-characters: `*`, `%`, `+`, `$`. The `*` and `%` meta-characters can appear multiple times in the pattern. To match wildcards at the beginning or end of the pattern, use `*` to match any single character or `%` to match a sequence of characters. If you use the wildcard patterns, it must include at least two non-meta-characters, and wildcards cannot be used between non-meta-characters. To match the beginning of a pattern, start the pattern with `+`. To match the end of the pattern, append the pattern with `$`. These meta-characters can't be adjacent to each other.
  --SmsEnabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --MmsEnabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --VoiceEnabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --ExcludeAllAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --ExcludeLocalAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --ExcludeForeignAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --Beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --NearNumber: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --NearLatLong: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --Distance: int # The search radius, in miles, for a `near_` query.  Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --InPostalCode: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --InRegion: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --InRateCenter: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --InLata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --InLocality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --FaxEnabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, available_phone_numbers: table<friendly_name: string, phone_number: string, lata: string, locality: string, rate_center: string, latitude: float, longitude: float, region: string, postal_code: string, iso_country: string, address_requirements: string, beta: bool, capabilities: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "AreaCode" $AreaCode "scalar") (serialize-qp "Contains" $Contains "scalar") (serialize-qp "SmsEnabled" $SmsEnabled "scalar") (serialize-qp "MmsEnabled" $MmsEnabled "scalar") (serialize-qp "VoiceEnabled" $VoiceEnabled "scalar") (serialize-qp "ExcludeAllAddressRequired" $ExcludeAllAddressRequired "scalar") (serialize-qp "ExcludeLocalAddressRequired" $ExcludeLocalAddressRequired "scalar") (serialize-qp "ExcludeForeignAddressRequired" $ExcludeForeignAddressRequired "scalar") (serialize-qp "Beta" $Beta "scalar") (serialize-qp "NearNumber" $NearNumber "scalar") (serialize-qp "NearLatLong" $NearLatLong "scalar") (serialize-qp "Distance" $Distance "scalar") (serialize-qp "InPostalCode" $InPostalCode "scalar") (serialize-qp "InRegion" $InRegion "scalar") (serialize-qp "InRateCenter" $InRateCenter "scalar") (serialize-qp "InLata" $InLata "scalar") (serialize-qp "InLocality" $InLocality "scalar") (serialize-qp "FaxEnabled" $FaxEnabled "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/AvailablePhoneNumbers/($CountryCode)/TollFree.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/Voip.json
#
# operationId: ListAvailablePhoneNumberVoip
export def "2010-04-01-accounts-available-phone-numbers-voipjson ListAvailablePhoneNumberVoip" [
  AccountSid: string
  CountryCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --AreaCode: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --Contains: string # Matching pattern to identify phone numbers. This pattern can be between 2 and 16 characters long and allows all digits (0-9) and all non-diacritic latin alphabet letters (a-z, A-Z). It accepts four meta-characters: `*`, `%`, `+`, `$`. The `*` and `%` meta-characters can appear multiple times in the pattern. To match wildcards at the beginning or end of the pattern, use `*` to match any single character or `%` to match a sequence of characters. If you use the wildcard patterns, it must include at least two non-meta-characters, and wildcards cannot be used between non-meta-characters. To match the beginning of a pattern, start the pattern with `+`. To match the end of the pattern, append the pattern with `$`. These meta-characters can't be adjacent to each other.
  --SmsEnabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --MmsEnabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --VoiceEnabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --ExcludeAllAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --ExcludeLocalAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --ExcludeForeignAddressRequired: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --Beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --NearNumber: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --NearLatLong: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --Distance: int # The search radius, in miles, for a `near_` query.  Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --InPostalCode: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --InRegion: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --InRateCenter: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --InLata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --InLocality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --FaxEnabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, available_phone_numbers: table<friendly_name: string, phone_number: string, lata: string, locality: string, rate_center: string, latitude: float, longitude: float, region: string, postal_code: string, iso_country: string, address_requirements: string, beta: bool, capabilities: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "AreaCode" $AreaCode "scalar") (serialize-qp "Contains" $Contains "scalar") (serialize-qp "SmsEnabled" $SmsEnabled "scalar") (serialize-qp "MmsEnabled" $MmsEnabled "scalar") (serialize-qp "VoiceEnabled" $VoiceEnabled "scalar") (serialize-qp "ExcludeAllAddressRequired" $ExcludeAllAddressRequired "scalar") (serialize-qp "ExcludeLocalAddressRequired" $ExcludeLocalAddressRequired "scalar") (serialize-qp "ExcludeForeignAddressRequired" $ExcludeForeignAddressRequired "scalar") (serialize-qp "Beta" $Beta "scalar") (serialize-qp "NearNumber" $NearNumber "scalar") (serialize-qp "NearLatLong" $NearLatLong "scalar") (serialize-qp "Distance" $Distance "scalar") (serialize-qp "InPostalCode" $InPostalCode "scalar") (serialize-qp "InRegion" $InRegion "scalar") (serialize-qp "InRateCenter" $InRateCenter "scalar") (serialize-qp "InLata" $InLata "scalar") (serialize-qp "InLocality" $InLocality "scalar") (serialize-qp "FaxEnabled" $FaxEnabled "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/AvailablePhoneNumbers/($CountryCode)/Voip.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch the balance for an Account based on Account Sid. Balance changes may not be reflected immediately. Child accounts do not contain balance information
#
# GET /2010-04-01/Accounts/{AccountSid}/Balance.json
# operationId: FetchBalance
export def "2010-04-01-accounts-balancejson FetchBalance" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, balance: string, currency: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Balance.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new outgoing call to phones, SIP-enabled endpoints or Twilio Client connections
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls.json
# operationId: CreateCall
export def "2010-04-01-accounts-callsjson CreateCall" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  To: string # The phone number, SIP address, or client identifier to call. (format: endpoint)
  From: string # The phone number or client identifier to use as the caller id. If using a phone number, it must be a Twilio number or a Verified [outgoing caller id](https://www.twilio.com/docs/voice/api/outgoing-caller-ids) for your account. If the `to` parameter is a phone number, `From` must also be a phone number. (format: endpoint)
  --Method: string@Method-completer # The HTTP method we should use when calling the `url` parameter's value. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --FallbackUrl: string # The URL that we call using the `fallback_method` if an error occurs when requesting or executing the TwiML at `url`. If an `application_sid` parameter is present, this parameter is ignored. (format: uri)
  --FallbackMethod: string@FallbackMethod-completer # The HTTP method that we should use to request the `fallback_url`. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --StatusCallback: string # The URL we should call using the `status_callback_method` to send status information to your application. If no `status_callback_event` is specified, we will send the `completed` status. If an `application_sid` parameter is present, this parameter is ignored. URLs must contain a valid hostname (underscores are not permitted). (format: uri)
  --StatusCallbackEvent: list # The call progress events that we will send to the `status_callback` URL. Can be: `initiated`, `ringing`, `answered`, and `completed`. If no event is specified, we send the `completed` status. If you want to receive multiple events, specify each one in a separate `status_callback_event` parameter. See the code sample for [monitoring call progress](https://www.twilio.com/docs/voice/api/call-resource?code-sample=code-create-a-call-resource-and-specify-a-statuscallbackevent&code-sdk-version=json). If an `application_sid` is present, this parameter is ignored.
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The HTTP method we should use when calling the `status_callback` URL. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --SendDigits: string # The string of keys to dial after connecting to the number, with a maximum length of 32 digits. Valid digits in the string include any digit (`0`-`9`), '`A`', '`B`', '`C`', '`D`', '`#`', and '`*`'. You can also use '`w`' to insert a half-second pause and '`W`' to insert a one-second pause. For example, to pause for one second after connecting and then dial extension 1234 followed by the # key, set this parameter to `W1234#`. Be sure to URL-encode this string because the '`#`' character has special meaning in a URL. If both `SendDigits` and `MachineDetection` parameters are provided, then `MachineDetection` will be ignored.
  --Timeout: int # The integer number of seconds that we should allow the phone to ring before assuming there is no answer. The default is `60` seconds and the maximum is `600` seconds. For some call flows, we will add a 5-second buffer to the timeout value you provide. For this reason, a timeout value of 10 seconds could result in an actual timeout closer to 15 seconds. You can set this to a short time, such as `15` seconds, to hang up before reaching an answering machine or voicemail.
  --Record: oneof<nothing, bool> # Whether to record the call. Can be `true` to record the phone call, or `false` to not. The default is `false`. The `recording_url` is sent to the `status_callback` URL.
  --RecordingChannels: string # The number of channels in the final recording. Can be: `mono` or `dual`. The default is `mono`. `mono` records both legs of the call in a single channel of the recording file. `dual` records each leg to a separate channel of the recording file. The first channel of a dual-channel recording contains the parent call and the second channel contains the child call.
  --RecordingStatusCallback: string # The URL that we call when the recording is available to be accessed.
  --RecordingStatusCallbackMethod: string@RecordingStatusCallbackMethod-completer # The HTTP method we should use when calling the `recording_status_callback` URL. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  --RecordingConfigurationId: string # The identifier of the configuration to be used when creating and processing the recording
  --SipAuthUsername: string # The username used to authenticate the caller making a SIP call.
  --SipAuthPassword: string # The password required to authenticate the user account specified in `sip_auth_username`.
  --MachineDetection: string # Whether to detect if a human, answering machine, or fax has picked up the call. Can be: `Enable` or `DetectMessageEnd`. Use `Enable` if you would like us to return `AnsweredBy` as soon as the called party is identified. Use `DetectMessageEnd`, if you would like to leave a message on an answering machine. If `send_digits` is provided, this parameter is ignored. For more information, see [Answering Machine Detection](https://www.twilio.com/docs/voice/answering-machine-detection).
  --MachineDetectionTimeout: int # The number of seconds that we should attempt to detect an answering machine before timing out and sending a voice request with `AnsweredBy` of `unknown`. The default timeout is 30 seconds.
  --RecordingStatusCallbackEvent: list # The recording status events that will trigger calls to the URL specified in `recording_status_callback`. Can be: `in-progress`, `completed` and `absent`. Defaults to `completed`. Separate  multiple values with a space.
  --Trim: string # Whether to trim any leading and trailing silence from the recording. Can be: `trim-silence` or `do-not-trim` and the default is `trim-silence`.
  --CallerId: string # The phone number, SIP address, or Client identifier that made this call. Phone numbers are in [E.164 format](https://wwnw.twilio.com/docs/glossary/what-e164) (e.g., +16175551212). SIP addresses are formatted as `name@company.com`.
  --MachineDetectionSpeechThreshold: int # The number of milliseconds that is used as the measuring stick for the length of the speech activity, where durations lower than this value will be interpreted as a human and longer than this value as a machine. Possible Values: 1000-6000. Default: 2400.
  --MachineDetectionSpeechEndThreshold: int # The number of milliseconds of silence after speech activity at which point the speech activity is considered complete. Possible Values: 500-5000. Default: 1200.
  --MachineDetectionSilenceTimeout: int # The number of milliseconds of initial silence after which an `unknown` AnsweredBy result will be returned. Possible Values: 2000-10000. Default: 5000.
  --AsyncAmd: string # Select whether to perform answering machine detection in the background. Default, blocks the execution of the call until Answering Machine Detection is completed. Can be: `true` or `false`.
  --AsyncAmdStatusCallback: string # The URL that we should call using the `async_amd_status_callback_method` to notify customer application whether the call was answered by human, machine or fax. (format: uri)
  --AsyncAmdStatusCallbackMethod: string@AsyncAmdStatusCallbackMethod-completer # The HTTP method we should use when calling the `async_amd_status_callback` URL. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  --Byoc: string # The SID of a BYOC (Bring Your Own Carrier) trunk to route this call with. Note that `byoc` is only meaningful when `to` is a phone number; it will otherwise be ignored. (Beta)
  --CallReason: string # The Reason for the outgoing call. Use it to specify the purpose of the call that is presented on the called party's phone. (Branded Calls Beta)
  --CallToken: string # A token string needed to invoke a forwarded call. A call_token is generated when an incoming call is received on a Twilio number. Pass an incoming call's call_token value to a forwarded call via the call_token parameter when creating a new call. A forwarded call should bear the same CallerID of the original incoming call.
  --RecordingTrack: string # The audio track to record for the call. Can be: `inbound`, `outbound` or `both`. The default is `both`. `inbound` records the audio that is received by Twilio. `outbound` records the audio that is generated from Twilio. `both` records the audio that is received and generated by Twilio.
  --TimeLimit: int # The maximum duration of the call in seconds. Constraints depend on account and configuration.
  --ClientNotificationUrl: string # The URL that we should use to deliver `push call notification`. (format: uri)
  --Url: string # The absolute URL that returns the TwiML instructions for the call. We will call this URL using the `method` when the call connects. For more information, see the [Url Parameter](https://www.twilio.com/docs/voice/make-calls#specify-a-url-parameter) section in [Making Calls](https://www.twilio.com/docs/voice/make-calls). (format: uri)
  --Twiml: string # TwiML instructions for the call Twilio will use without fetching Twiml from url parameter. If both `twiml` and `url` are provided then `twiml` parameter will be ignored. Max 4000 characters. (format: twiml)
  --ApplicationSid: string # The SID of the Application resource that will handle the call, if the call will be handled by an application.
]: any -> record<sid: string, date_created: string, date_updated: string, parent_call_sid: string, account_sid: string, to: string, to_formatted: string, from: string, from_formatted: string, phone_number_sid: string, status: string, start_time: string, end_time: string, duration: string, price: string, price_unit: string, direction: string, answered_by: string, api_version: string, forwarded_from: string, group_sid: string, caller_name: string, queue_time: string, trunk_sid: string, uri: string, subresource_uris: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls.json")
  let body = {To: $To, From: $From, Method: $Method, FallbackUrl: $FallbackUrl, FallbackMethod: $FallbackMethod, StatusCallback: $StatusCallback, StatusCallbackEvent: $StatusCallbackEvent, StatusCallbackMethod: $StatusCallbackMethod, SendDigits: $SendDigits, Timeout: $Timeout, Record: $Record, RecordingChannels: $RecordingChannels, RecordingStatusCallback: $RecordingStatusCallback, RecordingStatusCallbackMethod: $RecordingStatusCallbackMethod, RecordingConfigurationId: $RecordingConfigurationId, SipAuthUsername: $SipAuthUsername, SipAuthPassword: $SipAuthPassword, MachineDetection: $MachineDetection, MachineDetectionTimeout: $MachineDetectionTimeout, RecordingStatusCallbackEvent: $RecordingStatusCallbackEvent, Trim: $Trim, CallerId: $CallerId, MachineDetectionSpeechThreshold: $MachineDetectionSpeechThreshold, MachineDetectionSpeechEndThreshold: $MachineDetectionSpeechEndThreshold, MachineDetectionSilenceTimeout: $MachineDetectionSilenceTimeout, AsyncAmd: $AsyncAmd, AsyncAmdStatusCallback: $AsyncAmdStatusCallback, AsyncAmdStatusCallbackMethod: $AsyncAmdStatusCallbackMethod, Byoc: $Byoc, CallReason: $CallReason, CallToken: $CallToken, RecordingTrack: $RecordingTrack, TimeLimit: $TimeLimit, ClientNotificationUrl: $ClientNotificationUrl, Url: $Url, Twiml: $Twiml, ApplicationSid: $ApplicationSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieves a collection of calls made to and from your account
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls.json
# operationId: ListCall
export def "2010-04-01-accounts-callsjson ListCall" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --To: string # Only show calls made to this phone number, SIP address, Client identifier or SIM SID. (format: phone-number)
  --From: string # Only include calls from this phone number, SIP address, Client identifier or SIM SID. (format: phone-number)
  --ParentCallSid: string # Only include calls spawned by calls with this SID.
  --Status: string@Status-completer-1 # The status of the calls to include. Can be: `queued`, `ringing`, `in-progress`, `canceled`, `completed`, `failed`, `busy`, or `no-answer`.
  --StartTime: string # Only include calls that started on this date. Specify a date as `YYYY-MM-DD` in UTC, for example: `2009-07-06`, to read only calls that started on this date. (format: date-time)
  --StartTime<: string # Only include calls that started before this date. Specify a date as `YYYY-MM-DD` in UTC, for example: `2009-07-06`, to read only calls that started before this date. (format: date-time)
  --StartTime>: string # Only include calls that started on or after this date. Specify a date as `YYYY-MM-DD` in UTC, for example: `2009-07-06`, to read only calls that started on or after this date. (format: date-time)
  --EndTime: string # Only include calls that ended on this date. Specify a date as `YYYY-MM-DD` in UTC, for example: `2009-07-06`, to read only calls that ended on this date. (format: date-time)
  --EndTime<: string # Only include calls that ended before this date. Specify a date as `YYYY-MM-DD` in UTC, for example: `2009-07-06`, to read only calls that ended before this date. (format: date-time)
  --EndTime>: string # Only include calls that ended on or after this date. Specify a date as `YYYY-MM-DD` in UTC, for example: `2009-07-06`, to read only calls that ended on or after this date. (format: date-time)
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, calls: table<sid: string, date_created: string, date_updated: string, parent_call_sid: string, account_sid: string, to: string, to_formatted: string, from: string, from_formatted: string, phone_number_sid: string, status: string, start_time: string, end_time: string, duration: string, price: string, price_unit: string, direction: string, answered_by: string, api_version: string, forwarded_from: string, group_sid: string, caller_name: string, queue_time: string, trunk_sid: string, uri: string, subresource_uris: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "To" $To "scalar") (serialize-qp "From" $From "scalar") (serialize-qp "ParentCallSid" $ParentCallSid "scalar") (serialize-qp "Status" $Status "scalar") (serialize-qp "StartTime" $StartTime "scalar") (serialize-qp "StartTime<" $StartTime< "scalar") (serialize-qp "StartTime>" $StartTime> "scalar") (serialize-qp "EndTime" $EndTime "scalar") (serialize-qp "EndTime<" $EndTime< "scalar") (serialize-qp "EndTime>" $EndTime> "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Call record from your account. Once the record is deleted, it will no longer appear in the API and Account Portal logs.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Calls/{Sid}.json
# operationId: DeleteCall
export def "2010-04-01-accounts-calls DeleteCall" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch the call specified by the provided Call SID
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls/{Sid}.json
# operationId: FetchCall
export def "2010-04-01-accounts-calls FetchCall" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, date_created: string, date_updated: string, parent_call_sid: string, account_sid: string, to: string, to_formatted: string, from: string, from_formatted: string, phone_number_sid: string, status: string, start_time: string, end_time: string, duration: string, price: string, price_unit: string, direction: string, answered_by: string, api_version: string, forwarded_from: string, group_sid: string, caller_name: string, queue_time: string, trunk_sid: string, uri: string, subresource_uris: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiates a call redirect or terminates a call
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{Sid}.json
# operationId: UpdateCall
export def "2010-04-01-accounts-calls UpdateCall" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Url: string # The absolute URL that returns the TwiML instructions for the call. We will call this URL using the `method` when the call connects. For more information, see the [Url Parameter](https://www.twilio.com/docs/voice/make-calls#specify-a-url-parameter) section in [Making Calls](https://www.twilio.com/docs/voice/make-calls). (format: uri)
  --Method: string@Method-completer # The HTTP method we should use when calling the `url`. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --Status: string@Status-completer-2
  --FallbackUrl: string # The URL that we call using the `fallback_method` if an error occurs when requesting or executing the TwiML at `url`. If an `application_sid` parameter is present, this parameter is ignored. (format: uri)
  --FallbackMethod: string@FallbackMethod-completer # The HTTP method that we should use to request the `fallback_url`. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --StatusCallback: string # The URL we should call using the `status_callback_method` to send status information to your application. If no `status_callback_event` is specified, we will send the `completed` status. If an `application_sid` parameter is present, this parameter is ignored. URLs must contain a valid hostname (underscores are not permitted). (format: uri)
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The HTTP method we should use when requesting the `status_callback` URL. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --Twiml: string # TwiML instructions for the call Twilio will use without fetching Twiml from url. Twiml and url parameters are mutually exclusive (format: twiml)
  --TimeLimit: int # The maximum duration of the call in seconds. Constraints depend on account and configuration.
]: any -> record<sid: string, date_created: string, date_updated: string, parent_call_sid: string, account_sid: string, to: string, to_formatted: string, from: string, from_formatted: string, phone_number_sid: string, status: string, start_time: string, end_time: string, duration: string, price: string, price_unit: string, direction: string, answered_by: string, api_version: string, forwarded_from: string, group_sid: string, caller_name: string, queue_time: string, trunk_sid: string, uri: string, subresource_uris: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($Sid).json")
  let body = {Url: $Url, Method: $Method, Status: $Status, FallbackUrl: $FallbackUrl, FallbackMethod: $FallbackMethod, StatusCallback: $StatusCallback, StatusCallbackMethod: $StatusCallbackMethod, Twiml: $Twiml, TimeLimit: $TimeLimit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all events for a call.
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Events.json
# operationId: ListCallEvent
export def "2010-04-01-accounts-calls-eventsjson ListCallEvent" [
  AccountSid: string
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, events: table<request: any, response: any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/Events.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Notifications/{Sid}.json
#
# operationId: FetchCallNotification
export def "2010-04-01-accounts-calls-notifications FetchCallNotification" [
  AccountSid: string
  CallSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, api_version: string, call_sid: string, date_created: string, date_updated: string, error_code: string, log: string, message_date: string, message_text: string, more_info: string, request_method: string, request_url: string, request_variables: string, response_body: string, response_headers: string, sid: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/Notifications/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Notifications.json
#
# operationId: ListCallNotification
export def "2010-04-01-accounts-calls-notificationsjson ListCallNotification" [
  AccountSid: string
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Log: int # Only read notifications of the specified log level. Can be:  `0` to read only ERROR notifications or `1` to read only WARNING notifications. By default, all notifications are read.
  --MessageDate: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date)
  --MessageDate<: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date)
  --MessageDate>: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date)
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, notifications: table<account_sid: string, api_version: string, call_sid: string, date_created: string, date_updated: string, error_code: string, log: string, message_date: string, message_text: string, more_info: string, request_method: string, request_url: string, sid: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Log" $Log "scalar") (serialize-qp "MessageDate" $MessageDate "scalar") (serialize-qp "MessageDate<" $MessageDate< "scalar") (serialize-qp "MessageDate>" $MessageDate> "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/Notifications.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a recording for the call
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings.json
# operationId: CreateCallRecording
export def "2010-04-01-accounts-calls-recordingsjson CreateCallRecording" [
  AccountSid: string
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --RecordingStatusCallbackEvent: list # The recording status events on which we should call the `recording_status_callback` URL. Can be: `in-progress`, `completed` and `absent` and the default is `completed`. Separate multiple event values with a space.
  --RecordingStatusCallback: string # The URL we should call using the `recording_status_callback_method` on each recording event specified in  `recording_status_callback_event`. For more information, see [RecordingStatusCallback parameters](https://www.twilio.com/docs/voice/api/recording#recordingstatuscallback). (format: uri)
  --RecordingStatusCallbackMethod: string@RecordingStatusCallbackMethod-completer # The HTTP method we should use to call `recording_status_callback`. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  --Trim: string # Whether to trim any leading and trailing silence in the recording. Can be: `trim-silence` or `do-not-trim` and the default is `do-not-trim`. `trim-silence` trims the silence from the beginning and end of the recording and `do-not-trim` does not.
  --RecordingChannels: string # The number of channels used in the recording. Can be: `mono` or `dual` and the default is `mono`. `mono` records all parties of the call into one channel. `dual` records each party of a 2-party call into separate channels.
  --RecordingTrack: string # The audio track to record for the call. Can be: `inbound`, `outbound` or `both`. The default is `both`. `inbound` records the audio that is received by Twilio. `outbound` records the audio that is generated from Twilio. `both` records the audio that is received and generated by Twilio.
  --RecordingConfigurationId: string # The identifier of the configuration to be used when creating and processing the recording
]: any -> record<account_sid: string, api_version: string, call_sid: string, conference_sid: string, date_created: string, date_updated: string, start_time: string, duration: string, sid: string, price: float, uri: string, encryption_details: any, price_unit: string, status: string, channels: int, source: string, error_code: int, track: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/Recordings.json")
  let body = {RecordingStatusCallbackEvent: $RecordingStatusCallbackEvent, RecordingStatusCallback: $RecordingStatusCallback, RecordingStatusCallbackMethod: $RecordingStatusCallbackMethod, Trim: $Trim, RecordingChannels: $RecordingChannels, RecordingTrack: $RecordingTrack, RecordingConfigurationId: $RecordingConfigurationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of recordings belonging to the call used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings.json
# operationId: ListCallRecording
export def "2010-04-01-accounts-calls-recordingsjson ListCallRecording" [
  AccountSid: string
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --DateCreated: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date)
  --DateCreated<: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date)
  --DateCreated>: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date)
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, recordings: table<account_sid: string, api_version: string, call_sid: string, conference_sid: string, date_created: string, date_updated: string, start_time: string, duration: string, sid: string, price: float, uri: string, encryption_details: any, price_unit: string, status: string, channels: int, source: string, error_code: int, track: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "DateCreated" $DateCreated "scalar") (serialize-qp "DateCreated<" $DateCreated< "scalar") (serialize-qp "DateCreated>" $DateCreated> "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/Recordings.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Changes the status of the recording to paused, stopped, or in-progress. Note: Pass `Twilio.CURRENT` instead of recording sid to reference current active recording.
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings/{Sid}.json
# operationId: UpdateCallRecording
export def "2010-04-01-accounts-calls-recordings UpdateCallRecording" [
  AccountSid: string
  CallSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Status: string@Status-completer-3 # The status of the recording. Can be: `processing`, `completed` and `absent`. For more detailed statuses on in-progress recordings, check out how to [Update a Recording Resource](https://www.twilio.com/docs/voice/api/recording#update-a-recording-resource).
  --PauseBehavior: string # Whether to record during a pause. Can be: `skip` or `silence` and the default is `silence`. `skip` does not record during the pause period, while `silence` will replace the actual audio of the call with silence during the pause period. This parameter only applies when setting `status` is set to `paused`.
]: any -> record<account_sid: string, api_version: string, call_sid: string, conference_sid: string, date_created: string, date_updated: string, start_time: string, duration: string, sid: string, price: float, uri: string, encryption_details: any, price_unit: string, status: string, channels: int, source: string, error_code: int, track: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/Recordings/($Sid).json")
  let body = {Status: $Status, PauseBehavior: $PauseBehavior} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch an instance of a recording for a call
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings/{Sid}.json
# operationId: FetchCallRecording
export def "2010-04-01-accounts-calls-recordings FetchCallRecording" [
  AccountSid: string
  CallSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, api_version: string, call_sid: string, conference_sid: string, date_created: string, date_updated: string, start_time: string, duration: string, sid: string, price: float, uri: string, encryption_details: any, price_unit: string, status: string, channels: int, source: string, error_code: int, track: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/Recordings/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a recording from your account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings/{Sid}.json
# operationId: DeleteCallRecording
export def "2010-04-01-accounts-calls-recordings DeleteCallRecording" [
  AccountSid: string
  CallSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/Recordings/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an instance of a conference
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences/{Sid}.json
# operationId: FetchConference
export def "2010-04-01-accounts-conferences FetchConference" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, api_version: string, friendly_name: string, region: string, sid: string, status: string, uri: string, subresource_uris: record, reason_conference_ended: string, call_sid_ending_conference: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Conferences/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/Conferences/{Sid}.json
#
# operationId: UpdateConference
export def "2010-04-01-accounts-conferences UpdateConference" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Status: string@Status-completer-4
  --AnnounceUrl: string # The URL we should call to announce something into the conference. The URL may return an MP3 file, a WAV file, or a TwiML document that contains `<Play>`, `<Say>`, `<Pause>`, or `<Redirect>` verbs. (format: uri)
  --AnnounceMethod: string@AnnounceMethod-completer # The HTTP method used to call `announce_url`. Can be: `GET` or `POST` and the default is `POST` (format: http-method)
]: any -> record<account_sid: string, date_created: string, date_updated: string, api_version: string, friendly_name: string, region: string, sid: string, status: string, uri: string, subresource_uris: record, reason_conference_ended: string, call_sid_ending_conference: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Conferences/($Sid).json")
  let body = {Status: $Status, AnnounceUrl: $AnnounceUrl, AnnounceMethod: $AnnounceMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of conferences belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences.json
# operationId: ListConference
export def "2010-04-01-accounts-conferencesjson ListConference" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --DateCreated: string # Only include conferences that were created on this date. Specify a date as `YYYY-MM-DD` in UTC, for example: `2009-07-06`, to read only conferences that were created on this date. You can also specify an inequality, such as `DateCreated<=YYYY-MM-DD`, to read conferences that were created on or before midnight of this date, and `DateCreated>=YYYY-MM-DD` to read conferences that were created on or after midnight of this date. (format: date)
  --DateCreated<: string # Only include conferences that were created on this date. Specify a date as `YYYY-MM-DD` in UTC, for example: `2009-07-06`, to read only conferences that were created on this date. You can also specify an inequality, such as `DateCreated<=YYYY-MM-DD`, to read conferences that were created on or before midnight of this date, and `DateCreated>=YYYY-MM-DD` to read conferences that were created on or after midnight of this date. (format: date)
  --DateCreated>: string # Only include conferences that were created on this date. Specify a date as `YYYY-MM-DD` in UTC, for example: `2009-07-06`, to read only conferences that were created on this date. You can also specify an inequality, such as `DateCreated<=YYYY-MM-DD`, to read conferences that were created on or before midnight of this date, and `DateCreated>=YYYY-MM-DD` to read conferences that were created on or after midnight of this date. (format: date)
  --DateUpdated: string # Only include conferences that were last updated on this date. Specify a date as `YYYY-MM-DD` in UTC, for example: `2009-07-06`, to read only conferences that were last updated on this date. You can also specify an inequality, such as `DateUpdated<=YYYY-MM-DD`, to read conferences that were last updated on or before midnight of this date, and `DateUpdated>=YYYY-MM-DD` to read conferences that were last updated on or after midnight of this date. (format: date)
  --DateUpdated<: string # Only include conferences that were last updated on this date. Specify a date as `YYYY-MM-DD` in UTC, for example: `2009-07-06`, to read only conferences that were last updated on this date. You can also specify an inequality, such as `DateUpdated<=YYYY-MM-DD`, to read conferences that were last updated on or before midnight of this date, and `DateUpdated>=YYYY-MM-DD` to read conferences that were last updated on or after midnight of this date. (format: date)
  --DateUpdated>: string # Only include conferences that were last updated on this date. Specify a date as `YYYY-MM-DD` in UTC, for example: `2009-07-06`, to read only conferences that were last updated on this date. You can also specify an inequality, such as `DateUpdated<=YYYY-MM-DD`, to read conferences that were last updated on or before midnight of this date, and `DateUpdated>=YYYY-MM-DD` to read conferences that were last updated on or after midnight of this date. (format: date)
  --FriendlyName: string # The string that identifies the Conference resources to read.
  --Status: string@Status-completer-5 # The status of the resources to read. Can be: `init`, `in-progress`, or `completed`.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, conferences: table<account_sid: string, date_created: string, date_updated: string, api_version: string, friendly_name: string, region: string, sid: string, status: string, uri: string, subresource_uris: record, reason_conference_ended: string, call_sid_ending_conference: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "DateCreated" $DateCreated "scalar") (serialize-qp "DateCreated<" $DateCreated< "scalar") (serialize-qp "DateCreated>" $DateCreated> "scalar") (serialize-qp "DateUpdated" $DateUpdated "scalar") (serialize-qp "DateUpdated<" $DateUpdated< "scalar") (serialize-qp "DateUpdated>" $DateUpdated> "scalar") (serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "Status" $Status "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Conferences.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of recordings belonging to the call used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Recordings.json
# operationId: ListConferenceRecording
export def "2010-04-01-accounts-conferences-recordingsjson ListConferenceRecording" [
  AccountSid: string
  ConferenceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --DateCreated: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date)
  --DateCreated<: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date)
  --DateCreated>: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date)
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, recordings: table<account_sid: string, api_version: string, call_sid: string, conference_sid: string, date_created: string, date_updated: string, start_time: string, duration: string, sid: string, price: string, price_unit: string, status: string, channels: int, source: string, error_code: int, encryption_details: any, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "DateCreated" $DateCreated "scalar") (serialize-qp "DateCreated<" $DateCreated< "scalar") (serialize-qp "DateCreated>" $DateCreated> "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Conferences/($ConferenceSid)/Recordings.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Changes the status of the recording to paused, stopped, or in-progress. Note: To use `Twilio.CURRENT`, pass it as recording sid.
#
# POST /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Recordings/{Sid}.json
# operationId: UpdateConferenceRecording
export def "2010-04-01-accounts-conferences-recordings UpdateConferenceRecording" [
  AccountSid: string
  ConferenceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Status: string@Status-completer-3 # The status of the recording. Can be: `processing`, `completed` and `absent`. For more detailed statuses on in-progress recordings, check out how to [Update a Recording Resource](https://www.twilio.com/docs/voice/api/recording#update-a-recording-resource).
  --PauseBehavior: string # Whether to record during a pause. Can be: `skip` or `silence` and the default is `silence`. `skip` does not record during the pause period, while `silence` will replace the actual audio of the call with silence during the pause period. This parameter only applies when setting `status` is set to `paused`.
]: any -> record<account_sid: string, api_version: string, call_sid: string, conference_sid: string, date_created: string, date_updated: string, start_time: string, duration: string, sid: string, price: string, price_unit: string, status: string, channels: int, source: string, error_code: int, encryption_details: any, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Conferences/($ConferenceSid)/Recordings/($Sid).json")
  let body = {Status: $Status, PauseBehavior: $PauseBehavior} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch an instance of a recording for a call
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Recordings/{Sid}.json
# operationId: FetchConferenceRecording
export def "2010-04-01-accounts-conferences-recordings FetchConferenceRecording" [
  AccountSid: string
  ConferenceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, api_version: string, call_sid: string, conference_sid: string, date_created: string, date_updated: string, start_time: string, duration: string, sid: string, price: string, price_unit: string, status: string, channels: int, source: string, error_code: int, encryption_details: any, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Conferences/($ConferenceSid)/Recordings/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a recording from your account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Recordings/{Sid}.json
# operationId: DeleteConferenceRecording
export def "2010-04-01-accounts-conferences-recordings DeleteConferenceRecording" [
  AccountSid: string
  ConferenceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Conferences/($ConferenceSid)/Recordings/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an instance of a connect-app
#
# GET /2010-04-01/Accounts/{AccountSid}/ConnectApps/{Sid}.json
# operationId: FetchConnectApp
export def "2010-04-01-accounts-connect-apps FetchConnectApp" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, authorize_redirect_url: string, company_name: string, deauthorize_callback_method: string, deauthorize_callback_url: string, description: string, friendly_name: string, homepage_url: string, permissions: list<string>, sid: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/ConnectApps/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a connect-app with the specified parameters
#
# POST /2010-04-01/Accounts/{AccountSid}/ConnectApps/{Sid}.json
# operationId: UpdateConnectApp
export def "2010-04-01-accounts-connect-apps UpdateConnectApp" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --AuthorizeRedirectUrl: string # The URL to redirect the user to after we authenticate the user and obtain authorization to access the Connect App. (format: uri)
  --CompanyName: string # The company name to set for the Connect App.
  --DeauthorizeCallbackMethod: string@DeauthorizeCallbackMethod-completer # The HTTP method to use when calling `deauthorize_callback_url`. (format: http-method)
  --DeauthorizeCallbackUrl: string # The URL to call using the `deauthorize_callback_method` to de-authorize the Connect App. (format: uri)
  --Description: string # A description of the Connect App.
  --FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --HomepageUrl: string # A public URL where users can obtain more information about this Connect App. (format: uri)
  --Permissions: list # A comma-separated list of the permissions you will request from the users of this ConnectApp.  Can include: `get-all` and `post-all`.
]: any -> record<account_sid: string, authorize_redirect_url: string, company_name: string, deauthorize_callback_method: string, deauthorize_callback_url: string, description: string, friendly_name: string, homepage_url: string, permissions: list<string>, sid: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/ConnectApps/($Sid).json")
  let body = {AuthorizeRedirectUrl: $AuthorizeRedirectUrl, CompanyName: $CompanyName, DeauthorizeCallbackMethod: $DeauthorizeCallbackMethod, DeauthorizeCallbackUrl: $DeauthorizeCallbackUrl, Description: $Description, FriendlyName: $FriendlyName, HomepageUrl: $HomepageUrl, Permissions: $Permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete an instance of a connect-app
#
# DELETE /2010-04-01/Accounts/{AccountSid}/ConnectApps/{Sid}.json
# operationId: DeleteConnectApp
export def "2010-04-01-accounts-connect-apps DeleteConnectApp" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/ConnectApps/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of connect-apps belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/ConnectApps.json
# operationId: ListConnectApp
export def "2010-04-01-accounts-connect-appsjson ListConnectApp" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, connect_apps: table<account_sid: string, authorize_redirect_url: string, company_name: string, deauthorize_callback_method: string, deauthorize_callback_url: string, description: string, friendly_name: string, homepage_url: string, permissions: list, sid: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/ConnectApps.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Addresses/{AddressSid}/DependentPhoneNumbers.json
#
# operationId: ListDependentPhoneNumber
export def "2010-04-01-accounts-addresses-dependent-phone-numbersjson ListDependentPhoneNumber" [
  AccountSid: string
  AddressSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, dependent_phone_numbers: table<sid: string, account_sid: string, friendly_name: string, phone_number: string, voice_url: string, voice_method: string, voice_fallback_method: string, voice_fallback_url: string, voice_caller_id_lookup: bool, date_created: string, date_updated: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, address_requirements: string, capabilities: any, status_callback: string, status_callback_method: string, api_version: string, sms_application_sid: string, voice_application_sid: string, trunk_sid: string, emergency_status: string, emergency_address_sid: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Addresses/($AddressSid)/DependentPhoneNumbers.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an incoming-phone-number instance.
#
# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{Sid}.json
# operationId: UpdateIncomingPhoneNumber
export def "2010-04-01-accounts-incoming-phone-numbers UpdateIncomingPhoneNumber" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-AccountSid: string # The SID of the [Account](https://www.twilio.com/docs/iam/api/account) that created the IncomingPhoneNumber resource to update.  For more information, see [Exchanging Numbers Between Subaccounts](https://www.twilio.com/docs/iam/api/subaccounts#exchanging-numbers).
  --ApiVersion: string # The API version to use for incoming calls made to the phone number. The default is `2010-04-01`.
  --FriendlyName: string # A descriptive string that you created to describe this phone number. It can be up to 64 characters long. By default, this is a formatted version of the phone number.
  --SmsApplicationSid: string # The SID of the application that should handle SMS messages sent to the number. If an `sms_application_sid` is present, we ignore all of the `sms_*_url` urls and use those set on the application.
  --SmsFallbackMethod: string@SmsFallbackMethod-completer # The HTTP method that we should use to call `sms_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --SmsFallbackUrl: string # The URL that we should call when an error occurs while requesting or executing the TwiML defined by `sms_url`. (format: uri)
  --SmsMethod: string@SmsMethod-completer # The HTTP method that we should use to call `sms_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --SmsUrl: string # The URL we should call when the phone number receives an incoming SMS message. (format: uri)
  --StatusCallback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --VoiceApplicationSid: string # The SID of the application we should use to handle phone calls to the phone number. If a `voice_application_sid` is present, we ignore all of the voice urls and use only those set on the application. Setting a `voice_application_sid` will automatically delete your `trunk_sid` and vice versa.
  --VoiceCallerIdLookup: oneof<nothing, bool> # Whether to lookup the caller's name from the CNAM database and post it to your app. Can be: `true` or `false` and defaults to `false`.
  --VoiceFallbackMethod: string@VoiceFallbackMethod-completer # The HTTP method that we should use to call `voice_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --VoiceFallbackUrl: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --VoiceMethod: string@VoiceMethod-completer # The HTTP method that we should use to call `voice_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --VoiceUrl: string # The URL that we should call to answer a call to the phone number. The `voice_url` will not be called if a `voice_application_sid` or a `trunk_sid` is set. (format: uri)
  --EmergencyStatus: string@EmergencyStatus-completer # The parameter displays if emergency calling is enabled for this number. Active numbers may place emergency calls by dialing valid emergency numbers for the country.
  --EmergencyAddressSid: string # The SID of the emergency address configuration to use for emergency calling from this phone number.
  --TrunkSid: string # The SID of the Trunk we should use to handle phone calls to the phone number. If a `trunk_sid` is present, we ignore all of the voice urls and voice applications and use only those set on the Trunk. Setting a `trunk_sid` will automatically delete your `voice_application_sid` and vice versa.
  --VoiceReceiveMode: string@VoiceReceiveMode-completer
  --IdentitySid: string # The SID of the Identity resource that we should associate with the phone number. Some regions require an identity to meet local regulations.
  --AddressSid: string # The SID of the Address resource we should associate with the phone number. Some regions require addresses to meet local regulations.
  --BundleSid: string # The SID of the Bundle resource that you associate with the phone number. Some regions require a Bundle to meet local Regulations.
]: any -> record<account_sid: string, address_sid: string, address_requirements: string, api_version: string, beta: bool, capabilities: record<mms: bool, sms: bool, voice: bool, fax: bool>, date_created: string, date_updated: string, friendly_name: string, identity_sid: string, phone_number: string, origin: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_receive_mode: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string, emergency_status: string, emergency_address_sid: string, emergency_address_status: string, bundle_sid: string, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/IncomingPhoneNumbers/($Sid).json")
  let body = {AccountSid: $body_AccountSid, ApiVersion: $ApiVersion, FriendlyName: $FriendlyName, SmsApplicationSid: $SmsApplicationSid, SmsFallbackMethod: $SmsFallbackMethod, SmsFallbackUrl: $SmsFallbackUrl, SmsMethod: $SmsMethod, SmsUrl: $SmsUrl, StatusCallback: $StatusCallback, StatusCallbackMethod: $StatusCallbackMethod, VoiceApplicationSid: $VoiceApplicationSid, VoiceCallerIdLookup: $VoiceCallerIdLookup, VoiceFallbackMethod: $VoiceFallbackMethod, VoiceFallbackUrl: $VoiceFallbackUrl, VoiceMethod: $VoiceMethod, VoiceUrl: $VoiceUrl, EmergencyStatus: $EmergencyStatus, EmergencyAddressSid: $EmergencyAddressSid, TrunkSid: $TrunkSid, VoiceReceiveMode: $VoiceReceiveMode, IdentitySid: $IdentitySid, AddressSid: $AddressSid, BundleSid: $BundleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch an incoming-phone-number belonging to the account used to make the request.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{Sid}.json
# operationId: FetchIncomingPhoneNumber
export def "2010-04-01-accounts-incoming-phone-numbers FetchIncomingPhoneNumber" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, address_sid: string, address_requirements: string, api_version: string, beta: bool, capabilities: record<mms: bool, sms: bool, voice: bool, fax: bool>, date_created: string, date_updated: string, friendly_name: string, identity_sid: string, phone_number: string, origin: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_receive_mode: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string, emergency_status: string, emergency_address_sid: string, emergency_address_status: string, bundle_sid: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/IncomingPhoneNumbers/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a phone-numbers belonging to the account used to make the request.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{Sid}.json
# operationId: DeleteIncomingPhoneNumber
export def "2010-04-01-accounts-incoming-phone-numbers DeleteIncomingPhoneNumber" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/IncomingPhoneNumbers/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of incoming-phone-numbers belonging to the account used to make the request.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers.json
# operationId: ListIncomingPhoneNumber
export def "2010-04-01-accounts-incoming-phone-numbersjson ListIncomingPhoneNumber" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Beta: oneof<nothing, bool> # Whether to include phone numbers new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --FriendlyName: string # A string that identifies the IncomingPhoneNumber resources to read.
  --PhoneNumber: string # The phone numbers of the IncomingPhoneNumber resources to read. You can specify partial numbers and use '*' as a wildcard for any digit. (format: phone-number)
  --Origin: string # Whether to include phone numbers based on their origin. Can be: `twilio` or `hosted`. By default, phone numbers of all origin are included.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, incoming_phone_numbers: table<account_sid: string, address_sid: string, address_requirements: string, api_version: string, beta: bool, capabilities: record, date_created: string, date_updated: string, friendly_name: string, identity_sid: string, phone_number: string, origin: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_receive_mode: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string, emergency_status: string, emergency_address_sid: string, emergency_address_status: string, bundle_sid: string, status: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Beta" $Beta "scalar") (serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "PhoneNumber" $PhoneNumber "scalar") (serialize-qp "Origin" $Origin "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/IncomingPhoneNumbers.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Purchase a phone-number for the account.
#
# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers.json
# operationId: CreateIncomingPhoneNumber
export def "2010-04-01-accounts-incoming-phone-numbersjson CreateIncomingPhoneNumber" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ApiVersion: string # The API version to use for incoming calls made to the new phone number. The default is `2010-04-01`.
  --FriendlyName: string # A descriptive string that you created to describe the new phone number. It can be up to 64 characters long. By default, this is a formatted version of the new phone number.
  --SmsApplicationSid: string # The SID of the application that should handle SMS messages sent to the new phone number. If an `sms_application_sid` is present, we ignore all of the `sms_*_url` urls and use those set on the application.
  --SmsFallbackMethod: string@SmsFallbackMethod-completer # The HTTP method that we should use to call `sms_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --SmsFallbackUrl: string # The URL that we should call when an error occurs while requesting or executing the TwiML defined by `sms_url`. (format: uri)
  --SmsMethod: string@SmsMethod-completer # The HTTP method that we should use to call `sms_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --SmsUrl: string # The URL we should call when the new phone number receives an incoming SMS message. (format: uri)
  --StatusCallback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --VoiceApplicationSid: string # The SID of the application we should use to handle calls to the new phone number. If a `voice_application_sid` is present, we ignore all of the voice urls and use only those set on the application. Setting a `voice_application_sid` will automatically delete your `trunk_sid` and vice versa.
  --VoiceCallerIdLookup: oneof<nothing, bool> # Whether to lookup the caller's name from the CNAM database and post it to your app. Can be: `true` or `false` and defaults to `false`.
  --VoiceFallbackMethod: string@VoiceFallbackMethod-completer # The HTTP method that we should use to call `voice_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --VoiceFallbackUrl: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --VoiceMethod: string@VoiceMethod-completer # The HTTP method that we should use to call `voice_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --VoiceUrl: string # The URL that we should call to answer a call to the new phone number. The `voice_url` will not be called if a `voice_application_sid` or a `trunk_sid` is set. (format: uri)
  --EmergencyStatus: string@EmergencyStatus-completer # The parameter displays if emergency calling is enabled for this number. Active numbers may place emergency calls by dialing valid emergency numbers for the country.
  --EmergencyAddressSid: string # The SID of the emergency address configuration to use for emergency calling from the new phone number.
  --TrunkSid: string # The SID of the Trunk we should use to handle calls to the new phone number. If a `trunk_sid` is present, we ignore all of the voice urls and voice applications and use only those set on the Trunk. Setting a `trunk_sid` will automatically delete your `voice_application_sid` and vice versa.
  --IdentitySid: string # The SID of the Identity resource that we should associate with the new phone number. Some regions require an identity to meet local regulations.
  --AddressSid: string # The SID of the Address resource we should associate with the new phone number. Some regions require addresses to meet local regulations.
  --VoiceReceiveMode: string@VoiceReceiveMode-completer
  --BundleSid: string # The SID of the Bundle resource that you associate with the phone number. Some regions require a Bundle to meet local Regulations.
  --PhoneNumber: string # The phone number to purchase specified in [E.164](https://www.twilio.com/docs/glossary/what-e164) format.  E.164 phone numbers consist of a + followed by the country code and subscriber number without punctuation characters. For example, +14155551234. (format: phone-number)
  --AreaCode: string # The desired area code for your new incoming phone number. Can be any three-digit, US or Canada area code. We will provision an available phone number within this area code for you. **You must provide an `area_code` or a `phone_number`.** (US and Canada only).
]: any -> record<account_sid: string, address_sid: string, address_requirements: string, api_version: string, beta: bool, capabilities: record<mms: bool, sms: bool, voice: bool, fax: bool>, date_created: string, date_updated: string, friendly_name: string, identity_sid: string, phone_number: string, origin: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_receive_mode: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string, emergency_status: string, emergency_address_sid: string, emergency_address_status: string, bundle_sid: string, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/IncomingPhoneNumbers.json")
  let body = {ApiVersion: $ApiVersion, FriendlyName: $FriendlyName, SmsApplicationSid: $SmsApplicationSid, SmsFallbackMethod: $SmsFallbackMethod, SmsFallbackUrl: $SmsFallbackUrl, SmsMethod: $SmsMethod, SmsUrl: $SmsUrl, StatusCallback: $StatusCallback, StatusCallbackMethod: $StatusCallbackMethod, VoiceApplicationSid: $VoiceApplicationSid, VoiceCallerIdLookup: $VoiceCallerIdLookup, VoiceFallbackMethod: $VoiceFallbackMethod, VoiceFallbackUrl: $VoiceFallbackUrl, VoiceMethod: $VoiceMethod, VoiceUrl: $VoiceUrl, EmergencyStatus: $EmergencyStatus, EmergencyAddressSid: $EmergencyAddressSid, TrunkSid: $TrunkSid, IdentitySid: $IdentitySid, AddressSid: $AddressSid, VoiceReceiveMode: $VoiceReceiveMode, BundleSid: $BundleSid, PhoneNumber: $PhoneNumber, AreaCode: $AreaCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch an instance of an Add-on installation currently assigned to this Number.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns/{Sid}.json
# operationId: FetchIncomingPhoneNumberAssignedAddOn
export def "2010-04-01-accounts-incoming-phone-numbers-assigned-add-ons FetchIncomingPhoneNumberAssignedAddOn" [
  AccountSid: string
  ResourceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, account_sid: string, resource_sid: string, friendly_name: string, description: string, configuration: any, unique_name: string, date_created: string, date_updated: string, uri: string, subresource_uris: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/IncomingPhoneNumbers/($ResourceSid)/AssignedAddOns/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove the assignment of an Add-on installation from the Number specified.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns/{Sid}.json
# operationId: DeleteIncomingPhoneNumberAssignedAddOn
export def "2010-04-01-accounts-incoming-phone-numbers-assigned-add-ons DeleteIncomingPhoneNumberAssignedAddOn" [
  AccountSid: string
  ResourceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/IncomingPhoneNumbers/($ResourceSid)/AssignedAddOns/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of Add-on installations currently assigned to this Number.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns.json
# operationId: ListIncomingPhoneNumberAssignedAddOn
export def "2010-04-01-accounts-incoming-phone-numbers-assigned-add-onsjson ListIncomingPhoneNumberAssignedAddOn" [
  AccountSid: string
  ResourceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, assigned_add_ons: table<sid: string, account_sid: string, resource_sid: string, friendly_name: string, description: string, configuration: any, unique_name: string, date_created: string, date_updated: string, uri: string, subresource_uris: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/IncomingPhoneNumbers/($ResourceSid)/AssignedAddOns.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign an Add-on installation to the Number specified.
#
# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns.json
# operationId: CreateIncomingPhoneNumberAssignedAddOn
export def "2010-04-01-accounts-incoming-phone-numbers-assigned-add-onsjson CreateIncomingPhoneNumberAssignedAddOn" [
  AccountSid: string
  ResourceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  InstalledAddOnSid: string # The SID that identifies the Add-on installation.
]: any -> record<sid: string, account_sid: string, resource_sid: string, friendly_name: string, description: string, configuration: any, unique_name: string, date_created: string, date_updated: string, uri: string, subresource_uris: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/IncomingPhoneNumbers/($ResourceSid)/AssignedAddOns.json")
  let body = {InstalledAddOnSid: $InstalledAddOnSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch an instance of an Extension for the Assigned Add-on.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns/{AssignedAddOnSid}/Extensions/{Sid}.json
# operationId: FetchIncomingPhoneNumberAssignedAddOnExtension
export def "2010-04-01-accounts-incoming-phone-numbers-assigned-add-ons-extensions FetchIncomingPhoneNumberAssignedAddOnExtension" [
  AccountSid: string
  ResourceSid: string
  AssignedAddOnSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, account_sid: string, resource_sid: string, assigned_add_on_sid: string, friendly_name: string, product_name: string, unique_name: string, uri: string, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/IncomingPhoneNumbers/($ResourceSid)/AssignedAddOns/($AssignedAddOnSid)/Extensions/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of Extensions for the Assigned Add-on.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns/{AssignedAddOnSid}/Extensions.json
# operationId: ListIncomingPhoneNumberAssignedAddOnExtension
export def "2010-04-01-accounts-incoming-phone-numbers-assigned-add-ons-extensionsjson ListIncomingPhoneNumberAssignedAddOnExtension" [
  AccountSid: string
  ResourceSid: string
  AssignedAddOnSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, extensions: table<sid: string, account_sid: string, resource_sid: string, assigned_add_on_sid: string, friendly_name: string, product_name: string, unique_name: string, uri: string, enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/IncomingPhoneNumbers/($ResourceSid)/AssignedAddOns/($AssignedAddOnSid)/Extensions.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/Local.json
#
# operationId: ListIncomingPhoneNumberLocal
export def "2010-04-01-accounts-incoming-phone-numbers-localjson ListIncomingPhoneNumberLocal" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Beta: oneof<nothing, bool> # Whether to include phone numbers new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --FriendlyName: string # A string that identifies the resources to read.
  --PhoneNumber: string # The phone numbers of the IncomingPhoneNumber resources to read. You can specify partial numbers and use '*' as a wildcard for any digit. (format: phone-number)
  --Origin: string # Whether to include phone numbers based on their origin. Can be: `twilio` or `hosted`. By default, phone numbers of all origin are included.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, incoming_phone_numbers: table<account_sid: string, address_sid: string, address_requirements: string, api_version: string, beta: bool, capabilities: record, date_created: string, date_updated: string, friendly_name: string, identity_sid: string, phone_number: string, origin: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_receive_mode: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string, emergency_status: string, emergency_address_sid: string, emergency_address_status: string, bundle_sid: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Beta" $Beta "scalar") (serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "PhoneNumber" $PhoneNumber "scalar") (serialize-qp "Origin" $Origin "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/IncomingPhoneNumbers/Local.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/Local.json
#
# operationId: CreateIncomingPhoneNumberLocal
export def "2010-04-01-accounts-incoming-phone-numbers-localjson CreateIncomingPhoneNumberLocal" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  PhoneNumber: string # The phone number to purchase specified in [E.164](https://www.twilio.com/docs/glossary/what-e164) format.  E.164 phone numbers consist of a + followed by the country code and subscriber number without punctuation characters. For example, +14155551234. (format: phone-number)
  --ApiVersion: string # The API version to use for incoming calls made to the new phone number. The default is `2010-04-01`.
  --FriendlyName: string # A descriptive string that you created to describe the new phone number. It can be up to 64 characters long. By default, this is a formatted version of the phone number.
  --SmsApplicationSid: string # The SID of the application that should handle SMS messages sent to the new phone number. If an `sms_application_sid` is present, we ignore all of the `sms_*_url` urls and use those set on the application.
  --SmsFallbackMethod: string@SmsFallbackMethod-completer # The HTTP method that we should use to call `sms_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --SmsFallbackUrl: string # The URL that we should call when an error occurs while requesting or executing the TwiML defined by `sms_url`. (format: uri)
  --SmsMethod: string@SmsMethod-completer # The HTTP method that we should use to call `sms_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --SmsUrl: string # The URL we should call when the new phone number receives an incoming SMS message. (format: uri)
  --StatusCallback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --VoiceApplicationSid: string # The SID of the application we should use to handle calls to the new phone number. If a `voice_application_sid` is present, we ignore all of the voice urls and use only those set on the application. Setting a `voice_application_sid` will automatically delete your `trunk_sid` and vice versa.
  --VoiceCallerIdLookup: oneof<nothing, bool> # Whether to lookup the caller's name from the CNAM database and post it to your app. Can be: `true` or `false` and defaults to `false`.
  --VoiceFallbackMethod: string@VoiceFallbackMethod-completer # The HTTP method that we should use to call `voice_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --VoiceFallbackUrl: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --VoiceMethod: string@VoiceMethod-completer # The HTTP method that we should use to call `voice_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --VoiceUrl: string # The URL that we should call to answer a call to the new phone number. The `voice_url` will not be called if a `voice_application_sid` or a `trunk_sid` is set. (format: uri)
  --IdentitySid: string # The SID of the Identity resource that we should associate with the new phone number. Some regions require an identity to meet local regulations.
  --AddressSid: string # The SID of the Address resource we should associate with the new phone number. Some regions require addresses to meet local regulations.
  --EmergencyStatus: string@EmergencyStatus-completer # The parameter displays if emergency calling is enabled for this number. Active numbers may place emergency calls by dialing valid emergency numbers for the country.
  --EmergencyAddressSid: string # The SID of the emergency address configuration to use for emergency calling from the new phone number.
  --TrunkSid: string # The SID of the Trunk we should use to handle calls to the new phone number. If a `trunk_sid` is present, we ignore all of the voice urls and voice applications and use only those set on the Trunk. Setting a `trunk_sid` will automatically delete your `voice_application_sid` and vice versa.
  --VoiceReceiveMode: string@VoiceReceiveMode-completer
  --BundleSid: string # The SID of the Bundle resource that you associate with the phone number. Some regions require a Bundle to meet local Regulations.
]: any -> record<account_sid: string, address_sid: string, address_requirements: string, api_version: string, beta: bool, capabilities: record<mms: bool, sms: bool, voice: bool, fax: bool>, date_created: string, date_updated: string, friendly_name: string, identity_sid: string, phone_number: string, origin: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_receive_mode: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string, emergency_status: string, emergency_address_sid: string, emergency_address_status: string, bundle_sid: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/IncomingPhoneNumbers/Local.json")
  let body = {PhoneNumber: $PhoneNumber, ApiVersion: $ApiVersion, FriendlyName: $FriendlyName, SmsApplicationSid: $SmsApplicationSid, SmsFallbackMethod: $SmsFallbackMethod, SmsFallbackUrl: $SmsFallbackUrl, SmsMethod: $SmsMethod, SmsUrl: $SmsUrl, StatusCallback: $StatusCallback, StatusCallbackMethod: $StatusCallbackMethod, VoiceApplicationSid: $VoiceApplicationSid, VoiceCallerIdLookup: $VoiceCallerIdLookup, VoiceFallbackMethod: $VoiceFallbackMethod, VoiceFallbackUrl: $VoiceFallbackUrl, VoiceMethod: $VoiceMethod, VoiceUrl: $VoiceUrl, IdentitySid: $IdentitySid, AddressSid: $AddressSid, EmergencyStatus: $EmergencyStatus, EmergencyAddressSid: $EmergencyAddressSid, TrunkSid: $TrunkSid, VoiceReceiveMode: $VoiceReceiveMode, BundleSid: $BundleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/Mobile.json
#
# operationId: ListIncomingPhoneNumberMobile
export def "2010-04-01-accounts-incoming-phone-numbers-mobilejson ListIncomingPhoneNumberMobile" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Beta: oneof<nothing, bool> # Whether to include phone numbers new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --FriendlyName: string # A string that identifies the resources to read.
  --PhoneNumber: string # The phone numbers of the IncomingPhoneNumber resources to read. You can specify partial numbers and use '*' as a wildcard for any digit. (format: phone-number)
  --Origin: string # Whether to include phone numbers based on their origin. Can be: `twilio` or `hosted`. By default, phone numbers of all origin are included.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, incoming_phone_numbers: table<account_sid: string, address_sid: string, address_requirements: string, api_version: string, beta: bool, capabilities: record, date_created: string, date_updated: string, friendly_name: string, identity_sid: string, phone_number: string, origin: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_receive_mode: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string, emergency_status: string, emergency_address_sid: string, emergency_address_status: string, bundle_sid: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Beta" $Beta "scalar") (serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "PhoneNumber" $PhoneNumber "scalar") (serialize-qp "Origin" $Origin "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/IncomingPhoneNumbers/Mobile.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/Mobile.json
#
# operationId: CreateIncomingPhoneNumberMobile
export def "2010-04-01-accounts-incoming-phone-numbers-mobilejson CreateIncomingPhoneNumberMobile" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  PhoneNumber: string # The phone number to purchase specified in [E.164](https://www.twilio.com/docs/glossary/what-e164) format.  E.164 phone numbers consist of a + followed by the country code and subscriber number without punctuation characters. For example, +14155551234. (format: phone-number)
  --ApiVersion: string # The API version to use for incoming calls made to the new phone number. The default is `2010-04-01`.
  --FriendlyName: string # A descriptive string that you created to describe the new phone number. It can be up to 64 characters long. By default, the is a formatted version of the phone number.
  --SmsApplicationSid: string # The SID of the application that should handle SMS messages sent to the new phone number. If an `sms_application_sid` is present, we ignore all of the `sms_*_url` urls and use those of the application.
  --SmsFallbackMethod: string@SmsFallbackMethod-completer # The HTTP method that we should use to call `sms_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --SmsFallbackUrl: string # The URL that we should call when an error occurs while requesting or executing the TwiML defined by `sms_url`. (format: uri)
  --SmsMethod: string@SmsMethod-completer # The HTTP method that we should use to call `sms_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --SmsUrl: string # The URL we should call when the new phone number receives an incoming SMS message. (format: uri)
  --StatusCallback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --VoiceApplicationSid: string # The SID of the application we should use to handle calls to the new phone number. If a `voice_application_sid` is present, we ignore all of the voice urls and use only those set on the application. Setting a `voice_application_sid` will automatically delete your `trunk_sid` and vice versa.
  --VoiceCallerIdLookup: oneof<nothing, bool> # Whether to lookup the caller's name from the CNAM database and post it to your app. Can be: `true` or `false` and defaults to `false`.
  --VoiceFallbackMethod: string@VoiceFallbackMethod-completer # The HTTP method that we should use to call `voice_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --VoiceFallbackUrl: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --VoiceMethod: string@VoiceMethod-completer # The HTTP method that we should use to call `voice_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --VoiceUrl: string # The URL that we should call to answer a call to the new phone number. The `voice_url` will not be called if a `voice_application_sid` or a `trunk_sid` is set. (format: uri)
  --IdentitySid: string # The SID of the Identity resource that we should associate with the new phone number. Some regions require an identity to meet local regulations.
  --AddressSid: string # The SID of the Address resource we should associate with the new phone number. Some regions require addresses to meet local regulations.
  --EmergencyStatus: string@EmergencyStatus-completer # The parameter displays if emergency calling is enabled for this number. Active numbers may place emergency calls by dialing valid emergency numbers for the country.
  --EmergencyAddressSid: string # The SID of the emergency address configuration to use for emergency calling from the new phone number.
  --TrunkSid: string # The SID of the Trunk we should use to handle calls to the new phone number. If a `trunk_sid` is present, we ignore all of the voice urls and voice applications and use only those set on the Trunk. Setting a `trunk_sid` will automatically delete your `voice_application_sid` and vice versa.
  --VoiceReceiveMode: string@VoiceReceiveMode-completer
  --BundleSid: string # The SID of the Bundle resource that you associate with the phone number. Some regions require a Bundle to meet local Regulations.
]: any -> record<account_sid: string, address_sid: string, address_requirements: string, api_version: string, beta: bool, capabilities: record<mms: bool, sms: bool, voice: bool, fax: bool>, date_created: string, date_updated: string, friendly_name: string, identity_sid: string, phone_number: string, origin: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_receive_mode: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string, emergency_status: string, emergency_address_sid: string, emergency_address_status: string, bundle_sid: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/IncomingPhoneNumbers/Mobile.json")
  let body = {PhoneNumber: $PhoneNumber, ApiVersion: $ApiVersion, FriendlyName: $FriendlyName, SmsApplicationSid: $SmsApplicationSid, SmsFallbackMethod: $SmsFallbackMethod, SmsFallbackUrl: $SmsFallbackUrl, SmsMethod: $SmsMethod, SmsUrl: $SmsUrl, StatusCallback: $StatusCallback, StatusCallbackMethod: $StatusCallbackMethod, VoiceApplicationSid: $VoiceApplicationSid, VoiceCallerIdLookup: $VoiceCallerIdLookup, VoiceFallbackMethod: $VoiceFallbackMethod, VoiceFallbackUrl: $VoiceFallbackUrl, VoiceMethod: $VoiceMethod, VoiceUrl: $VoiceUrl, IdentitySid: $IdentitySid, AddressSid: $AddressSid, EmergencyStatus: $EmergencyStatus, EmergencyAddressSid: $EmergencyAddressSid, TrunkSid: $TrunkSid, VoiceReceiveMode: $VoiceReceiveMode, BundleSid: $BundleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/TollFree.json
#
# operationId: ListIncomingPhoneNumberTollFree
export def "2010-04-01-accounts-incoming-phone-numbers-toll-freejson ListIncomingPhoneNumberTollFree" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Beta: oneof<nothing, bool> # Whether to include phone numbers new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --FriendlyName: string # A string that identifies the resources to read.
  --PhoneNumber: string # The phone numbers of the IncomingPhoneNumber resources to read. You can specify partial numbers and use '*' as a wildcard for any digit. (format: phone-number)
  --Origin: string # Whether to include phone numbers based on their origin. Can be: `twilio` or `hosted`. By default, phone numbers of all origin are included.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, incoming_phone_numbers: table<account_sid: string, address_sid: string, address_requirements: string, api_version: string, beta: bool, capabilities: record, date_created: string, date_updated: string, friendly_name: string, identity_sid: string, phone_number: string, origin: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_receive_mode: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string, emergency_status: string, emergency_address_sid: string, emergency_address_status: string, bundle_sid: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Beta" $Beta "scalar") (serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "PhoneNumber" $PhoneNumber "scalar") (serialize-qp "Origin" $Origin "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/IncomingPhoneNumbers/TollFree.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/TollFree.json
#
# operationId: CreateIncomingPhoneNumberTollFree
export def "2010-04-01-accounts-incoming-phone-numbers-toll-freejson CreateIncomingPhoneNumberTollFree" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  PhoneNumber: string # The phone number to purchase specified in [E.164](https://www.twilio.com/docs/glossary/what-e164) format.  E.164 phone numbers consist of a + followed by the country code and subscriber number without punctuation characters. For example, +14155551234. (format: phone-number)
  --ApiVersion: string # The API version to use for incoming calls made to the new phone number. The default is `2010-04-01`.
  --FriendlyName: string # A descriptive string that you created to describe the new phone number. It can be up to 64 characters long. By default, this is a formatted version of the phone number.
  --SmsApplicationSid: string # The SID of the application that should handle SMS messages sent to the new phone number. If an `sms_application_sid` is present, we ignore all `sms_*_url` values and use those of the application.
  --SmsFallbackMethod: string@SmsFallbackMethod-completer # The HTTP method that we should use to call `sms_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --SmsFallbackUrl: string # The URL that we should call when an error occurs while requesting or executing the TwiML defined by `sms_url`. (format: uri)
  --SmsMethod: string@SmsMethod-completer # The HTTP method that we should use to call `sms_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --SmsUrl: string # The URL we should call when the new phone number receives an incoming SMS message. (format: uri)
  --StatusCallback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --VoiceApplicationSid: string # The SID of the application we should use to handle calls to the new phone number. If a `voice_application_sid` is present, we ignore all of the voice urls and use those set on the application. Setting a `voice_application_sid` will automatically delete your `trunk_sid` and vice versa.
  --VoiceCallerIdLookup: oneof<nothing, bool> # Whether to lookup the caller's name from the CNAM database and post it to your app. Can be: `true` or `false` and defaults to `false`.
  --VoiceFallbackMethod: string@VoiceFallbackMethod-completer # The HTTP method that we should use to call `voice_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --VoiceFallbackUrl: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --VoiceMethod: string@VoiceMethod-completer # The HTTP method that we should use to call `voice_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --VoiceUrl: string # The URL that we should call to answer a call to the new phone number. The `voice_url` will not be called if a `voice_application_sid` or a `trunk_sid` is set. (format: uri)
  --IdentitySid: string # The SID of the Identity resource that we should associate with the new phone number. Some regions require an Identity to meet local regulations.
  --AddressSid: string # The SID of the Address resource we should associate with the new phone number. Some regions require addresses to meet local regulations.
  --EmergencyStatus: string@EmergencyStatus-completer # The parameter displays if emergency calling is enabled for this number. Active numbers may place emergency calls by dialing valid emergency numbers for the country.
  --EmergencyAddressSid: string # The SID of the emergency address configuration to use for emergency calling from the new phone number.
  --TrunkSid: string # The SID of the Trunk we should use to handle calls to the new phone number. If a `trunk_sid` is present, we ignore all of the voice urls and voice applications and use only those set on the Trunk. Setting a `trunk_sid` will automatically delete your `voice_application_sid` and vice versa.
  --VoiceReceiveMode: string@VoiceReceiveMode-completer
  --BundleSid: string # The SID of the Bundle resource that you associate with the phone number. Some regions require a Bundle to meet local Regulations.
]: any -> record<account_sid: string, address_sid: string, address_requirements: string, api_version: string, beta: bool, capabilities: record<mms: bool, sms: bool, voice: bool, fax: bool>, date_created: string, date_updated: string, friendly_name: string, identity_sid: string, phone_number: string, origin: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_receive_mode: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string, emergency_status: string, emergency_address_sid: string, emergency_address_status: string, bundle_sid: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/IncomingPhoneNumbers/TollFree.json")
  let body = {PhoneNumber: $PhoneNumber, ApiVersion: $ApiVersion, FriendlyName: $FriendlyName, SmsApplicationSid: $SmsApplicationSid, SmsFallbackMethod: $SmsFallbackMethod, SmsFallbackUrl: $SmsFallbackUrl, SmsMethod: $SmsMethod, SmsUrl: $SmsUrl, StatusCallback: $StatusCallback, StatusCallbackMethod: $StatusCallbackMethod, VoiceApplicationSid: $VoiceApplicationSid, VoiceCallerIdLookup: $VoiceCallerIdLookup, VoiceFallbackMethod: $VoiceFallbackMethod, VoiceFallbackUrl: $VoiceFallbackUrl, VoiceMethod: $VoiceMethod, VoiceUrl: $VoiceUrl, IdentitySid: $IdentitySid, AddressSid: $AddressSid, EmergencyStatus: $EmergencyStatus, EmergencyAddressSid: $EmergencyAddressSid, TrunkSid: $TrunkSid, VoiceReceiveMode: $VoiceReceiveMode, BundleSid: $BundleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /2010-04-01/Accounts/{AccountSid}/Keys/{Sid}.json
#
# operationId: FetchKey
export def "2010-04-01-accounts-keys FetchKey" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, friendly_name: string, date_created: string, date_updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Keys/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/Keys/{Sid}.json
#
# operationId: UpdateKey
export def "2010-04-01-accounts-keys UpdateKey" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> record<sid: string, friendly_name: string, date_created: string, date_updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Keys/($Sid).json")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /2010-04-01/Accounts/{AccountSid}/Keys/{Sid}.json
#
# operationId: DeleteKey
export def "2010-04-01-accounts-keys DeleteKey" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Keys/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Keys.json
#
# operationId: ListKey
export def "2010-04-01-accounts-keysjson ListKey" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, keys: table<sid: string, friendly_name: string, date_created: string, date_updated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Keys.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/Keys.json
#
# operationId: CreateNewKey
export def "2010-04-01-accounts-keysjson CreateNewKey" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> record<sid: string, friendly_name: string, date_created: string, date_updated: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Keys.json")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete the Media resource.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Messages/{MessageSid}/Media/{Sid}.json
# operationId: DeleteMedia
export def "2010-04-01-accounts-messages-media DeleteMedia" [
  AccountSid: string
  MessageSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Messages/($MessageSid)/Media/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a single Media resource associated with a specific Message resource
#
# GET /2010-04-01/Accounts/{AccountSid}/Messages/{MessageSid}/Media/{Sid}.json
# operationId: FetchMedia
export def "2010-04-01-accounts-messages-media FetchMedia" [
  AccountSid: string
  MessageSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, content_type: string, date_created: string, date_updated: string, parent_sid: string, sid: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Messages/($MessageSid)/Media/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read a list of Media resources associated with a specific Message resource
#
# GET /2010-04-01/Accounts/{AccountSid}/Messages/{MessageSid}/Media.json
# operationId: ListMedia
export def "2010-04-01-accounts-messages-mediajson ListMedia" [
  AccountSid: string
  MessageSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --DateCreated: string # Only include Media resources that were created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read Media that were created on this date. You can also specify an inequality, such as `StartTime<=YYYY-MM-DD`, to read Media that were created on or before midnight of this date, and `StartTime>=YYYY-MM-DD` to read Media that were created on or after midnight of this date. (format: date-time)
  --DateCreated<: string # Only include Media resources that were created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read Media that were created on this date. You can also specify an inequality, such as `StartTime<=YYYY-MM-DD`, to read Media that were created on or before midnight of this date, and `StartTime>=YYYY-MM-DD` to read Media that were created on or after midnight of this date. (format: date-time)
  --DateCreated>: string # Only include Media resources that were created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read Media that were created on this date. You can also specify an inequality, such as `StartTime<=YYYY-MM-DD`, to read Media that were created on or before midnight of this date, and `StartTime>=YYYY-MM-DD` to read Media that were created on or after midnight of this date. (format: date-time)
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, media_list: table<account_sid: string, content_type: string, date_created: string, date_updated: string, parent_sid: string, sid: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "DateCreated" $DateCreated "scalar") (serialize-qp "DateCreated<" $DateCreated< "scalar") (serialize-qp "DateCreated>" $DateCreated> "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Messages/($MessageSid)/Media.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a specific member from the queue
#
# GET /2010-04-01/Accounts/{AccountSid}/Queues/{QueueSid}/Members/{CallSid}.json
# operationId: FetchMember
export def "2010-04-01-accounts-queues-members FetchMember" [
  AccountSid: string
  QueueSid: string
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<call_sid: string, date_enqueued: string, position: int, uri: string, wait_time: int, queue_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Queues/($QueueSid)/Members/($CallSid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Dequeue a member from a queue and have the member's call begin executing the TwiML document at that URL
#
# POST /2010-04-01/Accounts/{AccountSid}/Queues/{QueueSid}/Members/{CallSid}.json
# operationId: UpdateMember
export def "2010-04-01-accounts-queues-members UpdateMember" [
  AccountSid: string
  QueueSid: string
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Url: string # The absolute URL of the Queue resource. (format: uri)
  --Method: string@Method-completer # How to pass the update request data. Can be `GET` or `POST` and the default is `POST`. `POST` sends the data as encoded form data and `GET` sends the data as query parameters. (format: http-method)
]: any -> record<call_sid: string, date_enqueued: string, position: int, uri: string, wait_time: int, queue_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Queues/($QueueSid)/Members/($CallSid).json")
  let body = {Url: $Url, Method: $Method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve the members of the queue
#
# GET /2010-04-01/Accounts/{AccountSid}/Queues/{QueueSid}/Members.json
# operationId: ListMember
export def "2010-04-01-accounts-queues-membersjson ListMember" [
  AccountSid: string
  QueueSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, queue_members: table<call_sid: string, date_enqueued: string, position: int, uri: string, wait_time: int, queue_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Queues/($QueueSid)/Members.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send a message
#
# POST /2010-04-01/Accounts/{AccountSid}/Messages.json
# operationId: CreateMessage
export def "2010-04-01-accounts-messagesjson CreateMessage" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  To: string # The recipient's phone number in [E.164](https://www.twilio.com/docs/glossary/what-e164) format (for SMS/MMS) or [channel address](https://www.twilio.com/docs/messaging/channels), e.g. `whatsapp:+15552229999`. (format: phone-number)
  --StatusCallback: string # The URL of the endpoint to which Twilio sends [Message status callback requests](https://www.twilio.com/docs/sms/api/message-resource#twilios-request-to-the-statuscallback-url). URL must contain a valid hostname and underscores are not allowed. If you include this parameter with the `messaging_service_sid`, Twilio uses this URL instead of the Status Callback URL of the [Messaging Service](https://www.twilio.com/docs/messaging/api/service-resource).  (format: uri)
  --ApplicationSid: string # The SID of the associated [TwiML Application](https://www.twilio.com/docs/usage/api/applications). [Message status callback requests](https://www.twilio.com/docs/sms/api/message-resource#twilios-request-to-the-statuscallback-url) are sent to the TwiML App's `message_status_callback` URL. Note that the `status_callback` parameter of a request takes priority over the `application_sid` parameter; if both are included `application_sid` is ignored.
  --MaxPrice: float # [OBSOLETE] This parameter will no longer have any effect as of 2024-06-03.
  --ProvideFeedback: oneof<nothing, bool> # Boolean indicating whether or not you intend to provide delivery confirmation feedback to Twilio (used in conjunction with the [Message Feedback subresource](https://www.twilio.com/docs/sms/api/message-feedback-resource)). Default value is `false`.
  --Attempt: int # Total number of attempts made (including this request) to send the message regardless of the provider used
  --ValidityPeriod: int # The maximum length in seconds that the Message can remain in Twilio's outgoing message queue. If a queued Message exceeds the `validity_period`, the Message is not sent. Accepted values are integers from `1` to `36000`. Default value is `36000`. A `validity_period` greater than `5` is recommended. [Learn more about the validity period](https://www.twilio.com/blog/take-more-control-of-outbound-messages-using-validity-period-html)
  --ForceDelivery: oneof<nothing, bool> # Reserved
  --ContentRetention: string@ContentRetention-completer # Determines if the message content can be stored or redacted based on privacy settings
  --AddressRetention: string@AddressRetention-completer # Determines if the address can be stored or obfuscated based on privacy settings
  --SmartEncoded: oneof<nothing, bool> # Whether to detect Unicode characters that have a similar GSM-7 character and replace them. Can be: `true` or `false`.
  --PersistentAction: list # Rich actions for non-SMS/MMS channels. Used for [sending location in WhatsApp messages](https://www.twilio.com/docs/whatsapp/message-features#location-messages-with-whatsapp).
  --TrafficType: string@TrafficType-completer
  --ShortenUrls: oneof<nothing, bool> # For Messaging Services with [Link Shortening configured](https://www.twilio.com/docs/messaging/features/link-shortening) only: A Boolean indicating whether or not Twilio should shorten links in the `body` of the Message. Default value is `false`. If `true`, the `messaging_service_sid` parameter must also be provided.
  --ScheduleType: string@ScheduleType-completer # For Messaging Services only: Include this parameter with a value of `fixed` in conjuction with the `send_time` parameter in order to [schedule a Message](https://www.twilio.com/docs/messaging/features/message-scheduling).
  --SendAt: string # The time that Twilio will send the message. Must be in ISO 8601 format. (format: date-time)
  --SendAsMms: oneof<nothing, bool> # If set to `true`, Twilio delivers the message as a single MMS message, regardless of the presence of media.
  --ContentVariables: string # For [Content Editor/API](https://www.twilio.com/docs/content) only: Key-value pairs of [Template variables](https://www.twilio.com/docs/content/using-variables-with-content-api) and their substitution values. `content_sid` parameter must also be provided. If values are not defined in the `content_variables` parameter, the [Template's default placeholder values](https://www.twilio.com/docs/content/content-api-resources#create-templates) are used.
  --RiskCheck: string@RiskCheck-completer # Include this parameter with a value of `disable` to skip any kind of risk check on the respective message request.
  --From: string # The sender's Twilio phone number (in [E.164](https://en.wikipedia.org/wiki/E.164) format), [alphanumeric sender ID](https://www.twilio.com/docs/sms/quickstart), [Wireless SIM](https://www.twilio.com/docs/iot/wireless/programmable-wireless-send-machine-machine-sms-commands), [short code](https://www.twilio.com/en-us/messaging/channels/sms/short-codes), or [channel address](https://www.twilio.com/docs/messaging/channels) (e.g., `whatsapp:+15554449999`). The value of the `from` parameter must be a sender that is hosted within Twilio and belongs to the Account creating the Message. If you are using `messaging_service_sid`, this parameter can be empty (Twilio assigns a `from` value from the Messaging Service's Sender Pool) or you can provide a specific sender from your Sender Pool. (format: phone-number)
  --FallbackFrom: string # A fallback SMS sender to use when the recipient cannot be reached over RCS. This parameter may only be used when also providing a [Messaging Service](https://twilio.com/docs/messaging/services) containing an RCS sender. The fallback SMS sender must be either a Twilio phone number (in [E.164](https://en.wikipedia.org/wiki/E.164) format), [alphanumeric sender ID](https://www.twilio.com/docs/sms/quickstart), or [short code](https://www.twilio.com/en-us/messaging/channels/sms/short-codes), hosted within Twilio and belong to the Account creating the Message. (format: phone-number)
  --MessagingServiceSid: string # The SID of the [Messaging Service](https://www.twilio.com/docs/messaging/services) you want to associate with the Message. When this parameter is provided and the `from` parameter is omitted, Twilio selects the optimal sender from the Messaging Service's Sender Pool. You may also provide a `from` parameter if you want to use a specific Sender from the Sender Pool.
  --Body: string # The text content of the outgoing message. Can be up to 1,600 characters in length. SMS only: If the `body` contains more than 160 [GSM-7](https://www.twilio.com/docs/glossary/what-is-gsm-7-character-encoding) characters (or 70 [UCS-2](https://www.twilio.com/docs/glossary/what-is-ucs-2-character-encoding) characters), the message is segmented and charged accordingly. For long `body` text, consider using the [send_as_mms parameter](https://www.twilio.com/blog/mms-for-long-text-messages).
  --MediaUrl: list # The URL of media to include in the Message content. `jpeg`, `jpg`, `gif`, and `png` file types are fully supported by Twilio and content is formatted for delivery on destination devices. The media size limit is 5 MB for supported file types (`jpeg`, `jpg`, `png`, `gif`) and 500 KB for [other types](https://www.twilio.com/docs/messaging/guides/accepted-mime-types) of accepted media. To send more than one image in the message, provide multiple `media_url` parameters in the POST request. You can include up to ten `media_url` parameters per message. [International](https://support.twilio.com/hc/en-us/articles/223179808-Sending-and-receiving-MMS-messages) and [carrier](https://support.twilio.com/hc/en-us/articles/223133707-Is-MMS-supported-for-all-carriers-in-US-and-Canada-) limits apply.
  --ContentSid: string # For [Content Editor/API](https://www.twilio.com/docs/content) only: The SID of the Content Template to be used with the Message, e.g., `HXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`. If this parameter is not provided, a Content Template is not used. Find the SID in the Console on the Content Editor page. For Content API users, the SID is found in Twilio's response when [creating the Template](https://www.twilio.com/docs/content/content-api-resources#create-templates) or by [fetching your Templates](https://www.twilio.com/docs/content/content-api-resources#fetch-all-content-resources).
]: any -> record<body: string, num_segments: string, direction: string, from: string, to: string, date_updated: string, price: string, error_message: string, uri: string, account_sid: string, num_media: string, status: string, messaging_service_sid: string, sid: string, date_sent: string, date_created: string, error_code: int, price_unit: string, api_version: string, subresource_uris: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Messages.json")
  let body = {To: $To, StatusCallback: $StatusCallback, ApplicationSid: $ApplicationSid, MaxPrice: $MaxPrice, ProvideFeedback: $ProvideFeedback, Attempt: $Attempt, ValidityPeriod: $ValidityPeriod, ForceDelivery: $ForceDelivery, ContentRetention: $ContentRetention, AddressRetention: $AddressRetention, SmartEncoded: $SmartEncoded, PersistentAction: $PersistentAction, TrafficType: $TrafficType, ShortenUrls: $ShortenUrls, ScheduleType: $ScheduleType, SendAt: $SendAt, SendAsMms: $SendAsMms, ContentVariables: $ContentVariables, RiskCheck: $RiskCheck, From: $From, FallbackFrom: $FallbackFrom, MessagingServiceSid: $MessagingServiceSid, Body: $Body, MediaUrl: $MediaUrl, ContentSid: $ContentSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of Message resources associated with a Twilio Account
#
# GET /2010-04-01/Accounts/{AccountSid}/Messages.json
# operationId: ListMessage
export def "2010-04-01-accounts-messagesjson ListMessage" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --To: string # Filter by recipient. For example: Set this parameter to `+15558881111` to retrieve a list of Message resources sent to `+15558881111`. (format: phone-number)
  --From: string # Filter by sender. For example: Set this parameter to `+15552229999` to retrieve a list of Message resources sent by `+15552229999`. (format: phone-number)
  --DateSent: string # Filter by Message `sent_date`. Accepts GMT dates in the following formats: `YYYY-MM-DD` (to find Messages with a specific `sent_date`), `<=YYYY-MM-DD` (to find Messages with `sent_date`s on and before a specific date), and `>=YYYY-MM-DD` (to find Messages with `sent_dates` on and after a specific date). (format: date-time)
  --DateSent<: string # Filter by Message `sent_date`. Accepts GMT dates in the following formats: `YYYY-MM-DD` (to find Messages with a specific `sent_date`), `<=YYYY-MM-DD` (to find Messages with `sent_date`s on and before a specific date), and `>=YYYY-MM-DD` (to find Messages with `sent_dates` on and after a specific date). (format: date-time)
  --DateSent>: string # Filter by Message `sent_date`. Accepts GMT dates in the following formats: `YYYY-MM-DD` (to find Messages with a specific `sent_date`), `<=YYYY-MM-DD` (to find Messages with `sent_date`s on and before a specific date), and `>=YYYY-MM-DD` (to find Messages with `sent_dates` on and after a specific date). (format: date-time)
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, messages: table<body: string, num_segments: string, direction: string, from: string, to: string, date_updated: string, price: string, error_message: string, uri: string, account_sid: string, num_media: string, status: string, messaging_service_sid: string, sid: string, date_sent: string, date_created: string, error_code: int, price_unit: string, api_version: string, subresource_uris: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "To" $To "scalar") (serialize-qp "From" $From "scalar") (serialize-qp "DateSent" $DateSent "scalar") (serialize-qp "DateSent<" $DateSent< "scalar") (serialize-qp "DateSent>" $DateSent> "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Messages.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a Message resource from your account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Messages/{Sid}.json
# operationId: DeleteMessage
export def "2010-04-01-accounts-messages DeleteMessage" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Messages/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a specific Message
#
# GET /2010-04-01/Accounts/{AccountSid}/Messages/{Sid}.json
# operationId: FetchMessage
export def "2010-04-01-accounts-messages FetchMessage" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<body: string, num_segments: string, direction: string, from: string, to: string, date_updated: string, price: string, error_message: string, uri: string, account_sid: string, num_media: string, status: string, messaging_service_sid: string, sid: string, date_sent: string, date_created: string, error_code: int, price_unit: string, api_version: string, subresource_uris: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Messages/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Message resource (used to redact Message `body` text and to cancel not-yet-sent messages)
#
# POST /2010-04-01/Accounts/{AccountSid}/Messages/{Sid}.json
# operationId: UpdateMessage
export def "2010-04-01-accounts-messages UpdateMessage" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Body: string # The new `body` of the Message resource. To redact the text content of a Message, this parameter's value must be an empty string
  --Status: string@Status-completer-6
]: any -> record<body: string, num_segments: string, direction: string, from: string, to: string, date_updated: string, price: string, error_message: string, uri: string, account_sid: string, num_media: string, status: string, messaging_service_sid: string, sid: string, date_sent: string, date_created: string, error_code: int, price_unit: string, api_version: string, subresource_uris: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Messages/($Sid).json")
  let body = {Body: $Body, Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create Message Feedback to confirm a tracked user action was performed by the recipient of the associated Message
#
# POST /2010-04-01/Accounts/{AccountSid}/Messages/{MessageSid}/Feedback.json
# operationId: CreateMessageFeedback
export def "2010-04-01-accounts-messages-feedbackjson CreateMessageFeedback" [
  AccountSid: string
  MessageSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Outcome: string@Outcome-completer # Reported outcome indicating whether there is confirmation that the Message recipient performed a tracked user action. Can be: `unconfirmed` or `confirmed`. For more details see [How to Optimize Message Deliverability with Message Feedback](https://www.twilio.com/docs/messaging/guides/send-message-feedback-to-twilio).
]: any -> record<account_sid: string, message_sid: string, outcome: string, date_created: string, date_updated: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Messages/($MessageSid)/Feedback.json")
  let body = {Outcome: $Outcome} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a new Signing Key for the account making the request.
#
# POST /2010-04-01/Accounts/{AccountSid}/SigningKeys.json
# operationId: CreateNewSigningKey
export def "2010-04-01-accounts-signing-keysjson CreateNewSigningKey" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> record<sid: string, friendly_name: string, date_created: string, date_updated: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SigningKeys.json")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /2010-04-01/Accounts/{AccountSid}/SigningKeys.json
#
# operationId: ListSigningKey
export def "2010-04-01-accounts-signing-keysjson ListSigningKey" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, signing_keys: table<sid: string, friendly_name: string, date_created: string, date_updated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SigningKeys.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a notification belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Notifications/{Sid}.json
# operationId: FetchNotification
export def "2010-04-01-accounts-notifications FetchNotification" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, api_version: string, call_sid: string, date_created: string, date_updated: string, error_code: string, log: string, message_date: string, message_text: string, more_info: string, request_method: string, request_url: string, request_variables: string, response_body: string, response_headers: string, sid: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Notifications/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of notifications belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Notifications.json
# operationId: ListNotification
export def "2010-04-01-accounts-notificationsjson ListNotification" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Log: int # Only read notifications of the specified log level. Can be:  `0` to read only ERROR notifications or `1` to read only WARNING notifications. By default, all notifications are read.
  --MessageDate: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date)
  --MessageDate<: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date)
  --MessageDate>: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date)
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, notifications: table<account_sid: string, api_version: string, call_sid: string, date_created: string, date_updated: string, error_code: string, log: string, message_date: string, message_text: string, more_info: string, request_method: string, request_url: string, sid: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Log" $Log "scalar") (serialize-qp "MessageDate" $MessageDate "scalar") (serialize-qp "MessageDate<" $MessageDate< "scalar") (serialize-qp "MessageDate>" $MessageDate> "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Notifications.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an outgoing-caller-id belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds/{Sid}.json
# operationId: FetchOutgoingCallerId
export def "2010-04-01-accounts-outgoing-caller-ids FetchOutgoingCallerId" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, date_created: string, date_updated: string, friendly_name: string, account_sid: string, phone_number: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/OutgoingCallerIds/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the caller-id
#
# POST /2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds/{Sid}.json
# operationId: UpdateOutgoingCallerId
export def "2010-04-01-accounts-outgoing-caller-ids UpdateOutgoingCallerId" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> record<sid: string, date_created: string, date_updated: string, friendly_name: string, account_sid: string, phone_number: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/OutgoingCallerIds/($Sid).json")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete the caller-id specified from the account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds/{Sid}.json
# operationId: DeleteOutgoingCallerId
export def "2010-04-01-accounts-outgoing-caller-ids DeleteOutgoingCallerId" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/OutgoingCallerIds/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of outgoing-caller-ids belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds.json
# operationId: ListOutgoingCallerId
export def "2010-04-01-accounts-outgoing-caller-idsjson ListOutgoingCallerId" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PhoneNumber: string # The phone number of the OutgoingCallerId resources to read. (format: phone-number)
  --FriendlyName: string # The string that identifies the OutgoingCallerId resources to read.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, outgoing_caller_ids: table<sid: string, date_created: string, date_updated: string, friendly_name: string, account_sid: string, phone_number: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PhoneNumber" $PhoneNumber "scalar") (serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/OutgoingCallerIds.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds.json
#
# operationId: CreateValidationRequest
export def "2010-04-01-accounts-outgoing-caller-idsjson CreateValidationRequest" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  PhoneNumber: string # The phone number to verify in [E.164](https://www.twilio.com/docs/glossary/what-e164) format, which consists of a + followed by the country code and subscriber number. (format: phone-number)
  --FriendlyName: string # A descriptive string that you create to describe the new caller ID resource. It can be up to 64 characters long. The default value is a formatted version of the phone number.
  --CallDelay: int # The number of seconds to delay before initiating the verification call. Can be an integer between `0` and `60`, inclusive. The default is `0`.
  --Extension: string # The digits to dial after connecting the verification call.
  --StatusCallback: string # The URL we should call using the `status_callback_method` to send status information about the verification process to your application. (format: uri)
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST`, and the default is `POST`. (format: http-method)
]: any -> record<account_sid: string, call_sid: string, friendly_name: string, phone_number: string, validation_code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/OutgoingCallerIds.json")
  let body = {PhoneNumber: $PhoneNumber, FriendlyName: $FriendlyName, CallDelay: $CallDelay, Extension: $Extension, StatusCallback: $StatusCallback, StatusCallbackMethod: $StatusCallbackMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch an instance of a participant
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants/{CallSid}.json
# operationId: FetchParticipant
export def "2010-04-01-accounts-conferences-participants FetchParticipant" [
  AccountSid: string
  ConferenceSid: string
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, call_sid: string, label: string, call_sid_to_coach: string, coaching: bool, conference_sid: string, date_created: string, date_updated: string, end_conference_on_exit: bool, muted: bool, hold: bool, start_conference_on_enter: bool, status: string, queue_time: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Conferences/($ConferenceSid)/Participants/($CallSid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the properties of the participant
#
# POST /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants/{CallSid}.json
# operationId: UpdateParticipant
export def "2010-04-01-accounts-conferences-participants UpdateParticipant" [
  AccountSid: string
  ConferenceSid: string
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Muted: oneof<nothing, bool> # Whether the participant should be muted. Can be `true` or `false`. `true` will mute the participant, and `false` will un-mute them. Anything value other than `true` or `false` is interpreted as `false`.
  --Hold: oneof<nothing, bool> # Whether the participant should be on hold. Can be: `true` or `false`. `true` puts the participant on hold, and `false` lets them rejoin the conference.
  --HoldUrl: string # The URL we call using the `hold_method` for music that plays when the participant is on hold. The URL may return an MP3 file, a WAV file, or a TwiML document that contains `<Play>`, `<Say>`, `<Pause>`, or `<Redirect>` verbs. (format: uri)
  --HoldMethod: string@HoldMethod-completer # The HTTP method we should use to call `hold_url`. Can be: `GET` or `POST` and the default is `GET`. (format: http-method)
  --AnnounceUrl: string # The URL we call using the `announce_method` for an announcement to the participant. The URL may return an MP3 file, a WAV file, or a TwiML document that contains `<Play>`, `<Say>`, `<Pause>`, or `<Redirect>` verbs. (format: uri)
  --AnnounceMethod: string@AnnounceMethod-completer # The HTTP method we should use to call `announce_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --WaitUrl: string # The URL that Twilio calls using the `wait_method` before the conference has started. The URL may return an MP3 file, a WAV file, or a TwiML document. The default value is the URL of our standard hold music. If you do not want anything to play while waiting for the conference to start, specify an empty string by setting `wait_url` to `''`. For more details on the allowable verbs within the `waitUrl`, see the `waitUrl` attribute in the [<Conference> TwiML instruction](https://www.twilio.com/docs/voice/twiml/conference#attributes-waiturl). (format: uri)
  --WaitMethod: string@WaitMethod-completer # The HTTP method we should use to call `wait_url`. Can be `GET` or `POST` and the default is `POST`. When using a static audio file, this should be `GET` so that we can cache the file. (format: http-method)
  --BeepOnExit: oneof<nothing, bool> # Whether to play a notification beep to the conference when the participant exits. Can be: `true` or `false`.
  --EndConferenceOnExit: oneof<nothing, bool> # Whether to end the conference when the participant leaves. Can be: `true` or `false` and defaults to `false`.
  --Coaching: oneof<nothing, bool> # Whether the participant is coaching another call. Can be: `true` or `false`. If not present, defaults to `false` unless `call_sid_to_coach` is defined. If `true`, `call_sid_to_coach` must be defined.
  --CallSidToCoach: string # The SID of the participant who is being `coached`. The participant being coached is the only participant who can hear the participant who is `coaching`.
]: any -> record<account_sid: string, call_sid: string, label: string, call_sid_to_coach: string, coaching: bool, conference_sid: string, date_created: string, date_updated: string, end_conference_on_exit: bool, muted: bool, hold: bool, start_conference_on_enter: bool, status: string, queue_time: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Conferences/($ConferenceSid)/Participants/($CallSid).json")
  let body = {Muted: $Muted, Hold: $Hold, HoldUrl: $HoldUrl, HoldMethod: $HoldMethod, AnnounceUrl: $AnnounceUrl, AnnounceMethod: $AnnounceMethod, WaitUrl: $WaitUrl, WaitMethod: $WaitMethod, BeepOnExit: $BeepOnExit, EndConferenceOnExit: $EndConferenceOnExit, Coaching: $Coaching, CallSidToCoach: $CallSidToCoach} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Kick a participant from a given conference
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants/{CallSid}.json
# operationId: DeleteParticipant
export def "2010-04-01-accounts-conferences-participants DeleteParticipant" [
  AccountSid: string
  ConferenceSid: string
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Conferences/($ConferenceSid)/Participants/($CallSid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants.json
#
# operationId: CreateParticipant
export def "2010-04-01-accounts-conferences-participantsjson CreateParticipant" [
  AccountSid: string
  ConferenceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  From: string # The phone number, Client identifier, or username portion of SIP address that made this call. Phone numbers are in [E.164](https://www.twilio.com/docs/glossary/what-e164) format (e.g., +16175551212). Client identifiers are formatted `client:name`. If using a phone number, it must be a Twilio number or a Verified [outgoing caller id](https://www.twilio.com/docs/voice/api/outgoing-caller-ids) for your account. If the `to` parameter is a phone number, `from` must also be a phone number. If `to` is sip address, this value of `from` should be a username portion to be used to populate the P-Asserted-Identity header that is passed to the SIP endpoint. (format: endpoint)
  To: string # The phone number, SIP address, Client, TwiML App identifier that received this call. Phone numbers are in [E.164](https://www.twilio.com/docs/glossary/what-e164) format (e.g., +16175551212). SIP addresses are formatted as `sip:name@company.com`. Client identifiers are formatted `client:name`. TwiML App identifiers are formatted `app:<APP_SID>`. [Custom parameters](https://www.twilio.com/docs/voice/api/conference-participant-resource#custom-parameters) may also be specified. (format: endpoint)
  --StatusCallback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` and `POST` and defaults to `POST`. (format: http-method)
  --StatusCallbackEvent: list # The conference state changes that should generate a call to `status_callback`. Can be: `initiated`, `ringing`, `answered`, and `completed`. Separate multiple values with a space. The default value is `completed`.
  --Label: string # A label for this participant. If one is supplied, it may subsequently be used to fetch, update or delete the participant.
  --Timeout: int # The number of seconds that we should allow the phone to ring before assuming there is no answer. Can be an integer between `5` and `600`, inclusive. The default value is `60`. We always add a 5-second timeout buffer to outgoing calls, so  value of 10 would result in an actual timeout that was closer to 15 seconds.
  --Record: oneof<nothing, bool> # Whether to record the participant and their conferences, including the time between conferences. Can be `true` or `false` and the default is `false`.
  --Muted: oneof<nothing, bool> # Whether the agent is muted in the conference. Can be `true` or `false` and the default is `false`.
  --Beep: string # Whether to play a notification beep to the conference when the participant joins. Can be: `true`, `false`, `onEnter`, or `onExit`. The default value is `true`.
  --StartConferenceOnEnter: oneof<nothing, bool> # Whether to start the conference when the participant joins, if it has not already started. Can be: `true` or `false` and the default is `true`. If `false` and the conference has not started, the participant is muted and hears background music until another participant starts the conference.
  --EndConferenceOnExit: oneof<nothing, bool> # Whether to end the conference when the participant leaves. Can be: `true` or `false` and defaults to `false`.
  --WaitUrl: string # The URL that Twilio calls using the `wait_method` before the conference has started. The URL may return an MP3 file, a WAV file, or a TwiML document. The default value is the URL of our standard hold music. If you do not want anything to play while waiting for the conference to start, specify an empty string by setting `wait_url` to `''`. For more details on the allowable verbs within the `waitUrl`, see the `waitUrl` attribute in the [<Conference> TwiML instruction](https://www.twilio.com/docs/voice/twiml/conference#attributes-waiturl). (format: uri)
  --WaitMethod: string@WaitMethod-completer # The HTTP method we should use to call `wait_url`. Can be `GET` or `POST` and the default is `POST`. When using a static audio file, this should be `GET` so that we can cache the file. (format: http-method)
  --EarlyMedia: oneof<nothing, bool> # Whether to allow an agent to hear the state of the outbound call, including ringing or disconnect messages. Can be: `true` or `false` and defaults to `true`.
  --MaxParticipants: int # The maximum number of participants in the conference. Can be a positive integer from `2` to `250`. The default value is `250`.
  --ConferenceRecord: string # Whether to record the conference the participant is joining. Can be: `true`, `false`, `record-from-start`, and `do-not-record`. The default value is `false`.
  --ConferenceTrim: string # Whether to trim leading and trailing silence from the conference recording. Can be: `trim-silence` or `do-not-trim` and defaults to `trim-silence`.
  --ConferenceStatusCallback: string # The URL we should call using the `conference_status_callback_method` when the conference events in `conference_status_callback_event` occur. Only the value set by the first participant to join the conference is used. Subsequent `conference_status_callback` values are ignored. (format: uri)
  --ConferenceStatusCallbackMethod: string@ConferenceStatusCallbackMethod-completer # The HTTP method we should use to call `conference_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --ConferenceStatusCallbackEvent: list # The conference state changes that should generate a call to `conference_status_callback`. Can be: `start`, `end`, `join`, `leave`, `mute`, `hold`, `modify`, `speaker`, and `announcement`. Separate multiple values with a space. Defaults to `start end`.
  --RecordingChannels: string # The recording channels for the final recording. Can be: `mono` or `dual` and the default is `mono`.
  --RecordingStatusCallback: string # The URL that we should call using the `recording_status_callback_method` when the recording status changes. (format: uri)
  --RecordingStatusCallbackMethod: string@RecordingStatusCallbackMethod-completer # The HTTP method we should use when we call `recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --SipAuthUsername: string # The SIP username used for authentication.
  --SipAuthPassword: string # The SIP password for authentication.
  --Region: string # The [region](https://support.twilio.com/hc/en-us/articles/223132167-How-global-low-latency-routing-and-region-selection-work-for-conferences-and-Client-calls) where we should mix the recorded audio. Can be:`us1`, `us2`, `ie1`, `de1`, `sg1`, `br1`, `au1`, or `jp1`.
  --ConferenceRecordingStatusCallback: string # The URL we should call using the `conference_recording_status_callback_method` when the conference recording is available. (format: uri)
  --ConferenceRecordingStatusCallbackMethod: string@ConferenceRecordingStatusCallbackMethod-completer # The HTTP method we should use to call `conference_recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --RecordingStatusCallbackEvent: list # The recording state changes that should generate a call to `recording_status_callback`. Can be: `started`, `in-progress`, `paused`, `resumed`, `stopped`, `completed`, `failed`, and `absent`. Separate multiple values with a space, ex: `'in-progress completed failed'`.
  --ConferenceRecordingStatusCallbackEvent: list # The conference recording state changes that generate a call to `conference_recording_status_callback`. Can be: `in-progress`, `completed`, `failed`, and `absent`. Separate multiple values with a space, ex: `'in-progress completed failed'`
  --Coaching: oneof<nothing, bool> # Whether the participant is coaching another call. Can be: `true` or `false`. If not present, defaults to `false` unless `call_sid_to_coach` is defined. If `true`, `call_sid_to_coach` must be defined.
  --CallSidToCoach: string # The SID of the participant who is being `coached`. The participant being coached is the only participant who can hear the participant who is `coaching`.
  --JitterBufferSize: string # Jitter buffer size for the connecting participant. Twilio will use this setting to apply Jitter Buffer before participant's audio is mixed into the conference. Can be: `off`, `small`, `medium`, and `large`. Default to `large`.
  --Byoc: string # The SID of a BYOC (Bring Your Own Carrier) trunk to route this call with. Note that `byoc` is only meaningful when `to` is a phone number; it will otherwise be ignored. (Beta)
  --CallerId: string # The phone number, Client identifier, or username portion of SIP address that made this call. Phone numbers are in [E.164](https://www.twilio.com/docs/glossary/what-e164) format (e.g., +16175551212). Client identifiers are formatted `client:name`. If using a phone number, it must be a Twilio number or a Verified [outgoing caller id](https://www.twilio.com/docs/voice/api/outgoing-caller-ids) for your account. If the `to` parameter is a phone number, `callerId` must also be a phone number. If `to` is sip address, this value of `callerId` should be a username portion to be used to populate the From header that is passed to the SIP endpoint.
  --CallReason: string # The Reason for the outgoing call. Use it to specify the purpose of the call that is presented on the called party's phone. (Branded Calls Beta)
  --RecordingTrack: string # The audio track to record for the call. Can be: `inbound`, `outbound` or `both`. The default is `both`. `inbound` records the audio that is received by Twilio. `outbound` records the audio that is sent from Twilio. `both` records the audio that is received and sent by Twilio.
  --RecordingConfigurationId: string # The identifier of the configuration to be used when creating and processing the recording
  --TimeLimit: int # The maximum duration of the call in seconds. Constraints depend on account and configuration.
  --MachineDetection: string # Whether to detect if a human, answering machine, or fax has picked up the call. Can be: `Enable` or `DetectMessageEnd`. Use `Enable` if you would like us to return `AnsweredBy` as soon as the called party is identified. Use `DetectMessageEnd`, if you would like to leave a message on an answering machine. For more information, see [Answering Machine Detection](https://www.twilio.com/docs/voice/answering-machine-detection).
  --MachineDetectionTimeout: int # The number of seconds that we should attempt to detect an answering machine before timing out and sending a voice request with `AnsweredBy` of `unknown`. The default timeout is 30 seconds.
  --MachineDetectionSpeechThreshold: int # The number of milliseconds that is used as the measuring stick for the length of the speech activity, where durations lower than this value will be interpreted as a human and longer than this value as a machine. Possible Values: 1000-6000. Default: 2400.
  --MachineDetectionSpeechEndThreshold: int # The number of milliseconds of silence after speech activity at which point the speech activity is considered complete. Possible Values: 500-5000. Default: 1200.
  --MachineDetectionSilenceTimeout: int # The number of milliseconds of initial silence after which an `unknown` AnsweredBy result will be returned. Possible Values: 2000-10000. Default: 5000.
  --AmdStatusCallback: string # The URL that we should call using the `amd_status_callback_method` to notify customer application whether the call was answered by human, machine or fax. (format: uri)
  --AmdStatusCallbackMethod: string@AmdStatusCallbackMethod-completer # The HTTP method we should use when calling the `amd_status_callback` URL. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  --Trim: string # Whether to trim any leading and trailing silence from the participant recording. Can be: `trim-silence` or `do-not-trim` and the default is `trim-silence`.
  --CallToken: string # A token string needed to invoke a forwarded call. A call_token is generated when an incoming call is received on a Twilio number. Pass an incoming call's call_token value to a forwarded call via the call_token parameter when creating a new call. A forwarded call should bear the same CallerID of the original incoming call.
  --ClientNotificationUrl: string # The URL that we should use to deliver `push call notification`. (format: uri)
  --CallerDisplayName: string # The name that populates the display name in the From header. Must be between 2 and 255 characters. Only applicable for calls to sip address.
]: any -> record<account_sid: string, call_sid: string, label: string, call_sid_to_coach: string, coaching: bool, conference_sid: string, date_created: string, date_updated: string, end_conference_on_exit: bool, muted: bool, hold: bool, start_conference_on_enter: bool, status: string, queue_time: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Conferences/($ConferenceSid)/Participants.json")
  let body = {From: $From, To: $To, StatusCallback: $StatusCallback, StatusCallbackMethod: $StatusCallbackMethod, StatusCallbackEvent: $StatusCallbackEvent, Label: $Label, Timeout: $Timeout, Record: $Record, Muted: $Muted, Beep: $Beep, StartConferenceOnEnter: $StartConferenceOnEnter, EndConferenceOnExit: $EndConferenceOnExit, WaitUrl: $WaitUrl, WaitMethod: $WaitMethod, EarlyMedia: $EarlyMedia, MaxParticipants: $MaxParticipants, ConferenceRecord: $ConferenceRecord, ConferenceTrim: $ConferenceTrim, ConferenceStatusCallback: $ConferenceStatusCallback, ConferenceStatusCallbackMethod: $ConferenceStatusCallbackMethod, ConferenceStatusCallbackEvent: $ConferenceStatusCallbackEvent, RecordingChannels: $RecordingChannels, RecordingStatusCallback: $RecordingStatusCallback, RecordingStatusCallbackMethod: $RecordingStatusCallbackMethod, SipAuthUsername: $SipAuthUsername, SipAuthPassword: $SipAuthPassword, Region: $Region, ConferenceRecordingStatusCallback: $ConferenceRecordingStatusCallback, ConferenceRecordingStatusCallbackMethod: $ConferenceRecordingStatusCallbackMethod, RecordingStatusCallbackEvent: $RecordingStatusCallbackEvent, ConferenceRecordingStatusCallbackEvent: $ConferenceRecordingStatusCallbackEvent, Coaching: $Coaching, CallSidToCoach: $CallSidToCoach, JitterBufferSize: $JitterBufferSize, Byoc: $Byoc, CallerId: $CallerId, CallReason: $CallReason, RecordingTrack: $RecordingTrack, RecordingConfigurationId: $RecordingConfigurationId, TimeLimit: $TimeLimit, MachineDetection: $MachineDetection, MachineDetectionTimeout: $MachineDetectionTimeout, MachineDetectionSpeechThreshold: $MachineDetectionSpeechThreshold, MachineDetectionSpeechEndThreshold: $MachineDetectionSpeechEndThreshold, MachineDetectionSilenceTimeout: $MachineDetectionSilenceTimeout, AmdStatusCallback: $AmdStatusCallback, AmdStatusCallbackMethod: $AmdStatusCallbackMethod, Trim: $Trim, CallToken: $CallToken, ClientNotificationUrl: $ClientNotificationUrl, CallerDisplayName: $CallerDisplayName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of participants belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants.json
# operationId: ListParticipant
export def "2010-04-01-accounts-conferences-participantsjson ListParticipant" [
  AccountSid: string
  ConferenceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Muted: oneof<nothing, bool> # Whether to return only participants that are muted. Can be: `true` or `false`.
  --Hold: oneof<nothing, bool> # Whether to return only participants that are on hold. Can be: `true` or `false`.
  --Coaching: oneof<nothing, bool> # Whether to return only participants who are coaching another call. Can be: `true` or `false`.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, participants: table<account_sid: string, call_sid: string, label: string, call_sid_to_coach: string, coaching: bool, conference_sid: string, date_created: string, date_updated: string, end_conference_on_exit: bool, muted: bool, hold: bool, start_conference_on_enter: bool, status: string, queue_time: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Muted" $Muted "scalar") (serialize-qp "Hold" $Hold "scalar") (serialize-qp "Coaching" $Coaching "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Conferences/($ConferenceSid)/Participants.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# create an instance of payments. This will start a new payments session
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Payments.json
# operationId: CreatePayments
export def "2010-04-01-accounts-calls-paymentsjson CreatePayments" [
  AccountSid: string
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  IdempotencyKey: string # A unique token that will be used to ensure that multiple API calls with the same information do not result in multiple transactions. This should be a unique string value per API call and can be a randomly generated.
  StatusCallback: string # Provide an absolute or relative URL to receive status updates regarding your Pay session. Read more about the [expected StatusCallback values](https://www.twilio.com/docs/voice/api/payment-resource#statuscallback) (format: uri)
  --BankAccountType: string@BankAccountType-completer # Type of bank account if payment source is ACH. One of `consumer-checking`, `consumer-savings`, or `commercial-checking`. The default value is `consumer-checking`.
  --ChargeAmount: float # A positive decimal value less than 1,000,000 to charge against the credit card or bank account. Default currency can be overwritten with `currency` field. Leave blank or set to 0 to tokenize.
  --Currency: string # The currency of the `charge_amount`, formatted as [ISO 4127](http://www.iso.org/iso/home/standards/currency_codes.htm) format. The default value is `USD` and all values allowed from the Pay Connector are accepted.
  --Description: string # The description can be used to provide more details regarding the transaction. This information is submitted along with the payment details to the Payment Connector which are then posted on the transactions.
  --Input: string # A list of inputs that should be accepted. Currently only `dtmf` is supported. All digits captured during a pay session are redacted from the logs.
  --MinPostalCodeLength: int # A positive integer that is used to validate the length of the `PostalCode` inputted by the user. User must enter this many digits.
  --Parameter: any # A single-level JSON object used to pass custom parameters to payment processors. (Required for ACH payments). The information that has to be included here depends on the <Pay> Connector. [Read more](https://www.twilio.com/console/voice/pay-connectors).
  --PaymentConnector: string # This is the unique name corresponding to the Pay Connector installed in the Twilio Add-ons. Learn more about [<Pay> Connectors](https://www.twilio.com/console/voice/pay-connectors). The default value is `Default`.
  --PaymentMethod: string@PaymentMethod-completer # Type of payment being captured. One of `credit-card` or `ach-debit`. The default value is `credit-card`.
  --PostalCode: oneof<nothing, bool> # Indicates whether the credit card postal code (zip code) is a required piece of payment information that must be provided by the caller. The default is `true`.
  --SecurityCode: oneof<nothing, bool> # Indicates whether the credit card security code is a required piece of payment information that must be provided by the caller. The default is `true`.
  --Timeout: int # The number of seconds that <Pay> should wait for the caller to press a digit between each subsequent digit, after the first one, before moving on to validate the digits captured. The default is `5`, maximum is `600`.
  --TokenType: string@TokenType-completer # Indicates whether the payment method should be tokenized as a `one-time`, `reusable`, or `payment-method` token. The default value is `reusable`. Do not enter a charge amount when tokenizing. If a charge amount is entered, the payment method will be charged and not tokenized.
  --ValidCardTypes: string # Credit card types separated by space that Pay should accept. The default value is `visa mastercard amex`
  --RequireMatchingInputs: string # A comma-separated list of payment information fields that require the caller to enter the same value twice for confirmation. Supported values are `payment-card-number`, `expiration-date`, `security-code`, and `postal-code`.
  --Confirmation: string@Confirmation-completer # Whether to prompt the caller to confirm their payment information before submitting to the payment gateway. If `true`, the caller will hear the last 4 digits of their card or account number and must press 1 to confirm or 2 to cancel. Default is `false`.
]: any -> record<account_sid: string, call_sid: string, sid: string, date_created: string, date_updated: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/Payments.json")
  let body = {IdempotencyKey: $IdempotencyKey, StatusCallback: $StatusCallback, BankAccountType: $BankAccountType, ChargeAmount: $ChargeAmount, Currency: $Currency, Description: $Description, Input: $Input, MinPostalCodeLength: $MinPostalCodeLength, Parameter: $Parameter, PaymentConnector: $PaymentConnector, PaymentMethod: $PaymentMethod, PostalCode: $PostalCode, SecurityCode: $SecurityCode, Timeout: $Timeout, TokenType: $TokenType, ValidCardTypes: $ValidCardTypes, RequireMatchingInputs: $RequireMatchingInputs, Confirmation: $Confirmation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# update an instance of payments with different phases of payment flows.
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Payments/{Sid}.json
# operationId: UpdatePayments
export def "2010-04-01-accounts-calls-payments UpdatePayments" [
  AccountSid: string
  CallSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  IdempotencyKey: string # A unique token that will be used to ensure that multiple API calls with the same information do not result in multiple transactions. This should be a unique string value per API call and can be a randomly generated.
  StatusCallback: string # Provide an absolute or relative URL to receive status updates regarding your Pay session. Read more about the [Update](https://www.twilio.com/docs/voice/api/payment-resource#statuscallback-update) and [Complete/Cancel](https://www.twilio.com/docs/voice/api/payment-resource#statuscallback-cancelcomplete) POST requests. (format: uri)
  --Capture: string@Capture-completer # The piece of payment information that you wish the caller to enter. Must be one of `payment-card-number`, `expiration-date`, `security-code`, `postal-code`, `bank-routing-number`, `bank-account-number`, or their `-matcher` variants for input confirmation when `RequireMatchingInputs` is enabled.
  --Status: string@Status-completer-7 # Indicates whether the current payment session should be cancelled or completed. When `cancel` the payment session is cancelled. When `complete`, Twilio sends the payment information to the selected Pay Connector for processing.
]: any -> record<account_sid: string, call_sid: string, sid: string, date_created: string, date_updated: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/Payments/($Sid).json")
  let body = {IdempotencyKey: $IdempotencyKey, StatusCallback: $StatusCallback, Capture: $Capture, Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch an instance of a queue identified by the QueueSid
#
# GET /2010-04-01/Accounts/{AccountSid}/Queues/{Sid}.json
# operationId: FetchQueue
export def "2010-04-01-accounts-queues FetchQueue" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<date_updated: string, current_size: int, friendly_name: string, uri: string, account_sid: string, average_wait_time: int, sid: string, date_created: string, max_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Queues/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the queue with the new parameters
#
# POST /2010-04-01/Accounts/{AccountSid}/Queues/{Sid}.json
# operationId: UpdateQueue
export def "2010-04-01-accounts-queues UpdateQueue" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A descriptive string that you created to describe this resource. It can be up to 64 characters long.
  --MaxSize: int # The maximum number of calls allowed to be in the queue. The default is 1000. The maximum is 5000.
]: any -> record<date_updated: string, current_size: int, friendly_name: string, uri: string, account_sid: string, average_wait_time: int, sid: string, date_created: string, max_size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Queues/($Sid).json")
  let body = {FriendlyName: $FriendlyName, MaxSize: $MaxSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove an empty queue
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Queues/{Sid}.json
# operationId: DeleteQueue
export def "2010-04-01-accounts-queues DeleteQueue" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Queues/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of queues belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Queues.json
# operationId: ListQueue
export def "2010-04-01-accounts-queuesjson ListQueue" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, queues: table<date_updated: string, current_size: int, friendly_name: string, uri: string, account_sid: string, average_wait_time: int, sid: string, date_created: string, max_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Queues.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a queue
#
# POST /2010-04-01/Accounts/{AccountSid}/Queues.json
# operationId: CreateQueue
export def "2010-04-01-accounts-queuesjson CreateQueue" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  FriendlyName: string # A descriptive string that you created to describe this resource. It can be up to 64 characters long.
  --MaxSize: int # The maximum number of calls allowed to be in the queue. The default is 1000. The maximum is 5000.
]: any -> record<date_updated: string, current_size: int, friendly_name: string, uri: string, account_sid: string, average_wait_time: int, sid: string, date_created: string, max_size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Queues.json")
  let body = {FriendlyName: $FriendlyName, MaxSize: $MaxSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a Transcription
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Transcriptions.json
# operationId: CreateRealtimeTranscription
export def "2010-04-01-accounts-calls-transcriptionsjson CreateRealtimeTranscription" [
  AccountSid: string
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Name: string # The user-specified name of this Transcription, if one was given when the Transcription was created. This may be used to stop the Transcription.
  --Track: string@Track-completer # One of `inbound_track`, `outbound_track`, `both_tracks`.
  --StatusCallbackUrl: string # Absolute URL of the status callback. (format: uri)
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The http method for the status_callback (one of GET, POST). (format: http-method)
  --InboundTrackLabel: string # Friendly name given to the Inbound Track
  --OutboundTrackLabel: string # Friendly name given to the Outbound Track
  --PartialResults: oneof<nothing, bool> # Indicates if partial results are going to be sent to the customer
  --LanguageCode: string # Language code used by the transcription engine, specified in [BCP-47](https://www.rfc-editor.org/rfc/bcp/bcp47.txt) format
  --TranscriptionEngine: string # Definition of the transcription engine to be used, among those supported by Twilio
  --ProfanityFilter: oneof<nothing, bool> # indicates if the server will attempt to filter out profanities, replacing all but the initial character in each filtered word with asterisks
  --SpeechModel: string # Recognition model used by the transcription engine, among those supported by the provider
  --Hints: string # A Phrase contains words and phrase "hints" so that the speech recognition engine is more likely to recognize them.
  --EnableAutomaticPunctuation: oneof<nothing, bool> # The provider will add punctuation to recognition result
  --IntelligenceService: string # The SID or unique name of the [Intelligence Service](https://www.twilio.com/docs/conversational-intelligence/api/service-resource) for persisting transcripts and running post-call Language Operators
  --ConversationConfiguration: string # The ID of the Conversations Configuration for customizing conversation behavior in Intelligence Service
  --ConversationId: string # The ID of the Conversation for associating this Transcription with an existing Conversation in Intelligence Service
  --TranscriptionConfigurationId: string # The ID of the RealTimeTranscription Configuration for configuring all the non-default behaviors in one go.
  --EnableProviderData: oneof<nothing, bool> # Whether the callback includes raw provider data.
]: any -> record<sid: string, account_sid: string, call_sid: string, name: string, status: string, date_updated: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/Transcriptions.json")
  let body = {Name: $Name, Track: $Track, StatusCallbackUrl: $StatusCallbackUrl, StatusCallbackMethod: $StatusCallbackMethod, InboundTrackLabel: $InboundTrackLabel, OutboundTrackLabel: $OutboundTrackLabel, PartialResults: $PartialResults, LanguageCode: $LanguageCode, TranscriptionEngine: $TranscriptionEngine, ProfanityFilter: $ProfanityFilter, SpeechModel: $SpeechModel, Hints: $Hints, EnableAutomaticPunctuation: $EnableAutomaticPunctuation, IntelligenceService: $IntelligenceService, ConversationConfiguration: $ConversationConfiguration, ConversationId: $ConversationId, TranscriptionConfigurationId: $TranscriptionConfigurationId, EnableProviderData: $EnableProviderData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Stop a Transcription using either the SID of the Transcription resource or the `name` used when creating the resource
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Transcriptions/{Sid}.json
# operationId: UpdateRealtimeTranscription
export def "2010-04-01-accounts-calls-transcriptions UpdateRealtimeTranscription" [
  AccountSid: string
  CallSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Status: string@Status-completer-8
]: any -> record<sid: string, account_sid: string, call_sid: string, name: string, status: string, date_updated: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/Transcriptions/($Sid).json")
  let body = {Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch an instance of a recording
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{Sid}.json
# operationId: FetchRecording
export def "2010-04-01-accounts-recordings FetchRecording" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --IncludeSoftDeleted: oneof<nothing, bool> # A boolean parameter indicating whether to retrieve soft deleted recordings or not. Recordings metadata are kept after deletion for a retention period of 40 days.
]: nothing -> record<account_sid: string, api_version: string, call_sid: string, conference_sid: string, date_created: string, date_updated: string, start_time: string, duration: string, sid: string, price: string, price_unit: string, status: string, channels: int, source: string, error_code: int, uri: string, encryption_details: any, subresource_uris: record, media_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "IncludeSoftDeleted" $IncludeSoftDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Recordings/($Sid).json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a recording from your account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Recordings/{Sid}.json
# operationId: DeleteRecording
export def "2010-04-01-accounts-recordings DeleteRecording" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Recordings/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of recordings belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings.json
# operationId: ListRecording
export def "2010-04-01-accounts-recordingsjson ListRecording" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --DateCreated: string # Only include recordings that were created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read recordings that were created on this date. You can also specify an inequality, such as `DateCreated<=YYYY-MM-DD`, to read recordings that were created on or before midnight of this date, and `DateCreated>=YYYY-MM-DD` to read recordings that were created on or after midnight of this date. (format: date-time)
  --DateCreated<: string # Only include recordings that were created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read recordings that were created on this date. You can also specify an inequality, such as `DateCreated<=YYYY-MM-DD`, to read recordings that were created on or before midnight of this date, and `DateCreated>=YYYY-MM-DD` to read recordings that were created on or after midnight of this date. (format: date-time)
  --DateCreated>: string # Only include recordings that were created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read recordings that were created on this date. You can also specify an inequality, such as `DateCreated<=YYYY-MM-DD`, to read recordings that were created on or before midnight of this date, and `DateCreated>=YYYY-MM-DD` to read recordings that were created on or after midnight of this date. (format: date-time)
  --CallSid: string # The [Call](https://www.twilio.com/docs/voice/api/call-resource) SID of the resources to read.
  --ConferenceSid: string # The Conference SID that identifies the conference associated with the recording to read.
  --IncludeSoftDeleted: oneof<nothing, bool> # A boolean parameter indicating whether to retrieve soft deleted recordings or not. Recordings metadata are kept after deletion for a retention period of 40 days.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, recordings: table<account_sid: string, api_version: string, call_sid: string, conference_sid: string, date_created: string, date_updated: string, start_time: string, duration: string, sid: string, price: string, price_unit: string, status: string, channels: int, source: string, error_code: int, uri: string, encryption_details: any, subresource_uris: record, media_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "DateCreated" $DateCreated "scalar") (serialize-qp "DateCreated<" $DateCreated< "scalar") (serialize-qp "DateCreated>" $DateCreated> "scalar") (serialize-qp "CallSid" $CallSid "scalar") (serialize-qp "ConferenceSid" $ConferenceSid "scalar") (serialize-qp "IncludeSoftDeleted" $IncludeSoftDeleted "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Recordings.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an instance of an AddOnResult
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{Sid}.json
# operationId: FetchRecordingAddOnResult
export def "2010-04-01-accounts-recordings-add-on-results FetchRecordingAddOnResult" [
  AccountSid: string
  ReferenceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, account_sid: string, status: string, add_on_sid: string, add_on_configuration_sid: string, date_created: string, date_updated: string, date_completed: string, reference_sid: string, subresource_uris: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Recordings/($ReferenceSid)/AddOnResults/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a result and purge all associated Payloads
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{Sid}.json
# operationId: DeleteRecordingAddOnResult
export def "2010-04-01-accounts-recordings-add-on-results DeleteRecordingAddOnResult" [
  AccountSid: string
  ReferenceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Recordings/($ReferenceSid)/AddOnResults/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of results belonging to the recording
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults.json
# operationId: ListRecordingAddOnResult
export def "2010-04-01-accounts-recordings-add-on-resultsjson ListRecordingAddOnResult" [
  AccountSid: string
  ReferenceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, add_on_results: table<sid: string, account_sid: string, status: string, add_on_sid: string, add_on_configuration_sid: string, date_created: string, date_updated: string, date_completed: string, reference_sid: string, subresource_uris: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Recordings/($ReferenceSid)/AddOnResults.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an instance of a result payload
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{AddOnResultSid}/Payloads/{Sid}.json
# operationId: FetchRecordingAddOnResultPayload
export def "2010-04-01-accounts-recordings-add-on-results-payloads FetchRecordingAddOnResultPayload" [
  AccountSid: string
  ReferenceSid: string
  AddOnResultSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, add_on_result_sid: string, account_sid: string, label: string, add_on_sid: string, add_on_configuration_sid: string, content_type: string, date_created: string, date_updated: string, reference_sid: string, subresource_uris: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Recordings/($ReferenceSid)/AddOnResults/($AddOnResultSid)/Payloads/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a payload from the result along with all associated Data
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{AddOnResultSid}/Payloads/{Sid}.json
# operationId: DeleteRecordingAddOnResultPayload
export def "2010-04-01-accounts-recordings-add-on-results-payloads DeleteRecordingAddOnResultPayload" [
  AccountSid: string
  ReferenceSid: string
  AddOnResultSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Recordings/($ReferenceSid)/AddOnResults/($AddOnResultSid)/Payloads/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of payloads belonging to the AddOnResult
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{AddOnResultSid}/Payloads.json
# operationId: ListRecordingAddOnResultPayload
export def "2010-04-01-accounts-recordings-add-on-results-payloadsjson ListRecordingAddOnResultPayload" [
  AccountSid: string
  ReferenceSid: string
  AddOnResultSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, payloads: table<sid: string, add_on_result_sid: string, account_sid: string, label: string, add_on_sid: string, add_on_configuration_sid: string, content_type: string, date_created: string, date_updated: string, reference_sid: string, subresource_uris: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Recordings/($ReferenceSid)/AddOnResults/($AddOnResultSid)/Payloads.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an instance of a result payload
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{AddOnResultSid}/Payloads/{PayloadSid}/Data.json
# operationId: FetchRecordingAddOnResultPayloadData
export def "2010-04-01-accounts-recordings-add-on-results-payloads-datajson FetchRecordingAddOnResultPayloadData" [
  AccountSid: string
  ReferenceSid: string
  AddOnResultSid: string
  PayloadSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Recordings/($ReferenceSid)/AddOnResults/($AddOnResultSid)/Payloads/($PayloadSid)/Data.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{RecordingSid}/Transcriptions/{Sid}.json
#
# operationId: FetchRecordingTranscription
export def "2010-04-01-accounts-recordings-transcriptions FetchRecordingTranscription" [
  AccountSid: string
  RecordingSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, api_version: string, date_created: string, date_updated: string, duration: string, price: float, price_unit: string, recording_sid: string, sid: string, status: string, transcription_text: string, type: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Recordings/($RecordingSid)/Transcriptions/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /2010-04-01/Accounts/{AccountSid}/Recordings/{RecordingSid}/Transcriptions/{Sid}.json
#
# operationId: DeleteRecordingTranscription
export def "2010-04-01-accounts-recordings-transcriptions DeleteRecordingTranscription" [
  AccountSid: string
  RecordingSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Recordings/($RecordingSid)/Transcriptions/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{RecordingSid}/Transcriptions.json
#
# operationId: ListRecordingTranscription
export def "2010-04-01-accounts-recordings-transcriptionsjson ListRecordingTranscription" [
  AccountSid: string
  RecordingSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, transcriptions: table<account_sid: string, api_version: string, date_created: string, date_updated: string, duration: string, price: float, price_unit: string, recording_sid: string, sid: string, status: string, transcription_text: string, type: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Recordings/($RecordingSid)/Transcriptions.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an instance of a short code
#
# GET /2010-04-01/Accounts/{AccountSid}/SMS/ShortCodes/{Sid}.json
# operationId: FetchShortCode
export def "2010-04-01-accounts-sms-short-codes FetchShortCode" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, short_code: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SMS/ShortCodes/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a short code with the following parameters
#
# POST /2010-04-01/Accounts/{AccountSid}/SMS/ShortCodes/{Sid}.json
# operationId: UpdateShortCode
export def "2010-04-01-accounts-sms-short-codes UpdateShortCode" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A descriptive string that you created to describe this resource. It can be up to 64 characters long. By default, the `FriendlyName` is the short code.
  --ApiVersion: string # The API version to use to start a new TwiML session. Can be: `2010-04-01` or `2008-08-01`.
  --SmsUrl: string # The URL we should call when receiving an incoming SMS message to this short code. (format: uri)
  --SmsMethod: string@SmsMethod-completer # The HTTP method we should use when calling the `sms_url`. Can be: `GET` or `POST`. (format: http-method)
  --SmsFallbackUrl: string # The URL that we should call if an error occurs while retrieving or executing the TwiML from `sms_url`. (format: uri)
  --SmsFallbackMethod: string@SmsFallbackMethod-completer # The HTTP method that we should use to call the `sms_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
]: any -> record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, short_code: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SMS/ShortCodes/($Sid).json")
  let body = {FriendlyName: $FriendlyName, ApiVersion: $ApiVersion, SmsUrl: $SmsUrl, SmsMethod: $SmsMethod, SmsFallbackUrl: $SmsFallbackUrl, SmsFallbackMethod: $SmsFallbackMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of short-codes belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SMS/ShortCodes.json
# operationId: ListShortCode
export def "2010-04-01-accounts-sms-short-codesjson ListShortCode" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # The string that identifies the ShortCode resources to read.
  --ShortCode: string # Only show the ShortCode resources that match this pattern. You can specify partial numbers and use '*' as a wildcard for any digit.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, short_codes: table<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, short_code: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "ShortCode" $ShortCode "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SMS/ShortCodes.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/SigningKeys/{Sid}.json
#
# operationId: FetchSigningKey
export def "2010-04-01-accounts-signing-keys FetchSigningKey" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, friendly_name: string, date_created: string, date_updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SigningKeys/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/SigningKeys/{Sid}.json
#
# operationId: UpdateSigningKey
export def "2010-04-01-accounts-signing-keys UpdateSigningKey" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string
]: any -> record<sid: string, friendly_name: string, date_created: string, date_updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SigningKeys/($Sid).json")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /2010-04-01/Accounts/{AccountSid}/SigningKeys/{Sid}.json
#
# operationId: DeleteSigningKey
export def "2010-04-01-accounts-signing-keys DeleteSigningKey" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SigningKeys/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new credential list mapping resource
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/CredentialListMappings.json
# operationId: CreateSipAuthCallsCredentialListMapping
export def "2010-04-01-accounts-sip-domains-auth-calls-credential-list-mappingsjson CreateSipAuthCallsCredentialListMapping" [
  AccountSid: string
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  CredentialListSid: string # The SID of the CredentialList resource to map to the SIP domain.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/Auth/Calls/CredentialListMappings.json")
  let body = {CredentialListSid: $CredentialListSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of credential list mappings belonging to the domain used in the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/CredentialListMappings.json
# operationId: ListSipAuthCallsCredentialListMapping
export def "2010-04-01-accounts-sip-domains-auth-calls-credential-list-mappingsjson ListSipAuthCallsCredentialListMapping" [
  AccountSid: string
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, contents: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/Auth/Calls/CredentialListMappings.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a specific instance of a credential list mapping
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/CredentialListMappings/{Sid}.json
# operationId: FetchSipAuthCallsCredentialListMapping
export def "2010-04-01-accounts-sip-domains-auth-calls-credential-list-mappings FetchSipAuthCallsCredentialListMapping" [
  AccountSid: string
  DomainSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/Auth/Calls/CredentialListMappings/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a credential list mapping from the requested domain
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/CredentialListMappings/{Sid}.json
# operationId: DeleteSipAuthCallsCredentialListMapping
export def "2010-04-01-accounts-sip-domains-auth-calls-credential-list-mappings DeleteSipAuthCallsCredentialListMapping" [
  AccountSid: string
  DomainSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/Auth/Calls/CredentialListMappings/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new IP Access Control List mapping
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/IpAccessControlListMappings.json
# operationId: CreateSipAuthCallsIpAccessControlListMapping
export def "2010-04-01-accounts-sip-domains-auth-calls-ip-access-control-list-mappingsjson CreateSipAuthCallsIpAccessControlListMapping" [
  AccountSid: string
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  IpAccessControlListSid: string # The SID of the IpAccessControlList resource to map to the SIP domain.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/Auth/Calls/IpAccessControlListMappings.json")
  let body = {IpAccessControlListSid: $IpAccessControlListSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of IP Access Control List mappings belonging to the domain used in the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/IpAccessControlListMappings.json
# operationId: ListSipAuthCallsIpAccessControlListMapping
export def "2010-04-01-accounts-sip-domains-auth-calls-ip-access-control-list-mappingsjson ListSipAuthCallsIpAccessControlListMapping" [
  AccountSid: string
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, contents: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/Auth/Calls/IpAccessControlListMappings.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a specific instance of an IP Access Control List mapping
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/IpAccessControlListMappings/{Sid}.json
# operationId: FetchSipAuthCallsIpAccessControlListMapping
export def "2010-04-01-accounts-sip-domains-auth-calls-ip-access-control-list-mappings FetchSipAuthCallsIpAccessControlListMapping" [
  AccountSid: string
  DomainSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/Auth/Calls/IpAccessControlListMappings/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an IP Access Control List mapping from the requested domain
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/IpAccessControlListMappings/{Sid}.json
# operationId: DeleteSipAuthCallsIpAccessControlListMapping
export def "2010-04-01-accounts-sip-domains-auth-calls-ip-access-control-list-mappings DeleteSipAuthCallsIpAccessControlListMapping" [
  AccountSid: string
  DomainSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/Auth/Calls/IpAccessControlListMappings/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new credential list mapping resource
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Registrations/CredentialListMappings.json
# operationId: CreateSipAuthRegistrationsCredentialListMapping
export def "2010-04-01-accounts-sip-domains-auth-registrations-credential-list-mappingsjson CreateSipAuthRegistrationsCredentialListMapping" [
  AccountSid: string
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  CredentialListSid: string # The SID of the CredentialList resource to map to the SIP domain.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/Auth/Registrations/CredentialListMappings.json")
  let body = {CredentialListSid: $CredentialListSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of credential list mappings belonging to the domain used in the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Registrations/CredentialListMappings.json
# operationId: ListSipAuthRegistrationsCredentialListMapping
export def "2010-04-01-accounts-sip-domains-auth-registrations-credential-list-mappingsjson ListSipAuthRegistrationsCredentialListMapping" [
  AccountSid: string
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, contents: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/Auth/Registrations/CredentialListMappings.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a specific instance of a credential list mapping
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Registrations/CredentialListMappings/{Sid}.json
# operationId: FetchSipAuthRegistrationsCredentialListMapping
export def "2010-04-01-accounts-sip-domains-auth-registrations-credential-list-mappings FetchSipAuthRegistrationsCredentialListMapping" [
  AccountSid: string
  DomainSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/Auth/Registrations/CredentialListMappings/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a credential list mapping from the requested domain
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Registrations/CredentialListMappings/{Sid}.json
# operationId: DeleteSipAuthRegistrationsCredentialListMapping
export def "2010-04-01-accounts-sip-domains-auth-registrations-credential-list-mappings DeleteSipAuthRegistrationsCredentialListMapping" [
  AccountSid: string
  DomainSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/Auth/Registrations/CredentialListMappings/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of credentials.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials.json
# operationId: ListSipCredential
export def "2010-04-01-accounts-sip-credential-lists-credentialsjson ListSipCredential" [
  AccountSid: string
  CredentialListSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, credentials: table<sid: string, account_sid: string, credential_list_sid: string, username: string, date_created: string, date_updated: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/CredentialLists/($CredentialListSid)/Credentials.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new credential resource.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials.json
# operationId: CreateSipCredential
export def "2010-04-01-accounts-sip-credential-lists-credentialsjson CreateSipCredential" [
  AccountSid: string
  CredentialListSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Username: string # The username that will be passed when authenticating SIP requests. The username should be sent in response to Twilio's challenge of the initial INVITE. It can be up to 32 characters long.
  Password: string # The password that the username will use when authenticating SIP requests. The password must be a minimum of 12 characters, contain at least 1 digit, and have mixed case. (eg `IWasAtSignal2018`)
]: any -> record<sid: string, account_sid: string, credential_list_sid: string, username: string, date_created: string, date_updated: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/CredentialLists/($CredentialListSid)/Credentials.json")
  let body = {Username: $Username, Password: $Password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch a single credential.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials/{Sid}.json
# operationId: FetchSipCredential
export def "2010-04-01-accounts-sip-credential-lists-credentials FetchSipCredential" [
  AccountSid: string
  CredentialListSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, account_sid: string, credential_list_sid: string, username: string, date_created: string, date_updated: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/CredentialLists/($CredentialListSid)/Credentials/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a credential resource.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials/{Sid}.json
# operationId: UpdateSipCredential
export def "2010-04-01-accounts-sip-credential-lists-credentials UpdateSipCredential" [
  AccountSid: string
  CredentialListSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Password: string # The password that the username will use when authenticating SIP requests. The password must be a minimum of 12 characters, contain at least 1 digit, and have mixed case. (eg `IWasAtSignal2018`)
]: any -> record<sid: string, account_sid: string, credential_list_sid: string, username: string, date_created: string, date_updated: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/CredentialLists/($CredentialListSid)/Credentials/($Sid).json")
  let body = {Password: $Password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a credential resource.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials/{Sid}.json
# operationId: DeleteSipCredential
export def "2010-04-01-accounts-sip-credential-lists-credentials DeleteSipCredential" [
  AccountSid: string
  CredentialListSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/CredentialLists/($CredentialListSid)/Credentials/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Credential Lists
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists.json
# operationId: ListSipCredentialList
export def "2010-04-01-accounts-sip-credential-listsjson ListSipCredentialList" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, credential_lists: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/CredentialLists.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Credential List
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists.json
# operationId: CreateSipCredentialList
export def "2010-04-01-accounts-sip-credential-listsjson CreateSipCredentialList" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  FriendlyName: string # A human readable descriptive text that describes the CredentialList, up to 64 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/CredentialLists.json")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a Credential List
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{Sid}.json
# operationId: FetchSipCredentialList
export def "2010-04-01-accounts-sip-credential-lists FetchSipCredentialList" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/CredentialLists/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Credential List
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{Sid}.json
# operationId: UpdateSipCredentialList
export def "2010-04-01-accounts-sip-credential-lists UpdateSipCredentialList" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  FriendlyName: string # A human readable descriptive text for a CredentialList, up to 64 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/CredentialLists/($Sid).json")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a Credential List
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{Sid}.json
# operationId: DeleteSipCredentialList
export def "2010-04-01-accounts-sip-credential-lists DeleteSipCredentialList" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/CredentialLists/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a CredentialListMapping resource for an account.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/CredentialListMappings.json
# operationId: CreateSipCredentialListMapping
export def "2010-04-01-accounts-sip-domains-credential-list-mappingsjson CreateSipCredentialListMapping" [
  AccountSid: string
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  CredentialListSid: string # A 34 character string that uniquely identifies the CredentialList resource to map to the SIP domain.
]: any -> record<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/CredentialListMappings.json")
  let body = {CredentialListSid: $CredentialListSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Read multiple CredentialListMapping resources from an account.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/CredentialListMappings.json
# operationId: ListSipCredentialListMapping
export def "2010-04-01-accounts-sip-domains-credential-list-mappingsjson ListSipCredentialListMapping" [
  AccountSid: string
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, credential_list_mappings: table<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/CredentialListMappings.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a single CredentialListMapping resource from an account.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/CredentialListMappings/{Sid}.json
# operationId: FetchSipCredentialListMapping
export def "2010-04-01-accounts-sip-domains-credential-list-mappings FetchSipCredentialListMapping" [
  AccountSid: string
  DomainSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/CredentialListMappings/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a CredentialListMapping resource from an account.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/CredentialListMappings/{Sid}.json
# operationId: DeleteSipCredentialListMapping
export def "2010-04-01-accounts-sip-domains-credential-list-mappings DeleteSipCredentialListMapping" [
  AccountSid: string
  DomainSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/CredentialListMappings/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of domains belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains.json
# operationId: ListSipDomain
export def "2010-04-01-accounts-sip-domainsjson ListSipDomain" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, domains: table<account_sid: string, api_version: string, auth_type: string, date_created: string, date_updated: string, domain_name: string, friendly_name: string, sid: string, uri: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_status_callback_method: string, voice_status_callback_url: string, voice_url: string, subresource_uris: record, sip_registration: bool, emergency_calling_enabled: bool, secure: bool, byoc_trunk_sid: string, emergency_caller_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Domain
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains.json
# operationId: CreateSipDomain
export def "2010-04-01-accounts-sip-domainsjson CreateSipDomain" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  DomainName: string # The unique address you reserve on Twilio to which you route your SIP traffic. Domain names can contain letters, digits, and "-" and must end with `sip.twilio.com`.
  --FriendlyName: string # A descriptive string that you created to describe the resource. It can be up to 64 characters long.
  --VoiceUrl: string # The URL we should when the domain receives a call. (format: uri)
  --VoiceMethod: string@VoiceMethod-completer # The HTTP method we should use to call `voice_url`. Can be: `GET` or `POST`. (format: http-method)
  --VoiceFallbackUrl: string # The URL that we should call when an error occurs while retrieving or executing the TwiML from `voice_url`. (format: uri)
  --VoiceFallbackMethod: string@VoiceFallbackMethod-completer # The HTTP method we should use to call `voice_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --VoiceStatusCallbackUrl: string # The URL that we should call to pass status parameters (such as call ended) to your application. (format: uri)
  --VoiceStatusCallbackMethod: string@VoiceStatusCallbackMethod-completer # The HTTP method we should use to call `voice_status_callback_url`. Can be: `GET` or `POST`. (format: http-method)
  --SipRegistration: oneof<nothing, bool> # Whether to allow SIP Endpoints to register with the domain to receive calls. Can be `true` or `false`. `true` allows SIP Endpoints to register with the domain to receive calls, `false` does not.
  --EmergencyCallingEnabled: oneof<nothing, bool> # Whether emergency calling is enabled for the domain. If enabled, allows emergency calls on the domain from phone numbers with validated addresses.
  --Secure: oneof<nothing, bool> # Whether secure SIP is enabled for the domain. If enabled, TLS will be enforced and SRTP will be negotiated on all incoming calls to this sip domain.
  --ByocTrunkSid: string # The SID of the BYOC Trunk(Bring Your Own Carrier) resource that the Sip Domain will be associated with.
  --EmergencyCallerSid: string # Whether an emergency caller sid is configured for the domain. If present, this phone number will be used as the callback for the emergency call.
]: any -> record<account_sid: string, api_version: string, auth_type: string, date_created: string, date_updated: string, domain_name: string, friendly_name: string, sid: string, uri: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_status_callback_method: string, voice_status_callback_url: string, voice_url: string, subresource_uris: record, sip_registration: bool, emergency_calling_enabled: bool, secure: bool, byoc_trunk_sid: string, emergency_caller_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains.json")
  let body = {DomainName: $DomainName, FriendlyName: $FriendlyName, VoiceUrl: $VoiceUrl, VoiceMethod: $VoiceMethod, VoiceFallbackUrl: $VoiceFallbackUrl, VoiceFallbackMethod: $VoiceFallbackMethod, VoiceStatusCallbackUrl: $VoiceStatusCallbackUrl, VoiceStatusCallbackMethod: $VoiceStatusCallbackMethod, SipRegistration: $SipRegistration, EmergencyCallingEnabled: $EmergencyCallingEnabled, Secure: $Secure, ByocTrunkSid: $ByocTrunkSid, EmergencyCallerSid: $EmergencyCallerSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch an instance of a Domain
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{Sid}.json
# operationId: FetchSipDomain
export def "2010-04-01-accounts-sip-domains FetchSipDomain" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, api_version: string, auth_type: string, date_created: string, date_updated: string, domain_name: string, friendly_name: string, sid: string, uri: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_status_callback_method: string, voice_status_callback_url: string, voice_url: string, subresource_uris: record, sip_registration: bool, emergency_calling_enabled: bool, secure: bool, byoc_trunk_sid: string, emergency_caller_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the attributes of a domain
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{Sid}.json
# operationId: UpdateSipDomain
export def "2010-04-01-accounts-sip-domains UpdateSipDomain" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A descriptive string that you created to describe the resource. It can be up to 64 characters long.
  --VoiceFallbackMethod: string@VoiceFallbackMethod-completer # The HTTP method we should use to call `voice_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --VoiceFallbackUrl: string # The URL that we should call when an error occurs while retrieving or executing the TwiML requested by `voice_url`. (format: uri)
  --VoiceMethod: string@VoiceMethod-completer # The HTTP method we should use to call `voice_url` (format: http-method)
  --VoiceStatusCallbackMethod: string@VoiceStatusCallbackMethod-completer # The HTTP method we should use to call `voice_status_callback_url`. Can be: `GET` or `POST`. (format: http-method)
  --VoiceStatusCallbackUrl: string # The URL that we should call to pass status parameters (such as call ended) to your application. (format: uri)
  --VoiceUrl: string # The URL we should call when the domain receives a call. (format: uri)
  --SipRegistration: oneof<nothing, bool> # Whether to allow SIP Endpoints to register with the domain to receive calls. Can be `true` or `false`. `true` allows SIP Endpoints to register with the domain to receive calls, `false` does not.
  --DomainName: string # The unique address you reserve on Twilio to which you route your SIP traffic. Domain names can contain letters, digits, and "-" and must end with `sip.twilio.com`.
  --EmergencyCallingEnabled: oneof<nothing, bool> # Whether emergency calling is enabled for the domain. If enabled, allows emergency calls on the domain from phone numbers with validated addresses.
  --Secure: oneof<nothing, bool> # Whether secure SIP is enabled for the domain. If enabled, TLS will be enforced and SRTP will be negotiated on all incoming calls to this sip domain.
  --ByocTrunkSid: string # The SID of the BYOC Trunk(Bring Your Own Carrier) resource that the Sip Domain will be associated with.
  --EmergencyCallerSid: string # Whether an emergency caller sid is configured for the domain. If present, this phone number will be used as the callback for the emergency call.
]: any -> record<account_sid: string, api_version: string, auth_type: string, date_created: string, date_updated: string, domain_name: string, friendly_name: string, sid: string, uri: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_status_callback_method: string, voice_status_callback_url: string, voice_url: string, subresource_uris: record, sip_registration: bool, emergency_calling_enabled: bool, secure: bool, byoc_trunk_sid: string, emergency_caller_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($Sid).json")
  let body = {FriendlyName: $FriendlyName, VoiceFallbackMethod: $VoiceFallbackMethod, VoiceFallbackUrl: $VoiceFallbackUrl, VoiceMethod: $VoiceMethod, VoiceStatusCallbackMethod: $VoiceStatusCallbackMethod, VoiceStatusCallbackUrl: $VoiceStatusCallbackUrl, VoiceUrl: $VoiceUrl, SipRegistration: $SipRegistration, DomainName: $DomainName, EmergencyCallingEnabled: $EmergencyCallingEnabled, Secure: $Secure, ByocTrunkSid: $ByocTrunkSid, EmergencyCallerSid: $EmergencyCallerSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete an instance of a Domain
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{Sid}.json
# operationId: DeleteSipDomain
export def "2010-04-01-accounts-sip-domains DeleteSipDomain" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of IpAccessControlLists that belong to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists.json
# operationId: ListSipIpAccessControlList
export def "2010-04-01-accounts-sip-ip-access-control-listsjson ListSipIpAccessControlList" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, ip_access_control_lists: table<sid: string, account_sid: string, friendly_name: string, date_created: string, date_updated: string, subresource_uris: record, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/IpAccessControlLists.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new IpAccessControlList resource
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists.json
# operationId: CreateSipIpAccessControlList
export def "2010-04-01-accounts-sip-ip-access-control-listsjson CreateSipIpAccessControlList" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  FriendlyName: string # A human readable descriptive text that describes the IpAccessControlList, up to 255 characters long.
]: any -> record<sid: string, account_sid: string, friendly_name: string, date_created: string, date_updated: string, subresource_uris: record, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/IpAccessControlLists.json")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch a specific instance of an IpAccessControlList
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{Sid}.json
# operationId: FetchSipIpAccessControlList
export def "2010-04-01-accounts-sip-ip-access-control-lists FetchSipIpAccessControlList" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, account_sid: string, friendly_name: string, date_created: string, date_updated: string, subresource_uris: record, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/IpAccessControlLists/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rename an IpAccessControlList
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{Sid}.json
# operationId: UpdateSipIpAccessControlList
export def "2010-04-01-accounts-sip-ip-access-control-lists UpdateSipIpAccessControlList" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  FriendlyName: string # A human readable descriptive text, up to 255 characters long.
]: any -> record<sid: string, account_sid: string, friendly_name: string, date_created: string, date_updated: string, subresource_uris: record, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/IpAccessControlLists/($Sid).json")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete an IpAccessControlList from the requested account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{Sid}.json
# operationId: DeleteSipIpAccessControlList
export def "2010-04-01-accounts-sip-ip-access-control-lists DeleteSipIpAccessControlList" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/IpAccessControlLists/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an IpAccessControlListMapping resource.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/IpAccessControlListMappings/{Sid}.json
# operationId: FetchSipIpAccessControlListMapping
export def "2010-04-01-accounts-sip-domains-ip-access-control-list-mappings FetchSipIpAccessControlListMapping" [
  AccountSid: string
  DomainSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/IpAccessControlListMappings/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an IpAccessControlListMapping resource.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/IpAccessControlListMappings/{Sid}.json
# operationId: DeleteSipIpAccessControlListMapping
export def "2010-04-01-accounts-sip-domains-ip-access-control-list-mappings DeleteSipIpAccessControlListMapping" [
  AccountSid: string
  DomainSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/IpAccessControlListMappings/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new IpAccessControlListMapping resource.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/IpAccessControlListMappings.json
# operationId: CreateSipIpAccessControlListMapping
export def "2010-04-01-accounts-sip-domains-ip-access-control-list-mappingsjson CreateSipIpAccessControlListMapping" [
  AccountSid: string
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  IpAccessControlListSid: string # The unique id of the IP access control list to map to the SIP domain.
]: any -> record<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/IpAccessControlListMappings.json")
  let body = {IpAccessControlListSid: $IpAccessControlListSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of IpAccessControlListMapping resources.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/IpAccessControlListMappings.json
# operationId: ListSipIpAccessControlListMapping
export def "2010-04-01-accounts-sip-domains-ip-access-control-list-mappingsjson ListSipIpAccessControlListMapping" [
  AccountSid: string
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, ip_access_control_list_mappings: table<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/Domains/($DomainSid)/IpAccessControlListMappings.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read multiple IpAddress resources.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses.json
# operationId: ListSipIpAddress
export def "2010-04-01-accounts-sip-ip-access-control-lists-ip-addressesjson ListSipIpAddress" [
  AccountSid: string
  IpAccessControlListSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, ip_addresses: table<sid: string, account_sid: string, friendly_name: string, ip_address: string, cidr_prefix_length: int, ip_access_control_list_sid: string, date_created: string, date_updated: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/IpAccessControlLists/($IpAccessControlListSid)/IpAddresses.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new IpAddress resource.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses.json
# operationId: CreateSipIpAddress
export def "2010-04-01-accounts-sip-ip-access-control-lists-ip-addressesjson CreateSipIpAddress" [
  AccountSid: string
  IpAccessControlListSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  FriendlyName: string # A human readable descriptive text for this resource, up to 255 characters long.
  IpAddress: string # An IP address in dotted decimal notation from which you want to accept traffic. Any SIP requests from this IP address will be allowed by Twilio. IPv4 only supported today.
  --CidrPrefixLength: int # An integer representing the length of the CIDR prefix to use with this IP address when accepting traffic. By default the entire IP address is used.
]: any -> record<sid: string, account_sid: string, friendly_name: string, ip_address: string, cidr_prefix_length: int, ip_access_control_list_sid: string, date_created: string, date_updated: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/IpAccessControlLists/($IpAccessControlListSid)/IpAddresses.json")
  let body = {FriendlyName: $FriendlyName, IpAddress: $IpAddress, CidrPrefixLength: $CidrPrefixLength} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Read one IpAddress resource.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses/{Sid}.json
# operationId: FetchSipIpAddress
export def "2010-04-01-accounts-sip-ip-access-control-lists-ip-addresses FetchSipIpAddress" [
  AccountSid: string
  IpAccessControlListSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, account_sid: string, friendly_name: string, ip_address: string, cidr_prefix_length: int, ip_access_control_list_sid: string, date_created: string, date_updated: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/IpAccessControlLists/($IpAccessControlListSid)/IpAddresses/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an IpAddress resource.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses/{Sid}.json
# operationId: UpdateSipIpAddress
export def "2010-04-01-accounts-sip-ip-access-control-lists-ip-addresses UpdateSipIpAddress" [
  AccountSid: string
  IpAccessControlListSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --IpAddress: string # An IP address in dotted decimal notation from which you want to accept traffic. Any SIP requests from this IP address will be allowed by Twilio. IPv4 only supported today.
  --FriendlyName: string # A human readable descriptive text for this resource, up to 255 characters long.
  --CidrPrefixLength: int # An integer representing the length of the CIDR prefix to use with this IP address when accepting traffic. By default the entire IP address is used.
]: any -> record<sid: string, account_sid: string, friendly_name: string, ip_address: string, cidr_prefix_length: int, ip_access_control_list_sid: string, date_created: string, date_updated: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/IpAccessControlLists/($IpAccessControlListSid)/IpAddresses/($Sid).json")
  let body = {IpAddress: $IpAddress, FriendlyName: $FriendlyName, CidrPrefixLength: $CidrPrefixLength} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete an IpAddress resource.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses/{Sid}.json
# operationId: DeleteSipIpAddress
export def "2010-04-01-accounts-sip-ip-access-control-lists-ip-addresses DeleteSipIpAddress" [
  AccountSid: string
  IpAccessControlListSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/SIP/IpAccessControlLists/($IpAccessControlListSid)/IpAddresses/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Siprec
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Siprec.json
# operationId: CreateSiprec
export def "2010-04-01-accounts-calls-siprecjson CreateSiprec" [
  AccountSid: string
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Name: string # The user-specified name of this Siprec, if one was given when the Siprec was created. This may be used to stop the Siprec.
  --ConnectorName: string # Unique name used when configuring the connector via Marketplace Add-on.
  --Track: string@Track-completer # One of `inbound_track`, `outbound_track`, `both_tracks`.
  --StatusCallback: string # Absolute URL of the status callback. (format: uri)
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The http method for the status_callback (one of GET, POST). (format: http-method)
  --Parameter1Name: string # Parameter name
  --Parameter1Value: string # Parameter value
  --Parameter2Name: string # Parameter name
  --Parameter2Value: string # Parameter value
  --Parameter3Name: string # Parameter name
  --Parameter3Value: string # Parameter value
  --Parameter4Name: string # Parameter name
  --Parameter4Value: string # Parameter value
  --Parameter5Name: string # Parameter name
  --Parameter5Value: string # Parameter value
  --Parameter6Name: string # Parameter name
  --Parameter6Value: string # Parameter value
  --Parameter7Name: string # Parameter name
  --Parameter7Value: string # Parameter value
  --Parameter8Name: string # Parameter name
  --Parameter8Value: string # Parameter value
  --Parameter9Name: string # Parameter name
  --Parameter9Value: string # Parameter value
  --Parameter10Name: string # Parameter name
  --Parameter10Value: string # Parameter value
  --Parameter11Name: string # Parameter name
  --Parameter11Value: string # Parameter value
  --Parameter12Name: string # Parameter name
  --Parameter12Value: string # Parameter value
  --Parameter13Name: string # Parameter name
  --Parameter13Value: string # Parameter value
  --Parameter14Name: string # Parameter name
  --Parameter14Value: string # Parameter value
  --Parameter15Name: string # Parameter name
  --Parameter15Value: string # Parameter value
  --Parameter16Name: string # Parameter name
  --Parameter16Value: string # Parameter value
  --Parameter17Name: string # Parameter name
  --Parameter17Value: string # Parameter value
  --Parameter18Name: string # Parameter name
  --Parameter18Value: string # Parameter value
  --Parameter19Name: string # Parameter name
  --Parameter19Value: string # Parameter value
  --Parameter20Name: string # Parameter name
  --Parameter20Value: string # Parameter value
  --Parameter21Name: string # Parameter name
  --Parameter21Value: string # Parameter value
  --Parameter22Name: string # Parameter name
  --Parameter22Value: string # Parameter value
  --Parameter23Name: string # Parameter name
  --Parameter23Value: string # Parameter value
  --Parameter24Name: string # Parameter name
  --Parameter24Value: string # Parameter value
  --Parameter25Name: string # Parameter name
  --Parameter25Value: string # Parameter value
  --Parameter26Name: string # Parameter name
  --Parameter26Value: string # Parameter value
  --Parameter27Name: string # Parameter name
  --Parameter27Value: string # Parameter value
  --Parameter28Name: string # Parameter name
  --Parameter28Value: string # Parameter value
  --Parameter29Name: string # Parameter name
  --Parameter29Value: string # Parameter value
  --Parameter30Name: string # Parameter name
  --Parameter30Value: string # Parameter value
  --Parameter31Name: string # Parameter name
  --Parameter31Value: string # Parameter value
  --Parameter32Name: string # Parameter name
  --Parameter32Value: string # Parameter value
  --Parameter33Name: string # Parameter name
  --Parameter33Value: string # Parameter value
  --Parameter34Name: string # Parameter name
  --Parameter34Value: string # Parameter value
  --Parameter35Name: string # Parameter name
  --Parameter35Value: string # Parameter value
  --Parameter36Name: string # Parameter name
  --Parameter36Value: string # Parameter value
  --Parameter37Name: string # Parameter name
  --Parameter37Value: string # Parameter value
  --Parameter38Name: string # Parameter name
  --Parameter38Value: string # Parameter value
  --Parameter39Name: string # Parameter name
  --Parameter39Value: string # Parameter value
  --Parameter40Name: string # Parameter name
  --Parameter40Value: string # Parameter value
  --Parameter41Name: string # Parameter name
  --Parameter41Value: string # Parameter value
  --Parameter42Name: string # Parameter name
  --Parameter42Value: string # Parameter value
  --Parameter43Name: string # Parameter name
  --Parameter43Value: string # Parameter value
  --Parameter44Name: string # Parameter name
  --Parameter44Value: string # Parameter value
  --Parameter45Name: string # Parameter name
  --Parameter45Value: string # Parameter value
  --Parameter46Name: string # Parameter name
  --Parameter46Value: string # Parameter value
  --Parameter47Name: string # Parameter name
  --Parameter47Value: string # Parameter value
  --Parameter48Name: string # Parameter name
  --Parameter48Value: string # Parameter value
  --Parameter49Name: string # Parameter name
  --Parameter49Value: string # Parameter value
  --Parameter50Name: string # Parameter name
  --Parameter50Value: string # Parameter value
  --Parameter51Name: string # Parameter name
  --Parameter51Value: string # Parameter value
  --Parameter52Name: string # Parameter name
  --Parameter52Value: string # Parameter value
  --Parameter53Name: string # Parameter name
  --Parameter53Value: string # Parameter value
  --Parameter54Name: string # Parameter name
  --Parameter54Value: string # Parameter value
  --Parameter55Name: string # Parameter name
  --Parameter55Value: string # Parameter value
  --Parameter56Name: string # Parameter name
  --Parameter56Value: string # Parameter value
  --Parameter57Name: string # Parameter name
  --Parameter57Value: string # Parameter value
  --Parameter58Name: string # Parameter name
  --Parameter58Value: string # Parameter value
  --Parameter59Name: string # Parameter name
  --Parameter59Value: string # Parameter value
  --Parameter60Name: string # Parameter name
  --Parameter60Value: string # Parameter value
  --Parameter61Name: string # Parameter name
  --Parameter61Value: string # Parameter value
  --Parameter62Name: string # Parameter name
  --Parameter62Value: string # Parameter value
  --Parameter63Name: string # Parameter name
  --Parameter63Value: string # Parameter value
  --Parameter64Name: string # Parameter name
  --Parameter64Value: string # Parameter value
  --Parameter65Name: string # Parameter name
  --Parameter65Value: string # Parameter value
  --Parameter66Name: string # Parameter name
  --Parameter66Value: string # Parameter value
  --Parameter67Name: string # Parameter name
  --Parameter67Value: string # Parameter value
  --Parameter68Name: string # Parameter name
  --Parameter68Value: string # Parameter value
  --Parameter69Name: string # Parameter name
  --Parameter69Value: string # Parameter value
  --Parameter70Name: string # Parameter name
  --Parameter70Value: string # Parameter value
  --Parameter71Name: string # Parameter name
  --Parameter71Value: string # Parameter value
  --Parameter72Name: string # Parameter name
  --Parameter72Value: string # Parameter value
  --Parameter73Name: string # Parameter name
  --Parameter73Value: string # Parameter value
  --Parameter74Name: string # Parameter name
  --Parameter74Value: string # Parameter value
  --Parameter75Name: string # Parameter name
  --Parameter75Value: string # Parameter value
  --Parameter76Name: string # Parameter name
  --Parameter76Value: string # Parameter value
  --Parameter77Name: string # Parameter name
  --Parameter77Value: string # Parameter value
  --Parameter78Name: string # Parameter name
  --Parameter78Value: string # Parameter value
  --Parameter79Name: string # Parameter name
  --Parameter79Value: string # Parameter value
  --Parameter80Name: string # Parameter name
  --Parameter80Value: string # Parameter value
  --Parameter81Name: string # Parameter name
  --Parameter81Value: string # Parameter value
  --Parameter82Name: string # Parameter name
  --Parameter82Value: string # Parameter value
  --Parameter83Name: string # Parameter name
  --Parameter83Value: string # Parameter value
  --Parameter84Name: string # Parameter name
  --Parameter84Value: string # Parameter value
  --Parameter85Name: string # Parameter name
  --Parameter85Value: string # Parameter value
  --Parameter86Name: string # Parameter name
  --Parameter86Value: string # Parameter value
  --Parameter87Name: string # Parameter name
  --Parameter87Value: string # Parameter value
  --Parameter88Name: string # Parameter name
  --Parameter88Value: string # Parameter value
  --Parameter89Name: string # Parameter name
  --Parameter89Value: string # Parameter value
  --Parameter90Name: string # Parameter name
  --Parameter90Value: string # Parameter value
  --Parameter91Name: string # Parameter name
  --Parameter91Value: string # Parameter value
  --Parameter92Name: string # Parameter name
  --Parameter92Value: string # Parameter value
  --Parameter93Name: string # Parameter name
  --Parameter93Value: string # Parameter value
  --Parameter94Name: string # Parameter name
  --Parameter94Value: string # Parameter value
  --Parameter95Name: string # Parameter name
  --Parameter95Value: string # Parameter value
  --Parameter96Name: string # Parameter name
  --Parameter96Value: string # Parameter value
  --Parameter97Name: string # Parameter name
  --Parameter97Value: string # Parameter value
  --Parameter98Name: string # Parameter name
  --Parameter98Value: string # Parameter value
  --Parameter99Name: string # Parameter name
  --Parameter99Value: string # Parameter value
]: any -> record<sid: string, account_sid: string, call_sid: string, name: string, status: string, date_updated: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/Siprec.json")
  let body = {Name: $Name, ConnectorName: $ConnectorName, Track: $Track, StatusCallback: $StatusCallback, StatusCallbackMethod: $StatusCallbackMethod, Parameter1.Name: $Parameter1Name, Parameter1.Value: $Parameter1Value, Parameter2.Name: $Parameter2Name, Parameter2.Value: $Parameter2Value, Parameter3.Name: $Parameter3Name, Parameter3.Value: $Parameter3Value, Parameter4.Name: $Parameter4Name, Parameter4.Value: $Parameter4Value, Parameter5.Name: $Parameter5Name, Parameter5.Value: $Parameter5Value, Parameter6.Name: $Parameter6Name, Parameter6.Value: $Parameter6Value, Parameter7.Name: $Parameter7Name, Parameter7.Value: $Parameter7Value, Parameter8.Name: $Parameter8Name, Parameter8.Value: $Parameter8Value, Parameter9.Name: $Parameter9Name, Parameter9.Value: $Parameter9Value, Parameter10.Name: $Parameter10Name, Parameter10.Value: $Parameter10Value, Parameter11.Name: $Parameter11Name, Parameter11.Value: $Parameter11Value, Parameter12.Name: $Parameter12Name, Parameter12.Value: $Parameter12Value, Parameter13.Name: $Parameter13Name, Parameter13.Value: $Parameter13Value, Parameter14.Name: $Parameter14Name, Parameter14.Value: $Parameter14Value, Parameter15.Name: $Parameter15Name, Parameter15.Value: $Parameter15Value, Parameter16.Name: $Parameter16Name, Parameter16.Value: $Parameter16Value, Parameter17.Name: $Parameter17Name, Parameter17.Value: $Parameter17Value, Parameter18.Name: $Parameter18Name, Parameter18.Value: $Parameter18Value, Parameter19.Name: $Parameter19Name, Parameter19.Value: $Parameter19Value, Parameter20.Name: $Parameter20Name, Parameter20.Value: $Parameter20Value, Parameter21.Name: $Parameter21Name, Parameter21.Value: $Parameter21Value, Parameter22.Name: $Parameter22Name, Parameter22.Value: $Parameter22Value, Parameter23.Name: $Parameter23Name, Parameter23.Value: $Parameter23Value, Parameter24.Name: $Parameter24Name, Parameter24.Value: $Parameter24Value, Parameter25.Name: $Parameter25Name, Parameter25.Value: $Parameter25Value, Parameter26.Name: $Parameter26Name, Parameter26.Value: $Parameter26Value, Parameter27.Name: $Parameter27Name, Parameter27.Value: $Parameter27Value, Parameter28.Name: $Parameter28Name, Parameter28.Value: $Parameter28Value, Parameter29.Name: $Parameter29Name, Parameter29.Value: $Parameter29Value, Parameter30.Name: $Parameter30Name, Parameter30.Value: $Parameter30Value, Parameter31.Name: $Parameter31Name, Parameter31.Value: $Parameter31Value, Parameter32.Name: $Parameter32Name, Parameter32.Value: $Parameter32Value, Parameter33.Name: $Parameter33Name, Parameter33.Value: $Parameter33Value, Parameter34.Name: $Parameter34Name, Parameter34.Value: $Parameter34Value, Parameter35.Name: $Parameter35Name, Parameter35.Value: $Parameter35Value, Parameter36.Name: $Parameter36Name, Parameter36.Value: $Parameter36Value, Parameter37.Name: $Parameter37Name, Parameter37.Value: $Parameter37Value, Parameter38.Name: $Parameter38Name, Parameter38.Value: $Parameter38Value, Parameter39.Name: $Parameter39Name, Parameter39.Value: $Parameter39Value, Parameter40.Name: $Parameter40Name, Parameter40.Value: $Parameter40Value, Parameter41.Name: $Parameter41Name, Parameter41.Value: $Parameter41Value, Parameter42.Name: $Parameter42Name, Parameter42.Value: $Parameter42Value, Parameter43.Name: $Parameter43Name, Parameter43.Value: $Parameter43Value, Parameter44.Name: $Parameter44Name, Parameter44.Value: $Parameter44Value, Parameter45.Name: $Parameter45Name, Parameter45.Value: $Parameter45Value, Parameter46.Name: $Parameter46Name, Parameter46.Value: $Parameter46Value, Parameter47.Name: $Parameter47Name, Parameter47.Value: $Parameter47Value, Parameter48.Name: $Parameter48Name, Parameter48.Value: $Parameter48Value, Parameter49.Name: $Parameter49Name, Parameter49.Value: $Parameter49Value, Parameter50.Name: $Parameter50Name, Parameter50.Value: $Parameter50Value, Parameter51.Name: $Parameter51Name, Parameter51.Value: $Parameter51Value, Parameter52.Name: $Parameter52Name, Parameter52.Value: $Parameter52Value, Parameter53.Name: $Parameter53Name, Parameter53.Value: $Parameter53Value, Parameter54.Name: $Parameter54Name, Parameter54.Value: $Parameter54Value, Parameter55.Name: $Parameter55Name, Parameter55.Value: $Parameter55Value, Parameter56.Name: $Parameter56Name, Parameter56.Value: $Parameter56Value, Parameter57.Name: $Parameter57Name, Parameter57.Value: $Parameter57Value, Parameter58.Name: $Parameter58Name, Parameter58.Value: $Parameter58Value, Parameter59.Name: $Parameter59Name, Parameter59.Value: $Parameter59Value, Parameter60.Name: $Parameter60Name, Parameter60.Value: $Parameter60Value, Parameter61.Name: $Parameter61Name, Parameter61.Value: $Parameter61Value, Parameter62.Name: $Parameter62Name, Parameter62.Value: $Parameter62Value, Parameter63.Name: $Parameter63Name, Parameter63.Value: $Parameter63Value, Parameter64.Name: $Parameter64Name, Parameter64.Value: $Parameter64Value, Parameter65.Name: $Parameter65Name, Parameter65.Value: $Parameter65Value, Parameter66.Name: $Parameter66Name, Parameter66.Value: $Parameter66Value, Parameter67.Name: $Parameter67Name, Parameter67.Value: $Parameter67Value, Parameter68.Name: $Parameter68Name, Parameter68.Value: $Parameter68Value, Parameter69.Name: $Parameter69Name, Parameter69.Value: $Parameter69Value, Parameter70.Name: $Parameter70Name, Parameter70.Value: $Parameter70Value, Parameter71.Name: $Parameter71Name, Parameter71.Value: $Parameter71Value, Parameter72.Name: $Parameter72Name, Parameter72.Value: $Parameter72Value, Parameter73.Name: $Parameter73Name, Parameter73.Value: $Parameter73Value, Parameter74.Name: $Parameter74Name, Parameter74.Value: $Parameter74Value, Parameter75.Name: $Parameter75Name, Parameter75.Value: $Parameter75Value, Parameter76.Name: $Parameter76Name, Parameter76.Value: $Parameter76Value, Parameter77.Name: $Parameter77Name, Parameter77.Value: $Parameter77Value, Parameter78.Name: $Parameter78Name, Parameter78.Value: $Parameter78Value, Parameter79.Name: $Parameter79Name, Parameter79.Value: $Parameter79Value, Parameter80.Name: $Parameter80Name, Parameter80.Value: $Parameter80Value, Parameter81.Name: $Parameter81Name, Parameter81.Value: $Parameter81Value, Parameter82.Name: $Parameter82Name, Parameter82.Value: $Parameter82Value, Parameter83.Name: $Parameter83Name, Parameter83.Value: $Parameter83Value, Parameter84.Name: $Parameter84Name, Parameter84.Value: $Parameter84Value, Parameter85.Name: $Parameter85Name, Parameter85.Value: $Parameter85Value, Parameter86.Name: $Parameter86Name, Parameter86.Value: $Parameter86Value, Parameter87.Name: $Parameter87Name, Parameter87.Value: $Parameter87Value, Parameter88.Name: $Parameter88Name, Parameter88.Value: $Parameter88Value, Parameter89.Name: $Parameter89Name, Parameter89.Value: $Parameter89Value, Parameter90.Name: $Parameter90Name, Parameter90.Value: $Parameter90Value, Parameter91.Name: $Parameter91Name, Parameter91.Value: $Parameter91Value, Parameter92.Name: $Parameter92Name, Parameter92.Value: $Parameter92Value, Parameter93.Name: $Parameter93Name, Parameter93.Value: $Parameter93Value, Parameter94.Name: $Parameter94Name, Parameter94.Value: $Parameter94Value, Parameter95.Name: $Parameter95Name, Parameter95.Value: $Parameter95Value, Parameter96.Name: $Parameter96Name, Parameter96.Value: $Parameter96Value, Parameter97.Name: $Parameter97Name, Parameter97.Value: $Parameter97Value, Parameter98.Name: $Parameter98Name, Parameter98.Value: $Parameter98Value, Parameter99.Name: $Parameter99Name, Parameter99.Value: $Parameter99Value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Stop a Siprec using either the SID of the Siprec resource or the `name` used when creating the resource
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Siprec/{Sid}.json
# operationId: UpdateSiprec
export def "2010-04-01-accounts-calls-siprec UpdateSiprec" [
  AccountSid: string
  CallSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Status: string@Status-completer-8
]: any -> record<sid: string, account_sid: string, call_sid: string, name: string, status: string, date_updated: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/Siprec/($Sid).json")
  let body = {Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a Stream
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Streams.json
# operationId: CreateStream
export def "2010-04-01-accounts-calls-streamsjson CreateStream" [
  AccountSid: string
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Url: string # Relative or absolute URL where WebSocket connection will be established. (format: uri)
  --Name: string # The user-specified name of this Stream, if one was given when the Stream was created. This can be used to stop the Stream.
  --Track: string@Track-completer # The tracks to be included in the Stream. Possible values are `inbound_track`, `outbound_track`, `both_tracks`. Default value is `inbound_track`.
  --StatusCallback: string # Absolute URL to which Twilio sends status callback HTTP requests. (format: uri)
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The HTTP method Twilio uses when sending `status_callback` requests. Possible values are `GET` and `POST`. Default is `POST`. (format: http-method)
  --Parameter1Name: string # Parameter name
  --Parameter1Value: string # Parameter value
  --Parameter2Name: string # Parameter name
  --Parameter2Value: string # Parameter value
  --Parameter3Name: string # Parameter name
  --Parameter3Value: string # Parameter value
  --Parameter4Name: string # Parameter name
  --Parameter4Value: string # Parameter value
  --Parameter5Name: string # Parameter name
  --Parameter5Value: string # Parameter value
  --Parameter6Name: string # Parameter name
  --Parameter6Value: string # Parameter value
  --Parameter7Name: string # Parameter name
  --Parameter7Value: string # Parameter value
  --Parameter8Name: string # Parameter name
  --Parameter8Value: string # Parameter value
  --Parameter9Name: string # Parameter name
  --Parameter9Value: string # Parameter value
  --Parameter10Name: string # Parameter name
  --Parameter10Value: string # Parameter value
  --Parameter11Name: string # Parameter name
  --Parameter11Value: string # Parameter value
  --Parameter12Name: string # Parameter name
  --Parameter12Value: string # Parameter value
  --Parameter13Name: string # Parameter name
  --Parameter13Value: string # Parameter value
  --Parameter14Name: string # Parameter name
  --Parameter14Value: string # Parameter value
  --Parameter15Name: string # Parameter name
  --Parameter15Value: string # Parameter value
  --Parameter16Name: string # Parameter name
  --Parameter16Value: string # Parameter value
  --Parameter17Name: string # Parameter name
  --Parameter17Value: string # Parameter value
  --Parameter18Name: string # Parameter name
  --Parameter18Value: string # Parameter value
  --Parameter19Name: string # Parameter name
  --Parameter19Value: string # Parameter value
  --Parameter20Name: string # Parameter name
  --Parameter20Value: string # Parameter value
  --Parameter21Name: string # Parameter name
  --Parameter21Value: string # Parameter value
  --Parameter22Name: string # Parameter name
  --Parameter22Value: string # Parameter value
  --Parameter23Name: string # Parameter name
  --Parameter23Value: string # Parameter value
  --Parameter24Name: string # Parameter name
  --Parameter24Value: string # Parameter value
  --Parameter25Name: string # Parameter name
  --Parameter25Value: string # Parameter value
  --Parameter26Name: string # Parameter name
  --Parameter26Value: string # Parameter value
  --Parameter27Name: string # Parameter name
  --Parameter27Value: string # Parameter value
  --Parameter28Name: string # Parameter name
  --Parameter28Value: string # Parameter value
  --Parameter29Name: string # Parameter name
  --Parameter29Value: string # Parameter value
  --Parameter30Name: string # Parameter name
  --Parameter30Value: string # Parameter value
  --Parameter31Name: string # Parameter name
  --Parameter31Value: string # Parameter value
  --Parameter32Name: string # Parameter name
  --Parameter32Value: string # Parameter value
  --Parameter33Name: string # Parameter name
  --Parameter33Value: string # Parameter value
  --Parameter34Name: string # Parameter name
  --Parameter34Value: string # Parameter value
  --Parameter35Name: string # Parameter name
  --Parameter35Value: string # Parameter value
  --Parameter36Name: string # Parameter name
  --Parameter36Value: string # Parameter value
  --Parameter37Name: string # Parameter name
  --Parameter37Value: string # Parameter value
  --Parameter38Name: string # Parameter name
  --Parameter38Value: string # Parameter value
  --Parameter39Name: string # Parameter name
  --Parameter39Value: string # Parameter value
  --Parameter40Name: string # Parameter name
  --Parameter40Value: string # Parameter value
  --Parameter41Name: string # Parameter name
  --Parameter41Value: string # Parameter value
  --Parameter42Name: string # Parameter name
  --Parameter42Value: string # Parameter value
  --Parameter43Name: string # Parameter name
  --Parameter43Value: string # Parameter value
  --Parameter44Name: string # Parameter name
  --Parameter44Value: string # Parameter value
  --Parameter45Name: string # Parameter name
  --Parameter45Value: string # Parameter value
  --Parameter46Name: string # Parameter name
  --Parameter46Value: string # Parameter value
  --Parameter47Name: string # Parameter name
  --Parameter47Value: string # Parameter value
  --Parameter48Name: string # Parameter name
  --Parameter48Value: string # Parameter value
  --Parameter49Name: string # Parameter name
  --Parameter49Value: string # Parameter value
  --Parameter50Name: string # Parameter name
  --Parameter50Value: string # Parameter value
  --Parameter51Name: string # Parameter name
  --Parameter51Value: string # Parameter value
  --Parameter52Name: string # Parameter name
  --Parameter52Value: string # Parameter value
  --Parameter53Name: string # Parameter name
  --Parameter53Value: string # Parameter value
  --Parameter54Name: string # Parameter name
  --Parameter54Value: string # Parameter value
  --Parameter55Name: string # Parameter name
  --Parameter55Value: string # Parameter value
  --Parameter56Name: string # Parameter name
  --Parameter56Value: string # Parameter value
  --Parameter57Name: string # Parameter name
  --Parameter57Value: string # Parameter value
  --Parameter58Name: string # Parameter name
  --Parameter58Value: string # Parameter value
  --Parameter59Name: string # Parameter name
  --Parameter59Value: string # Parameter value
  --Parameter60Name: string # Parameter name
  --Parameter60Value: string # Parameter value
  --Parameter61Name: string # Parameter name
  --Parameter61Value: string # Parameter value
  --Parameter62Name: string # Parameter name
  --Parameter62Value: string # Parameter value
  --Parameter63Name: string # Parameter name
  --Parameter63Value: string # Parameter value
  --Parameter64Name: string # Parameter name
  --Parameter64Value: string # Parameter value
  --Parameter65Name: string # Parameter name
  --Parameter65Value: string # Parameter value
  --Parameter66Name: string # Parameter name
  --Parameter66Value: string # Parameter value
  --Parameter67Name: string # Parameter name
  --Parameter67Value: string # Parameter value
  --Parameter68Name: string # Parameter name
  --Parameter68Value: string # Parameter value
  --Parameter69Name: string # Parameter name
  --Parameter69Value: string # Parameter value
  --Parameter70Name: string # Parameter name
  --Parameter70Value: string # Parameter value
  --Parameter71Name: string # Parameter name
  --Parameter71Value: string # Parameter value
  --Parameter72Name: string # Parameter name
  --Parameter72Value: string # Parameter value
  --Parameter73Name: string # Parameter name
  --Parameter73Value: string # Parameter value
  --Parameter74Name: string # Parameter name
  --Parameter74Value: string # Parameter value
  --Parameter75Name: string # Parameter name
  --Parameter75Value: string # Parameter value
  --Parameter76Name: string # Parameter name
  --Parameter76Value: string # Parameter value
  --Parameter77Name: string # Parameter name
  --Parameter77Value: string # Parameter value
  --Parameter78Name: string # Parameter name
  --Parameter78Value: string # Parameter value
  --Parameter79Name: string # Parameter name
  --Parameter79Value: string # Parameter value
  --Parameter80Name: string # Parameter name
  --Parameter80Value: string # Parameter value
  --Parameter81Name: string # Parameter name
  --Parameter81Value: string # Parameter value
  --Parameter82Name: string # Parameter name
  --Parameter82Value: string # Parameter value
  --Parameter83Name: string # Parameter name
  --Parameter83Value: string # Parameter value
  --Parameter84Name: string # Parameter name
  --Parameter84Value: string # Parameter value
  --Parameter85Name: string # Parameter name
  --Parameter85Value: string # Parameter value
  --Parameter86Name: string # Parameter name
  --Parameter86Value: string # Parameter value
  --Parameter87Name: string # Parameter name
  --Parameter87Value: string # Parameter value
  --Parameter88Name: string # Parameter name
  --Parameter88Value: string # Parameter value
  --Parameter89Name: string # Parameter name
  --Parameter89Value: string # Parameter value
  --Parameter90Name: string # Parameter name
  --Parameter90Value: string # Parameter value
  --Parameter91Name: string # Parameter name
  --Parameter91Value: string # Parameter value
  --Parameter92Name: string # Parameter name
  --Parameter92Value: string # Parameter value
  --Parameter93Name: string # Parameter name
  --Parameter93Value: string # Parameter value
  --Parameter94Name: string # Parameter name
  --Parameter94Value: string # Parameter value
  --Parameter95Name: string # Parameter name
  --Parameter95Value: string # Parameter value
  --Parameter96Name: string # Parameter name
  --Parameter96Value: string # Parameter value
  --Parameter97Name: string # Parameter name
  --Parameter97Value: string # Parameter value
  --Parameter98Name: string # Parameter name
  --Parameter98Value: string # Parameter value
  --Parameter99Name: string # Parameter name
  --Parameter99Value: string # Parameter value
]: any -> record<sid: string, account_sid: string, call_sid: string, name: string, status: string, date_updated: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/Streams.json")
  let body = {Url: $Url, Name: $Name, Track: $Track, StatusCallback: $StatusCallback, StatusCallbackMethod: $StatusCallbackMethod, Parameter1.Name: $Parameter1Name, Parameter1.Value: $Parameter1Value, Parameter2.Name: $Parameter2Name, Parameter2.Value: $Parameter2Value, Parameter3.Name: $Parameter3Name, Parameter3.Value: $Parameter3Value, Parameter4.Name: $Parameter4Name, Parameter4.Value: $Parameter4Value, Parameter5.Name: $Parameter5Name, Parameter5.Value: $Parameter5Value, Parameter6.Name: $Parameter6Name, Parameter6.Value: $Parameter6Value, Parameter7.Name: $Parameter7Name, Parameter7.Value: $Parameter7Value, Parameter8.Name: $Parameter8Name, Parameter8.Value: $Parameter8Value, Parameter9.Name: $Parameter9Name, Parameter9.Value: $Parameter9Value, Parameter10.Name: $Parameter10Name, Parameter10.Value: $Parameter10Value, Parameter11.Name: $Parameter11Name, Parameter11.Value: $Parameter11Value, Parameter12.Name: $Parameter12Name, Parameter12.Value: $Parameter12Value, Parameter13.Name: $Parameter13Name, Parameter13.Value: $Parameter13Value, Parameter14.Name: $Parameter14Name, Parameter14.Value: $Parameter14Value, Parameter15.Name: $Parameter15Name, Parameter15.Value: $Parameter15Value, Parameter16.Name: $Parameter16Name, Parameter16.Value: $Parameter16Value, Parameter17.Name: $Parameter17Name, Parameter17.Value: $Parameter17Value, Parameter18.Name: $Parameter18Name, Parameter18.Value: $Parameter18Value, Parameter19.Name: $Parameter19Name, Parameter19.Value: $Parameter19Value, Parameter20.Name: $Parameter20Name, Parameter20.Value: $Parameter20Value, Parameter21.Name: $Parameter21Name, Parameter21.Value: $Parameter21Value, Parameter22.Name: $Parameter22Name, Parameter22.Value: $Parameter22Value, Parameter23.Name: $Parameter23Name, Parameter23.Value: $Parameter23Value, Parameter24.Name: $Parameter24Name, Parameter24.Value: $Parameter24Value, Parameter25.Name: $Parameter25Name, Parameter25.Value: $Parameter25Value, Parameter26.Name: $Parameter26Name, Parameter26.Value: $Parameter26Value, Parameter27.Name: $Parameter27Name, Parameter27.Value: $Parameter27Value, Parameter28.Name: $Parameter28Name, Parameter28.Value: $Parameter28Value, Parameter29.Name: $Parameter29Name, Parameter29.Value: $Parameter29Value, Parameter30.Name: $Parameter30Name, Parameter30.Value: $Parameter30Value, Parameter31.Name: $Parameter31Name, Parameter31.Value: $Parameter31Value, Parameter32.Name: $Parameter32Name, Parameter32.Value: $Parameter32Value, Parameter33.Name: $Parameter33Name, Parameter33.Value: $Parameter33Value, Parameter34.Name: $Parameter34Name, Parameter34.Value: $Parameter34Value, Parameter35.Name: $Parameter35Name, Parameter35.Value: $Parameter35Value, Parameter36.Name: $Parameter36Name, Parameter36.Value: $Parameter36Value, Parameter37.Name: $Parameter37Name, Parameter37.Value: $Parameter37Value, Parameter38.Name: $Parameter38Name, Parameter38.Value: $Parameter38Value, Parameter39.Name: $Parameter39Name, Parameter39.Value: $Parameter39Value, Parameter40.Name: $Parameter40Name, Parameter40.Value: $Parameter40Value, Parameter41.Name: $Parameter41Name, Parameter41.Value: $Parameter41Value, Parameter42.Name: $Parameter42Name, Parameter42.Value: $Parameter42Value, Parameter43.Name: $Parameter43Name, Parameter43.Value: $Parameter43Value, Parameter44.Name: $Parameter44Name, Parameter44.Value: $Parameter44Value, Parameter45.Name: $Parameter45Name, Parameter45.Value: $Parameter45Value, Parameter46.Name: $Parameter46Name, Parameter46.Value: $Parameter46Value, Parameter47.Name: $Parameter47Name, Parameter47.Value: $Parameter47Value, Parameter48.Name: $Parameter48Name, Parameter48.Value: $Parameter48Value, Parameter49.Name: $Parameter49Name, Parameter49.Value: $Parameter49Value, Parameter50.Name: $Parameter50Name, Parameter50.Value: $Parameter50Value, Parameter51.Name: $Parameter51Name, Parameter51.Value: $Parameter51Value, Parameter52.Name: $Parameter52Name, Parameter52.Value: $Parameter52Value, Parameter53.Name: $Parameter53Name, Parameter53.Value: $Parameter53Value, Parameter54.Name: $Parameter54Name, Parameter54.Value: $Parameter54Value, Parameter55.Name: $Parameter55Name, Parameter55.Value: $Parameter55Value, Parameter56.Name: $Parameter56Name, Parameter56.Value: $Parameter56Value, Parameter57.Name: $Parameter57Name, Parameter57.Value: $Parameter57Value, Parameter58.Name: $Parameter58Name, Parameter58.Value: $Parameter58Value, Parameter59.Name: $Parameter59Name, Parameter59.Value: $Parameter59Value, Parameter60.Name: $Parameter60Name, Parameter60.Value: $Parameter60Value, Parameter61.Name: $Parameter61Name, Parameter61.Value: $Parameter61Value, Parameter62.Name: $Parameter62Name, Parameter62.Value: $Parameter62Value, Parameter63.Name: $Parameter63Name, Parameter63.Value: $Parameter63Value, Parameter64.Name: $Parameter64Name, Parameter64.Value: $Parameter64Value, Parameter65.Name: $Parameter65Name, Parameter65.Value: $Parameter65Value, Parameter66.Name: $Parameter66Name, Parameter66.Value: $Parameter66Value, Parameter67.Name: $Parameter67Name, Parameter67.Value: $Parameter67Value, Parameter68.Name: $Parameter68Name, Parameter68.Value: $Parameter68Value, Parameter69.Name: $Parameter69Name, Parameter69.Value: $Parameter69Value, Parameter70.Name: $Parameter70Name, Parameter70.Value: $Parameter70Value, Parameter71.Name: $Parameter71Name, Parameter71.Value: $Parameter71Value, Parameter72.Name: $Parameter72Name, Parameter72.Value: $Parameter72Value, Parameter73.Name: $Parameter73Name, Parameter73.Value: $Parameter73Value, Parameter74.Name: $Parameter74Name, Parameter74.Value: $Parameter74Value, Parameter75.Name: $Parameter75Name, Parameter75.Value: $Parameter75Value, Parameter76.Name: $Parameter76Name, Parameter76.Value: $Parameter76Value, Parameter77.Name: $Parameter77Name, Parameter77.Value: $Parameter77Value, Parameter78.Name: $Parameter78Name, Parameter78.Value: $Parameter78Value, Parameter79.Name: $Parameter79Name, Parameter79.Value: $Parameter79Value, Parameter80.Name: $Parameter80Name, Parameter80.Value: $Parameter80Value, Parameter81.Name: $Parameter81Name, Parameter81.Value: $Parameter81Value, Parameter82.Name: $Parameter82Name, Parameter82.Value: $Parameter82Value, Parameter83.Name: $Parameter83Name, Parameter83.Value: $Parameter83Value, Parameter84.Name: $Parameter84Name, Parameter84.Value: $Parameter84Value, Parameter85.Name: $Parameter85Name, Parameter85.Value: $Parameter85Value, Parameter86.Name: $Parameter86Name, Parameter86.Value: $Parameter86Value, Parameter87.Name: $Parameter87Name, Parameter87.Value: $Parameter87Value, Parameter88.Name: $Parameter88Name, Parameter88.Value: $Parameter88Value, Parameter89.Name: $Parameter89Name, Parameter89.Value: $Parameter89Value, Parameter90.Name: $Parameter90Name, Parameter90.Value: $Parameter90Value, Parameter91.Name: $Parameter91Name, Parameter91.Value: $Parameter91Value, Parameter92.Name: $Parameter92Name, Parameter92.Value: $Parameter92Value, Parameter93.Name: $Parameter93Name, Parameter93.Value: $Parameter93Value, Parameter94.Name: $Parameter94Name, Parameter94.Value: $Parameter94Value, Parameter95.Name: $Parameter95Name, Parameter95.Value: $Parameter95Value, Parameter96.Name: $Parameter96Name, Parameter96.Value: $Parameter96Value, Parameter97.Name: $Parameter97Name, Parameter97.Value: $Parameter97Value, Parameter98.Name: $Parameter98Name, Parameter98.Value: $Parameter98Value, Parameter99.Name: $Parameter99Name, Parameter99.Value: $Parameter99Value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Stop a Stream using either the SID of the Stream resource or the `name` used when creating the resource
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Streams/{Sid}.json
# operationId: UpdateStream
export def "2010-04-01-accounts-calls-streams UpdateStream" [
  AccountSid: string
  CallSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Status: string@Status-completer-8
]: any -> record<sid: string, account_sid: string, call_sid: string, name: string, status: string, date_updated: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/Streams/($Sid).json")
  let body = {Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a new token for ICE servers
#
# POST /2010-04-01/Accounts/{AccountSid}/Tokens.json
# operationId: CreateToken
export def "2010-04-01-accounts-tokensjson CreateToken" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Ttl: int # The duration in seconds for which the generated credentials are valid. The default value is 86400 (24 hours).
]: any -> record<account_sid: string, date_created: string, date_updated: string, ice_servers: table<credential: string, username: string, url: string, urls: string>, password: string, ttl: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Tokens.json")
  let body = {Ttl: $Ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch an instance of a Transcription
#
# GET /2010-04-01/Accounts/{AccountSid}/Transcriptions/{Sid}.json
# operationId: FetchTranscription
export def "2010-04-01-accounts-transcriptions FetchTranscription" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, api_version: string, date_created: string, date_updated: string, duration: string, price: float, price_unit: string, recording_sid: string, sid: string, status: string, transcription_text: string, type: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Transcriptions/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a transcription from the account used to make the request
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Transcriptions/{Sid}.json
# operationId: DeleteTranscription
export def "2010-04-01-accounts-transcriptions DeleteTranscription" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Transcriptions/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of transcriptions belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Transcriptions.json
# operationId: ListTranscription
export def "2010-04-01-accounts-transcriptionsjson ListTranscription" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, transcriptions: table<account_sid: string, api_version: string, date_created: string, date_updated: string, duration: string, price: float, price_unit: string, recording_sid: string, sid: string, status: string, transcription_text: string, type: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Transcriptions.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of usage-records belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records.json
# operationId: ListUsageRecord
export def "2010-04-01-accounts-usage-recordsjson ListUsageRecord" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Category: string # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --StartDate: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --EndDate: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --IncludeSubaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $Category "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "IncludeSubaccounts" $IncludeSubaccounts "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Usage/Records.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/AllTime.json
#
# operationId: ListUsageRecordAllTime
export def "2010-04-01-accounts-usage-records-all-timejson ListUsageRecordAllTime" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Category: string # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --StartDate: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --EndDate: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --IncludeSubaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $Category "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "IncludeSubaccounts" $IncludeSubaccounts "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Usage/Records/AllTime.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/Daily.json
#
# operationId: ListUsageRecordDaily
export def "2010-04-01-accounts-usage-records-dailyjson ListUsageRecordDaily" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Category: string # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --StartDate: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --EndDate: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --IncludeSubaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $Category "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "IncludeSubaccounts" $IncludeSubaccounts "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Usage/Records/Daily.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/LastMonth.json
#
# operationId: ListUsageRecordLastMonth
export def "2010-04-01-accounts-usage-records-last-monthjson ListUsageRecordLastMonth" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Category: string # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --StartDate: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --EndDate: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --IncludeSubaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $Category "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "IncludeSubaccounts" $IncludeSubaccounts "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Usage/Records/LastMonth.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/Monthly.json
#
# operationId: ListUsageRecordMonthly
export def "2010-04-01-accounts-usage-records-monthlyjson ListUsageRecordMonthly" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Category: string # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --StartDate: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --EndDate: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --IncludeSubaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $Category "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "IncludeSubaccounts" $IncludeSubaccounts "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Usage/Records/Monthly.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/ThisMonth.json
#
# operationId: ListUsageRecordThisMonth
export def "2010-04-01-accounts-usage-records-this-monthjson ListUsageRecordThisMonth" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Category: string # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --StartDate: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --EndDate: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --IncludeSubaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $Category "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "IncludeSubaccounts" $IncludeSubaccounts "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Usage/Records/ThisMonth.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/Today.json
#
# operationId: ListUsageRecordToday
export def "2010-04-01-accounts-usage-records-todayjson ListUsageRecordToday" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Category: string # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --StartDate: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --EndDate: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --IncludeSubaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $Category "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "IncludeSubaccounts" $IncludeSubaccounts "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Usage/Records/Today.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/Yearly.json
#
# operationId: ListUsageRecordYearly
export def "2010-04-01-accounts-usage-records-yearlyjson ListUsageRecordYearly" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Category: string # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --StartDate: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --EndDate: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --IncludeSubaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $Category "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "IncludeSubaccounts" $IncludeSubaccounts "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Usage/Records/Yearly.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/Yesterday.json
#
# operationId: ListUsageRecordYesterday
export def "2010-04-01-accounts-usage-records-yesterdayjson ListUsageRecordYesterday" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Category: string # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --StartDate: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --EndDate: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --IncludeSubaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $Category "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "IncludeSubaccounts" $IncludeSubaccounts "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Usage/Records/Yesterday.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch and instance of a usage-trigger
#
# GET /2010-04-01/Accounts/{AccountSid}/Usage/Triggers/{Sid}.json
# operationId: FetchUsageTrigger
export def "2010-04-01-accounts-usage-triggers FetchUsageTrigger" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, api_version: string, callback_method: string, callback_url: string, current_value: string, date_created: string, date_fired: string, date_updated: string, friendly_name: string, recurring: string, sid: string, trigger_by: string, trigger_value: string, uri: string, usage_category: string, usage_record_uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Usage/Triggers/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an instance of a usage trigger
#
# POST /2010-04-01/Accounts/{AccountSid}/Usage/Triggers/{Sid}.json
# operationId: UpdateUsageTrigger
export def "2010-04-01-accounts-usage-triggers UpdateUsageTrigger" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --CallbackMethod: string@CallbackMethod-completer # The HTTP method we should use to call `callback_url`. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  --CallbackUrl: string # The URL we should call using `callback_method` when the trigger fires. (format: uri)
  --FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> record<account_sid: string, api_version: string, callback_method: string, callback_url: string, current_value: string, date_created: string, date_fired: string, date_updated: string, friendly_name: string, recurring: string, sid: string, trigger_by: string, trigger_value: string, uri: string, usage_category: string, usage_record_uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Usage/Triggers/($Sid).json")
  let body = {CallbackMethod: $CallbackMethod, CallbackUrl: $CallbackUrl, FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /2010-04-01/Accounts/{AccountSid}/Usage/Triggers/{Sid}.json
#
# operationId: DeleteUsageTrigger
export def "2010-04-01-accounts-usage-triggers DeleteUsageTrigger" [
  AccountSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Usage/Triggers/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new UsageTrigger
#
# POST /2010-04-01/Accounts/{AccountSid}/Usage/Triggers.json
# operationId: CreateUsageTrigger
export def "2010-04-01-accounts-usage-triggersjson CreateUsageTrigger" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  CallbackUrl: string # The URL we should call using `callback_method` when the trigger fires. (format: uri)
  TriggerValue: string # The usage value at which the trigger should fire.  For convenience, you can use an offset value such as `+30` to specify a trigger_value that is 30 units more than the current usage value. Be sure to urlencode a `+` as `%2B`.
  UsageCategory: string # The usage category that the trigger should watch.  Use one of the supported [usage categories](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) for this value.
  --CallbackMethod: string@CallbackMethod-completer # The HTTP method we should use to call `callback_url`. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  --FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --Recurring: string@Recurring-completer # The frequency of a recurring UsageTrigger.  Can be: `daily`, `monthly`, or `yearly` for recurring triggers or empty for non-recurring triggers. A trigger will only fire once during each period. Recurring times are in GMT.
  --TriggerBy: string@TriggerBy-completer # The field in the [UsageRecord](https://www.twilio.com/docs/usage/api/usage-record) resource that fires the trigger.  Can be: `count`, `usage`, or `price`, as described in the [UsageRecords documentation](https://www.twilio.com/docs/usage/api/usage-record#usage-count-price).
]: any -> record<account_sid: string, api_version: string, callback_method: string, callback_url: string, current_value: string, date_created: string, date_fired: string, date_updated: string, friendly_name: string, recurring: string, sid: string, trigger_by: string, trigger_value: string, uri: string, usage_category: string, usage_record_uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Usage/Triggers.json")
  let body = {CallbackUrl: $CallbackUrl, TriggerValue: $TriggerValue, UsageCategory: $UsageCategory, CallbackMethod: $CallbackMethod, FriendlyName: $FriendlyName, Recurring: $Recurring, TriggerBy: $TriggerBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of usage-triggers belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Usage/Triggers.json
# operationId: ListUsageTrigger
export def "2010-04-01-accounts-usage-triggersjson ListUsageTrigger" [
  AccountSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Recurring: string@Recurring-completer # The frequency of recurring UsageTriggers to read. Can be: `daily`, `monthly`, or `yearly` to read recurring UsageTriggers. An empty value or a value of `alltime` reads non-recurring UsageTriggers.
  --TriggerBy: string@TriggerBy-completer # The trigger field of the UsageTriggers to read.  Can be: `count`, `usage`, or `price` as described in the [UsageRecords documentation](https://www.twilio.com/docs/usage/api/usage-record#usage-count-price).
  --UsageCategory: string # The usage category of the UsageTriggers to read. Must be a supported [usage categories](https://www.twilio.com/docs/usage/api/usage-record#usage-categories).
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_triggers: table<account_sid: string, api_version: string, callback_method: string, callback_url: string, current_value: string, date_created: string, date_fired: string, date_updated: string, friendly_name: string, recurring: string, sid: string, trigger_by: string, trigger_value: string, uri: string, usage_category: string, usage_record_uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Recurring" $Recurring "scalar") (serialize-qp "TriggerBy" $TriggerBy "scalar") (serialize-qp "UsageCategory" $UsageCategory "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Usage/Triggers.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new User Defined Message for the given Call SID.
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/UserDefinedMessages.json
# operationId: CreateUserDefinedMessage
export def "2010-04-01-accounts-calls-user-defined-messagesjson CreateUserDefinedMessage" [
  AccountSid: string
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Content: string # The User Defined Message in the form of URL-encoded JSON string.
  --IdempotencyKey: string # A unique string value to identify API call. This should be a unique string value per API call and can be a randomly generated.
]: any -> record<account_sid: string, call_sid: string, sid: string, date_created: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/UserDefinedMessages.json")
  let body = {Content: $Content, IdempotencyKey: $IdempotencyKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Subscribe to User Defined Messages for a given Call SID.
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/UserDefinedMessageSubscriptions.json
# operationId: CreateUserDefinedMessageSubscription
export def "2010-04-01-accounts-calls-user-defined-message-subscriptionsjson CreateUserDefinedMessageSubscription" [
  AccountSid: string
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Callback: string # The URL we should call using the `method` to send user defined events to your application. URLs must contain a valid hostname (underscores are not permitted). (format: uri)
  --IdempotencyKey: string # A unique string value to identify API call. This should be a unique string value per API call and can be a randomly generated.
  --Method: string@Method-completer # The HTTP method Twilio will use when requesting the above `Url`. Either `GET` or `POST`. Default is `POST`. (format: http-method)
]: any -> record<account_sid: string, call_sid: string, sid: string, date_created: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/UserDefinedMessageSubscriptions.json")
  let body = {Callback: $Callback, IdempotencyKey: $IdempotencyKey, Method: $Method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a specific User Defined Message Subscription.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/UserDefinedMessageSubscriptions/{Sid}.json
# operationId: DeleteUserDefinedMessageSubscription
export def "2010-04-01-accounts-calls-user-defined-message-subscriptions DeleteUserDefinedMessageSubscription" [
  AccountSid: string
  CallSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base $"/2010-04-01/Accounts/($AccountSid)/Calls/($CallSid)/UserDefinedMessageSubscriptions/($Sid).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
