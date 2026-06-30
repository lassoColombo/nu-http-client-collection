# Auto-generated client for Open Data API vv1.3
# Source: https://api.apis.guru/v2/specs/openbanking.org.uk/v1.3/openapi.json
# Auth: --token flag or $env.OPEN_DATA_API_TOKEN

const BASE_URL = "https://developer.openbanking.org.uk/reference-implementation/open-banking/v1.3"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o OPEN_DATA_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

# HEAD — bodyless; default surfaces just the headers on success
def send-head [req: record, insecure: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = (http head --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure $req.url)
  if (not $full) and (not $allow_errors) and (status-ok $resp.status $ok_codes) { return $resp.headers }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://developer.openbanking.org.uk/reference-implementation/open-banking/v1.3"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "atms get" } } | get name | first)
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

# Gets a list of all `ATM` objects.
#
# GET /atms
export def "atms get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-modified-since: string # Used for conditional request, to retrieve data only if modified since a given date
  --if-none-match: string # Used for conditional request, to retrieve data only if the given Etag value does not match
]: nothing -> record<data: table<ATMID: string, ATMServices: list, AccessibilityTypes: list, AdditionalATMServices: list, Address: record, BranchIdentification: string, Currency: list, GeographicLocation: record, LocationCategory: string, MinimumValueDispensed: string, Organisation: record, SiteID: string, SiteName: string, SupportedLanguages: list>, meta: record<Agreement: string, LastUpdated: string, License: string, TermsOfUse: string, TotalResults: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/atms" $auth.query)
  let accept_val = "application/prs.openbanking.opendata.v1.3+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since, "If-None-Match": $if_none_match} | compact
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

# Gets header information on the current set of `ATM` data
#
# HEAD /atms
export def "atms head" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-modified-since: string # Used for conditional request, to retrieve data only if modified since a given date
  --if-none-match: string # Used for conditional request, to retrieve data only if the given Etag value does not match
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/atms" $auth.query)
  let accept_val = "application/prs.openbanking.opendata.v1.3+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "head"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-head $req $insecure $allow_errors $full []
}

# Gets a list of all `Branch` objects.
#
# GET /branches
export def "branches get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-modified-since: string # Used for conditional request, to retrieve data only if modified since a given date
  --if-none-match: string # Used for conditional request, to retrieve data only if the given Etag value does not match
]: nothing -> record<data: table<ATMAtBranch: bool, AccessibilityTypes: string, Address: record, AlternatePhone: list, ArrivalTime: string, BranchDescription: string, BranchFacilitiesName: list, BranchIdentification: string, BranchMediatedServiceName: list, BranchName: string, BranchOtherFacilities: list, BranchOtherMediatedServices: list, BranchOtherSelfServices: list, BranchPhoto: string, BranchSelfServeServiceName: list, BranchType: string, CustomerSegment: list, DaysOfTheWeek: string, DepartureTime: string, FaxNumber: list, GeographicLocation: record, OpeningTimes: list, Organisation: record, ParkingLocation: string, PlannedBranchClosure: list, StopName: string, TelephoneNumber: string>, meta: record<Agreement: string, LastUpdated: string, License: string, TermsOfUse: string, TotalResults: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/branches" $auth.query)
  let accept_val = "application/prs.openbanking.opendata.v1.3+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since, "If-None-Match": $if_none_match} | compact
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

# Gets header information on the current set of `Branch` data
#
# HEAD /branches
export def "branches head" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-modified-since: string # Used for conditional request, to retrieve data only if modified since a given date
  --if-none-match: string # Used for conditional request, to retrieve data only if the given Etag value does not match
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/branches" $auth.query)
  let accept_val = "application/prs.openbanking.opendata.v1.3+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "head"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-head $req $insecure $allow_errors $full []
}

# Gets a list of all `Branch Current Account` objects.
#
# GET /business-current-accounts
export def "business-current-accounts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-modified-since: string # Used for conditional request, to retrieve data only if modified since a given date
  --if-none-match: string # Used for conditional request, to retrieve data only if the given Etag value does not match
]: nothing -> record<data: table<AccessChannels: list, Benefits: record, CAPricing: list, CardNotes: string, CardType: list, CardWithdrawalLimit: string, ChequeBookAvailable: bool, Contactless: bool, CreditInterest: record, CreditScoringPartOfAccountOpeningForGettingAnAccount: bool, CreditScoringPartOfAccountOpeningForIDVerification: bool, CreditScoringPartOfAccountOpeningIDVerificationIsAHardOrSoftCreditScore: list, CreditScoringPartOfAccountOpeningIDVerificationText: list, CreditScoringPartOfAccountOpeningIsAHardOrSoftCreditScore: list, CreditScoringPartOfAccountOpeningText: string, Currency: list, Eligibility: record, Feature: list, FeesAndCharges: list, InternationalPaymentsSupported: bool, MaximumMonthlyCharge: string, MobileWallet: list, Organisation: record, Overdraft: list, OverdraftOffered: bool, ProductDescription: string, ProductIdentifier: string, ProductName: string, ProductSegment: list, ProductType: string, ProductURL: list, TsandCs: list>, meta: record<Agreement: string, LastUpdated: string, License: string, TermsOfUse: string, TotalResults: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business-current-accounts" $auth.query)
  let accept_val = "application/prs.openbanking.opendata.v1.3+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since, "If-None-Match": $if_none_match} | compact
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

# Gets header information on the current set of `Business Current Account` data
#
# HEAD /business-current-accounts
export def "business-current-accounts head" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-modified-since: string # Used for conditional request, to retrieve data only if modified since a given date
  --if-none-match: string # Used for conditional request, to retrieve data only if the given Etag value does not match
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business-current-accounts" $auth.query)
  let accept_val = "application/prs.openbanking.opendata.v1.3+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "head"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-head $req $insecure $allow_errors $full []
}

# Gets a list of all `Commerical Credit Card` objects.
#
# GET /commercial-credit-cards
export def "commercial-credit-cards get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-modified-since: string # Used for conditional request, to retrieve data only if modified since a given date
  --if-none-match: string # Used for conditional request, to retrieve data only if the given Etag value does not match
]: nothing -> record<data: table<Benefits: record, Description: string, Details: record, Eligibility: record, KeyFeatures: string, Organisation: record, OtherKeyFeatures: string, PaymentHoliday: bool, PaymentHolidayDescription: string, ProductIdentifier: string, ProductName: string, ProductSegment: list, ProductType: string, ProductURL: list, TsandCs: list>, meta: record<Agreement: string, LastUpdated: string, License: string, TermsOfUse: string, TotalResults: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/commercial-credit-cards" $auth.query)
  let accept_val = "application/prs.openbanking.opendata.v1.3+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since, "If-None-Match": $if_none_match} | compact
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

# Gets header information on the current set of `Commerical Credit Card` data
#
# HEAD /commercial-credit-cards
export def "commercial-credit-cards head" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-modified-since: string # Used for conditional request, to retrieve data only if modified since a given date
  --if-none-match: string # Used for conditional request, to retrieve data only if the given Etag value does not match
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/commercial-credit-cards" $auth.query)
  let accept_val = "application/prs.openbanking.opendata.v1.3+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "head"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-head $req $insecure $allow_errors $full []
}

# Gets a list of all `Personal Current Account` objects.
#
# GET /personal-current-accounts
export def "personal-current-accounts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-modified-since: string # Used for conditional request, to retrieve data only if modified since a given date
  --if-none-match: string # Used for conditional request, to retrieve data only if the given Etag value does not match
]: nothing -> record<data: table<AccessChannels: list, Benefits: record, CAPricing: list, CardNotes: string, CardType: list, CardWithdrawalLimit: string, ChequeBookAvailable: bool, Contactless: bool, CreditInterest: record, CreditScoringPartOfAccountOpeningForGettingAnAccount: bool, CreditScoringPartOfAccountOpeningForIDVerification: bool, CreditScoringPartOfAccountOpeningIDVerificationIsAHardOrSoftCreditScore: list, CreditScoringPartOfAccountOpeningIDVerificationText: list, CreditScoringPartOfAccountOpeningIsAHardOrSoftCreditScore: list, CreditScoringPartOfAccountOpeningText: string, Currency: list, Eligibility: record, Feature: list, FeesAndCharges: list, InternationalPaymentsSupported: bool, MaximumMonthlyCharge: string, MobileWallet: list, Organisation: record, Overdraft: list, OverdraftOffered: bool, ProductDescription: string, ProductIdentifier: string, ProductName: string, ProductSegment: list, ProductType: string, ProductURL: list, TsandCs: list>, meta: record<Agreement: string, LastUpdated: string, License: string, TermsOfUse: string, TotalResults: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/personal-current-accounts" $auth.query)
  let accept_val = "application/prs.openbanking.opendata.v1.3+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since, "If-None-Match": $if_none_match} | compact
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

# Gets header information on the current set of `Personal Current Account` data
#
# HEAD /personal-current-accounts
export def "personal-current-accounts head" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-modified-since: string # Used for conditional request, to retrieve data only if modified since a given date
  --if-none-match: string # Used for conditional request, to retrieve data only if the given Etag value does not match
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/personal-current-accounts" $auth.query)
  let accept_val = "application/prs.openbanking.opendata.v1.3+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "head"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-head $req $insecure $allow_errors $full []
}

# Gets a list of all `Unsercured SME Lending` objects.
#
# GET /unsecured-sme-loans
export def "unsecured-sme-loans get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-modified-since: string # Used for conditional request, to retrieve data only if modified since a given date
  --if-none-match: string # Used for conditional request, to retrieve data only if the given Etag value does not match
]: nothing -> record<data: table<ArrearsTreatment: string, Benefits: record, Currency: list, CustomerAccessChannels: list, Eligibility: record, FeesAndCharges: list, LoanItem: list, MaximumLoanAmount: string, MaximumLoanTerm: int, MinimumLoanAmount: string, MinimumLoanTerm: int, Organisation: record, PaymentHoliday: bool, ProductDescription: string, ProductIdentifier: string, ProductName: string, ProductSegment: list, ProductTypeName: string, ProductURL: list, TsandCs: list>, meta: record<Agreement: string, LastUpdated: string, License: string, TermsOfUse: string, TotalResults: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unsecured-sme-loans" $auth.query)
  let accept_val = "application/prs.openbanking.opendata.v1.3+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since, "If-None-Match": $if_none_match} | compact
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

# Gets header information on the current set of `Unsercured SME Lending` data
#
# HEAD /unsecured-sme-loans
export def "unsecured-sme-loans head" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-modified-since: string # Used for conditional request, to retrieve data only if modified since a given date
  --if-none-match: string # Used for conditional request, to retrieve data only if the given Etag value does not match
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unsecured-sme-loans" $auth.query)
  let accept_val = "application/prs.openbanking.opendata.v1.3+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "head"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-head $req $insecure $allow_errors $full []
}
