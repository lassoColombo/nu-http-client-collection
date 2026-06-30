# Auto-generated client for GoToTraining v1.0.0
# Source: https://api.apis.guru/v2/specs/getgo.com/gototraining/1.0.0/swagger.json
# Auth: --token flag or $env.GOTOTRAINING_TOKEN

const BASE_URL = "https://api.getgo.com/G2T/rest"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o GOTOTRAINING_TOKEN | default "" }
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.getgo.com/G2T/rest"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts-organizers get-list-organisers" } } | get name | first)
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

# DEPRECATED: Get Organizers
#
# GET /accounts/{accountKey}/organizers
# DEPRECATED
# operationId: getAllOrganisers
@deprecated
export def "accounts-organizers get-list-organisers" [
  account_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<email: string, givenName: string, organizerKey: string, surname: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_key | is-empty) { error make --unspanned { msg: "path parameter 'accountKey' must be non-empty" } }
  let full_url = (build-url $base ({account_key: (encode-path-segment $account_key)} | format pattern "/accounts/{account_key}/organizers") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Get Trainings
#
# GET /organizers/{organizerKey}/trainings
# operationId: getAllTrainings
export def "organizers-trainings get-list" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<description: string, name: string, organizers: list<record>, registrationSettings: record<disableConfirmationEmail: bool, disableWebRegistration: bool>, timeZone: string, times: list<record>, trainingId: string, trainingKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}/trainings") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Create Training
#
# POST /organizers/{organizerKey}/trainings
# operationId: scheduleTraining
# --registrationSettings shape: {disableConfirmationEmail: bool, disableWebRegistration: bool}
# --times item shape: {endDate: string, startDate: string}
export def "organizers-trainings create-schedule" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
  --description: string # Description of the training
  name: string # Name of the training
  --organizers: list<int> # List of keys of the co-organizers for this training
  --registration-settings: any # Training settings, namely availability of web registration and confirmation emails to the training registrants — shape: {disableConfirmationEmail: bool, disableWebRegistration: bool}
  time_zone: string # Time zone of the training. (Must be a valid time zone ID, see https://goto-developer.logmein.com/time-zones)
  times: list # Array with startDate and endDate for the training sessions — item shape: {endDate: string, startDate: string}
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}/trainings") $auth.query)
  let req_body = {"description": $description, "name": $name, "organizers": $organizers, "registrationSettings": $registration_settings, "timeZone": $time_zone, "times": $times} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Delete Training
#
# DELETE /organizers/{organizerKey}/trainings/{trainingKey}
# operationId: cancelTraining
export def "organizers-trainings cancel" [
  organizer_key: int
  training_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  if ($training_key | is-empty) { error make --unspanned { msg: "path parameter 'trainingKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Get Training
#
# GET /organizers/{organizerKey}/trainings/{trainingKey}
# operationId: getTraining
export def "organizers-trainings get" [
  organizer_key: int
  training_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> record<description: string, name: string, organizers: table<email: string, givenName: string, organizerKey: string, surname: string>, registrationSettings: record<disableConfirmationEmail: bool, disableWebRegistration: bool>, timeZone: string, times: table<endDate: string, startDate: string>, trainingId: string, trainingKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  if ($training_key | is-empty) { error make --unspanned { msg: "path parameter 'trainingKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Get Management URL for Training
#
# GET /organizers/{organizerKey}/trainings/{trainingKey}/manageUrl
# operationId: getManageTrainingURL
export def "organizers-trainings-manage-url get" [
  organizer_key: int
  training_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  if ($training_key | is-empty) { error make --unspanned { msg: "path parameter 'trainingKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/manageUrl") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Update Training Name and Description
#
# PUT /organizers/{organizerKey}/trainings/{trainingKey}/nameDescription
# operationId: updateTrainingNameDescription
export def "organizers-trainings-name-description update" [
  organizer_key: int
  training_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
  --description: string # The training's description
  name: string # The training's name
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  if ($training_key | is-empty) { error make --unspanned { msg: "path parameter 'trainingKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/nameDescription") $auth.query)
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get Training Organizers
#
# GET /organizers/{organizerKey}/trainings/{trainingKey}/organizers
# operationId: getOrganisersForTraining
export def "organizers-trainings-organizers get-organisers" [
  organizer_key: int
  training_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<email: string, givenName: string, organizerKey: string, surname: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  if ($training_key | is-empty) { error make --unspanned { msg: "path parameter 'trainingKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/organizers") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Update Training Organizers
#
# PUT /organizers/{organizerKey}/trainings/{trainingKey}/organizers
# operationId: updateOrganisersForTraining
export def "organizers-trainings-organizers update-organisers" [
  organizer_key: int
  training_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
  --notify-organizers: oneof<nothing, bool> # Specifies whether an email should be sent notifying of the change to the training's organizers.
  organizers: list<int> # List of keys of the organizers for the training.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  if ($training_key | is-empty) { error make --unspanned { msg: "path parameter 'trainingKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/organizers") $auth.query)
  let req_body = {"notifyOrganizers": $notify_organizers, "organizers": $organizers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get Training Registrants
#
# GET /organizers/{organizerKey}/trainings/{trainingKey}/registrants
# operationId: getRegistrants
export def "organizers-trainings-registrants list" [
  organizer_key: int
  training_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<confirmationUrl: string, email: string, givenName: string, joinUrl: string, registrantKey: string, registrationDate: string, status: string, surname: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  if ($training_key | is-empty) { error make --unspanned { msg: "path parameter 'trainingKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/registrants") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Register for Training
#
# POST /organizers/{organizerKey}/trainings/{trainingKey}/registrants
# operationId: registerForTraining
export def "organizers-trainings-registrants create" [
  organizer_key: int
  training_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
  email: string # The registrant's email address
  given_name: string # The registrant's first name
  surname: string # The registrant's surname
]: any -> record<confirmationUrl: string, joinUrl: string, registrantKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  if ($training_key | is-empty) { error make --unspanned { msg: "path parameter 'trainingKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/registrants") $auth.query)
  let req_body = {"email": $email, "givenName": $given_name, "surname": $surname} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Cancel Registration
#
# DELETE /organizers/{organizerKey}/trainings/{trainingKey}/registrants/{registrantKey}
# operationId: cancelRegistration
export def "organizers-trainings-registrants cancel-registration" [
  organizer_key: int
  training_key: int
  registrant_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  if ($training_key | is-empty) { error make --unspanned { msg: "path parameter 'trainingKey' must be non-empty" } }
  if ($registrant_key | is-empty) { error make --unspanned { msg: "path parameter 'registrantKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key), registrant_key: (encode-path-segment $registrant_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/registrants/{registrant_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Get Registrant
#
# GET /organizers/{organizerKey}/trainings/{trainingKey}/registrants/{registrantKey}
# operationId: getRegistrant
export def "organizers-trainings-registrants get" [
  organizer_key: int
  training_key: int
  registrant_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> record<confirmationUrl: string, email: string, givenName: string, joinUrl: string, registrantKey: string, registrationDate: string, status: string, surname: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  if ($training_key | is-empty) { error make --unspanned { msg: "path parameter 'trainingKey' must be non-empty" } }
  if ($registrant_key | is-empty) { error make --unspanned { msg: "path parameter 'registrantKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key), registrant_key: (encode-path-segment $registrant_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/registrants/{registrant_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Update Training Registration Settings
#
# PUT /organizers/{organizerKey}/trainings/{trainingKey}/registrationSettings
# operationId: updateRegistrationSettingsForTraining
export def "organizers-trainings-registration-settings update" [
  organizer_key: int
  training_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
  --disable-confirmation-email: oneof<nothing, bool> # Indicates whether confirmation emails to the training registrants are disabled
  --disable-web-registration: oneof<nothing, bool> # Indicates whether the web registration for the training is disabled
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  if ($training_key | is-empty) { error make --unspanned { msg: "path parameter 'trainingKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/registrationSettings") $auth.query)
  let req_body = {"disableConfirmationEmail": $disable_confirmation_email, "disableWebRegistration": $disable_web_registration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get Start Url
#
# GET /organizers/{organizerKey}/trainings/{trainingKey}/startUrl
# operationId: getStartUrl
export def "organizers-trainings-start-url get" [
  organizer_key: int
  training_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  if ($training_key | is-empty) { error make --unspanned { msg: "path parameter 'trainingKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/startUrl") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Update Training Times
#
# PUT /organizers/{organizerKey}/trainings/{trainingKey}/times
# operationId: updateTrainingTimes
# --times item shape: {endDate: string, startDate: string}
export def "organizers-trainings-times update" [
  organizer_key: int
  training_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
  --notify-registrants: oneof<nothing, bool> # Notify registrants via email of change to training. Default is true
  --notify-trainers: oneof<nothing, bool> # Notify trainers via email of change to training. Default is true
  time_zone: string # Time zone of the training. Must be a valid time zone ID, see https://goto-developer.logmein.com/time-zones
  times: list # Start and end times for the training sessions — item shape: {endDate: string, startDate: string}
]: any -> record<notifiedRegistrants: int, notifiedTrainers: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  if ($training_key | is-empty) { error make --unspanned { msg: "path parameter 'trainingKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/times") $auth.query)
  let req_body = {"notifyRegistrants": $notify_registrants, "notifyTrainers": $notify_trainers, "timeZone": $time_zone, "times": $times} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Get Sessions by Date Range
#
# POST /reports/organizers/{organizerKey}/sessions
# operationId: getSessionDetailsForDateRange
export def "reports-organizers-sessions get-details-for-date-range" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
  end_date: string # The ending time of an interval (format: date-time)
  start_date: string # The starting time of an interval (format: date-time)
]: any -> table<attendanceCount: int, duration: int, organizers: list<record>, sessionEndTime: string, sessionKey: string, sessionStartTime: string, trainingName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/reports/organizers/{organizer_key}/sessions") $auth.query)
  let req_body = {"endDate": $end_date, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Get Attendance Details
#
# GET /reports/organizers/{organizerKey}/sessions/{sessionKey}/attendees
# operationId: getAttendanceDetails
export def "reports-organizers-sessions-attendees get-attendance-details" [
  organizer_key: int
  session_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<email: string, givenName: string, inSessionTimes: list<record>, surname: string, timeInSession: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  if ($session_key | is-empty) { error make --unspanned { msg: "path parameter 'sessionKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), session_key: (encode-path-segment $session_key)} | format pattern "/reports/organizers/{organizer_key}/sessions/{session_key}/attendees") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Get Sessions By Training
#
# GET /reports/organizers/{organizerKey}/trainings/{trainingKey}
# operationId: getSessionDetailsForTraining
export def "reports-organizers-trainings get-session-details" [
  organizer_key: int
  training_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<attendanceCount: int, duration: int, organizers: list<record>, sessionEndTime: string, sessionKey: string, sessionStartTime: string, trainingName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  if ($training_key | is-empty) { error make --unspanned { msg: "path parameter 'trainingKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/reports/organizers/{organizer_key}/trainings/{training_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Get Online Recordings for Training
#
# GET /trainings/{trainingKey}/recordings
# operationId: getRecordingsForTraining
export def "trainings-recordings get" [
  training_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> record<recordingList: table<description: string, downloadUrl: string, endDate: string, name: string, recordingId: int, registrationUrl: string, startDate: string>, trainingKey: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($training_key | is-empty) { error make --unspanned { msg: "path parameter 'trainingKey' must be non-empty" } }
  let full_url = (build-url $base ({training_key: (encode-path-segment $training_key)} | format pattern "/trainings/{training_key}/recordings") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Get Download for Online Recordings
#
# GET /trainings/{trainingKey}/recordings/{recordingId}
# operationId: getRecordingDownloadById
export def "trainings-recordings get-download" [
  training_key: int
  recording_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($training_key | is-empty) { error make --unspanned { msg: "path parameter 'trainingKey' must be non-empty" } }
  if ($recording_id | is-empty) { error make --unspanned { msg: "path parameter 'recordingId' must be non-empty" } }
  let full_url = (build-url $base ({training_key: (encode-path-segment $training_key), recording_id: (encode-path-segment $recording_id)} | format pattern "/trainings/{training_key}/recordings/{recording_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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
  send-get $req $insecure $raw $allow_errors $full [302]
}

# Start Training
#
# GET /trainings/{trainingKey}/start
# operationId: startTraining
export def "trainings-start start" [
  training_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> record<hostURL: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($training_key | is-empty) { error make --unspanned { msg: "path parameter 'trainingKey' must be non-empty" } }
  let full_url = (build-url $base ({training_key: (encode-path-segment $training_key)} | format pattern "/trainings/{training_key}/start") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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
