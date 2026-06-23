# Auto-generated client for GoToTraining v1.0.0
# Source: https://api.apis.guru/v2/specs/getgo.com/gototraining/1.0.0/swagger.json
# Auth: --token flag or $env.GOTOTRAINING_TOKEN

const BASE_URL = "https://api.getgo.com/G2T/rest"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GOTOTRAINING_TOKEN | default "" }
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
  let full_url = (build-url $base ({account_key: (encode-path-segment $account_key)} | format pattern "/accounts/{account_key}/organizers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}/trainings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}/trainings"))
  let req_body = {"description": $description, "name": $name, "organizers": $organizers, "registrationSettings": $registration_settings, "timeZone": $time_zone, "times": $times} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/manageUrl"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/nameDescription"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/organizers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/organizers"))
  let req_body = {"notifyOrganizers": $notify_organizers, "organizers": $organizers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/registrants"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/registrants"))
  let req_body = {"email": $email, "givenName": $given_name, "surname": $surname} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key), registrant_key: (encode-path-segment $registrant_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/registrants/{registrant_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key), registrant_key: (encode-path-segment $registrant_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/registrants/{registrant_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/registrationSettings"))
  let req_body = {"disableConfirmationEmail": $disable_confirmation_email, "disableWebRegistration": $disable_web_registration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/startUrl"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/organizers/{organizer_key}/trainings/{training_key}/times"))
  let req_body = {"notifyRegistrants": $notify_registrants, "notifyTrainers": $notify_trainers, "timeZone": $time_zone, "times": $times} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/reports/organizers/{organizer_key}/sessions"))
  let req_body = {"endDate": $end_date, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), session_key: (encode-path-segment $session_key)} | format pattern "/reports/organizers/{organizer_key}/sessions/{session_key}/attendees"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), training_key: (encode-path-segment $training_key)} | format pattern "/reports/organizers/{organizer_key}/trainings/{training_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({training_key: (encode-path-segment $training_key)} | format pattern "/trainings/{training_key}/recordings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({training_key: (encode-path-segment $training_key), recording_id: (encode-path-segment $recording_id)} | format pattern "/trainings/{training_key}/recordings/{recording_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({training_key: (encode-path-segment $training_key)} | format pattern "/trainings/{training_key}/start"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
