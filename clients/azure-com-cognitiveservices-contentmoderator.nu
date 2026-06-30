# Auto-generated client for Content Moderator Client v1.0
# Source: https://api.apis.guru/v2/specs/azure.com/cognitiveservices-ContentModerator/1.0/swagger.json
# Auth: --token flag or $env.CONTENT_MODERATOR_CLIENT_TOKEN

const BASE_URL = "{Endpoint}"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CONTENT_MODERATOR_CLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "ocp-apim-subscription-key" => { {scheme: $scheme, headers: {Ocp-Apim-Subscription-Key: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["{Endpoint}"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key"] }

# Completers for enum parameters
def content-type-completer [] { ["text/html" "text/markdown" "text/plain" "text/xml"] }
def content-type-completer-1 [] { ["Image" "Text" "Video"] }
def content-type-completer-2 [] { ["application/json" "image/jpeg"] }
def accept-completer [] { ["application/json" "text/json"] }
def content-type-completer-3 [] { ["text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "contentmoderator-lists-v1-0-imagelists get-management-image-list-image" } } | get name | first)
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

# Gets all the Image Lists.
#
# GET /contentmoderator/lists/v1.0/imagelists
# operationId: ListManagementImageLists_GetAllImageLists
export def "contentmoderator-lists-v1-0-imagelists get-management-image-list-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Description: string, Id: int, Metadata: record, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contentmoderator/lists/v1.0/imagelists" $auth.query)
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

# Creates an image list.
#
# POST /contentmoderator/lists/v1.0/imagelists
# operationId: ListManagementImageLists_Create
export def "contentmoderator-lists-v1-0-imagelists create-management-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The content type.
  --description: string # Description of the list.
  --metadata: record # Metadata of the list.
  --name: string # Name of the list.
]: any -> record<Description: string, Id: int, Metadata: record, Name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contentmoderator/lists/v1.0/imagelists" $auth.query)
  let req_body = {"Description": $description, "Metadata": $metadata, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Deletes image list with the list Id equal to list Id passed.
#
# DELETE /contentmoderator/lists/v1.0/imagelists/{listId}
# operationId: ListManagementImageLists_Delete
export def "contentmoderator-lists-v1-0-imagelists delete-management-image" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns the details of the image list with list Id equal to list Id passed.
#
# GET /contentmoderator/lists/v1.0/imagelists/{listId}
# operationId: ListManagementImageLists_GetDetails
export def "contentmoderator-lists-v1-0-imagelists get-management-image-details" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Description: string, Id: int, Metadata: record, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}") $auth.query)
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

# Updates an image list with list Id equal to list Id passed.
#
# PUT /contentmoderator/lists/v1.0/imagelists/{listId}
# operationId: ListManagementImageLists_Update
export def "contentmoderator-lists-v1-0-imagelists update-management-image" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The content type.
  --description: string # Description of the list.
  --metadata: record # Metadata of the list.
  --name: string # Name of the list.
]: any -> record<Description: string, Id: int, Metadata: record, Name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}") $auth.query)
  let req_body = {"Description": $description, "Metadata": $metadata, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Refreshes the index of the list with list Id equal to list Id passed.
#
# POST /contentmoderator/lists/v1.0/imagelists/{listId}/RefreshIndex
# operationId: ListManagementImageLists_RefreshIndex
export def "contentmoderator-lists-v1-0-imagelists-refresh-index list-management-image" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<AdvancedInfo: list<record>, ContentSourceId: string, IsUpdateSuccess: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}/RefreshIndex") $auth.query)
  let accept_val = "application/json"
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

# Deletes all images from the list with list Id equal to list Id passed.
#
# DELETE /contentmoderator/lists/v1.0/imagelists/{listId}/images
# operationId: ListManagementImage_DeleteAllImages
export def "contentmoderator-lists-v1-0-imagelists-images delete-management-list" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}/images") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Gets all image Ids from the list with list Id equal to list Id passed.
#
# GET /contentmoderator/lists/v1.0/imagelists/{listId}/images
# operationId: ListManagementImage_GetAllImageIds
export def "contentmoderator-lists-v1-0-imagelists-images get-management-list" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ContentIds: list<int>, ContentSource: string, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}/images") $auth.query)
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

# Add an image to the list with list Id equal to list Id passed.
#
# POST /contentmoderator/lists/v1.0/imagelists/{listId}/images
# operationId: ListManagementImage_AddImage
export def "contentmoderator-lists-v1-0-imagelists-images create-management" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: int # Tag for the image.
  --label: string # The image label.
]: nothing -> record<AdditionalInfo: table<Key: string, Value: string>, ContentId: string, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "label" $label "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}/images") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"tag": $tag, "label": $label} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Deletes an image from the list with list Id and image Id passed.
#
# DELETE /contentmoderator/lists/v1.0/imagelists/{listId}/images/{ImageId}
# operationId: ListManagementImage_DeleteImage
export def "contentmoderator-lists-v1-0-imagelists-images delete-management" [
  list_id: string
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'ImageId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id), image_id: (encode-path-segment $image_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}/images/{image_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# gets all the Term Lists
#
# GET /contentmoderator/lists/v1.0/termlists
# operationId: ListManagementTermLists_GetAllTermLists
export def "contentmoderator-lists-v1-0-termlists get-management-term-list-term" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Description: string, Id: int, Metadata: record, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contentmoderator/lists/v1.0/termlists" $auth.query)
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

# Creates a Term List
#
# POST /contentmoderator/lists/v1.0/termlists
# operationId: ListManagementTermLists_Create
export def "contentmoderator-lists-v1-0-termlists create-management-term" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The content type.
  --description: string # Description of the list.
  --metadata: record # Metadata of the list.
  --name: string # Name of the list.
]: any -> record<Description: string, Id: int, Metadata: record, Name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contentmoderator/lists/v1.0/termlists" $auth.query)
  let req_body = {"Description": $description, "Metadata": $metadata, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Deletes term list with the list Id equal to list Id passed.
#
# DELETE /contentmoderator/lists/v1.0/termlists/{listId}
# operationId: ListManagementTermLists_Delete
export def "contentmoderator-lists-v1-0-termlists delete-management-term" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns list Id details of the term list with list Id equal to list Id passed.
#
# GET /contentmoderator/lists/v1.0/termlists/{listId}
# operationId: ListManagementTermLists_GetDetails
export def "contentmoderator-lists-v1-0-termlists get-management-term-details" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Description: string, Id: int, Metadata: record, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}") $auth.query)
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

# Updates an Term List.
#
# PUT /contentmoderator/lists/v1.0/termlists/{listId}
# operationId: ListManagementTermLists_Update
export def "contentmoderator-lists-v1-0-termlists update-management-term" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The content type.
  --description: string # Description of the list.
  --metadata: record # Metadata of the list.
  --name: string # Name of the list.
]: any -> record<Description: string, Id: int, Metadata: record, Name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}") $auth.query)
  let req_body = {"Description": $description, "Metadata": $metadata, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Refreshes the index of the list with list Id equal to list ID passed.
#
# POST /contentmoderator/lists/v1.0/termlists/{listId}/RefreshIndex
# operationId: ListManagementTermLists_RefreshIndex
export def "contentmoderator-lists-v1-0-termlists-refresh-index list-management-term" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms.
]: nothing -> record<AdvancedInfo: list<record>, ContentSourceId: string, IsUpdateSuccess: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}/RefreshIndex") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"language": $language} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Deletes all terms from the list with list Id equal to the list Id passed.
#
# DELETE /contentmoderator/lists/v1.0/termlists/{listId}/terms
# operationId: ListManagementTerm_DeleteAllTerms
export def "contentmoderator-lists-v1-0-termlists-terms delete-management-list" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms.
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}/terms") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"language": $language} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets all terms from the list with list Id equal to the list Id passed.
#
# GET /contentmoderator/lists/v1.0/termlists/{listId}/terms
# operationId: ListManagementTerm_GetAllTerms
export def "contentmoderator-lists-v1-0-termlists-terms get-management-list" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms.
  --offset: int # The pagination start index.
  --limit: int # The max limit.
]: nothing -> record<Data: record<Language: string, Status: record<Code: int, Description: string, Exception: string>, Terms: list<record>, TrackingId: string>, Paging: record<Limit: int, Offset: int, Returned: int, Total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}/terms") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"language": $language, "offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a term from the list with list Id equal to the list Id passed.
#
# DELETE /contentmoderator/lists/v1.0/termlists/{listId}/terms/{term}
# operationId: ListManagementTerm_DeleteTerm
export def "contentmoderator-lists-v1-0-termlists-terms delete-management" [
  list_id: string
  term: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms.
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  if ($term | is-empty) { error make --unspanned { msg: "path parameter 'term' must be non-empty" } }
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id), term: (encode-path-segment $term)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}/terms/{term}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"language": $language} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Add a term to the term list with list Id equal to list Id passed.
#
# POST /contentmoderator/lists/v1.0/termlists/{listId}/terms/{term}
# operationId: ListManagementTerm_AddTerm
export def "contentmoderator-lists-v1-0-termlists-terms create-management" [
  list_id: string
  term: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms.
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  if ($term | is-empty) { error make --unspanned { msg: "path parameter 'term' must be non-empty" } }
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id), term: (encode-path-segment $term)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}/terms/{term}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"language": $language} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Returns probabilities of the image containing racy or adult content.
#
# POST /contentmoderator/moderate/v1.0/ProcessImage/Evaluate
# operationId: ImageModeration_Evaluate
export def "contentmoderator-moderate-v1-0-process-image-evaluate create-moderation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-image: oneof<nothing, bool> # Whether to retain the submitted image for future use; defaults to false if omitted.
]: nothing -> record<AdultClassificationScore: float, AdvancedInfo: table<Key: string, Value: string>, CacheID: string, IsImageAdultClassified: bool, IsImageRacyClassified: bool, RacyClassificationScore: float, Result: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "CacheImage" $cache_image "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessImage/Evaluate" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"CacheImage": $cache_image} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Returns the list of faces found.
#
# POST /contentmoderator/moderate/v1.0/ProcessImage/FindFaces
# operationId: ImageModeration_FindFaces
export def "contentmoderator-moderate-v1-0-process-image-find-faces find-moderation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-image: oneof<nothing, bool> # Whether to retain the submitted image for future use; defaults to false if omitted.
]: nothing -> record<AdvancedInfo: table<Key: string, Value: string>, CacheId: string, Count: int, Faces: table<Bottom: int, Left: int, Right: int, Top: int>, Result: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "CacheImage" $cache_image "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessImage/FindFaces" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"CacheImage": $cache_image} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Fuzzily match an image against one of your custom Image Lists. You can create and manage your custom image lists using this (/docs/services/578ff44d2703741568569ab9/operations/578ff7b12703741568569abe) API. Returns ID and tags of matching image. Note: Refresh Index must be run on the corresponding Image List before additions and removals are reflected in the response.
#
# POST /contentmoderator/moderate/v1.0/ProcessImage/Match
# operationId: ImageModeration_Match
export def "contentmoderator-moderate-v1-0-process-image-match create-moderation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --list-id: string # The list Id.
  --cache-image: oneof<nothing, bool> # Whether to retain the submitted image for future use; defaults to false if omitted.
]: nothing -> record<CacheID: string, IsMatch: bool, Matches: table<Label: string, MatchId: int, Score: float, Source: string, Tags: list>, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listId" $list_id "scalar") (serialize-qp "CacheImage" $cache_image "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessImage/Match" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"listId": $list_id, "CacheImage": $cache_image} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Returns any text found in the image for the language specified. If no language is specified in input then the detection defaults to English.
#
# POST /contentmoderator/moderate/v1.0/ProcessImage/OCR
# operationId: ImageModeration_OCR
export def "contentmoderator-moderate-v1-0-process-image-ocr create-moderation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms.
  --cache-image: oneof<nothing, bool> # Whether to retain the submitted image for future use; defaults to false if omitted.
  --enhanced: oneof<nothing, bool> # When set to True, the image goes through additional processing to come with additional candidates. image/tiff is not supported when enhanced is set to true Note: This impacts the response time. (default: false)
]: nothing -> record<CacheId: string, Candidates: table<Confidence: float, Text: string>, Language: string, Metadata: table<Key: string, Value: string>, Status: record<Code: int, Description: string, Exception: string>, Text: string, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "CacheImage" $cache_image "scalar") (serialize-qp "enhanced" $enhanced "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessImage/OCR" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"language": $language, "CacheImage": $cache_image, "enhanced": $enhanced} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# This operation will detect the language of given input content. Returns the ISO 639-3 code (http://www-01.sil.org/iso639-3/codes.asp) for the predominant language comprising the submitted text. Over 110 languages supported.
#
# POST /contentmoderator/moderate/v1.0/ProcessText/DetectLanguage
# operationId: TextModeration_DetectLanguage
export def "contentmoderator-moderate-v1-0-process-text-detect-language create-moderation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer # The content type.
  --body: any
]: any -> record<DetectedLanguage: string, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessText/DetectLanguage" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "text/plain")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Detect profanity and match against custom and shared blacklists
#
# POST /contentmoderator/moderate/v1.0/ProcessText/Screen/
# operationId: TextModeration_ScreenText
export def "contentmoderator-moderate-v1-0-process-text-screen create-moderation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the text.
  --autocorrect: oneof<nothing, bool> # Autocorrect text. (default: false)
  --pii: oneof<nothing, bool> # Detect personal identifiable information. (default: false)
  --list-id: string # The list Id.
  --classify: oneof<nothing, bool> # Classify input. (default: false)
  --content-type: string@content-type-completer # The content type.
  --body: any
]: any -> record<AutoCorrectedText: string, Classification: record<Category1: record<Score: float>, Category2: record<Score: float>, Category3: record<Score: float>, ReviewRecommended: bool>, Language: string, Misrepresentation: list<string>, NormalizedText: string, OriginalText: string, PII: record<Address: list<record>, Email: list<record>, IPA: list<record>, Phone: list<record>, SSN: list<record>>, Status: record<Code: int, Description: string, Exception: string>, Terms: table<Index: int, ListId: int, OriginalIndex: int, Term: string>, TrackingId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "autocorrect" $autocorrect "scalar") (serialize-qp "PII" $pii "scalar") (serialize-qp "listId" $list_id "scalar") (serialize-qp "classify" $classify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessText/Screen/" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "text/plain")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: ({"language": $language, "autocorrect": $autocorrect, "PII": $pii, "listId": $list_id, "classify": $classify} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# A job Id will be returned for the content posted on this endpoint. Once the content is evaluated against the Workflow provided the review will be created or ignored based on the workflow expression. CallBack Schemas Job Completion CallBack Sample { "JobId": ", "ReviewId": "", "WorkFlowId": "default", "Status": "", "ContentType": "Image", "ContentId": "", "CallBackType": "Job", "Metadata": { "adultscore": "0.xxx", "a": "False", "racyscore": "0.xxx", "r": "True" } } Review Completion CallBack Sample { "ReviewId": "", "ModifiedOn": "2016-10-11T22:36:32.9934851Z", "ModifiedBy": "", "CallBackType": "Review", "ContentId": "", "Metadata": { "adultscore": "0.xxx", "a": "False", "racyscore": "0.xxx", "r": "True" }, "ReviewerResultTags": { "a": "False", "r": "True" } } .
#
# POST /contentmoderator/review/v1.0/teams/{teamName}/jobs
# operationId: Reviews_CreateJob
export def "contentmoderator-review-v1-0-teams-jobs create" [
  team_name: string
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
  --content-type: string@content-type-completer-1 # Image, Text or Video.
  --content-id: string # Id/Name to identify the content submitted.
  --workflow-name: string # Workflow Name that you want to invoke.
  --call-back-endpoint: string # Callback endpoint for posting the create job result.
  --content-type-2: string@content-type-completer-2 # The content type. (disambiguated-2)
  content_value: string # Content to evaluate for a job.
]: any -> record<JobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  let qp = [(serialize-qp "ContentType" $content_type "scalar") (serialize-qp "ContentId" $content_id "scalar") (serialize-qp "WorkflowName" $workflow_name "scalar") (serialize-qp "CallBackEndpoint" $call_back_endpoint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/jobs") $qp $auth.query)
  let req_body = {"ContentValue": $content_value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type_2} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type_2 | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: ({"ContentType": $content_type, "ContentId": $content_id, "WorkflowName": $workflow_name, "CallBackEndpoint": $call_back_endpoint} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Get the Job Details for a Job Id.
#
# GET /contentmoderator/review/v1.0/teams/{teamName}/jobs/{JobId}
# operationId: Reviews_GetJobDetails
export def "contentmoderator-review-v1-0-teams-jobs get-details" [
  team_name: string
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
]: nothing -> record<CallBackEndpoint: string, Id: string, JobExecutionReport: table<Msg: string, Ts: string>, ResultMetaData: table<Key: string, Value: string>, ReviewId: string, Status: string, TeamName: string, Type: string, WorkflowId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), job_id: (encode-path-segment $job_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/jobs/{job_id}") $auth.query)
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

# The reviews created would show up for Reviewers on your team. As Reviewers complete reviewing, results of the Review would be POSTED (i.e. HTTP POST) on the specified CallBackEndpoint. CallBack Schemas Review Completion CallBack Sample { "ReviewId": "", "ModifiedOn": "2016-10-11T22:36:32.9934851Z", "ModifiedBy": "", "CallBackType": "Review", "ContentId": "", "Metadata": { "adultscore": "0.xxx", "a": "False", "racyscore": "0.xxx", "r": "True" }, "ReviewerResultTags": { "a": "False", "r": "True" } } .
#
# POST /contentmoderator/review/v1.0/teams/{teamName}/reviews
# operationId: Reviews_CreateReviews
export def "contentmoderator-review-v1-0-teams-reviews create" [
  team_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sub-team: string # SubTeam of your team, you want to assign the created review to.
  --url-content-type: string # The content type.
  --body: list
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  let qp = [(serialize-qp "subTeam" $sub_team "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"UrlContentType": $url_content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"subTeam": $sub_team} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns review details for the review Id passed.
#
# GET /contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}
# operationId: Reviews_GetReview
export def "contentmoderator-review-v1-0-teams-reviews get" [
  team_name: string
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<CallbackEndpoint: string, Content: string, ContentId: string, CreatedBy: string, Metadata: table<Key: string, Value: string>, ReviewId: string, ReviewerResultTags: table<Key: string, Value: string>, Status: string, SubTeam: string, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  if ($review_id | is-empty) { error make --unspanned { msg: "path parameter 'reviewId' must be non-empty" } }
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}") $auth.query)
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

# The reviews created would show up for Reviewers on your team. As Reviewers complete reviewing, results of the Review would be POSTED (i.e. HTTP POST) on the specified CallBackEndpoint. CallBack Schemas Review Completion CallBack Sample { "ReviewId": "", "ModifiedOn": "2016-10-11T22:36:32.9934851Z", "ModifiedBy": "", "CallBackType": "Review", "ContentId": "", "Metadata": { "adultscore": "0.xxx", "a": "False", "racyscore": "0.xxx", "r": "True" }, "ReviewerResultTags": { "a": "False", "r": "True" } } .
#
# GET /contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}/frames
# operationId: Reviews_GetVideoFrames
export def "contentmoderator-review-v1-0-teams-reviews-frames get-video" [
  team_name: string
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-seed: int # Time stamp of the frame from where you want to start fetching the frames.
  --no-of-records: int # Number of frames to fetch.
  --filter: string # Get frames filtered by tags.
]: nothing -> record<ReviewId: string, VideoFrames: table<FrameImage: string, Metadata: list, ReviewerResultTags: list, Timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  if ($review_id | is-empty) { error make --unspanned { msg: "path parameter 'reviewId' must be non-empty" } }
  let qp = [(serialize-qp "startSeed" $start_seed "scalar") (serialize-qp "noOfRecords" $no_of_records "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}/frames") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"startSeed": $start_seed, "noOfRecords": $no_of_records, "filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# The reviews created would show up for Reviewers on your team. As Reviewers complete reviewing, results of the Review would be POSTED (i.e. HTTP POST) on the specified CallBackEndpoint. CallBack Schemas Review Completion CallBack Sample { "ReviewId": "", "ModifiedOn": "2016-10-11T22:36:32.9934851Z", "ModifiedBy": "", "CallBackType": "Review", "ContentId": "", "Metadata": { "adultscore": "0.xxx", "a": "False", "racyscore": "0.xxx", "r": "True" }, "ReviewerResultTags": { "a": "False", "r": "True" } } .
#
# POST /contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}/frames
# operationId: Reviews_AddVideoFrame
export def "contentmoderator-review-v1-0-teams-reviews-frames create-video" [
  team_name: string
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timescale: int # Timescale of the video you are adding frames to.
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  if ($review_id | is-empty) { error make --unspanned { msg: "path parameter 'reviewId' must be non-empty" } }
  let qp = [(serialize-qp "timescale" $timescale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}/frames") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"timescale": $timescale} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Publish video review to make it available for review.
#
# POST /contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}/publish
# operationId: Reviews_PublishVideoReview
export def "contentmoderator-review-v1-0-teams-reviews-publish publish-video" [
  team_name: string
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  if ($review_id | is-empty) { error make --unspanned { msg: "path parameter 'reviewId' must be non-empty" } }
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}/publish") $auth.query)
  let accept_val = "application/json"
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
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# This API adds a transcript file (text version of all the words spoken in a video) to a video review. The file should be a valid WebVTT format.
#
# PUT /contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}/transcript
# operationId: Reviews_AddVideoTranscript
export def "contentmoderator-review-v1-0-teams-reviews-transcript create-video" [
  team_name: string
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer-3 # The content type.
  --body: any
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  if ($review_id | is-empty) { error make --unspanned { msg: "path parameter 'reviewId' must be non-empty" } }
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}/transcript") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "text/plain")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [204]
}

# This API adds a transcript screen text result file for a video review. Transcript screen text result file is a result of Screen Text API . In order to generate transcript screen text result file , a transcript file has to be screened for profanity using Screen Text API.
#
# PUT /contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}/transcriptmoderationresult
# operationId: Reviews_AddVideoTranscriptModerationResult
export def "contentmoderator-review-v1-0-teams-reviews-transcriptmoderationresult create-video-transcript-moderation-result" [
  team_name: string
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The content type.
  --body: list
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  if ($review_id | is-empty) { error make --unspanned { msg: "path parameter 'reviewId' must be non-empty" } }
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}/transcriptmoderationresult") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [204]
}
