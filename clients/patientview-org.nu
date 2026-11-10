# Auto-generated client for PatientView v1.0
# Source: https://api.apis.guru/v2/specs/patientview.org/1.0/openapi.json
# Auth: --token flag or $env.PATIENTVIEW_TOKEN

const BASE_URL = "https://www.patientview.org"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o PATIENTVIEW_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://www.patientview.org"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["log-in" "log-out" "get-basic-user-information" "get-basic-patient-details" "get-patient-management-diagnoses" "get-patient-management-lookup-types" "validate-patient-management" "get-patient-management" "save-patient-management" "save-patient-management-surgeries" "get-available-observation-headings" "get-observations-by-codes" "get-observations-by-code" "get-patient-entered-observations-by-code" "get-patient-entered-observation-headings" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
export def "log-in" [
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
]: any -> oneof<record<auditActions: list<string>, checkSecretWord: bool, created: string, expiration: string, externalStandards: table<description: string, id: int, name: string>, groupFeatures: table<created: string, description: string, id: int, lastUpdate: string, name: string>, groupMessagingEnabled: bool, mustSetSecretWord: bool, patientFeatures: table<created: string, description: string, id: int, lastUpdate: string, name: string>, patientMessagingFeatureTypes: list<string>, patientRoles: table<description: string, id: int, name: string, visible: bool>, routes: table<controller: string, created: string, displayOrder: int, id: int, lookup: record, templateUrl: string, title: string, url: string>, secretWord: string, secretWordChoices: record, secretWordIndexes: list<string>, secretWordSalt: string, secretWordToken: string, securityRoles: table<description: string, id: int, name: string, visible: bool>, shouldEnterCondition: bool, staffFeatures: table<created: string, description: string, id: int, lastUpdate: string, name: string>, staffRoles: table<description: string, id: int, name: string, visible: bool>, token: string, user: record<apiKey: record<expired: bool, expiryDate: string, key: string>, canSwitchUser: bool, changePassword: bool, contactNumber: string, created: string, currentLogin: string, currentLoginIpAddress: string, dateOfBirth: string, deleted: bool, dummy: bool, email: string, emailVerified: bool, forename: string, groupRoles: list<record>, hideSecretWordNotification: bool, id: int, identifiers: list<record>, lastLogin: string, lastLoginIpAddress: string, latestDataReceivedBy: record<code: string, groupType: record, id: int, lastImportDate: string, name: string, parentCodes: list, shortName: string, visible: bool, visibleToJoin: bool>, latestDataReceivedDate: string, locked: bool, picture: string, roleDescription: string, secretWordIsSet: bool, surname: string, userFeatures: list<record>, username: string>, userFeatures: table<created: string, description: string, id: int, lastUpdate: string, name: string>, userGroups: table<code: string, groupType: record, id: int, lastImportDate: string, name: string, parentCodes: list, shortName: string, visible: bool, visibleToJoin: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/login" $auth.query)
  let req_body = {"apiKey": $api_key, "password": $password, "username": $username} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Log Out
#
# DELETE /auth/logout/{token}
# operationId: logOut
export def "log-out" [
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
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/auth/logout/{token_arg}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Get Basic User Information
#
# GET /auth/{token}/basicuserinformation
# operationId: getBasicUserInformation
export def "get-basic-user-information" [
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
]: nothing -> oneof<record<apiKey: record<expired: bool, expiryDate: string, key: string>, canSwitchUser: bool, changePassword: bool, contactNumber: string, created: string, currentLogin: string, currentLoginIpAddress: string, dateOfBirth: string, deleted: bool, dummy: bool, email: string, emailVerified: bool, forename: string, groupRoles: table<group: record, id: int, role: record>, hideSecretWordNotification: bool, id: int, identifiers: list<record>, lastLogin: string, lastLoginIpAddress: string, latestDataReceivedBy: record<code: string, groupType: record<created: string, description: string, descriptionFriendly: string, displayOrder: int, id: int, lastUpdate: string, lookupType: record, value: string>, id: int, lastImportDate: string, name: string, parentCodes: list<string>, shortName: string, visible: bool, visibleToJoin: bool>, latestDataReceivedDate: string, locked: bool, picture: string, roleDescription: string, secretWordIsSet: bool, surname: string, userFeatures: table<created: string, feature: record, id: int, lastUpdate: string, optInDate: string, optInHidden: bool, optInStatus: bool, optOutHidden: bool>, username: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($token_arg | is-empty) { error make --unspanned { msg: "path parameter 'token' must be non-empty" } }
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/auth/{token_arg}/basicuserinformation") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Basic Patient Information
#
# GET /patient/{userId}/basic
# operationId: getBasicPatientDetails
export def "get-basic-patient-details" [
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
]: nothing -> oneof<table<diagnosisCodes: list<record>, fhirAllergies: list<record>, fhirConditions: list<record>, fhirEncounters: list<record>, fhirObservations: list<record>, fhirPatient: record<address1: string, address2: string, address3: string, address4: string, contacts: list, dateOfBirth: string, dateOfBirthNoTime: string, forename: string, gender: string, group: record, groupCode: string, identifier: string, identifiers: list, postcode: string, practitioners: list, surname: string>, fhirPractitioners: list<record>, group: record<address1: string, address2: string, address3: string, childGroups: list, code: string, contactPoints: list, created: string, fhirResourceId: string, groupFeatures: list, groupType: record, id: int, lastImportDate: string, lastUpdate: string, links: list, locations: list, name: string, parentGroups: list, postcode: string, sftpUser: string, shortName: string, visible: bool, visibleToJoin: bool>, id: int>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/patient/{user_id}/basic") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# getPatientManagementDiagnoses
#
# GET /patientmanagement/diagnoses
# operationId: getPatientManagementDiagnoses
export def "get-patient-management-diagnoses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<code: string, codeCategories: list<record>, codeType: record<created: string, description: string, descriptionFriendly: string, displayOrder: int, id: int, lastUpdate: string, lookupType: record, value: string>, created: string, description: string, displayOrder: int, externalStandards: list<record>, fullDescription: string, hideFromPatients: bool, id: int, lastUpdate: string, links: list<record>, patientFriendlyName: string, removedExternally: bool, sourceType: string, standardType: record<created: string, description: string, descriptionFriendly: string, displayOrder: int, id: int, lastUpdate: string, lookupType: record, value: string>>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/patientmanagement/diagnoses" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# getPatientManagementLookupTypes
#
# GET /patientmanagement/lookuptypes
# operationId: getPatientManagementLookupTypes
export def "get-patient-management-lookup-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<created: string, description: string, id: int, lastUpdate: string, type: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/patientmanagement/lookuptypes" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# validatePatientManagement
#
# POST /patientmanagement/validate
# operationId: validatePatientManagement
export def "validate-patient-management" [
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
  let full_url = (build-url $base "/patientmanagement/validate" $auth.query)
  let req_body = {"condition": $condition, "encounters": $encounters, "groupCode": $group_code, "identifier": $identifier, "observations": $observations, "patient": $patient, "practitioners": $practitioners} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# getPatientManagement
#
# GET /patientmanagement/{userId}/group/{groupId}/identifier/{identifierId}
# operationId: getPatientManagement
export def "get-patient-management" [
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
]: nothing -> oneof<record<condition: record<asserter: string, category: string, code: string, date: string, description: string, fullDescription: string, group: record<address1: string, address2: string, address3: string, childGroups: list, code: string, contactPoints: list, created: string, fhirResourceId: string, groupFeatures: list, groupType: record, id: int, lastImportDate: string, lastUpdate: string, links: list, locations: list, name: string, parentGroups: list, postcode: string, sftpUser: string, shortName: string, visible: bool, visibleToJoin: bool>, id: int, identifier: string, links: list<record>, notes: string, severity: string, status: string>, encounters: table<date: string, encounterType: string, group: record, id: int, identifier: string, links: list, observations: list, procedures: list, status: string>, groupCode: string, identifier: string, observations: table<applies: string, bodySite: string, comments: string, comparator: string, diagram: string, group: record, id: int, identifier: string, location: string, name: string, temporaryUuid: string, units: string, value: string>, patient: record<address1: string, address2: string, address3: string, address4: string, contacts: list<record>, dateOfBirth: string, dateOfBirthNoTime: string, forename: string, gender: string, group: record<address1: string, address2: string, address3: string, childGroups: list, code: string, contactPoints: list, created: string, fhirResourceId: string, groupFeatures: list, groupType: record, id: int, lastImportDate: string, lastUpdate: string, links: list, locations: list, name: string, parentGroups: list, postcode: string, sftpUser: string, shortName: string, visible: bool, visibleToJoin: bool>, groupCode: string, identifier: string, identifiers: list<record>, postcode: string, practitioners: list<record>, surname: string>, practitioners: table<address1: string, address2: string, address3: string, address4: string, allowInviteGp: bool, contacts: list, gender: string, groupCode: string, identifier: string, inviteDate: string, name: string, postcode: string, role: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($identifier_id | is-empty) { error make --unspanned { msg: "path parameter 'identifierId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), group_id: (encode-path-segment $group_id), identifier_id: (encode-path-segment $identifier_id)} | format pattern "/patientmanagement/{user_id}/group/{group_id}/identifier/{identifier_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# savePatientManagement
#
# POST /patientmanagement/{userId}/group/{groupId}/identifier/{identifierId}
# operationId: savePatientManagement
export def "save-patient-management" [
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
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), group_id: (encode-path-segment $group_id), identifier_id: (encode-path-segment $identifier_id)} | format pattern "/patientmanagement/{user_id}/group/{group_id}/identifier/{identifier_id}") $auth.query)
  let req_body = {"condition": $condition, "encounters": $encounters, "groupCode": $group_code, "identifier": $identifier, "observations": $observations, "patient": $patient, "practitioners": $practitioners} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# savePatientManagementSurgeries
#
# POST /patientmanagement/{userId}/group/{groupId}/identifier/{identifierId}/surgeries
# operationId: savePatientManagementSurgeries
export def "save-patient-management-surgeries" [
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
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), group_id: (encode-path-segment $group_id), identifier_id: (encode-path-segment $identifier_id)} | format pattern "/patientmanagement/{user_id}/group/{group_id}/identifier/{identifier_id}/surgeries") $auth.query)
  let req_body = {"condition": $condition, "encounters": $encounters, "groupCode": $group_code, "identifier": $identifier, "observations": $observations, "patient": $patient, "practitioners": $practitioners} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Get Available Observations Types For a User
#
# GET /user/{userId}/availableobservationheadings
# operationId: getAvailableObservationHeadings
export def "get-available-observation-headings" [
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
]: nothing -> oneof<table<code: string, created: string, decimalPlaces: int, defaultPanel: int, defaultPanelOrder: int, heading: string, id: int, infoLink: string, lastUpdate: string, maxGraph: float, minGraph: float, name: string, normalRange: string, observationHeadingGroups: list<record>, units: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/user/{user_id}/availableobservationheadings") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Observations of Multiple Types For a User
#
# GET /user/{userId}/observations
# operationId: getObservationsByCodes
export def "get-observations-by-codes" [
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
  --code: list<string> # code (required)
  --limit: int # limit (required, format: int64)
  --offset: int # offset (required, format: int64)
  --order-direction: string # orderDirection (required)
]: nothing -> oneof<record<data: table<key: list>, totalElements: int, totalPages: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($code == null) { error make --unspanned { msg: "required query parameter 'code' missing: pass --code" } }
  if ($limit == null) { error make --unspanned { msg: "required query parameter 'limit' missing: pass --limit" } }
  if ($offset == null) { error make --unspanned { msg: "required query parameter 'offset' missing: pass --offset" } }
  if ($order_direction == null) { error make --unspanned { msg: "required query parameter 'orderDirection' missing: pass --order-direction" } }
  let qp = [(serialize-qp "code" $code "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orderDirection" $order_direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/user/{user_id}/observations") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"code": $code, "limit": $limit, "offset": $offset, "orderDirection": $order_direction} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Observations of a Certain Type For a User
#
# GET /user/{userId}/observations/{code}
# operationId: getObservationsByCode
export def "get-observations-by-code" [
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
]: nothing -> oneof<table<applies: string, bodySite: string, comments: string, comparator: string, diagram: string, group: record<address1: string, address2: string, address3: string, childGroups: list, code: string, contactPoints: list, created: string, fhirResourceId: string, groupFeatures: list, groupType: record, id: int, lastImportDate: string, lastUpdate: string, links: list, locations: list, name: string, parentGroups: list, postcode: string, sftpUser: string, shortName: string, visible: bool, visibleToJoin: bool>, id: int, identifier: string, location: string, name: string, temporaryUuid: string, units: string, value: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($code | is-empty) { error make --unspanned { msg: "path parameter 'code' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), code: (encode-path-segment $code)} | format pattern "/user/{user_id}/observations/{code}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get patient entered Observations of a Certain Type For a User
#
# GET /user/{userId}/observations/{code}/patiententered
# operationId: getPatientEnteredObservationsByCode
export def "get-patient-entered-observations-by-code" [
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
]: nothing -> oneof<table<applies: string, bodySite: string, comments: string, comparator: string, diagram: string, group: record<address1: string, address2: string, address3: string, childGroups: list, code: string, contactPoints: list, created: string, fhirResourceId: string, groupFeatures: list, groupType: record, id: int, lastImportDate: string, lastUpdate: string, links: list, locations: list, name: string, parentGroups: list, postcode: string, sftpUser: string, shortName: string, visible: bool, visibleToJoin: bool>, id: int, identifier: string, location: string, name: string, temporaryUuid: string, units: string, value: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($code | is-empty) { error make --unspanned { msg: "path parameter 'code' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), code: (encode-path-segment $code)} | format pattern "/user/{user_id}/observations/{code}/patiententered") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Available Patient Entered Observations Types For a User
#
# GET /user/{userId}/patiententeredobservationheadings
# operationId: getPatientEnteredObservationHeadings
export def "get-patient-entered-observation-headings" [
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
]: nothing -> oneof<table<code: string, created: string, decimalPlaces: int, defaultPanel: int, defaultPanelOrder: int, heading: string, id: int, infoLink: string, lastUpdate: string, maxGraph: float, minGraph: float, name: string, normalRange: string, observationHeadingGroups: list<record>, units: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/user/{user_id}/patiententeredobservationheadings") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
