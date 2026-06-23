# Auto-generated client for PatientView v1.0
# Source: https://api.apis.guru/v2/specs/patientview.org/1.0/openapi.json
# Auth: --token flag or $env.PATIENTVIEW_TOKEN

const BASE_URL = "https://www.patientview.org"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PATIENTVIEW_TOKEN | default "" }
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

def base-url-completer [] { ["https://www.patientview.org"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "auth-login create-log" } } | get name | first)
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

# Log In
#
# POST /auth/login
# operationId: logIn
export def "auth-login create-log" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --password: string
  --username: string
]: any -> record<auditActions: list<string>, checkSecretWord: bool, created: string, expiration: string, externalStandards: table<description: string, id: int, name: string>, groupFeatures: table<created: string, description: string, id: int, lastUpdate: string, name: string>, groupMessagingEnabled: bool, mustSetSecretWord: bool, patientFeatures: table<created: string, description: string, id: int, lastUpdate: string, name: string>, patientMessagingFeatureTypes: list<string>, patientRoles: table<description: string, id: int, name: string, visible: bool>, routes: table<controller: string, created: string, displayOrder: int, id: int, lookup: record, templateUrl: string, title: string, url: string>, secretWord: string, secretWordChoices: record, secretWordIndexes: list<string>, secretWordSalt: string, secretWordToken: string, securityRoles: table<description: string, id: int, name: string, visible: bool>, shouldEnterCondition: bool, staffFeatures: table<created: string, description: string, id: int, lastUpdate: string, name: string>, staffRoles: table<description: string, id: int, name: string, visible: bool>, token: string, user: record<apiKey: record<expired: bool, expiryDate: string, key: string>, canSwitchUser: bool, changePassword: bool, contactNumber: string, created: string, currentLogin: string, currentLoginIpAddress: string, dateOfBirth: string, deleted: bool, dummy: bool, email: string, emailVerified: bool, forename: string, groupRoles: list<record>, hideSecretWordNotification: bool, id: int, identifiers: list<record>, lastLogin: string, lastLoginIpAddress: string, latestDataReceivedBy: record<code: string, groupType: record, id: int, lastImportDate: string, name: string, parentCodes: list, shortName: string, visible: bool, visibleToJoin: bool>, latestDataReceivedDate: string, locked: bool, picture: string, roleDescription: string, secretWordIsSet: bool, surname: string, userFeatures: list<record>, username: string>, userFeatures: table<created: string, description: string, id: int, lastUpdate: string, name: string>, userGroups: table<code: string, groupType: record, id: int, lastImportDate: string, name: string, parentCodes: list, shortName: string, visible: bool, visibleToJoin: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/login")
  let req_body = {"apiKey": $api_key, "password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Log Out
#
# DELETE /auth/logout/{token}
# operationId: logOut
export def "auth-logout delete-log-out" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($token_arg | is-empty) { error make --unspanned { msg: "path parameter 'token' must be non-empty" } }
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/auth/logout/{token_arg}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Basic User Information
#
# GET /auth/{token}/basicuserinformation
# operationId: getBasicUserInformation
export def "auth-basicuserinformation get-basic-user-information" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiKey: record<expired: bool, expiryDate: string, key: string>, canSwitchUser: bool, changePassword: bool, contactNumber: string, created: string, currentLogin: string, currentLoginIpAddress: string, dateOfBirth: string, deleted: bool, dummy: bool, email: string, emailVerified: bool, forename: string, groupRoles: table<group: record, id: int, role: record>, hideSecretWordNotification: bool, id: int, identifiers: list<record>, lastLogin: string, lastLoginIpAddress: string, latestDataReceivedBy: record<code: string, groupType: record<created: string, description: string, descriptionFriendly: string, displayOrder: int, id: int, lastUpdate: string, lookupType: record, value: string>, id: int, lastImportDate: string, name: string, parentCodes: list<string>, shortName: string, visible: bool, visibleToJoin: bool>, latestDataReceivedDate: string, locked: bool, picture: string, roleDescription: string, secretWordIsSet: bool, surname: string, userFeatures: table<created: string, feature: record, id: int, lastUpdate: string, optInDate: string, optInHidden: bool, optInStatus: bool, optOutHidden: bool>, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($token_arg | is-empty) { error make --unspanned { msg: "path parameter 'token' must be non-empty" } }
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/auth/{token_arg}/basicuserinformation"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Basic Patient Information
#
# GET /patient/{userId}/basic
# operationId: getBasicPatientDetails
export def "patient-basic get-details" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<diagnosisCodes: list<record>, fhirAllergies: list<record>, fhirConditions: list<record>, fhirEncounters: list<record>, fhirObservations: list<record>, fhirPatient: record<address1: string, address2: string, address3: string, address4: string, contacts: list, dateOfBirth: string, dateOfBirthNoTime: string, forename: string, gender: string, group: record, groupCode: string, identifier: string, identifiers: list, postcode: string, practitioners: list, surname: string>, fhirPractitioners: list<record>, group: record<address1: string, address2: string, address3: string, childGroups: list, code: string, contactPoints: list, created: string, fhirResourceId: string, groupFeatures: list, groupType: record, id: int, lastImportDate: string, lastUpdate: string, links: list, locations: list, name: string, parentGroups: list, postcode: string, sftpUser: string, shortName: string, visible: bool, visibleToJoin: bool>, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/patient/{user_id}/basic"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# getPatientManagementDiagnoses
#
# GET /patientmanagement/diagnoses
# operationId: getPatientManagementDiagnoses
export def "patientmanagement-diagnoses get-patient-management" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, codeCategories: list<record>, codeType: record<created: string, description: string, descriptionFriendly: string, displayOrder: int, id: int, lastUpdate: string, lookupType: record, value: string>, created: string, description: string, displayOrder: int, externalStandards: list<record>, fullDescription: string, hideFromPatients: bool, id: int, lastUpdate: string, links: list<record>, patientFriendlyName: string, removedExternally: bool, sourceType: string, standardType: record<created: string, description: string, descriptionFriendly: string, displayOrder: int, id: int, lastUpdate: string, lookupType: record, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/patientmanagement/diagnoses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# getPatientManagementLookupTypes
#
# GET /patientmanagement/lookuptypes
# operationId: getPatientManagementLookupTypes
export def "patientmanagement-lookuptypes get-patient-management-lookup-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created: string, description: string, id: int, lastUpdate: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/patientmanagement/lookuptypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# validatePatientManagement
#
# POST /patientmanagement/validate
# operationId: validatePatientManagement
# --condition shape: {asserter?: string, category?: string, code?: string, date?: string, description?: string, fullDescription?: string, group?: record, id?: int, identifier?: string, links?: list, notes?: string, severity?: string, status?: string}
# --encounters item shape: {date?: string, encounterType?: string, group?: record, id?: int, identifier?: string, links?: list, observations?: list, procedures?: list, status?: string}
# --observations item shape: {applies?: string, bodySite?: string, comments?: string, comparator?: string, diagram?: string, group?: record, id?: int, identifier?: string, location?: string, name?: string, temporaryUuid?: string, units?: string, value?: string}
# --patient shape: {address1?: string, address2?: string, address3?: string, address4?: string, contacts?: list, dateOfBirth?: string, dateOfBirthNoTime?: string, forename?: string, gender?: string, group?: record, groupCode?: string, identifier?: string, identifiers?: list, postcode?: string, practitioners?: list, surname?: string}
# --practitioners item shape: {address1?: string, address2?: string, address3?: string, address4?: string, allowInviteGp?: bool, contacts?: list, gender?: string, groupCode?: string, identifier?: string, inviteDate?: string, name?: string, postcode?: string, role?: string}
export def "patientmanagement-validate validate-patient-management" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --condition: record # shape: {asserter?: string, category?: string, code?: string, date?: string, description?: string, fullDescription?: string, group?: record, id?: int, identifier?: string, links?: list, notes?: string, severity?: string, status?: string}
  --encounters: list # item shape: {date?: string, encounterType?: string, group?: record, id?: int, identifier?: string, links?: list, observations?: list, procedures?: list, status?: string}
  --group-code: string
  --identifier: string
  --observations: list # item shape: {applies?: string, bodySite?: string, comments?: string, comparator?: string, diagram?: string, group?: record, id?: int, identifier?: string, location?: string, name?: string, temporaryUuid?: string, units?: string, value?: string}
  --patient: record # shape: {address1?: string, address2?: string, address3?: string, address4?: string, contacts?: list, dateOfBirth?: string, dateOfBirthNoTime?: string, forename?: string, gender?: string, group?: record, groupCode?: string, identifier?: string, identifiers?: list, postcode?: string, practitioners?: list, surname?: string}
  --practitioners: list # item shape: {address1?: string, address2?: string, address3?: string, address4?: string, allowInviteGp?: bool, contacts?: list, gender?: string, groupCode?: string, identifier?: string, inviteDate?: string, name?: string, postcode?: string, role?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/patientmanagement/validate")
  let req_body = {"condition": $condition, "encounters": $encounters, "groupCode": $group_code, "identifier": $identifier, "observations": $observations, "patient": $patient, "practitioners": $practitioners} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# getPatientManagement
#
# GET /patientmanagement/{userId}/group/{groupId}/identifier/{identifierId}
# operationId: getPatientManagement
export def "patientmanagement-group-identifier get-patient-management" [
  user_id: int
  group_id: int
  identifier_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<condition: record<asserter: string, category: string, code: string, date: string, description: string, fullDescription: string, group: record<address1: string, address2: string, address3: string, childGroups: list, code: string, contactPoints: list, created: string, fhirResourceId: string, groupFeatures: list, groupType: record, id: int, lastImportDate: string, lastUpdate: string, links: list, locations: list, name: string, parentGroups: list, postcode: string, sftpUser: string, shortName: string, visible: bool, visibleToJoin: bool>, id: int, identifier: string, links: list<record>, notes: string, severity: string, status: string>, encounters: table<date: string, encounterType: string, group: record, id: int, identifier: string, links: list, observations: list, procedures: list, status: string>, groupCode: string, identifier: string, observations: table<applies: string, bodySite: string, comments: string, comparator: string, diagram: string, group: record, id: int, identifier: string, location: string, name: string, temporaryUuid: string, units: string, value: string>, patient: record<address1: string, address2: string, address3: string, address4: string, contacts: list<record>, dateOfBirth: string, dateOfBirthNoTime: string, forename: string, gender: string, group: record<address1: string, address2: string, address3: string, childGroups: list, code: string, contactPoints: list, created: string, fhirResourceId: string, groupFeatures: list, groupType: record, id: int, lastImportDate: string, lastUpdate: string, links: list, locations: list, name: string, parentGroups: list, postcode: string, sftpUser: string, shortName: string, visible: bool, visibleToJoin: bool>, groupCode: string, identifier: string, identifiers: list<record>, postcode: string, practitioners: list<record>, surname: string>, practitioners: table<address1: string, address2: string, address3: string, address4: string, allowInviteGp: bool, contacts: list, gender: string, groupCode: string, identifier: string, inviteDate: string, name: string, postcode: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($identifier_id | is-empty) { error make --unspanned { msg: "path parameter 'identifierId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), group_id: (encode-path-segment $group_id), identifier_id: (encode-path-segment $identifier_id)} | format pattern "/patientmanagement/{user_id}/group/{group_id}/identifier/{identifier_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# savePatientManagement
#
# POST /patientmanagement/{userId}/group/{groupId}/identifier/{identifierId}
# operationId: savePatientManagement
# --condition shape: {asserter?: string, category?: string, code?: string, date?: string, description?: string, fullDescription?: string, group?: record, id?: int, identifier?: string, links?: list, notes?: string, severity?: string, status?: string}
# --encounters item shape: {date?: string, encounterType?: string, group?: record, id?: int, identifier?: string, links?: list, observations?: list, procedures?: list, status?: string}
# --observations item shape: {applies?: string, bodySite?: string, comments?: string, comparator?: string, diagram?: string, group?: record, id?: int, identifier?: string, location?: string, name?: string, temporaryUuid?: string, units?: string, value?: string}
# --patient shape: {address1?: string, address2?: string, address3?: string, address4?: string, contacts?: list, dateOfBirth?: string, dateOfBirthNoTime?: string, forename?: string, gender?: string, group?: record, groupCode?: string, identifier?: string, identifiers?: list, postcode?: string, practitioners?: list, surname?: string}
# --practitioners item shape: {address1?: string, address2?: string, address3?: string, address4?: string, allowInviteGp?: bool, contacts?: list, gender?: string, groupCode?: string, identifier?: string, inviteDate?: string, name?: string, postcode?: string, role?: string}
export def "patientmanagement-group-identifier create-save-patient-management" [
  user_id: int
  group_id: int
  identifier_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --condition: record # shape: {asserter?: string, category?: string, code?: string, date?: string, description?: string, fullDescription?: string, group?: record, id?: int, identifier?: string, links?: list, notes?: string, severity?: string, status?: string}
  --encounters: list # item shape: {date?: string, encounterType?: string, group?: record, id?: int, identifier?: string, links?: list, observations?: list, procedures?: list, status?: string}
  --group-code: string
  --identifier: string
  --observations: list # item shape: {applies?: string, bodySite?: string, comments?: string, comparator?: string, diagram?: string, group?: record, id?: int, identifier?: string, location?: string, name?: string, temporaryUuid?: string, units?: string, value?: string}
  --patient: record # shape: {address1?: string, address2?: string, address3?: string, address4?: string, contacts?: list, dateOfBirth?: string, dateOfBirthNoTime?: string, forename?: string, gender?: string, group?: record, groupCode?: string, identifier?: string, identifiers?: list, postcode?: string, practitioners?: list, surname?: string}
  --practitioners: list # item shape: {address1?: string, address2?: string, address3?: string, address4?: string, allowInviteGp?: bool, contacts?: list, gender?: string, groupCode?: string, identifier?: string, inviteDate?: string, name?: string, postcode?: string, role?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($identifier_id | is-empty) { error make --unspanned { msg: "path parameter 'identifierId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), group_id: (encode-path-segment $group_id), identifier_id: (encode-path-segment $identifier_id)} | format pattern "/patientmanagement/{user_id}/group/{group_id}/identifier/{identifier_id}"))
  let req_body = {"condition": $condition, "encounters": $encounters, "groupCode": $group_code, "identifier": $identifier, "observations": $observations, "patient": $patient, "practitioners": $practitioners} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# savePatientManagementSurgeries
#
# POST /patientmanagement/{userId}/group/{groupId}/identifier/{identifierId}/surgeries
# operationId: savePatientManagementSurgeries
# --condition shape: {asserter?: string, category?: string, code?: string, date?: string, description?: string, fullDescription?: string, group?: record, id?: int, identifier?: string, links?: list, notes?: string, severity?: string, status?: string}
# --encounters item shape: {date?: string, encounterType?: string, group?: record, id?: int, identifier?: string, links?: list, observations?: list, procedures?: list, status?: string}
# --observations item shape: {applies?: string, bodySite?: string, comments?: string, comparator?: string, diagram?: string, group?: record, id?: int, identifier?: string, location?: string, name?: string, temporaryUuid?: string, units?: string, value?: string}
# --patient shape: {address1?: string, address2?: string, address3?: string, address4?: string, contacts?: list, dateOfBirth?: string, dateOfBirthNoTime?: string, forename?: string, gender?: string, group?: record, groupCode?: string, identifier?: string, identifiers?: list, postcode?: string, practitioners?: list, surname?: string}
# --practitioners item shape: {address1?: string, address2?: string, address3?: string, address4?: string, allowInviteGp?: bool, contacts?: list, gender?: string, groupCode?: string, identifier?: string, inviteDate?: string, name?: string, postcode?: string, role?: string}
export def "patientmanagement-group-identifier-surgeries create-save-patient-management" [
  user_id: int
  group_id: int
  identifier_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --condition: record # shape: {asserter?: string, category?: string, code?: string, date?: string, description?: string, fullDescription?: string, group?: record, id?: int, identifier?: string, links?: list, notes?: string, severity?: string, status?: string}
  --encounters: list # item shape: {date?: string, encounterType?: string, group?: record, id?: int, identifier?: string, links?: list, observations?: list, procedures?: list, status?: string}
  --group-code: string
  --identifier: string
  --observations: list # item shape: {applies?: string, bodySite?: string, comments?: string, comparator?: string, diagram?: string, group?: record, id?: int, identifier?: string, location?: string, name?: string, temporaryUuid?: string, units?: string, value?: string}
  --patient: record # shape: {address1?: string, address2?: string, address3?: string, address4?: string, contacts?: list, dateOfBirth?: string, dateOfBirthNoTime?: string, forename?: string, gender?: string, group?: record, groupCode?: string, identifier?: string, identifiers?: list, postcode?: string, practitioners?: list, surname?: string}
  --practitioners: list # item shape: {address1?: string, address2?: string, address3?: string, address4?: string, allowInviteGp?: bool, contacts?: list, gender?: string, groupCode?: string, identifier?: string, inviteDate?: string, name?: string, postcode?: string, role?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($identifier_id | is-empty) { error make --unspanned { msg: "path parameter 'identifierId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), group_id: (encode-path-segment $group_id), identifier_id: (encode-path-segment $identifier_id)} | format pattern "/patientmanagement/{user_id}/group/{group_id}/identifier/{identifier_id}/surgeries"))
  let req_body = {"condition": $condition, "encounters": $encounters, "groupCode": $group_code, "identifier": $identifier, "observations": $observations, "patient": $patient, "practitioners": $practitioners} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Available Observations Types For a User
#
# GET /user/{userId}/availableobservationheadings
# operationId: getAvailableObservationHeadings
export def "user-availableobservationheadings get-available-observation-headings" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, created: string, decimalPlaces: int, defaultPanel: int, defaultPanelOrder: int, heading: string, id: int, infoLink: string, lastUpdate: string, maxGraph: float, minGraph: float, name: string, normalRange: string, observationHeadingGroups: list<record>, units: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/user/{user_id}/availableobservationheadings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Observations of Multiple Types For a User
#
# GET /user/{userId}/observations
# operationId: getObservationsByCodes
export def "user-observations get-by-codes" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: list<string> # code
  --limit: int # limit (format: int64)
  --offset: int # offset (format: int64)
  --order-direction: string # orderDirection
]: nothing -> record<data: table<key: list>, totalElements: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "code" $code "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orderDirection" $order_direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/user/{user_id}/observations") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"code": $code, "limit": $limit, "offset": $offset, "orderDirection": $order_direction} | compact), body: null}
}

# Get Observations of a Certain Type For a User
#
# GET /user/{userId}/observations/{code}
# operationId: getObservationsByCode
export def "user-observations get" [
  user_id: int
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<applies: string, bodySite: string, comments: string, comparator: string, diagram: string, group: record<address1: string, address2: string, address3: string, childGroups: list, code: string, contactPoints: list, created: string, fhirResourceId: string, groupFeatures: list, groupType: record, id: int, lastImportDate: string, lastUpdate: string, links: list, locations: list, name: string, parentGroups: list, postcode: string, sftpUser: string, shortName: string, visible: bool, visibleToJoin: bool>, id: int, identifier: string, location: string, name: string, temporaryUuid: string, units: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($code | is-empty) { error make --unspanned { msg: "path parameter 'code' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), code: (encode-path-segment $code)} | format pattern "/user/{user_id}/observations/{code}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get patient entered Observations of a Certain Type For a User
#
# GET /user/{userId}/observations/{code}/patiententered
# operationId: getPatientEnteredObservationsByCode
export def "user-observations-patiententered get-patient-entered" [
  user_id: int
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<applies: string, bodySite: string, comments: string, comparator: string, diagram: string, group: record<address1: string, address2: string, address3: string, childGroups: list, code: string, contactPoints: list, created: string, fhirResourceId: string, groupFeatures: list, groupType: record, id: int, lastImportDate: string, lastUpdate: string, links: list, locations: list, name: string, parentGroups: list, postcode: string, sftpUser: string, shortName: string, visible: bool, visibleToJoin: bool>, id: int, identifier: string, location: string, name: string, temporaryUuid: string, units: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($code | is-empty) { error make --unspanned { msg: "path parameter 'code' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), code: (encode-path-segment $code)} | format pattern "/user/{user_id}/observations/{code}/patiententered"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Available Patient Entered Observations Types For a User
#
# GET /user/{userId}/patiententeredobservationheadings
# operationId: getPatientEnteredObservationHeadings
export def "user-patiententeredobservationheadings get-patient-entered-observation-headings" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, created: string, decimalPlaces: int, defaultPanel: int, defaultPanelOrder: int, heading: string, id: int, infoLink: string, lastUpdate: string, maxGraph: float, minGraph: float, name: string, normalRange: string, observationHeadingGroups: list<record>, units: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/user/{user_id}/patiententeredobservationheadings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
