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
    "ocp-apim-subscription-key" => { {scheme: $scheme, headers: {"Ocp-Apim-Subscription-Key": $token_val}, query: "", location: "header"} }
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
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-management-image-lists-get-all-image-lists" "list-management-image-lists-create" "list-management-image-lists-delete" "list-management-image-lists-get-details" "list-management-image-lists-update" "list-management-image-lists-refresh-index" "list-management-image-delete-all-images" "list-management-image-get-all-image-ids" "list-management-image-add-image" "list-management-image-delete-image" "list-management-term-lists-get-all-term-lists" "list-management-term-lists-create" "list-management-term-lists-delete" "list-management-term-lists-get-details" "list-management-term-lists-update" "list-management-term-lists-refresh-index" "list-management-term-delete-all-terms" "list-management-term-get-all-terms" "list-management-term-delete-term" "list-management-term-add-term" "image-moderation-evaluate" "image-moderation-find-faces" "image-moderation-match" "image-moderation-ocr" "text-moderation-detect-language" "text-moderation-screen-text" "reviews-create-job" "reviews-get-job-details" "reviews-create-reviews" "reviews-get-review" "reviews-get-video-frames" "reviews-add-video-frame" "reviews-publish-video-review" "reviews-add-video-transcript" "reviews-add-video-transcript-moderation-result" "commands"] | sort) } | get name | first)
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

# Gets all the Image Lists.
#
# GET /contentmoderator/lists/v1.0/imagelists
# operationId: ListManagementImageLists_GetAllImageLists
export def "list-management-image-lists-get-all-image-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<Description: string, Id: int, Metadata: record, Name: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contentmoderator/lists/v1.0/imagelists" $auth.query)
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

# Creates an image list.
#
# POST /contentmoderator/lists/v1.0/imagelists
# operationId: ListManagementImageLists_Create
export def "list-management-image-lists-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The content type. (required)
  --description: string # Description of the list.
  --metadata: record # Metadata of the list.
  --name: string # Name of the list.
]: any -> oneof<record<Description: string, Id: int, Metadata: record, Name: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contentmoderator/lists/v1.0/imagelists" $auth.query)
  let req_body = {"Description": $description, "Metadata": $metadata, "Name": $name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else if ($effective_ct =~ '\+json\s*(;|$)') { (if (($req_body | describe) =~ '^(record|list|table)') { $req_body | to json -r } else { $req_body }) } else { $req_body }
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
export def "list-management-image-lists-delete" [
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns the details of the image list with list Id equal to list Id passed.
#
# GET /contentmoderator/lists/v1.0/imagelists/{listId}
# operationId: ListManagementImageLists_GetDetails
export def "list-management-image-lists-get-details" [
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
]: nothing -> oneof<record<Description: string, Id: int, Metadata: record, Name: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}") $auth.query)
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

# Updates an image list with list Id equal to list Id passed.
#
# PUT /contentmoderator/lists/v1.0/imagelists/{listId}
# operationId: ListManagementImageLists_Update
export def "list-management-image-lists-update" [
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
  --content-type: string # The content type. (required)
  --description: string # Description of the list.
  --metadata: record # Metadata of the list.
  --name: string # Name of the list.
]: any -> oneof<record<Description: string, Id: int, Metadata: record, Name: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}") $auth.query)
  let req_body = {"Description": $description, "Metadata": $metadata, "Name": $name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else if ($effective_ct =~ '\+json\s*(;|$)') { (if (($req_body | describe) =~ '^(record|list|table)') { $req_body | to json -r } else { $req_body }) } else { $req_body }
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
export def "list-management-image-lists-refresh-index" [
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
]: nothing -> oneof<record<AdvancedInfo: list<record>, ContentSourceId: string, IsUpdateSuccess: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}/RefreshIndex") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "list-management-image-delete-all-images" [
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Gets all image Ids from the list with list Id equal to list Id passed.
#
# GET /contentmoderator/lists/v1.0/imagelists/{listId}/images
# operationId: ListManagementImage_GetAllImageIds
export def "list-management-image-get-all-image-ids" [
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
]: nothing -> oneof<record<ContentIds: list<int>, ContentSource: string, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}/images") $auth.query)
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

# Add an image to the list with list Id equal to list Id passed.
#
# POST /contentmoderator/lists/v1.0/imagelists/{listId}/images
# operationId: ListManagementImage_AddImage
export def "list-management-image-add-image" [
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
]: nothing -> oneof<record<AdditionalInfo: table<Key: string, Value: string>, ContentId: string, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "label" $label "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}/images") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "list-management-image-delete-image" [
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# gets all the Term Lists
#
# GET /contentmoderator/lists/v1.0/termlists
# operationId: ListManagementTermLists_GetAllTermLists
export def "list-management-term-lists-get-all-term-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<Description: string, Id: int, Metadata: record, Name: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contentmoderator/lists/v1.0/termlists" $auth.query)
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

# Creates a Term List
#
# POST /contentmoderator/lists/v1.0/termlists
# operationId: ListManagementTermLists_Create
export def "list-management-term-lists-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The content type. (required)
  --description: string # Description of the list.
  --metadata: record # Metadata of the list.
  --name: string # Name of the list.
]: any -> oneof<record<Description: string, Id: int, Metadata: record, Name: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contentmoderator/lists/v1.0/termlists" $auth.query)
  let req_body = {"Description": $description, "Metadata": $metadata, "Name": $name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else if ($effective_ct =~ '\+json\s*(;|$)') { (if (($req_body | describe) =~ '^(record|list|table)') { $req_body | to json -r } else { $req_body }) } else { $req_body }
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
export def "list-management-term-lists-delete" [
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns list Id details of the term list with list Id equal to list Id passed.
#
# GET /contentmoderator/lists/v1.0/termlists/{listId}
# operationId: ListManagementTermLists_GetDetails
export def "list-management-term-lists-get-details" [
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
]: nothing -> oneof<record<Description: string, Id: int, Metadata: record, Name: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}") $auth.query)
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

# Updates an Term List.
#
# PUT /contentmoderator/lists/v1.0/termlists/{listId}
# operationId: ListManagementTermLists_Update
export def "list-management-term-lists-update" [
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
  --content-type: string # The content type. (required)
  --description: string # Description of the list.
  --metadata: record # Metadata of the list.
  --name: string # Name of the list.
]: any -> oneof<record<Description: string, Id: int, Metadata: record, Name: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}") $auth.query)
  let req_body = {"Description": $description, "Metadata": $metadata, "Name": $name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else if ($effective_ct =~ '\+json\s*(;|$)') { (if (($req_body | describe) =~ '^(record|list|table)') { $req_body | to json -r } else { $req_body }) } else { $req_body }
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
export def "list-management-term-lists-refresh-index" [
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
  --language: string # Language of the terms. (required)
]: nothing -> oneof<record<AdvancedInfo: list<record>, ContentSourceId: string, IsUpdateSuccess: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  if ($language == null) { error make --unspanned { msg: "required query parameter 'language' missing: pass --language" } }
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}/RefreshIndex") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "list-management-term-delete-all-terms" [
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
  --language: string # Language of the terms. (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  if ($language == null) { error make --unspanned { msg: "required query parameter 'language' missing: pass --language" } }
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}/terms") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "list-management-term-get-all-terms" [
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
  --language: string # Language of the terms. (required)
  --offset: int # The pagination start index.
  --limit: int # The max limit.
]: nothing -> oneof<record<Data: record<Language: string, Status: record<Code: int, Description: string, Exception: string>, Terms: list<record>, TrackingId: string>, Paging: record<Limit: int, Offset: int, Returned: int, Total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  if ($language == null) { error make --unspanned { msg: "required query parameter 'language' missing: pass --language" } }
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}/terms") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "list-management-term-delete-term" [
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
  --language: string # Language of the terms. (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  if ($term | is-empty) { error make --unspanned { msg: "path parameter 'term' must be non-empty" } }
  if ($language == null) { error make --unspanned { msg: "required query parameter 'language' missing: pass --language" } }
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id), term: (encode-path-segment $term)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}/terms/{term}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "list-management-term-add-term" [
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
  --language: string # Language of the terms. (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  if ($term | is-empty) { error make --unspanned { msg: "path parameter 'term' must be non-empty" } }
  if ($language == null) { error make --unspanned { msg: "required query parameter 'language' missing: pass --language" } }
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id), term: (encode-path-segment $term)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}/terms/{term}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "image-moderation-evaluate" [
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
]: nothing -> oneof<record<AdultClassificationScore: float, AdvancedInfo: table<Key: string, Value: string>, CacheID: string, IsImageAdultClassified: bool, IsImageRacyClassified: bool, RacyClassificationScore: float, Result: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "CacheImage" $cache_image "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessImage/Evaluate" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "image-moderation-find-faces" [
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
]: nothing -> oneof<record<AdvancedInfo: table<Key: string, Value: string>, CacheId: string, Count: int, Faces: table<Bottom: int, Left: int, Right: int, Top: int>, Result: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "CacheImage" $cache_image "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessImage/FindFaces" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "image-moderation-match" [
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
]: nothing -> oneof<record<CacheID: string, IsMatch: bool, Matches: table<Label: string, MatchId: int, Score: float, Source: string, Tags: list>, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listId" $list_id "scalar") (serialize-qp "CacheImage" $cache_image "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessImage/Match" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "image-moderation-ocr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms. (required)
  --cache-image: oneof<nothing, bool> # Whether to retain the submitted image for future use; defaults to false if omitted.
  --enhanced: oneof<nothing, bool> # When set to True, the image goes through additional processing to come with additional candidates. image/tiff is not supported when enhanced is set to true Note: This impacts the response time. (default: false)
]: nothing -> oneof<record<CacheId: string, Candidates: table<Confidence: float, Text: string>, Language: string, Metadata: table<Key: string, Value: string>, Status: record<Code: int, Description: string, Exception: string>, Text: string, TrackingId: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($language == null) { error make --unspanned { msg: "required query parameter 'language' missing: pass --language" } }
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "CacheImage" $cache_image "scalar") (serialize-qp "enhanced" $enhanced "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessImage/OCR" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "text-moderation-detect-language" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer # The content type. (required)
  --body: any
]: any -> oneof<record<DetectedLanguage: string, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessText/DetectLanguage" $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let effective_ct = ($content_type | default "text/plain")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else if ($effective_ct =~ '\+json\s*(;|$)') { (if (($req_body | describe) =~ '^(record|list|table)') { $req_body | to json -r } else { $req_body }) } else { $req_body }
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
export def "text-moderation-screen-text" [
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
  --content-type: string@content-type-completer # The content type. (required)
  --body: any
]: any -> oneof<record<AutoCorrectedText: string, Classification: record<Category1: record<Score: float>, Category2: record<Score: float>, Category3: record<Score: float>, ReviewRecommended: bool>, Language: string, Misrepresentation: list<string>, NormalizedText: string, OriginalText: string, PII: record<Address: list<record>, Email: list<record>, IPA: list<record>, Phone: list<record>, SSN: list<record>>, Status: record<Code: int, Description: string, Exception: string>, Terms: table<Index: int, ListId: int, OriginalIndex: int, Term: string>, TrackingId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "autocorrect" $autocorrect "scalar") (serialize-qp "PII" $pii "scalar") (serialize-qp "listId" $list_id "scalar") (serialize-qp "classify" $classify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessText/Screen/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let effective_ct = ($content_type | default "text/plain")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else if ($effective_ct =~ '\+json\s*(;|$)') { (if (($req_body | describe) =~ '^(record|list|table)') { $req_body | to json -r } else { $req_body }) } else { $req_body }
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
export def "reviews-create-job" [
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
  --content-type: string@content-type-completer-1 # Image, Text or Video. (required)
  --content-id: string # Id/Name to identify the content submitted. (required)
  --workflow-name: string # Workflow Name that you want to invoke. (required)
  --call-back-endpoint: string # Callback endpoint for posting the create job result.
  --hdr-content-type: string@content-type-completer-2 # The content type. (required) (spec name: Content-Type)
  content_value: string # Content to evaluate for a job.
]: any -> oneof<record<JobId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  if ($content_type == null) { error make --unspanned { msg: "required query parameter 'ContentType' missing: pass --content-type" } }
  if ($content_id == null) { error make --unspanned { msg: "required query parameter 'ContentId' missing: pass --content-id" } }
  if ($workflow_name == null) { error make --unspanned { msg: "required query parameter 'WorkflowName' missing: pass --workflow-name" } }
  let qp = [(serialize-qp "ContentType" $content_type "scalar") (serialize-qp "ContentId" $content_id "scalar") (serialize-qp "WorkflowName" $workflow_name "scalar") (serialize-qp "CallBackEndpoint" $call_back_endpoint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/jobs") $qp $auth.query)
  let req_body = {"ContentValue": $content_value} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $hdr_content_type} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let effective_ct = ($hdr_content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else if ($effective_ct =~ '\+json\s*(;|$)') { (if (($req_body | describe) =~ '^(record|list|table)') { $req_body | to json -r } else { $req_body }) } else { $req_body }
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
export def "reviews-get-job-details" [
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
]: nothing -> oneof<record<CallBackEndpoint: string, Id: string, JobExecutionReport: table<Msg: string, Ts: string>, ResultMetaData: table<Key: string, Value: string>, ReviewId: string, Status: string, TeamName: string, Type: string, WorkflowId: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'JobId' must be non-empty" } }
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), job_id: (encode-path-segment $job_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/jobs/{job_id}") $auth.query)
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

# The reviews created would show up for Reviewers on your team. As Reviewers complete reviewing, results of the Review would be POSTED (i.e. HTTP POST) on the specified CallBackEndpoint. CallBack Schemas Review Completion CallBack Sample { "ReviewId": "", "ModifiedOn": "2016-10-11T22:36:32.9934851Z", "ModifiedBy": "", "CallBackType": "Review", "ContentId": "", "Metadata": { "adultscore": "0.xxx", "a": "False", "racyscore": "0.xxx", "r": "True" }, "ReviewerResultTags": { "a": "False", "r": "True" } } .
#
# POST /contentmoderator/review/v1.0/teams/{teamName}/reviews
# operationId: Reviews_CreateReviews
export def "reviews-create-reviews" [
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
  --url-content-type: string # The content type. (required)
  --body: list
]: any -> oneof<list<string>, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  if ($url_content_type == null) { error make --unspanned { msg: "required header parameter 'UrlContentType' missing: pass --url-content-type" } }
  let qp = [(serialize-qp "subTeam" $sub_team "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews") $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"UrlContentType": $url_content_type} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "reviews-get-review" [
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
]: nothing -> oneof<record<CallbackEndpoint: string, Content: string, ContentId: string, CreatedBy: string, Metadata: table<Key: string, Value: string>, ReviewId: string, ReviewerResultTags: table<Key: string, Value: string>, Status: string, SubTeam: string, Type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  if ($review_id | is-empty) { error make --unspanned { msg: "path parameter 'reviewId' must be non-empty" } }
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}") $auth.query)
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

# The reviews created would show up for Reviewers on your team. As Reviewers complete reviewing, results of the Review would be POSTED (i.e. HTTP POST) on the specified CallBackEndpoint. CallBack Schemas Review Completion CallBack Sample { "ReviewId": "", "ModifiedOn": "2016-10-11T22:36:32.9934851Z", "ModifiedBy": "", "CallBackType": "Review", "ContentId": "", "Metadata": { "adultscore": "0.xxx", "a": "False", "racyscore": "0.xxx", "r": "True" }, "ReviewerResultTags": { "a": "False", "r": "True" } } .
#
# GET /contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}/frames
# operationId: Reviews_GetVideoFrames
export def "reviews-get-video-frames" [
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
]: nothing -> oneof<record<ReviewId: string, VideoFrames: table<FrameImage: string, Metadata: list, ReviewerResultTags: list, Timestamp: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  if ($review_id | is-empty) { error make --unspanned { msg: "path parameter 'reviewId' must be non-empty" } }
  let qp = [(serialize-qp "startSeed" $start_seed "scalar") (serialize-qp "noOfRecords" $no_of_records "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}/frames") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "reviews-add-video-frame" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  if ($review_id | is-empty) { error make --unspanned { msg: "path parameter 'reviewId' must be non-empty" } }
  let qp = [(serialize-qp "timescale" $timescale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}/frames") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "reviews-publish-video-review" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  if ($review_id | is-empty) { error make --unspanned { msg: "path parameter 'reviewId' must be non-empty" } }
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}/publish") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "reviews-add-video-transcript" [
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
  --content-type: string@content-type-completer-3 # The content type. (required)
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  if ($review_id | is-empty) { error make --unspanned { msg: "path parameter 'reviewId' must be non-empty" } }
  let content_type = ($content_type | default "text/plain")
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}/transcript") $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let effective_ct = ($content_type | default "text/plain")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else if ($effective_ct =~ '\+json\s*(;|$)') { (if (($req_body | describe) =~ '^(record|list|table)') { $req_body | to json -r } else { $req_body }) } else { $req_body }
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
export def "reviews-add-video-transcript-moderation-result" [
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
  --content-type: string # The content type. (required)
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_name | is-empty) { error make --unspanned { msg: "path parameter 'teamName' must be non-empty" } }
  if ($review_id | is-empty) { error make --unspanned { msg: "path parameter 'reviewId' must be non-empty" } }
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}/transcriptmoderationresult") $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else if ($effective_ct =~ '\+json\s*(;|$)') { (if (($req_body | describe) =~ '^(record|list|table)') { $req_body | to json -r } else { $req_body }) } else { $req_body }
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
