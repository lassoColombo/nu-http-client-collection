# Auto-generated client for Custom Vision Training Client v3.2
# Source: https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-Training/3.2/openapi.json
# Auth: --token flag or $env.CUSTOM_VISION_TRAINING_CLIENT_TOKEN

const BASE_URL = "https://southcentralus.api.cognitive.microsoft.com/customvision/v3.2/training"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CUSTOM_VISION_TRAINING_CLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "training-key" => { {scheme: $scheme, headers: {Training-Key: $token_val}, query: "", location: "header"} }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://southcentralus.api.cognitive.microsoft.com/customvision/v3.2/training" "none/customvision/v3.2/training"] }
def auth-scheme-completer [] { ["training-key"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/xml"] }
def classification-type-completer [] { ["Multiclass" "Multilabel"] }
def status-completer [] { ["Failed" "Importing" "Succeeded"] }
def sort-by-completer [] { ["UncertaintyAscending" "UncertaintyDescending"] }
def order-by-completer [] { ["Newest" "Oldest"] }
def platform-completer [] { ["CoreML" "DockerFile" "ONNX" "TensorFlow" "VAIDK"] }
def flavor-completer [] { ["ARM" "Linux" "ONNX10" "ONNX12" "TensorFlowLite" "TensorFlowNormal" "Windows"] }
def order-by-completer-1 [] { ["Newest" "Oldest" "Suggested"] }
def type-completer [] { ["Negative" "Regular"] }
def training-type-completer [] { ["Advanced" "Regular"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "domains list" } } | get name | first)
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

# Get a list of the available domains.
#
# GET /domains
# operationId: GetDomains
export def "domains list" [
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
]: nothing -> table<enabled: bool, exportable: bool, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domains")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get information about a specific domain.
#
# GET /domains/{domainId}
# operationId: GetDomain
export def "domains get" [
  domain_id: string
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
]: nothing -> record<enabled: bool, exportable: bool, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_id | is-empty) { error make --unspanned { msg: "path parameter 'domainId' must be non-empty" } }
  let full_url = (build-url $base ({domain_id: (encode-path-segment $domain_id)} | format pattern "/domains/{domain_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get your projects.
#
# GET /projects
# operationId: GetProjects
export def "projects list" [
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
]: nothing -> table<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record, targetExportPlatforms: list, useNegativeSet: bool>, status: string, thumbnailUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a project.
#
# POST /projects
# operationId: CreateProject
export def "projects create" [
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
  --name: string # Name of the project.
  --description: string # The description of the project.
  --domain-id: string # The id of the domain to use for this project. Defaults to General. (format: uuid)
  --classification-type: string@classification-type-completer # The type of classifier to create for this project.
  --target-export-platforms: list<string> # List of platforms the trained model is intending exporting to.
]: nothing -> record<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record<augmentationMethods: record>, targetExportPlatforms: list<string>, useNegativeSet: bool>, status: string, thumbnailUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "domainId" $domain_id "scalar") (serialize-qp "classificationType" $classification_type "scalar") (serialize-qp "targetExportPlatforms" $target_export_platforms "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "description": $description, "domainId": $domain_id, "classificationType": $classification_type, "targetExportPlatforms": $target_export_platforms} | compact), body: null}
}

# Imports a project.
#
# POST /projects/import
# operationId: ImportProject
export def "projects-import import" [
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
  --qp-token: string # Token generated from the export project call.
]: nothing -> record<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record<augmentationMethods: record>, targetExportPlatforms: list<string>, useNegativeSet: bool>, status: string, thumbnailUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects/import" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"token": $qp_token} | compact), body: null}
}

# Delete a specific project.
#
# DELETE /projects/{projectId}
# operationId: DeleteProject
export def "projects delete" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific project.
#
# GET /projects/{projectId}
# operationId: GetProject
export def "projects get" [
  project_id: string
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
]: nothing -> record<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record<augmentationMethods: record>, targetExportPlatforms: list<string>, useNegativeSet: bool>, status: string, thumbnailUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a specific project.
#
# PATCH /projects/{projectId}
# operationId: UpdateProject
# --settings shape: {classificationType?: "Multiclass"|"Multilabel", domainId?: string, imageProcessingSettings?: record, targetExportPlatforms?: list<string>}
export def "projects update" [
  project_id: string
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
  --description: string # Gets or sets the description of the project. (nullable)
  name: string # Gets or sets the name of the project.
  settings: record # Represents settings associated with a project. — shape: {classificationType?: "Multiclass"|"Multilabel", domainId?: string, imageProcessingSettings?: record, targetExportPlatforms?: list<string>}
  --status: string@status-completer # Gets the status of the project.
]: any -> record<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record<augmentationMethods: record>, targetExportPlatforms: list<string>, useNegativeSet: bool>, status: string, thumbnailUri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}"))
  let req_body = {"description": $description, "name": $name, "settings": $settings, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Exports a project.
#
# GET /projects/{projectId}/export
# operationId: ExportProject
export def "projects-export export" [
  project_id: string
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
]: nothing -> record<estimatedImportTimeInMS: int, imageCount: int, iterationCount: int, regionCount: int, tagCount: int, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/export"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete images from the set of training images.
#
# DELETE /projects/{projectId}/images
# operationId: DeleteImages
export def "projects-images delete" [
  project_id: string
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
  --image-ids: list<string> # Ids of the images to be deleted. Limited to 256 images per batch.
  --all-images: oneof<nothing, bool> # Flag to specify delete all images, specify this flag or a list of images. Using this flag will return a 202 response to indicate the images are being deleted.
  --all-iterations: oneof<nothing, bool> # Removes these images from all iterations, not just the current workspace. Using this flag will return a 202 response to indicate the images are being deleted.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "imageIds" $image_ids "csv") (serialize-qp "allImages" $all_images "scalar") (serialize-qp "allIterations" $all_iterations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/images") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"imageIds": $image_ids, "allImages": $all_images, "allIterations": $all_iterations} | compact), body: null}
}

# Add the provided images to the set of training images.
#
# POST /projects/{projectId}/images
# operationId: CreateImagesFromData
export def "projects-images create-from-data" [
  project_id: string
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
  --tag-ids: list<string> # The tags ids with which to tag each image. Limited to 20.
  image_data: string # Binary image data. Supported formats are JPEG, GIF, PNG, and BMP. Supports images up to 6MB. (format: binary)
]: any -> record<images: table<image: record, sourceUrl: string, status: string>, isBatchSuccessful: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "tagIds" $tag_ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/images") $qp)
  let req_body = {"imageData": $image_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageData"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: ({"tagIds": $tag_ids} | compact), body: $req_body}
}

# Add the provided batch of images to the set of training images.
#
# POST /projects/{projectId}/images/files
# operationId: CreateImagesFromFiles
# --images item shape: {contents?: string, name?: string, regions?: list, tagIds?: list<string>}
export def "projects-images-files create" [
  project_id: string
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
  --images: list # item shape: {contents?: string, name?: string, regions?: list, tagIds?: list<string>}
  --tag-ids: list<string>
]: any -> record<images: table<image: record, sourceUrl: string, status: string>, isBatchSuccessful: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/images/files"))
  let req_body = {"images": $images, "tagIds": $tag_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get images by id for a given project iteration.
#
# GET /projects/{projectId}/images/id
# operationId: GetImagesByIds
export def "projects-images-id get" [
  project_id: string
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
  --image-ids: list<string> # The list of image ids to retrieve. Limited to 256.
  --iteration-id: string # The iteration id. Defaults to workspace. (format: uuid)
]: nothing -> table<created: string, height: int, id: string, originalImageUri: string, regions: list<record>, resizedImageUri: string, tags: list<record>, thumbnailUri: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "imageIds" $image_ids "csv") (serialize-qp "iterationId" $iteration_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/images/id") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"imageIds": $image_ids, "iterationId": $iteration_id} | compact), body: null}
}

# Add the specified predicted images to the set of training images.
#
# POST /projects/{projectId}/images/predictions
# operationId: CreateImagesFromPredictions
# --images item shape: {id?: string, regions?: list, tagIds?: list<string>}
export def "projects-images-predictions create" [
  project_id: string
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
  --images: list # item shape: {id?: string, regions?: list, tagIds?: list<string>}
  --tag-ids: list<string>
]: any -> record<images: table<image: record, sourceUrl: string, status: string>, isBatchSuccessful: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/images/predictions"))
  let req_body = {"images": $images, "tagIds": $tag_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a set of image regions.
#
# DELETE /projects/{projectId}/images/regions
# operationId: DeleteImageRegions
export def "projects-images-regions delete" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --region-ids: list<string> # Regions to delete. Limited to 64.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "regionIds" $region_ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/images/regions") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"regionIds": $region_ids} | compact), body: null}
}

# Create a set of image regions.
#
# POST /projects/{projectId}/images/regions
# operationId: CreateImageRegions
# --regions item shape: {height: float, imageId: string, left: float, tagId: string, top: float, width: float}
export def "projects-images-regions create" [
  project_id: string
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
  --regions: list # item shape: {height: float, imageId: string, left: float, tagId: string, top: float, width: float}
]: any -> record<created: table<created: string, height: float, imageId: string, left: float, regionId: string, tagId: string, tagName: string, top: float, width: float>, duplicated: table<height: float, imageId: string, left: float, tagId: string, top: float, width: float>, exceeded: table<height: float, imageId: string, left: float, tagId: string, top: float, width: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/images/regions"))
  let req_body = {"regions": $regions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get untagged images whose suggested tags match given tags. Returns empty array if no images are found.
#
# POST /projects/{projectId}/images/suggested
# operationId: QuerySuggestedImages
export def "projects-images-suggested list" [
  project_id: string
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
  --iteration-id: string # IterationId to use for the suggested tags and regions. (format: uuid)
  --continuation: string # Continuation Id for database pagination. Initially null but later used to paginate.
  --max-count: int # Maximum number of results you want to be returned in the response. (format: int32)
  --session: string # SessionId for database query. Initially set to null but later used to paginate.
  --sort-by: string@sort-by-completer # OrderBy. Ordering mechanism for your results.
  --tag-ids: list<string> # Existing TagIds in project to filter suggested tags on.
  --threshold: float # Confidence threshold to filter suggested tags on. (format: double)
]: any -> record<results: table<created: string, domain: string, height: int, id: string, iteration: string, originalImageUri: string, predictionUncertainty: float, predictions: list, project: string, resizedImageUri: string, thumbnailUri: string, width: int>, token: record<continuation: string, maxCount: int, session: string, sortBy: string, tagIds: list<string>, threshold: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "iterationId" $iteration_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/images/suggested") $qp)
  let req_body = {"continuation": $continuation, "maxCount": $max_count, "session": $session, "sortBy": $sort_by, "tagIds": $tag_ids, "threshold": $threshold} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"iterationId": $iteration_id} | compact), body: $req_body}
}

# Get count of images whose suggested tags match given tags and their probabilities are greater than or equal to the given threshold. Returns count as 0 if none found.
#
# POST /projects/{projectId}/images/suggested/count
# operationId: QuerySuggestedImageCount
export def "projects-images-suggested-count list" [
  project_id: string
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
  --iteration-id: string # IterationId to use for the suggested tags and regions. (format: uuid)
  --tag-ids: list<string> # Existing TagIds in project to get suggested tags count for.
  --threshold: float # Confidence threshold to filter suggested tags on. (format: double)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "iterationId" $iteration_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/images/suggested/count") $qp)
  let req_body = {"tagIds": $tag_ids, "threshold": $threshold} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"iterationId": $iteration_id} | compact), body: $req_body}
}

# Get tagged images for a given project iteration.
#
# GET /projects/{projectId}/images/tagged
# operationId: GetTaggedImages
export def "projects-images-tagged get" [
  project_id: string
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
  --iteration-id: string # The iteration id. Defaults to workspace. (format: uuid)
  --tag-ids: list<string> # A list of tags ids to filter the images. Defaults to all tagged images when null. Limited to 20.
  --order-by: string@order-by-completer # The ordering. Defaults to newest.
  --take: int # Maximum number of images to return. Defaults to 50, limited to 256. (format: int32, default: 50)
  --skip: int # Number of images to skip before beginning the image batch. Defaults to 0. (format: int32, default: 0)
]: nothing -> table<created: string, height: int, id: string, originalImageUri: string, regions: list<record>, resizedImageUri: string, tags: list<record>, thumbnailUri: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "iterationId" $iteration_id "scalar") (serialize-qp "tagIds" $tag_ids "csv") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/images/tagged") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"iterationId": $iteration_id, "tagIds": $tag_ids, "orderBy": $order_by, "take": $take, "skip": $skip} | compact), body: null}
}

# Gets the number of images tagged with the provided {tagIds}.
#
# GET /projects/{projectId}/images/tagged/count
# operationId: GetTaggedImageCount
export def "projects-images-tagged-count get" [
  project_id: string
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
  --iteration-id: string # The iteration id. Defaults to workspace. (format: uuid)
  --tag-ids: list<string> # A list of tags ids to filter the images to count. Defaults to all tags when null.
]: nothing -> oneof<int, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "iterationId" $iteration_id "scalar") (serialize-qp "tagIds" $tag_ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/images/tagged/count") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"iterationId": $iteration_id, "tagIds": $tag_ids} | compact), body: null}
}

# Remove a set of tags from a set of images.
#
# DELETE /projects/{projectId}/images/tags
# operationId: DeleteImageTags
export def "projects-images-tags delete" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-ids: list<string> # Image ids. Limited to 64 images.
  --tag-ids: list<string> # Tags to be deleted from the specified images. Limited to 20 tags.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "imageIds" $image_ids "csv") (serialize-qp "tagIds" $tag_ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/images/tags") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"imageIds": $image_ids, "tagIds": $tag_ids} | compact), body: null}
}

# Associate a set of images with a set of tags.
#
# POST /projects/{projectId}/images/tags
# operationId: CreateImageTags
# --tags item shape: {imageId?: string, tagId?: string}
export def "projects-images-tags create" [
  project_id: string
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
  --tags: list # Image Tag entries to include in this batch. — item shape: {imageId?: string, tagId?: string}
]: any -> record<created: table<imageId: string, tagId: string>, duplicated: table<imageId: string, tagId: string>, exceeded: table<imageId: string, tagId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/images/tags"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get untagged images for a given project iteration.
#
# GET /projects/{projectId}/images/untagged
# operationId: GetUntaggedImages
export def "projects-images-untagged get" [
  project_id: string
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
  --iteration-id: string # The iteration id. Defaults to workspace. (format: uuid)
  --order-by: string@order-by-completer # The ordering. Defaults to newest.
  --take: int # Maximum number of images to return. Defaults to 50, limited to 256. (format: int32, default: 50)
  --skip: int # Number of images to skip before beginning the image batch. Defaults to 0. (format: int32, default: 0)
]: nothing -> table<created: string, height: int, id: string, originalImageUri: string, regions: list<record>, resizedImageUri: string, tags: list<record>, thumbnailUri: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "iterationId" $iteration_id "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/images/untagged") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"iterationId": $iteration_id, "orderBy": $order_by, "take": $take, "skip": $skip} | compact), body: null}
}

# Gets the number of untagged images.
#
# GET /projects/{projectId}/images/untagged/count
# operationId: GetUntaggedImageCount
export def "projects-images-untagged-count get" [
  project_id: string
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
  --iteration-id: string # The iteration id. Defaults to workspace. (format: uuid)
]: nothing -> oneof<int, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "iterationId" $iteration_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/images/untagged/count") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"iterationId": $iteration_id} | compact), body: null}
}

# Add the provided images urls to the set of training images.
#
# POST /projects/{projectId}/images/urls
# operationId: CreateImagesFromUrls
# --images item shape: {regions?: list, tagIds?: list<string>, url: string}
export def "projects-images-urls create" [
  project_id: string
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
  --images: list # item shape: {regions?: list, tagIds?: list<string>, url: string}
  --tag-ids: list<string>
]: any -> record<images: table<image: record, sourceUrl: string, status: string>, isBatchSuccessful: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/images/urls"))
  let req_body = {"images": $images, "tagIds": $tag_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get region proposals for an image. Returns empty array if no proposals are found.
#
# POST /projects/{projectId}/images/{imageId}/regionproposals
# operationId: GetImageRegionProposals
export def "projects-images-regionproposals get-region-proposals" [
  project_id: string
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
]: nothing -> record<imageId: string, projectId: string, proposals: table<boundingBox: record, confidence: float>> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), image_id: (encode-path-segment $image_id)} | format pattern "/projects/{project_id}/images/{image_id}/regionproposals"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get iterations for the project.
#
# GET /projects/{projectId}/iterations
# operationId: GetIterations
export def "projects-iterations list" [
  project_id: string
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
]: nothing -> table<classificationType: string, created: string, domainId: string, exportable: bool, exportableTo: list<string>, id: string, lastModified: string, name: string, originalPublishResourceId: string, projectId: string, publishName: string, reservedBudgetInHours: int, status: string, trainedAt: string, trainingTimeInMinutes: int, trainingType: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/iterations"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a specific iteration of a project.
#
# DELETE /projects/{projectId}/iterations/{iterationId}
# operationId: DeleteIteration
export def "projects-iterations delete" [
  project_id: string
  iteration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($iteration_id | is-empty) { error make --unspanned { msg: "path parameter 'iterationId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), iteration_id: (encode-path-segment $iteration_id)} | format pattern "/projects/{project_id}/iterations/{iteration_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific iteration.
#
# GET /projects/{projectId}/iterations/{iterationId}
# operationId: GetIteration
export def "projects-iterations get" [
  project_id: string
  iteration_id: string
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
]: nothing -> record<classificationType: string, created: string, domainId: string, exportable: bool, exportableTo: list<string>, id: string, lastModified: string, name: string, originalPublishResourceId: string, projectId: string, publishName: string, reservedBudgetInHours: int, status: string, trainedAt: string, trainingTimeInMinutes: int, trainingType: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($iteration_id | is-empty) { error make --unspanned { msg: "path parameter 'iterationId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), iteration_id: (encode-path-segment $iteration_id)} | format pattern "/projects/{project_id}/iterations/{iteration_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a specific iteration.
#
# PATCH /projects/{projectId}/iterations/{iterationId}
# operationId: UpdateIteration
export def "projects-iterations update" [
  project_id: string
  iteration_id: string
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
  name: string # Gets or sets the name of the iteration.
]: any -> record<classificationType: string, created: string, domainId: string, exportable: bool, exportableTo: list<string>, id: string, lastModified: string, name: string, originalPublishResourceId: string, projectId: string, publishName: string, reservedBudgetInHours: int, status: string, trainedAt: string, trainingTimeInMinutes: int, trainingType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($iteration_id | is-empty) { error make --unspanned { msg: "path parameter 'iterationId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), iteration_id: (encode-path-segment $iteration_id)} | format pattern "/projects/{project_id}/iterations/{iteration_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get the list of exports for a specific iteration.
#
# GET /projects/{projectId}/iterations/{iterationId}/export
# operationId: GetExports
export def "projects-iterations-export get" [
  project_id: string
  iteration_id: string
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
]: nothing -> table<downloadUri: string, flavor: string, newerVersionAvailable: bool, platform: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($iteration_id | is-empty) { error make --unspanned { msg: "path parameter 'iterationId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), iteration_id: (encode-path-segment $iteration_id)} | format pattern "/projects/{project_id}/iterations/{iteration_id}/export"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Export a trained iteration.
#
# POST /projects/{projectId}/iterations/{iterationId}/export
# operationId: ExportIteration
export def "projects-iterations-export export" [
  project_id: string
  iteration_id: string
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
  --platform: string@platform-completer # The target platform.
  --flavor: string@flavor-completer # The flavor of the target platform.
]: nothing -> record<downloadUri: string, flavor: string, newerVersionAvailable: bool, platform: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($iteration_id | is-empty) { error make --unspanned { msg: "path parameter 'iterationId' must be non-empty" } }
  let qp = [(serialize-qp "platform" $platform "scalar") (serialize-qp "flavor" $flavor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), iteration_id: (encode-path-segment $iteration_id)} | format pattern "/projects/{project_id}/iterations/{iteration_id}/export") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"platform": $platform, "flavor": $flavor} | compact), body: null}
}

# Get detailed performance information about an iteration.
#
# GET /projects/{projectId}/iterations/{iterationId}/performance
# operationId: GetIterationPerformance
export def "projects-iterations-performance get" [
  project_id: string
  iteration_id: string
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
  --threshold: float # The threshold used to determine true predictions. (format: float)
  --overlap-threshold: float # If applicable, the bounding box overlap threshold used to determine true predictions. (format: float)
]: nothing -> record<averagePrecision: float, perTagPerformance: table<averagePrecision: float, id: string, name: string, precision: float, precisionStdDeviation: float, recall: float, recallStdDeviation: float>, precision: float, precisionStdDeviation: float, recall: float, recallStdDeviation: float> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($iteration_id | is-empty) { error make --unspanned { msg: "path parameter 'iterationId' must be non-empty" } }
  let qp = [(serialize-qp "threshold" $threshold "scalar") (serialize-qp "overlapThreshold" $overlap_threshold "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), iteration_id: (encode-path-segment $iteration_id)} | format pattern "/projects/{project_id}/iterations/{iteration_id}/performance") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"threshold": $threshold, "overlapThreshold": $overlap_threshold} | compact), body: null}
}

# Get image with its prediction for a given project iteration.
#
# GET /projects/{projectId}/iterations/{iterationId}/performance/images
# operationId: GetImagePerformances
export def "projects-iterations-performance-images get" [
  project_id: string
  iteration_id: string
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
  --tag-ids: list<string> # A list of tags ids to filter the images. Defaults to all tagged images when null. Limited to 20.
  --order-by: string@order-by-completer # The ordering. Defaults to newest.
  --take: int # Maximum number of images to return. Defaults to 50, limited to 256. (format: int32, default: 50)
  --skip: int # Number of images to skip before beginning the image batch. Defaults to 0. (format: int32, default: 0)
]: nothing -> table<created: string, height: int, id: string, imageUri: string, predictions: list<record>, regions: list<record>, tags: list<record>, thumbnailUri: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($iteration_id | is-empty) { error make --unspanned { msg: "path parameter 'iterationId' must be non-empty" } }
  let qp = [(serialize-qp "tagIds" $tag_ids "csv") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), iteration_id: (encode-path-segment $iteration_id)} | format pattern "/projects/{project_id}/iterations/{iteration_id}/performance/images") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagIds": $tag_ids, "orderBy": $order_by, "take": $take, "skip": $skip} | compact), body: null}
}

# Gets the number of images tagged with the provided {tagIds} that have prediction results from training for the provided iteration {iterationId}.
#
# GET /projects/{projectId}/iterations/{iterationId}/performance/images/count
# operationId: GetImagePerformanceCount
export def "projects-iterations-performance-images-count get" [
  project_id: string
  iteration_id: string
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
  --tag-ids: list<string> # A list of tags ids to filter the images to count. Defaults to all tags when null.
]: nothing -> oneof<int, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($iteration_id | is-empty) { error make --unspanned { msg: "path parameter 'iterationId' must be non-empty" } }
  let qp = [(serialize-qp "tagIds" $tag_ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), iteration_id: (encode-path-segment $iteration_id)} | format pattern "/projects/{project_id}/iterations/{iteration_id}/performance/images/count") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagIds": $tag_ids} | compact), body: null}
}

# Unpublish a specific iteration.
#
# DELETE /projects/{projectId}/iterations/{iterationId}/publish
# operationId: UnpublishIteration
export def "projects-iterations-publish delete" [
  project_id: string
  iteration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($iteration_id | is-empty) { error make --unspanned { msg: "path parameter 'iterationId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), iteration_id: (encode-path-segment $iteration_id)} | format pattern "/projects/{project_id}/iterations/{iteration_id}/publish"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Publish a specific iteration.
#
# POST /projects/{projectId}/iterations/{iterationId}/publish
# operationId: PublishIteration
export def "projects-iterations-publish publish" [
  project_id: string
  iteration_id: string
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
  --publish-name: string # The name to give the published iteration.
  --prediction-id: string # The id of the prediction resource to publish to.
]: nothing -> oneof<bool, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($iteration_id | is-empty) { error make --unspanned { msg: "path parameter 'iterationId' must be non-empty" } }
  let qp = [(serialize-qp "publishName" $publish_name "scalar") (serialize-qp "predictionId" $prediction_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), iteration_id: (encode-path-segment $iteration_id)} | format pattern "/projects/{project_id}/iterations/{iteration_id}/publish") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"publishName": $publish_name, "predictionId": $prediction_id} | compact), body: null}
}

# Delete a set of predicted images and their associated prediction results.
#
# DELETE /projects/{projectId}/predictions
# operationId: DeletePrediction
export def "projects-predictions delete" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The prediction ids. Limited to 64.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "ids" $ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/predictions") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids} | compact), body: null}
}

# Get images that were sent to your prediction endpoint.
#
# POST /projects/{projectId}/predictions/query
# operationId: QueryPredictions
# --tags item shape: {id?: string, maxThreshold?: float, minThreshold?: float}
export def "projects-predictions-query list" [
  project_id: string
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
  --application: string
  --continuation: string
  --end-time: string # nullable, format: date-time
  --iteration-id: string # nullable, format: uuid
  --max-count: int # format: int32
  --order-by: string@order-by-completer-1
  --session: string
  --start-time: string # nullable, format: date-time
  --tags: list # item shape: {id?: string, maxThreshold?: float, minThreshold?: float}
]: any -> record<results: table<created: string, domain: string, id: string, iteration: string, originalImageUri: string, predictions: list, project: string, resizedImageUri: string, thumbnailUri: string>, token: record<application: string, continuation: string, endTime: string, iterationId: string, maxCount: int, orderBy: string, session: string, startTime: string, tags: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/predictions/query"))
  let req_body = {"application": $application, "continuation": $continuation, "endTime": $end_time, "iterationId": $iteration_id, "maxCount": $max_count, "orderBy": $order_by, "session": $session, "startTime": $start_time, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Quick test an image.
#
# POST /projects/{projectId}/quicktest/image
# operationId: QuickTestImage
export def "projects-quicktest-image test-quick" [
  project_id: string
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
  --iteration-id: string # Optional. Specifies the id of a particular iteration to evaluate against. The default iteration for the project will be used when not specified. (format: uuid)
  --store: oneof<nothing, bool> # Optional. Specifies whether or not to store the result of this prediction. The default is true, to store. (default: true)
  image_data: string # Binary image data. Supported formats are JPEG, GIF, PNG, and BMP. Supports images up to 6MB. (format: binary)
]: any -> record<created: string, id: string, iteration: string, predictions: table<boundingBox: record, probability: float, tagId: string, tagName: string>, project: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "iterationId" $iteration_id "scalar") (serialize-qp "store" $store "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/quicktest/image") $qp)
  let req_body = {"imageData": $image_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageData"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: ({"iterationId": $iteration_id, "store": $store} | compact), body: $req_body}
}

# Quick test an image url.
#
# POST /projects/{projectId}/quicktest/url
# operationId: QuickTestImageUrl
export def "projects-quicktest-url test-quick-image" [
  project_id: string
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
  --iteration-id: string # Optional. Specifies the id of a particular iteration to evaluate against. The default iteration for the project will be used when not specified. (format: uuid)
  --store: oneof<nothing, bool> # Optional. Specifies whether or not to store the result of this prediction. The default is true, to store. (default: true)
  url: string # Url of the image.
]: any -> record<created: string, id: string, iteration: string, predictions: table<boundingBox: record, probability: float, tagId: string, tagName: string>, project: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "iterationId" $iteration_id "scalar") (serialize-qp "store" $store "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/quicktest/url") $qp)
  let req_body = {"url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"iterationId": $iteration_id, "store": $store} | compact), body: $req_body}
}

# Get the tags for a given project and iteration.
#
# GET /projects/{projectId}/tags
# operationId: GetTags
export def "projects-tags list" [
  project_id: string
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
  --iteration-id: string # The iteration id. Defaults to workspace. (format: uuid)
]: nothing -> table<description: string, id: string, imageCount: int, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "iterationId" $iteration_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/tags") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"iterationId": $iteration_id} | compact), body: null}
}

# Create a tag for the project.
#
# POST /projects/{projectId}/tags
# operationId: CreateTag
export def "projects-tags create" [
  project_id: string
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
  --name: string # The tag name.
  --description: string # Optional description for the tag.
  --type: string@type-completer # Optional type for the tag.
]: nothing -> record<description: string, id: string, imageCount: int, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/tags") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "description": $description, "type": $type} | compact), body: null}
}

# Delete a tag from the project.
#
# DELETE /projects/{projectId}/tags/{tagId}
# operationId: DeleteTag
export def "projects-tags delete" [
  project_id: string
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
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/projects/{project_id}/tags/{tag_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get information about a specific tag.
#
# GET /projects/{projectId}/tags/{tagId}
# operationId: GetTag
export def "projects-tags get" [
  project_id: string
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
  --accept: string@accept-completer # Response content type
  --iteration-id: string # The iteration to retrieve this tag from. Optional, defaults to current training set. (format: uuid)
]: nothing -> record<description: string, id: string, imageCount: int, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let qp = [(serialize-qp "iterationId" $iteration_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/projects/{project_id}/tags/{tag_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"iterationId": $iteration_id} | compact), body: null}
}

# Update a tag.
#
# PATCH /projects/{projectId}/tags/{tagId}
# operationId: UpdateTag
export def "projects-tags update" [
  project_id: string
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
  --accept: string@accept-completer # Response content type
  --description: string # Gets or sets the description of the tag. (nullable)
  name: string # Gets or sets the name of the tag.
  type: string@type-completer # Gets or sets the type of the tag.
]: any -> record<description: string, id: string, imageCount: int, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/projects/{project_id}/tags/{tag_id}"))
  let req_body = {"description": $description, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Suggest tags and regions for an array/batch of untagged images. Returns empty array if no tags are found.
#
# POST /projects/{projectId}/tagsandregions/suggestions
# operationId: SuggestTagsAndRegions
export def "projects-tagsandregions-suggestions create-suggest-tags-and-regions" [
  project_id: string
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
  --iteration-id: string # IterationId to use for tag and region suggestion. (format: uuid)
  --image-ids: list<string> # Array of image ids tag suggestion are needed for. Use GetUntaggedImages API to get imageIds.
]: nothing -> table<created: string, id: string, iteration: string, predictionUncertainty: float, predictions: list<record>, project: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "iterationId" $iteration_id "scalar") (serialize-qp "imageIds" $image_ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/tagsandregions/suggestions") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"iterationId": $iteration_id, "imageIds": $image_ids} | compact), body: null}
}

# Queues project for training.
#
# POST /projects/{projectId}/train
# operationId: TrainProject
export def "projects-train create" [
  project_id: string
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
  --training-type: string@training-type-completer # The type of training to use to train the project (default: Regular).
  --reserved-budget-in-hours: int # The number of hours reserved as budget for training (if applicable). (format: int32, default: 0)
  --force-train: oneof<nothing, bool> # Whether to force train even if dataset and configuration does not change (default: false). (default: false)
  --notification-email-address: string # The email address to send notification to when training finishes (default: null).
  --selected-tags: list<string> # List of tags selected for this training session, other tags in the project will be ignored.
]: any -> record<classificationType: string, created: string, domainId: string, exportable: bool, exportableTo: list<string>, id: string, lastModified: string, name: string, originalPublishResourceId: string, projectId: string, publishName: string, reservedBudgetInHours: int, status: string, trainedAt: string, trainingTimeInMinutes: int, trainingType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "trainingType" $training_type "scalar") (serialize-qp "reservedBudgetInHours" $reserved_budget_in_hours "scalar") (serialize-qp "forceTrain" $force_train "scalar") (serialize-qp "notificationEmailAddress" $notification_email_address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/train") $qp)
  let req_body = {"selectedTags": $selected_tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"trainingType": $training_type, "reservedBudgetInHours": $reserved_budget_in_hours, "forceTrain": $force_train, "notificationEmailAddress": $notification_email_address} | compact), body: $req_body}
}
