# Auto-generated client for Content Moderator Client v1.0
# Source: https://api.apis.guru/v2/specs/azure.com/cognitiveservices-ContentModerator/1.0/swagger.json
# Auth: --token flag or $env.CONTENT_MODERATOR_CLIENT_TOKEN

const BASE_URL = "https://azure.local"
const DEFAULT_AUTH = "ocp-apim-subscription-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CONTENT_MODERATOR_CLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "ocp-apim-subscription-key" => { {headers: {Ocp-Apim-Subscription-Key: $token_val}, query: ""} }
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

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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

def base-url-completer [] { ["https://azure.local"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key"] }

# Completers for enum parameters
def content-type-completer [] { ["text/html" "text/markdown" "text/plain" "text/xml"] }
def content-type-completer-1 [] { ["Image" "Text" "Video"] }
def content-type-completer-2 [] { ["application/json" "image/jpeg"] }
def accept-completer [] { ["application/json" "text/json"] }
def content-type-completer-3 [] { ["text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Description: string, Id: int, Metadata: record, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contentmoderator/lists/v1.0/imagelists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The content type.
]: nothing -> record<Description: string, Id: int, Metadata: record, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contentmoderator/lists/v1.0/imagelists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Description: string, Id: int, Metadata: record, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The content type.
]: nothing -> record<Description: string, Id: int, Metadata: record, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<AdvancedInfo: list<record>, ContentSourceId: string, IsUpdateSuccess: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}/RefreshIndex"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}/images"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ContentIds: list<int>, ContentSource: string, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}/images"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: int # Tag for the image.
  --label: string # The image label.
]: nothing -> record<AdditionalInfo: table<Key: string, Value: string>, ContentId: string, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "label" $label "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}/images") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id), image_id: (encode-path-segment $image_id)} | format pattern "/contentmoderator/lists/v1.0/imagelists/{list_id}/images/{image_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Description: string, Id: int, Metadata: record, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contentmoderator/lists/v1.0/termlists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The content type.
]: nothing -> record<Description: string, Id: int, Metadata: record, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contentmoderator/lists/v1.0/termlists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Description: string, Id: int, Metadata: record, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The content type.
]: nothing -> record<Description: string, Id: int, Metadata: record, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms.
]: nothing -> record<AdvancedInfo: list<record>, ContentSourceId: string, IsUpdateSuccess: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}/RefreshIndex") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms.
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}/terms") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms.
  --offset: int # The pagination start index.
  --limit: int # The max limit.
]: nothing -> record<Data: record<Language: string, Status: record<Code: int, Description: string, Exception: string>, Terms: list<record>, TrackingId: string>, Paging: record<Limit: int, Offset: int, Returned: int, Total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}/terms") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms.
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id), term: (encode-path-segment $term)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}/terms/{term}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms.
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id), term: (encode-path-segment $term)} | format pattern "/contentmoderator/lists/v1.0/termlists/{list_id}/terms/{term}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-image: oneof<nothing, bool> # Whether to retain the submitted image for future use; defaults to false if omitted.
]: nothing -> record<AdultClassificationScore: float, AdvancedInfo: table<Key: string, Value: string>, CacheID: string, IsImageAdultClassified: bool, IsImageRacyClassified: bool, RacyClassificationScore: float, Result: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "CacheImage" $cache_image "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessImage/Evaluate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-image: oneof<nothing, bool> # Whether to retain the submitted image for future use; defaults to false if omitted.
]: nothing -> record<AdvancedInfo: table<Key: string, Value: string>, CacheId: string, Count: int, Faces: table<Bottom: int, Left: int, Right: int, Top: int>, Result: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "CacheImage" $cache_image "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessImage/FindFaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --list-id: string # The list Id.
  --cache-image: oneof<nothing, bool> # Whether to retain the submitted image for future use; defaults to false if omitted.
]: nothing -> record<CacheID: string, IsMatch: bool, Matches: table<Label: string, MatchId: int, Score: float, Source: string, Tags: list>, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listId" $list_id "scalar") (serialize-qp "CacheImage" $cache_image "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessImage/Match" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms.
  --cache-image: oneof<nothing, bool> # Whether to retain the submitted image for future use; defaults to false if omitted.
  --enhanced: oneof<nothing, bool> # When set to True, the image goes through additional processing to come with additional candidates. image/tiff is not supported when enhanced is set to true Note: This impacts the response time. (default: false)
]: nothing -> record<CacheId: string, Candidates: table<Confidence: float, Text: string>, Language: string, Metadata: table<Key: string, Value: string>, Status: record<Code: int, Description: string, Exception: string>, Text: string, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "CacheImage" $cache_image "scalar") (serialize-qp "enhanced" $enhanced "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessImage/OCR" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer # The content type.
]: nothing -> record<DetectedLanguage: string, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessText/DetectLanguage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the text.
  --autocorrect: oneof<nothing, bool> # Autocorrect text. (default: false)
  --pii: oneof<nothing, bool> # Detect personal identifiable information. (default: false)
  --list-id: string # The list Id.
  --classify: oneof<nothing, bool> # Classify input. (default: false)
  --content-type: string@content-type-completer # The content type.
]: nothing -> record<AutoCorrectedText: string, Classification: record<Category1: record<Score: float>, Category2: record<Score: float>, Category3: record<Score: float>, ReviewRecommended: bool>, Language: string, Misrepresentation: list<string>, NormalizedText: string, OriginalText: string, PII: record<Address: list<record>, Email: list<record>, IPA: list<record>, Phone: list<record>, SSN: list<record>>, Status: record<Code: int, Description: string, Exception: string>, Terms: table<Index: int, ListId: int, OriginalIndex: int, Term: string>, TrackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "autocorrect" $autocorrect "scalar") (serialize-qp "PII" $pii "scalar") (serialize-qp "listId" $list_id "scalar") (serialize-qp "classify" $classify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contentmoderator/moderate/v1.0/ProcessText/Screen/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string@content-type-completer-1 # Image, Text or Video.
  --content-id: string # Id/Name to identify the content submitted.
  --workflow-name: string # Workflow Name that you want to invoke.
  --call-back-endpoint: string # Callback endpoint for posting the create job result.
  --content-type: string@content-type-completer-2 # The content type.
  content_value: string # Content to evaluate for a job.
]: any -> record<JobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ContentType" $content_type "scalar") (serialize-qp "ContentId" $content_id "scalar") (serialize-qp "WorkflowName" $workflow_name "scalar") (serialize-qp "CallBackEndpoint" $call_back_endpoint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/jobs") $qp)
  let req_body = {"ContentValue": $content_value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&" } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $effective_ct $req_body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<CallBackEndpoint: string, Id: string, JobExecutionReport: table<Msg: string, Ts: string>, ResultMetaData: table<Key: string, Value: string>, ReviewId: string, Status: string, TeamName: string, Type: string, WorkflowId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), job_id: (encode-path-segment $job_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/jobs/{job_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --sub-team: string # SubTeam of your team, you want to assign the created review to.
  --url-content-type: string # The content type.
  --body: record
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subTeam" $sub_team "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"UrlContentType": $url_content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<CallbackEndpoint: string, Content: string, ContentId: string, CreatedBy: string, Metadata: table<Key: string, Value: string>, ReviewId: string, ReviewerResultTags: table<Key: string, Value: string>, Status: string, SubTeam: string, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-seed: int # Time stamp of the frame from where you want to start fetching the frames.
  --no-of-records: int # Number of frames to fetch.
  --filter: string # Get frames filtered by tags.
]: nothing -> record<ReviewId: string, VideoFrames: table<FrameImage: string, Metadata: list, ReviewerResultTags: list, Timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startSeed" $start_seed "scalar") (serialize-qp "noOfRecords" $no_of_records "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}/frames") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --timescale: int # Timescale of the video you are adding frames to.
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timescale" $timescale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}/frames") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}/publish"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer-3 # The content type.
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}/transcript"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The content type.
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team_name: (encode-path-segment $team_name), review_id: (encode-path-segment $review_id)} | format pattern "/contentmoderator/review/v1.0/teams/{team_name}/reviews/{review_id}/transcriptmoderationresult"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
