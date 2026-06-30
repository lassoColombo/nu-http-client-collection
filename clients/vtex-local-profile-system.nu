# Auto-generated client for Profile System v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Profile-System/1.0/openapi.json
# Auth: --token flag or $env.PROFILE_SYSTEM_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o PROFILE_SYSTEM_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-vtex-api-appkey" => { {scheme: $scheme, headers: {X-VTEX-API-AppKey: $token_val}, query: "", location: "header"} }
    "x-vtex-api-apptoken" => { {scheme: $scheme, headers: {X-VTEX-API-AppToken: $token_val}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| $acc | merge $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "storage-profile-system-profiles create-client" } } | get name | first)
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

# Create client profile
#
# POST /api/storage/profile-system/profiles
# operationId: CreateClientProfile
export def "storage-profile-system-profiles create-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ttl: int # This parameter sets the the Time To Live (TTL), in days, of the specific document being created or updated with this request. After this period of time from the moment of the request, the document is deleted. By sending this parameter you override the TTL set for the schema. > Currently, the available default document schemas have no TTL. This means that documents are stored indefinitely, unless a TTL is sent when creating or updating. (e.g. 365)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --birth-date: string # Client's birth date in ISO 8601 format. (e.g. 1925-11-17)
  document: string # Client's document. (e.g. 12345678900)
  document_type: string # Type of document informed in `document`. (e.g. CPF)
  email: string # Client's email address. (e.g. john.doe@example.com)
  first_name: string # Client's first name. (e.g. John)
  last_name: string # Client's last name. (e.g. Doe)
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ttl" $ttl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/storage/profile-system/profiles" $qp $auth.query)
  let req_body = {"birthDate": $birth_date, "document": $document, "documentType": $document_type, "email": $email, "firstName": $first_name, "lastName": $last_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: ({"ttl": $ttl} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Create or update profile schema
#
# PUT /api/storage/profile-system/profiles/schema
# operationId: CreateOrUpdateProfileSchema
# --properties shape: {{fieldName}?: record}
export def "storage-profile-system-profiles-schema create-or-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  description: string # Schema's human readable description. (e.g. This schema describes a b2c customer profile.)
  --document-ttl: int # Document time to live, in days. After this many days from its creation or update, any document cerated from this schema will be deleted. (e.g. 1825)
  properties: record # Object describing each field in your desired schema. In this object, each property is a new object, describing the field according to: `type` (string); `sensitive` (boolean); `pii` (boolean) and; `items.type` (if field is array). — shape: {{fieldName}?: record}
  required: list<string> # Schema required fields. (e.g. [firstName, lastName, email, document, documentType])
  title: string # Schema title. (e.g. Client profile schema)
  type: string # Schema type. (e.g. object)
  --v-indexed: list # e.g. [email, document]
  --v-unique: list # e.g. [email, document]
  --version: int # Schema version. (e.g. 1)
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/storage/profile-system/profiles/schema" $auth.query)
  let req_body = {"description": $description, "documentTTL": $document_ttl, "properties": $properties, "required": $required, "title": $title, "type": $type, "v-indexed": $v_indexed, "v-unique": $v_unique, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Delete client profile
#
# DELETE /api/storage/profile-system/profiles/{profileId}
# operationId: DeleteClientProfile
export def "storage-profile-system-profiles delete-client" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Get profile
#
# GET /api/storage/profile-system/profiles/{profileId}
# operationId: GetProfile
export def "storage-profile-system-profiles get" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<any> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  let qp = [(serialize-qp "alternativeKey" $alternative_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"alternativeKey": $alternative_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates client profile
#
# PATCH /api/storage/profile-system/profiles/{profileId}
# operationId: UpdateClientProfile
export def "storage-profile-system-profiles update-client" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --ttl: int # This parameter sets the the Time To Live (TTL), in days, of the specific document being created or updated with this request. After this period of time from the moment of the request, the document is deleted. By sending this parameter you override the TTL set for the schema. > Currently, the available default document schemas have no TTL. This means that documents are stored indefinitely, unless a TTL is sent when creating or updating. (e.g. 365)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --birth-date: string # Client's birth date in ISO 8601 format. (e.g. 1925-11-17)
  --document: string # Client's document. (e.g. 12345678900)
  --document-type: string # Type of document informed in `document`. (e.g. CPF)
  --email: string # Client's email address. (e.g. john.doe@example.com)
  --first-name: string # Client's first name. (e.g. John)
  --last-name: string # Client's last name. (e.g. Doe)
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  let qp = [(serialize-qp "alternativeKey" $alternative_key "scalar") (serialize-qp "ttl" $ttl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}") $qp $auth.query)
  let req_body = {"birthDate": $birth_date, "document": $document, "documentType": $document_type, "email": $email, "firstName": $first_name, "lastName": $last_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "patch"
    url: $full_url
    query: ({"alternativeKey": $alternative_key, "ttl": $ttl} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Get client addresses
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses
# operationId: GetClientAddresses
export def "storage-profile-system-profiles-addresses get-client" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<any> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  let qp = [(serialize-qp "alternativeKey" $alternative_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}/addresses") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"alternativeKey": $alternative_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create client address
#
# POST /api/storage/profile-system/profiles/{profileId}/addresses
# operationId: CreateClientAddress
export def "storage-profile-system-profiles-addresses create-client-address" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  administrative_area_level1: string # Name of administrative area, such as the state or province. (e.g. RJ)
  --country-code: string # Two letter country code. (e.g. BR)
  country_name: string # Name of the address country. (e.g. Brasil)
  locality: string # Name of address locality, such as the city. (e.g. Locality)
  locality_area_level1: string # Name of the address locality area, such as the neighborhood or district. (e.g. Locality area)
  postal_code: string # Address postal code. (e.g. 20200-000)
  route: string # Address route or street name. (e.g. 51)
  street_number: string # Address street number. (e.g. 999)
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  let qp = [(serialize-qp "alternativeKey" $alternative_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}/addresses") $qp $auth.query)
  let req_body = {"administrativeAreaLevel1": $administrative_area_level1, "countryCode": $country_code, "countryName": $country_name, "locality": $locality, "localityAreaLevel1": $locality_area_level1, "postalCode": $postal_code, "route": $route, "streetNumber": $street_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: ({"alternativeKey": $alternative_key} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Get unmasked client addresses
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses/unmask
# operationId: GetUnmaskedClientAddresses
export def "storage-profile-system-profiles-addresses-unmask get-unmasked-client" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<record> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  let qp = [(serialize-qp "alternativeKey" $alternative_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}/addresses/unmask") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"alternativeKey": $alternative_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete address
#
# DELETE /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}
# operationId: DeleteAddress
export def "storage-profile-system-profiles-addresses delete-address" [
  profile_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  let qp = [(serialize-qp "alternativeKey" $alternative_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id), address_id: (encode-path-segment $address_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}/addresses/{address_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"alternativeKey": $alternative_key} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get address
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}
# operationId: GetAddress
export def "storage-profile-system-profiles-addresses get-address" [
  profile_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  let qp = [(serialize-qp "alternativeKey" $alternative_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id), address_id: (encode-path-segment $address_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}/addresses/{address_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"alternativeKey": $alternative_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update client address
#
# PATCH /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}
# operationId: UpdateClientAddress
export def "storage-profile-system-profiles-addresses update-client-address" [
  profile_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --administrative-area-level1: string # Name of administrative area, such as the state or province. (e.g. RJ)
  --country-code: string # Two letter country code. (e.g. BR)
  --country-name: string # Name of the address country. (e.g. Brasil)
  --locality: string # Name of address locality, such as the city. (e.g. Locality)
  --locality-area-level1: string # Name of the address locality area, such as the neighborhood or district. (e.g. Locality area)
  --postal-code: string # Address postal code. (e.g. 20200-000)
  --route: string # Name of the address country. (e.g. Brasil)
  --street-number: string # Name of the address country. (e.g. Brasil)
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  let qp = [(serialize-qp "alternativeKey" $alternative_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id), address_id: (encode-path-segment $address_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}/addresses/{address_id}") $qp $auth.query)
  let req_body = {"administrativeAreaLevel1": $administrative_area_level1, "countryCode": $country_code, "countryName": $country_name, "locality": $locality, "localityAreaLevel1": $locality_area_level1, "postalCode": $postal_code, "route": $route, "streetNumber": $street_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "patch"
    url: $full_url
    query: ({"alternativeKey": $alternative_key} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Get unmasked address
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}/unmask
# operationId: GetUnmaskedAddress
export def "storage-profile-system-profiles-addresses-unmask get-unmasked-address" [
  profile_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for requesting unmasked data. (e.g. data-validation)
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  let qp = [(serialize-qp "reason" $reason "scalar") (serialize-qp "alternativeKey" $alternative_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id), address_id: (encode-path-segment $address_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}/addresses/{address_id}/unmask") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"reason": $reason, "alternativeKey": $alternative_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get address by version
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}/versions/{addressVersionId}
# operationId: GetAddressByVersion
export def "storage-profile-system-profiles-addresses-versions get-address" [
  profile_id: string
  address_id: string
  address_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for requesting unmasked data. (e.g. data-validation)
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  if ($address_version_id | is-empty) { error make --unspanned { msg: "path parameter 'addressVersionId' must be non-empty" } }
  let qp = [(serialize-qp "reason" $reason "scalar") (serialize-qp "alternativeKey" $alternative_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id), address_id: (encode-path-segment $address_id), address_version_id: (encode-path-segment $address_version_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}/addresses/{address_id}/versions/{address_version_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"reason": $reason, "alternativeKey": $alternative_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get unmasked address by version
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}/versions/{addressVersionId}/unmask
# operationId: GetUnmaskedAddressByVersion
export def "storage-profile-system-profiles-addresses-versions-unmask get-unmasked-address" [
  profile_id: string
  address_id: string
  address_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for requesting unmasked data. (e.g. data-validation)
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  if ($address_version_id | is-empty) { error make --unspanned { msg: "path parameter 'addressVersionId' must be non-empty" } }
  let qp = [(serialize-qp "reason" $reason "scalar") (serialize-qp "alternativeKey" $alternative_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id), address_id: (encode-path-segment $address_id), address_version_id: (encode-path-segment $address_version_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}/addresses/{address_id}/versions/{address_version_id}/unmask") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"reason": $reason, "alternativeKey": $alternative_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete purchase information
#
# DELETE /api/storage/profile-system/profiles/{profileId}/purchase-info
# operationId: DeletePurchaseInformation
export def "storage-profile-system-profiles-purchase-info delete-information" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  let qp = [(serialize-qp "alternativeKey" $alternative_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}/purchase-info") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"alternativeKey": $alternative_key} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get purchase information
#
# GET /api/storage/profile-system/profiles/{profileId}/purchase-info
# operationId: GetPurchaseInformation
export def "storage-profile-system-profiles-purchase-info get-information" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<any> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  let qp = [(serialize-qp "alternativeKey" $alternative_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}/purchase-info") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"alternativeKey": $alternative_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update purchase information
#
# PATCH /api/storage/profile-system/profiles/{profileId}/purchase-info
# operationId: UpdatePurchaseInformation
export def "storage-profile-system-profiles-purchase-info update-information" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: record
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  let qp = [(serialize-qp "alternativeKey" $alternative_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}/purchase-info") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "patch"
    url: $full_url
    query: ({"alternativeKey": $alternative_key} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Create purchase information
#
# POST /api/storage/profile-system/profiles/{profileId}/purchase-info
# operationId: CreatePurchaseInformation
export def "storage-profile-system-profiles-purchase-info create-information" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: record
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  let qp = [(serialize-qp "alternativeKey" $alternative_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}/purchase-info") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: ({"alternativeKey": $alternative_key} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Get unmasked purchase information
#
# GET /api/storage/profile-system/profiles/{profileId}/purchase-info/unmask
# operationId: GetUnmaskedPurchaseInformation
export def "storage-profile-system-profiles-purchase-info-unmask get-unmasked-information" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<record> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}/purchase-info/unmask") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Get unmasked profile
#
# GET /api/storage/profile-system/profiles/{profileId}/unmask
# operationId: GetUnmaskedProfile
export def "storage-profile-system-profiles-unmask get-unmasked" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for requesting unmasked data. (e.g. data-validation)
  --alternative-key: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`. > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<any> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  let qp = [(serialize-qp "reason" $reason "scalar") (serialize-qp "alternativeKey" $alternative_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}/unmask") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"reason": $reason, "alternativeKey": $alternative_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get profile by version
#
# GET /api/storage/profile-system/profiles/{profileId}/versions/{profileVersionId}
# operationId: GetProfileByVersion
export def "storage-profile-system-profiles-versions get" [
  profile_id: string
  profile_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<any> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  if ($profile_version_id | is-empty) { error make --unspanned { msg: "path parameter 'profileVersionId' must be non-empty" } }
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id), profile_version_id: (encode-path-segment $profile_version_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}/versions/{profile_version_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Get unmasked profile by version
#
# GET /api/storage/profile-system/profiles/{profileId}/versions/{profileVersionId}/unmask
# operationId: GetUnmaskedProfileByVersion
export def "storage-profile-system-profiles-versions-unmask get-unmasked" [
  profile_id: string
  profile_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for requesting unmasked data. (e.g. data-validation)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<any> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  if ($profile_version_id | is-empty) { error make --unspanned { msg: "path parameter 'profileVersionId' must be non-empty" } }
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id), profile_version_id: (encode-path-segment $profile_version_id)} | format pattern "/api/storage/profile-system/profiles/{profile_id}/versions/{profile_version_id}/unmask") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"reason": $reason} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create prospect
#
# POST /api/storage/profile-system/prospects
# operationId: CreateProspect
export def "storage-profile-system-prospects create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: record
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/storage/profile-system/prospects" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Delete prospect
#
# DELETE /api/storage/profile-system/prospects/{prospectId}
# operationId: DeleteProspect
export def "storage-profile-system-prospects delete" [
  prospect_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($prospect_id | is-empty) { error make --unspanned { msg: "path parameter 'prospectId' must be non-empty" } }
  let full_url = (build-url $base ({prospect_id: (encode-path-segment $prospect_id)} | format pattern "/api/storage/profile-system/prospects/{prospect_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Get prospect
#
# GET /api/storage/profile-system/prospects/{prospectId}
# operationId: GetProspect
export def "storage-profile-system-prospects get" [
  prospect_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<any> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($prospect_id | is-empty) { error make --unspanned { msg: "path parameter 'prospectId' must be non-empty" } }
  let full_url = (build-url $base ({prospect_id: (encode-path-segment $prospect_id)} | format pattern "/api/storage/profile-system/prospects/{prospect_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Update prospect
#
# PATCH /api/storage/profile-system/prospects/{prospectId}
# operationId: UpdateProspect
export def "storage-profile-system-prospects update" [
  prospect_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: record
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($prospect_id | is-empty) { error make --unspanned { msg: "path parameter 'prospectId' must be non-empty" } }
  let full_url = (build-url $base ({prospect_id: (encode-path-segment $prospect_id)} | format pattern "/api/storage/profile-system/prospects/{prospect_id}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Get unmasked prospect
#
# GET /api/storage/profile-system/prospects/{prospectId}/unmask
# operationId: GetUnmaskedProspect
export def "storage-profile-system-prospects-unmask get-unmasked" [
  prospect_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for requesting unmasked data. (e.g. data-validation)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<any> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o PROFILE_SYSTEM_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o PROFILE_SYSTEM_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($prospect_id | is-empty) { error make --unspanned { msg: "path parameter 'prospectId' must be non-empty" } }
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({prospect_id: (encode-path-segment $prospect_id)} | format pattern "/api/storage/profile-system/prospects/{prospect_id}/unmask") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"reason": $reason} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
