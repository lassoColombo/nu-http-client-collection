# Auto-generated client for NaviPlan API vv1
# Source: https://api.apis.guru/v2/specs/naviplancentral.com/plan/v1/swagger.json
# Auth: --token flag or $env.NAVIPLAN_API_TOKEN

const BASE_URL = "https://demo.uat.naviplancentral.com/plan"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o NAVIPLAN_API_TOKEN | default "" }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://demo.uat.naviplancentral.com/plan" "http://demo.uat.naviplancentral.com/plan"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "advisors get" } } | get name | first)
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

# Retrieve Advisors
#
# GET /api/Advisors
# operationId: Advisors_Get
export def "advisors get" [
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
]: nothing -> record<advisors: table<addressLine1: string, addressLine2: string, advisorId: string, advisorTitle: string, businessPhone: string, cellPhone: string, city: string, emailAddress: string, faxPhone: string, firstName: string, homePhone: string, lastName: string, links: list, middleName: string, officeName: string, officeWebsite: string, pagerNumber: string, postalCode: string, stateProvince: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Advisors" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Retrieve Advisors for a Client
#
# GET /api/Advisors/{householdId}/{clientId}
# operationId: Advisors_GetByHouseholdidClientid
export def "advisors get-by-household-id-client-id" [
  household_id: int
  client_id: string
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
]: nothing -> record<advisors: table<addressLine1: string, addressLine2: string, advisorId: string, advisorTitle: string, businessPhone: string, cellPhone: string, city: string, emailAddress: string, faxPhone: string, firstName: string, homePhone: string, lastName: string, links: list, middleName: string, officeName: string, officeWebsite: string, pagerNumber: string, postalCode: string, stateProvince: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($household_id | is-empty) { error make --unspanned { msg: "path parameter 'householdId' must be non-empty" } }
  if ($client_id | is-empty) { error make --unspanned { msg: "path parameter 'clientId' must be non-empty" } }
  let full_url = (build-url $base ({household_id: (encode-path-segment $household_id), client_id: (encode-path-segment $client_id)} | format pattern "/api/Advisors/{household_id}/{client_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Retrieve an Advisor
#
# GET /api/Advisors/{id}
# operationId: Advisors_GetById
export def "advisors get-by-id" [
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
]: nothing -> record<addressLine1: string, addressLine2: string, advisorId: string, advisorTitle: string, businessPhone: string, cellPhone: string, city: string, emailAddress: string, faxPhone: string, firstName: string, homePhone: string, lastName: string, links: table<href: string, rel: string>, middleName: string, officeName: string, officeWebsite: string, pagerNumber: string, postalCode: string, stateProvince: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Advisors/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Retrieve plan assumptions
#
# GET /api/Assumptions
# operationId: Assumptions_GetByPlanid
export def "assumptions get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<assumptions: record<anyHeadAlreadyRetired: bool, bothRetired: bool, bucketing: record<distributionBucketTargetBalance: record, endDate: record, indexedAt: record, returnRate: record, standardDeviation: record, startDate: record>, client: record<alreadyRetired: bool, deceasedAge: int, deceasedDate: record, estateIncomeTaxes: record, governmentPensions: record, maritalOrTaxFilingStatus: record, preRetirementIncomeTaxes: record, retirementAge: int, retirementDate: record, retirementIncomeTaxes: record>, coClient: record<alreadyRetired: bool, deceasedAge: int, deceasedDate: record, estateIncomeTaxes: record, governmentPensions: record, maritalOrTaxFilingStatus: record, preRetirementIncomeTaxes: record, retirementAge: int, retirementDate: record, retirementIncomeTaxes: record>, firstToDieDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, firstToDieMember: string, firstToRetireDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, inflationRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, lastToDieDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, lastToDieMember: string, lastToRetireDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, retirementYearAdjustedIfAlreadyRetired: record<raw: int>, splitSurplusSavingsStrategiesEnabled: bool, taxMethod: string>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Assumptions" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve business entities
#
# GET /api/BusinessEntities
# operationId: BusinessEntities_GetByPlanid
export def "business-entities list" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<businessEntities: table<activities: list, assetId: record, businessType: string, businessTypeFormatted: string, currentAnnualDistributions: record, currentAnnualDividends: record, currentAnnualGrowthRate: record, currentAnnualNetIncome: record, entityName: string, liquidationEvent: record, marketValuationDate: record, marketValue: record, owner: string, purchaseAmount: record, purchaseDate: record, standardDeviation: record>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/BusinessEntities" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve a business entity
#
# GET /api/BusinessEntities/{id}
# operationId: BusinessEntities_GetByIdPlanid
export def "business-entities get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<businessEntity: record<activities: list<record>, assetId: record<rawId: int>, businessType: string, businessTypeFormatted: string, currentAnnualDistributions: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, currentAnnualDividends: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, currentAnnualGrowthRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, currentAnnualNetIncome: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, entityName: string, liquidationEvent: record<firstSaleDate: record, lastSaleDate: record, liquidationType: string, liquidationTypeDescription: string, saleDatesDescription: string>, marketValuationDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, marketValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, owner: string, purchaseAmount: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, purchaseDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, standardDeviation: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/BusinessEntities/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve Monte Carlo results from standalone calc service
#
# GET /api/Calculations/MonteCarlo
# operationId: Calculations_GetByPlanid
export def "calculations-monte-carlo get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> oneof<bool, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Calculations/MonteCarlo" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve defined benefit pensions
#
# GET /api/DefinedBenefitPensions
# operationId: DefinedBenefitPensions_GetByPlanid
export def "defined-benefit-pensions list" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<definedBenefitPensions: table<benefit: record, description: string, isBenefitFormula: bool, isBenefitIntegratedWithCppQpp: bool, isFormulaIntegratedWithCppQpp: bool, owner: string, pensionType: string, percentPayableToSurvivor: record, projectedYearsOfService: int, startDate: record>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/DefinedBenefitPensions" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve a definedBenefitPension
#
# GET /api/DefinedBenefitPensions/{id}
# operationId: DefinedBenefitPensions_GetByIdPlanid
export def "defined-benefit-pensions get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<definedBenefitPension: record<benefit: record<enabled: bool, populated: bool, value: record>, description: string, isBenefitFormula: bool, isBenefitIntegratedWithCppQpp: bool, isFormulaIntegratedWithCppQpp: bool, owner: string, pensionType: string, percentPayableToSurvivor: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, projectedYearsOfService: int, startDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/DefinedBenefitPensions/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Accepts the EULA
#
# POST /api/Eula/Accept
# operationId: Eula_Accept
export def "eula-accept create" [
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
  let full_url = (build-url $base "/api/Eula/Accept" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve family
#
# GET /api/Family
# operationId: Family_GetByPlanid
export def "family get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<family: record<address: record<city: string, combinedCityStateProvince: string, country: string, stateOrProvince: string, stateOrProvinceAbbrev: string, street1: string, street2: string, zipOrPostalCode: string>, client: record<address: record, ageAsOfPlanDate: int, birthdate: record, citizenship: string, email: string, employer: record, gender: record, name: record, ownershipId: string, phone: record>, coClient: record<address: record, ageAsOfPlanDate: int, birthdate: record, citizenship: string, email: string, employer: record, gender: record, name: record, ownershipId: string, phone: record>, dependents: list<record>, headFullNames: string>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Family" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve the adjustments
#
# GET /api/GoalAdjustments/Education/{id}/Adjustments
# operationId: GoalAdjustments_GetEducationByIdClientidPlanid
export def "goal-adjustments-education-adjustments get-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
]: nothing -> record<adjustedValues: record<duration: float, expensesCovered: float, lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float>, created: string, goalId: int, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/GoalAdjustments/Education/{id}/Adjustments") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"clientId": $client_id, "planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Perform calculations
#
# POST /api/GoalAdjustments/Education/{id}/Calculations
# operationId: GoalAdjustments_PostEducationByIdGoaladjustmentsPlanid
# --adjustedValues shape: {duration?: float, expensesCovered?: float, lumpSumContribution?: float, lumpSumDate?: string, monthlySavingsContribution?: float}
export def "goal-adjustments-education-calculations create-by-goaladjustments-planid" [
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
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
  --adjusted-values: record # shape: {duration?: float, expensesCovered?: float, lumpSumContribution?: float, lumpSumDate?: string, monthlySavingsContribution?: float}
]: any -> record<goalAdjustments: record<adjustedValues: record<duration: float, expensesCovered: float, lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float>, created: string, goalId: int>, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/GoalAdjustments/Education/{id}/Calculations") $qp $auth.query)
  let req_body = {"adjustedValues": $adjusted_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of goals with their relevant success rates.
#
# GET /api/GoalAdjustments/GoalSuccessRates
# operationId: GoalAdjustments_GetGoalSuccessRatesByClientidPlanid
export def "goal-adjustments-goal-success-rates get-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
]: nothing -> record<goalSuccessRateResults: table<description: string, goalId: int, successRate: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/GoalAdjustments/GoalSuccessRates" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"clientId": $client_id, "planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve the adjustments
#
# GET /api/GoalAdjustments/MajorPurchase/{id}/Adjustments
# operationId: GoalAdjustments_GetMajorPurchaseByIdClientidPlanid
export def "goal-adjustments-major-purchase-adjustments get-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
]: nothing -> record<adjustedValues: record<lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float, targetDate: string, totalNeed: float>, created: string, goalId: int, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/GoalAdjustments/MajorPurchase/{id}/Adjustments") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"clientId": $client_id, "planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Perform calculations
#
# POST /api/GoalAdjustments/MajorPurchase/{id}/Calculations
# operationId: GoalAdjustments_PostMajorPurchaseByIdGoaladjustmentsPlanid
# --adjustedValues shape: {lumpSumContribution?: float, lumpSumDate?: string, monthlySavingsContribution?: float, targetDate?: string, totalNeed?: float}
export def "goal-adjustments-major-purchase-calculations create-by-goaladjustments-planid" [
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
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
  --adjusted-values: record # shape: {lumpSumContribution?: float, lumpSumDate?: string, monthlySavingsContribution?: float, targetDate?: string, totalNeed?: float}
]: any -> record<goalAdjustments: record<adjustedValues: record<lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float, targetDate: string, totalNeed: float>, created: string, goalId: int>, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/GoalAdjustments/MajorPurchase/{id}/Calculations") $qp $auth.query)
  let req_body = {"adjustedValues": $adjusted_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of goal adjustment restrictions.
#
# GET /api/GoalAdjustments/Restrictions
# operationId: GoalAdjustments_GetGoalAdjustmentRestrictionsByClientidPlanid
export def "goal-adjustments-restrictions get-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
]: nothing -> record<educationRestrictions: table<canChangeDuration: bool, goalId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/GoalAdjustments/Restrictions" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"clientId": $client_id, "planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve the adjustments
#
# GET /api/GoalAdjustments/Retirement/Adjustments
# operationId: GoalAdjustments_GetRetirementByClientidPlanid
export def "goal-adjustments-retirement-adjustments get-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
]: nothing -> record<adjustedValues: record<clientRetirementAge: float, coClientRetirementAge: float, discretionaryExpenseCoverage: float, fixedExpenseCoverage: float, lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float>, created: string, goalId: int, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/GoalAdjustments/Retirement/Adjustments" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"clientId": $client_id, "planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Perform calculations
#
# POST /api/GoalAdjustments/Retirement/Calculations
# operationId: GoalAdjustments_PostRetirementByGoaladjustmentsPlanid
# --adjustedValues shape: {clientRetirementAge?: float, coClientRetirementAge?: float, discretionaryExpenseCoverage?: float, fixedExpenseCoverage?: float, lumpSumContribution?: float, lumpSumDate?: string, monthlySavingsContribution?: float}
export def "goal-adjustments-retirement-calculations create-by-goaladjustments-planid" [
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
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
  --adjusted-values: record # shape: {clientRetirementAge?: float, coClientRetirementAge?: float, discretionaryExpenseCoverage?: float, fixedExpenseCoverage?: float, lumpSumContribution?: float, lumpSumDate?: string, monthlySavingsContribution?: float}
]: any -> record<goalAdjustments: record<adjustedValues: record<clientRetirementAge: float, coClientRetirementAge: float, discretionaryExpenseCoverage: float, fixedExpenseCoverage: float, lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float>, created: string, goalId: int>, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/GoalAdjustments/Retirement/Calculations" $qp $auth.query)
  let req_body = {"adjustedValues": $adjusted_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns WAMO values for current goal
#
# GET /api/GoalAdjustments/{id}/WhatAreMyOptions
# operationId: GoalAdjustments_GetWhatAreMyOptionsByIdClientidPlanid
export def "goal-adjustments-what-are-my-options get-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
]: nothing -> record<additionalMonthlySavings: float, clientRetirementAge: int, clientRetirementAgeDate: string, coClientRetirementAge: int, coClientRetirementAgeDate: string, expenseCoverageDollars: float, expenseCoveragePercentage: float, lumpSumSavings: float, purchaseDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/GoalAdjustments/{id}/WhatAreMyOptions") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"clientId": $client_id, "planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve goals
#
# GET /api/Goals
# operationId: Goals_GetByPlanid
export def "goals list" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<goals: table<assetsRemainingAfterFundingGoal: record, coverage: record, description: string, endDate: record, identifier: record, startDate: record, type: string, yearAssetsDepleted: record>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Goals" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve goals
#
# GET /api/Goals/{id}
# operationId: Goals_GetByIdPlanid
export def "goals get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<goal: record<assetsRemainingAfterFundingGoal: record<enabled: bool, populated: bool, value: record>, coverage: record<enabled: bool, populated: bool, value: record>, description: string, endDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, identifier: record<id: int>, startDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, type: string, yearAssetsDepleted: record<enabled: bool, populated: bool, value: record>>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Goals/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve holding companies
#
# GET /api/HoldingCompanies
# operationId: HoldingCompanies_GetByPlanid
export def "holding-companies list" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<holdingCompanies: table<annualDividendYield: record, ccpc: record, commonSharesOutstanding: int, contributions: record, corporateYearEnd: record, description: string, dividendType: string, dividendTypeFormatted: string, estateDetails: record, historicalData: record, id: string, investmentAccounts: list, liabilities: list, lifeInsurancePolicies: list, marketValue: record, numPreferredShareClasses: int, otherAssets: list, ownershipAsOfDate: record, ownershipDetails: record, preferredSharesOutstanding: int, provinceOfIncorporation: string, provinceOfTaxation: string, realEstateAssets: list, valueOfAllCommonShares: record, valueOfAllPreferredShares: record, withdrawals: record>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/HoldingCompanies" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve a holding company
#
# GET /api/HoldingCompanies/{id}
# operationId: HoldingCompanies_GetByIdPlanid
export def "holding-companies get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<holdingCompany: record<annualDividendYield: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, ccpc: record<rawValue: bool, valueAsYesNo: string>, commonSharesOutstanding: int, contributions: record<interCompanyDividendsReceived: list, sharePurchases: list, shareholderLoans: list>, corporateYearEnd: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, description: string, dividendType: string, dividendTypeFormatted: string, estateDetails: record<enableFiftyPercentSolution: record, estateFreeze: record, estateFreezeDate: record, shareOptionsAtFirstDeath: string, shareOptionsAtSecondDeathAndDeathInTheSameYear: string>, historicalData: record<generalSetups: record, notionalAccounts: record, outstandingShareholderLoans: record>, id: string, investmentAccounts: list<record>, liabilities: list<record>, lifeInsurancePolicies: list<record>, marketValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, numPreferredShareClasses: int, otherAssets: list<record>, ownershipAsOfDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, ownershipDetails: record<common: list, commonSharesDetails: list, preferred: list, preferredSharesDetails: list, shareholderPercentOwnership: list>, preferredSharesOutstanding: int, provinceOfIncorporation: string, provinceOfTaxation: string, realEstateAssets: list<record>, valueOfAllCommonShares: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, valueOfAllPreferredShares: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, withdrawals: record<loanRepaymentsToShareholder: list, manualDividendDistributions: list, shareRedemptions: list>>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/HoldingCompanies/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve all Households associated with the user
#
# GET /api/Households
# operationId: Households_GetByHouseholdid
export def "households get-by-householdid" [
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
  --household-id: int # The Id of the specific household to retrieve (format: int32)
]: nothing -> record<households: table<accessiblePlans: list, clientDescription: string, householdId: int>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "householdId" $household_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Households" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"householdId": $household_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve liabilities
#
# GET /api/Liabilities
# operationId: Liabilities_GetByPlanid
export def "liabilities list" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<liabilities: table<annualPaymentAmount: record, balanceAsOf: record, balanceAsOfPlanDate: record, debtModStrategies: record, description: string, id: string, insuredForDisability: record, insuredForLife: record, interestRate: record, isInterestRateVariable: record, isPaymentVariable: record, linkedAssetId: string, linkedAssetName: string, loanDate: record, originalBalance: record, owner: string, paidOffByRetirement: record, payOffDate: record, payOffOptionType: record, paymentAmount: record, paymentFrequency: record, paymentType: record, type: record>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Liabilities" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve a liability
#
# GET /api/Liabilities/{id}
# operationId: Liabilities_GetByIdPlanid
export def "liabilities get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<liability: record<annualPaymentAmount: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, balanceAsOf: record<date: record, formattedDecimal: string, formattedNoDecimal: string, raw: float>, balanceAsOfPlanDate: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, debtModStrategies: record<lumpSumDebtModStrategies: list, periodicDebtModStrategies: list>, description: string, id: string, insuredForDisability: record<rawValue: bool, valueAsYesNo: string>, insuredForLife: record<rawValue: bool, valueAsYesNo: string>, interestRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, isInterestRateVariable: record<rawValue: bool, valueAsYesNo: string>, isPaymentVariable: record<rawValue: bool, valueAsYesNo: string>, linkedAssetId: string, linkedAssetName: string, loanDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, originalBalance: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, owner: string, paidOffByRetirement: record<enabled: bool, populated: bool, value: record>, payOffDate: record<enabled: bool, populated: bool, value: record>, payOffOptionType: record<value: string>, paymentAmount: record<enabled: bool, populated: bool, value: record>, paymentFrequency: record<value: string>, paymentType: record<value: string>, type: record<value: string>>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Liabilities/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve lifestyle assets
#
# GET /api/LifestyleAssets
# operationId: LifestyleAssets_GetByPlanid
export def "lifestyle-assets list" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<lifestyleAssets: table<afterTaxProceedsAccountName: string, description: string, futureValueProjectedGrossSaleValue: record, id: string, isMajorPurchaseGoal: bool, marketValueAsOf: record, owner: string, preTaxGrowthRate: record, presentValueProjectedGrossSaleValue: record, projectedSaleDate: record, purchaseAmount: record, purchaseDate: record, sellingCostPercent: record, standardDeviation: record, type: record>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/LifestyleAssets" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve lifestyle assets
#
# GET /api/LifestyleAssets/{id}
# operationId: LifestyleAssets_GetByIdPlanid
export def "lifestyle-assets get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<lifestyleAsset: record<afterTaxProceedsAccountName: string, description: string, futureValueProjectedGrossSaleValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, id: string, isMajorPurchaseGoal: bool, marketValueAsOf: record<date: record, formattedDecimal: string, formattedNoDecimal: string, raw: float>, owner: string, preTaxGrowthRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, presentValueProjectedGrossSaleValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, projectedSaleDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, purchaseAmount: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, purchaseDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, sellingCostPercent: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, standardDeviation: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, type: record<formatted: string, value: string>>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/LifestyleAssets/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieves all goals from the live plan
#
# GET /api/LivePlan/Goals
# operationId: LivePlan_GetGoalsByClientidPlanid
export def "live-plan-goals get-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
]: nothing -> record<clientDescription: string, clientId: int, goals: table<amount: float, coveragePercentage: float, description: string, endDate: string, id: int, inflationRate: float, owners: list, startDate: string, type: string>, planDescription: string, planLastUpdateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/LivePlan/Goals" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"clientId": $client_id, "planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of funding accounts
#
# GET /api/LivePlan/Goals/Funding
# operationId: LivePlan_GetGoalFundingListByClientidPlanid
export def "live-plan-goals-funding get-list-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
]: nothing -> record<goals: table<description: string, fundingAccounts: list, goalId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/LivePlan/Goals/Funding" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"clientId": $client_id, "planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve WAMO values for a given goal
#
# GET /api/LivePlan/Goals/{id}/WhatAreMyOptions
# operationId: LivePlan_GetWhatAreMyOptionsByIdClientidPlanid
export def "live-plan-goals-what-are-my-options get-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
]: nothing -> record<additionalMonthlySavings: float, clientRetirementAge: int, clientRetirementAgeDate: string, coClientRetirementAge: int, coClientRetirementAgeDate: string, expenseCoverageDollars: float, expenseCoveragePercentage: float, lumpSumSavings: float, purchaseDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/LivePlan/Goals/{id}/WhatAreMyOptions") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"clientId": $client_id, "planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieves accounts for a given plan
#
# GET /api/LivePlan/NetWorth/Accounts
# operationId: LivePlan_GetAccountsByClientidPlanid
export def "live-plan-net-worth-accounts get-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
]: nothing -> record<accounts: table<description: string, holdings: list, id: int, legacyId: string, owner: record, type: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/LivePlan/NetWorth/Accounts" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"clientId": $client_id, "planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieves liabilities for a given plan
#
# GET /api/LivePlan/NetWorth/Liabilities
# operationId: LivePlan_GetLiabilitiesByClientidPlanid
export def "live-plan-net-worth-liabilities get-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
]: nothing -> record<liabilities: table<description: string, endDate: string, id: int, legacyId: string, outstandingPrincipal: float, outstandingPrincipalAsOfDate: string, owner: record, startDate: string, type: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/LivePlan/NetWorth/Liabilities" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"clientId": $client_id, "planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieves lifestyle assets for a given plan
#
# GET /api/LivePlan/NetWorth/LifestyleAssets
# operationId: LivePlan_GetLifestyleAssetsByClientidPlanid
export def "live-plan-net-worth-lifestyle-assets get-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
]: nothing -> record<lifestyleAssets: table<description: string, id: int, owner: record, purchaseDate: string, purchaseValue: float, type: int, valuationDate: string, valuationValue: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/LivePlan/NetWorth/LifestyleAssets" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"clientId": $client_id, "planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieves real estate accounts for a given plan
#
# GET /api/LivePlan/NetWorth/RealEstate
# operationId: LivePlan_GetRealEstateAssetsByClientidPlanid
export def "live-plan-net-worth-real-estate get-assets-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
]: nothing -> record<realEstateAssets: table<description: string, id: int, legacyId: string, marketValue: float, owner: record, purchaseAmount: float, purchaseDate: string, valuationDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/LivePlan/NetWorth/RealEstate" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"clientId": $client_id, "planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieves net worth projections
#
# GET /api/LivePlan/Projections/NetWorth
# operationId: LivePlan_GetProjectedNetWorthByClientidPlanid
export def "live-plan-projections-net-worth get-projected-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
]: nothing -> record<netWorthProjections: table<endOfYearRetirementAssets: float, endOfYearTotalAssets: float, year: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/LivePlan/Projections/NetWorth" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"clientId": $client_id, "planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieves needs vs abilities projections
#
# GET /api/LivePlan/Projections/{id}/NeedsVsAbilities
# operationId: LivePlan_GetProjectedNeedsVsAbilitiesByIdClientidPlanid
export def "live-plan-projections-needs-vs-abilities get-projected-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3).
]: nothing -> record<goalId: int, percentCovered: float, projections: table<projectedAbilities: float, projectedNeed: float, year: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/LivePlan/Projections/{id}/NeedsVsAbilities") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"clientId": $client_id, "planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve net worth
#
# GET /api/NetWorth
# operationId: NetWorth_GetByPlanid
export def "net-worth get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<links: table<href: string, rel: string>, netWorth: record<netWorthAtPlanDate: record<assets: record, assetsFundingRetirement: record, clientNetWorth: record, coClientNetWorth: record, communityPropertyNetWorth: record, jointNetWorth: record, liabilities: record, totalNetWorth: record>, netWorthAtPlanEnd: record<enabled: bool, populated: bool, value: record>, netWorthAtRetirement: record<enabled: bool, populated: bool, value: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/NetWorth" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Determines if the currently logged in user has set their own password
#
# POST /api/Password/HasUserSetPassword
# operationId: Password_HasUserSetPassword
export def "password-has-user-set-password update" [
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
  let full_url = (build-url $base "/api/Password/HasUserSetPassword" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Gets the password complexity requirements
#
# GET /api/Password/PasswordRequirements
# operationId: Password_PasswordRequirements
export def "password-password-requirements get" [
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
  let full_url = (build-url $base "/api/Password/PasswordRequirements" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Resets the password for the supplied user name
#
# POST /api/Password/Reset
# operationId: Password_ResetByModel
export def "password-reset reset-by-model" [
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
  locale: string # Supported locales are: "en-US", "en-CA", and "fr-CA"
  user_name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Password/Reset" $auth.query)
  let req_body = {"locale": $locale, "userName": $user_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Sets the password for the currently logged in user
#
# POST /api/Password/Set
# operationId: Password_SetByModel
export def "password-set update-by-model" [
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
  --new-password: string
  --old-password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Password/Set" $auth.query)
  let req_body = {"newPassword": $new_password, "oldPassword": $old_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Retrieve plan information
#
# GET /api/PlanInformation
# operationId: PlanInformation_GetByPlanid
export def "plan-information get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<country: string, description: string, isJointAnalysis: bool, links: table<href: string, rel: string>, locale: string, planDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, planDescription: string, planId: string, planLevel: string, planModules: record<isCriticalIllnessModuleEnabled: bool, isDisabilityIncomeModuleEnabled: bool, isEstatePlanningModuleEabled: bool, isLongTermCareModuleEnabled: bool, isSurvivorIncomeModuleEnabled: bool>, planType: string, publishDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/PlanInformation" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve plan data statuses
#
# GET /api/PlanStatuses
# operationId: PlanStatuses_GetByPlanid
export def "plan-statuses get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3)
]: nothing -> record<hasIntegratedAccounts: string, links: table<href: string, rel: string>, planDataStatus: string, serializedDataStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/PlanStatuses" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve portfolio accounts
#
# GET /api/PortfolioAccounts
# operationId: PortfolioAccounts_GetByPlanid
export def "portfolio-accounts list" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<links: table<href: string, rel: string>, portfolioAccounts: table<accountReturnRatesNoLongerCorrelateToAssumedAssetMixDueToOverrideInGsm: bool, annualFee: record, applicableRangeRetirementLiquidatedAssets: record, costBasis: record, description: string, descriptionWithOwner: string, excludeInAA: bool, holdings: list, id: string, isSystemGenerated: bool, marketValue: record, owner: string, portfolioAssets: list, rateOfReturn: record, savingsStrategies: record, seppRedemptionStrategy: record, type: string, valuationDate: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/PortfolioAccounts" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve a portfolio account
#
# GET /api/PortfolioAccounts/{id}
# operationId: PortfolioAccounts_GetByIdPlanid
export def "portfolio-accounts get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<links: table<href: string, rel: string>, portfolioAccount: record<accountReturnRatesNoLongerCorrelateToAssumedAssetMixDueToOverrideInGsm: bool, annualFee: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, applicableRangeRetirementLiquidatedAssets: record<endDate: record, startDate: record>, costBasis: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, description: string, descriptionWithOwner: string, excludeInAA: bool, holdings: list<record>, id: string, isSystemGenerated: bool, marketValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, owner: string, portfolioAssets: list<record>, rateOfReturn: record<preRetirement: record, retirement: record>, savingsStrategies: record<lumpSumSavingsStrategies: list, periodicSavingsStrategies: list, rrspMaximizerStrategies: list, surplusSavingsStrategies: list>, seppRedemptionStrategy: record<applicableDateRange: record, distributionMethod: record, lifeExpectancyTable: record, redemptionFrequency: record>, type: string, valuationDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/PortfolioAccounts/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve projected annual summaries
#
# GET /api/ProjectedAnnualSummary
# operationId: ProjectedAnnualSummary_GetByPlanid
export def "projected-annual-summary list" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<links: table<href: string, rel: string>, projections: table<annualSummary: record, links: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ProjectedAnnualSummary" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve projected annual summary by id
#
# GET /api/ProjectedAnnualSummary/{id}
# operationId: ProjectedAnnualSummary_GetByIdPlanid
export def "projected-annual-summary get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<annualSummary: record<cashFlow: record<surplusDeficit: float, totalIncome: float, totalOutflowsWithTaxes: float, totalOutflowsWithoutTaxes: float, totalTaxes: float>, clientAge: int, coClientAge: int, netWorth: record<totalAssets: float, totalLiabilities: float, totalNetWorth: float>, year: int>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/ProjectedAnnualSummary/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve projected cash flow
#
# GET /api/ProjectedCashFlow
# operationId: ProjectedCashFlow_GetByPlanid
export def "projected-cash-flow list" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<links: table<href: string, rel: string>, projections: table<cashFlow: record, links: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ProjectedCashFlow" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve projected cash flow by id
#
# GET /api/ProjectedCashFlow/{id}
# operationId: ProjectedCashFlow_GetByIdPlanid
export def "projected-cash-flow get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<cashFlow: record<cashFlow: record<clientCashFlow: record, coClientCashFlow: record, totalCashFlow: record>, clientAge: int, coClientAge: int, year: int>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/ProjectedCashFlow/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve assets funding goals over time
#
# GET /api/ProjectedGoals/AssetsFundingGoals
# operationId: ProjectedGoals_GetAssetsFundingGoalsByPlanid
export def "projected-goals-assets-funding-goals get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<links: table<href: string, rel: string>, projections: table<clientAge: int, coClientAge: int, goals: list, year: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ProjectedGoals/AssetsFundingGoals" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve needs vs abilities data
#
# GET /api/ProjectedGoals/NeedsVsAbilities
# operationId: ProjectedGoals_GetNeedsVsAbilitiesByPlanid
export def "projected-goals-needs-vs-abilities get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<links: table<href: string, rel: string>, projections: table<clientAge: int, coClientAge: int, goals: list, year: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ProjectedGoals/NeedsVsAbilities" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve projected net worth
#
# GET /api/ProjectedNetWorth
# operationId: ProjectedNetWorth_GetByPlanid
export def "projected-net-worth list" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<links: table<href: string, rel: string>, projections: table<links: list, netWorth: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ProjectedNetWorth" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve projected net worth by id
#
# GET /api/ProjectedNetWorth/{id}
# operationId: ProjectedNetWorth_GetByIdPlanid
export def "projected-net-worth get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<links: table<href: string, rel: string>, netWorth: record<clientAge: int, coClientAge: int, endOfYearNetWorth: record<assets: record, assetsFundingRetirement: record, clientNetWorth: record, coClientNetWorth: record, communityPropertyNetWorth: record, jointNetWorth: record, liabilities: record, totalNetWorth: record>, year: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/ProjectedNetWorth/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve restricted stocks
#
# GET /api/RestrictedStocks
# operationId: RestrictedStocks_GetByPlanid
export def "restricted-stocks list" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<links: table<href: string, rel: string>, restrictedStocks: table<annualDividendPerUnit: record, applicableRangeRetirementLiquidatedAssets: record, awardedDate: record, currentUnitValue: record, description: string, growthRate: record, id: string, numberOfUnits: int, owner: string, pricePaidForAward: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/RestrictedStocks" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve a restricted stock
#
# GET /api/RestrictedStocks/{id}
# operationId: RestrictedStocks_GetByIdPlanid
export def "restricted-stocks get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<links: table<href: string, rel: string>, restrictedStock: record<annualDividendPerUnit: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, applicableRangeRetirementLiquidatedAssets: record<endDate: record, startDate: record>, awardedDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, currentUnitValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, description: string, growthRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, id: string, numberOfUnits: int, owner: string, pricePaidForAward: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/RestrictedStocks/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# This resource can be used to check the status of the service.
#
# GET /api/ServiceInformation/Statistics
# operationId: ServiceInformation_Statistics
export def "service-information-statistics get" [
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
]: nothing -> record<altairConnectionStatus: bool, name: string, pomVersion: string, serviceVersion: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/ServiceInformation/Statistics" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Retrieve stock options
#
# GET /api/StockOptions
# operationId: StockOptions_GetByPlanid
export def "stock-options list" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<links: table<href: string, rel: string>, stockOptions: table<annualDividendPerUnit: record, applicableRangeRetirementLiquidatedAssets: record, company: string, currentUnitPrice: record, currentUnitPriceDate: record, description: string, endOfPlanYearExercisableGrossValue: record, exerciseCost: record, expirationDate: record, grantDate: record, grantedOptions: int, growthRate: record, id: string, optionsExercisable: int, optionsExercised: int, optionsVested: int, owner: string, preTaxProfit: record, startOfYearAMTBasis: record, startOfYearCostBasis: record, startOfYearUnitPrice: record, strikePrice: record, symbol: string, type: string, typeFormatted: string, vestingSchedule: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/StockOptions" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Retrieve a stock option
#
# GET /api/StockOptions/{id}
# operationId: StockOptions_GetByIdPlanid
export def "stock-options get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3).
]: nothing -> record<links: table<href: string, rel: string>, stockOption: record<annualDividendPerUnit: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, applicableRangeRetirementLiquidatedAssets: record<endDate: record, startDate: record>, company: string, currentUnitPrice: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, currentUnitPriceDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, description: string, endOfPlanYearExercisableGrossValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, exerciseCost: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, expirationDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, grantDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, grantedOptions: int, growthRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, id: string, optionsExercisable: int, optionsExercised: int, optionsVested: int, owner: string, preTaxProfit: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, startOfYearAMTBasis: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, startOfYearCostBasis: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, startOfYearUnitPrice: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, strikePrice: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, symbol: string, type: string, typeFormatted: string, vestingSchedule: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/StockOptions/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"planId": $plan_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Start a session with the DomainProviders user store
#
# POST /api/auth/Login
# operationId: Auth_LoginByModel
export def "auth-login create-by-model" [
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
  --password: string
  --username: string
]: any -> record<eulaAccepted: bool, hasAccountAggregation: bool, hasGoalWhatIfing: bool, hasUserSetPassword: bool, isAdmin: bool, isAdvisor: bool, isClient: bool, isPasswordExpired: bool, userId: string, userName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/auth/Login" $auth.query)
  let req_body = {"password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Gets the login rules
#
# GET /api/auth/LoginConfiguration
# operationId: Auth_PasswordRequirements
export def "auth-login-configuration get-password-requirements" [
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
  let full_url = (build-url $base "/api/auth/LoginConfiguration" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# POST /api/auth/Logout
#
# operationId: Auth_Logout
export def "auth-logout create" [
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
  let full_url = (build-url $base "/api/auth/Logout" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Validate and extend the duration of a session
#
# POST /api/auth/ResumeSession
# operationId: Auth_ResumeSession
export def "auth-resume-session create" [
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
]: nothing -> record<eulaAccepted: bool, hasAccountAggregation: bool, hasGoalWhatIfing: bool, hasUserSetPassword: bool, isAdmin: bool, isAdvisor: bool, isClient: bool, isPasswordExpired: bool, userId: string, userName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/auth/ResumeSession" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}
