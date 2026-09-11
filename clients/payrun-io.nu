# Auto-generated client for PayRun.IO v22.23.10.42
# Source: https://api.apis.guru/v2/specs/payrun.io/22.23.10.42/openapi.json
# Auth: --token flag or $env.PAYRUN_IO_TOKEN

const BASE_URL = "https://api.test.payrun.io"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o PAYRUN_IO_TOKEN | default "" }
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

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.test.payrun.io"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "delete-employer" } } | get name | first)
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

# Delete an Employer
#
# DELETE /Employer/{EmployerId}
# operationId: DeleteEmployer
export def "delete-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the employer
#
# GET /Employer/{EmployerId}
# operationId: GetEmployer
export def "get-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Patches the employer
#
# PATCH /Employer/{EmployerId}
# operationId: PatchEmployer
# --Employer shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, ... (2 more fields)}
export def "patch-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --employer: record # shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, ... (2 more fields)}
]: any -> record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}") $auth.query)
  let req_body = {"Employer": $employer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates the Employer
#
# PUT /Employer/{EmployerId}
# operationId: PutEmployer
# --Employer shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, ... (2 more fields)}
export def "put-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --employer: record # shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, ... (2 more fields)}
]: any -> record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}") $auth.query)
  let req_body = {"Employer": $employer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete an CIS line type
#
# DELETE /Employer/{EmployerId}/CisLineType/{CisLineTypeId}
# operationId: DeleteCisLineType
export def "delete-cis-line-type" [
  employer_id: string
  cis_line_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($cis_line_type_id | is-empty) { error make --unspanned { msg: "path parameter 'CisLineTypeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), cis_line_type_id: (encode-path-segment $cis_line_type_id)} | format pattern "/Employer/{employer_id}/CisLineType/{cis_line_type_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get CIS line type from employer
#
# GET /Employer/{EmployerId}/CisLineType/{CisLineTypeId}
# operationId: GetCisLineTypeFromEmployer
export def "get-cis-line-type-from-employer" [
  employer_id: string
  cis_line_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<CisLineType: record<Description: string, LineType: string, NominalCode: record<_href: string, _rel: string, _title: string>, TaxTreatment: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($cis_line_type_id | is-empty) { error make --unspanned { msg: "path parameter 'CisLineTypeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), cis_line_type_id: (encode-path-segment $cis_line_type_id)} | format pattern "/Employer/{employer_id}/CisLineType/{cis_line_type_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Updates the CIS line type
#
# PUT /Employer/{EmployerId}/CisLineType/{CisLineTypeId}
# operationId: PutCisLineTypeIntoEmployer
# --CisLineType shape: {Description?: string, LineType?: string, NominalCode?: record, TaxTreatment?: "Taxable"|"NonTaxable"|"Notional"|"Materials"}
export def "put-cis-line-type-into-employer" [
  employer_id: string
  cis_line_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --cis-line-type: record # shape: {Description?: string, LineType?: string, NominalCode?: record, TaxTreatment?: "Taxable"|"NonTaxable"|"Notional"|"Materials"}
]: any -> record<CisLineType: record<Description: string, LineType: string, NominalCode: record<_href: string, _rel: string, _title: string>, TaxTreatment: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($cis_line_type_id | is-empty) { error make --unspanned { msg: "path parameter 'CisLineTypeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), cis_line_type_id: (encode-path-segment $cis_line_type_id)} | format pattern "/Employer/{employer_id}/CisLineType/{cis_line_type_id}") $auth.query)
  let req_body = {"CisLineType": $cis_line_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete CIS line type tag
#
# DELETE /Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tag/{TagId}
# operationId: DeleteCisLineTypeTag
export def "delete-cis-line-type-tag" [
  employer_id: string
  cis_line_type_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($cis_line_type_id | is-empty) { error make --unspanned { msg: "path parameter 'CisLineTypeId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), cis_line_type_id: (encode-path-segment $cis_line_type_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/CisLineType/{cis_line_type_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get CIS line type tag
#
# GET /Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tag/{TagId}
# operationId: GetTagFromCisLineType
export def "get-tag-from-cis-line-type" [
  employer_id: string
  cis_line_type_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($cis_line_type_id | is-empty) { error make --unspanned { msg: "path parameter 'CisLineTypeId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), cis_line_type_id: (encode-path-segment $cis_line_type_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/CisLineType/{cis_line_type_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert CIS line type tag
#
# PUT /Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tag/{TagId}
# operationId: PutCisLineTypeTag
export def "put-cis-line-type-tag" [
  employer_id: string
  cis_line_type_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($cis_line_type_id | is-empty) { error make --unspanned { msg: "path parameter 'CisLineTypeId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), cis_line_type_id: (encode-path-segment $cis_line_type_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/CisLineType/{cis_line_type_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get all tags from the CIS line type
#
# GET /Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tags
# operationId: GetTagsFromCisLineType
export def "get-tags-from-cis-line-type" [
  employer_id: string
  cis_line_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($cis_line_type_id | is-empty) { error make --unspanned { msg: "path parameter 'CisLineTypeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), cis_line_type_id: (encode-path-segment $cis_line_type_id)} | format pattern "/Employer/{employer_id}/CisLineType/{cis_line_type_id}/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get CIS line types from employer.
#
# GET /Employer/{EmployerId}/CisLineTypes
# operationId: GetCisLineTypesFromEmployer
export def "get-cis-line-types-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/CisLineTypes") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create a new CIS line type
#
# POST /Employer/{EmployerId}/CisLineTypes
# operationId: PostCisLineTypeIntoEmployer
# --CisLineType shape: {Description?: string, LineType?: string, NominalCode?: record, TaxTreatment?: "Taxable"|"NonTaxable"|"Notional"|"Materials"}
export def "post-cis-line-type-into-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --cis-line-type: record # shape: {Description?: string, LineType?: string, NominalCode?: record, TaxTreatment?: "Taxable"|"NonTaxable"|"Notional"|"Materials"}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/CisLineTypes") $auth.query)
  let req_body = {"CisLineType": $cis_line_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get CIS line types with tag
#
# GET /Employer/{EmployerId}/CisLineTypes/Tag/{TagId}
# operationId: GetCisLineTypesWithTag
export def "get-cis-line-types-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/CisLineTypes/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all CIS line type tags
#
# GET /Employer/{EmployerId}/CisLineTypes/Tags
# operationId: GetAllCisLineTypeTags
export def "get-all-cis-line-type-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/CisLineTypes/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete the CIS transaction
#
# DELETE /Employer/{EmployerId}/CisTransaction/{CisTransactionId}
# operationId: DeleteCisTransaction
export def "delete-cis-transaction" [
  employer_id: string
  cis_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($cis_transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'CisTransactionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), cis_transaction_id: (encode-path-segment $cis_transaction_id)} | format pattern "/Employer/{employer_id}/CisTransaction/{cis_transaction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get the CIS transaction
#
# GET /Employer/{EmployerId}/CisTransaction/{CisTransactionId}
# operationId: GetCisTransactionFromEmployer
export def "get-cis-transaction-from-employer" [
  employer_id: string
  cis_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<CisTransaction: record<CisMessageType: string, EmployerCore: record<_href: string, _rel: string, _title: string>, RequestData: string, ResponseData: string, TaxYear: int, Timestamp: string, TransactionStatus: string, TransmissionDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($cis_transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'CisTransactionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), cis_transaction_id: (encode-path-segment $cis_transaction_id)} | format pattern "/Employer/{employer_id}/CisTransaction/{cis_transaction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all CIS transactions for the employer
#
# GET /Employer/{EmployerId}/CisTransactions
# operationId: GetCisTransactionsFromEmployer
export def "get-cis-transactions-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/CisTransactions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Deletes the DPS message
#
# DELETE /Employer/{EmployerId}/DpsMessage/{DpsMessageId}
# operationId: DeleteDpsMessage
export def "delete-dps-message" [
  employer_id: string
  dps_message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($dps_message_id | is-empty) { error make --unspanned { msg: "path parameter 'DpsMessageId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), dps_message_id: (encode-path-segment $dps_message_id)} | format pattern "/Employer/{employer_id}/DpsMessage/{dps_message_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the DPS message
#
# GET /Employer/{EmployerId}/DpsMessage/{DpsMessageId}
# operationId: GetDpsMessageFromEmployer
export def "get-dps-message-from-employer" [
  employer_id: string
  dps_message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<DpsMessage: record<FormType: string, IssueDate: string, LastUpdated: string, Message: string, MessageStatus: string, MessageType: string, ProcessingResult: string, RetrieveDate: string, SequenceNumber: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($dps_message_id | is-empty) { error make --unspanned { msg: "path parameter 'DpsMessageId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), dps_message_id: (encode-path-segment $dps_message_id)} | format pattern "/Employer/{employer_id}/DpsMessage/{dps_message_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Patches the DPS message
#
# PATCH /Employer/{EmployerId}/DpsMessage/{DpsMessageId}
# operationId: PatchDpsMessage
export def "patch-dps-message" [
  employer_id: string
  dps_message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<DpsMessage: record<FormType: string, IssueDate: string, LastUpdated: string, Message: string, MessageStatus: string, MessageType: string, ProcessingResult: string, RetrieveDate: string, SequenceNumber: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($dps_message_id | is-empty) { error make --unspanned { msg: "path parameter 'DpsMessageId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), dps_message_id: (encode-path-segment $dps_message_id)} | format pattern "/Employer/{employer_id}/DpsMessage/{dps_message_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req null $insecure $raw $allow_errors $full [200]
}

# Puts the DPS message
#
# PUT /Employer/{EmployerId}/DpsMessage/{DpsMessageId}
# operationId: PutDpsMessage
export def "put-dps-message" [
  employer_id: string
  dps_message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<DpsMessage: record<FormType: string, IssueDate: string, LastUpdated: string, Message: string, MessageStatus: string, MessageType: string, ProcessingResult: string, RetrieveDate: string, SequenceNumber: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($dps_message_id | is-empty) { error make --unspanned { msg: "path parameter 'DpsMessageId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), dps_message_id: (encode-path-segment $dps_message_id)} | format pattern "/Employer/{employer_id}/DpsMessage/{dps_message_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [201]
}

# Gets the DPS messages
#
# GET /Employer/{EmployerId}/DpsMessages
# operationId: GetDpsMessagesFromEmployer
export def "get-dps-messages-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/DpsMessages") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Posta the DPS message
#
# POST /Employer/{EmployerId}/DpsMessages
# operationId: PostDpsMessage
export def "post-dps-message" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/DpsMessages") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Delete an Employee
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}
# operationId: DeleteEmployee
export def "delete-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get employee from employer
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}
# operationId: GetEmployeeFromEmployer
export def "get-employee-from-employer" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Patches the employee
#
# PATCH /Employer/{EmployerId}/Employee/{EmployeeId}
# operationId: PatchEmployee
# --Employee shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, ... (41 more fields)}
export def "patch-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --employee: record # shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, ... (41 more fields)}
]: any -> record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}") $auth.query)
  let req_body = {"Employee": $employee} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates the Employee
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}
# operationId: PutEmployeeIntoEmployer
# --Employee shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, ... (41 more fields)}
export def "put-employee-into-employer" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --employee: record # shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, ... (41 more fields)}
]: any -> record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}") $auth.query)
  let req_body = {"Employee": $employee} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete auto enrolment assessment
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessment/{AEAssessmentId}
# operationId: DeleteAEAssessment
export def "delete-ae-assessment" [
  employer_id: string
  employee_id: string
  ae_assessment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($ae_assessment_id | is-empty) { error make --unspanned { msg: "path parameter 'AEAssessmentId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), ae_assessment_id: (encode-path-segment $ae_assessment_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/AEAssessment/{ae_assessment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get the auto enrolment assessment
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessment/{AEAssessmentId}
# operationId: GetAEAssessmentFromEmployee
export def "get-ae-assessment-from-employee" [
  employer_id: string
  employee_id: string
  ae_assessment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<AEAssessment: record<Age: int, AssessmentCode: string, AssessmentDate: string, AssessmentEvent: string, AssessmentOverride: string, AssessmentResult: string, IsMemberOfAlternativePensionScheme: bool, OptOutWindowEndDate: string, QualifyingEarnings: float, ReenrolmentDate: string, StatePensionAge: int, StatePensionDate: string, TaxPeriod: int, TaxYear: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($ae_assessment_id | is-empty) { error make --unspanned { msg: "path parameter 'AEAssessmentId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), ae_assessment_id: (encode-path-segment $ae_assessment_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/AEAssessment/{ae_assessment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert new auto enrolment assessment
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessment/{AEAssessmentId}
# operationId: PutNewAEAssessment
# --AEAssessment shape: {Age?: int, AssessmentCode?: "Excluded"|"EligibleJobHolder"|"NonEligibleJobHolder"|"EntitledWorker", AssessmentDate?: string, AssessmentEvent?: "NonEnrolmentEvent"|"AutomaticEnrolment"|"OptIn"|"VoluntaryJoiner"|"ContractualEnrolment", AssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AssessmentResult?: "Inconclusive"|"NoChange"|"Enrol"|"Exit", IsMemberOfAlternativePensionScheme?: bool, OptOutWindowEndDate?: string, ... (6 more fields)}
export def "put-new-ae-assessment" [
  employer_id: string
  employee_id: string
  ae_assessment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --ae-assessment: record # shape: {Age?: int, AssessmentCode?: "Excluded"|"EligibleJobHolder"|"NonEligibleJobHolder"|"EntitledWorker", AssessmentDate?: string, AssessmentEvent?: "NonEnrolmentEvent"|"AutomaticEnrolment"|"OptIn"|"VoluntaryJoiner"|"ContractualEnrolment", AssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AssessmentResult?: "Inconclusive"|"NoChange"|"Enrol"|"Exit", IsMemberOfAlternativePensionScheme?: bool, OptOutWindowEndDate?: string, ... (6 more fields)}
]: any -> record<AEAssessment: record<Age: int, AssessmentCode: string, AssessmentDate: string, AssessmentEvent: string, AssessmentOverride: string, AssessmentResult: string, IsMemberOfAlternativePensionScheme: bool, OptOutWindowEndDate: string, QualifyingEarnings: float, ReenrolmentDate: string, StatePensionAge: int, StatePensionDate: string, TaxPeriod: int, TaxYear: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($ae_assessment_id | is-empty) { error make --unspanned { msg: "path parameter 'AEAssessmentId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), ae_assessment_id: (encode-path-segment $ae_assessment_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/AEAssessment/{ae_assessment_id}") $auth.query)
  let req_body = {"AEAssessment": $ae_assessment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get the auto enrolment assessments
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessments
# operationId: GetAEAssessmentsFromEmployee
export def "get-ae-assessments-from-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/AEAssessments") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert new auto enrolment assessment
#
# POST /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessments
# operationId: PostNewAEAssessment
# --AEAssessment shape: {Age?: int, AssessmentCode?: "Excluded"|"EligibleJobHolder"|"NonEligibleJobHolder"|"EntitledWorker", AssessmentDate?: string, AssessmentEvent?: "NonEnrolmentEvent"|"AutomaticEnrolment"|"OptIn"|"VoluntaryJoiner"|"ContractualEnrolment", AssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AssessmentResult?: "Inconclusive"|"NoChange"|"Enrol"|"Exit", IsMemberOfAlternativePensionScheme?: bool, OptOutWindowEndDate?: string, ... (6 more fields)}
export def "post-new-ae-assessment" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --ae-assessment: record # shape: {Age?: int, AssessmentCode?: "Excluded"|"EligibleJobHolder"|"NonEligibleJobHolder"|"EntitledWorker", AssessmentDate?: string, AssessmentEvent?: "NonEnrolmentEvent"|"AutomaticEnrolment"|"OptIn"|"VoluntaryJoiner"|"ContractualEnrolment", AssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AssessmentResult?: "Inconclusive"|"NoChange"|"Enrol"|"Exit", IsMemberOfAlternativePensionScheme?: bool, OptOutWindowEndDate?: string, ... (6 more fields)}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/AEAssessments") $auth.query)
  let req_body = {"AEAssessment": $ae_assessment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get links to all commentaries for the specified employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Commentaries
# operationId: GetCommentariesFromEmployee
export def "get-commentaries-from-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Commentaries") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get commentary from employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Commentary/{CommentaryId}
# operationId: GetCommentaryFromEmployee
export def "get-commentary-from-employee" [
  employer_id: string
  employee_id: string
  commentary_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Commentary: record<Created: string, Detail: string, Employee: record<_href: string, _rel: string, _title: string>, PayRun: record<_href: string, _rel: string, _title: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($commentary_id | is-empty) { error make --unspanned { msg: "path parameter 'CommentaryId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), commentary_id: (encode-path-segment $commentary_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Commentary/{commentary_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the journal Lines from the specified employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/JournalLines
# operationId: GetJournalLinesFromEmployee
export def "get-journal-lines-from-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/JournalLines") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Deletes a pay instruction
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}
# operationId: DeletePayInstruction
export def "delete-pay-instruction" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($pay_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'PayInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), pay_instruction_id: (encode-path-segment $pay_instruction_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstruction/{pay_instruction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the specified pay instruction from the employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}
# operationId: GetPayInstructionFromEmployee
export def "get-pay-instruction-from-employee" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<PayInstruction: record<Description: string, EndDate: string, PayLineTag: string, StartDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($pay_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'PayInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), pay_instruction_id: (encode-path-segment $pay_instruction_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstruction/{pay_instruction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Sparse Update of a Pay Instruction
#
# PATCH /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}
# operationId: PatchPayInstruction
# --PayInstruction shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
export def "patch-pay-instruction" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --pay-instruction: record # shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
]: any -> record<PayInstruction: record<Description: string, EndDate: string, PayLineTag: string, StartDate: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($pay_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'PayInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), pay_instruction_id: (encode-path-segment $pay_instruction_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstruction/{pay_instruction_id}") $auth.query)
  let req_body = {"PayInstruction": $pay_instruction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update a Pay Instruction
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}
# operationId: PutPayInstruction
# --PayInstruction shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
export def "put-pay-instruction" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --pay-instruction: record # shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
]: any -> record<PayInstruction: record<Description: string, EndDate: string, PayLineTag: string, StartDate: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($pay_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'PayInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), pay_instruction_id: (encode-path-segment $pay_instruction_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstruction/{pay_instruction_id}") $auth.query)
  let req_body = {"PayInstruction": $pay_instruction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete pay instruction tag
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tag/{TagId}
# operationId: DeletePayInstructionTag
export def "delete-pay-instruction-tag" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($pay_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'PayInstructionId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), pay_instruction_id: (encode-path-segment $pay_instruction_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstruction/{pay_instruction_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get pay instruction tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tag/{TagId}
# operationId: GetTagFromPayInstruction
export def "get-tag-from-pay-instruction" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($pay_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'PayInstructionId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), pay_instruction_id: (encode-path-segment $pay_instruction_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstruction/{pay_instruction_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert pay instruction tag
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tag/{TagId}
# operationId: PutPayInstructionTag
export def "put-pay-instruction-tag" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($pay_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'PayInstructionId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), pay_instruction_id: (encode-path-segment $pay_instruction_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstruction/{pay_instruction_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get all tags from the pay instruction
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tags
# operationId: GetTagsFromPayInstruction
export def "get-tags-from-pay-instruction" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($pay_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'PayInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), pay_instruction_id: (encode-path-segment $pay_instruction_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstruction/{pay_instruction_id}/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the pay instructions from the specified employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions
# operationId: GetPayInstructionsFromEmployee
export def "get-pay-instructions-from-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstructions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Creates a new Pay Instruction
#
# POST /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions
# operationId: PostPayInstruction
# --PayInstruction shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
export def "post-pay-instruction" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --pay-instruction: record # shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstructions") $auth.query)
  let req_body = {"PayInstruction": $pay_instruction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get pay instructions with tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions/Tag/{TagId}
# operationId: GetPayInstructionsWithTag
export def "get-pay-instructions-with-tag" [
  employer_id: string
  employee_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstructions/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all pay instruction tags
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions/Tags
# operationId: GetAllPayInstructionTags
export def "get-all-pay-instruction-tags" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstructions/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the specified pay line from the employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}
# operationId: GetPayLineFromEmployee
export def "get-pay-line-from-employee" [
  employer_id: string
  employee_id: string
  pay_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<PayLine: record<Calculator: string, Description: string, Generated: string, PayCode: string, PayCodeType: string, PayRunSequence: int, PaymentDate: string, TaxPeriod: int, TaxYear: int, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($pay_line_id | is-empty) { error make --unspanned { msg: "path parameter 'PayLineId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), pay_line_id: (encode-path-segment $pay_line_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayLine/{pay_line_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete pay line tag
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tag/{TagId}
# operationId: DeletePayLineTag
export def "delete-pay-line-tag" [
  employer_id: string
  employee_id: string
  pay_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($pay_line_id | is-empty) { error make --unspanned { msg: "path parameter 'PayLineId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), pay_line_id: (encode-path-segment $pay_line_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayLine/{pay_line_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get pay line tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tag/{TagId}
# operationId: GetTagFromPayLine
export def "get-tag-from-pay-line" [
  employer_id: string
  employee_id: string
  pay_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($pay_line_id | is-empty) { error make --unspanned { msg: "path parameter 'PayLineId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), pay_line_id: (encode-path-segment $pay_line_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayLine/{pay_line_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert pay line tag
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tag/{TagId}
# operationId: PutPayLineTag
export def "put-pay-line-tag" [
  employer_id: string
  employee_id: string
  pay_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($pay_line_id | is-empty) { error make --unspanned { msg: "path parameter 'PayLineId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), pay_line_id: (encode-path-segment $pay_line_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayLine/{pay_line_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get all tags from the pay line
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tags
# operationId: GetTagsFromPayLine
export def "get-tags-from-pay-line" [
  employer_id: string
  employee_id: string
  pay_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($pay_line_id | is-empty) { error make --unspanned { msg: "path parameter 'PayLineId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), pay_line_id: (encode-path-segment $pay_line_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayLine/{pay_line_id}/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the pay lines from the specified employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLines
# operationId: GetPayLinesFromEmployee
export def "get-pay-lines-from-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayLines") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get pay lines with tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLines/Tag/{TagId}
# operationId: GetPayLinesWithTag
export def "get-pay-lines-with-tag" [
  employer_id: string
  employee_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayLines/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all pay line tags
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLines/Tags
# operationId: GetAllPayLineTags
export def "get-all-pay-line-tags" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayLines/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the pay runs from the employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayRuns
# operationId: GetPayRunsFromEmployee
export def "get-pay-runs-from-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayRuns") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete an Employee revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/Revision/{RevisionNumber}
# operationId: DeleteEmployeeRevisionByNumber
export def "delete-employee-revision-by-number" [
  employer_id: string
  employee_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($revision_number | is-empty) { error make --unspanned { msg: "path parameter 'RevisionNumber' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), revision_number: (encode-path-segment $revision_number)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Revision/{revision_number}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the employee by revision number
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Revision/{RevisionNumber}
# operationId: GetEmployeeRevisionByNumber
export def "get-employee-revision-by-number" [
  employer_id: string
  employee_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($revision_number | is-empty) { error make --unspanned { msg: "path parameter 'RevisionNumber' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), revision_number: (encode-path-segment $revision_number)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Revision/{revision_number}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the employee summary by revision number
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Revision/{RevisionNumber}/Summary
# operationId: GetEmployeeRevisionSummaryByNumber
export def "get-employee-revision-summary-by-number" [
  employer_id: string
  employee_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($revision_number | is-empty) { error make --unspanned { msg: "path parameter 'RevisionNumber' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), revision_number: (encode-path-segment $revision_number)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Revision/{revision_number}/Summary") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all employee revisions
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Revisions
# operationId: GetEmployeeRevisions
export def "get-employee-revisions" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Revisions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all employee revision summaries
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Revisions/Summary
# operationId: GetEmployeeRevisionSummaries
export def "get-employee-revision-summaries" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Revisions/Summary") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Deletes employee secret
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/Secret/{SecretId}
# operationId: DeleteEmployeeSecret
export def "delete-employee-secret" [
  employer_id: string
  employee_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($secret_id | is-empty) { error make --unspanned { msg: "path parameter 'SecretId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), secret_id: (encode-path-segment $secret_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Secret/{secret_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get employee secret
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Secret/{SecretId}
# operationId: GetEmployeeSecret
export def "get-employee-secret" [
  employer_id: string
  employee_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<EmployeeSecret: record<Created: string, Name: string, Value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($secret_id | is-empty) { error make --unspanned { msg: "path parameter 'SecretId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), secret_id: (encode-path-segment $secret_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Secret/{secret_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create a new employee secret
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/Secret/{SecretId}
# operationId: PutEmployeeSecret
export def "put-employee-secret" [
  employer_id: string
  employee_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<EmployeeSecret: record<Created: string, Name: string, Value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($secret_id | is-empty) { error make --unspanned { msg: "path parameter 'SecretId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), secret_id: (encode-path-segment $secret_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Secret/{secret_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [201]
}

# Get all employee secret links
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Secrets
# operationId: GetEmployeeSecrets
export def "get-employee-secrets" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Secrets") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create a new employee secret
#
# POST /Employer/{EmployerId}/Employee/{EmployeeId}/Secrets
# operationId: PostEmployeeSecret
export def "post-employee-secret" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Secrets") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Get employee summary from employer
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Summary
# operationId: GetEmployeeSummaryFromEmployer
export def "get-employee-summary-from-employer" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Summary") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete employee tag
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}
# operationId: DeleteEmployeeTag
export def "delete-employee-tag" [
  employer_id: string
  employee_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get employee tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}
# operationId: GetTagFromEmployee
export def "get-tag-from-employee" [
  employer_id: string
  employee_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert employee tag
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}
# operationId: PutEmployeeTag
export def "put-employee-tag" [
  employer_id: string
  employee_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get employee revision tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}/{EffectiveDate}
# operationId: GetTagFromEmployeeRevision
export def "get-tag-from-employee-revision" [
  employer_id: string
  employee_id: string
  tag_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), tag_id: (encode-path-segment $tag_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Tag/{tag_id}/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all employee tags
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Tags
# operationId: GetTagsFromEmployee
export def "get-tags-from-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all employee revision tags
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Tags/{EffectiveDate}
# operationId: GetTagsFromEmployeeRevision
export def "get-tags-from-employee-revision" [
  employer_id: string
  employee_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Tags/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete an Employee revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/{EffectiveDate}
# operationId: DeleteEmployeeRevision
export def "delete-employee-revision" [
  employer_id: string
  employee_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get employee by effective date.
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/{EffectiveDate}
# operationId: GetEmployeeByEffectiveDate
export def "get-employee-by-effective-date" [
  employer_id: string
  employee_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get employee summary by effective date.
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/{EffectiveDate}/Summary
# operationId: GetEmployeeSummaryByEffectiveDate
export def "get-employee-summary-by-effective-date" [
  employer_id: string
  employee_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), employee_id: (encode-path-segment $employee_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/{effective_date}/Summary") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get employees from employer.
#
# GET /Employer/{EmployerId}/Employees
# operationId: GetEmployeesFromEmployer
export def "get-employees-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/Employees") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create a new Employee
#
# POST /Employer/{EmployerId}/Employees
# operationId: PostEmployeeIntoEmployer
# --Employee shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, ... (41 more fields)}
export def "post-employee-into-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --employee: record # shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, ... (41 more fields)}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/Employees") $auth.query)
  let req_body = {"Employee": $employee} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get employee summaries from employer.
#
# GET /Employer/{EmployerId}/Employees/Summary
# operationId: GetEmployeeSummariesFromEmployer
export def "get-employee-summaries-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/Employees/Summary") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get employees with tag
#
# GET /Employer/{EmployerId}/Employees/Tag/{TagId}
# operationId: GetEmployeesWithTag
export def "get-employees-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/Employees/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all employee tags
#
# GET /Employer/{EmployerId}/Employees/Tags
# operationId: GetAllEmployeeTags
export def "get-all-employee-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/Employees/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get employees from employer at a given effective date.
#
# GET /Employer/{EmployerId}/Employees/{EffectiveDate}
# operationId: GetEmployeesByEffectiveDate
export def "get-employees-by-effective-date" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/Employees/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get employee summaries from employer at a given effective date.
#
# GET /Employer/{EmployerId}/Employees/{EffectiveDate}/Summary
# operationId: GetEmployeeSummariesByEffectiveDate
export def "get-employee-summaries-by-effective-date" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/Employees/{effective_date}/Summary") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete an holiday scheme
#
# DELETE /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}
# operationId: DeleteHolidayScheme
export def "delete-holiday-scheme" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($holiday_scheme_id | is-empty) { error make --unspanned { msg: "path parameter 'HolidaySchemeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), holiday_scheme_id: (encode-path-segment $holiday_scheme_id)} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get holiday scheme from employer
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}
# operationId: GetHolidaySchemeFromEmployer
export def "get-holiday-scheme-from-employer" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($holiday_scheme_id | is-empty) { error make --unspanned { msg: "path parameter 'HolidaySchemeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), holiday_scheme_id: (encode-path-segment $holiday_scheme_id)} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Patches the holiday scheme
#
# PATCH /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}
# operationId: PatchHolidayScheme
# --HolidayScheme shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
export def "patch-holiday-scheme" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --holiday-scheme: record # shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
]: any -> record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($holiday_scheme_id | is-empty) { error make --unspanned { msg: "path parameter 'HolidaySchemeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), holiday_scheme_id: (encode-path-segment $holiday_scheme_id)} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}") $auth.query)
  let req_body = {"HolidayScheme": $holiday_scheme} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates the holiday scheme
#
# PUT /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}
# operationId: PutHolidaySchemeIntoEmployer
# --HolidayScheme shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
export def "put-holiday-scheme-into-employer" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --holiday-scheme: record # shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
]: any -> record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($holiday_scheme_id | is-empty) { error make --unspanned { msg: "path parameter 'HolidaySchemeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), holiday_scheme_id: (encode-path-segment $holiday_scheme_id)} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}") $auth.query)
  let req_body = {"HolidayScheme": $holiday_scheme} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete an HolidayScheme revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Revision/{RevisionNumber}
# operationId: DeleteHolidaySchemeRevisionByNumber
export def "delete-holiday-scheme-revision-by-number" [
  employer_id: string
  holiday_scheme_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($holiday_scheme_id | is-empty) { error make --unspanned { msg: "path parameter 'HolidaySchemeId' must be non-empty" } }
  if ($revision_number | is-empty) { error make --unspanned { msg: "path parameter 'RevisionNumber' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), holiday_scheme_id: (encode-path-segment $holiday_scheme_id), revision_number: (encode-path-segment $revision_number)} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Revision/{revision_number}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the holiday scheme revision by revision number
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Revision/{RevisionNumber}
# operationId: GetHolidaySchemeRevisionByNumber
export def "get-holiday-scheme-revision-by-number" [
  employer_id: string
  holiday_scheme_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($holiday_scheme_id | is-empty) { error make --unspanned { msg: "path parameter 'HolidaySchemeId' must be non-empty" } }
  if ($revision_number | is-empty) { error make --unspanned { msg: "path parameter 'RevisionNumber' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), holiday_scheme_id: (encode-path-segment $holiday_scheme_id), revision_number: (encode-path-segment $revision_number)} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Revision/{revision_number}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all holiday scheme revisions
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Revisions
# operationId: GetHolidaySchemeRevisions
export def "get-holiday-scheme-revisions" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($holiday_scheme_id | is-empty) { error make --unspanned { msg: "path parameter 'HolidaySchemeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), holiday_scheme_id: (encode-path-segment $holiday_scheme_id)} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Revisions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete holiday scheme tag
#
# DELETE /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}
# operationId: DeleteHolidaySchemeTag
export def "delete-holiday-scheme-tag" [
  employer_id: string
  holiday_scheme_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($holiday_scheme_id | is-empty) { error make --unspanned { msg: "path parameter 'HolidaySchemeId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), holiday_scheme_id: (encode-path-segment $holiday_scheme_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get holiday scheme tag
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}
# operationId: GetTagFromHolidayScheme
export def "get-tag-from-holiday-scheme" [
  employer_id: string
  holiday_scheme_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($holiday_scheme_id | is-empty) { error make --unspanned { msg: "path parameter 'HolidaySchemeId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), holiday_scheme_id: (encode-path-segment $holiday_scheme_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert holiday scheme tag
#
# PUT /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}
# operationId: PutHolidaySchemeTag
export def "put-holiday-scheme-tag" [
  employer_id: string
  holiday_scheme_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($holiday_scheme_id | is-empty) { error make --unspanned { msg: "path parameter 'HolidaySchemeId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), holiday_scheme_id: (encode-path-segment $holiday_scheme_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get holiday scheme revision tag
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}/{EffectiveDate}
# operationId: GetTagFromHolidaySchemeRevision
export def "get-tag-from-holiday-scheme-revision" [
  employer_id: string
  holiday_scheme_id: string
  tag_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($holiday_scheme_id | is-empty) { error make --unspanned { msg: "path parameter 'HolidaySchemeId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), holiday_scheme_id: (encode-path-segment $holiday_scheme_id), tag_id: (encode-path-segment $tag_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Tag/{tag_id}/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all tags from the holiday scheme
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tags
# operationId: GetTagsFromHolidayScheme
export def "get-tags-from-holiday-scheme" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($holiday_scheme_id | is-empty) { error make --unspanned { msg: "path parameter 'HolidaySchemeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), holiday_scheme_id: (encode-path-segment $holiday_scheme_id)} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all holiday scheme revision tags
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tags/{EffectiveDate}
# operationId: GetTagsFromHolidaySchemeRevision
export def "get-tags-from-holiday-scheme-revision" [
  employer_id: string
  holiday_scheme_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($holiday_scheme_id | is-empty) { error make --unspanned { msg: "path parameter 'HolidaySchemeId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), holiday_scheme_id: (encode-path-segment $holiday_scheme_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Tags/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete an holiday scheme revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/{EffectiveDate}
# operationId: DeleteHolidaySchemeRevision
export def "delete-holiday-scheme-revision" [
  employer_id: string
  holiday_scheme_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($holiday_scheme_id | is-empty) { error make --unspanned { msg: "path parameter 'HolidaySchemeId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), holiday_scheme_id: (encode-path-segment $holiday_scheme_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get holiday scheme by effective date.
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/{EffectiveDate}
# operationId: GetHolidaySchemeByEffectiveDate
export def "get-holiday-scheme-by-effective-date" [
  employer_id: string
  holiday_scheme_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($holiday_scheme_id | is-empty) { error make --unspanned { msg: "path parameter 'HolidaySchemeId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), holiday_scheme_id: (encode-path-segment $holiday_scheme_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get holiday schemes from employer.
#
# GET /Employer/{EmployerId}/HolidaySchemes
# operationId: GetHolidaySchemesFromEmployer
export def "get-holiday-schemes-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/HolidaySchemes") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create a new holiday scheme
#
# POST /Employer/{EmployerId}/HolidaySchemes
# operationId: PostHolidaySchemeIntoEmployer
# --HolidayScheme shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
export def "post-holiday-scheme-into-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --holiday-scheme: record # shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/HolidaySchemes") $auth.query)
  let req_body = {"HolidayScheme": $holiday_scheme} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get holiday schemes with tag
#
# GET /Employer/{EmployerId}/HolidaySchemes/Tag/{TagId}
# operationId: GetHolidaySchemesWithTag
export def "get-holiday-schemes-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/HolidaySchemes/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all holiday scheme tags
#
# GET /Employer/{EmployerId}/HolidaySchemes/Tags
# operationId: GetAllHolidaySchemeTags
export def "get-all-holiday-scheme-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/HolidaySchemes/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get holiday schemes from employer at a given effective date.
#
# GET /Employer/{EmployerId}/HolidaySchemes/{EffectiveDate}
# operationId: GetHolidaySchemesByEffectiveDate
export def "get-holiday-schemes-by-effective-date" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/HolidaySchemes/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Deletes a Journal instruction
#
# DELETE /Employer/{EmployerId}/JournalInstruction/{JournalInstructionId}
# operationId: DeleteJournalInstruction
export def "delete-journal-instruction" [
  employer_id: string
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($journal_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'JournalInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), journal_instruction_id: (encode-path-segment $journal_instruction_id)} | format pattern "/Employer/{employer_id}/JournalInstruction/{journal_instruction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the specified journal instruction from the employer
#
# GET /Employer/{EmployerId}/JournalInstruction/{JournalInstructionId}
# operationId: GetJournalInstructionFromEmployer
export def "get-journal-instruction-from-employer" [
  employer_id: string
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($journal_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'JournalInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), journal_instruction_id: (encode-path-segment $journal_instruction_id)} | format pattern "/Employer/{employer_id}/JournalInstruction/{journal_instruction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Update a Journal Instruction
#
# PUT /Employer/{EmployerId}/JournalInstruction/{JournalInstructionId}
# operationId: PutJournalInstruction
export def "put-journal-instruction" [
  employer_id: string
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($journal_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'JournalInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), journal_instruction_id: (encode-path-segment $journal_instruction_id)} | format pattern "/Employer/{employer_id}/JournalInstruction/{journal_instruction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Gets the Journal instructions from the specified employer
#
# GET /Employer/{EmployerId}/JournalInstructions
# operationId: GetJournalInstructionsFromEmployer
export def "get-journal-instructions-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/JournalInstructions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Creates a new Journal Instruction
#
# POST /Employer/{EmployerId}/JournalInstructions
# operationId: PostJournalInstruction
export def "post-journal-instruction" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/JournalInstructions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Gets the specified journal Line from the employer
#
# GET /Employer/{EmployerId}/JournalLine/{JournalLineId}
# operationId: GetJournalLineFromEmployer
export def "get-journal-line-from-employer" [
  employer_id: string
  journal_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<JournalLine: record<Credit: float, Debit: float, Description: string, Employee: record<_href: string, _rel: string, _title: string>, Generated: string, Grouping: string, LedgerTarget: string, NomCode: string, PayFrequency: string, PayRun: record<_href: string, _rel: string, _title: string>, SubContractor: record<_href: string, _rel: string, _title: string>, SubNomCode: string, TaxPeriod: int, TaxYear: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($journal_line_id | is-empty) { error make --unspanned { msg: "path parameter 'JournalLineId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), journal_line_id: (encode-path-segment $journal_line_id)} | format pattern "/Employer/{employer_id}/JournalLine/{journal_line_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete journal line tag
#
# DELETE /Employer/{EmployerId}/JournalLine/{JournalLineId}/Tag/{TagId}
# operationId: DeleteJournalLineTag
export def "delete-journal-line-tag" [
  employer_id: string
  journal_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($journal_line_id | is-empty) { error make --unspanned { msg: "path parameter 'JournalLineId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), journal_line_id: (encode-path-segment $journal_line_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/JournalLine/{journal_line_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get journal line tag
#
# GET /Employer/{EmployerId}/JournalLine/{JournalLineId}/Tag/{TagId}
# operationId: GetTagFromJournalLine
export def "get-tag-from-journal-line" [
  employer_id: string
  journal_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($journal_line_id | is-empty) { error make --unspanned { msg: "path parameter 'JournalLineId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), journal_line_id: (encode-path-segment $journal_line_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/JournalLine/{journal_line_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert journal line tag
#
# PUT /Employer/{EmployerId}/JournalLine/{JournalLineId}/Tag/{TagId}
# operationId: PutJournalLineTag
export def "put-journal-line-tag" [
  employer_id: string
  journal_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($journal_line_id | is-empty) { error make --unspanned { msg: "path parameter 'JournalLineId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), journal_line_id: (encode-path-segment $journal_line_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/JournalLine/{journal_line_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get tags from journal line
#
# GET /Employer/{EmployerId}/JournalLine/{JournalLineId}/Tags
# operationId: GetTagsFromJournalLine
export def "get-tags-from-journal-line" [
  employer_id: string
  journal_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($journal_line_id | is-empty) { error make --unspanned { msg: "path parameter 'JournalLineId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), journal_line_id: (encode-path-segment $journal_line_id)} | format pattern "/Employer/{employer_id}/JournalLine/{journal_line_id}/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the Journal Lines from the specified employer
#
# GET /Employer/{EmployerId}/JournalLines
# operationId: GetJournalLinesFromEmployer
export def "get-journal-lines-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/JournalLines") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get links to tagged journal lines
#
# GET /Employer/{EmployerId}/JournalLines/Tag/{TagId}
# operationId: GetAllJournalLinesWithTag
export def "get-all-journal-lines-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/JournalLines/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all journal line tags
#
# GET /Employer/{EmployerId}/JournalLines/Tags
# operationId: GetAllJournalLineTags
export def "get-all-journal-line-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/JournalLines/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Deletes the nominal codes
#
# DELETE /Employer/{EmployerId}/NominalCode/{NominalCodeId}
# operationId: DeleteNominalCode
export def "delete-nominal-code" [
  employer_id: string
  nominal_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($nominal_code_id | is-empty) { error make --unspanned { msg: "path parameter 'NominalCodeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), nominal_code_id: (encode-path-segment $nominal_code_id)} | format pattern "/Employer/{employer_id}/NominalCode/{nominal_code_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the nominal code
#
# GET /Employer/{EmployerId}/NominalCode/{NominalCodeId}
# operationId: GetNominalCodeFromEmployer
export def "get-nominal-code-from-employer" [
  employer_id: string
  nominal_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<NominalCode: record<Description: string, Key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($nominal_code_id | is-empty) { error make --unspanned { msg: "path parameter 'NominalCodeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), nominal_code_id: (encode-path-segment $nominal_code_id)} | format pattern "/Employer/{employer_id}/NominalCode/{nominal_code_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert nominal code
#
# PUT /Employer/{EmployerId}/NominalCode/{NominalCodeId}
# operationId: PutNominalCode
# --NominalCode shape: {Description?: string, Key?: string}
export def "put-nominal-code" [
  employer_id: string
  nominal_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --nominal-code: record # shape: {Description?: string, Key?: string}
]: any -> record<NominalCode: record<Description: string, Key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($nominal_code_id | is-empty) { error make --unspanned { msg: "path parameter 'NominalCodeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), nominal_code_id: (encode-path-segment $nominal_code_id)} | format pattern "/Employer/{employer_id}/NominalCode/{nominal_code_id}") $auth.query)
  let req_body = {"NominalCode": $nominal_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [201]
}

# Gets the pay codes by nominal code
#
# GET /Employer/{EmployerId}/NominalCode/{NominalCodeId}/PayCodes
# operationId: GetPayCodesFromNominalCode
export def "get-pay-codes-from-nominal-code" [
  employer_id: string
  nominal_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($nominal_code_id | is-empty) { error make --unspanned { msg: "path parameter 'NominalCodeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), nominal_code_id: (encode-path-segment $nominal_code_id)} | format pattern "/Employer/{employer_id}/NominalCode/{nominal_code_id}/PayCodes") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the nominal codes
#
# GET /Employer/{EmployerId}/NominalCodes
# operationId: GetNominalCodesFromEmployer
export def "get-nominal-codes-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/NominalCodes") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert nominal code
#
# POST /Employer/{EmployerId}/NominalCodes
# operationId: PostNominalCode
# --NominalCode shape: {Description?: string, Key?: string}
export def "post-nominal-code" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --nominal-code: record # shape: {Description?: string, Key?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/NominalCodes") $auth.query)
  let req_body = {"NominalCode": $nominal_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Deletes a pay code
#
# DELETE /Employer/{EmployerId}/PayCode/{PayCodeId}
# operationId: DeletePayCode
export def "delete-pay-code" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_code_id | is-empty) { error make --unspanned { msg: "path parameter 'PayCodeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_code_id: (encode-path-segment $pay_code_id)} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the specified pay code from the employer
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}
# operationId: GetPayCodeFromEmployer
export def "get-pay-code-from-employer" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<_href: string, _rel: string, _title: string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_code_id | is-empty) { error make --unspanned { msg: "path parameter 'PayCodeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_code_id: (encode-path-segment $pay_code_id)} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Patches the pay code
#
# PATCH /Employer/{EmployerId}/PayCode/{PayCodeId}
# operationId: PatchPayCode
# --PayCode shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
export def "patch-pay-code" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --pay-code: record # shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
]: any -> record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<_href: string, _rel: string, _title: string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_code_id | is-empty) { error make --unspanned { msg: "path parameter 'PayCodeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_code_id: (encode-path-segment $pay_code_id)} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}") $auth.query)
  let req_body = {"PayCode": $pay_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates a pay code
#
# PUT /Employer/{EmployerId}/PayCode/{PayCodeId}
# operationId: PutPayCode
# --PayCode shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
export def "put-pay-code" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --pay-code: record # shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
]: any -> record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<_href: string, _rel: string, _title: string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_code_id | is-empty) { error make --unspanned { msg: "path parameter 'PayCodeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_code_id: (encode-path-segment $pay_code_id)} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}") $auth.query)
  let req_body = {"PayCode": $pay_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete an PayCode revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/PayCode/{PayCodeId}/Revision/{RevisionNumber}
# operationId: DeletePayCodeRevisionByNumber
export def "delete-pay-code-revision-by-number" [
  employer_id: string
  pay_code_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_code_id | is-empty) { error make --unspanned { msg: "path parameter 'PayCodeId' must be non-empty" } }
  if ($revision_number | is-empty) { error make --unspanned { msg: "path parameter 'RevisionNumber' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_code_id: (encode-path-segment $pay_code_id), revision_number: (encode-path-segment $revision_number)} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/Revision/{revision_number}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the pay code by revision number
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/Revision/{RevisionNumber}
# operationId: GetPayCodeRevisionByNumber
export def "get-pay-code-revision-by-number" [
  employer_id: string
  pay_code_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<_href: string, _rel: string, _title: string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_code_id | is-empty) { error make --unspanned { msg: "path parameter 'PayCodeId' must be non-empty" } }
  if ($revision_number | is-empty) { error make --unspanned { msg: "path parameter 'RevisionNumber' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_code_id: (encode-path-segment $pay_code_id), revision_number: (encode-path-segment $revision_number)} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/Revision/{revision_number}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all revisions of the Pay Code
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/Revisions
# operationId: GetPayCodeRevisions
export def "get-pay-code-revisions" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_code_id | is-empty) { error make --unspanned { msg: "path parameter 'PayCodeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_code_id: (encode-path-segment $pay_code_id)} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/Revisions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete pay code tag
#
# DELETE /Employer/{EmployerId}/PayCode/{PayCodeId}/Tag/{TagId}
# operationId: DeletePayCodeTag
export def "delete-pay-code-tag" [
  employer_id: string
  pay_code_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_code_id | is-empty) { error make --unspanned { msg: "path parameter 'PayCodeId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_code_id: (encode-path-segment $pay_code_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get pay code tag
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/Tag/{TagId}
# operationId: GetTagFromPayCode
export def "get-tag-from-pay-code" [
  employer_id: string
  pay_code_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_code_id | is-empty) { error make --unspanned { msg: "path parameter 'PayCodeId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_code_id: (encode-path-segment $pay_code_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert pay code tag
#
# PUT /Employer/{EmployerId}/PayCode/{PayCodeId}/Tag/{TagId}
# operationId: PutPayCodeTag
export def "put-pay-code-tag" [
  employer_id: string
  pay_code_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_code_id | is-empty) { error make --unspanned { msg: "path parameter 'PayCodeId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_code_id: (encode-path-segment $pay_code_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get all pay code tags
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/Tags
# operationId: GetTagsFromPayCode
export def "get-tags-from-pay-code" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_code_id | is-empty) { error make --unspanned { msg: "path parameter 'PayCodeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_code_id: (encode-path-segment $pay_code_id)} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Deletes a pay code revision
#
# DELETE /Employer/{EmployerId}/PayCode/{PayCodeId}/{EffectiveDate}
# operationId: DeletePayCodeRevision
export def "delete-pay-code-revision" [
  employer_id: string
  pay_code_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_code_id | is-empty) { error make --unspanned { msg: "path parameter 'PayCodeId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_code_id: (encode-path-segment $pay_code_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets pay code for specified date
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/{EffectiveDate}
# operationId: GetPayCodeByEffectiveDate
export def "get-pay-code-by-effective-date" [
  employer_id: string
  pay_code_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<_href: string, _rel: string, _title: string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_code_id | is-empty) { error make --unspanned { msg: "path parameter 'PayCodeId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_code_id: (encode-path-segment $pay_code_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the pay codes from the employer
#
# GET /Employer/{EmployerId}/PayCodes
# operationId: GetPayCodesFromEmployer
export def "get-pay-codes-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/PayCodes") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create a new pay code
#
# POST /Employer/{EmployerId}/PayCodes
# operationId: PostPayCode
# --PayCode shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
export def "post-pay-code" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --pay-code: record # shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/PayCodes") $auth.query)
  let req_body = {"PayCode": $pay_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get pay codes with tag
#
# GET /Employer/{EmployerId}/PayCodes/Tag/{TagId}
# operationId: GetPayCodesWithTag
export def "get-pay-codes-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/PayCodes/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all pay code tags
#
# GET /Employer/{EmployerId}/PayCodes/Tags
# operationId: GetAllPayCodeTags
export def "get-all-pay-code-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/PayCodes/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets all pay codes for specified date
#
# GET /Employer/{EmployerId}/PayCodes/{EffectiveDate}
# operationId: GetPayCodesByEffectiveDate
export def "get-pay-codes-by-effective-date" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/PayCodes/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Deletes a pay schedule
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}
# operationId: DeletePaySchedule
export def "delete-pay-schedule" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the specified pay schedule from the employer
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}
# operationId: GetPayScheduleFromEmployer
export def "get-pay-schedule-from-employer" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<PaySchedule: record<MetaData: record, Name: string, PayFrequency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Updates a pay schedule
#
# PUT /Employer/{EmployerId}/PaySchedule/{PayScheduleId}
# operationId: PutPaySchedule
# --PaySchedule shape: {MetaData?: record, Name?: string, PayFrequency?: "Weekly"|"Monthly"|"TwoWeekly"|"FourWeekly"|"Yearly"}
export def "put-pay-schedule" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --pay-schedule: record # shape: {MetaData?: record, Name?: string, PayFrequency?: "Weekly"|"Monthly"|"TwoWeekly"|"FourWeekly"|"Yearly"}
]: any -> record<PaySchedule: record<MetaData: record, Name: string, PayFrequency: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}") $auth.query)
  let req_body = {"PaySchedule": $pay_schedule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get all employees revisions from a pay schedule.
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Employees
# operationId: GetEmployeesFromPaySchedule
export def "get-employees-from-pay-schedule" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/Employees") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get employees from a pay schedule on effective date.
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Employees/{EffectiveDate}
# operationId: GetEmployeesFromPayScheduleOnEffectiveDate
export def "get-employees-from-pay-schedule-on-effective-date" [
  employer_id: string
  pay_schedule_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/Employees/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Deletes a pay run
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}
# operationId: DeletePayRun
export def "delete-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($pay_run_id | is-empty) { error make --unspanned { msg: "path parameter 'PayRunId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), pay_run_id: (encode-path-segment $pay_run_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the pay run from the pay schedule
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}
# operationId: GetPayRunFromPaySchedule
export def "get-pay-run-from-pay-schedule" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<PayRun: record<Executed: string, IsSupplementary: bool, PayFrequency: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentDate: string, PeriodEnd: string, PeriodStart: string, ProceedingPayRun: record<_href: string, _rel: string, _title: string>, Sequence: int, TaxPeriod: int, TaxYear: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($pay_run_id | is-empty) { error make --unspanned { msg: "path parameter 'PayRunId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), pay_run_id: (encode-path-segment $pay_run_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get the auto enrolment assessments
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/AEAssessments
# operationId: GetAEAssessmentsFromPayRun
export def "get-ae-assessments-from-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($pay_run_id | is-empty) { error make --unspanned { msg: "path parameter 'PayRunId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), pay_run_id: (encode-path-segment $pay_run_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/AEAssessments") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get links to all commentaries for the specified pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Commentaries
# operationId: GetCommentariesFromPayRun
export def "get-commentaries-from-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($pay_run_id | is-empty) { error make --unspanned { msg: "path parameter 'PayRunId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), pay_run_id: (encode-path-segment $pay_run_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/Commentaries") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Deletes a pay run employee
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Employee/{EmployeeId}
# operationId: DeletePayRunEmployee
export def "delete-pay-run-employee" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($pay_run_id | is-empty) { error make --unspanned { msg: "path parameter 'PayRunId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), pay_run_id: (encode-path-segment $pay_run_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/Employee/{employee_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get commentary from payrun by specified employee.
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Employee/{EmployeeId}/Commentary
# operationId: GetCommentaryFromPayRunByEmployee
export def "get-commentary-from-pay-run-by-employee" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Commentary: record<Created: string, Detail: string, Employee: record<_href: string, _rel: string, _title: string>, PayRun: record<_href: string, _rel: string, _title: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($pay_run_id | is-empty) { error make --unspanned { msg: "path parameter 'PayRunId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), pay_run_id: (encode-path-segment $pay_run_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/Employee/{employee_id}/Commentary") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get employees from the pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Employees
# operationId: GetEmployeesFromPayRun
export def "get-employees-from-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($pay_run_id | is-empty) { error make --unspanned { msg: "path parameter 'PayRunId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), pay_run_id: (encode-path-segment $pay_run_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/Employees") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the journal Lines from the specified pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/JournalLines
# operationId: GetJournalLinesFromPayRun
export def "get-journal-lines-from-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($pay_run_id | is-empty) { error make --unspanned { msg: "path parameter 'PayRunId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), pay_run_id: (encode-path-segment $pay_run_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/JournalLines") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the pay lines from the specified pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/PayLines
# operationId: GetPayLinesFromPayRun
export def "get-pay-lines-from-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($pay_run_id | is-empty) { error make --unspanned { msg: "path parameter 'PayRunId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), pay_run_id: (encode-path-segment $pay_run_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/PayLines") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the report lines from the specified pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/ReportLines
# operationId: GetReportLinesFromPayRun
export def "get-report-lines-from-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($pay_run_id | is-empty) { error make --unspanned { msg: "path parameter 'PayRunId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), pay_run_id: (encode-path-segment $pay_run_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/ReportLines") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete pay run tag
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tag/{TagId}
# operationId: DeletePayRunTag
export def "delete-pay-run-tag" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($pay_run_id | is-empty) { error make --unspanned { msg: "path parameter 'PayRunId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), pay_run_id: (encode-path-segment $pay_run_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get pay run tag
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tag/{TagId}
# operationId: GetTagFromPayRun
export def "get-tag-from-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($pay_run_id | is-empty) { error make --unspanned { msg: "path parameter 'PayRunId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), pay_run_id: (encode-path-segment $pay_run_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert pay run tag
#
# PUT /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tag/{TagId}
# operationId: PutPayRunTag
export def "put-pay-run-tag" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($pay_run_id | is-empty) { error make --unspanned { msg: "path parameter 'PayRunId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), pay_run_id: (encode-path-segment $pay_run_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get all pay run tags
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tags
# operationId: GetTagsFromPayRun
export def "get-tags-from-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($pay_run_id | is-empty) { error make --unspanned { msg: "path parameter 'PayRunId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), pay_run_id: (encode-path-segment $pay_run_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the pay runs from the pay schedule
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRuns
# operationId: GetPayRunsFromPaySchedule
export def "get-pay-runs-from-pay-schedule" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRuns") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get pay runs with tag
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRuns/Tag/{TagId}
# operationId: GetPayRunsWithTag
export def "get-pay-runs-with-tag" [
  employer_id: string
  pay_schedule_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRuns/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all pay run tags
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRuns/Tags
# operationId: GetAllPayRunTags
export def "get-all-pay-run-tags" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRuns/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete pay schedule tag
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tag/{TagId}
# operationId: DeletePayScheduleTag
export def "delete-pay-schedule-tag" [
  employer_id: string
  pay_schedule_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get pay schedule tag
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tag/{TagId}
# operationId: GetTagFromPaySchedule
export def "get-tag-from-pay-schedule" [
  employer_id: string
  pay_schedule_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert pay schedule tag
#
# PUT /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tag/{TagId}
# operationId: PutPayScheduleTag
export def "put-pay-schedule-tag" [
  employer_id: string
  pay_schedule_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get all pay schedule tags
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tags
# operationId: GetTagsFromPaySchedule
export def "get-tags-from-pay-schedule" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pay_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'PayScheduleId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pay_schedule_id: (encode-path-segment $pay_schedule_id)} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the pay schedule from the specified employer
#
# GET /Employer/{EmployerId}/PaySchedules
# operationId: GetPaySchedulesFromEmployer
export def "get-pay-schedules-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/PaySchedules") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create a new pay schedule
#
# POST /Employer/{EmployerId}/PaySchedules
# operationId: PostPaySchedule
# --PaySchedule shape: {MetaData?: record, Name?: string, PayFrequency?: "Weekly"|"Monthly"|"TwoWeekly"|"FourWeekly"|"Yearly"}
export def "post-pay-schedule" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --pay-schedule: record # shape: {MetaData?: record, Name?: string, PayFrequency?: "Weekly"|"Monthly"|"TwoWeekly"|"FourWeekly"|"Yearly"}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/PaySchedules") $auth.query)
  let req_body = {"PaySchedule": $pay_schedule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get pay schedule with tag
#
# GET /Employer/{EmployerId}/PaySchedules/Tag/{TagId}
# operationId: GetPaySchedulesWithTag
export def "get-pay-schedules-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/PaySchedules/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all pay schedule tags
#
# GET /Employer/{EmployerId}/PaySchedules/Tags
# operationId: GetAllPayScheduleTags
export def "get-all-pay-schedule-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/PaySchedules/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete a Pension
#
# DELETE /Employer/{EmployerId}/Pension/{PensionId}
# operationId: DeletePension
export def "delete-pension" [
  employer_id: string
  pension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pension_id | is-empty) { error make --unspanned { msg: "path parameter 'PensionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pension_id: (encode-path-segment $pension_id)} | format pattern "/Employer/{employer_id}/Pension/{pension_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get pension from employer
#
# GET /Employer/{EmployerId}/Pension/{PensionId}
# operationId: GetPensionFromEmployer
export def "get-pension-from-employer" [
  employer_id: string
  pension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pension_id | is-empty) { error make --unspanned { msg: "path parameter 'PensionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pension_id: (encode-path-segment $pension_id)} | format pattern "/Employer/{employer_id}/Pension/{pension_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Patches the pension
#
# PATCH /Employer/{EmployerId}/Pension/{PensionId}
# operationId: PatchPension
# --Pension shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ... (13 more fields)}
export def "patch-pension" [
  employer_id: string
  pension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --pension: record # shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ... (13 more fields)}
]: any -> record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pension_id | is-empty) { error make --unspanned { msg: "path parameter 'PensionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pension_id: (encode-path-segment $pension_id)} | format pattern "/Employer/{employer_id}/Pension/{pension_id}") $auth.query)
  let req_body = {"Pension": $pension} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates the Pension
#
# PUT /Employer/{EmployerId}/Pension/{PensionId}
# operationId: PutPensionIntoEmployer
# --Pension shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ... (13 more fields)}
export def "put-pension-into-employer" [
  employer_id: string
  pension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --pension: record # shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ... (13 more fields)}
]: any -> record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pension_id | is-empty) { error make --unspanned { msg: "path parameter 'PensionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pension_id: (encode-path-segment $pension_id)} | format pattern "/Employer/{employer_id}/Pension/{pension_id}") $auth.query)
  let req_body = {"Pension": $pension} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete an Pension revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/Pension/{PensionId}/Revision/{RevisionNumber}
# operationId: DeletePensionRevisionByNumber
export def "delete-pension-revision-by-number" [
  employer_id: string
  pension_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pension_id | is-empty) { error make --unspanned { msg: "path parameter 'PensionId' must be non-empty" } }
  if ($revision_number | is-empty) { error make --unspanned { msg: "path parameter 'RevisionNumber' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pension_id: (encode-path-segment $pension_id), revision_number: (encode-path-segment $revision_number)} | format pattern "/Employer/{employer_id}/Pension/{pension_id}/Revision/{revision_number}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the pension by revision number
#
# GET /Employer/{EmployerId}/Pension/{PensionId}/Revision/{RevisionNumber}
# operationId: GetPensionRevisionByNumber
export def "get-pension-revision-by-number" [
  employer_id: string
  pension_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pension_id | is-empty) { error make --unspanned { msg: "path parameter 'PensionId' must be non-empty" } }
  if ($revision_number | is-empty) { error make --unspanned { msg: "path parameter 'RevisionNumber' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pension_id: (encode-path-segment $pension_id), revision_number: (encode-path-segment $revision_number)} | format pattern "/Employer/{employer_id}/Pension/{pension_id}/Revision/{revision_number}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all pension revisions
#
# GET /Employer/{EmployerId}/Pension/{PensionId}/Revisions
# operationId: GetPensionRevisions
export def "get-pension-revisions" [
  employer_id: string
  pension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pension_id | is-empty) { error make --unspanned { msg: "path parameter 'PensionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pension_id: (encode-path-segment $pension_id)} | format pattern "/Employer/{employer_id}/Pension/{pension_id}/Revisions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete an Pension revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/Pension/{PensionId}/{EffectiveDate}
# operationId: DeletePensionRevision
export def "delete-pension-revision" [
  employer_id: string
  pension_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pension_id | is-empty) { error make --unspanned { msg: "path parameter 'PensionId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pension_id: (encode-path-segment $pension_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/Pension/{pension_id}/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get pension by effective date.
#
# GET /Employer/{EmployerId}/Pension/{PensionId}/{EffectiveDate}
# operationId: GetPensionByEffectiveDate
export def "get-pension-by-effective-date" [
  employer_id: string
  pension_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($pension_id | is-empty) { error make --unspanned { msg: "path parameter 'PensionId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), pension_id: (encode-path-segment $pension_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/Pension/{pension_id}/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get pensions from employer.
#
# GET /Employer/{EmployerId}/Pensions
# operationId: GetPensionsFromEmployer
export def "get-pensions-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/Pensions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create a new Pension
#
# POST /Employer/{EmployerId}/Pensions
# operationId: PostPensionIntoEmployer
# --Pension shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ... (13 more fields)}
export def "post-pension-into-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --pension: record # shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ... (13 more fields)}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/Pensions") $auth.query)
  let req_body = {"Pension": $pension} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get pensions from employer at a given effective date.
#
# GET /Employer/{EmployerId}/Pensions/{EffectiveDate}
# operationId: GetPensionsByEffectiveDate
export def "get-pensions-by-effective-date" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/Pensions/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the specified report line from the employer
#
# GET /Employer/{EmployerId}/ReportLine/{ReportLineId}
# operationId: GetReportLineFromEmployer
export def "get-report-line-from-employer" [
  employer_id: string
  report_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<ReportLine: record<Description: string, Generated: string, TaxMonth: int, TaxYear: int, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($report_line_id | is-empty) { error make --unspanned { msg: "path parameter 'ReportLineId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), report_line_id: (encode-path-segment $report_line_id)} | format pattern "/Employer/{employer_id}/ReportLine/{report_line_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the report lines from the specified employer
#
# GET /Employer/{EmployerId}/ReportLines
# operationId: GetReportLinesFromEmployer
export def "get-report-lines-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/ReportLines") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Deletes a reporting instruction
#
# DELETE /Employer/{EmployerId}/ReportingInstruction/{ReportingInstructionId}
# operationId: DeleteReportingInstruction
export def "delete-reporting-instruction" [
  employer_id: string
  reporting_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($reporting_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'ReportingInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), reporting_instruction_id: (encode-path-segment $reporting_instruction_id)} | format pattern "/Employer/{employer_id}/ReportingInstruction/{reporting_instruction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the specified reporting instruction from the employer
#
# GET /Employer/{EmployerId}/ReportingInstruction/{ReportingInstructionId}
# operationId: GetReportingInstructionFromEmployer
export def "get-reporting-instruction-from-employer" [
  employer_id: string
  reporting_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<ReportingInstruction: record<EndDate: string, StartDate: string, TaxMonth: int, TaxYear: int, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($reporting_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'ReportingInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), reporting_instruction_id: (encode-path-segment $reporting_instruction_id)} | format pattern "/Employer/{employer_id}/ReportingInstruction/{reporting_instruction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Update a reporting Instruction
#
# PUT /Employer/{EmployerId}/ReportingInstruction/{ReportingInstructionId}
# operationId: PutReportingInstruction
# --ReportingInstruction shape: {EndDate?: string, StartDate?: string, TaxMonth?: int, TaxYear?: int, Value?: float}
export def "put-reporting-instruction" [
  employer_id: string
  reporting_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --reporting-instruction: record # shape: {EndDate?: string, StartDate?: string, TaxMonth?: int, TaxYear?: int, Value?: float}
]: any -> record<ReportingInstruction: record<EndDate: string, StartDate: string, TaxMonth: int, TaxYear: int, Value: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($reporting_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'ReportingInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), reporting_instruction_id: (encode-path-segment $reporting_instruction_id)} | format pattern "/Employer/{employer_id}/ReportingInstruction/{reporting_instruction_id}") $auth.query)
  let req_body = {"ReportingInstruction": $reporting_instruction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets the reporting instructions from the specified employer
#
# GET /Employer/{EmployerId}/ReportingInstructions
# operationId: GetReportingInstructionsFromEmployer
export def "get-reporting-instructions-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/ReportingInstructions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Creates a new Reporting Instruction
#
# POST /Employer/{EmployerId}/ReportingInstructions
# operationId: PostReportingInstruction
# --ReportingInstruction shape: {EndDate?: string, StartDate?: string, TaxMonth?: int, TaxYear?: int, Value?: float}
export def "post-reporting-instruction" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --reporting-instruction: record # shape: {EndDate?: string, StartDate?: string, TaxMonth?: int, TaxYear?: int, Value?: float}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/ReportingInstructions") $auth.query)
  let req_body = {"ReportingInstruction": $reporting_instruction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete an Employer revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/Revision/{RevisionNumber}
# operationId: DeleteEmployerRevisionByNumber
export def "delete-employer-revision-by-number" [
  employer_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($revision_number | is-empty) { error make --unspanned { msg: "path parameter 'RevisionNumber' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), revision_number: (encode-path-segment $revision_number)} | format pattern "/Employer/{employer_id}/Revision/{revision_number}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the employer by revision number
#
# GET /Employer/{EmployerId}/Revision/{RevisionNumber}
# operationId: GetEmployerRevisionByNumber
export def "get-employer-revision-by-number" [
  employer_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($revision_number | is-empty) { error make --unspanned { msg: "path parameter 'RevisionNumber' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), revision_number: (encode-path-segment $revision_number)} | format pattern "/Employer/{employer_id}/Revision/{revision_number}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the employer summary by revision number
#
# GET /Employer/{EmployerId}/Revision/{RevisionNumber}/Summary
# operationId: GetEmployerRevisionSummaryByNumber
export def "get-employer-revision-summary-by-number" [
  employer_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($revision_number | is-empty) { error make --unspanned { msg: "path parameter 'RevisionNumber' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), revision_number: (encode-path-segment $revision_number)} | format pattern "/Employer/{employer_id}/Revision/{revision_number}/Summary") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the employer revisions
#
# GET /Employer/{EmployerId}/Revisions
# operationId: GetEmployerRevisions
export def "get-employer-revisions" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/Revisions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all employer revision summaries
#
# GET /Employer/{EmployerId}/Revisions/Summary
# operationId: GetEmployerRevisionSummaries
export def "get-employer-revision-summaries" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/Revisions/Summary") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete the RTI transaction
#
# DELETE /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}
# operationId: DeleteRtiTransaction
export def "delete-rti-transaction" [
  employer_id: string
  rti_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($rti_transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'RtiTransactionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), rti_transaction_id: (encode-path-segment $rti_transaction_id)} | format pattern "/Employer/{employer_id}/RtiTransaction/{rti_transaction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get the RTI transaction
#
# GET /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}
# operationId: GetRtiTransactionFromEmployer
export def "get-rti-transaction-from-employer" [
  employer_id: string
  rti_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<RtiTransactionBase: record<EmployerCore: record<_href: string, _rel: string, _title: string>, RequestData: string, ResponseData: string, RtiType: string, TaxYear: int, Timestamp: string, TransactionStatus: string, TransmissionDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($rti_transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'RtiTransactionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), rti_transaction_id: (encode-path-segment $rti_transaction_id)} | format pattern "/Employer/{employer_id}/RtiTransaction/{rti_transaction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get the RTI transaction summary
#
# GET /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Summary
# operationId: GetRtiTransactionSummaryFromEmployer
export def "get-rti-transaction-summary-from-employer" [
  employer_id: string
  rti_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<RtiTransactionBase: record<EmployerCore: record<_href: string, _rel: string, _title: string>, RequestData: string, ResponseData: string, RtiType: string, TaxYear: int, Timestamp: string, TransactionStatus: string, TransmissionDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($rti_transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'RtiTransactionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), rti_transaction_id: (encode-path-segment $rti_transaction_id)} | format pattern "/Employer/{employer_id}/RtiTransaction/{rti_transaction_id}/Summary") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete RTI transaction tag
#
# DELETE /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tag/{TagId}
# operationId: DeleteRtiTransactionTag
export def "delete-rti-transaction-tag" [
  employer_id: string
  rti_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($rti_transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'RtiTransactionId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), rti_transaction_id: (encode-path-segment $rti_transaction_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/RtiTransaction/{rti_transaction_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get RTI transaction tag
#
# GET /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tag/{TagId}
# operationId: GetTagFromRtiTransaction
export def "get-tag-from-rti-transaction" [
  employer_id: string
  rti_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($rti_transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'RtiTransactionId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), rti_transaction_id: (encode-path-segment $rti_transaction_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/RtiTransaction/{rti_transaction_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert RTI transaction tag
#
# PUT /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tag/{TagId}
# operationId: PutRtiTransactionTag
export def "put-rti-transaction-tag" [
  employer_id: string
  rti_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($rti_transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'RtiTransactionId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), rti_transaction_id: (encode-path-segment $rti_transaction_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/RtiTransaction/{rti_transaction_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get all tags from RTI transaction
#
# GET /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tags
# operationId: GetTagsFromRtiTransaction
export def "get-tags-from-rti-transaction" [
  employer_id: string
  rti_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($rti_transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'RtiTransactionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), rti_transaction_id: (encode-path-segment $rti_transaction_id)} | format pattern "/Employer/{employer_id}/RtiTransaction/{rti_transaction_id}/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all RTI transactions for the employer
#
# GET /Employer/{EmployerId}/RtiTransactions
# operationId: GetRtiTransactionsFromEmployer
export def "get-rti-transactions-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/RtiTransactions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all RTI transaction summaries for the employer
#
# GET /Employer/{EmployerId}/RtiTransactions/Summary
# operationId: GetRtiTransactionSummariesFromEmployer
export def "get-rti-transaction-summaries-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/RtiTransactions/Summary") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get RTI transactions with tag
#
# GET /Employer/{EmployerId}/RtiTransactions/Tag/{TagId}
# operationId: GetRtiTransactionsWithTag
export def "get-rti-transactions-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/RtiTransactions/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all RTI transaction tags
#
# GET /Employer/{EmployerId}/RtiTransactions/Tags
# operationId: GetAllRtiTransactionTags
export def "get-all-rti-transaction-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/RtiTransactions/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Deletes employer secret
#
# DELETE /Employer/{EmployerId}/Secret/{SecretId}
# operationId: DeleteEmployerSecret
export def "delete-employer-secret" [
  employer_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($secret_id | is-empty) { error make --unspanned { msg: "path parameter 'SecretId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), secret_id: (encode-path-segment $secret_id)} | format pattern "/Employer/{employer_id}/Secret/{secret_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get employer secret
#
# GET /Employer/{EmployerId}/Secret/{SecretId}
# operationId: GetEmployerSecret
export def "get-employer-secret" [
  employer_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<EmployerSecret: record<Created: string, Name: string, Value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($secret_id | is-empty) { error make --unspanned { msg: "path parameter 'SecretId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), secret_id: (encode-path-segment $secret_id)} | format pattern "/Employer/{employer_id}/Secret/{secret_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create a new employer secret
#
# PUT /Employer/{EmployerId}/Secret/{SecretId}
# operationId: PutEmployerSecret
export def "put-employer-secret" [
  employer_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<EmployerSecret: record<Created: string, Name: string, Value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($secret_id | is-empty) { error make --unspanned { msg: "path parameter 'SecretId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), secret_id: (encode-path-segment $secret_id)} | format pattern "/Employer/{employer_id}/Secret/{secret_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [201]
}

# Get all employer secret links
#
# GET /Employer/{EmployerId}/Secrets
# operationId: GetEmployerSecrets
export def "get-employer-secrets" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/Secrets") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create a new employer secret
#
# POST /Employer/{EmployerId}/Secrets
# operationId: PostEmployerSecret
export def "post-employer-secret" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/Secrets") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Delete an sub contractor
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}
# operationId: DeleteSubContractor
export def "delete-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get sub contractor from employer
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}
# operationId: GetSubContractorFromEmployer
export def "get-sub-contractor-from-employer" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Patches the sub contractor
#
# PATCH /Employer/{EmployerId}/SubContractor/{SubContractorId}
# operationId: PatchSubContractor
# --SubContractor shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", ... (14 more fields)}
export def "patch-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --sub-contractor: record # shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", ... (14 more fields)}
]: any -> record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}") $auth.query)
  let req_body = {"SubContractor": $sub_contractor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates the sub contractor
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}
# operationId: PutSubContractorIntoEmployer
# --SubContractor shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", ... (14 more fields)}
export def "put-sub-contractor-into-employer" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --sub-contractor: record # shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", ... (14 more fields)}
]: any -> record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}") $auth.query)
  let req_body = {"SubContractor": $sub_contractor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a CIS instruction
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}
# operationId: DeleteCisInstruction
export def "delete-cis-instruction" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($cis_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'CisInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), cis_instruction_id: (encode-path-segment $cis_instruction_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstruction/{cis_instruction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get CIS instruction from sub contractor
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}
# operationId: GetCisInstructionFromSubContractor
export def "get-cis-instruction-from-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<CisInstruction: record<CisLineTag: string, CisLineType: string, Description: string, PayFrequency: string, PeriodEnd: int, PeriodStart: int, TaxYearEnd: int, TaxYearStart: int, UOM: string, Units: float, VAT: float, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($cis_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'CisInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), cis_instruction_id: (encode-path-segment $cis_instruction_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstruction/{cis_instruction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Patches the CIS instruction
#
# PATCH /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}
# operationId: PatchCisInstruction
export def "patch-cis-instruction" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<CisInstruction: record<CisLineTag: string, CisLineType: string, Description: string, PayFrequency: string, PeriodEnd: int, PeriodStart: int, TaxYearEnd: int, TaxYearStart: int, UOM: string, Units: float, VAT: float, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($cis_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'CisInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), cis_instruction_id: (encode-path-segment $cis_instruction_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstruction/{cis_instruction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req null $insecure $raw $allow_errors $full [200]
}

# Updates the CIS instruction
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}
# operationId: PutCisInstructionIntoSubContractor
# --CisInstruction shape: {CisLineTag?: string, CisLineType?: string, Description?: string, PayFrequency?: "Monthly"|"Weekly", PeriodEnd?: int, PeriodStart?: int, TaxYearEnd?: int, TaxYearStart?: int, UOM?: "NotSet"|"Minute"|"Hour"|"Day"|"Week"|"Month"|"Year"|"Unit", Units?: float, VAT?: float, Value?: float}
export def "put-cis-instruction-into-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --cis-instruction: record # shape: {CisLineTag?: string, CisLineType?: string, Description?: string, PayFrequency?: "Monthly"|"Weekly", PeriodEnd?: int, PeriodStart?: int, TaxYearEnd?: int, TaxYearStart?: int, UOM?: "NotSet"|"Minute"|"Hour"|"Day"|"Week"|"Month"|"Year"|"Unit", Units?: float, VAT?: float, Value?: float}
]: any -> record<CisInstruction: record<CisLineTag: string, CisLineType: string, Description: string, PayFrequency: string, PeriodEnd: int, PeriodStart: int, TaxYearEnd: int, TaxYearStart: int, UOM: string, Units: float, VAT: float, Value: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($cis_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'CisInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), cis_instruction_id: (encode-path-segment $cis_instruction_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstruction/{cis_instruction_id}") $auth.query)
  let req_body = {"CisInstruction": $cis_instruction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete CIS instruction tag
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tag/{TagId}
# operationId: DeleteCisInstructionTag
export def "delete-cis-instruction-tag" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($cis_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'CisInstructionId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), cis_instruction_id: (encode-path-segment $cis_instruction_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstruction/{cis_instruction_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get CIS instruction tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tag/{TagId}
# operationId: GetTagFromCisInstruction
export def "get-tag-from-cis-instruction" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($cis_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'CisInstructionId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), cis_instruction_id: (encode-path-segment $cis_instruction_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstruction/{cis_instruction_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert CIS instruction tag
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tag/{TagId}
# operationId: PutCisInstructionTag
export def "put-cis-instruction-tag" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($cis_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'CisInstructionId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), cis_instruction_id: (encode-path-segment $cis_instruction_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstruction/{cis_instruction_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get all tags from the CIS instruction
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tags
# operationId: GetTagsFromCisInstruction
export def "get-tags-from-cis-instruction" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($cis_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'CisInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), cis_instruction_id: (encode-path-segment $cis_instruction_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstruction/{cis_instruction_id}/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get CIS instructions from sub contractor.
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions
# operationId: GetCisInstructionsFromSubContractor
export def "get-cis-instructions-from-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstructions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create a new CIS instruction
#
# POST /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions
# operationId: PostCisInstructionIntoSubContractor
# --CisInstruction shape: {CisLineTag?: string, CisLineType?: string, Description?: string, PayFrequency?: "Monthly"|"Weekly", PeriodEnd?: int, PeriodStart?: int, TaxYearEnd?: int, TaxYearStart?: int, UOM?: "NotSet"|"Minute"|"Hour"|"Day"|"Week"|"Month"|"Year"|"Unit", Units?: float, VAT?: float, Value?: float}
export def "post-cis-instruction-into-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --cis-instruction: record # shape: {CisLineTag?: string, CisLineType?: string, Description?: string, PayFrequency?: "Monthly"|"Weekly", PeriodEnd?: int, PeriodStart?: int, TaxYearEnd?: int, TaxYearStart?: int, UOM?: "NotSet"|"Minute"|"Hour"|"Day"|"Week"|"Month"|"Year"|"Unit", Units?: float, VAT?: float, Value?: float}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstructions") $auth.query)
  let req_body = {"CisInstruction": $cis_instruction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get CIS instructions with tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions/Tag/{TagId}
# operationId: GetCisInstructionsWithTag
export def "get-cis-instructions-with-tag" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstructions/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all CIS instruction tags
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions/Tags
# operationId: GetAllCisInstructionTags
export def "get-all-cis-instruction-tags" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstructions/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete a CIS line
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}
# operationId: DeleteCisLine
export def "delete-cis-line" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($cis_line_id | is-empty) { error make --unspanned { msg: "path parameter 'CisLineId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), cis_line_id: (encode-path-segment $cis_line_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLine/{cis_line_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get CIS line from sub contractor
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}
# operationId: GetCisLineFromSubContractor
export def "get-cis-line-from-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<CisLine: record<CisDeduction: float, CisLineType: string, Description: string, Generated: string, GrossPay: float, NominalCodeKey: string, PayFrequency: string, TaxMonth: int, TaxPeriod: int, TaxTreatment: string, TaxYear: int, UOM: string, UnitRate: float, Units: float, VAT: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($cis_line_id | is-empty) { error make --unspanned { msg: "path parameter 'CisLineId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), cis_line_id: (encode-path-segment $cis_line_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLine/{cis_line_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete CIS line tag
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tag/{TagId}
# operationId: DeleteCisLineTag
export def "delete-cis-line-tag" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($cis_line_id | is-empty) { error make --unspanned { msg: "path parameter 'CisLineId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), cis_line_id: (encode-path-segment $cis_line_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLine/{cis_line_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get CIS line tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tag/{TagId}
# operationId: GetTagFromCisLine
export def "get-tag-from-cis-line" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($cis_line_id | is-empty) { error make --unspanned { msg: "path parameter 'CisLineId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), cis_line_id: (encode-path-segment $cis_line_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLine/{cis_line_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert CIS line tag
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tag/{TagId}
# operationId: PutCisLineTag
export def "put-cis-line-tag" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($cis_line_id | is-empty) { error make --unspanned { msg: "path parameter 'CisLineId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), cis_line_id: (encode-path-segment $cis_line_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLine/{cis_line_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get all tags from the CIS line
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tags
# operationId: GetTagsFromCisLine
export def "get-tags-from-cis-line" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($cis_line_id | is-empty) { error make --unspanned { msg: "path parameter 'CisLineId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), cis_line_id: (encode-path-segment $cis_line_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLine/{cis_line_id}/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get CIS lines from sub contractor.
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLines
# operationId: GetCisLinesFromSubContractor
export def "get-cis-lines-from-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLines") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get CIS lines with tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLines/Tag/{TagId}
# operationId: GetCisLinesWithTag
export def "get-cis-lines-with-tag" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLines/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all CIS line tags
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLines/Tags
# operationId: GetAllCisLineTags
export def "get-all-cis-line-tags" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLines/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the journal Lines from the specified sub contractor
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/JournalLines
# operationId: GetJournalLinesFromSubContractor
export def "get-journal-lines-from-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/JournalLines") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete an SubContractor revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/Revision/{RevisionNumber}
# operationId: DeleteSubContractorRevisionByNumber
export def "delete-sub-contractor-revision-by-number" [
  employer_id: string
  sub_contractor_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($revision_number | is-empty) { error make --unspanned { msg: "path parameter 'RevisionNumber' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), revision_number: (encode-path-segment $revision_number)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Revision/{revision_number}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the sub contractor by revision number
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Revision/{RevisionNumber}
# operationId: GetSubContractorRevisionByNumber
export def "get-sub-contractor-revision-by-number" [
  employer_id: string
  sub_contractor_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($revision_number | is-empty) { error make --unspanned { msg: "path parameter 'RevisionNumber' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), revision_number: (encode-path-segment $revision_number)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Revision/{revision_number}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all sub contractor revisions
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Revisions
# operationId: GetSubContractorRevisions
export def "get-sub-contractor-revisions" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Revisions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete sub contractor tag
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}
# operationId: DeleteSubContractorTag
export def "delete-sub-contractor-tag" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get sub contractor tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}
# operationId: GetTagFromSubContractor
export def "get-tag-from-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert sub contractor tag
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}
# operationId: PutSubContractorTag
export def "put-sub-contractor-tag" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get sub contractor revision tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}/{EffectiveDate}
# operationId: GetTagFromSubContractorRevision
export def "get-tag-from-sub-contractor-revision" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), tag_id: (encode-path-segment $tag_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Tag/{tag_id}/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all tags from the sub contractor
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tags
# operationId: GetTagsFromSubContractor
export def "get-tags-from-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all sub contractor revision tags
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tags/{EffectiveDate}
# operationId: GetTagsFromSubContractorRevision
export def "get-tags-from-sub-contractor-revision" [
  employer_id: string
  sub_contractor_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Tags/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete an sub contractor revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/{EffectiveDate}
# operationId: DeleteSubContractorRevision
export def "delete-sub-contractor-revision" [
  employer_id: string
  sub_contractor_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get sub contractor by effective date.
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/{EffectiveDate}
# operationId: GetSubContractorByEffectiveDate
export def "get-sub-contractor-by-effective-date" [
  employer_id: string
  sub_contractor_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($sub_contractor_id | is-empty) { error make --unspanned { msg: "path parameter 'SubContractorId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), sub_contractor_id: (encode-path-segment $sub_contractor_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get sub contractors from employer.
#
# GET /Employer/{EmployerId}/SubContractors
# operationId: GetSubContractorsFromEmployer
export def "get-sub-contractors-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/SubContractors") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create a new sub contractor
#
# POST /Employer/{EmployerId}/SubContractors
# operationId: PostSubContractorIntoEmployer
# --SubContractor shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", ... (14 more fields)}
export def "post-sub-contractor-into-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --sub-contractor: record # shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", ... (14 more fields)}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/SubContractors") $auth.query)
  let req_body = {"SubContractor": $sub_contractor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get sub contractors with tag
#
# GET /Employer/{EmployerId}/SubContractors/Tag/{TagId}
# operationId: GetSubContractorsWithTag
export def "get-sub-contractors-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/SubContractors/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all sub contractor tags
#
# GET /Employer/{EmployerId}/SubContractors/Tags
# operationId: GetAllSubContractorTags
export def "get-all-sub-contractor-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/SubContractors/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get sub contractors from employer at a given effective date.
#
# GET /Employer/{EmployerId}/SubContractors/{EffectiveDate}
# operationId: GetSubContractorsByEffectiveDate
export def "get-sub-contractors-by-effective-date" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/SubContractors/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get employer summary
#
# GET /Employer/{EmployerId}/Summary
# operationId: GetEmployerSummary
export def "get-employer-summary" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/Summary") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete employer tag
#
# DELETE /Employer/{EmployerId}/Tag/{TagId}
# operationId: DeleteEmployerTag
export def "delete-employer-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get employer tag
#
# GET /Employer/{EmployerId}/Tag/{TagId}
# operationId: GetTagFromEmployer
export def "get-tag-from-employer" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert employer tag
#
# PUT /Employer/{EmployerId}/Tag/{TagId}
# operationId: PutEmployerTag
export def "put-employer-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get employer revision tag
#
# GET /Employer/{EmployerId}/Tag/{TagId}/{EffectiveDate}
# operationId: GetTagFromEmployerRevision
export def "get-tag-from-employer-revision" [
  employer_id: string
  tag_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), tag_id: (encode-path-segment $tag_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/Tag/{tag_id}/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all employer tags
#
# GET /Employer/{EmployerId}/Tags
# operationId: GetTagsFromEmployer
export def "get-tags-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all employer revision tags
#
# GET /Employer/{EmployerId}/Tags/{EffectiveDate}
# operationId: GetTagsFromEmployerRevision
export def "get-tags-from-employer-revision" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/Tags/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete third party transaction
#
# DELETE /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}
# operationId: DeleteThirdPartyTransaction
export def "delete-third-party-transaction" [
  employer_id: string
  third_party_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($third_party_transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'ThirdPartyTransactionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), third_party_transaction_id: (encode-path-segment $third_party_transaction_id)} | format pattern "/Employer/{employer_id}/ThirdPartyTransaction/{third_party_transaction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a third party transaction
#
# GET /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}
# operationId: GetThirdPartyTransaction
export def "get-third-party-transaction" [
  employer_id: string
  third_party_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($third_party_transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'ThirdPartyTransactionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), third_party_transaction_id: (encode-path-segment $third_party_transaction_id)} | format pattern "/Employer/{employer_id}/ThirdPartyTransaction/{third_party_transaction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete third party transaction tag
#
# DELETE /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tag/{TagId}
# operationId: DeleteThirdPartyTransactionTag
export def "delete-third-party-transaction-tag" [
  employer_id: string
  third_party_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($third_party_transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'ThirdPartyTransactionId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), third_party_transaction_id: (encode-path-segment $third_party_transaction_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/ThirdPartyTransaction/{third_party_transaction_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get third party transaction tag
#
# GET /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tag/{TagId}
# operationId: GetTagFromThirdPartyTransaction
export def "get-tag-from-third-party-transaction" [
  employer_id: string
  third_party_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($third_party_transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'ThirdPartyTransactionId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), third_party_transaction_id: (encode-path-segment $third_party_transaction_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/ThirdPartyTransaction/{third_party_transaction_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# insert third party transaction tag
#
# PUT /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tag/{TagId}
# operationId: PutThirdPartyTransactionTag
export def "put-third-party-transaction-tag" [
  employer_id: string
  third_party_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($third_party_transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'ThirdPartyTransactionId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), third_party_transaction_id: (encode-path-segment $third_party_transaction_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/ThirdPartyTransaction/{third_party_transaction_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get tags from third party transaction
#
# GET /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tags
# operationId: GetTagsFromThirdPartyTransaction
export def "get-tags-from-third-party-transaction" [
  employer_id: string
  third_party_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($third_party_transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'ThirdPartyTransactionId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), third_party_transaction_id: (encode-path-segment $third_party_transaction_id)} | format pattern "/Employer/{employer_id}/ThirdPartyTransaction/{third_party_transaction_id}/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all third party transaction links
#
# GET /Employer/{EmployerId}/ThirdPartyTransactions
# operationId: GetThirdPartyTransactions
export def "get-third-party-transactions" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/ThirdPartyTransactions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get links to tagged third party transactions
#
# GET /Employer/{EmployerId}/ThirdPartyTransactions/Tag/{TagId}
# operationId: GetAllThirdPartyTransactionsWithTag
export def "get-all-third-party-transactions-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Employer/{employer_id}/ThirdPartyTransactions/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all third party transaction tags
#
# GET /Employer/{EmployerId}/ThirdPartyTransactions/Tags
# operationId: GetAllThirdPartyTransactionTags
export def "get-all-third-party-transaction-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Employer/{employer_id}/ThirdPartyTransactions/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete an Employer revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/{EffectiveDate}
# operationId: DeleteEmployerRevision
export def "delete-employer-revision" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the employer at the specified effective
#
# GET /Employer/{EmployerId}/{EffectiveDate}
# operationId: GetEmployerByEffectiveDate
export def "get-employer-by-effective-date" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get employer summary by effective date.
#
# GET /Employer/{EmployerId}/{EffectiveDate}/Summary
# operationId: GetEmployerSummaryByEffectiveDate
export def "get-employer-summary-by-effective-date" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id), effective_date: (encode-path-segment $effective_date)} | format pattern "/Employer/{employer_id}/{effective_date}/Summary") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets all employers
#
# GET /Employers
# operationId: GetEmployers
export def "get-employers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Employers" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create a new Employer
#
# POST /Employers
# operationId: PostEmployer
# --Employer shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, ... (2 more fields)}
export def "post-employer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --employer: record # shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, ... (2 more fields)}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Employers" $auth.query)
  let req_body = {"Employer": $employer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get employer summaries.
#
# GET /Employers/Summary
# operationId: GetEmployerSummaries
export def "get-employer-summaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Employers/Summary" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get employers with tag
#
# GET /Employers/Tag/{TagId}
# operationId: GetEmployersWithTag
export def "get-employers-with-tag" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/Employers/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all employer tags
#
# GET /Employers/Tags
# operationId: GetAllEmployerTags
export def "get-all-employer-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Employers/Tags" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets all employers at the specified effective date
#
# GET /Employers/{EffectiveDate}
# operationId: GetEmployersByEffectiveDate
export def "get-employers-by-effective-date" [
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({effective_date: (encode-path-segment $effective_date)} | format pattern "/Employers/{effective_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get employer summaries at a given effective date.
#
# GET /Employers/{EffectiveDate}/Summary
# operationId: GetEmployerSummariesByEffectiveDate
export def "get-employer-summaries-by-effective-date" [
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($effective_date | is-empty) { error make --unspanned { msg: "path parameter 'EffectiveDate' must be non-empty" } }
  let full_url = (build-url $base ({effective_date: (encode-path-segment $effective_date)} | format pattern "/Employers/{effective_date}/Summary") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get health check status
#
# GET /Healthcheck
# operationId: GetHealthCheck
export def "get-health-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<HealthCheck: record<Info: string, Version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Healthcheck" $auth.query)
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

# Get all Batch jobs
#
# GET /Jobs/Batch
# operationId: GetBatchJobs
export def "get-batch-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Batch" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create new Batch job
#
# POST /Jobs/Batch
# operationId: PostNewBatchJob
# --BatchJobInstruction shape: {HoldingDate?: string, Instructions?: record, ValidateOnly?: bool}
export def "post-new-batch-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --batch-job-instruction: record # shape: {HoldingDate?: string, Instructions?: record, ValidateOnly?: bool}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Batch" $auth.query)
  let req_body = {"BatchJobInstruction": $batch_job_instruction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete the Batch job
#
# DELETE /Jobs/Batch/{JobId}
# operationId: DeleteBatchJob
export def "delete-batch-job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/Batch/{job_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get the Batch job information
#
# GET /Jobs/Batch/{JobId}/Info
# operationId: GetBatchJobInfo
export def "get-batch-job-info" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/Batch/{job_id}/Info") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get the Batch job progress
#
# GET /Jobs/Batch/{JobId}/Progress
# operationId: GetBatchJobProgress
export def "get-batch-job-progress" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/Batch/{job_id}/Progress") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get the Batch job status
#
# GET /Jobs/Batch/{JobId}/Status
# operationId: GetBatchJobStatus
export def "get-batch-job-status" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/Batch/{job_id}/Status") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all CIS jobs
#
# GET /Jobs/Cis
# operationId: GetCisJobs
export def "get-cis-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Cis" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create new CIS job
#
# POST /Jobs/Cis
# operationId: PostNewCisJob
# --CisJobInstructionBase shape: {Employer?: record, HoldingDate?: string, SubContractors?: record}
export def "post-new-cis-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --cis-job-instruction-base: record # shape: {Employer?: record, HoldingDate?: string, SubContractors?: record}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Cis" $auth.query)
  let req_body = {"CisJobInstructionBase": $cis_job_instruction_base} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete the CIS job
#
# DELETE /Jobs/Cis/{JobId}
# operationId: DeleteCisJob
export def "delete-cis-job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/Cis/{job_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get the CIS job information
#
# GET /Jobs/Cis/{JobId}/Info
# operationId: GetCisJobInfo
export def "get-cis-job-info" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/Cis/{job_id}/Info") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get the CIS job progress
#
# GET /Jobs/Cis/{JobId}/Progress
# operationId: GetCisJobProgress
export def "get-cis-job-progress" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/Cis/{job_id}/Progress") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get the CIS job status
#
# GET /Jobs/Cis/{JobId}/Status
# operationId: GetCisJobStatus
export def "get-cis-job-status" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/Cis/{job_id}/Status") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all DPS jobs
#
# GET /Jobs/Dps
# operationId: GetDpsJobs
export def "get-dps-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Dps" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create new DPS job
#
# POST /Jobs/Dps
# operationId: PostNewDpsJob
# --DpsJobInstruction shape: {Apply?: bool, Employer?: record, FromDate?: string, HoldingDate?: string, MessageTypes?: record, MessagesToProcess?: record, Retrieve?: bool}
export def "post-new-dps-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --dps-job-instruction: record # shape: {Apply?: bool, Employer?: record, FromDate?: string, HoldingDate?: string, MessageTypes?: record, MessagesToProcess?: record, Retrieve?: bool}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Dps" $auth.query)
  let req_body = {"DpsJobInstruction": $dps_job_instruction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete the DPS job
#
# DELETE /Jobs/Dps/{JobId}
# operationId: DeleteDpsJob
export def "delete-dps-job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/Dps/{job_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get the DPS job information
#
# GET /Jobs/Dps/{JobId}/Info
# operationId: GetDpsJobInfo
export def "get-dps-job-info" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/Dps/{job_id}/Info") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get the DPS job progress
#
# GET /Jobs/Dps/{JobId}/Progress
# operationId: GetDpsJobProgress
export def "get-dps-job-progress" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/Dps/{job_id}/Progress") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get the DPS job status
#
# GET /Jobs/Dps/{JobId}/Status
# operationId: GetDpsJobStatus
export def "get-dps-job-status" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/Dps/{job_id}/Status") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets all jobs relating to the employer.
#
# GET /Jobs/Employer/{EmployerId}
# operationId: GetEmployerJobs
export def "get-employer-jobs" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employer_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployerId' must be non-empty" } }
  let full_url = (build-url $base ({employer_id: (encode-path-segment $employer_id)} | format pattern "/Jobs/Employer/{employer_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all PayRun jobs
#
# GET /Jobs/PayRuns
# operationId: GetPayRunJobs
export def "get-pay-run-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/PayRuns" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create new PayRun job
#
# POST /Jobs/PayRuns
# operationId: PostNewPayRunJob
# --PayRunJobInstruction shape: {Employees?: record, EndDate?: string, HoldingDate?: string, IsSupplementary?: bool, PaySchedule?: record, PaymentDate?: string, StartDate?: string}
export def "post-new-pay-run-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --pay-run-job-instruction: record # shape: {Employees?: record, EndDate?: string, HoldingDate?: string, IsSupplementary?: bool, PaySchedule?: record, PaymentDate?: string, StartDate?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/PayRuns" $auth.query)
  let req_body = {"PayRunJobInstruction": $pay_run_job_instruction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete the pay run job
#
# DELETE /Jobs/PayRuns/{JobId}
# operationId: DeletePayRunJob
export def "delete-pay-run-job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/PayRuns/{job_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get the pay run job information
#
# GET /Jobs/PayRuns/{JobId}/Info
# operationId: GetPayRunJobInfo
export def "get-pay-run-job-info" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/PayRuns/{job_id}/Info") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get the pay run job progress
#
# GET /Jobs/PayRuns/{JobId}/Progress
# operationId: GetPayRunJobProgress
export def "get-pay-run-job-progress" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/PayRuns/{job_id}/Progress") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get the pay run job status
#
# GET /Jobs/PayRuns/{JobId}/Status
# operationId: GetPayRunJobStatus
export def "get-pay-run-job-status" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/PayRuns/{job_id}/Status") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all RTI jobs
#
# GET /Jobs/Rti
# operationId: GetRtiJobs
export def "get-rti-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Rti" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create new RTI job
#
# POST /Jobs/Rti
# operationId: PostNewRtiJob
# --RtiJobInstruction shape: {EarlierTaxYear?: int, Employer?: record, FinalSubmissionForYear?: bool, Generate?: bool, HoldingDate?: string, LateReason?: "A"|"B"|"C"|"D"|"F"|"G"|"H", NoPaymentForPeriodFrom?: string, NoPaymentForPeriodTo?: string, PaySchedule?: record, PaymentDate?: string, PeriodOfInactivityFrom?: string, PeriodOfInactivityTo?: string, RtiTransaction?: record, RtiType?: string, SchemeCeased?: string, TaxMonth?: int, TaxYear?: int, Timestamp?: string, Transmit?: bool}
export def "post-new-rti-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --rti-job-instruction: record # shape: {EarlierTaxYear?: int, Employer?: record, FinalSubmissionForYear?: bool, Generate?: bool, HoldingDate?: string, LateReason?: "A"|"B"|"C"|"D"|"F"|"G"|"H", NoPaymentForPeriodFrom?: string, NoPaymentForPeriodTo?: string, PaySchedule?: record, PaymentDate?: string, PeriodOfInactivityFrom?: string, PeriodOfInactivityTo?: string, RtiTransaction?: record, RtiType?: string, SchemeCeased?: string, TaxMonth?: int, TaxYear?: int, Timestamp?: string, Transmit?: bool}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Rti" $auth.query)
  let req_body = {"RtiJobInstruction": $rti_job_instruction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete the RTI job
#
# DELETE /Jobs/Rti/{JobId}
# operationId: DeleteRtiJob
export def "delete-rti-job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/Rti/{job_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get the RTI job information
#
# GET /Jobs/Rti/{JobId}/Info
# operationId: GetRtiJobInfo
export def "get-rti-job-info" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/Rti/{job_id}/Info") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get the RTI job progress
#
# GET /Jobs/Rti/{JobId}/Progress
# operationId: GetRtiJobProgress
export def "get-rti-job-progress" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/Rti/{job_id}/Progress") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get the RTI job status
#
# GET /Jobs/Rti/{JobId}/Status
# operationId: GetRtiJobStatus
export def "get-rti-job-status" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/Rti/{job_id}/Status") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all Third Party jobs
#
# GET /Jobs/ThirdParty
# operationId: GetThirdPartyJobs
export def "get-third-party-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/ThirdParty" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create new Third Party job
#
# POST /Jobs/ThirdParty
# operationId: PostNewThirdPartyJob
# --ThirdPartyJobInstruction shape: {EmployerHref?: string, HoldingDate?: string, InstructionType?: string, MetaData?: record, PayLoad?: string}
export def "post-new-third-party-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --third-party-job-instruction: record # shape: {EmployerHref?: string, HoldingDate?: string, InstructionType?: string, MetaData?: record, PayLoad?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/ThirdParty" $auth.query)
  let req_body = {"ThirdPartyJobInstruction": $third_party_job_instruction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete the Third Party job
#
# DELETE /Jobs/ThirdParty/{JobId}
# operationId: DeleteThirdPartyJob
export def "delete-third-party-job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/ThirdParty/{job_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get the Third Party job information
#
# GET /Jobs/ThirdParty/{JobId}/Info
# operationId: GetThirdPartyJobInfo
export def "get-third-party-job-info" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/ThirdParty/{job_id}/Info") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get the Third Party job progress
#
# GET /Jobs/ThirdParty/{JobId}/Progress
# operationId: GetThirdPartyJobProgress
export def "get-third-party-job-progress" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/ThirdParty/{job_id}/Progress") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get the Third Party job status
#
# GET /Jobs/ThirdParty/{JobId}/Status
# operationId: GetThirdPartyJobStatus
export def "get-third-party-job-status" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/Jobs/ThirdParty/{job_id}/Status") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Deletes a Journal instruction template
#
# DELETE /JournalInstruction/{JournalInstructionId}
# operationId: DeleteJournalInstructionTemplate
export def "delete-journal-instruction-template" [
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($journal_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'JournalInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({journal_instruction_id: (encode-path-segment $journal_instruction_id)} | format pattern "/JournalInstruction/{journal_instruction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the Journal instructions template for the application
#
# GET /JournalInstruction/{JournalInstructionId}
# operationId: GetJournalInstructionTemplate
export def "get-journal-instruction-template" [
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($journal_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'JournalInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({journal_instruction_id: (encode-path-segment $journal_instruction_id)} | format pattern "/JournalInstruction/{journal_instruction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Update a Journal Instruction template
#
# PUT /JournalInstruction/{JournalInstructionId}
# operationId: PutJournalInstructionTemplate
export def "put-journal-instruction-template" [
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($journal_instruction_id | is-empty) { error make --unspanned { msg: "path parameter 'JournalInstructionId' must be non-empty" } }
  let full_url = (build-url $base ({journal_instruction_id: (encode-path-segment $journal_instruction_id)} | format pattern "/JournalInstruction/{journal_instruction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Gets the Journal instructions templates for the application
#
# GET /JournalInstructions
# operationId: GetJournalInstructionTemplates
export def "get-journal-instruction-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/JournalInstructions" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Creates a new Journal Instruction template
#
# POST /JournalInstructions
# operationId: PostJournalInstructionTemplate
export def "post-journal-instruction-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/JournalInstructions" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Deletes the permission object
#
# DELETE /Permission/{PermissionId}
# operationId: DeletePermission
export def "delete-permission" [
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($permission_id | is-empty) { error make --unspanned { msg: "path parameter 'PermissionId' must be non-empty" } }
  let full_url = (build-url $base ({permission_id: (encode-path-segment $permission_id)} | format pattern "/Permission/{permission_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Gets the permission object
#
# GET /Permission/{PermissionId}
# operationId: GetPermission
export def "get-permission" [
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Permission: record<Description: string, Expression: string, Name: string, Policy: string, Verbs: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($permission_id | is-empty) { error make --unspanned { msg: "path parameter 'PermissionId' must be non-empty" } }
  let full_url = (build-url $base ({permission_id: (encode-path-segment $permission_id)} | format pattern "/Permission/{permission_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Patch permission object
#
# PATCH /Permission/{PermissionId}
# operationId: PatchPermission
export def "patch-permission" [
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Permission: record<Description: string, Expression: string, Name: string, Policy: string, Verbs: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($permission_id | is-empty) { error make --unspanned { msg: "path parameter 'PermissionId' must be non-empty" } }
  let full_url = (build-url $base ({permission_id: (encode-path-segment $permission_id)} | format pattern "/Permission/{permission_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req null $insecure $raw $allow_errors $full [200]
}

# Puts permisson object
#
# PUT /Permission/{PermissionId}
# operationId: PutPermission
export def "put-permission" [
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Permission: record<Description: string, Expression: string, Name: string, Policy: string, Verbs: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($permission_id | is-empty) { error make --unspanned { msg: "path parameter 'PermissionId' must be non-empty" } }
  let full_url = (build-url $base ({permission_id: (encode-path-segment $permission_id)} | format pattern "/Permission/{permission_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Delete Permission tag
#
# DELETE /Permission/{PermissionId}/Tag/{TagId}
# operationId: DeletePermissionTag
export def "delete-permission-tag" [
  permission_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($permission_id | is-empty) { error make --unspanned { msg: "path parameter 'PermissionId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({permission_id: (encode-path-segment $permission_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Permission/{permission_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get Permission tag
#
# GET /Permission/{PermissionId}/Tag/{TagId}
# operationId: GetTagFromPermission
export def "get-tag-from-permission" [
  permission_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($permission_id | is-empty) { error make --unspanned { msg: "path parameter 'PermissionId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({permission_id: (encode-path-segment $permission_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Permission/{permission_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert Permission tag
#
# PUT /Permission/{PermissionId}/Tag/{TagId}
# operationId: PutPermissionTag
export def "put-permission-tag" [
  permission_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($permission_id | is-empty) { error make --unspanned { msg: "path parameter 'PermissionId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({permission_id: (encode-path-segment $permission_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/Permission/{permission_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get tags from Permission
#
# GET /Permission/{PermissionId}/Tags
# operationId: GetTagsFromPermission
export def "get-tags-from-permission" [
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($permission_id | is-empty) { error make --unspanned { msg: "path parameter 'PermissionId' must be non-empty" } }
  let full_url = (build-url $base ({permission_id: (encode-path-segment $permission_id)} | format pattern "/Permission/{permission_id}/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets all permission objects
#
# GET /Permissions
# operationId: GetPermissions
export def "get-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Permissions" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Post permisson object
#
# POST /Permissions
# operationId: PostPermission
export def "post-permission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Permissions" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get links to tagged Permissions
#
# GET /Permissions/Tag/{TagId}
# operationId: GetAllPermissionsWithTag
export def "get-all-permissions-with-tag" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/Permissions/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all Permission tags
#
# GET /Permissions/Tags
# operationId: GetAllPermissionTags
export def "get-all-permission-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Permissions/Tags" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get the query result
#
# POST /Query
# operationId: GetQueryResponse
# --Query shape: {Encoding?: string, ExcludeNullOrEmptyElements?: bool, Groups?: record, RootNodeName?: string, SuppressMetricAttributes?: bool, Variables?: record}
export def "get-query-response" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --query: record # shape: {Encoding?: string, ExcludeNullOrEmptyElements?: bool, Groups?: record, RootNodeName?: string, SuppressMetricAttributes?: bool, Variables?: record}
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Query" $auth.query)
  let req_body = {"Query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets the journal expression data schema
#
# GET /ReferenceData/JournalExpressionDataTable
# operationId: GetJournalExpressionSchema
export def "get-journal-expression-schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ReferenceData/JournalExpressionDataTable" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Runs the active pay instructions report
#
# GET /Report/ACTPAYINS/run
# operationId: GetActivePayInstructionsReportOutput
export def "get-active-pay-instructions-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --employee-key: string # The employee unique key. E.g. EE001
  --active-on: string # The active date to consider. E.g 2017-04-05 (format: date)
  --from-date: string # The lower filter date. E.g 2016-04-06 (format: date)
  --to-date: string # The upper filter date. E.g 2017-04-05 (format: date)
  --type: string # the data type to filter on. E.g. TaxPayInstruction
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "EmployeeKey" $employee_key "scalar") (serialize-qp "ActiveOn" $active_on "scalar") (serialize-qp "FromDate" $from_date "scalar") (serialize-qp "ToDate" $to_date "scalar") (serialize-qp "Type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/ACTPAYINS/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "EmployeeKey": $employee_key, "ActiveOn": $active_on, "FromDate": $from_date, "ToDate": $to_date, "Type": $type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the AOE liability report
#
# GET /Report/AOELIABILITY/run
# operationId: GetAoeLiabilityReportOuput
export def "get-aoe-liability-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --tax-period: string # The tax period number. (format: integer)
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "TaxPeriod" $tax_period "scalar") (serialize-qp "TransformDefinitionKey" $transform_definition_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/AOELIABILITY/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "PayScheduleKey": $pay_schedule_key, "TaxYear": $tax_year, "TaxPeriod": $tax_period, "TransformDefinitionKey": $transform_definition_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the DPS message report
#
# GET /Report/DPSMSG/run
# operationId: GetDpsMessageReportOutput
export def "get-dps-message-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --from-date: string # The lower filter date. E.g 2016-04-06 (format: date)
  --to-date: string # The upper filter date. E.g 2017-04-05 (format: date)
  --message-types: string # The DPS message types as a CSV list. E.g. P6,P9,SL1,SL2
  --message-statuses: string # The DPS message status as a CSV list. E.g. Retrieved,Processed,Blocked,Ignored
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "FromDate" $from_date "scalar") (serialize-qp "ToDate" $to_date "scalar") (serialize-qp "MessageTypes" $message_types "scalar") (serialize-qp "MessageStatuses" $message_statuses "scalar") (serialize-qp "StartIndex" $start_index "scalar") (serialize-qp "MaxIndex" $max_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/DPSMSG/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "FromDate": $from_date, "ToDate": $to_date, "MessageTypes": $message_types, "MessageStatuses": $message_statuses, "StartIndex": $start_index, "MaxIndex": $max_index} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the employer summary report
#
# GET /Report/EMPSUM/run
# operationId: GetEmployerSummaryReportOuput
export def "get-employer-summary-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --context-date: string # The date context for the report. E.g. 2018-04-30 (format: date)
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "ContextDate" $context_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/EMPSUM/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "ContextDate": $context_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the gross to net report
#
# GET /Report/GRO2NET/run
# operationId: GetGrossToNetReportOutput
export def "get-gross-to-net-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --tax-period: string # The tax period number. (format: integer)
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "TaxPeriod" $tax_period "scalar") (serialize-qp "StartIndex" $start_index "scalar") (serialize-qp "MaxIndex" $max_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/GRO2NET/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "PayScheduleKey": $pay_schedule_key, "TaxYear": $tax_year, "TaxPeriod": $tax_period, "StartIndex": $start_index, "MaxIndex": $max_index} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the holiday balance report
#
# GET /Report/HOLBAL/run
# operationId: GetHolidayBalanceReportOutput
export def "get-holiday-balance-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --holiday-year-end: string # The holiday year end for the report. E.g. 2018-12-31 (format: date)
  --employee-codes: string # A comma separated list of the employee codes. E.g. EMP001,EMP002
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "HolidayYearEnd" $holiday_year_end "scalar") (serialize-qp "EmployeeCodes" $employee_codes "scalar") (serialize-qp "StartIndex" $start_index "scalar") (serialize-qp "MaxIndex" $max_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/HOLBAL/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "HolidayYearEnd": $holiday_year_end, "EmployeeCodes": $employee_codes, "StartIndex": $start_index, "MaxIndex": $max_index} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the journal report
#
# GET /Report/JOURNAL/run
# operationId: GetJournalReportOuput
export def "get-journal-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-frequency: string # The pay frequency option. E.g. Monthly
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --tax-period: string # The tax period number. (format: integer)
  --ledger-target: string # Specific to JOURNAL report, a filter used to select the journal lines for the specified ledger target. E.g. [Default]
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayFrequency" $pay_frequency "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "TaxPeriod" $tax_period "scalar") (serialize-qp "LedgerTarget" $ledger_target "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/JOURNAL/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "PayFrequency": $pay_frequency, "TaxYear": $tax_year, "TaxPeriod": $tax_period, "LedgerTarget": $ledger_target} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the last pay date report
#
# GET /Report/LASTPAYDATE/run
# operationId: GetLastPayDateReportOuput
export def "get-last-pay-date-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --employee-key: string # The employee unique key. E.g. EE001
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "EmployeeKey" $employee_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/LASTPAYDATE/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "EmployeeKey": $employee_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the net pay report
#
# GET /Report/NETPAY/run
# operationId: GetNetPayReportOutput
export def "get-net-pay-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --tax-period: string # The tax period number. (format: integer)
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "TaxPeriod" $tax_period "scalar") (serialize-qp "StartIndex" $start_index "scalar") (serialize-qp "MaxIndex" $max_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/NETPAY/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "PayScheduleKey": $pay_schedule_key, "TaxYear": $tax_year, "TaxPeriod": $tax_period, "StartIndex": $start_index, "MaxIndex": $max_index} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the next pay period report
#
# GET /Report/NEXTPERIOD/run
# operationId: GetNextPayPeriodDatesReportOutput
export def "get-next-pay-period-dates-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/NEXTPERIOD/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "PayScheduleKey": $pay_schedule_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the P11 summary report
#
# GET /Report/P11SUM/run
# operationId: GetP11SummaryReportOutput
export def "get-p11-summary-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "StartIndex" $start_index "scalar") (serialize-qp "MaxIndex" $max_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/P11SUM/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "PayScheduleKey": $pay_schedule_key, "TaxYear": $tax_year, "StartIndex": $start_index, "MaxIndex": $max_index} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the P32 report
#
# GET /Report/P32/run
# operationId: GetP32NetReportOutput
export def "get-p32-net-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/P32/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "TaxYear": $tax_year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the P32 summary report
#
# GET /Report/P32SUM/run
# operationId: GetP32SummaryNetReportOutput
export def "get-p32-summary-net-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/P32SUM/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "TaxYear": $tax_year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the P45 report
#
# GET /Report/P45/run
# operationId: GetP45ReportOutput
export def "get-p45-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --employee-key: string # The employee unique key. E.g. EE001
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "EmployeeKey" $employee_key "scalar") (serialize-qp "TransformDefinitionKey" $transform_definition_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/P45/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "EmployeeKey": $employee_key, "TransformDefinitionKey": $transform_definition_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the P60 report
#
# GET /Report/P60/run
# operationId: GetP60ReportOutput
export def "get-p60-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --employee-codes: string # A comma separated list of the employee codes. E.g. EMP001,EMP002
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "EmployeeCodes" $employee_codes "scalar") (serialize-qp "TransformDefinitionKey" $transform_definition_key "scalar") (serialize-qp "StartIndex" $start_index "scalar") (serialize-qp "MaxIndex" $max_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/P60/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "TaxYear": $tax_year, "EmployeeCodes": $employee_codes, "TransformDefinitionKey": $transform_definition_key, "StartIndex": $start_index, "MaxIndex": $max_index} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the PAPDIS report
#
# GET /Report/PAPDIS/run
# operationId: GetPapdisReportOuput
export def "get-papdis-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --payment-date: string # The payment date context for the report. E.g. 2018-04-30 (format: date)
  --pension-key: string # The pension scheme unique key. E.g. PENSCH001
  --message-function-code: string # Specific to PAPDIS report, specifies the business function that the sender is requesting. If left BLANK it will be assumed to be 0 (Enrol / Receive Contributions).
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "PaymentDate" $payment_date "scalar") (serialize-qp "PensionKey" $pension_key "scalar") (serialize-qp "MessageFunctionCode" $message_function_code "scalar") (serialize-qp "TransformDefinitionKey" $transform_definition_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/PAPDIS/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "PayScheduleKey": $pay_schedule_key, "TaxYear": $tax_year, "PaymentDate": $payment_date, "PensionKey": $pension_key, "MessageFunctionCode": $message_function_code, "TransformDefinitionKey": $transform_definition_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the PASS report
#
# GET /Report/PASS/run
# operationId: GetPassReportOuput
export def "get-pass-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --payment-date: string # The payment date context for the report. E.g. 2018-04-30 (format: date)
  --pension-key: string # The pension scheme unique key. E.g. PENSCH001
  --message-function-code: string # Specific to PAPDIS report, specifies the business function that the sender is requesting. If left BLANK it will be assumed to be 0 (Enrol / Receive Contributions).
  --intermediary-id: string # Specific to PensionSync PASS report, a unique identifier for the Intermediary who is acting on behalf of the employer.
  --document-id: string # Specific to PensionSync PASS report, a document identifier unique for this document within the Intermediary.
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "PaymentDate" $payment_date "scalar") (serialize-qp "PensionKey" $pension_key "scalar") (serialize-qp "MessageFunctionCode" $message_function_code "scalar") (serialize-qp "IntermediaryId" $intermediary_id "scalar") (serialize-qp "DocumentId" $document_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/PASS/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "PayScheduleKey": $pay_schedule_key, "TaxYear": $tax_year, "PaymentDate": $payment_date, "PensionKey": $pension_key, "MessageFunctionCode": $message_function_code, "IntermediaryId": $intermediary_id, "DocumentId": $document_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the Pay Dashboard payslips report
#
# GET /Report/PAYDASHBOARD/run
# operationId: GetPayDashboardPayslipReportOuput
export def "get-pay-dashboard-payslip-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --employee-codes: string # A comma separated list of the employee codes. E.g. EMP001,EMP002
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --payment-date: string # The payment date context for the report. E.g. 2018-04-30 (format: date)
  --publication-date: string # Specific to the Pay Dashboard report, allows the specification of a future payslip publication date. E.g. 2018-12-31 (format: date)
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "EmployeeCodes" $employee_codes "scalar") (serialize-qp "TransformDefinitionKey" $transform_definition_key "scalar") (serialize-qp "StartIndex" $start_index "scalar") (serialize-qp "MaxIndex" $max_index "scalar") (serialize-qp "PaymentDate" $payment_date "scalar") (serialize-qp "PublicationDate" $publication_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/PAYDASHBOARD/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "PayScheduleKey": $pay_schedule_key, "TaxYear": $tax_year, "EmployeeCodes": $employee_codes, "TransformDefinitionKey": $transform_definition_key, "StartIndex": $start_index, "MaxIndex": $max_index, "PaymentDate": $payment_date, "PublicationDate": $publication_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the verbose payslip report
#
# GET /Report/PAYSLIP3/run
# operationId: GetPayslip3ReportOutput
export def "get-payslip3-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --employee-codes: string # A comma separated list of the employee codes. E.g. EMP001,EMP002
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --payment-date: string # The payment date context for the report. E.g. 2018-04-30 (format: date)
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "EmployeeCodes" $employee_codes "scalar") (serialize-qp "TransformDefinitionKey" $transform_definition_key "scalar") (serialize-qp "StartIndex" $start_index "scalar") (serialize-qp "MaxIndex" $max_index "scalar") (serialize-qp "PaymentDate" $payment_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/PAYSLIP3/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "PayScheduleKey": $pay_schedule_key, "TaxYear": $tax_year, "EmployeeCodes": $employee_codes, "TransformDefinitionKey": $transform_definition_key, "StartIndex": $start_index, "MaxIndex": $max_index, "PaymentDate": $payment_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Runs the pension liability report
#
# GET /Report/PENLIABILITY/run
# operationId: GetPensionLiabilityReportOutput
export def "get-pension-liability-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --pension-key: string # The pension scheme unique key. E.g. PENSCH001
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "PensionKey" $pension_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/PENLIABILITY/run" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EmployerKey": $employer_key, "TaxYear": $tax_year, "PensionKey": $pension_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a report definition
#
# DELETE /Report/{ReportDefinitionId}
# operationId: DeleteReportDefinition
export def "delete-report-definition" [
  report_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($report_definition_id | is-empty) { error make --unspanned { msg: "path parameter 'ReportDefinitionId' must be non-empty" } }
  let full_url = (build-url $base ({report_definition_id: (encode-path-segment $report_definition_id)} | format pattern "/Report/{report_definition_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get the report definition
#
# GET /Report/{ReportDefinitionId}
# operationId: GetReportDefinitionFromApplication
export def "get-report-definition-from-application" [
  report_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<ReportDefinition: record<Active: bool, Readonly: bool, ReportQuery: record<Encoding: string, ExcludeNullOrEmptyElements: bool, Groups: record, RootNodeName: string, SuppressMetricAttributes: bool, Variables: record>, SupportedTransforms: string, Title: string, Version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($report_definition_id | is-empty) { error make --unspanned { msg: "path parameter 'ReportDefinitionId' must be non-empty" } }
  let full_url = (build-url $base ({report_definition_id: (encode-path-segment $report_definition_id)} | format pattern "/Report/{report_definition_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Updates a report definition
#
# PUT /Report/{ReportDefinitionId}
# operationId: PutReportDefinition
# --ReportDefinition shape: {Active?: bool, Readonly?: bool, ReportQuery?: record, SupportedTransforms?: string, Title?: string, Version?: string}
export def "put-report-definition" [
  report_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --report-definition: record # shape: {Active?: bool, Readonly?: bool, ReportQuery?: record, SupportedTransforms?: string, Title?: string, Version?: string}
]: any -> record<ReportDefinition: record<Active: bool, Readonly: bool, ReportQuery: record<Encoding: string, ExcludeNullOrEmptyElements: bool, Groups: record, RootNodeName: string, SuppressMetricAttributes: bool, Variables: record>, SupportedTransforms: string, Title: string, Version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($report_definition_id | is-empty) { error make --unspanned { msg: "path parameter 'ReportDefinitionId' must be non-empty" } }
  let full_url = (build-url $base ({report_definition_id: (encode-path-segment $report_definition_id)} | format pattern "/Report/{report_definition_id}") $auth.query)
  let req_body = {"ReportDefinition": $report_definition} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Runs the specified report definition
#
# GET /Report/{ReportDefinitionId}/run
# operationId: GetReportOutput
export def "get-report-output" [
  report_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($report_definition_id | is-empty) { error make --unspanned { msg: "path parameter 'ReportDefinitionId' must be non-empty" } }
  let full_url = (build-url $base ({report_definition_id: (encode-path-segment $report_definition_id)} | format pattern "/Report/{report_definition_id}/run") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets all reports
#
# GET /Reports
# operationId: GetReportDefinitionsFromApplication
export def "get-report-definitions-from-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Reports" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create a new report definition
#
# POST /Reports
# operationId: PostReportDefinition
# --ReportDefinition shape: {Active?: bool, Readonly?: bool, ReportQuery?: record, SupportedTransforms?: string, Title?: string, Version?: string}
export def "post-report-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --report-definition: record # shape: {Active?: bool, Readonly?: bool, ReportQuery?: record, SupportedTransforms?: string, Title?: string, Version?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Reports" $auth.query)
  let req_body = {"ReportDefinition": $report_definition} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get a list of all available schemas
#
# GET /Schemas
# operationId: GetSchemas
export def "get-schemas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Schemas" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get XSD schema
#
# GET /Schemas/{DtoDataType}
# operationId: GetSchema
export def "get-schema" [
  dto_data_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($dto_data_type | is-empty) { error make --unspanned { msg: "path parameter 'DtoDataType' must be non-empty" } }
  let full_url = (build-url $base ({dto_data_type: (encode-path-segment $dto_data_type)} | format pattern "/Schemas/{dto_data_type}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Deletes Application secret
#
# DELETE /Secret/{SecretId}
# operationId: DeleteApplicationSecret
export def "delete-application-secret" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_id | is-empty) { error make --unspanned { msg: "path parameter 'SecretId' must be non-empty" } }
  let full_url = (build-url $base ({secret_id: (encode-path-segment $secret_id)} | format pattern "/Secret/{secret_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get Application secret
#
# GET /Secret/{SecretId}
# operationId: GetApplicationSecret
export def "get-application-secret" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_id | is-empty) { error make --unspanned { msg: "path parameter 'SecretId' must be non-empty" } }
  let full_url = (build-url $base ({secret_id: (encode-path-segment $secret_id)} | format pattern "/Secret/{secret_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create a new Application secret
#
# PUT /Secret/{SecretId}
# operationId: PutApplicationSecret
export def "put-application-secret" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_id | is-empty) { error make --unspanned { msg: "path parameter 'SecretId' must be non-empty" } }
  let full_url = (build-url $base ({secret_id: (encode-path-segment $secret_id)} | format pattern "/Secret/{secret_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [201]
}

# Get all Application secret links
#
# GET /Secrets
# operationId: GetApplicationSecrets
export def "get-application-secrets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Secrets" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create a new Application secret
#
# POST /Secrets
# operationId: PostApplicationSecret
export def "post-application-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Secrets" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Get the object template
#
# GET /Template/{DtoDataType}
# operationId: GetTemplateModel
export def "get-template-model" [
  dto_data_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($dto_data_type | is-empty) { error make --unspanned { msg: "path parameter 'DtoDataType' must be non-empty" } }
  let full_url = (build-url $base ({dto_data_type: (encode-path-segment $dto_data_type)} | format pattern "/Template/{dto_data_type}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get a list of all available data object tempaltes
#
# GET /Templates
# operationId: GetTemplates
export def "get-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Templates" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Deletes a transform definition
#
# DELETE /Transform/{TransformDefinitionId}
# operationId: DeleteTransformDefinition
export def "delete-transform-definition" [
  transform_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($transform_definition_id | is-empty) { error make --unspanned { msg: "path parameter 'TransformDefinitionId' must be non-empty" } }
  let full_url = (build-url $base ({transform_definition_id: (encode-path-segment $transform_definition_id)} | format pattern "/Transform/{transform_definition_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get the transform definition
#
# GET /Transform/{TransformDefinitionId}
# operationId: GetTransformDefinitionFromApplication
export def "get-transform-definition-from-application" [
  transform_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<TransformDefinition: record<Active: bool, ContentType: string, Definition: string, DefinitionType: string, Readonly: bool, SupportedReports: string, TaxYear: int, Title: string, Version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($transform_definition_id | is-empty) { error make --unspanned { msg: "path parameter 'TransformDefinitionId' must be non-empty" } }
  let full_url = (build-url $base ({transform_definition_id: (encode-path-segment $transform_definition_id)} | format pattern "/Transform/{transform_definition_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Updates a transform definition
#
# PUT /Transform/{TransformDefinitionId}
# operationId: PutTransformDefinition
# --TransformDefinition shape: {Active?: bool, ContentType?: string, Definition?: string, DefinitionType?: string, Readonly?: bool, SupportedReports?: string, TaxYear?: int, Title?: string, Version?: string}
export def "put-transform-definition" [
  transform_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --transform-definition: record # shape: {Active?: bool, ContentType?: string, Definition?: string, DefinitionType?: string, Readonly?: bool, SupportedReports?: string, TaxYear?: int, Title?: string, Version?: string}
]: any -> record<TransformDefinition: record<Active: bool, ContentType: string, Definition: string, DefinitionType: string, Readonly: bool, SupportedReports: string, TaxYear: int, Title: string, Version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($transform_definition_id | is-empty) { error make --unspanned { msg: "path parameter 'TransformDefinitionId' must be non-empty" } }
  let full_url = (build-url $base ({transform_definition_id: (encode-path-segment $transform_definition_id)} | format pattern "/Transform/{transform_definition_id}") $auth.query)
  let req_body = {"TransformDefinition": $transform_definition} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets all transform definitions
#
# GET /Transforms
# operationId: GetTransformDefinitionsFromApplication
export def "get-transform-definitions-from-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Transforms" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Create a new transform definition
#
# POST /Transforms
# operationId: PostTransformDefinition
# --TransformDefinition shape: {Active?: bool, ContentType?: string, Definition?: string, DefinitionType?: string, Readonly?: bool, SupportedReports?: string, TaxYear?: int, Title?: string, Version?: string}
export def "post-transform-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
  --transform-definition: record # shape: {Active?: bool, ContentType?: string, Definition?: string, DefinitionType?: string, Readonly?: bool, SupportedReports?: string, TaxYear?: int, Title?: string, Version?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Transforms" $auth.query)
  let req_body = {"TransformDefinition": $transform_definition} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Deletes the user object
#
# DELETE /User/{UserId}
# operationId: DeleteUser
export def "delete-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/User/{user_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Gets the user object
#
# GET /User/{UserId}
# operationId: GetUser
export def "get-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<User: record<MetaData: record, Permissions: record<Permission: list>, Roles: record<Role: list>, UserIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/User/{user_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Patch user object
#
# PATCH /User/{UserId}
# operationId: PatchUser
export def "patch-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<User: record<MetaData: record, Permissions: record<Permission: list>, Roles: record<Role: list>, UserIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/User/{user_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req null $insecure $raw $allow_errors $full [200]
}

# Puts user object
#
# PUT /User/{UserId}
# operationId: PutUser
export def "put-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<User: record<MetaData: record, Permissions: record<Permission: list>, Roles: record<Role: list>, UserIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/User/{user_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Gets the user permissions
#
# GET /User/{UserId}/Permissions
# operationId: GetUserPermissions
export def "get-user-permissions" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/User/{user_id}/Permissions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Delete user tag
#
# DELETE /User/{UserId}/Tag/{TagId}
# operationId: DeleteUserTag
export def "delete-user-tag" [
  user_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/User/{user_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get user tag
#
# GET /User/{UserId}/Tag/{TagId}
# operationId: GetTagFromUser
export def "get-tag-from-user" [
  user_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/User/{user_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Insert user tag
#
# PUT /User/{UserId}/Tag/{TagId}
# operationId: PutUserTag
export def "put-user-tag" [
  user_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/User/{user_id}/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get tags from user
#
# GET /User/{UserId}/Tags
# operationId: GetTagsFromUser
export def "get-tags-from-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/User/{user_id}/Tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Gets all user objects
#
# GET /Users
# operationId: GetUsers
export def "get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Users" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Post user object
#
# POST /Users
# operationId: PostUser
export def "post-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Users" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get links to tagged users
#
# GET /Users/Tag/{TagId}
# operationId: GetAllUsersWithTag
export def "get-all-users-with-tag" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'TagId' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/Users/Tag/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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

# Get all user tags
#
# GET /Users/Tags
# operationId: GetAllUserTags
export def "get-all-user-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Users/Tags" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
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
