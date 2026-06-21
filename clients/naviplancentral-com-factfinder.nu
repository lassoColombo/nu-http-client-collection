# Auto-generated client for Advicent.FactFinderService vv1
# Source: https://api.apis.guru/v2/specs/naviplancentral.com/factfinder/v1/swagger.json
# Auth: --token flag or $env.ADVICENT_FACTFINDERSERVICE_TOKEN

const BASE_URL = "https://demo.uat.naviplancentral.com/factfinder"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ADVICENT_FACTFINDERSERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["https://demo.uat.naviplancentral.com/factfinder" "http://demo.uat.naviplancentral.com/factfinder"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def country-completer [] { ["Canada" "UnitedStates"] }
def accept-completer [] { ["application/json" "text/json"] }
def owner-completer [] { ["Client" "CoClient" "Dependent" "Joint" "Other"] }
def employer-savings-amount-type-completer [] { ["Dollar" "Max" "Percent"] }
def mandatory-amount-type-completer [] { ["Dollar" "Max" "Percent"] }
def post-tax-savings-amount-type-completer [] { ["Dollar" "Max" "Percent"] }
def pre-tax-savings-amount-type-completer [] { ["Dollar" "Max" "Percent"] }
def plan-action-completer [] { ["Duplicate" "New" "Project" "Update"] }
def insured-completer [] { ["Client" "CoClient"] }
def member-completer [] { ["Client" "CoClient"] }
def dependent-of-completer [] { ["Client" "CoClient" "Joint" "Other"] }
def relationship-completer [] { ["Aunt" "Brother" "Daughter" "DaughterInLaw" "Father" "FemaleCousin" "FemaleOther" "FosterDaughter" "FosterSon" "Granddaughter" "Grandfather" "Grandmother" "Grandson" "MaleCousin" "MaleOther" "Mother" "Nephew" "Niece" "Sister" "Son" "SonInLaw" "Uncle"] }
def benefit-type-completer [] { ["Dollar" "Percent"] }
def member-completer-1 [] { ["Client" "CoClient" "Dependent"] }
def member-completer-2 [] { ["Client" "CoClient" "Joint"] }
def plan-level-completer [] { ["Level1" "Level2"] }
def module-name-completer [] { ["Assets" "Demographics" "Education" "Expenses" "Incomes" "Insurance" "Liabilities" "MajorPurchase" "Retirement"] }
def status-completer [] { ["AdvisorAccepted" "Canceled" "ClientSubmitted" "Deleted" "Draft" "InProgress" "New"] }
def entity-completer [] { ["CriticalIllnessInsurancePolicies" "DisabilityInsurancePoliciesBenefit" "DisabilityInsurancePoliciesPremium" "Expenses" "Liabilities" "LifeInsurancePolicies" "LongTermCareInsurancePoliciesBenefit" "LongTermCareInsurancePoliciesPremium" "RealEstateAssets" "RetirementExpenses" "SavingsStrategies"] }
def owner-completer-1 [] { ["Client" "CoClient"] }
def owner-completer-2 [] { ["Client" "CoClient" "Joint"] }
def payment-type-completer [] { ["InterestOnly" "LastPeriod" "PrincipalAndInterest" "SetPrincipal"] }
def beneficiary-completer [] { ["Client" "CoClient" "Dependent" "Other"] }
def insured-completer-1 [] { ["Client" "CoClient" "FirstToDie" "Other" "SecondToDie"] }
def payer-completer [] { ["Client" "CoClient" "Joint" "Other"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-types get-by-country" } } | get name | first)
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

# Description: This operation retrieves all Account Types for the specified country. Purpose: Provides access to the Account Types including id and type description.
#
# GET /api/AccountTypes
# operationId: AccountTypes_GetByCountry
export def "account-types get-by-country" [
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
  --country: string@country-completer # The country used to filter Account Types
]: nothing -> record<accountTypes: table<allowedSavingsTypes: list, id: int, links: list, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/AccountTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"country": $country} | compact), body: null}
}

# Description: This operation retrieves all Account Types for the specified id. Purpose: Provides access to the Account Types including id and type description.
#
# GET /api/AccountTypes/{id}
# operationId: AccountTypes_GetById
export def "account-types get" [
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
]: nothing -> record<allowedSavingsTypes: table<typeName: string, validAmountTypes: list>, id: int, links: table<href: string, rel: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/AccountTypes/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves all Accounts for the specified Fact Finder ID and/or external source ID. Purpose: Provides access to the Account information including description and market value.
#
# GET /api/Accounts
# operationId: Accounts_GetAccountsByFactFinderIdByFactfinderidExternalsourceid
export def "accounts get-by-fact-finder-by-factfinderid-externalsourceid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Accounts (format: int32)
  --external-source-id: string # The external ID used to filter Accounts
]: nothing -> record<accounts: table<accountId: int, accountType: int, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, lastUpdated: string, links: list, marketValue: float, owner: string, ownerDependentId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar") (serialize-qp "externalSourceId" $external_source_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Accounts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id, "externalSourceId": $external_source_id} | compact), body: null}
}

# Description: The operation creates an Account. Purpose: Allows for creation of Accounts on a Fact Finder.
#
# POST /api/Accounts
# operationId: Accounts_PostByModel
export def "accounts create-by-model" [
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
  --account-type: int # format: int32
  description: string
  --external-destination-id: string
  --external-source-id: string
  --external-source-name: string
  fact_finder_id: int # format: int32
  --last-updated: string # format: date-time
  --market-value: float # format: double
  --owner: string@owner-completer
  --owner-dependent-id: int # format: int32
]: any -> record<accountId: int, accountType: int, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, lastUpdated: string, links: table<href: string, rel: string>, marketValue: float, owner: string, ownerDependentId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Accounts")
  let req_body = {"accountType": $account_type, "description": $description, "externalDestinationId": $external_destination_id, "externalSourceId": $external_source_id, "externalSourceName": $external_source_name, "factFinderId": $fact_finder_id, "lastUpdated": $last_updated, "marketValue": $market_value, "owner": $owner, "ownerDependentId": $owner_dependent_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves all holdings in the specified Account.
#
# GET /api/Accounts/{accountId}/Holdings
# operationId: Accounts_GetAccountHoldingsByAccountid
export def "accounts-holdings list" [
  account_id: int
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
]: nothing -> record<holdings: table<accountHoldingId: int, accountId: int, costBasis: float, cusip: string, description: string, externalDestinationId: string, links: list, marketValue: float, symbol: string, valuationDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/api/Accounts/{account_id}/Holdings"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a holding and adds it to an existing Account.
#
# POST /api/Accounts/{accountId}/Holdings
# operationId: Accounts_PostAccountHoldingByAccountidModel
export def "accounts-holdings create-by-model" [
  account_id: int
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
  --cost-basis: float # format: double
  --cusip: string
  description: string
  --external-destination-id: string
  --market-value: float # format: double
  --symbol: string
  --valuation-date: string # format: date-time
]: any -> record<accountHoldingId: int, accountId: int, costBasis: float, cusip: string, description: string, externalDestinationId: string, links: table<href: string, rel: string>, marketValue: float, symbol: string, valuationDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/api/Accounts/{account_id}/Holdings"))
  let req_body = {"costBasis": $cost_basis, "cusip": $cusip, "description": $description, "externalDestinationId": $external_destination_id, "marketValue": $market_value, "symbol": $symbol, "valuationDate": $valuation_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates all holdings associated with an account
#
# PUT /api/Accounts/{accountId}/Holdings
# operationId: Accounts_PutHoldingsByAccountidHoldings
# --holdings item shape: {costBasis?: float, cusip?: string, description: string, externalDestinationId?: string, marketValue?: float, symbol?: string, valuationDate?: string}
export def "accounts-holdings update-by-account-id" [
  account_id: int
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
  --holdings: list # item shape: {costBasis?: float, cusip?: string, description: string, externalDestinationId?: string, marketValue?: float, symbol?: string, valuationDate?: string}
]: any -> record<holdings: table<accountHoldingId: int, accountId: int, costBasis: float, cusip: string, description: string, externalDestinationId: string, links: list, marketValue: float, symbol: string, valuationDate: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/api/Accounts/{account_id}/Holdings"))
  let req_body = {"holdings": $holdings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation deletes a single Account Holding for the specified Account Holding ID and Account ID. Purpose: Provides the ability to remove individual holdings from a specified Account.
#
# DELETE /api/Accounts/{accountId}/Holdings/{id}
# operationId: Accounts_DeleteAccountHoldingByAccountidId
export def "accounts-holdings delete" [
  account_id: int
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), id: (encode-path-segment $id)} | format pattern "/api/Accounts/{account_id}/Holdings/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Account Holding for the specified Account Holding ID and Account ID. Purpose: Provides access to the Account Holding information including description and market value.
#
# GET /api/Accounts/{accountId}/Holdings/{id}
# operationId: Accounts_GetAccountHoldingByAccountidId
export def "accounts-holdings get" [
  account_id: int
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
]: nothing -> record<accountHoldingId: int, accountId: int, costBasis: float, cusip: string, description: string, externalDestinationId: string, links: table<href: string, rel: string>, marketValue: float, symbol: string, valuationDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), id: (encode-path-segment $id)} | format pattern "/api/Accounts/{account_id}/Holdings/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a holding associated with an account
#
# PUT /api/Accounts/{accountId}/Holdings/{id}
# operationId: Accounts_PutByAccountidIdHolding
export def "accounts-holdings update-by-account-id-1" [
  account_id: int
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
  --cost-basis: float # format: double
  --cusip: string
  description: string
  --external-destination-id: string
  --market-value: float # format: double
  --symbol: string
  --valuation-date: string # format: date-time
]: any -> record<costBasis: float, cusip: string, description: string, externalDestinationId: string, marketValue: float, symbol: string, valuationDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), id: (encode-path-segment $id)} | format pattern "/api/Accounts/{account_id}/Holdings/{id}"))
  let req_body = {"costBasis": $cost_basis, "cusip": $cusip, "description": $description, "externalDestinationId": $external_destination_id, "marketValue": $market_value, "symbol": $symbol, "valuationDate": $valuation_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes all savings strategies tied to an account
#
# DELETE /api/Accounts/{accountId}/SavingsStrategies
# operationId: Accounts_DeleteSavingsStrategiesByAccountid
export def "accounts-savings-strategies delete" [
  account_id: int
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/api/Accounts/{account_id}/SavingsStrategies"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all of the savings strategies for a specific account
#
# GET /api/Accounts/{accountId}/SavingsStrategies
# operationId: Accounts_GetSavingsStrategiesByAccountIdByAccountid
export def "accounts-savings-strategies get-by" [
  account_id: int
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
]: nothing -> record<savingsStrategies: table<accountId: int, employerSavingsAmount: float, employerSavingsAmountType: string, endDate: string, externalDestinationId: string, frequencyId: int, mandatoryAmount: float, mandatoryAmountType: string, postTaxSavingsAmount: float, postTaxSavingsAmountType: string, preTaxSavingsAmount: float, preTaxSavingsAmountType: string, savingsStrategyId: int, startDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/api/Accounts/{account_id}/SavingsStrategies"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a savings strategy on a specific account
#
# POST /api/Accounts/{accountId}/SavingsStrategies
# operationId: Accounts_PostSavingsStrategyByAccountidSavingsstrategy
export def "accounts-savings-strategies create-strategy-by-savingsstrategy" [
  account_id: int
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
  --employer-savings-amount: float # format: double
  --employer-savings-amount-type: string@employer-savings-amount-type-completer
  --end-date: string # format: date-time
  --external-destination-id: string
  --frequency-id: int # format: int32
  --mandatory-amount: float # format: double
  --mandatory-amount-type: string@mandatory-amount-type-completer
  --post-tax-savings-amount: float # format: double
  --post-tax-savings-amount-type: string@post-tax-savings-amount-type-completer
  --pre-tax-savings-amount: float # format: double
  --pre-tax-savings-amount-type: string@pre-tax-savings-amount-type-completer
  --start-date: string # format: date-time
]: any -> record<accountId: int, employerSavingsAmount: float, employerSavingsAmountType: string, endDate: string, externalDestinationId: string, frequencyId: int, mandatoryAmount: float, mandatoryAmountType: string, postTaxSavingsAmount: float, postTaxSavingsAmountType: string, preTaxSavingsAmount: float, preTaxSavingsAmountType: string, savingsStrategyId: int, startDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/api/Accounts/{account_id}/SavingsStrategies"))
  let req_body = {"employerSavingsAmount": $employer_savings_amount, "employerSavingsAmountType": $employer_savings_amount_type, "endDate": $end_date, "externalDestinationId": $external_destination_id, "frequencyId": $frequency_id, "mandatoryAmount": $mandatory_amount, "mandatoryAmountType": $mandatory_amount_type, "postTaxSavingsAmount": $post_tax_savings_amount, "postTaxSavingsAmountType": $post_tax_savings_amount_type, "preTaxSavingsAmount": $pre_tax_savings_amount, "preTaxSavingsAmountType": $pre_tax_savings_amount_type, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a specific savings strategy
#
# DELETE /api/Accounts/{accountId}/SavingsStrategies/{id}
# operationId: Accounts_DeleteSavingsStrategyByAccountidId
export def "accounts-savings-strategies delete-strategy" [
  account_id: int
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), id: (encode-path-segment $id)} | format pattern "/api/Accounts/{account_id}/SavingsStrategies/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific savings strategy for an account
#
# GET /api/Accounts/{accountId}/SavingsStrategies/{id}
# operationId: Accounts_GetSavingsStrategiesByAccountIdAndSavingsStrategyIdByAccountidId
export def "accounts-savings-strategies get-by-and-strategy" [
  account_id: int
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
]: nothing -> record<accountId: int, employerSavingsAmount: float, employerSavingsAmountType: string, endDate: string, externalDestinationId: string, frequencyId: int, mandatoryAmount: float, mandatoryAmountType: string, postTaxSavingsAmount: float, postTaxSavingsAmountType: string, preTaxSavingsAmount: float, preTaxSavingsAmountType: string, savingsStrategyId: int, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), id: (encode-path-segment $id)} | format pattern "/api/Accounts/{account_id}/SavingsStrategies/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a specific savings strategy
#
# PUT /api/Accounts/{accountId}/SavingsStrategies/{id}
# operationId: Accounts_PutSavingsStrategyByAccountidIdSavingsstrategy
export def "accounts-savings-strategies update-strategy-by-savingsstrategy" [
  account_id: int
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
  --employer-savings-amount: float # format: double
  --employer-savings-amount-type: string@employer-savings-amount-type-completer
  --end-date: string # format: date-time
  --external-destination-id: string
  --frequency-id: int # format: int32
  --mandatory-amount: float # format: double
  --mandatory-amount-type: string@mandatory-amount-type-completer
  --post-tax-savings-amount: float # format: double
  --post-tax-savings-amount-type: string@post-tax-savings-amount-type-completer
  --pre-tax-savings-amount: float # format: double
  --pre-tax-savings-amount-type: string@pre-tax-savings-amount-type-completer
  --start-date: string # format: date-time
]: any -> record<accountId: int, employerSavingsAmount: float, employerSavingsAmountType: string, endDate: string, externalDestinationId: string, frequencyId: int, mandatoryAmount: float, mandatoryAmountType: string, postTaxSavingsAmount: float, postTaxSavingsAmountType: string, preTaxSavingsAmount: float, preTaxSavingsAmountType: string, savingsStrategyId: int, startDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), id: (encode-path-segment $id)} | format pattern "/api/Accounts/{account_id}/SavingsStrategies/{id}"))
  let req_body = {"employerSavingsAmount": $employer_savings_amount, "employerSavingsAmountType": $employer_savings_amount_type, "endDate": $end_date, "externalDestinationId": $external_destination_id, "frequencyId": $frequency_id, "mandatoryAmount": $mandatory_amount, "mandatoryAmountType": $mandatory_amount_type, "postTaxSavingsAmount": $post_tax_savings_amount, "postTaxSavingsAmountType": $post_tax_savings_amount_type, "preTaxSavingsAmount": $pre_tax_savings_amount, "preTaxSavingsAmountType": $pre_tax_savings_amount_type, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation removes an Account tied to a Fact Finder. Purpose: Allows for removal of an Account from a Fact Finder.
#
# DELETE /api/Accounts/{id}
# operationId: Accounts_DeleteAccountById
export def "accounts delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Accounts/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Account for the specified Account ID. Purpose: Provides access to the Account information including description and market value.
#
# GET /api/Accounts/{id}
# operationId: Accounts_GetById
export def "accounts get" [
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
]: nothing -> record<accountId: int, accountType: int, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, lastUpdated: string, links: table<href: string, rel: string>, marketValue: float, owner: string, ownerDependentId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Accounts/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates an Account, deletes associated saving strategies if the account type changes. Purpose: Allows for complete replacement of an Account on a Fact Finder.
#
# PUT /api/Accounts/{id}
# operationId: Accounts_PutByIdModel
export def "accounts update-by-model" [
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
  --account-type: int # format: int32
  description: string
  --external-destination-id: string
  --external-source-id: string
  --external-source-name: string
  fact_finder_id: int # format: int32
  --last-updated: string # format: date-time
  --market-value: float # format: double
  --owner: string@owner-completer
  --owner-dependent-id: int # format: int32
]: any -> record<accountId: int, accountType: int, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, lastUpdated: string, links: table<href: string, rel: string>, marketValue: float, owner: string, ownerDependentId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Accounts/{id}"))
  let req_body = {"accountType": $account_type, "description": $description, "externalDestinationId": $external_destination_id, "externalSourceId": $external_source_id, "externalSourceName": $external_source_name, "factFinderId": $fact_finder_id, "lastUpdated": $last_updated, "marketValue": $market_value, "owner": $owner, "ownerDependentId": $owner_dependent_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation submits the Fact Finder data to an external system. Purpose: Allows Fact Finder data to be persisted in another system for that system's consumption and use.
#
# POST /api/Clients
# operationId: Clients_PostByModel
export def "clients create-by-model" [
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
  --external-destination-name: string
  fact_finder_id: int # format: int32
  plan_action: string@plan-action-completer
]: any -> record<clientId: int, message: string, ownerUser: string, planId: int, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Clients")
  let req_body = {"externalDestinationName": $external_destination_name, "factFinderId": $fact_finder_id, "planAction": $plan_action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Critical Illness Insurance Policies for the specified Fact Finder ID. Purpose: Provides access to the Critical Illness Insurance Policies including description and policy type.
#
# GET /api/CriticalIllnessInsurancePolicies
# operationId: CriticalIllnessInsurancePolicies_GetCriticalIllnessInsurancePoliciesByFactFinderIdByFactfinderid
export def "critical-illness-insurance-policies get-by-fact-finder-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Critical Illness Insurance Policies (format: int32)
]: nothing -> record<criticalIllnessInsurancePolicies: table<benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, insurancePolicyId: int, insured: string, links: list, policyType: int, premium: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/CriticalIllnessInsurancePolicies" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: The operation creates a Critical Illness Insurance Policy. Purpose: Allows for creation of Critical Illness Insurance Policies on a Fact Finder.
#
# POST /api/CriticalIllnessInsurancePolicies
# operationId: CriticalIllnessInsurancePolicies_PostByModel
export def "critical-illness-insurance-policies create-by-model" [
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
  --benefit: float # format: double
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --insured: string@insured-completer
  --policy-type: int # format: int32
  --premium: float # format: double
]: any -> record<benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/CriticalIllnessInsurancePolicies")
  let req_body = {"benefit": $benefit, "description": $description, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "frequency": $frequency, "insured": $insured, "policyType": $policy_type, "premium": $premium} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation removes a Critical Illness Insurance Policy tied to a Fact Finder. Purpose: Allows for removal of a Critical Illness Insurance Policy from a Fact Finder.
#
# DELETE /api/CriticalIllnessInsurancePolicies/{id}
# operationId: CriticalIllnessInsurancePolicies_DeleteById
export def "critical-illness-insurance-policies delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/CriticalIllnessInsurancePolicies/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Critical Illness Insurance Policy for the specified Critical Illness Insurance Policy ID. Purpose: Provides access to the Critical Illness Insurance Policy including description and policy type.
#
# GET /api/CriticalIllnessInsurancePolicies/{id}
# operationId: CriticalIllnessInsurancePolicies_GetById
export def "critical-illness-insurance-policies get" [
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
]: nothing -> record<benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/CriticalIllnessInsurancePolicies/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates a Critical Illness Insurance Policy. Purpose: Allows for complete replacement of a Critical Illness Insurance Policy on a Fact Finder.
#
# PUT /api/CriticalIllnessInsurancePolicies/{id}
# operationId: CriticalIllnessInsurancePolicies_PutByIdModel
export def "critical-illness-insurance-policies update-by-model" [
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
  --benefit: float # format: double
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --insured: string@insured-completer
  --policy-type: int # format: int32
  --premium: float # format: double
]: any -> record<benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/CriticalIllnessInsurancePolicies/{id}"))
  let req_body = {"benefit": $benefit, "description": $description, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "frequency": $frequency, "insured": $insured, "policyType": $policy_type, "premium": $premium} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Critical Illness Insurance Policy Types for the specified country. Purpose: Provides access to the Critical Illness Insurance Policy Types including id and type description.
#
# GET /api/CriticalIllnessInsurancePolicyTypes
# operationId: CriticalIllnessInsurancePolicyTypes_GetByCountry
export def "critical-illness-insurance-policy-types get-by-country" [
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
  --country: string@country-completer # The country used to filter Critical Illness Insurance Policy Types
]: nothing -> record<insurancePolicyTypes: table<id: int, links: list, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/CriticalIllnessInsurancePolicyTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"country": $country} | compact), body: null}
}

# Description: This operation retrieves the Critical Illness Insurance Policy Type for the specified id. Purpose: Provides access to the Critical Illness Insurance Policy Types including id and type description.
#
# GET /api/CriticalIllnessInsurancePolicyTypes/{id}
# operationId: CriticalIllnessInsurancePolicyTypes_GetById
export def "critical-illness-insurance-policy-types get" [
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
]: nothing -> record<id: int, links: table<href: string, rel: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/CriticalIllnessInsurancePolicyTypes/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves all Defined Benefit Pensions for the specified Fact Finder ID. Purpose: Provides access to the Defined Benefit Pensions including description and start date.
#
# GET /api/DefinedBenefitPensions
# operationId: DefinedBenefitPensions_GetDefinedBenefitPensionsByFactFinderIdByFactfinderid
export def "defined-benefit-pensions get-by-fact-finder-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Defined Benefit Pensions (format: int32)
]: nothing -> record<definedBenefitPensions: table<definedBenefitPensionId: int, description: string, estimatedAmount: float, externalDestinationId: string, factFinderId: int, links: list, member: string, startDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/DefinedBenefitPensions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: The operation creates a Defined Benefit Pension. Purpose: Allows for creation of Defined Benefit Pensions on a Fact Finder.
#
# POST /api/DefinedBenefitPensions
# operationId: DefinedBenefitPensions_PostByModel
export def "defined-benefit-pensions create-by-model" [
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
  description: string
  --estimated-amount: float # format: double
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --member: string@member-completer
  --start-date: string # format: date-time
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/DefinedBenefitPensions")
  let req_body = {"description": $description, "estimatedAmount": $estimated_amount, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "member": $member, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation removes a Defined Benefit Pension tied to a Fact Finder. Purpose: Allows for removal of a Defined Benefit Pension from a Fact Finder.
#
# DELETE /api/DefinedBenefitPensions/{id}
# operationId: DefinedBenefitPensions_DeleteDefinedBenefitPensionById
export def "defined-benefit-pensions delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/DefinedBenefitPensions/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Defined Benefit Pension for the specified Defined Benefit Pension ID. Purpose: Provides access to the Defined Benefit Pension including description and start date.
#
# GET /api/DefinedBenefitPensions/{id}
# operationId: DefinedBenefitPensions_GetById
export def "defined-benefit-pensions get" [
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
]: nothing -> record<definedBenefitPensionId: int, description: string, estimatedAmount: float, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, member: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/DefinedBenefitPensions/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates a Defined Benefit Pension. Purpose: Allows for complete replacement of a Defined Benefit Pension on a Fact Finder.
#
# PUT /api/DefinedBenefitPensions/{id}
# operationId: DefinedBenefitPensions_PutDefinedBenefitPensionByIdModel
export def "defined-benefit-pensions update-by-model" [
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
  description: string
  --estimated-amount: float # format: double
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --member: string@member-completer
  --start-date: string # format: date-time
]: any -> record<description: string, estimatedAmount: float, externalDestinationId: string, factFinderId: int, member: string, startDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/DefinedBenefitPensions/{id}"))
  let req_body = {"description": $description, "estimatedAmount": $estimated_amount, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "member": $member, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Demographic information for the specified Fact Finder ID. Purpose: Provides access to the Demographic information including city and state.
#
# GET /api/Demographics
# operationId: Demographics_GetDemographicsByFactFinderIdByFactfinderid
export def "demographics get-by-fact-finder-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Demographic information (format: int32)
]: nothing -> record<city: string, created: string, demographicsId: int, externalDestinationId: string, externalSourceId: string, factFinderId: int, head1: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, head2: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, jointAnalysis: bool, links: table<href: string, rel: string>, lockRetirement: bool, state: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Demographics" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: The operation creates Demographic information. Purpose: Allows for creation of Demographic information on a Fact Finder.
#
# POST /api/Demographics
# operationId: Demographics_PostByModel
# --head1 shape: {alreadyRetired: bool, birthDate: string, externalDestinationId?: string, firstName: string, gender: "Male"|"Female"|"None", lastName: string, taxFilingStatus: int}
# --head2 shape: {alreadyRetired: bool, birthDate: string, externalDestinationId?: string, firstName: string, gender: "Male"|"Female"|"None", lastName: string, taxFilingStatus: int}
export def "demographics create-by-model" [
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
  city: string
  --external-destination-id: string
  --external-source-id: string
  fact_finder_id: int # format: int32
  head1: record # shape: {alreadyRetired: bool, birthDate: string, externalDestinationId?: string, firstName: string, gender: "Male"|"Female"|"None", lastName: string, taxFilingStatus: int}
  --head2: record # shape: {alreadyRetired: bool, birthDate: string, externalDestinationId?: string, firstName: string, gender: "Male"|"Female"|"None", lastName: string, taxFilingStatus: int}
  --joint-analysis: oneof<nothing, bool>
  state: int # format: int32
]: any -> record<city: string, created: string, demographicsId: int, externalDestinationId: string, externalSourceId: string, factFinderId: int, head1: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, head2: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, jointAnalysis: bool, links: table<href: string, rel: string>, lockRetirement: bool, state: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Demographics")
  let req_body = {"city": $city, "externalDestinationId": $external_destination_id, "externalSourceId": $external_source_id, "factFinderId": $fact_finder_id, "head1": $head1, "head2": $head2, "jointAnalysis": $joint_analysis, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Dependents for the specified Demographic information ID. Purpose: Provides access to the Dependents including first and last name.
#
# GET /api/Demographics/{demographicId}/Dependents
# operationId: Demographics_GetDependentsByDemographicid
export def "demographics-dependents list" [
  demographic_id: int
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
]: nothing -> record<dependents: table<birthDate: string, demographicsId: int, dependentId: int, dependentOf: string, externalDestinationId: string, firstName: string, lastName: string, links: list, relationship: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($demographic_id | is-empty) { error make --unspanned { msg: "path parameter 'demographicId' must be non-empty" } }
  let full_url = (build-url $base ({demographic_id: (encode-path-segment $demographic_id)} | format pattern "/api/Demographics/{demographic_id}/Dependents"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation creates a Dependent. Purpose: Allows for creation of Dependents on a Fact Finder.
#
# POST /api/Demographics/{demographicId}/Dependents
# operationId: Demographics_PostByDemographicidModel
export def "demographics-dependents create-by-model" [
  demographic_id: int
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
  birth_date: string # format: date-time
  dependent_of: string@dependent-of-completer
  --external-destination-id: string
  first_name: string
  last_name: string
  relationship: string@relationship-completer
]: any -> record<birthDate: string, demographicsId: int, dependentId: int, dependentOf: string, externalDestinationId: string, firstName: string, lastName: string, links: table<href: string, rel: string>, relationship: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($demographic_id | is-empty) { error make --unspanned { msg: "path parameter 'demographicId' must be non-empty" } }
  let full_url = (build-url $base ({demographic_id: (encode-path-segment $demographic_id)} | format pattern "/api/Demographics/{demographic_id}/Dependents"))
  let req_body = {"birthDate": $birth_date, "dependentOf": $dependent_of, "externalDestinationId": $external_destination_id, "firstName": $first_name, "lastName": $last_name, "relationship": $relationship} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation removes a Dependent tied to a Fact Finder. Purpose: Allows for removal of a Dependent from a Fact Finder.
#
# DELETE /api/Demographics/{demographicId}/Dependents/{id}
# operationId: Demographics_DeleteDependentByDemographicidId
export def "demographics-dependents delete" [
  demographic_id: int
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($demographic_id | is-empty) { error make --unspanned { msg: "path parameter 'demographicId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({demographic_id: (encode-path-segment $demographic_id), id: (encode-path-segment $id)} | format pattern "/api/Demographics/{demographic_id}/Dependents/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Dependent for the specified Dependent ID. Purpose: Provides access to the Dependent including first and last name.
#
# GET /api/Demographics/{demographicId}/Dependents/{id}
# operationId: Demographics_GetDependentByDemographicidId
export def "demographics-dependents get" [
  demographic_id: int
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
]: nothing -> record<birthDate: string, demographicsId: int, dependentId: int, dependentOf: string, externalDestinationId: string, firstName: string, lastName: string, links: table<href: string, rel: string>, relationship: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($demographic_id | is-empty) { error make --unspanned { msg: "path parameter 'demographicId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({demographic_id: (encode-path-segment $demographic_id), id: (encode-path-segment $id)} | format pattern "/api/Demographics/{demographic_id}/Dependents/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates a Dependent. Purpose: Allows for complete replacement of a Dependent on a Fact Finder.
#
# PUT /api/Demographics/{demographicId}/Dependents/{id}
# operationId: Demographics_PutByDemographicidIdModel
export def "demographics-dependents update-by-model" [
  demographic_id: int
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
  birth_date: string # format: date-time
  dependent_of: string@dependent-of-completer
  --external-destination-id: string
  first_name: string
  last_name: string
  relationship: string@relationship-completer
]: any -> record<birthDate: string, demographicsId: int, dependentId: int, dependentOf: string, externalDestinationId: string, firstName: string, lastName: string, links: table<href: string, rel: string>, relationship: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($demographic_id | is-empty) { error make --unspanned { msg: "path parameter 'demographicId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({demographic_id: (encode-path-segment $demographic_id), id: (encode-path-segment $id)} | format pattern "/api/Demographics/{demographic_id}/Dependents/{id}"))
  let req_body = {"birthDate": $birth_date, "dependentOf": $dependent_of, "externalDestinationId": $external_destination_id, "firstName": $first_name, "lastName": $last_name, "relationship": $relationship} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves Demographic information for the specified Demographic information ID. Purpose: Provides access to the Demographic information including city and state.
#
# GET /api/Demographics/{id}
# operationId: Demographics_GetById
export def "demographics get" [
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
]: nothing -> record<city: string, created: string, demographicsId: int, externalDestinationId: string, externalSourceId: string, factFinderId: int, head1: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, head2: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, jointAnalysis: bool, links: table<href: string, rel: string>, lockRetirement: bool, state: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Demographics/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates Demographic information. Purpose: Allows for complete replacement of Demographic information on a Fact Finder.
#
# PUT /api/Demographics/{id}
# operationId: Demographics_PutByIdModel
# --head1 shape: {alreadyRetired: bool, birthDate: string, externalDestinationId?: string, firstName: string, gender: "Male"|"Female"|"None", lastName: string, taxFilingStatus: int}
# --head2 shape: {alreadyRetired: bool, birthDate: string, externalDestinationId?: string, firstName: string, gender: "Male"|"Female"|"None", lastName: string, taxFilingStatus: int}
export def "demographics update-by-model" [
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
  city: string
  --external-destination-id: string
  --external-source-id: string
  fact_finder_id: int # format: int32
  head1: record # shape: {alreadyRetired: bool, birthDate: string, externalDestinationId?: string, firstName: string, gender: "Male"|"Female"|"None", lastName: string, taxFilingStatus: int}
  --head2: record # shape: {alreadyRetired: bool, birthDate: string, externalDestinationId?: string, firstName: string, gender: "Male"|"Female"|"None", lastName: string, taxFilingStatus: int}
  --joint-analysis: oneof<nothing, bool>
  state: int # format: int32
]: any -> record<city: string, created: string, demographicsId: int, externalDestinationId: string, externalSourceId: string, factFinderId: int, head1: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, head2: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, jointAnalysis: bool, links: table<href: string, rel: string>, lockRetirement: bool, state: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Demographics/{id}"))
  let req_body = {"city": $city, "externalDestinationId": $external_destination_id, "externalSourceId": $external_source_id, "factFinderId": $fact_finder_id, "head1": $head1, "head2": $head2, "jointAnalysis": $joint_analysis, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Disability Insurance Policies for the specified Fact Finder ID. Purpose: Provides access to the Disability Insurance Policies including description and policy type.
#
# GET /api/DisabilityInsurancePolicies
# operationId: DisabilityInsurancePolicies_GetDisabilityInsurancePoliciesByFactFinderIdByFactfinderid
export def "disability-insurance-policies get-by-fact-finder-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Disability Insurance Policies (format: int32)
]: nothing -> record<disabilityInsurancePolicies: table<benefit: float, benefitFrequency: int, benefitType: string, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: list, policyType: int, premium: float, premiumFrequency: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/DisabilityInsurancePolicies" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: The operation creates a Disability Insurance Policy. Purpose: Allows for creation of Disability Insurance Policies on a Fact Finder.
#
# POST /api/DisabilityInsurancePolicies
# operationId: DisabilityInsurancePolicies_PostByModel
export def "disability-insurance-policies create-by-model" [
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
  --benefit: float # format: double
  --benefit-frequency: int # format: int32
  --benefit-type: string@benefit-type-completer
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --insured: string@insured-completer
  --policy-type: int # format: int32
  --premium: float # format: double
  --premium-frequency: int # format: int32
]: any -> record<benefit: float, benefitFrequency: int, benefitType: string, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float, premiumFrequency: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/DisabilityInsurancePolicies")
  let req_body = {"benefit": $benefit, "benefitFrequency": $benefit_frequency, "benefitType": $benefit_type, "description": $description, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "insured": $insured, "policyType": $policy_type, "premium": $premium, "premiumFrequency": $premium_frequency} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation removes a Disability Insurance Policy tied to a Fact Finder. Purpose: Allows for removal of a Disability Insurance Policy from a Fact Finder.
#
# DELETE /api/DisabilityInsurancePolicies/{id}
# operationId: DisabilityInsurancePolicies_DeleteById
export def "disability-insurance-policies delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/DisabilityInsurancePolicies/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Disability Insurance Policy for the specified Disability Insurance Policy ID. Purpose: Provides access to the Disability Insurance Policy including description and policy type.
#
# GET /api/DisabilityInsurancePolicies/{id}
# operationId: DisabilityInsurancePolicies_GetById
export def "disability-insurance-policies get" [
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
]: nothing -> record<benefit: float, benefitFrequency: int, benefitType: string, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float, premiumFrequency: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/DisabilityInsurancePolicies/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates a Disability Insurance Policy. Purpose: Allows for complete replacement of a Disability Insurance Policy on a Fact Finder.
#
# PUT /api/DisabilityInsurancePolicies/{id}
# operationId: DisabilityInsurancePolicies_PutByIdModel
export def "disability-insurance-policies update-by-model" [
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
  --benefit: float # format: double
  --benefit-frequency: int # format: int32
  --benefit-type: string@benefit-type-completer
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --insured: string@insured-completer
  --policy-type: int # format: int32
  --premium: float # format: double
  --premium-frequency: int # format: int32
]: any -> record<benefit: float, benefitFrequency: int, benefitType: string, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float, premiumFrequency: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/DisabilityInsurancePolicies/{id}"))
  let req_body = {"benefit": $benefit, "benefitFrequency": $benefit_frequency, "benefitType": $benefit_type, "description": $description, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "insured": $insured, "policyType": $policy_type, "premium": $premium, "premiumFrequency": $premium_frequency} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Disability Insurance Policy Types for the specified country. Purpose: Provides access to the Disability Insurance Policy Types including id and type description.
#
# GET /api/DisabilityInsurancePolicyTypes
# operationId: DisabilityInsurancePolicyTypes_GetByCountry
export def "disability-insurance-policy-types get-by-country" [
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
  --country: string@country-completer # The country used to filter Disability Insurance Policy Types
]: nothing -> record<insurancePolicyTypes: table<id: int, links: list, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/DisabilityInsurancePolicyTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"country": $country} | compact), body: null}
}

# Description: This operation retrieves all Disability Insurance Policy Types for the specified id. Purpose: Provides access to the Disability Insurance Policy Types including id and type description.
#
# GET /api/DisabilityInsurancePolicyTypes/{id}
# operationId: DisabilityInsurancePolicyTypes_GetById
export def "disability-insurance-policy-types get" [
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
]: nothing -> record<id: int, links: table<href: string, rel: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/DisabilityInsurancePolicyTypes/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves all Education Goals for the specified Fact Finder ID. Purpose: Provides access to the Education Goals including description and projected cost.
#
# GET /api/EducationGoals
# operationId: EducationGoals_GetEducationGoalsByFactFinderIdByFactfinderid
export def "education-goals get-by-fact-finder-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Education Goals (format: int32)
]: nothing -> record<educationGoals: table<description: string, educationGoalId: int, externalDestinationId: string, factFinderId: int, links: list, projectedCost: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/EducationGoals" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: The operation creates an Education Goal. Purpose: Allows for creation of Education Goals on a Fact Finder.
#
# POST /api/EducationGoals
# operationId: EducationGoals_PostByModel
export def "education-goals create-by-model" [
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
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --projected-cost: float # format: double
]: any -> record<description: string, educationGoalId: int, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, projectedCost: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/EducationGoals")
  let req_body = {"description": $description, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "projectedCost": $projected_cost} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Education Goal Expenses for the specified Education Goal ID. Purpose: Provides access to the Education Goal Expenses including description and annual cost.
#
# GET /api/EducationGoals/{educationGoalId}/Expenses
# operationId: EducationGoals_GetEducationExpensesByEducationGoalIdByEducationgoalid
export def "education-goals-expenses get-by" [
  education_goal_id: int
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
]: nothing -> record<educationExpenses: table<annualCost: float, educationExpenseId: int, educationGoalId: int, externalDestinationId: string, links: list, member: string, memberDependentId: int, startYear: string, years: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($education_goal_id | is-empty) { error make --unspanned { msg: "path parameter 'educationGoalId' must be non-empty" } }
  let full_url = (build-url $base ({education_goal_id: (encode-path-segment $education_goal_id)} | format pattern "/api/EducationGoals/{education_goal_id}/Expenses"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation creates an Education Goal Expense. Purpose: Allows for creation of Education Goal Expenses on a Fact Finder.
#
# POST /api/EducationGoals/{educationGoalId}/Expenses
# operationId: EducationGoals_PostByEducationgoalidModel
export def "education-goals-expenses create-by-model" [
  education_goal_id: int
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
  --annual-cost: float # format: double
  --external-destination-id: string
  --member: string@member-completer-1
  --member-dependent-id: int # format: int32
  --start-year: string # format: date-time
  --years: int # format: int32
]: any -> record<annualCost: float, educationExpenseId: int, educationGoalId: int, externalDestinationId: string, links: table<href: string, rel: string>, member: string, memberDependentId: int, startYear: string, years: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($education_goal_id | is-empty) { error make --unspanned { msg: "path parameter 'educationGoalId' must be non-empty" } }
  let full_url = (build-url $base ({education_goal_id: (encode-path-segment $education_goal_id)} | format pattern "/api/EducationGoals/{education_goal_id}/Expenses"))
  let req_body = {"annualCost": $annual_cost, "externalDestinationId": $external_destination_id, "member": $member, "memberDependentId": $member_dependent_id, "startYear": $start_year, "years": $years} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation removes an Education Goal Expense tied to a Fact Finder. Purpose: Allows for removal of an Education Goal Expense from a Fact Finder.
#
# DELETE /api/EducationGoals/{educationGoalId}/Expenses/{id}
# operationId: EducationGoals_DeleteByEducationgoalidId
export def "education-goals-expenses delete" [
  education_goal_id: int
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($education_goal_id | is-empty) { error make --unspanned { msg: "path parameter 'educationGoalId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({education_goal_id: (encode-path-segment $education_goal_id), id: (encode-path-segment $id)} | format pattern "/api/EducationGoals/{education_goal_id}/Expenses/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Education Goal Expense for the specified Education Goal Expense ID. Purpose: Provides access to the Education Goal Expense including description and annual cost.
#
# GET /api/EducationGoals/{educationGoalId}/Expenses/{id}
# operationId: EducationGoals_GetEducationExpenseByEducationgoalidId
export def "education-goals-expenses get" [
  education_goal_id: int
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
]: nothing -> record<annualCost: float, educationExpenseId: int, educationGoalId: int, externalDestinationId: string, links: table<href: string, rel: string>, member: string, memberDependentId: int, startYear: string, years: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($education_goal_id | is-empty) { error make --unspanned { msg: "path parameter 'educationGoalId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({education_goal_id: (encode-path-segment $education_goal_id), id: (encode-path-segment $id)} | format pattern "/api/EducationGoals/{education_goal_id}/Expenses/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates an Education Goal Expense. Purpose: Allows for complete replacement of an Education Goal Expense on a Fact Finder.
#
# PUT /api/EducationGoals/{educationGoalId}/Expenses/{id}
# operationId: EducationGoals_PutByEducationgoalidIdModel
export def "education-goals-expenses update-by-model" [
  education_goal_id: int
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
  --annual-cost: float # format: double
  --external-destination-id: string
  --member: string@member-completer-1
  --member-dependent-id: int # format: int32
  --start-year: string # format: date-time
  --years: int # format: int32
]: any -> record<annualCost: float, educationExpenseId: int, educationGoalId: int, externalDestinationId: string, links: table<href: string, rel: string>, member: string, memberDependentId: int, startYear: string, years: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($education_goal_id | is-empty) { error make --unspanned { msg: "path parameter 'educationGoalId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({education_goal_id: (encode-path-segment $education_goal_id), id: (encode-path-segment $id)} | format pattern "/api/EducationGoals/{education_goal_id}/Expenses/{id}"))
  let req_body = {"annualCost": $annual_cost, "externalDestinationId": $external_destination_id, "member": $member, "memberDependentId": $member_dependent_id, "startYear": $start_year, "years": $years} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation removes an Education Goal tied to a Fact Finder. Purpose: Allows for removal of an Education Goal from a Fact Finder.
#
# DELETE /api/EducationGoals/{id}
# operationId: EducationGoals_DeleteById
export def "education-goals delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/EducationGoals/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Education Goal for the specified Education Goal ID. Purpose: Provides access to the Education Goal including description and projected cost.
#
# GET /api/EducationGoals/{id}
# operationId: EducationGoals_GetById
export def "education-goals get" [
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
]: nothing -> record<description: string, educationGoalId: int, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, projectedCost: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/EducationGoals/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation creates an Education Goal Expense. Purpose: Allows for creation of Education Goal Expenses on a Fact Finder.
#
# PUT /api/EducationGoals/{id}
# operationId: EducationGoals_PutByIdModel
export def "education-goals update-by-model" [
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
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --projected-cost: float # format: double
]: any -> record<description: string, educationGoalId: int, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, projectedCost: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/EducationGoals/{id}"))
  let req_body = {"description": $description, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "projectedCost": $projected_cost} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Expense Types for the specified country. Purpose: Provides access to the Expense Types including id and type description.
#
# GET /api/ExpenseTypes
# operationId: ExpenseTypes_GetByCountry
export def "expense-types get-by-country" [
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
  --country: string@country-completer # The country used to filter Expense Types
]: nothing -> record<expenseTypes: table<id: int, links: list, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ExpenseTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"country": $country} | compact), body: null}
}

# Description: This operation retrieves all Expense Types for the specified country. Purpose: Provides access to the Expense Types including id and type description.
#
# GET /api/ExpenseTypes/{id}
# operationId: ExpenseTypes_GetById
export def "expense-types get" [
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
]: nothing -> record<id: int, links: table<href: string, rel: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/ExpenseTypes/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves all Expenses for the specified Fact Finder ID. Purpose: Provides access to the Expenses including description and Expense type.
#
# GET /api/Expenses
# operationId: Expenses_GetExpensesByFactFinderIdByFactfinderid
export def "expenses get-by-fact-finder-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Expenses (format: int32)
]: nothing -> record<expenses: table<annualPeriod: int, description: string, endDate: string, expenseAmount: float, expenseId: int, expenseTypeId: int, externalDestinationId: string, factFinderId: int, frequency: int, links: list, member: string, startDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Expenses" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: The operation creates an Expense. Purpose: Allows for creation of Expenses on a Fact Finder.
#
# POST /api/Expenses
# operationId: Expenses_PostByModel
export def "expenses create-by-model" [
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
  --annual-period: int # format: int32
  description: string
  --end-date: string # format: date-time
  --expense-amount: float # format: double
  --expense-type-id: int # format: int32
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --member: string@member-completer-2
  --start-date: string # format: date-time
]: any -> record<annualPeriod: int, description: string, endDate: string, expenseAmount: float, expenseId: int, expenseTypeId: int, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, member: string, startDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Expenses")
  let req_body = {"annualPeriod": $annual_period, "description": $description, "endDate": $end_date, "expenseAmount": $expense_amount, "expenseTypeId": $expense_type_id, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "frequency": $frequency, "member": $member, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation removes an Expense tied to a Fact Finder. Purpose: Allows for removal of an Expense from a Fact Finder.
#
# DELETE /api/Expenses/{id}
# operationId: Expenses_DeleteById
export def "expenses delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Expenses/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Expense for the specified Expense ID. Purpose: Provides access to the Expense including description and Expense type.
#
# GET /api/Expenses/{id}
# operationId: Expenses_GetById
export def "expenses get" [
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
]: nothing -> record<annualPeriod: int, description: string, endDate: string, expenseAmount: float, expenseId: int, expenseTypeId: int, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, member: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Expenses/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates an Expense. Purpose: Allows for complete replacement of an Expense on a Fact Finder. Note: Expense type cannot be changed for expenses prepopulated from NaviPlan.
#
# PUT /api/Expenses/{id}
# operationId: Expenses_PutByIdModel
export def "expenses update-by-model" [
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
  --annual-period: int # format: int32
  description: string
  --end-date: string # format: date-time
  --expense-amount: float # format: double
  --expense-type-id: int # format: int32
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --member: string@member-completer-2
  --start-date: string # format: date-time
]: any -> record<annualPeriod: int, description: string, endDate: string, expenseAmount: float, expenseId: int, expenseTypeId: int, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, member: string, startDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Expenses/{id}"))
  let req_body = {"annualPeriod": $annual_period, "description": $description, "endDate": $end_date, "expenseAmount": $expense_amount, "expenseTypeId": $expense_type_id, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "frequency": $frequency, "member": $member, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Fact Finders for the specified householdId, or if null, all households associated with the user. Purpose: Provides access to the Fact Finder including status.
#
# GET /api/FactFinders
# operationId: FactFinders_GetByHouseholdIdByHouseholdid
export def "fact-finders get-by-household-by-householdid" [
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
  --household-id: int # The ID of the household used to retrieve the fact finders. If not set, uses all households associated with the user (format: int32)
]: nothing -> table<countryCode: string, created: string, factFinderId: int, householdId: int, lastStatusUpdate: string, links: list<record>, modules: record<factFinderModules: list>, planId: int, planLevel: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "householdId" $household_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/FactFinders" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"householdId": $household_id} | compact), body: null}
}

# Description: The operation creates a completely empty draft Fact Finder. Requirements: A householdId and list of modules must be provided. Purpose: Stages a Fact Finder for population.
#
# POST /api/FactFinders
# operationId: FactFinders_PostByModel
export def "fact-finders create-by-model" [
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
  household_id: int # format: int32
  --modules: list<string>
  --plan-level: string@plan-level-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/FactFinders")
  let req_body = {"householdId": $household_id, "modules": $modules, "planLevel": $plan_level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation creates a new Populated Fact Finder. Requirements: A householdId and list of modules must be provided. Purpose: Creation of a Fact Finder.
#
# POST /api/FactFinders/Populate
# operationId: FactFinders_PostPopulateByModel
export def "fact-finders-populate create-by-model" [
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
  household_id: int # format: int32
  --modules: list<string>
  --plan-id: int # format: int32
  --plan-level: string@plan-level-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/FactFinders/Populate")
  let req_body = {"householdId": $household_id, "modules": $modules, "planId": $plan_id, "planLevel": $plan_level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Fact Finder Modules for the specified Fact Finder ID. Purpose: Provides access to the Fact Finder Modules including description and policy type.
#
# GET /api/FactFinders/{factFinderId}/Modules
# operationId: FactFinderModules_GetByFactfinderid
export def "fact-finders-modules list" [
  fact_finder_id: int
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
]: nothing -> record<factFinderModules: table<available: bool, factFinderId: int, links: list, moduleId: int, moduleName: string, visited: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($fact_finder_id | is-empty) { error make --unspanned { msg: "path parameter 'factFinderId' must be non-empty" } }
  let full_url = (build-url $base ({fact_finder_id: (encode-path-segment $fact_finder_id)} | format pattern "/api/FactFinders/{fact_finder_id}/Modules"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Fact Finder Module for the specified Fact Finder Module ID. Purpose: Provides access to the Fact Finder Module including description and policy type.
#
# GET /api/FactFinders/{factFinderId}/Modules/{id}
# operationId: FactFinderModules_GetByFactfinderidId
export def "fact-finders-modules get" [
  fact_finder_id: int
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
]: nothing -> record<available: bool, factFinderId: int, links: table<href: string, rel: string>, moduleId: int, moduleName: string, visited: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($fact_finder_id | is-empty) { error make --unspanned { msg: "path parameter 'factFinderId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({fact_finder_id: (encode-path-segment $fact_finder_id), id: (encode-path-segment $id)} | format pattern "/api/FactFinders/{fact_finder_id}/Modules/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates a Fact Finder Module. Purpose: Allows for complete replacement of a Fact Finder Module on a Fact Finder.
#
# PUT /api/FactFinders/{factFinderId}/Modules/{id}
# operationId: FactFinderModules_PutByModelFactfinderidId
export def "fact-finders-modules update-by-model" [
  fact_finder_id: int
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
  --available: oneof<nothing, bool>
  module_name: string@module-name-completer
  --visited: oneof<nothing, bool>
]: any -> record<available: bool, factFinderId: int, links: table<href: string, rel: string>, moduleId: int, moduleName: string, visited: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($fact_finder_id | is-empty) { error make --unspanned { msg: "path parameter 'factFinderId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({fact_finder_id: (encode-path-segment $fact_finder_id), id: (encode-path-segment $id)} | format pattern "/api/FactFinders/{fact_finder_id}/Modules/{id}"))
  let req_body = {"available": $available, "moduleName": $module_name, "visited": $visited} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation retrieves Snapshots of a Fact Finder. Purpose: Allows for advisors to view all Snapshots taken of a Fact Finder.
#
# GET /api/FactFinders/{factFinderId}/Snapshots
# operationId: FactFinders_GetSnapshotsByFactfinderid
export def "fact-finders-snapshots get" [
  fact_finder_id: int
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
]: nothing -> record<snapshots: table<created: string, factFinderData: record, factFinderId: int, factFinderStatus: string, snapshotId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($fact_finder_id | is-empty) { error make --unspanned { msg: "path parameter 'factFinderId' must be non-empty" } }
  let full_url = (build-url $base ({fact_finder_id: (encode-path-segment $fact_finder_id)} | format pattern "/api/FactFinders/{fact_finder_id}/Snapshots"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation creates a Snapshot of a Fact Finder. Purpose: Allows for advisors to compare the current fact finder to a snapshot prior to acceptance.
#
# POST /api/FactFinders/{factFinderId}/Snapshots
# operationId: FactFinders_PostSnapshotsByFactfinderid
export def "fact-finders-snapshots create" [
  fact_finder_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($fact_finder_id | is-empty) { error make --unspanned { msg: "path parameter 'factFinderId' must be non-empty" } }
  let full_url = (build-url $base ({fact_finder_id: (encode-path-segment $fact_finder_id)} | format pattern "/api/FactFinders/{fact_finder_id}/Snapshots"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation deletes a single Fact Finder for the specified Fact Finder ID. Purpose: Deletes the fact finder.
#
# DELETE /api/FactFinders/{id}
# operationId: FactFinders_DeleteById
export def "fact-finders delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/FactFinders/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Fact Finder for the specified Fact Finder ID. Purpose: Provides access to the Fact Finder including status.
#
# GET /api/FactFinders/{id}
# operationId: FactFinders_GetById
export def "fact-finders get" [
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
]: nothing -> record<countryCode: string, created: string, factFinderId: int, householdId: int, lastStatusUpdate: string, links: table<href: string, rel: string>, modules: record<factFinderModules: list<record>>, planId: int, planLevel: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/FactFinders/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates a Fact Finder. Purpose: Allows for the updating of a Fact Finder.
#
# PUT /api/FactFinders/{id}
# operationId: FactFinders_PutByIdModel
export def "fact-finders update-by-model" [
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
  --status: string@status-completer
]: any -> record<countryCode: string, created: string, factFinderId: int, householdId: int, lastStatusUpdate: string, links: table<href: string, rel: string>, modules: record<factFinderModules: list<record>>, planId: int, planLevel: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/FactFinders/{id}"))
  let req_body = {"status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation populates a fact finder. Purpose: Allows for the population of a Fact Finder based on a NaviPlan plan or client. This operation cannot be performed on a Fact Finder more than once.
#
# PUT /api/FactFinders/{id}/Populate
# operationId: FactFinders_PutPopulateFactFinderByIdModel
export def "fact-finders-populate update-by-model" [
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
  --plan-id: int # format: int32
]: any -> record<countryCode: string, created: string, factFinderId: int, householdId: int, lastStatusUpdate: string, links: table<href: string, rel: string>, modules: record<factFinderModules: list<record>>, planId: int, planLevel: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/FactFinders/{id}/Populate"))
  let req_body = {"planId": $plan_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Filing Status Types for the specified country. Purpose: Provides access to the Filing Status Types including id and type description.
#
# GET /api/FilingStatusTypes
# operationId: FilingStatusTypes_GetByCountry
export def "filing-status-types get-by-country" [
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
  --country: string@country-completer # The country used to filter Filing Status Types
]: nothing -> record<filingStatusTypes: table<filingStatusTypeId: int, filingStatusTypeName: string, hasJointDependent: bool, links: list, partnerStatuses: list, validForSingleAnalysis: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/FilingStatusTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"country": $country} | compact), body: null}
}

# Description: This operation retrieves all Filing Status Type for the specified id. Purpose: Provides access to the Filing Status Types including id and type description.
#
# GET /api/FilingStatusTypes/{id}
# operationId: FilingStatusTypes_GetById
export def "filing-status-types get" [
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
]: nothing -> record<filingStatusTypeId: int, filingStatusTypeName: string, hasJointDependent: bool, links: table<href: string, rel: string>, partnerStatuses: list<int>, validForSingleAnalysis: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/FilingStatusTypes/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves all Frequency Types for the specified country and entity. Purpose: Provides access to the Frequency Types including id and type description.
#
# GET /api/FrequencyTypes
# operationId: FrequencyTypes_GetByEntityCountry
export def "frequency-types get-by-entity-country" [
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
  --entity: string@entity-completer # The entity used to filter Frequency Types
  --country: string@country-completer # The country used to filter Frequency Types
]: nothing -> record<frequencyTypes: table<id: int, links: list, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity" $entity "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/FrequencyTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"entity": $entity, "country": $country} | compact), body: null}
}

# Description: This operation retrieves the Frequency Type for the specified id. Purpose: Provides access to the Frequency Types including id and type description.
#
# GET /api/FrequencyTypes/{id}
# operationId: FrequencyTypes_GetById
export def "frequency-types get" [
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
]: nothing -> record<id: int, links: table<href: string, rel: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/FrequencyTypes/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves all Income Types for the specified country. Purpose: Provides access to the Income Types including id and type description.
#
# GET /api/IncomeTypes
# operationId: IncomeTypes_GetByCountry
export def "income-types get-by-country" [
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
  --country: string@country-completer # The country used to filter Income Types
]: nothing -> record<incomeTypes: table<id: int, links: list, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/IncomeTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"country": $country} | compact), body: null}
}

# Description: This operation retrieves the Income Type for the specified id. Purpose: Provides access to the Income Types including id and type description.
#
# GET /api/IncomeTypes/{id}
# operationId: IncomeTypes_GetById
export def "income-types get" [
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
]: nothing -> record<id: int, links: table<href: string, rel: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/IncomeTypes/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves all Incomes for the specified Fact Finder ID. Purpose: Provides access to the Incomes including annual amount and start date.
#
# GET /api/Incomes
# operationId: Incomes_GetIncomesByFactFinderIdByFactfinderid
export def "incomes get-by-fact-finder-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Incomes (format: int32)
]: nothing -> record<incomes: table<annualAmount: float, description: string, endDate: string, externalDestinationId: string, factFinderId: int, incomeId: int, incomeTypeId: int, links: list, owner: string, startDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Incomes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: The operation creates an Income. Purpose: Allows for creation of Incomes on a Fact Finder.
#
# POST /api/Incomes
# operationId: Incomes_PostByModel
export def "incomes create-by-model" [
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
  --annual-amount: float # format: double
  description: string
  --end-date: string # format: date-time
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --income-type-id: int # format: int32
  --owner: string@owner-completer-1
  --start-date: string # format: date-time
]: any -> record<annualAmount: float, description: string, endDate: string, externalDestinationId: string, factFinderId: int, incomeId: int, incomeTypeId: int, links: table<href: string, rel: string>, owner: string, startDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Incomes")
  let req_body = {"annualAmount": $annual_amount, "description": $description, "endDate": $end_date, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "incomeTypeId": $income_type_id, "owner": $owner, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation removes an Income tied to a Fact Finder. Purpose: Allows for removal of an Income from a Fact Finder.
#
# DELETE /api/Incomes/{id}
# operationId: Incomes_DeleteById
export def "incomes delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Incomes/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Income for the specified Income ID. Purpose: Provides access to the Income including annual amount and start date.
#
# GET /api/Incomes/{id}
# operationId: Incomes_GetById
export def "incomes get" [
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
]: nothing -> record<annualAmount: float, description: string, endDate: string, externalDestinationId: string, factFinderId: int, incomeId: int, incomeTypeId: int, links: table<href: string, rel: string>, owner: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Incomes/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates an Income. Purpose: Allows for complete replacement of an Income on a Fact Finder.
#
# PUT /api/Incomes/{id}
# operationId: Incomes_PutByIdModel
export def "incomes update-by-model" [
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
  --annual-amount: float # format: double
  description: string
  --end-date: string # format: date-time
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --income-type-id: int # format: int32
  --owner: string@owner-completer-1
  --start-date: string # format: date-time
]: any -> record<annualAmount: float, description: string, endDate: string, externalDestinationId: string, factFinderId: int, incomeId: int, incomeTypeId: int, links: table<href: string, rel: string>, owner: string, startDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Incomes/{id}"))
  let req_body = {"annualAmount": $annual_amount, "description": $description, "endDate": $end_date, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "incomeTypeId": $income_type_id, "owner": $owner, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Liabilities for the specified Fact Finder ID. Purpose: Provides access to the Liabilities including owner and type.
#
# GET /api/Liabilities
# operationId: Liabilities_GetLiabilitiesByFactFinderIdByFactfinderidExternalsourceid
export def "liabilities get-by-fact-finder-by-factfinderid-externalsourceid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Liabilities (format: int32)
  --external-source-id: string # The external source ID used to filter Liabilities
]: nothing -> record<liabilities: table<balance: float, balanceAsOfDate: string, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, frequency: int, interestRate: float, lastUpdated: string, liabilityId: int, liabilityType: int, links: list, loanDate: string, originalPrincipal: float, owner: string, payment: float, paymentType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar") (serialize-qp "externalSourceId" $external_source_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Liabilities" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id, "externalSourceId": $external_source_id} | compact), body: null}
}

# Description: The operation creates a Liability. Purpose: Allows for creation of Liabilities on a Fact Finder.
#
# POST /api/Liabilities
# operationId: Liabilities_PostByModel
export def "liabilities create-by-model" [
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
  --balance: float # format: double
  --balance-as-of-date: string # format: date-time
  description: string
  --external-destination-id: string
  --external-source-id: string
  --external-source-name: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --interest-rate: float # format: double
  --last-updated: string # format: date-time
  --liability-type: int # format: int32
  --loan-date: string # format: date-time
  --original-principal: float # format: double
  --owner: string@owner-completer-2
  --payment: float # format: double
  --payment-type: string@payment-type-completer
]: any -> record<balance: float, balanceAsOfDate: string, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, frequency: int, interestRate: float, lastUpdated: string, liabilityId: int, liabilityType: int, links: table<href: string, rel: string>, loanDate: string, originalPrincipal: float, owner: string, payment: float, paymentType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Liabilities")
  let req_body = {"balance": $balance, "balanceAsOfDate": $balance_as_of_date, "description": $description, "externalDestinationId": $external_destination_id, "externalSourceId": $external_source_id, "externalSourceName": $external_source_name, "factFinderId": $fact_finder_id, "frequency": $frequency, "interestRate": $interest_rate, "lastUpdated": $last_updated, "liabilityType": $liability_type, "loanDate": $loan_date, "originalPrincipal": $original_principal, "owner": $owner, "payment": $payment, "paymentType": $payment_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation removes a Liability tied to a Fact Finder. Purpose: Allows for removal of a Liability from a Fact Finder.
#
# DELETE /api/Liabilities/{id}
# operationId: Liabilities_DeleteById
export def "liabilities delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Liabilities/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Liability for the specified Liability ID. Purpose: Provides access to the Liability including owner and type.
#
# GET /api/Liabilities/{id}
# operationId: Liabilities_GetById
export def "liabilities get" [
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
]: nothing -> record<balance: float, balanceAsOfDate: string, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, frequency: int, interestRate: float, lastUpdated: string, liabilityId: int, liabilityType: int, links: table<href: string, rel: string>, loanDate: string, originalPrincipal: float, owner: string, payment: float, paymentType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Liabilities/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates a Liability. Purpose: Allows for complete replacement of a Liability on a Fact Finder.
#
# PUT /api/Liabilities/{id}
# operationId: Liabilities_PutByIdModel
export def "liabilities update-by-model" [
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
  --balance: float # format: double
  --balance-as-of-date: string # format: date-time
  description: string
  --external-destination-id: string
  --external-source-id: string
  --external-source-name: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --interest-rate: float # format: double
  --last-updated: string # format: date-time
  --liability-type: int # format: int32
  --loan-date: string # format: date-time
  --original-principal: float # format: double
  --owner: string@owner-completer-2
  --payment: float # format: double
  --payment-type: string@payment-type-completer
]: any -> record<balance: float, balanceAsOfDate: string, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, frequency: int, interestRate: float, lastUpdated: string, liabilityId: int, liabilityType: int, links: table<href: string, rel: string>, loanDate: string, originalPrincipal: float, owner: string, payment: float, paymentType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Liabilities/{id}"))
  let req_body = {"balance": $balance, "balanceAsOfDate": $balance_as_of_date, "description": $description, "externalDestinationId": $external_destination_id, "externalSourceId": $external_source_id, "externalSourceName": $external_source_name, "factFinderId": $fact_finder_id, "frequency": $frequency, "interestRate": $interest_rate, "lastUpdated": $last_updated, "liabilityType": $liability_type, "loanDate": $loan_date, "originalPrincipal": $original_principal, "owner": $owner, "payment": $payment, "paymentType": $payment_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Liability Types for the specified country. Purpose: Provides access to the Liability Types including id and type description.
#
# GET /api/LiabilityTypes
# operationId: LiabilityTypes_GetByCountry
export def "liability-types get-by-country" [
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
  --country: string@country-completer # The country used to filter Liability Types
]: nothing -> record<liabilityTypes: table<id: int, links: list, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/LiabilityTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"country": $country} | compact), body: null}
}

# Description: This operation retrieves the Liability Type for the specified id. Purpose: Provides access to the Liability Types including id and type description.
#
# GET /api/LiabilityTypes/{id}
# operationId: LiabilityTypes_GetById
export def "liability-types get" [
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
]: nothing -> record<id: int, links: table<href: string, rel: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/LiabilityTypes/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves all Life Insurance Policies for the specified Fact Finder ID. Purpose: Provides access to the Life Insurance Policies including description and policy type.
#
# GET /api/LifeInsurancePolicies
# operationId: LifeInsurancePolicies_GetLifeInsurancePoliciesByFactFinderIdByFactfinderid
export def "life-insurance-policies get-by-fact-finder-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Life Insurance Policies (format: int32)
]: nothing -> record<lifeInsurancePolicies: table<beneficiary: string, beneficiaryDependentId: int, benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, generalAccountMarketValue: float, insurancePolicyId: int, insured: string, links: list, payer: string, policyType: int, premium: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/LifeInsurancePolicies" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: The operation creates a Life Insurance Policy. Purpose: Allows for creation of Life Insurance Policies on a Fact Finder.
#
# POST /api/LifeInsurancePolicies
# operationId: LifeInsurancePolicies_PostByModel
export def "life-insurance-policies create-by-model" [
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
  --beneficiary: string@beneficiary-completer
  --beneficiary-dependent-id: int # format: int32
  --benefit: float # format: double
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --general-account-market-value: float # format: double
  --insured: string@insured-completer-1
  --payer: string@payer-completer
  --policy-type: int # format: int32
  --premium: float # format: double
]: any -> record<beneficiary: string, beneficiaryDependentId: int, benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, generalAccountMarketValue: float, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, payer: string, policyType: int, premium: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/LifeInsurancePolicies")
  let req_body = {"beneficiary": $beneficiary, "beneficiaryDependentId": $beneficiary_dependent_id, "benefit": $benefit, "description": $description, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "frequency": $frequency, "generalAccountMarketValue": $general_account_market_value, "insured": $insured, "payer": $payer, "policyType": $policy_type, "premium": $premium} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation removes a Life Insurance Policy tied to a Fact Finder. Purpose: Allows for removal of a Life Insurance Policy and associated subaccounts from a Fact Finder.
#
# DELETE /api/LifeInsurancePolicies/{id}
# operationId: LifeInsurancePolicies_DeleteById
export def "life-insurance-policies delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/LifeInsurancePolicies/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Life Insurance Policy for the specified Life Insurance Policy ID. Purpose: Provides access to the Life Insurance Policy including description and policy type.
#
# GET /api/LifeInsurancePolicies/{id}
# operationId: LifeInsurancePolicies_GetById
export def "life-insurance-policies get" [
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
]: nothing -> record<beneficiary: string, beneficiaryDependentId: int, benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, generalAccountMarketValue: float, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, payer: string, policyType: int, premium: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/LifeInsurancePolicies/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates a Life Insurance Policy, deletes associated sub-accounts if the policy type changes. Purpose: Allows for complete replacement of a Life Insurance Policy on a Fact Finder.
#
# PUT /api/LifeInsurancePolicies/{id}
# operationId: LifeInsurancePolicies_PutByIdModel
export def "life-insurance-policies update-by-model" [
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
  --beneficiary: string@beneficiary-completer
  --beneficiary-dependent-id: int # format: int32
  --benefit: float # format: double
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --general-account-market-value: float # format: double
  --insured: string@insured-completer-1
  --payer: string@payer-completer
  --policy-type: int # format: int32
  --premium: float # format: double
]: any -> record<beneficiary: string, beneficiaryDependentId: int, benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, generalAccountMarketValue: float, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, payer: string, policyType: int, premium: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/LifeInsurancePolicies/{id}"))
  let req_body = {"beneficiary": $beneficiary, "beneficiaryDependentId": $beneficiary_dependent_id, "benefit": $benefit, "description": $description, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "frequency": $frequency, "generalAccountMarketValue": $general_account_market_value, "insured": $insured, "payer": $payer, "policyType": $policy_type, "premium": $premium} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: Get all the subaccounts for an existing Life Insurance Policy. Purpose: Provides access to all the Life Insurance Policy subaccounts.
#
# GET /api/LifeInsurancePolicies/{lifeInsurancePolicyId}/Subaccounts
# operationId: LifeInsurancePolicies_GetSubaccountsByLifeinsurancepolicyid
export def "life-insurance-policies-subaccounts list" [
  life_insurance_policy_id: int
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
]: nothing -> record<lifeInsurancePolicySubaccounts: table<description: string, externalDestinationId: string, lifeInsurancePolicyId: int, lifeInsurancePolicySubaccountId: int, marketValue: float, symbol: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($life_insurance_policy_id | is-empty) { error make --unspanned { msg: "path parameter 'lifeInsurancePolicyId' must be non-empty" } }
  let full_url = (build-url $base ({life_insurance_policy_id: (encode-path-segment $life_insurance_policy_id)} | format pattern "/api/LifeInsurancePolicies/{life_insurance_policy_id}/Subaccounts"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: Creates a subaccount and adds it to an existing Life Insurance Policy. Purpose: Allows for creation of subaccount on a Life Insurance Policy.
#
# POST /api/LifeInsurancePolicies/{lifeInsurancePolicyId}/Subaccounts
# operationId: LifeInsurancePolicies_PostSubaccountByLifeinsurancepolicyidModel
export def "life-insurance-policies-subaccounts create-by-model" [
  life_insurance_policy_id: int
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
  description: string
  --external-destination-id: string
  --market-value: float # format: double
  --symbol: string
]: any -> record<description: string, externalDestinationId: string, lifeInsurancePolicyId: int, lifeInsurancePolicySubaccountId: int, marketValue: float, symbol: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($life_insurance_policy_id | is-empty) { error make --unspanned { msg: "path parameter 'lifeInsurancePolicyId' must be non-empty" } }
  let full_url = (build-url $base ({life_insurance_policy_id: (encode-path-segment $life_insurance_policy_id)} | format pattern "/api/LifeInsurancePolicies/{life_insurance_policy_id}/Subaccounts"))
  let req_body = {"description": $description, "externalDestinationId": $external_destination_id, "marketValue": $market_value, "symbol": $symbol} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: Deletes an existing Life Insurance Policy Subaccount for an existing Life Insurance Policy. Purpose: Allows for removal of a subaccount from a Life Insurance Policy.
#
# DELETE /api/LifeInsurancePolicies/{lifeInsurancePolicyId}/Subaccounts/{id}
# operationId: LifeInsurancePolicies_DeleteSubaccountByLifeinsurancepolicyidId
export def "life-insurance-policies-subaccounts delete" [
  life_insurance_policy_id: int
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($life_insurance_policy_id | is-empty) { error make --unspanned { msg: "path parameter 'lifeInsurancePolicyId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({life_insurance_policy_id: (encode-path-segment $life_insurance_policy_id), id: (encode-path-segment $id)} | format pattern "/api/LifeInsurancePolicies/{life_insurance_policy_id}/Subaccounts/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: Get a specific subaccount for an existing Life Insurance Policy. Purpose: Provides access to the Life Insurance Policy subaccount.
#
# GET /api/LifeInsurancePolicies/{lifeInsurancePolicyId}/Subaccounts/{id}
# operationId: LifeInsurancePolicies_GetSubaccountByLifeinsurancepolicyidId
export def "life-insurance-policies-subaccounts get" [
  life_insurance_policy_id: int
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
]: nothing -> record<description: string, externalDestinationId: string, lifeInsurancePolicyId: int, lifeInsurancePolicySubaccountId: int, marketValue: float, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($life_insurance_policy_id | is-empty) { error make --unspanned { msg: "path parameter 'lifeInsurancePolicyId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({life_insurance_policy_id: (encode-path-segment $life_insurance_policy_id), id: (encode-path-segment $id)} | format pattern "/api/LifeInsurancePolicies/{life_insurance_policy_id}/Subaccounts/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: Updates an existing Life Insurance Policy Subaccount for an existing Life Insurance Policy. Purpose: Allows for complete replacement of a subaccount on a Life Insurance Policy.
#
# PUT /api/LifeInsurancePolicies/{lifeInsurancePolicyId}/Subaccounts/{id}
# operationId: LifeInsurancePolicies_PutSubaccountByLifeinsurancepolicyidIdModel
export def "life-insurance-policies-subaccounts update-by-model" [
  life_insurance_policy_id: int
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
  description: string
  --external-destination-id: string
  --market-value: float # format: double
  --symbol: string
]: any -> record<description: string, externalDestinationId: string, marketValue: float, symbol: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($life_insurance_policy_id | is-empty) { error make --unspanned { msg: "path parameter 'lifeInsurancePolicyId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({life_insurance_policy_id: (encode-path-segment $life_insurance_policy_id), id: (encode-path-segment $id)} | format pattern "/api/LifeInsurancePolicies/{life_insurance_policy_id}/Subaccounts/{id}"))
  let req_body = {"description": $description, "externalDestinationId": $external_destination_id, "marketValue": $market_value, "symbol": $symbol} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Life Insurance Policy Types for the specified country. Purpose: Provides access to the Life Insurance Policy Types including id and type description.
#
# GET /api/LifeInsurancePolicyTypes
# operationId: LifeInsurancePolicyTypes_GetByCountry
export def "life-insurance-policy-types get-by-country" [
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
  --country: string@country-completer # The country used to filter Life Insurance Policy Types
]: nothing -> record<insurancePolicyTypes: table<id: int, links: list, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/LifeInsurancePolicyTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"country": $country} | compact), body: null}
}

# Description: This operation retrieves the Life Insurance Policy Type for the specified id. Purpose: Provides access to the Life Insurance Policy Types including id and type description.
#
# GET /api/LifeInsurancePolicyTypes/{id}
# operationId: LifeInsurancePolicyTypes_GetById
export def "life-insurance-policy-types get" [
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
]: nothing -> record<id: int, links: table<href: string, rel: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/LifeInsurancePolicyTypes/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves all Lifestyle Asset Types for the specified country. Purpose: Provides access to the Lifestyle Asset Types including id and type description.
#
# GET /api/LifestyleAssetTypes
# operationId: LifestyleAssetTypes_GetByCountry
export def "lifestyle-asset-types get-by-country" [
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
  --country: string@country-completer # The country used to filter Lifestyle Asset Types
]: nothing -> record<lifestyleAssetTypes: table<id: int, links: list, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/LifestyleAssetTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"country": $country} | compact), body: null}
}

# Description: This operation retrieves the Lifestyle Asset Type for the specified id. Purpose: Provides access to the Lifestyle Asset Types including id and type description.
#
# GET /api/LifestyleAssetTypes/{id}
# operationId: LifestyleAssetTypes_GetById
export def "lifestyle-asset-types get" [
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
]: nothing -> record<id: int, links: table<href: string, rel: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/LifestyleAssetTypes/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves all Lifestyle Assets for the specified Fact Finder ID. Purpose: Provides access to the Lifestyle Assets including description and market value.
#
# GET /api/LifestyleAssets
# operationId: LifestyleAssets_GetLifestyleAssetsByFactFinderIdByFactfinderid
export def "lifestyle-assets get-by-fact-finder-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Lifestyle Assets (format: int32)
]: nothing -> record<lifestyleAssets: table<description: string, externalDestinationId: string, factFinderId: int, lifestyleAssetId: int, links: list, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, type: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/LifestyleAssets" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: The operation creates a Lifestyle Asset. Purpose: Allows for creation of Lifestyle Assets on a Fact Finder.
#
# POST /api/LifestyleAssets
# operationId: LifestyleAssets_PostByModel
export def "lifestyle-assets create-by-model" [
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
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --market-value: float # format: double
  --owner: string@owner-completer-2
  --purchase-amount: float # format: double
  --purchase-date: string # format: date-time
  --type: int # format: int32
]: any -> record<description: string, externalDestinationId: string, factFinderId: int, lifestyleAssetId: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, type: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/LifestyleAssets")
  let req_body = {"description": $description, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "marketValue": $market_value, "owner": $owner, "purchaseAmount": $purchase_amount, "purchaseDate": $purchase_date, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation removes a Lifestyle Asset tied to a Fact Finder. Purpose: Allows for removal of a Lifestyle Asset from a Fact Finder.
#
# DELETE /api/LifestyleAssets/{id}
# operationId: LifestyleAssets_DeleteById
export def "lifestyle-assets delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/LifestyleAssets/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Lifestyle Asset for the specified Lifestyle Asset ID. Purpose: Provides access to the Lifestyle Asset including description and market value.
#
# GET /api/LifestyleAssets/{id}
# operationId: LifestyleAssets_GetById
export def "lifestyle-assets get" [
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
]: nothing -> record<description: string, externalDestinationId: string, factFinderId: int, lifestyleAssetId: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/LifestyleAssets/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates a Lifestyle Asset. Purpose: Allows for complete replacement of a Lifestyle Asset on a Fact Finder.
#
# PUT /api/LifestyleAssets/{id}
# operationId: LifestyleAssets_PutByIdModel
export def "lifestyle-assets update-by-model" [
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
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --market-value: float # format: double
  --owner: string@owner-completer-2
  --purchase-amount: float # format: double
  --purchase-date: string # format: date-time
  --type: int # format: int32
]: any -> record<description: string, externalDestinationId: string, factFinderId: int, lifestyleAssetId: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, type: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/LifestyleAssets/{id}"))
  let req_body = {"description": $description, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "marketValue": $market_value, "owner": $owner, "purchaseAmount": $purchase_amount, "purchaseDate": $purchase_date, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Long Term Care Insurance Policies for the specified Fact Finder ID. Purpose: Provides access to the Long Term Care Insurance Policies including description and premium.
#
# GET /api/LongTermCareInsurancePolicies
# operationId: LongTermCareInsurancePolicies_GetLongTermCareInsurancePoliciesByFactFinderIdByFactfinderid
export def "long-term-care-insurance-policies get-by-fact-finder-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Long Term Care Insurance Policies (format: int32)
]: nothing -> record<longTermCareInsurancePolicies: table<benefit: float, benefitFrequency: int, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: list, premium: float, premiumFrequency: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/LongTermCareInsurancePolicies" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: The operation creates a Long Term Care Insurance Policy. Purpose: Allows for creation of Long Term Care Insurance Policies on a Fact Finder.
#
# POST /api/LongTermCareInsurancePolicies
# operationId: LongTermCareInsurancePolicies_PostByModel
export def "long-term-care-insurance-policies create-by-model" [
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
  --benefit: float # format: double
  --benefit-frequency: int # format: int32
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --insured: string@insured-completer
  --premium: float # format: double
  --premium-frequency: int # format: int32
]: any -> record<benefit: float, benefitFrequency: int, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, premium: float, premiumFrequency: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/LongTermCareInsurancePolicies")
  let req_body = {"benefit": $benefit, "benefitFrequency": $benefit_frequency, "description": $description, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "insured": $insured, "premium": $premium, "premiumFrequency": $premium_frequency} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation removes a Long Term Care Insurance Policy tied to a Fact Finder. Purpose: Allows for removal of a Long Term Care Insurance Policy from a Fact Finder.
#
# DELETE /api/LongTermCareInsurancePolicies/{id}
# operationId: LongTermCareInsurancePolicies_DeleteById
export def "long-term-care-insurance-policies delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/LongTermCareInsurancePolicies/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Long Term Care Insurance Policy for the specified Long Term Care Insurance Policy ID. Purpose: Provides access to the Long Term Care Insurance Policy including description and premium.
#
# GET /api/LongTermCareInsurancePolicies/{id}
# operationId: LongTermCareInsurancePolicies_GetById
export def "long-term-care-insurance-policies get" [
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
]: nothing -> record<benefit: float, benefitFrequency: int, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, premium: float, premiumFrequency: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/LongTermCareInsurancePolicies/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates a Long Term Care Insurance Policy. Purpose: Allows for complete replacement of a Long Term Care Insurance Policy on a Fact Finder.
#
# PUT /api/LongTermCareInsurancePolicies/{id}
# operationId: LongTermCareInsurancePolicies_PutByIdModel
export def "long-term-care-insurance-policies update-by-model" [
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
  --benefit: float # format: double
  --benefit-frequency: int # format: int32
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --insured: string@insured-completer
  --premium: float # format: double
  --premium-frequency: int # format: int32
]: any -> record<benefit: float, benefitFrequency: int, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, premium: float, premiumFrequency: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/LongTermCareInsurancePolicies/{id}"))
  let req_body = {"benefit": $benefit, "benefitFrequency": $benefit_frequency, "description": $description, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "insured": $insured, "premium": $premium, "premiumFrequency": $premium_frequency} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Major Purchase Goal Types for the specified country. Purpose: Provides access to the Major Purchase Goal Types including id and type description.
#
# GET /api/MajorPurchaseGoalTypes
# operationId: MajorPurchaseGoalTypes_GetByCountry
export def "major-purchase-goal-types get-by-country" [
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
  --country: string@country-completer # The country used to filter Major Purchase Goal Types
]: nothing -> record<majorPurchaseGoalTypes: table<description: string, links: list, majorPurchaseGoalTypeId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/MajorPurchaseGoalTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"country": $country} | compact), body: null}
}

# Description: This operation retrieves the Major Purchase Goal Type for the specified id. Purpose: Provides access to the Major Purchase Goal Types including id and type description.
#
# GET /api/MajorPurchaseGoalTypes/{id}
# operationId: MajorPurchaseGoalTypes_GetById
export def "major-purchase-goal-types get" [
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
]: nothing -> record<description: string, links: table<href: string, rel: string>, majorPurchaseGoalTypeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/MajorPurchaseGoalTypes/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves all Major Purchases for the specified Fact Finder ID. Purpose: Provides access to the Major Purchases including description and amount.
#
# GET /api/MajorPurchaseGoals
# operationId: MajorPurchaseGoals_GetMajorPurchaseGoalsByFactFinderIdByFactfinderid
export def "major-purchase-goals get-by-fact-finder-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Major Purchases (format: int32)
]: nothing -> record<majorPurchaseGoals: table<amount: float, description: string, externalDestinationId: string, factFinderId: int, links: list, majorPurchaseGoalId: int, majorPurchaseGoalTypeId: int, member: string, targetDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/MajorPurchaseGoals" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: The operation creates a Major Purchase. Purpose: Allows for creation of Major Purchases on a Fact Finder.
#
# POST /api/MajorPurchaseGoals
# operationId: MajorPurchaseGoals_PostByModel
export def "major-purchase-goals create-by-model" [
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
  --amount: float # format: double
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --major-purchase-goal-type-id: int # format: int32
  --member: string@member-completer-2
  --target-date: string # format: date-time
]: any -> record<amount: float, description: string, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, majorPurchaseGoalId: int, majorPurchaseGoalTypeId: int, member: string, targetDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/MajorPurchaseGoals")
  let req_body = {"amount": $amount, "description": $description, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "majorPurchaseGoalTypeId": $major_purchase_goal_type_id, "member": $member, "targetDate": $target_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation removes a Major Purchase tied to a Fact Finder. Purpose: Allows for removal of a Major Purchase from a Fact Finder.
#
# DELETE /api/MajorPurchaseGoals/{id}
# operationId: MajorPurchaseGoals_DeleteById
export def "major-purchase-goals delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/MajorPurchaseGoals/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Major Purchase for the specified Major Purchase ID. Purpose: Provides access to the Major Purchase including description and amount.
#
# GET /api/MajorPurchaseGoals/{id}
# operationId: MajorPurchaseGoals_GetById
export def "major-purchase-goals get" [
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
]: nothing -> record<amount: float, description: string, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, majorPurchaseGoalId: int, majorPurchaseGoalTypeId: int, member: string, targetDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/MajorPurchaseGoals/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates a Major Purchase. Purpose: Allows for complete replacement of a Major Purchase on a Fact Finder.
#
# PUT /api/MajorPurchaseGoals/{id}
# operationId: MajorPurchaseGoals_PutByIdModel
export def "major-purchase-goals update-by-model" [
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
  --amount: float # format: double
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --major-purchase-goal-type-id: int # format: int32
  --member: string@member-completer-2
  --target-date: string # format: date-time
]: any -> record<amount: float, description: string, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, majorPurchaseGoalId: int, majorPurchaseGoalTypeId: int, member: string, targetDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/MajorPurchaseGoals/{id}"))
  let req_body = {"amount": $amount, "description": $description, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "majorPurchaseGoalTypeId": $major_purchase_goal_type_id, "member": $member, "targetDate": $target_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all current Accounts for the specified Fact Finder ID, as well as all of the holdings and savings strategies belonging to those accounts. Purpose: Provides access to the Accounts in a Fact Finder as well as any sub-entities belonging to them.
#
# GET /api/Presentation/Accounts
# operationId: Presentation_GetAccountsByFactfinderidExternalsourceid
export def "presentation-accounts get-by-factfinderid-externalsourceid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Accounts (format: int32)
  --external-source-id: string # The external ID used to filter Accounts
]: nothing -> record<accounts: table<accountId: int, accountType: int, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, holdings: list, lastUpdated: string, links: list, marketValue: float, owner: string, ownerDependentId: int, savingsStrategies: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar") (serialize-qp "externalSourceId" $external_source_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Presentation/Accounts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id, "externalSourceId": $external_source_id} | compact), body: null}
}

# Description: This operation retrieves owner values for the fact finder based on demographics data Purpose: Provides the list of valid options for owner, student, beneficiary, etc.
#
# GET /api/Presentation/Demographics/Owners
# operationId: Presentation_GetDemographicOwnersByFactfinderid
export def "presentation-demographics-owners get-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve owners. (format: int32)
]: nothing -> record<owners: table<displayName: string, owner: string, ownerDependentId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Presentation/Demographics/Owners" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: This operation retrieves all relationship types relevant to demographics. Purpose: Provides a list of relationship types organized by whether or not they can be defined as children.
#
# GET /api/Presentation/Demographics/Relationships
# operationId: Presentation_GetDemographicRelationships
export def "presentation-demographics-relationships get" [
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
]: nothing -> record<relationshipTypes: table<id: int, isChildType: bool, relationshipType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Presentation/Demographics/Relationships")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves all current Incomes for the specified Fact Finder ID. Purpose: Provides access to the Incomes in a Fact Finder, filtered by Incomes that are current.
#
# GET /api/Presentation/Incomes
# operationId: Presentation_GetIncomesByFactfinderid
export def "presentation-incomes get-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Incomes (format: int32)
]: nothing -> record<incomes: table<annualAmount: float, description: string, endDate: string, externalDestinationId: string, factFinderId: int, incomeId: int, incomeTypeId: int, links: list, owner: string, startDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Presentation/Incomes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: This operation retrieves all current Liabilities for the specified Fact Finder ID. Purpose: Provides access to the Liabilities in a Fact Finder, filtered by Liabilities that are current.
#
# GET /api/Presentation/Liabilities
# operationId: Presentation_GetLiabilitiesByFactfinderid
export def "presentation-liabilities get-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Liabilities (format: int32)
]: nothing -> record<liabilities: table<balance: float, balanceAsOfDate: string, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, frequency: int, interestRate: float, lastUpdated: string, liabilityId: int, liabilityType: int, links: list, loanDate: string, originalPrincipal: float, owner: string, payment: float, paymentType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Presentation/Liabilities" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: This operation retrieves all life insurance policies, including subaccounts if available, for the specified Fact Finder ID. Purpose: Provides access to the Life Insurance Policies in a Fact Finder.
#
# GET /api/Presentation/LifeInsurancePolicies
# operationId: Presentation_GetLifeInsurancePoliciesByFactfinderid
export def "presentation-life-insurance-policies get-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Life Insurance Policies. (format: int32)
]: nothing -> record<lifeInsurancePolicies: table<beneficiary: string, beneficiaryDependentId: int, benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, generalAccountMarketValue: float, insurancePolicyId: int, insured: string, links: list, payer: string, policyType: int, premium: float, subaccounts: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Presentation/LifeInsurancePolicies" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: This operation retrieves all future Defined Benefit Pensions for the specified Fact Finder ID. Purpose: Provides access to the Pensions in a Fact Finder, filtered by Pensions that are in the future.
#
# GET /api/Presentation/Pensions
# operationId: Presentation_GetPensionsByFactfinderid
export def "presentation-pensions get-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Pensions. (format: int32)
]: nothing -> record<definedBenefitPensions: table<definedBenefitPensionId: int, description: string, estimatedAmount: float, externalDestinationId: string, factFinderId: int, links: list, member: string, startDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Presentation/Pensions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: This operation retrieves all Real Estate Assets for the specified Fact Finder ID. Purpose: Provides access to the Real Estate Assets including description and market value.
#
# GET /api/RealEstateAssets
# operationId: RealEstateAssets_GetRealEstateAssetsByFactFinderIdByFactfinderid
export def "real-estate-assets get-by-fact-finder-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Real Estate Assets (format: int32)
]: nothing -> record<realEstateAssets: table<description: string, externalDestinationId: string, factFinderId: int, frequency: int, links: list, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, realEstateAssetId: int, rentalIncome: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/RealEstateAssets" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: The operation creates a Real Estate Asset. Purpose: Allows for creation of Real Estate Assets on a Fact Finder.
#
# POST /api/RealEstateAssets
# operationId: RealEstateAssets_PostByModel
export def "real-estate-assets create-by-model" [
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
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --market-value: float # format: double
  --owner: string@owner-completer-2
  --purchase-amount: float # format: double
  --purchase-date: string # format: date-time
  --rental-income: float # format: double
]: any -> record<description: string, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, realEstateAssetId: int, rentalIncome: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/RealEstateAssets")
  let req_body = {"description": $description, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "frequency": $frequency, "marketValue": $market_value, "owner": $owner, "purchaseAmount": $purchase_amount, "purchaseDate": $purchase_date, "rentalIncome": $rental_income} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation removes a Real Estate Asset tied to a Fact Finder. Purpose: Allows for removal of a Real Estate Asset from a Fact Finder.
#
# DELETE /api/RealEstateAssets/{id}
# operationId: RealEstateAssets_DeleteById
export def "real-estate-assets delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/RealEstateAssets/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Real Estate Asset for the specified Real Estate Asset ID. Purpose: Provides access to the Real Estate Asset including description and market value.
#
# GET /api/RealEstateAssets/{id}
# operationId: RealEstateAssets_GetById
export def "real-estate-assets get" [
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
]: nothing -> record<description: string, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, realEstateAssetId: int, rentalIncome: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/RealEstateAssets/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates a Real Estate Asset. Purpose: Allows for complete replacement of a Real Estate Asset on a Fact Finder.
#
# PUT /api/RealEstateAssets/{id}
# operationId: RealEstateAssets_PutByIdModel
export def "real-estate-assets update-by-model" [
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
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --market-value: float # format: double
  --owner: string@owner-completer-2
  --purchase-amount: float # format: double
  --purchase-date: string # format: date-time
  --rental-income: float # format: double
]: any -> record<description: string, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, realEstateAssetId: int, rentalIncome: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/RealEstateAssets/{id}"))
  let req_body = {"description": $description, "externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "frequency": $frequency, "marketValue": $market_value, "owner": $owner, "purchaseAmount": $purchase_amount, "purchaseDate": $purchase_date, "rentalIncome": $rental_income} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Retirement Goals for the specified Fact Finder ID. Purpose: Provides access to the Retirement Goals including retirement date.
#
# GET /api/RetirementGoals
# operationId: RetirementGoals_GetRetirementGoalsByFactFinderIdByFactfinderid
export def "retirement-goals get-by-fact-finder-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Retirement Goals (format: int32)
]: nothing -> record<retirementGoals: table<externalDestinationId: string, factFinderId: int, head1RetirementDate: string, head2RetirementDate: string, links: list, retirementGoalId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "factFinderId" $fact_finder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/RetirementGoals" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"factFinderId": $fact_finder_id} | compact), body: null}
}

# Description: The operation creates a Retirement Goal. Purpose: Allows for creation of Retirement Goals on a Fact Finder.
#
# POST /api/RetirementGoals
# operationId: RetirementGoals_PostByModel
export def "retirement-goals create-by-model" [
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
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --head1-retirement-date: string # format: date-time
  --head2-retirement-date: string # format: date-time
]: any -> record<externalDestinationId: string, factFinderId: int, head1RetirementDate: string, head2RetirementDate: string, links: table<href: string, rel: string>, retirementGoalId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/RetirementGoals")
  let req_body = {"externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "head1RetirementDate": $head1_retirement_date, "head2RetirementDate": $head2_retirement_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation removes a Retirement Goal tied to a Fact Finder. Purpose: Allows for removal of a Retirement Goal from a Fact Finder.
#
# DELETE /api/RetirementGoals/{id}
# operationId: RetirementGoals_DeleteById
export def "retirement-goals delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/RetirementGoals/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Retirement Goal for the specified Retirement Goal ID. Purpose: Provides access to the Retirement Goal including retirement date.
#
# GET /api/RetirementGoals/{id}
# operationId: RetirementGoals_GetById
export def "retirement-goals get" [
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
]: nothing -> record<externalDestinationId: string, factFinderId: int, head1RetirementDate: string, head2RetirementDate: string, links: table<href: string, rel: string>, retirementGoalId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/RetirementGoals/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates a Retirement Goal. Purpose: Allows for complete replacement of a Retirement Goal on a Fact Finder.
#
# PUT /api/RetirementGoals/{id}
# operationId: RetirementGoals_PutByIdModel
export def "retirement-goals update-by-model" [
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
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --head1-retirement-date: string # format: date-time
  --head2-retirement-date: string # format: date-time
]: any -> record<externalDestinationId: string, factFinderId: int, head1RetirementDate: string, head2RetirementDate: string, links: table<href: string, rel: string>, retirementGoalId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/RetirementGoals/{id}"))
  let req_body = {"externalDestinationId": $external_destination_id, "factFinderId": $fact_finder_id, "head1RetirementDate": $head1_retirement_date, "head2RetirementDate": $head2_retirement_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves all Retirement Goal Expenses for the specified Retirement Goal ID. Purpose: Provides access to the Retirement Goal Expenses including description and amount.
#
# GET /api/RetirementGoals/{retirementGoalId}/Expenses
# operationId: RetirementGoals_GetRetirementExpensesByRetirementGoalIdByRetirementgoalid
export def "retirement-goals-expenses get-by" [
  retirement_goal_id: int
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
]: nothing -> record<retirementExpenses: table<amount: float, annualPeriod: int, description: string, endDate: string, externalDestinationId: string, frequency: int, links: list, member: string, retirementExpenseId: int, retirementGoalId: int, startDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($retirement_goal_id | is-empty) { error make --unspanned { msg: "path parameter 'retirementGoalId' must be non-empty" } }
  let full_url = (build-url $base ({retirement_goal_id: (encode-path-segment $retirement_goal_id)} | format pattern "/api/RetirementGoals/{retirement_goal_id}/Expenses"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation creates a Retirement Goal Expense. Purpose: Allows for creation of Retirement Goal Expenses on a Fact Finder.
#
# POST /api/RetirementGoals/{retirementGoalId}/Expenses
# operationId: RetirementGoals_PostByRetirementgoalidModel
export def "retirement-goals-expenses create-by-model" [
  retirement_goal_id: int
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
  --amount: float # format: double
  --annual-period: int # format: int32
  description: string
  --end-date: string # format: date-time
  --external-destination-id: string
  --frequency: int # format: int32
  --member: string@member-completer-2
  --start-date: string # format: date-time
]: any -> record<amount: float, annualPeriod: int, description: string, endDate: string, externalDestinationId: string, frequency: int, links: table<href: string, rel: string>, member: string, retirementExpenseId: int, retirementGoalId: int, startDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($retirement_goal_id | is-empty) { error make --unspanned { msg: "path parameter 'retirementGoalId' must be non-empty" } }
  let full_url = (build-url $base ({retirement_goal_id: (encode-path-segment $retirement_goal_id)} | format pattern "/api/RetirementGoals/{retirement_goal_id}/Expenses"))
  let req_body = {"amount": $amount, "annualPeriod": $annual_period, "description": $description, "endDate": $end_date, "externalDestinationId": $external_destination_id, "frequency": $frequency, "member": $member, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: The operation removes a Retirement Goal Expense tied to a Fact Finder. Purpose: Allows for removal of a Retirement Goal Expense from a Fact Finder.
#
# DELETE /api/RetirementGoals/{retirementGoalId}/Expenses/{id}
# operationId: RetirementGoals_DeleteByRetirementgoalidId
export def "retirement-goals-expenses delete" [
  retirement_goal_id: int
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($retirement_goal_id | is-empty) { error make --unspanned { msg: "path parameter 'retirementGoalId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({retirement_goal_id: (encode-path-segment $retirement_goal_id), id: (encode-path-segment $id)} | format pattern "/api/RetirementGoals/{retirement_goal_id}/Expenses/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves a single Retirement Goal Expense for the specified Retirement Goal Expense ID. Purpose: Provides access to the Retirement Goal Expense including description and amount.
#
# GET /api/RetirementGoals/{retirementGoalId}/Expenses/{id}
# operationId: RetirementGoals_GetRetirementExpenseByRetirementgoalidId
export def "retirement-goals-expenses get" [
  retirement_goal_id: int
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
]: nothing -> record<amount: float, annualPeriod: int, description: string, endDate: string, externalDestinationId: string, frequency: int, links: table<href: string, rel: string>, member: string, retirementExpenseId: int, retirementGoalId: int, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($retirement_goal_id | is-empty) { error make --unspanned { msg: "path parameter 'retirementGoalId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({retirement_goal_id: (encode-path-segment $retirement_goal_id), id: (encode-path-segment $id)} | format pattern "/api/RetirementGoals/{retirement_goal_id}/Expenses/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: The operation updates a Retirement Goal Expense. Purpose: Allows for complete replacement of a Retirement Goal Expense on a Fact Finder.
#
# PUT /api/RetirementGoals/{retirementGoalId}/Expenses/{id}
# operationId: RetirementGoals_PutByRetirementgoalidIdModel
export def "retirement-goals-expenses update-by-model" [
  retirement_goal_id: int
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
  --amount: float # format: double
  --annual-period: int # format: int32
  description: string
  --end-date: string # format: date-time
  --external-destination-id: string
  --frequency: int # format: int32
  --member: string@member-completer-2
  --start-date: string # format: date-time
]: any -> record<amount: float, annualPeriod: int, description: string, endDate: string, externalDestinationId: string, frequency: int, links: table<href: string, rel: string>, member: string, retirementExpenseId: int, retirementGoalId: int, startDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($retirement_goal_id | is-empty) { error make --unspanned { msg: "path parameter 'retirementGoalId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({retirement_goal_id: (encode-path-segment $retirement_goal_id), id: (encode-path-segment $id)} | format pattern "/api/RetirementGoals/{retirement_goal_id}/Expenses/{id}"))
  let req_body = {"amount": $amount, "annualPeriod": $annual_period, "description": $description, "endDate": $end_date, "externalDestinationId": $external_destination_id, "frequency": $frequency, "member": $member, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Description: This operation retrieves information statistics for the current service. Purpose: Provides access to Service Information.
#
# GET /api/ServiceInformation
# operationId: FactFinderServiceInformation_Get
export def "service-information get-fact-finder" [
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
]: nothing -> record<name: string, schemaVersion: int, serviceVersion: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/ServiceInformation")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Description: This operation retrieves all States and Provinces for the specified country. Purpose: Provides access to the States and Provinces.
#
# GET /api/StatesProvinces
# operationId: StatesProvinces_GetByCountry
export def "states-provinces get-by-country" [
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
  --country: string@country-completer # The country used to filter States and Provinces
]: nothing -> record<statesProvinces: table<links: list, stateProvinceId: int, stateProvinceName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/StatesProvinces" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"country": $country} | compact), body: null}
}

# Description: This operation retrieves the States and Provinces for the specified id. Purpose: Provides access to the States and Provinces.
#
# GET /api/StatesProvinces/{id}
# operationId: StatesProvinces_GetById
export def "states-provinces get" [
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
]: nothing -> record<links: table<href: string, rel: string>, stateProvinceId: int, stateProvinceName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/StatesProvinces/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
