# Auto-generated client for Einstein Vision and Einstein Language v2.0.1
# Source: https://api.apis.guru/v2/specs/salesforce.local/einstein/2.0.1/openapi.json
# Auth: --token flag or $env.EINSTEIN_VISION_AND_EINSTEIN_LANGUAGE_TOKEN

const BASE_URL = "http://salesforce.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o EINSTEIN_VISION_AND_EINSTEIN_LANGUAGE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
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

def base-url-completer [] { ["http://salesforce.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["text-intent" "text-sentiment"] }
def source-completer [] { ["all" "feedback" "upload"] }
def grant-type-completer [] { ["refresh_token" "urn:ietf:params:oauth:grant-type:jwt-bearer"] }
def type-completer-1 [] { ["image" "image-multi-label"] }
def type-completer-2 [] { ["image" "image-detection" "image-multi-label"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apiusage get-usage-plans" } } | get name | first)
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

# Get API Isage
#
# GET /v2/apiusage
# operationId: getApiUsagePlansV2
export def "apiusage get-usage-plans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<endsAt: string, id: string, licenseId: string, object: string, organizationId: string, planData: list, predictionsMax: int, predictionsUsed: int, startsAt: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/apiusage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get All Datasets
#
# GET /v2/language/datasets
# operationId: listDatasets
export def "language-datasets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Index of the dataset from which you want to start paging (default: 0)
  --count: string # Number of datsets to return. Maximum valid value is 25. If you specify a number greater than 25, the call returns 25 datasets. (default: 25)
  --global: oneof<nothing, bool> # If true, returns all global datasets. Global datasets are public datasets that Salesforce provides. (default: false)
]: nothing -> record<data: table<available: bool, createdAt: string, id: int, labelSummary: record, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "global" $global "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/language/datasets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a Dataset From a File Asynchronously
#
# POST /v2/language/datasets/upload
# operationId: uploadDatasetAsync
export def "language-datasets-upload upload-async" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Path to the .csv, .tsv, or .json file on the local drive (FilePart).
  --name: string # Name of the dataset. Optional. If this parameter is omitted, the dataset name is derived from the file name. (e.g. weather)
  --path: string # URL of the .csv, .tsv, or .json file.
  --type: string@type-completer # Type of dataset data.
]: any -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/language/datasets/upload")
  let req_body = {"data": $data, "name": $name, "path": $path, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Create a Dataset From a File Synchronously
#
# POST /v2/language/datasets/upload/sync
# operationId: uploadDatasetSync
export def "language-datasets-upload-sync upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Path to the .csv, .tsv, or .json file on the local drive (FilePart).
  --name: string # Name of the dataset. Optional. If this parameter is omitted, the dataset name is derived from the file name. (e.g. weather)
  --path: string # URL of the .csv, .tsv, or .json file.
  --type: string@type-completer # Type of dataset data.
]: any -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/language/datasets/upload/sync")
  let req_body = {"data": $data, "name": $name, "path": $path, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete a Dataset
#
# DELETE /v2/language/datasets/{datasetId}
# operationId: deleteDataset
export def "language-datasets delete" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dataset_id: (encode-path-segment $dataset_id)} | format pattern "/v2/language/datasets/{dataset_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a Dataset
#
# GET /v2/language/datasets/{datasetId}
# operationId: getDataset
export def "language-datasets get" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dataset_id: (encode-path-segment $dataset_id)} | format pattern "/v2/language/datasets/{dataset_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get All Examples
#
# GET /v2/language/datasets/{datasetId}/examples
# operationId: getExamples
export def "language-datasets-examples get" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Index of the example from which you want to start paging. (default: 0)
  --count: string # Number of examples to return. (default: 100)
  --qp-source: string@source-completer # return examples that were created in the dataset as feedback
]: nothing -> record<data: table<createdAt: string, id: int, label: record, location: string, name: string, object: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dataset_id: (encode-path-segment $dataset_id)} | format pattern "/v2/language/datasets/{dataset_id}/examples") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get All Models
#
# GET /v2/language/datasets/{datasetId}/models
# operationId: getTrainedModels
export def "language-datasets-models get-trained" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Index of the model from which you want to start paging. (default: 0)
  --count: string # Number of models to return. (default: 100)
]: nothing -> record<data: table<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, failureMsg: string, language: string, modelId: string, modelType: string, name: string, object: string, progress: float, status: string, updatedAt: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dataset_id: (encode-path-segment $dataset_id)} | format pattern "/v2/language/datasets/{dataset_id}/models") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Examples From a File
#
# PUT /v2/language/datasets/{datasetId}/upload
# operationId: updateDatasetAsync
export def "language-datasets-upload update-async" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Path to the .csv, .tsv, or .json file on a local drive.
  --type: string # URL of the .csv, .tsv, or .json file.
]: any -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dataset_id: (encode-path-segment $dataset_id)} | format pattern "/v2/language/datasets/{dataset_id}/upload"))
  let req_body = {"data": $data, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Get Deletion Status
#
# GET /v2/language/deletion/{id}
# operationId: get
export def "language-deletion get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/language/deletion/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get All Examples for Label
#
# GET /v2/language/examples
# operationId: getExamplesByLabel
export def "language-examples get-by-label" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label-id: string # Label Id (e.g. SomeLabelId)
  --offset: string # Index of the example from which you want to start paging. (default: 0)
  --count: string # Number of examples to return. (default: 100)
]: nothing -> record<data: table<createdAt: string, id: int, label: record, location: string, name: string, object: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "labelId" $label_id "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/language/examples" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a Feedback Example
#
# POST /v2/language/feedback
# operationId: provideFeedback
export def "language-feedback create-provide" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document: string # Intent or sentiment string to add to the dataset.
  --expected-label: string # Correct label for the example. Must be a label that exists in the dataset.
  --model-id: string # ID of the model that misclassified the image. The feedback example is added to the dataset associated with this model.
  --name: string # Name of the example. Optional. Maximum length is 180 characters. (e.g. feedback-2)
]: any -> record<createdAt: string, id: int, label: record<datasetId: int, id: int, name: string, numExamples: int>, location: string, name: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/language/feedback")
  let req_body = {"document": $document, "expectedLabel": $expected_label, "modelId": $model_id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Prediction for Intent
#
# POST /v2/language/intent
# operationId: intentMultipart
export def "language-intent create-multipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  document: string # Text for which you want to return an intent prediction. (e.g. I can't tell you how much fun it was)
  model_id: string # ID of the model that makes the prediction. The model must have been created from a dataset with a type of text-sentiment. (e.g. WJH4YCA7YX4PCWVNCYNWYHBMY4)
  --num-results: int # Number of probabilities to return. (format: int32, e.g. 3)
  --sample-id: string # String that you can pass in to tag the prediction. Optional. Can be any value, and is returned in the response.
]: any -> record<object: string, probabilities: table<label: string, probability: float>, sampleId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/language/intent")
  let req_body = {"document": $document, "modelId": $model_id, "numResults": $num_results, "sampleId": $sample_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete a Model
#
# DELETE /v2/language/models/{modelId}
# operationId: deleteModel
export def "language-models delete" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: (encode-path-segment $model_id)} | format pattern "/v2/language/models/{model_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Model Metrics
#
# GET /v2/language/models/{modelId}
# operationId: getTrainedModelMetrics
export def "language-models get-trained-metrics" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<algorithm: string, createdAt: string, id: string, language: string, metricsData: record, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: (encode-path-segment $model_id)} | format pattern "/v2/language/models/{model_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Model Learning Curve
#
# GET /v2/language/models/{modelId}/lc
# operationId: getTrainedModelLearningCurve
export def "language-models-lc get-trained-learning-curve" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Index of the epoch from which you want to start paging (default: 0)
  --count: string # Number of epoch to return. Maximum valid value is 25. (default: 25)
]: nothing -> record<data: table<epoch: record, epochResults: record, metricsData: record, object: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({model_id: (encode-path-segment $model_id)} | format pattern "/v2/language/models/{model_id}/lc") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrain a Dataset
#
# POST /v2/language/retrain
# operationId: retrain
# --trainParams shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
export def "language-retrain create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string # Algorithm used for train (e.g. intent)
  --epochs: int # Number of training iterations for the neural network. Optional. (format: int32, e.g. 20)
  --learning-rate: float # N/A for intent or sentiment models. (format: float, e.g. 0.0001)
  --model-id: string # ID of the model to be updated from the training. (e.g. 7JXCXTRXTMNLJCEF2DR5CJ46QU)
  --train-params: record # JSON that contains parameters that specify how the model is created — shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
]: any -> record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/language/retrain")
  let req_body = {"algorithm": $algorithm, "epochs": $epochs, "learningRate": $learning_rate, "modelId": $model_id, "trainParams": $train_params} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Prediction for Sentiment
#
# POST /v2/language/sentiment
# operationId: sentimentMultipart
export def "language-sentiment create-multipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  document: string # Text for which you want to return a sentiment prediction. (e.g. I can't tell you how much fun it was)
  model_id: string # ID of the model that makes the prediction. The model must have been created from a dataset with a type of text-sentiment. (e.g. WJH4YCA7YX4PCWVNCYNWYHBMY4)
  --num-results: int # Number of probabilities to return. (format: int32, e.g. 3)
  --sample-id: string # String that you can pass in to tag the prediction. Optional. Can be any value, and is returned in the response.
]: any -> record<object: string, probabilities: table<label: string, probability: float>, sampleId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/language/sentiment")
  let req_body = {"document": $document, "modelId": $model_id, "numResults": $num_results, "sampleId": $sample_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Train a Dataset
#
# POST /v2/language/train
# operationId: train
# --trainParams shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
export def "language-train create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string # Algorithm used for train (e.g. intent)
  --dataset-id: int # ID of the dataset to train. (format: int64, e.g. 57)
  --epochs: int # Number of training iterations for the neural network. Optional. (format: int32, e.g. 20)
  --learning-rate: float # N/A for intent or sentiment models. (format: double)
  --name: string # Name of the model. Maximum length is 180 characters.
  --train-params: record # JSON that contains parameters that specify how the model is created — shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
]: any -> record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/language/train")
  let req_body = {"algorithm": $algorithm, "datasetId": $dataset_id, "epochs": $epochs, "learningRate": $learning_rate, "name": $name, "trainParams": $train_params} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Get Training Status
#
# GET /v2/language/train/{modelId}
# operationId: getTrainStatusAndProgress
export def "language-train get-status-and-progress" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: (encode-path-segment $model_id)} | format pattern "/v2/language/train/{model_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Generate an OAuth Token
#
# POST /v2/oauth2/token
# Docs: https://metamind.readme.io/docs/generate-an-oauth-access-token — authentication guid
# operationId: generateTokenV2
export def "oauth2-token generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assertion: string # encrypted payload to identify yourself (e.g. SOME_ASSERTION_STRING)
  --grant-type: string@grant-type-completer # specify the authentication method desired (e.g. urn:ietf:params:oauth:grant-type:jwt-bearer)
  --refresh-token: string # The refresh token you created previously. (e.g. SomeRefreshToken)
  --scope: string # set to `offline` to generate a refresh token (e.g. offline)
  --valid-for: int # Number of seconds until the access token expires. Default is 60 seconds. Maximum value is 30 days (format: int32, default: 60, e.g. 120)
]: any -> record<access_token: string, expires_in: string, refresh_token: string, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/oauth2/token")
  let req_body = {"assertion": $assertion, "grant_type": $grant_type, "refresh_token": $refresh_token, "scope": $scope, "valid_for": $valid_for} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# Delete a Refresh Token
#
# DELETE /v2/oauth2/tokens/{token}
# operationId: revokeRefreshTokenV2
export def "oauth2-tokens delete-refresh" [
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
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/v2/oauth2/tokens/{token_arg}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Feedback Examples From a Zip File
#
# PUT /v2/vision/bulkfeedback
# operationId: updateDatasetAsync_1
export def "vision-bulkfeedback update-dataset-async-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Local .zip file to upload. The maximum .zip file size you can upload from a local drive is 50 MB.
  --model-id: string # ID of the model that misclassified the images. The feedback examples are added to the dataset associated with this model.
]: any -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/bulkfeedback")
  let req_body = {"data": $data, "modelId": $model_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Get All Datasets
#
# GET /v2/vision/datasets
# operationId: listDatasets_1
export def "vision-datasets list-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Index of the dataset from which you want to start paging (default: 0)
  --count: string # Number of datsets to return. Maximum valid value is 25. If you specify a number greater than 25, the call returns 25 datasets. (default: 25)
  --global: oneof<nothing, bool> # If true, returns all global datasets. Global datasets are public datasets that Salesforce provides. (default: false)
]: nothing -> record<data: table<available: bool, createdAt: string, id: int, labelSummary: record, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "global" $global "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/vision/datasets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a Dataset
#
# POST /v2/vision/datasets
# operationId: createDataset
export def "vision-datasets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --labels: string # Optional comma-separated list of labels. If specified, creates the labels in the dataset. Maximum number of labels per dataset is 250. (e.g. beach,mountain)
  --name: string # Name of the dataset. Maximum length is 180 characters. (e.g. Beach and Mountain)
  --type: string@type-completer-1 # Type of dataset data
]: any -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/datasets")
  let req_body = {"labels": $labels, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Create a Dataset From a Zip File Asynchronously
#
# POST /v2/vision/datasets/upload
# operationId: uploadDatasetAsync_1
export def "vision-datasets-upload upload-async-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Path to the .zip file on the local drive (FilePart).
  --name: string # Name of the dataset. Optional. If this parameter is omitted, the dataset name is derived from the .zip file name. (e.g. mountainvsbeach)
  --path: string # URL of the .zip file.
  --type: string@type-completer-2 # Type of dataset data.
]: any -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/datasets/upload")
  let req_body = {"data": $data, "name": $name, "path": $path, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Create a Dataset From a Zip File Synchronously
#
# POST /v2/vision/datasets/upload/sync
# operationId: uploadDatasetSync_1
export def "vision-datasets-upload-sync upload-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Path to the .zip file on the local drive (FilePart).
  --name: string # Name of the dataset. Optional. If this parameter is omitted, the dataset name is derived from the .zip file name. (e.g. mountainvsbeach)
  --path: string # URL of the .zip file.
  --type: string@type-completer-2 # Type of dataset data.
]: any -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/datasets/upload/sync")
  let req_body = {"data": $data, "name": $name, "path": $path, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete a Dataset
#
# DELETE /v2/vision/datasets/{datasetId}
# operationId: deleteDataset_1
export def "vision-datasets delete-by-datasetId" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dataset_id: (encode-path-segment $dataset_id)} | format pattern "/v2/vision/datasets/{dataset_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a Dataset
#
# GET /v2/vision/datasets/{datasetId}
# operationId: getDataset_1
export def "vision-datasets get-by-datasetId" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dataset_id: (encode-path-segment $dataset_id)} | format pattern "/v2/vision/datasets/{dataset_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get All Examples
#
# GET /v2/vision/datasets/{datasetId}/examples
# operationId: getExamples_1
export def "vision-datasets-examples get-by-datasetId" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Index of the example from which you want to start paging. (default: 0)
  --count: string # Number of examples to return. (default: 100)
  --qp-source: string@source-completer # return examples that were created in the dataset as feedback
]: nothing -> record<data: table<createdAt: string, id: int, label: record, location: string, name: string, object: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dataset_id: (encode-path-segment $dataset_id)} | format pattern "/v2/vision/datasets/{dataset_id}/examples") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create an Example
#
# POST /v2/vision/datasets/{datasetId}/examples
# operationId: addExample
export def "vision-datasets-examples create" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Location of the local image file to upload.
  --label-id: int # ID of the label to add to the example. (format: int64, e.g. 42)
  --name: string # Name of the example. Maximum length is 180 characters.
]: any -> record<createdAt: string, id: int, label: record<datasetId: int, id: int, name: string, numExamples: int>, location: string, name: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dataset_id: (encode-path-segment $dataset_id)} | format pattern "/v2/vision/datasets/{dataset_id}/examples"))
  let req_body = {"data": $data, "labelId": $label_id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Get All Models
#
# GET /v2/vision/datasets/{datasetId}/models
# operationId: getTrainedModels_1
export def "vision-datasets-models get-trained-by-datasetId" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Index of the model from which you want to start paging. (default: 0)
  --count: string # Number of models to return. (default: 100)
]: nothing -> record<data: table<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, failureMsg: string, language: string, modelId: string, modelType: string, name: string, object: string, progress: float, status: string, updatedAt: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dataset_id: (encode-path-segment $dataset_id)} | format pattern "/v2/vision/datasets/{dataset_id}/models") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Examples From a Zip File
#
# PUT /v2/vision/datasets/{datasetId}/upload
# operationId: updateDatasetAsync_2
export def "vision-datasets-upload update-async-by-datasetId" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Location of the local image file to upload.
  --path: string # URL of the .zip file.
]: any -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dataset_id: (encode-path-segment $dataset_id)} | format pattern "/v2/vision/datasets/{dataset_id}/upload"))
  let req_body = {"data": $data, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Get Deletion Status
#
# GET /v2/vision/deletion/{id}
# operationId: get_1
export def "vision-deletion get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/vision/deletion/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Detection with Image File
#
# POST /v2/vision/detect
# operationId: detectMultipart
export def "vision-detect create-multipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  model_id: string # ID of the model that makes the detection. (e.g. YCQ4ZACEPJFGXZNRA6ERF3GL5E)
  --sample-base64-content: string # The image contained in a base64 string. (e.g. SomeBase64EncodedImage)
  --sample-id: string # String that you can pass in to tag the prediction. Optional. Can be any value, and is returned in the response.
  --sample-location: string # URL of the image file.
]: any -> record<object: string, probabilities: table<boundingBox: record, label: string, probability: float>, sampleId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/detect")
  let req_body = {"modelId": $model_id, "sampleBase64Content": $sample_base64_content, "sampleId": $sample_id, "sampleLocation": $sample_location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get All Examples for Label
#
# GET /v2/vision/examples
# operationId: getExamplesByLabel_1
export def "vision-examples get-by-label-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label-id: string # Label Id (e.g. SomeLabelId)
  --offset: string # Index of the example from which you want to start paging. (default: 0)
  --count: string # Number of examples to return. (default: 100)
]: nothing -> record<data: table<createdAt: string, id: int, label: record, location: string, name: string, object: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "labelId" $label_id "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/vision/examples" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a Feedback Example
#
# POST /v2/vision/feedback
# operationId: provideFeedback_1
export def "vision-feedback create-provide-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Local image file to upload.
  --expected-label: string # Correct label for the example. Must be a label that exists in the dataset.
  --model-id: string # ID of the model that misclassified the image. The feedback example is added to the dataset associated with this model.
  --name: string # Name of the example. Optional. Maximum length is 180 characters. (e.g. feedback-1)
]: any -> record<createdAt: string, id: int, label: record<datasetId: int, id: int, name: string, numExamples: int>, location: string, name: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/feedback")
  let req_body = {"data": $data, "expectedLabel": $expected_label, "modelId": $model_id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete a Model
#
# DELETE /v2/vision/models/{modelId}
# operationId: deleteModel_1
export def "vision-models delete-by-modelId" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: (encode-path-segment $model_id)} | format pattern "/v2/vision/models/{model_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Model Metrics
#
# GET /v2/vision/models/{modelId}
# operationId: getTrainedModelMetrics_1
export def "vision-models get-trained-metrics-by-modelId" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<algorithm: string, createdAt: string, id: string, language: string, metricsData: record, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: (encode-path-segment $model_id)} | format pattern "/v2/vision/models/{model_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Model Learning Curve
#
# GET /v2/vision/models/{modelId}/lc
# operationId: getTrainedModelLearningCurve_1
export def "vision-models-lc get-trained-learning-curve-by-modelId" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Index of the epoch from which you want to start paging (default: 0)
  --count: string # Number of epoch to return. Maximum valid value is 25. (default: 25)
]: nothing -> record<data: table<epoch: record, epochResults: record, metricsData: record, object: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({model_id: (encode-path-segment $model_id)} | format pattern "/v2/vision/models/{model_id}/lc") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Detect Text
#
# POST /v2/vision/ocr
# operationId: ocrMultipart
export def "vision-ocr create-multipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --model-id: string # ID of the model that makes the prediction. Valid values are OCRModel and tabulatev2. (e.g. WJH4YCA7YX4PCWVNCYNWYHBMY4)
  --sample-content: string # Binary content of image file uploaded as multipart/form-data. Optional. (format: binary)
  --sample-id: string # String that you can pass in to tag the prediction. Optional. Can be any value, and is returned in the response.
  --sample-location: string # URL of the image file. Use this parameter when sending in a file from a web location. Optional.
  --task: string # Optional. Designates the type of data in the image. Default is text. Valid values: contact, table, and text. (default: text, e.g. table)
]: any -> record<object: string, probabilities: table<attributes: record, boundingBox: record, label: string, probability: float>, sampleId: string, task: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/ocr")
  let req_body = {"modelId": $model_id, "sampleContent": $sample_content, "sampleId": $sample_id, "sampleLocation": $sample_location, "task": $task} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["sampleContent"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Make Prediction
#
# POST /v2/vision/predict
# operationId: predictMultipart
export def "vision-predict create-multipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  model_id: string # ID of the model that makes the prediction. (e.g. WJH4YCA7YX4PCWVNCYNWYHBMY4)
  --num-results: int # Number of probabilities to return. (format: int32, e.g. 3)
  --sample-base64-content: string # The image contained in a base64 string. (e.g. SomeBase64EncodedImage)
  --sample-id: string # String that you can pass in to tag the prediction. Optional. Can be any value, and is returned in the response.
  --sample-location: string # URL of the image file.
]: any -> record<object: string, probabilities: table<label: string, probability: float>, sampleId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/predict")
  let req_body = {"modelId": $model_id, "numResults": $num_results, "sampleBase64Content": $sample_base64_content, "sampleId": $sample_id, "sampleLocation": $sample_location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrain a Dataset
#
# POST /v2/vision/retrain
# operationId: retrain_1
# --trainParams shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
export def "vision-retrain create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string # Specifies the algorithm used to train the dataset. Optional. Use this parameter only when training a dataset with a type of image-detection. Valid values are object-detection-v1 and retail-execution. (e.g. object-detection)
  --epochs: int # Number of training iterations for the neural network. Optional. (format: int32, e.g. 20)
  --learning-rate: float # Specifies how much the gradient affects the optimization of the model at each time step. Optional. (format: float, e.g. 0.0001)
  --model-id: string # ID of the model to be updated from the training. (e.g. 7JXCXTRXTMNLJCEF2DR5CJ46QU)
  --train-params: record # JSON that contains parameters that specify how the model is created — shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
]: any -> record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/retrain")
  let req_body = {"algorithm": $algorithm, "epochs": $epochs, "learningRate": $learning_rate, "modelId": $model_id, "trainParams": $train_params} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Train a Dataset
#
# POST /v2/vision/train
# operationId: train_1
# --trainParams shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
export def "vision-train create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string # Specifies the algorithm used to train the dataset. Optional. Use this parameter only when training a dataset with a type of image-detection. Valid values are object-detection-v1 and retail-execution. (e.g. object-detection)
  --dataset-id: int # ID of the dataset to train. (format: int64, e.g. 57)
  --epochs: int # Number of training iterations for the neural network. Optional. (format: int32, e.g. 20)
  --learning-rate: float # Specifies how much the gradient affects the optimization of the model at each time step. Optional. (format: double, e.g. 0.0001)
  --name: string # Name of the model. Maximum length is 180 characters.
  --train-params: record # JSON that contains parameters that specify how the model is created — shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
]: any -> record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/train")
  let req_body = {"algorithm": $algorithm, "datasetId": $dataset_id, "epochs": $epochs, "learningRate": $learning_rate, "name": $name, "trainParams": $train_params} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Get Training Status
#
# GET /v2/vision/train/{modelId}
# operationId: getTrainStatusAndProgress_1
export def "vision-train get-status-and-progress-by-modelId" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: (encode-path-segment $model_id)} | format pattern "/v2/vision/train/{model_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
