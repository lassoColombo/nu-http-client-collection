# Auto-generated client for PatientView v1.0
# Source: https://api.apis.guru/v2/specs/patientview.org/1.0/openapi.json
# Auth: --token flag or $env.PATIENTVIEW_TOKEN

const BASE_URL = "https://www.patientview.org"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PATIENTVIEW_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
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

def base-url-completer [] { ["https://www.patientview.org"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "auth-login logIn" } } | get name | first)
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
export def "auth-login logIn" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string
  --password: string
  --username: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/login")
  let body = {apiKey: $apiKey, password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Log Out
#
# DELETE /auth/logout/{token}
# operationId: logOut
export def "auth-logout logOut" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/auth/logout/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Basic User Information
#
# GET /auth/{token}/basicuserinformation
# operationId: getBasicUserInformation
export def "auth-basicuserinformation get" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/auth/($token)/basicuserinformation")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Basic Patient Information
#
# GET /patient/{userId}/basic
# operationId: getBasicPatientDetails
export def "patient-basic get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/patient/($userId)/basic")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getPatientManagementDiagnoses
#
# GET /patientmanagement/diagnoses
# operationId: getPatientManagementDiagnoses
export def "patientmanagement-diagnoses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, codeCategories: list<record>, codeType: record<created: string, description: string, descriptionFriendly: string, displayOrder: int, id: int, lastUpdate: string, lookupType: record, value: string>, created: string, description: string, displayOrder: int, externalStandards: list<record>, fullDescription: string, hideFromPatients: bool, id: int, lastUpdate: string, links: list<record>, patientFriendlyName: string, removedExternally: bool, sourceType: string, standardType: record<created: string, description: string, descriptionFriendly: string, displayOrder: int, id: int, lastUpdate: string, lookupType: record, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/patientmanagement/diagnoses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getPatientManagementLookupTypes
#
# GET /patientmanagement/lookuptypes
# operationId: getPatientManagementLookupTypes
export def "patientmanagement-lookuptypes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created: string, description: string, id: int, lastUpdate: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/patientmanagement/lookuptypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
export def "patientmanagement-validate validatePatientManagement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --condition: record # shape: {asserter?: string, category?: string, code?: string, date?: string, description?: string, fullDescription?: string, group?: record, id?: int, identifier?: string, links?: list, notes?: string, severity?: string, status?: string}
  --encounters: list # item shape: {date?: string, encounterType?: string, group?: record, id?: int, identifier?: string, links?: list, observations?: list, procedures?: list, status?: string}
  --groupCode: string
  --identifier: string
  --observations: list # item shape: {applies?: string, bodySite?: string, comments?: string, comparator?: string, diagram?: string, group?: record, id?: int, identifier?: string, location?: string, name?: string, temporaryUuid?: string, units?: string, value?: string}
  --patient: record # shape: {address1?: string, address2?: string, address3?: string, address4?: string, contacts?: list, dateOfBirth?: string, dateOfBirthNoTime?: string, forename?: string, gender?: string, group?: record, groupCode?: string, identifier?: string, identifiers?: list, postcode?: string, practitioners?: list, surname?: string}
  --practitioners: list # item shape: {address1?: string, address2?: string, address3?: string, address4?: string, allowInviteGp?: bool, contacts?: list, gender?: string, groupCode?: string, identifier?: string, inviteDate?: string, name?: string, postcode?: string, role?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/patientmanagement/validate")
  let body = {condition: $condition, encounters: $encounters, groupCode: $groupCode, identifier: $identifier, observations: $observations, patient: $patient, practitioners: $practitioners} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getPatientManagement
#
# GET /patientmanagement/{userId}/group/{groupId}/identifier/{identifierId}
# operationId: getPatientManagement
export def "patientmanagement-group-identifier get" [
  userId: int
  groupId: int
  identifierId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<condition: record<asserter: string, category: string, code: string, date: string, description: string, fullDescription: string, group: record<address1: string, address2: string, address3: string, childGroups: list, code: string, contactPoints: list, created: string, fhirResourceId: string, groupFeatures: list, groupType: record, id: int, lastImportDate: string, lastUpdate: string, links: list, locations: list, name: string, parentGroups: list, postcode: string, sftpUser: string, shortName: string, visible: bool, visibleToJoin: bool>, id: int, identifier: string, links: list<record>, notes: string, severity: string, status: string>, encounters: table<date: string, encounterType: string, group: record, id: int, identifier: string, links: list, observations: list, procedures: list, status: string>, groupCode: string, identifier: string, observations: table<applies: string, bodySite: string, comments: string, comparator: string, diagram: string, group: record, id: int, identifier: string, location: string, name: string, temporaryUuid: string, units: string, value: string>, patient: record<address1: string, address2: string, address3: string, address4: string, contacts: list<record>, dateOfBirth: string, dateOfBirthNoTime: string, forename: string, gender: string, group: record<address1: string, address2: string, address3: string, childGroups: list, code: string, contactPoints: list, created: string, fhirResourceId: string, groupFeatures: list, groupType: record, id: int, lastImportDate: string, lastUpdate: string, links: list, locations: list, name: string, parentGroups: list, postcode: string, sftpUser: string, shortName: string, visible: bool, visibleToJoin: bool>, groupCode: string, identifier: string, identifiers: list<record>, postcode: string, practitioners: list<record>, surname: string>, practitioners: table<address1: string, address2: string, address3: string, address4: string, allowInviteGp: bool, contacts: list, gender: string, groupCode: string, identifier: string, inviteDate: string, name: string, postcode: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/patientmanagement/($userId)/group/($groupId)/identifier/($identifierId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
export def "patientmanagement-group-identifier savePatientManagement" [
  userId: int
  groupId: int
  identifierId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --condition: record # shape: {asserter?: string, category?: string, code?: string, date?: string, description?: string, fullDescription?: string, group?: record, id?: int, identifier?: string, links?: list, notes?: string, severity?: string, status?: string}
  --encounters: list # item shape: {date?: string, encounterType?: string, group?: record, id?: int, identifier?: string, links?: list, observations?: list, procedures?: list, status?: string}
  --groupCode: string
  --identifier: string
  --observations: list # item shape: {applies?: string, bodySite?: string, comments?: string, comparator?: string, diagram?: string, group?: record, id?: int, identifier?: string, location?: string, name?: string, temporaryUuid?: string, units?: string, value?: string}
  --patient: record # shape: {address1?: string, address2?: string, address3?: string, address4?: string, contacts?: list, dateOfBirth?: string, dateOfBirthNoTime?: string, forename?: string, gender?: string, group?: record, groupCode?: string, identifier?: string, identifiers?: list, postcode?: string, practitioners?: list, surname?: string}
  --practitioners: list # item shape: {address1?: string, address2?: string, address3?: string, address4?: string, allowInviteGp?: bool, contacts?: list, gender?: string, groupCode?: string, identifier?: string, inviteDate?: string, name?: string, postcode?: string, role?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/patientmanagement/($userId)/group/($groupId)/identifier/($identifierId)")
  let body = {condition: $condition, encounters: $encounters, groupCode: $groupCode, identifier: $identifier, observations: $observations, patient: $patient, practitioners: $practitioners} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
export def "patientmanagement-group-identifier-surgeries savePatientManagementSurgeries" [
  userId: int
  groupId: int
  identifierId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --condition: record # shape: {asserter?: string, category?: string, code?: string, date?: string, description?: string, fullDescription?: string, group?: record, id?: int, identifier?: string, links?: list, notes?: string, severity?: string, status?: string}
  --encounters: list # item shape: {date?: string, encounterType?: string, group?: record, id?: int, identifier?: string, links?: list, observations?: list, procedures?: list, status?: string}
  --groupCode: string
  --identifier: string
  --observations: list # item shape: {applies?: string, bodySite?: string, comments?: string, comparator?: string, diagram?: string, group?: record, id?: int, identifier?: string, location?: string, name?: string, temporaryUuid?: string, units?: string, value?: string}
  --patient: record # shape: {address1?: string, address2?: string, address3?: string, address4?: string, contacts?: list, dateOfBirth?: string, dateOfBirthNoTime?: string, forename?: string, gender?: string, group?: record, groupCode?: string, identifier?: string, identifiers?: list, postcode?: string, practitioners?: list, surname?: string}
  --practitioners: list # item shape: {address1?: string, address2?: string, address3?: string, address4?: string, allowInviteGp?: bool, contacts?: list, gender?: string, groupCode?: string, identifier?: string, inviteDate?: string, name?: string, postcode?: string, role?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/patientmanagement/($userId)/group/($groupId)/identifier/($identifierId)/surgeries")
  let body = {condition: $condition, encounters: $encounters, groupCode: $groupCode, identifier: $identifier, observations: $observations, patient: $patient, practitioners: $practitioners} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Available Observations Types For a User
#
# GET /user/{userId}/availableobservationheadings
# operationId: getAvailableObservationHeadings
export def "user-availableobservationheadings get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, created: string, decimalPlaces: int, defaultPanel: int, defaultPanelOrder: int, heading: string, id: int, infoLink: string, lastUpdate: string, maxGraph: float, minGraph: float, name: string, normalRange: string, observationHeadingGroups: list<record>, units: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/($userId)/availableobservationheadings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Observations of Multiple Types For a User
#
# GET /user/{userId}/observations
# operationId: getObservationsByCodes
export def "user-observations list" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: list # code
  --limit: int # limit (format: int64)
  --offset: int # offset (format: int64)
  --orderDirection: string # orderDirection
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code" $code "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orderDirection" $orderDirection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user/($userId)/observations" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Observations of a Certain Type For a User
#
# GET /user/{userId}/observations/{code}
# operationId: getObservationsByCode
export def "user-observations get" [
  userId: int
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/($userId)/observations/($code)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get patient entered Observations of a Certain Type For a User
#
# GET /user/{userId}/observations/{code}/patiententered
# operationId: getPatientEnteredObservationsByCode
export def "user-observations-patiententered get" [
  userId: int
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/($userId)/observations/($code)/patiententered")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Available Patient Entered Observations Types For a User
#
# GET /user/{userId}/patiententeredobservationheadings
# operationId: getPatientEnteredObservationHeadings
export def "user-patiententeredobservationheadings get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, created: string, decimalPlaces: int, defaultPanel: int, defaultPanelOrder: int, heading: string, id: int, infoLink: string, lastUpdate: string, maxGraph: float, minGraph: float, name: string, normalRange: string, observationHeadingGroups: list<record>, units: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/($userId)/patiententeredobservationheadings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
